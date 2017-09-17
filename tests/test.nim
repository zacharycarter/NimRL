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

  let spaceshipOptions = DungeonOptions(kind: DungeonKind.Spaceship, shipBlueprint: newShipBlueprint(64, 64, "templates/spaceship_one.png"), seed: random(1337).int32)
  let spaceship = generate(64, 64, spaceshipOptions)
  spaceship.print
  
main()