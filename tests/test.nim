import random, nimrl, times, os, strutils

template benchmark(benchmarkName: string, code: stmt) =
  let t0 = epochTime()
  code
  let elapsed = epochTime() - t0
  let elapsedStr = elapsed.formatFloat(format = ffDecimal, precision = 3)
  echo "CPU Time [", benchmarkName, "] ", elapsedStr, "s"


proc main() =
  randomize()

  let caveOptions = DungeonOptions(kind: DungeonKind.CACaves)
  let caves = generate(128, 128, caveOptions) 
  caves.print

  write(stdout, "\n")

  let hbwDungeonOptions = DungeonOptions(kind: DungeonKind.HBWDungeon, subkind: DungeonSubKind.SeanDungeon)
  let hbwDungeon = generate(128, 128, hbwDungeonOptions)
  hbwDungeon.print

  write(stdout, "\n")

  let shipSize = (512, 512)
  let spaceshipOptions = DungeonOptions(kind: DungeonKind.Spaceship, shipBlueprint: newShipBlueprint(shipSize[0], shipSize[1], "templates/spaceship_two.png"), seed: random(epochTime()).int32)
  benchmark "ship generation":
    let spaceship = generate(shipSize[0], shipSize[1], spaceshipOptions)
  spaceship.print
  
main()