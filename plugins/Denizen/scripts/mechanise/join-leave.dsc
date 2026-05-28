jump_announce:
  type: world
  debug: false
  events:
    on player joins:
      - if <discord[mybot].exists>:
        - define channel 1506295560427012286
        - define player_name <player.name>
        - define messages <list[присоединился к игре|залетает на сервер|запрыгивает на борт]>
        - define random_msg <[messages].random>
        - define embed <discord_embed[title=<[player_name]> <[random_msg]>;color=#00FF00;thumbnail=https://mc-heads.net/head/<player.name>]>
        - ~discordmessage id:mybot channel:<[channel]> embed:<[embed]>

    on player quits:
      - if <discord[mybot].exists>:
        - define channel 1506295560427012286
        - define player_name <player.name>
        - define messages <list[игроку стало скучно|пошел делать уроки|вышел из игры]>
        - define random_msg <[messages].random>
        - define embed <discord_embed[title=<[player_name]> <[random_msg]>;color=#FF0000;thumbnail=https://mc-heads.net/head/<player.name>]>
        - ~discordmessage id:mybot channel:<[channel]> embed:<[embed]>
