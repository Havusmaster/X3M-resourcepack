param(
    [string]$ServerPath = (Split-Path -Parent $MyInvocation.MyCommand.Path),
    [switch]$Now
)

# ===== CONFIG =====
$Cfg = @{
    WorldNames      = @("super flat", "super flat_nether", "super flat_the_end")
    BackupDir       = Join-Path $ServerPath "backups"
    PingHost        = "127.0.0.1"
    PingPort        = 25565
    EmptyWaitHours  = 1
    MaxAutoBackups  = 3
    CheckInterval   = 60
    MskTz           = "Russian Standard Time"
}

# ===== SERVER LIST PING =====
function Write-VarInt {
    param([System.IO.Stream]$Stream, [int]$Value)
    $v = [uint32]$Value
    do {
        $b = $v -band 0x7F
        $v = $v -shr 7
        if ($v -ne 0) { $b = $b -bor 0x80 }
        $Stream.WriteByte([byte]$b)
    } while ($v -ne 0)
}

function Read-VarInt {
    param([System.IO.Stream]$Stream)
    $result = 0; $shift = 0
    do {
        $b = $Stream.ReadByte()
        if ($b -eq -1) { return $null }
        $result = $result -bor (([uint32]($b -band 0x7F)) -shl $shift)
        $shift += 7
        if ($shift -gt 35) { return $null }
    } while (($b -band 0x80) -ne 0)
    return [int]$result
}

function Get-PlayerCount {
    $tcp = $null; $stream = $null
    try {
        $tcp = [System.Net.Sockets.TcpClient]::new()
        $tcp.Connect($Cfg.PingHost, $Cfg.PingPort)
        $tcp.ReceiveTimeout = 4000
        $tcp.SendTimeout = 4000
        $stream = $tcp.GetStream()

        # Handshake (0x00): proto(-1) + addr + port + next(1)
        $hsPayload = New-Object byte[] 0
        $hsPayload = $hsPayload + [byte]0x00
        $hsPayload = $hsPayload + [byte]0xFF,0xFF,0xFF,0xFF,0x0F
        $addrBytes = [Text.Encoding]::UTF8.GetBytes("localhost")
        $addrLen = [uint32]$addrBytes.Length
        $hsStream = [System.IO.MemoryStream]::new()
        Write-VarInt -Stream $hsStream -Value $addrLen
        $hsStream.Write($addrBytes, 0, $addrBytes.Length)
        $hsStream.Write([BitConverter]::GetBytes([uint16]$Cfg.PingPort), 0, 2)
        Write-VarInt -Stream $hsStream -Value 1
        $hsExtra = $hsStream.ToArray(); $hsStream.Dispose()
        $hsPayload = $hsPayload + $hsExtra

        $fullPacket = New-Object byte[] 0
        $lenStream = [System.IO.MemoryStream]::new()
        Write-VarInt -Stream $lenStream -Value ($hsPayload.Length)
        $fullPacket = $lenStream.ToArray() + $hsPayload; $lenStream.Dispose()

        $stream.Write($fullPacket, 0, $fullPacket.Length)

        # Status request (0x00)
        $stream.WriteByte(0x01)
        $stream.WriteByte(0x00)

        # Read response: varint(len), varint(id), varint(strlen), string
        $pkLen = Read-VarInt $stream
        if (-not $pkLen) { return $null }
        $pkId = Read-VarInt $stream
        if (-not $pkId) { return $null }
        $strLen = Read-VarInt $stream
        if (-not $strLen) { return $null }
        if ($strLen -gt 32768) { return $null }

        $strBytes = New-Object byte[] $strLen
        $read = 0
        while ($read -lt $strLen) {
            $n = $stream.Read($strBytes, $read, $strLen - $read)
            if ($n -le 0) { return $null }
            $read += $n
        }

        $json = [Text.Encoding]::UTF8.GetString($strBytes)
        $obj = $json | ConvertFrom-Json
        if ($obj -and $obj.players) {
            return [int]$obj.players.online
        }
        return $null
    } catch {
        return $null
    } finally {
        if ($stream) { $stream.Dispose() }
        if ($tcp) { $tcp.Dispose() }
    }
}

# ===== HELPERS =====
function Get-MskTime {
    $utc = [DateTime]::UtcNow
    try {
        $tz = [TimeZoneInfo]::FindSystemTimeZoneById($Cfg.MskTz)
        return [TimeZoneInfo]::ConvertTimeFromUtc($utc, $tz)
    } catch {
        return $utc.AddHours(3)
    }
}

function New-Backup {
    param([string]$Type, [string]$Timestamp)
    $backupRoot = Join-Path (Join-Path $Cfg.BackupDir $Type) $Timestamp
    $null = New-Item -ItemType Directory -Path $backupRoot -Force
    $success = $true
    foreach ($w in $Cfg.WorldNames) {
        $src = Join-Path $ServerPath $w
        $dst = Join-Path $backupRoot ($w -replace 'super flat', 'world')
        if (Test-Path $src) {
            Write-Host "  Copying $w -> $dst"
            $copied = $false
            for ($retry = 0; $retry -lt 5; $retry++) {
                try {
                    robocopy $src $dst /E /R:2 /W:3 /NP /NFL /NDL > $null 2>&1
                    if ($LASTEXITCODE -lt 8) { $copied = $true; break }
                } catch {}
                Start-Sleep -Seconds 3
            }
            if (-not $copied) {
                Write-Host "  FAILED: $w" -ForegroundColor Red
                $success = $false
            }
        } else {
            Write-Host "  WARNING: $src not found" -ForegroundColor Yellow
        }
    }
    return $success
}

function Invoke-GitCommit {
    param([string]$Tag, [string]$Message)

    $backupMeta = Join-Path $Cfg.BackupDir ".gitkeep"
    $null = New-Item -ItemType Directory -Path $Cfg.BackupDir -Force
    $null = New-Item -ItemType File -Path $backupMeta -Force

    git -C $ServerPath add --all
    if ($LASTEXITCODE -ne 0) { return $false }

    git -C $ServerPath commit -m $Message
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) { return $false }

    git -C $ServerPath tag $Tag
    if ($LASTEXITCODE -ne 0) { return $false }

    Write-Host "  Pushing to GitHub..."
    git -C $ServerPath push origin main --tags
    if ($LASTEXITCODE -ne 0) {
        git -C $ServerPath push origin master --tags
    }

    return $true
}

function Remove-OldBackups {
    param([string]$Type)
    if ($Type -ne "auto") { return }
    $autoDir = Join-Path $Cfg.BackupDir "auto"
    if (-not (Test-Path $autoDir)) { return }
    $backupDirs = Get-ChildItem -Path $autoDir -Directory | Sort-Object Name -Descending
    $toRemove = $backupDirs | Select-Object -Skip $Cfg.MaxAutoBackups
    foreach ($dir in $toRemove) {
        Write-Host "  Removing old auto backup: $($dir.Name)"
        Remove-Item -Path $dir.FullName -Recurse -Force
    }
}

function Remove-OldGitTags {
    param([string]$Type)
    $prefix = "backup-$Type-"
    $tags = git -C $ServerPath tag --list "${prefix}*" | Sort-Object -Descending
    if ($Type -eq "auto") {
        $toRemove = $tags | Select-Object -Skip $Cfg.MaxAutoBackups
        foreach ($tag in $toRemove) {
            Write-Host "  Removing old tag: $tag"
            git -C $ServerPath tag -d $tag
            git -C $ServerPath push origin --delete $tag 2>$null
        }
    }
}

function Ensure-GitSetup {
    if (-not (Test-Path (Join-Path $ServerPath ".git"))) {
        Write-Host "Initializing git repository..." -ForegroundColor Cyan
        git -C $ServerPath init
        git -C $ServerPath config user.email "server-backup@minecraft.local"
        git -C $ServerPath config user.name "Minecraft Backup Bot"

        $remote = git -C $ServerPath remote get-url origin 2>$null
        if (-not $remote) {
            Write-Host "WARNING: No git remote configured. Backups will be local only." -ForegroundColor Red
            Write-Host "Set up a GitHub repo and add it as remote 'origin'." -ForegroundColor Red
        }
    }
}

function Start-Backup {
    param([string]$Type, [string]$Timestamp)
    Write-Host "  Type: $Type"
    Write-Host "  Date: $Timestamp"
    Write-Host "  Copying worlds..." -ForegroundColor Cyan
    $ok = New-Backup -Type $Type -Timestamp $Timestamp
    if ($ok) {
        Write-Host "  Git commit & push..." -ForegroundColor Cyan
        $tag = "backup-$Type-$Timestamp"
        $msg = "backup: $Type $Timestamp"
        Invoke-GitCommit -Tag $tag -Message $msg
        Remove-OldBackups -Type $Type
        Remove-OldGitTags -Type $Type
        Write-Host "  DONE" -ForegroundColor Green
    } else {
        Write-Host "  FAILED" -ForegroundColor Red
    }
}

# ===== MAIN =====
Ensure-GitSetup

Write-Host "=== Minecraft Auto-Backup ===" -ForegroundColor Cyan
Write-Host "Server: $ServerPath"
Write-Host "Ping:   $($Cfg.PingHost):$($Cfg.PingPort)"
Write-Host "MSK TZ: $($Cfg.MskTz)"
Write-Host "Backup: $($Cfg.BackupDir)"
Write-Host "MaxAuto:$($Cfg.MaxAutoBackups) backups (manual: unlimited)"
Write-Host "Check:  every $($Cfg.CheckInterval)s"
Write-Host ""

# === FORCED BACKUP (from Denizen /backup command) ===
if ($Now) {
    Write-Host "=== MANUAL BACKUP ===" -ForegroundColor Cyan
    $ts = (Get-MskTime).ToString("yyyy-MM-dd_HH-mm-ss")
    Start-Backup -Type "manual" -Timestamp $ts
    Write-Host "=== BACKUP DONE ===" -ForegroundColor Cyan
    exit 0
}

# === AUTO BACKUP LOOP ===
$state = "idle"
$emptySince = $null

while ($true) {
    $mskNow = Get-MskTime
    $online = Get-PlayerCount

    # Check for forced backup signal via Denizen player flag
    $flagsDir = Join-Path $ServerPath "plugins\Denizen\player_flags"
    $triggered = $null
    if ($state -eq "idle" -and (Test-Path $flagsDir)) {
        foreach ($ff in (Get-ChildItem -Path $flagsDir -Filter "*.dat")) {
            $text = Get-Content -Path $ff.FullName -Raw -ErrorAction SilentlyContinue
            if ($text -and $text -match "backup_triggered:true") {
                $triggered = $ff.FullName; break
            }
        }
    }
    if ($triggered) {
        Write-Host ""; Write-Host "=== SIGNAL: MANUAL BACKUP ===" -ForegroundColor Cyan
        $content = Get-Content -Path $triggered -Raw
        $content = $content -replace 'backup_triggered:true\r?\n?', ''
        [IO.File]::WriteAllText($triggered, $content, [Text.Encoding]::UTF8)
        $ts = $mskNow.ToString("yyyy-MM-dd_HH-mm-ss")
        Start-Backup -Type "manual" -Timestamp $ts
        Write-Host "=== BACKUP DONE ===`n" -ForegroundColor Cyan
        Start-Sleep -Seconds 10; continue
    }

    if ($online -eq $null -and $state -ne "idle") {
        Write-Host "Server offline, resetting state" -ForegroundColor Yellow
        $state = "idle"; $emptySince = $null
        Start-Sleep -Seconds $Cfg.CheckInterval; continue
    }

    switch ($state) {
        "idle" {
            $isTarget = ($mskNow.Hour -eq 0 -and $mskNow.Minute -eq 0)
            if ($isTarget) {
                if ($online -eq $null) {
                    Write-Host "$($mskNow.ToString('HH:mm:ss')) MSK: Server offline, skipping" -ForegroundColor Yellow
                    Start-Sleep -Seconds 57; continue
                }
                if ($online -gt 0) {
                    Write-Host "$($mskNow.ToString('HH:mm:ss')) MSK: $online players online, waiting..." -ForegroundColor Yellow
                    $state = "waiting_empty"
                } else {
                    Write-Host "$($mskNow.ToString('HH:mm:ss')) MSK: Server empty, cooldown..." -ForegroundColor Green
                    $emptySince = Get-Date; $state = "cooldown"
                }
            }
        }
        "waiting_empty" {
            if ($online -eq $null) {
                $state = "idle"; $emptySince = $null
                Start-Sleep -Seconds 57; continue
            }
            if ($online -eq 0) {
                Write-Host "  Server empty, cooldown..." -ForegroundColor Green
                $emptySince = Get-Date; $state = "cooldown"
            } else {
                Write-Host "  $online players online, waiting..." -ForegroundColor Yellow
            }
        }
        "cooldown" {
            if ($online -eq $null) {
                $state = "idle"; $emptySince = $null
                Start-Sleep -Seconds 57; continue
            }
            if ($online -gt 0) {
                Write-Host "  Player joined, resetting timer" -ForegroundColor Yellow
                $emptySince = $null; $state = "waiting_empty"
                Start-Sleep -Seconds 57; continue
            }
            $waitHours = $Cfg.EmptyWaitHours
            $elapsed = ((Get-Date) - $emptySince).TotalHours
            Write-Host "  Cooldown: $([math]::Round($elapsed,1))/${waitHours}h"
            if ($elapsed -ge $waitHours) {
                Write-Host ""; Write-Host "=== AUTO BACKUP ===" -ForegroundColor Cyan
                $state = "backing_up"
            }
        }
        "backing_up" {
            $ts = $mskNow.ToString("yyyy-MM-dd_HH-mm-ss")
            Start-Backup -Type "auto" -Timestamp $ts
            $state = "idle"; $emptySince = $null
            Write-Host "=== BACKUP DONE ===`n" -ForegroundColor Cyan
        }
    }

    Start-Sleep -Seconds $Cfg.CheckInterval
}
