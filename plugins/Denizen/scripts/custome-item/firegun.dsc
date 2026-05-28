fire_gun:
  type: world
  debug: false
  events:
    on player right clicks with:flint_and_steel block|air:
      - playeffect effect:flame at:<player.location.above[1.6].forward[5]> quantity:15 offset:0.5,0.5,0.5
