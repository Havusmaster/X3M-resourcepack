@echo off
chcp 65001 >nul
title Server Launcher

echo =======================================
echo      Minecraft Server Launcher
echo =======================================
echo.

echo [1/4] Starting Minecraft Server...
start "Minecraft Server" cmd /c title Minecraft Server ^& echo. ^& echo === Minecraft Server Console === ^& echo Type 'help' for commands ^& echo. ^& java -Xms1G -Xmx1G -jar paper-1.21.11-69.jar nogui ^& echo. ^& echo Server stopped. You can close this window. ^& pause

echo [2/4] Opening Error Monitor...
start "Server Errors" cmd /c title "Server Errors" ^& powershell -ExecutionPolicy Bypass -NoExit -File "server-errors.ps1"

echo [3/4] Starting Auto-Backup Monitor...
start "Auto-Backup" cmd /c title "Auto-Backup" ^& powershell -ExecutionPolicy Bypass -NoExit -File "auto-backup.ps1"

echo [4/4] Checking Git Setup...
if not exist ".git" (
    echo WARNING: Git repository not initialized.
    echo Run the following to set up GitHub backups:
    echo   git init
    echo   git remote add origin https://github.com/YOUR_USER/YOUR_REPO.git
    echo.
) else (
    echo Git repository found.
)

echo.
echo All windows launched!
echo - Minecraft Server  (console + all logs)
echo - Server Errors     (errors and warnings only)
echo - Auto-Backup       (daily backup at 00:00 MSK)
echo.
echo Close this window when done.
pause
