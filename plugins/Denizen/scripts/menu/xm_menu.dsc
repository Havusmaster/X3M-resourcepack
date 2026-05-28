x3m_growth_item:
  type: item
  material: heart_of_the_sea
  display name: "<&a><bold>Рост"

x3m_particles_item:
  type: item
  material: nether_star
  display name: "<&e><bold>Партиклы"

x3m_barrier_item:
  type: item
  material: barrier
  display name: "<&c><bold>Отключить Партиклы"

x3m_particle_ash:
  type: item
  material: coal
  display name: "<&8><bold>Пепел"

x3m_particle_sculk_soul:
  type: item
  material: sculk_shrieker
  display name: "<&3><bold>Душа Скулка"

x3m_particle_soul_fire_flame:
  type: item
  material: soul_torch
  display name: "<&5><bold>Пламя Души"

x3m_particle_firework:
  type: item
  material: firework_rocket
  display name: "<&c><bold>Фейерверк"

x3m_particle_cherry:
  type: item
  material: cherry_leaves
  display name: "<&d><bold>Вишнёвые Лепестки"

x3m_particle_enchant:
  type: item
  material: enchanted_book
  display name: "<&b><bold>Зачарование"

x3m_growth_small:
  type: item
  material: rabbit_foot
  display name: "<&f><bold>Маленький <&7>(1.5 блока)"

x3m_growth_normal:
  type: item
  material: player_head
  display name: "<&a><bold>Обычный <&7>(1.8 блока)"

x3m_growth_big:
  type: item
  material: ghast_tear
  display name: "<&c><bold>Большой <&7>(2.5 блока)"

x3m_menu_inventory:
  type: inventory
  inventory: chest
  title: "<&b>X3M Меню"
  size: 9
  gui: true
  slots:
    - [] [] [] [x3m_growth_item] [] [x3m_particles_item] [] [] []

x3m_growth_menu:
  type: inventory
  inventory: chest
  title: "<&a>Настройки Роста"
  size: 9
  gui: true
  slots:
    - [] [] [x3m_growth_small] [] [x3m_growth_normal] [] [x3m_growth_big] [] []

x3m_particles_menu:
  type: inventory
  inventory: chest
  title: "<&e>Настройки Партиклов"
  size: 45
  gui: true
  slots:
    - [] [] [] [] [] [] [] [] []
    - [] [] [x3m_particle_ash] [] [x3m_particle_sculk_soul] [] [x3m_particle_enchant] [] []
    - [] [] [] [x3m_particle_firework] [] [x3m_particle_soul_fire_flame] [] [] []
    - [] [] [] [] [x3m_particle_cherry] [] [] [] []
    - [] [] [] [] [] [] [] [] [x3m_barrier_item]

x3m_menu_handler:
  type: world
  debug: false
  events:
    on player clicks item in inventory:
      - if <inventory.script.name||null> == x3m_menu_inventory || <inventory.script.name||null> == x3m_growth_menu || <inventory.script.name||null> == x3m_particles_menu:
        - determine cancelled

    on player clicks item in x3m_menu_inventory:
      - choose <context.item.script.name||null>:
        - case x3m_growth_item:
          - inventory open d:x3m_growth_menu
        - case x3m_particles_item:
          - inventory open d:x3m_particles_menu

    on player clicks item in x3m_growth_menu:
      - choose <context.item.script.name||null>:
        - case x3m_growth_small:
          - execute as_server "attribute <player.name> minecraft:scale base set 0.85"
          - flag player growth:small
          - narrate "Размер <yellow>Маленький <white>установлен!"
          - inventory close
        - case x3m_growth_normal:
          - execute as_server "attribute <player.name> minecraft:scale base set 1"
          - flag player growth:normal
          - narrate "Размер <green>Обычный <white>установлен!"
          - inventory close
        - case x3m_growth_big:
          - execute as_server "attribute <player.name> minecraft:scale base set 1.25"
          - flag player growth:big
          - narrate "Размер <red>Большой <white>установлен!"
          - inventory close

    on player clicks item in x3m_particles_menu:
      - define effect_location <player.location.above[0.2]>
      - choose <context.item.script.name||null>:
        - case x3m_barrier_item:
          - flag player particle:!
          - narrate "<green>Все партиклы отключены!"
          - inventory close
        - case x3m_particle_ash:
          - flag player particle:ash
          - narrate "Эффект <gray>Пепел <white>успешно установлен!"
          - inventory close
          - repeat 5:
            - playeffect effect:ash at:<[effect_location]> quantity:20 offset:0.3,0.1,0.3
            - wait 1t
        - case x3m_particle_sculk_soul:
          - flag player particle:sculk_soul
          - narrate "Эффект <blue>Душа Скулка <white>успешно установлен!"
          - inventory close
          - repeat 5:
            - playeffect effect:sculk_soul at:<[effect_location]> quantity:20 offset:0.3,0.1,0.3
            - wait 1t
        - case x3m_particle_soul_fire_flame:
          - flag player particle:soul_fire_flame
          - narrate "Эффект <dark_purple>Пламя Души <white>успешно установлен!"
          - inventory close
          - repeat 5:
            - playeffect effect:soul_fire_flame at:<[effect_location]> quantity:20 offset:0.3,0.1,0.3
            - wait 1t
        - case x3m_particle_firework:
          - flag player particle:firework
          - narrate "Эффект <red>Фейерверк <white>успешно установлен!"
          - inventory close
          - repeat 5:
            - playeffect effect:firework at:<[effect_location]> quantity:20 offset:0.3,0.1,0.3
            - wait 1t
        - case x3m_particle_cherry:
          - flag player particle:cherry
          - narrate "Эффект <light_purple>Вишнёвые Лепестки <white>успешно установлен!"
          - inventory close
          - repeat 5:
            - playeffect effect:cherry_leaves at:<[effect_location]> quantity:20 offset:0.3,0.1,0.3
            - wait 1t
        - case x3m_particle_enchant:
          - flag player particle:enchant
          - narrate "Эффект <aqua>Зачарование <white>успешно установлен!"
          - inventory close
          - repeat 5:
            - playeffect effect:enchant at:<[effect_location]> quantity:20 offset:0.3,0.1,0.3
            - wait 1t

    on player joins:
      - wait 1t
      - choose <player.flag[growth]||normal>:
        - case small:
          - execute as_server "attribute <player.name> minecraft:scale base set 0.85"
        - case normal:
          - execute as_server "attribute <player.name> minecraft:scale base set 1"
        - case big:
          - execute as_server "attribute <player.name> minecraft:scale base set 1.25"

    on player respawns:
      - wait 1t
      - choose <player.flag[growth]||normal>:
        - case small:
          - execute as_server "attribute <player.name> minecraft:scale base set 0.85"
        - case normal:
          - execute as_server "attribute <player.name> minecraft:scale base set 1"
        - case big:
          - execute as_server "attribute <player.name> minecraft:scale base set 1.25"

x3m_command:
  type: command
  name: x3m
  description: Открывает меню X3M
  usage: /x3m
  debug: false
  script:
    - if <player.flag[discord_linked]||false> != true:
      - narrate "<&c>Сначала привяжите Discord."
      - stop
    - define did <player.flag[discord_id]||null>
    - define has_role false
    - if <[did]> != null:
      - foreach <discord[mybot].groups>:
        - foreach <[value].roles>:
          - if <[value].id||0> == 1506724552770719835:
            - define users <[value].users||null>
            - if <[users]> != null:
              - foreach <[users]>:
                - if <[value].id||0> == <[did]>:
                  - define has_role true
    - if <[has_role]> != true:
      - narrate "<&c>У вас нет роли X3unity."
      - stop
    - inventory open d:x3m_menu_inventory

testroles_command:
  type: command
  name: testroles
  usage: /testroles
  debug: false
  permission: op
  script:
    - define did <player.flag[discord_id]||null>
    - if <[did]> == null:
      - narrate "<red>Discord ID не найден. Привяжите аккаунт."
      - stop
    - narrate "<green>Discord ID: <[did]>"
    - define found_role null
    - foreach <discord[mybot].groups>:
      - define gname <[value].name||>
      - foreach <[value].roles>:
        - if <[value].id||0> == 1506724552770719835:
          - define found_role <[value]>
          - define role_name <[value].name||unknown>
          - narrate "<green>Роль '<[role_name]>' найдена в группе '<[gname]>'"
    - if <[found_role]> == null:
      - narrate "<red>Роль X3unity (1506724552770719835) не найдена ни в одной группе!"
      - narrate "<gray>Проверь ID роли и что бот в той же группе"
      - stop
    - define users <[found_role].users||null>
    - if <[users]> == null:
      - narrate "<red>users вернул null — у бота нет Server Members Intent?"
      - stop
    - if <[users].is_empty>:
      - narrate "<yellow>Список users пуст — никто не имеет этой роли?"
      - stop
    - narrate "<green>Найдено <[users].size> пользователей с ролью X3unity:"
    - foreach <[users]>:
      - define uid <[value].id||0>
      - define uname <[value].name||unknown>
      - if <[uid]> == <[did]>:
        - narrate "  - <[uname]> (<[uid]>) ✅ ЭТО ВЫ"
      - else:
        - narrate "  - <[uname]> (<[uid]>)"
    - define is_member false
    - foreach <[users]>:
      - if <[value].id||0> == <[did]>:
        - define is_member true
    - if <[is_member]>:
      - narrate "<green>✅ Вы имеете роль X3unity — меню откроется!"
    - else:
      - narrate "<red>❌ Вас нет в списке пользователей с ролью X3unity"

particles_under_feet:
  type: world
  debug: false
  events:
    on player steps on block:
      - if !<player.is_on_ground>:
        - stop
      - define particle <player.flag[particle]||null>
      - if <[particle]> == null:
        - stop
      - playeffect effect:<[particle]>
          at:<player.location.above[0.2]>
          quantity:10
          offset:0.4,0.1,0.4
          targets:<player.location.find_players_within[40]>

particle:
  type: command
  debug: false
  name: x3particle
  description: Устанавливает партикл
  usage: /x3particle <&lt>effect<&gt>
  permission: op
  tab complete:
    - determine <list[ash|sculk_soul|enchant|soul_fire_flame|firework|cherry|barrier]>
  script:
    - if <player.is_op> != true:
      - narrate "<&c>Откуда ты смог написать команду"
      - stop
    - define particle <context.args.get[1]||null>
    - if <[particle]> == null:
      - narrate "<red>Вы не ввели желаемый эффект!"
      - stop
    - if <[particle]> == barrier:
      - flag player particle:!
      - narrate "<green>Все партиклы отключены!"
      - stop
    - if <[particle].contains_single[ash|sculk_soul|enchant|soul_fire_flame|firework|cherry]>:
      - flag player particle:<[particle]>
      - narrate "Эффект <yellow><[particle]> <white>успешно установлен!"
