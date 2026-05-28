discord_link_system:
  type: world
  debug: false
  events:
    on player joins:
      - if <player.flag[discord_linked]||false> = true:
        - stop
      - if <discord[mybot].exists> != true:
        - wait 3s
      - define uuid <player.uuid>
      - define found false
      - if <discord[mybot].exists>:
        - define topic <discordchannel@mybot,1506725522187485376.topic||>
        - if <[topic]> != null && <[topic].starts_with[!links:]>:
          - define raw <[topic].replace[!links:].with[]>
          - define entries <[raw].split[||]>
          - foreach <[entries]>:
            - if <[found]> = false:
              - define parts <[value].split[,]>
              - if <[parts].size> >= 4 && <[parts].get[1]> == <[uuid]>:
                - flag player discord_linked:true
                - flag player discord_id:<[parts].get[3]>
                - flag player discord_name:<[parts].get[4]>
                - define found true
                - narrate "<&a>Связь с Discord восстановлена!"
      - if <[found]> = true:
        - stop
      - define code <util.random.int[1000].to[9999]>
      - flag server discord_codes.<[code]>:<player.name>
      - narrate "<&6>========================"
      - narrate "<&e>ПРИВЯЗКА DISCORD"
      - narrate "<&7>Отправьте боту код:"
      - narrate "<&a><[code]>"
      - narrate "<&6>========================"

    on discord message received:
      - define code <context.new_message.text>
      - define player_name <server.flag[discord_codes.<[code]>]||null>
      - if <[player_name]> == null:
        - stop
      - define target <server.match_player[<[player_name]>]>
      - if <[target]> == null:
        - stop
      - define discord_id <context.author.id>
      - define discord_name <context.author.name>
      - define uuid <[target].uuid>
      - flag <[target]> discord_linked:true
      - flag <[target]> discord_id:<[discord_id]>
      - flag <[target]> discord_name:<[discord_name]>
      - flag server discord_codes.<[code]>:!
      - define entry "<[uuid]>,<[player_name]>,<[discord_id]>,<[discord_name]>"
      - define topic <discordchannel@mybot,1506725522187485376.topic||>
      - if <[topic]> != null && <[topic].starts_with[!links:]>:
        - define sep ||
        - define new_topic <[topic].append[<[sep]>].append[<[entry]>]>
      - else:
        - define new_topic "!links:<[entry]>"
      - adjust <discordchannel@mybot,1506725522187485376> topic:<[new_topic]>
      - ~discordmessage id:mybot channel:1506725522187485376 "<[player_name]>:<[discord_name]>"
      - narrate "<&a>Discord успешно привязан!" targets:<[target]>

unlink_command:
  type: command
  debug: false
  name: unlink
  script:
    - define uuid <player.uuid>
    - flag <player> discord_linked:!
    - flag <player> discord_id:!
    - flag <player> discord_name:!
    - if <discord[mybot].exists>:
      - define topic <discordchannel@mybot,1506725522187485376.topic||>
      - if <[topic]> != null && <[topic].starts_with[!links:]>:
        - define raw <[topic].replace[!links:].with[]>
        - define entries <[raw].split[||]>
        - define new_entries <>
        - define sep ||
        - foreach <[entries]>:
          - if <[value].contains[<[uuid]>]> != true:
            - if <[new_entries]> == "":
              - define new_entries "<[value]>"
            - else:
              - define new_entries <[new_entries].append[<[sep]>].append[<[value]>]>
        - if <[new_entries]> != "":
          - adjust <discordchannel@mybot,1506725522187485376> topic:!links:<[new_entries]>
        - else:
          - adjust <discordchannel@mybot,1506725522187485376> topic:""
    - narrate "<&c>Discord отвязан."

