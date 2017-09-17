import random, times, deques, nimrl/hbw, stb_image/read as stbi, nimrl/spaceship, nimrl/dungeon

export
  spaceship, dungeon.DungeonOptions, dungeon.DungeonKind, dungeon.DungeonSubKind

proc countAdjacentWalls(caves: Dungeon, row, column: int): int =
  for i in -1..<2:
    for j in -1..<2:
      if caves[column + i, row + j].kind != CellKind.Count:
        inc(result)

proc simulateCaveFormation(caves: Dungeon): Dungeon =
  initialize(result, caves.width, caves.height)

  for column in 1..<caves.width-1:
    for row in 1..<caves.height-1:
      let walls = countAdjacentWalls(caves, row, column)
      if walls > 4:
        result[column, row] = CellKind.Wall
      else:
        result[column, row] = CellKind.Count

proc checkValidity(dungeon: var Dungeon, queue: Deque[tuple[column, row: int]], column, row: int): bool =
  result = column > 0 and column < dungeon.width - 1 and row > 0 and row < dungeon.height - 1 and dungeon[column, row].kind == CellKind.Count and not queue.contains((column, row))

proc floodFill(dungeon: var Dungeon, r, c: int, room: var seq[tuple[column, row: int]]) =
  var queue = initDeque[tuple[column, row: int]]()

  queue.addLast((c, r))

  while queue.len > 0:
    let coord = queue.popFirst()

    dungeon[coord.column, coord.row] = CellKind.Floor
    room.add(coord)

    if checkValidity(dungeon, queue, coord.column - 1, coord.row):
      queue.addLast((coord.column - 1, coord.row))
      
    if checkValidity(dungeon, queue, coord.column + 1, coord.row):
      queue.addLast((coord.column + 1, coord.row))

    if checkValidity(dungeon, queue, coord.column, coord.row - 1):
      queue.addLast((coord.column, coord.row - 1))

    if checkValidity(dungeon, queue, coord.column, coord.row + 1):
      queue.addLast((coord.column, coord.row + 1))

proc generateCaves(caves: var Dungeon) =  
  const chanceToStartAlive = 0.55

  for column in 1..<caves.width-1:
    for row in 1..<caves.height-1:
      if random(1.0) < chanceToStartAlive:
        caves[column, row] = CellKind.Count

  for step in 0..<2:
    caves = simulateCaveFormation(caves)

  var caverns: seq[seq[tuple[column, row: int]]] = @[]

  for column in 1..<caves.width-1:
    for row in 1..<caves.height-1:
      if caves[column, row].kind == CellKind.Count:
        var cavern: seq[tuple[column, row: int]] = @[]
        floodFill(caves, row, column, cavern)

        caverns.add(cavern)

  var largestCavern = caverns[0]
  for cavern in 1..<caverns.len:
    if caverns[cavern].len > largestCavern.len:
      largestCavern = caverns[cavern]


  for cavern in caverns:
    if cavern == largestCavern:
      continue
    
    for space in cavern:
      caves[space.column, space.row] = CellKind.Wall

proc generateHBWDungeon(dungeon: var Dungeon, dungeonOptions: DungeonOptions) =
  var hbwFilename: string
  
  case dungeonOptions.subKind
  of DungeonSubKind.SeanDungeon:
    hbwFilename = "templates/template_sean_dungeon.png"
  else:
    discard

  hbw.generate(hbwFilename, dungeon.width, dungeon.height)

  var
    width, height, channels: int
    data: seq[uint8]
  
  data = stbi.load("out.png", width, height, channels, stbi.Default)

  for y in 0..<height:
    for x in 0..<width:
      let index = (x + width * y) * 3
      if data[index] == 255:
        dungeon[x, y] = CellKind.Wall
      else:
        dungeon[x, y] = CellKind.Floor

proc generateSpaceship(dungeon: var Dungeon, dungeonOptions: DungeonOptions) =
  spaceship.generate(dungeon, dungeonOptions.shipBlueprint, dungeonOptions.seed)

proc generate*(width, height: int, dungeonOptions: DungeonOptions): Dungeon = 
  case dungeonOptions.kind
  of DungeonKind.CACaves:
    result.kind = DungeonKind.CACaves
    initialize(result, height, width)
    generateCaves(result)
  of DungeonKind.HBWDungeon:
    result.kind = DungeonKind.HBWDungeon
    initialize(result, height, width)
    generateHBWDungeon(result, dungeonOptions)
  of DungeonKind.Spaceship:
    result.kind = DungeonKind.Spaceship
    initialize(result, height, width)
    generateSpaceship(result, dungeonOptions)


proc print*(dungeon: Dungeon) =
  case dungeon.kind
  of DungeonKind.CACaves, DungeonKind.HBWDungeon:
    for column in 0..<dungeon.width:
      for row in 0..<dungeon.height:
        case dungeon[column, row].kind
        of CellKind.Empty:
          write(stdout, " ")
        of CellKind.Floor:
          write(stdout, ".")
        of CellKind.Wall:
          write(stdout, "#")
        else:
          write(stdout, "+")
      write(stdout, "\n")
  else:
    for column in 0..<dungeon.width:
      for row in 0..<dungeon.height:
        case dungeon[row, column].kind
        of CellKind.Empty:
          write(stdout, " ")
        of CellKind.Floor:
          write(stdout, ".")
        of CellKind.Wall:
          write(stdout, "#")
        else:
          write(stdout, "+")
      write(stdout, "\n")