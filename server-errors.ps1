param(
    [string]$LogPath = "logs\latest.log"
)

$logDir = Split-Path $LogPath -Parent
while (-not (Test-Path $logDir)) {
    Clear-Host
    Write-Host "Waiting for logs directory..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
}

while (-not (Test-Path $LogPath)) {
    Clear-Host
    Write-Host "Waiting for latest.log..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
}

try {
    $stream = [System.IO.File]::Open($LogPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    $reader = New-Object System.IO.StreamReader($stream)

    while (-not $reader.EndOfStream) { $reader.ReadLine() | Out-Null }

    Write-Host "=== Error & Warning Monitor ===" -ForegroundColor Yellow
    Write-Host "Showing: ERROR, WARN, SEVERE, Exception, Failed" -ForegroundColor DarkGray
    Write-Host ""

    $ignore = @(
        'ProtocolLib.*has not yet been tested',
        'SERVER IS RUNNING IN OFFLINE/INSECURE MODE',
        'will make no attempt to authenticate usernames',
        'While this makes the game possible to play without internet access',
        'To change this, set "online-mode" to "true"',
        'JDA.*WebSocketClient.*Connected to WebSocket',
        'JDA.*Finished Loading',
        'Defaulting to no-operation',
        'See https://www.slf4j.org'
    )

    while ($true) {
        $line = $reader.ReadLine()
        if ($line -ne $null) {
            $skip = $false
            foreach ($pattern in $ignore) {
                if ($line -match $pattern) { $skip = $true; break }
            }
            if ($skip) { continue }

            if ($line -match "\[.*\] \[.*(?:WARN|ERROR|SEVERE).*\]") {
                if ($line -match "\[.*\] \[.*WARN.*\]") {
                    Write-Host $line -ForegroundColor Yellow
                } elseif ($line -match "\[.*\] \[.*ERROR.*\]") {
                    Write-Host $line -ForegroundColor Red
                } elseif ($line -match "\[.*\] \[.*SEVERE.*\]") {
                    Write-Host $line -ForegroundColor DarkRed -BackgroundColor Black
                }
            } elseif ($line -match "^\s+at .*\(.*\)$" -or $line -match "^\s+\.\.\. \d+ more$") {
                Write-Host $line -ForegroundColor DarkRed
            } elseif ($line -match "(?:Exception|Error|Failed|Cannot|Could not|Unable to|NullPointer|StackOverflow|OutOfMemory)") {
                Write-Host $line -ForegroundColor Red
            } elseif ($line -match "Warning:") {
                Write-Host $line -ForegroundColor Yellow
            } elseif ($line -match "\[.*\] \[.*INFO.*\]: (?:Error|ERROR|Failed|FAILED)") {
                Write-Host $line -ForegroundColor Red
            }
        } else {
            $reader.DiscardBufferedData()
            Start-Sleep -Milliseconds 100
        }
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
}
