import random, nimrl, times

proc main() =
  randomize()

  let caveOptions = DungeonOptions(kind: DungeonKind.CACaves)
  let caves = generate(64, 32, caveOptions) 
  caves.print

  write(stdout, "\n")

  let hbwDungeonOptions = DungeonOptions(kind: DungeonKind.HBWDungeon, subkind: DungeonSubKind.SeanDungeon)
  let hbwDungeon = generate(64, 32, hbwDungeonOptions)
  hbwDungeon.print

  write(stdout, "\n")

  let shipSize = (256, 256)
  let spaceshipOptions = DungeonOptions(kind: DungeonKind.Spaceship, shipBlueprint: newShipBlueprint(shipSize[0], shipSize[1], "templates/spaceship_one.png"), seed: random(epochTime()).int32)
  let spaceship = generate(shipSize[0], shipSize[1], spaceshipOptions)
  spaceship.print
  
main()