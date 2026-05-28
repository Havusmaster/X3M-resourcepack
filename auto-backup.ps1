param(
    [string]$ServerPath = (Split-Path -Parent $MyInvocation.MyCommand.Path),
    [switch]$Now
)

# ===== CONFIG =====
$Cfg = @{
    WorldNames     = @("super flat", "super flat_nether", "super flat_the_end")
    BackupDir      = Join-Path $ServerPath "backups"
    RconHost       = "127.0.0.1"
    RconPort       = 25575
    EmptyWaitHours = 1
    KeepBackups    = 2
    CheckInterval  = 60
    MskTz          = "Russian Standard Time"
}

# ===== RCON CLIENT =====
function Send-RconCommand {
    param([string]$Password, [string]$Command)
    $tcp = $null; $stream = $null; $writer = $null; $reader = $null
    try {
        $tcp = [System.Net.Sockets.TcpClient]::new()
        $tcp.Connect($Cfg.RconHost, $Cfg.RconPort)
        $tcp.ReceiveTimeout = 5000
        $tcp.SendTimeout = 5000
        $stream = $tcp.GetStream()
        $writer = [System.IO.BinaryWriter]::new($stream)

        $loginId = 1
        $loginPayload = [Text.Encoding]::UTF8.GetBytes($Password + "`0")
        $writer.Write([int32](4 + 4 + $loginPayload.Length)) # len
        $writer.Write([int32]$loginId)                        # req id
        $writer.Write([int32]3)                                # type: login
        $writer.Write($loginPayload)                           # payload + null
        $writer.Flush()

        $respId = Read-RconResponse $stream
        if ($respId -ne $loginId) { return $null }

        $cmdId = 2
        $cmdPayload = [Text.Encoding]::UTF8.GetBytes($Command + "`0")
        $writer.Write([int32](4 + 4 + $cmdPayload.Length))
        $writer.Write([int32]$cmdId)
        $writer.Write([int32]2)
        $writer.Write($cmdPayload)
        $writer.Flush()

        return Read-RconResponse $stream -isCommand $true
    } catch {
        return $null
    } finally {
        if ($writer) { $writer.Dispose() }
        if ($reader) { $reader.Dispose() }
        if ($stream) { $stream.Dispose() }
        if ($tcp) { $tcp.Dispose() }
    }
}

function Read-RconResponse {
    param([System.Net.Sockets.NetworkStream]$Stream, [switch]$IsCommand)
    $reader = [System.IO.BinaryReader]::new($Stream)
    try {
        $len = $reader.ReadInt32()
        if ($len -lt 8) { return $null }
        $reqId = $reader.ReadInt32()
        $type  = $reader.ReadInt32()
        $payloadLen = $len - 8
        $payloadBytes = $reader.ReadBytes($payloadLen)
        $nullTerminator = $payloadBytes.IndexOf([byte]0)
        $text = if ($nullTerminator -ge 0) {
            [Text.Encoding]::UTF8.GetString($payloadBytes, 0, $nullTerminator)
        } else {
            [Text.Encoding]::UTF8.GetString($payloadBytes)
        }
        return @{ RequestId = $reqId; Type = $type; Text = $text }
    } catch { return $null }
    finally { if ($reader) { $reader.Dispose() } }
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

function Get-RconPass {
    $props = Get-Content (Join-Path $ServerPath "server.properties") -Encoding UTF8
    foreach ($line in $props) {
        if ($line -match '^rcon\.password=(.+)') { return $matches[1] }
    }
    return $null
}

function Get-PlayerCount {
    $pass = Get-RconPass
    if (-not $pass) { return $null }
    $resp = Send-RconCommand -Password $pass -Command "list"
    if (-not $resp -or -not $resp.Text) { return $null }
    if ($resp.Text -match 'There are (\d+) of a max') {
        return [int]$matches[1]
    }
    return $null
}

function Invoke-SaveAll {
    $pass = Get-RconPass
    if (-not $pass) { return }
    Send-RconCommand -Password $pass -Command "save-all" | Out-Null
    Start-Sleep -Seconds 5
    Send-RconCommand -Password $pass -Command "save-all" | Out-Null
    Start-Sleep -Seconds 10
}

function Send-Broadcast {
    param([string]$Message)
    $pass = Get-RconPass
    if (-not $pass) { return }
    Send-RconCommand -Password $pass -Command "say $Message" | Out-Null
}

function New-Backup {
    param([string]$Timestamp)
    $backupRoot = Join-Path $Cfg.BackupDir $Timestamp
    $null = New-Item -ItemType Directory -Path $backupRoot -Force
    $success = $true
    foreach ($w in $Cfg.WorldNames) {
        $src = Join-Path $ServerPath $w
        $dst = Join-Path $backupRoot ($w -replace 'super flat', 'world')
        if (Test-Path $src) {
            Write-Host "  Copying $w -> $dst"
            try {
                Copy-Item -Path $src -Destination $dst -Recurse -Force -ErrorAction Stop
            } catch {
                Write-Host "  FAILED: $_" -ForegroundColor Red
                $success = $false
            }
        } else {
            Write-Host "  WARNING: $src not found" -ForegroundColor Yellow
        }
    }
    return $success
}

function Invoke-GitCommit {
    param([string]$Timestamp, [string]$Message)

    $backupMeta = Join-Path $Cfg.BackupDir ".gitkeep"
    $null = New-Item -ItemType Directory -Path $Cfg.BackupDir -Force
    $null = New-Item -ItemType File -Path $backupMeta -Force

    git -C $ServerPath add --all
    if ($LASTEXITCODE -ne 0) { return $false }

    git -C $ServerPath commit -m $Message
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1) { return $false }

    git -C $ServerPath tag "backup-$Timestamp"
    if ($LASTEXITCODE -ne 0) { return $false }

    Write-Host "  Pushing to GitHub..."
    git -C $ServerPath push origin main --tags
    if ($LASTEXITCODE -ne 0) {
        git -C $ServerPath push origin master --tags
    }

    return $true
}

function Remove-OldBackups {
    $backupDirs = Get-ChildItem -Path $Cfg.BackupDir -Directory | Sort-Object Name -Descending
    $toRemove = $backupDirs | Select-Object -Skip $Cfg.KeepBackups
    foreach ($dir in $toRemove) {
        Write-Host "  Removing old backup: $($dir.Name)"
        Remove-Item -Path $dir.FullName -Recurse -Force
    }
}

function Remove-OldGitTags {
    $tags = git -C $ServerPath tag --list 'backup-*' | Sort-Object -Descending
    $toRemove = $tags | Select-Object -Skip $Cfg.KeepBackups
    foreach ($tag in $toRemove) {
        Write-Host "  Removing old tag: $tag"
        git -C $ServerPath tag -d $tag
        git -C $ServerPath push origin --delete $tag 2>$null
    }
}

function Ensure-GitSetup {
    if (-not (Test-Path (Join-Path $ServerPath ".git"))) {
        Write-Host "Initializing git repository..." -ForegroundColor Cyan
        git -C $ServerPath init
        git -C $ServerPath config user.email "server-backup@minecraft.local"
        git -C $ServerPath config user.name "Minecraft Backup Bot"

        Write-Host ""
        Write-Host "=== GITHUB SETUP REQUIRED ===" -ForegroundColor Yellow
        Write-Host "Run these commands to connect to GitHub:" -ForegroundColor Yellow
        Write-Host "  cd `"$ServerPath`"" -ForegroundColor White
        Write-Host "  git remote add origin https://github.com/YOUR_USER/YOUR_REPO.git" -ForegroundColor White
        Write-Host "==============================" -ForegroundColor Yellow
        Write-Host ""

        $remote = git -C $ServerPath remote get-url origin 2>$null
        if (-not $remote) {
            Write-Host "WARNING: No git remote configured. Backups will be local only." -ForegroundColor Red
            Write-Host "Set up a GitHub repo and add it as remote 'origin'." -ForegroundColor Red
        }
    }
}

# ===== MAIN LOOP =====
Ensure-GitSetup

Write-Host "=== Minecraft Auto-Backup Monitor ===" -ForegroundColor Cyan
Write-Host "Server: $ServerPath"
Write-Host "RCON:   $($Cfg.RconHost):$($Cfg.RconPort)"
Write-Host "MSK TZ: $($Cfg.MskTz)"
Write-Host "Backup: $($Cfg.BackupDir)"
Write-Host "Keep:   $($Cfg.KeepBackups) backups"
Write-Host "Check:  every $($Cfg.CheckInterval)s"
Write-Host ""

$state = "idle"
$emptySince = $null

function Start-BackupNow {
    param([string]$Timestamp)
    Send-Broadcast "&6[Backup] &eНачинается сохранение мира..."
    Write-Host "  Saving world..." -ForegroundColor Cyan
    Invoke-SaveAll
    Write-Host "  Copying worlds..." -ForegroundColor Cyan
    $ok = New-Backup -Timestamp $Timestamp
    if ($ok) {
        Write-Host "  Git commit & push..." -ForegroundColor Cyan
        Invoke-GitCommit -Timestamp $Timestamp -Message "backup: $Timestamp (auto)"
        Remove-OldBackups
        Remove-OldGitTags
        Send-Broadcast "&6[Backup] &aМир сохранён и отправлен в GitHub!"
        Write-Host "  DONE" -ForegroundColor Green
    } else {
        Send-Broadcast "&6[Backup] &cОшибка при сохранении мира!"
        Write-Host "  FAILED" -ForegroundColor Red
    }
}

if ($Now) {
    Write-Host "=== FORCED BACKUP ===" -ForegroundColor Cyan
    $ts = (Get-MskTime).ToString("yyyy-MM-dd_HH-mm-ss")
    Start-BackupNow -Timestamp $ts
    Write-Host "=== BACKUP DONE ===" -ForegroundColor Cyan
    exit 0
}

while ($true) {
    $mskNow = Get-MskTime

    $online = $null
    try { $online = Get-PlayerCount } catch {}

    if ($online -eq $null -and $state -ne "idle") {
        Write-Host "Server offline, resetting state" -ForegroundColor Yellow
        $state = "idle"
        $emptySince = $null
        Start-Sleep -Seconds $Cfg.CheckInterval
        continue
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
                    Send-Broadcast "&6[Backup] &e00:00 MSK - ожидание выхода игроков для бэкапа..."
                    $state = "waiting_empty"
                } else {
                    Write-Host "$($mskNow.ToString('HH:mm:ss')) MSK: Server empty, cooldown..." -ForegroundColor Green
                    $emptySince = Get-Date
                    $state = "cooldown"
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
                $emptySince = Get-Date
                $state = "cooldown"
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
                Send-Broadcast "&6[Backup] &eИгрок зашёл - таймер бэкапа сброшен"
                $emptySince = $null; $state = "waiting_empty"
                Start-Sleep -Seconds 57; continue
            }
            $waitHours = $Cfg.EmptyWaitHours
            $elapsed = ((Get-Date) - $emptySince).TotalHours
            Write-Host "  Cooldown: $([math]::Round($elapsed,1))/${waitHours}h"
            if ($elapsed -ge $waitHours) {
                Write-Host ""; Write-Host "=== STARTING BACKUP ===" -ForegroundColor Cyan
                $state = "backing_up"
            }
        }
        "backing_up" {
            $ts = $mskNow.ToString("yyyy-MM-dd_HH-mm-ss")
            Start-BackupNow -Timestamp $ts
            $state = "idle"; $emptySince = $null
            Write-Host "=== BACKUP DONE ===`n" -ForegroundColor Cyan
        }
    }

    Start-Sleep -Seconds $Cfg.CheckInterval
}
