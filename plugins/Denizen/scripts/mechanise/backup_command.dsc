backup_command:
  type: command
  name: backup
  debug: false
  permission: op
  script:
    - announce "<&6>[Backup] <&e>Принудительный бэкап запущен оператором <player.name>..."
    - execute as server "save-all"
    - wait 3s
    - execute as server "save-all"
    - wait 2s
    - narrate "<&6>Копирование миров и отправка в GitHub..."
    - system "powershell -ExecutionPolicy Bypass -NoProfile -File auto-backup.ps1 -Now"
    - narrate "<&6>Бэкап запущен в фоне, следите за консолью"
