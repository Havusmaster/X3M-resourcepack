awm_give:
  type: command
  name: awm
  debug: false
  permission: op
  script:
    - narrate "<green>Выдача AWM..."
    - give spyglass
    - narrate "<green>Готово! Зажми ПКМ для прицела, отпусти для выстрела"

powder_scope:
  type: world
  debug: false
  events:
    on player lowers spyglass:
      - define powder <player.item_in_offhand.quantity||0>
      - if <player.item_in_offhand.material.name||AIR> != GUNPOWDER:
        - narrate "<red>Нужен порох во второй руке!"
        - stop
      - define speed <[powder].mul[1.5]>
      - if <[speed]> > 8:
        - define speed 8
      - take slot:offhand quantity:<[speed].div[1.2]> material:GUNPOWDER
      - shoot arrow origin:<player.eye_location> destination:<player.eye_location.forward[200]> speed:<[speed]>
      - playsound <player.location> sound:item.crossbow.shoot volume:1 pitch:<[speed].div[8].add[0.5]>
      - playeffect effect:smoke at:<player.eye_location>
      - narrate "<gray>Сила выстрела: <yellow><[speed]>"
