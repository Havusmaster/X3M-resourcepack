backup_command:
  type: command
  name: backup
  debug: false
  permission: op
  script:
    - announce "<&6>[Backup] <&e>Принудительный бэкап запущен оператором <player.name>..."
    - execute as_server "save-all"
    - wait 3s
    - execute as_server "save-all"
    - wait 2s
    - flag player backup_triggered:true
    - narrate "<&6>Бэкап запущен, ожидайте..."
