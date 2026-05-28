player_list:
  type: world
  debug: false
  events:
    on discord message received:
      - define message <context.new_message.text>
      - define channel_id <context.new_message.channel.id>
      - define author_id <context.new_message.author.id>
      - define bot_id 1506292700784365748
      - if <[channel_id]> == 1506295560427012286 && <[author_id]> != <[bot_id]>:
        - if <[message].to_lowercase> == "list":
          - if <discord[mybot].exists>:
            - define players <server.online_players>
            - if <[players].is_empty>:
              - define embed <discord_embed[title=Игроков онлайн: 0;description=Нет игроков на сервере;color=#5865F2;timestamp=<util.time_now>]>
            - else:
              - define count <[players].size>
              - define player_list <[players].parse[name].separated_by[&n• ]>
              - define embed <discord_embed[title=Игроков онлайн: <[count]>;description=• <[player_list]>;color=#5865F2;timestamp=<util.time_now>]>
            - ~discordmessage id:mybot channel:<[channel_id]> embed:<[embed]>
