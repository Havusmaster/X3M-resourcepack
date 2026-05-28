discord_chat:
  type: world
  debug: false
  events:
    on server start:
      - ~discordconnect id:mybot token:<secret[discord_bot_token]>
      - wait 3s
      - if <discord[mybot].exists>:
        - define log_channel 1506295560427012286
        - discordmessage id:mybot channel:<[log_channel]> "✅ **Minecraft сервер запущен!**"

    on player chats:
      - if <discord[mybot].exists> && <player.name> != Console:
        - define player_name <player.name>
        - define message <context.message>
        - define channel 1506295560427012286
        - ~discordmessage id:mybot channel:<[channel]> "**<[player_name]>**: <[message]>"

    on discord message received:
      - define author <context.new_message.author.name>
      - define author_id <context.new_message.author.id>
      - define message <context.new_message.text>
      - define channel_id <context.new_message.channel.id>
      - define bot_id 1506292700784365748
      - if <[channel_id]> == 1506295560427012286 && <[author_id]> != <[bot_id]>:
        - if <[message]> == "list":
          - stop
        - announce "<gray>[Discord] <aqua><[author]>: <white><[message]>"
