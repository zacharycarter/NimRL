import stb_image/read as stbi, dungeon, random, seeded_noise, geom, astar, threadpool, tables, dungeon_graph, sequtils, locks

{.experimental.}

proc newShipBlueprint*(width, height: int, shipTemplateFilename: string): ShipBlueprint = 
  var channels: int
  
  result = ShipBlueprint(
      width: width,
      height: height,
      shipTemplate: ShipTemplate()
  )

  result.shipTemplate.image = stbi.load(shipTemplateFilename, result.shipTemplate.width, result.shipTemplate.height, channels, stbi.Default)

proc write(spaceship: var Dungeon, column, row: int, cellKind: CellKind) =
  spaceship[column, row] = cellKind

proc writeToBothSides(spaceship: var Dungeon, column, row: int, cellKind: CellKind) =
  spaceship[column, row] = cellKind
  spaceship[spaceship.width - 1 - column, row] = cellKind

proc isPartOfShip(spaceship: Dungeon, column, row: int): bool =
  if column < 0 or row < 0 or column >= spaceship.width or row >= spaceship.height:
    return false
  return spaceship.partOfShip[row * spaceship.width + column]

proc trimNonContiguous(spaceship: var Dungeon, startColumn, startRow: int) =
  spaceship.partOfShip[startRow * spaceship.width + startColumn] = true

  var added = 1

  while added > 0:
    added = 0

    for column in 0..<spaceship.width:
      for row in 0..<spaceship.height:
        if spaceship[column, row].kind == CellKind.Count and spaceship.partOfShip[row * spaceship.width + column] == false:
          if spaceship.isPartOfShip(column + 1, row) or spaceship.isPartOfShip(column - 1, row) or spaceship.isPartOfShip(column, row + 1) or spaceship.isPartOfShip(column, row - 1):
            spaceship.partofShip[row * spaceship.width + column] = true
            inc(added)

  for column in 0..<spaceship.width:
    for row in 0..<spaceship.height:
      if not spaceship.partOfShip[row * spaceship.width + column]:
        spaceship[column, row] = CellKind.Empty

proc generateUnderlyingStructure(spaceship: var Dungeon, shipBlueprint: ShipBlueprint) =
  var
    blackX, blackY = -1
    xStructureOffset = random(200) - 100
    yStructureOffset = random(200) - 100

  for column in 0..<spaceship.width div 2:
    for row in 0..<spaceship.height:
      let templateX = int((column.float / shipBlueprint.width.float) * shipBlueprint.shipTemplate.width.float)
      let templateY = int((row.float / shipBlueprint.height.float) * shipBlueprint.shipTemplate.height.float)
      let index = (templateX + shipBlueprint.shipTemplate.width * templateY) * 4
      
      let r = shipBlueprint.shipTemplate.image[index]
      let g = shipBlueprint.shipTemplate.image[index + 1]
      let b = shipBlueprint.shipTemplate.image[index + 2]
      let a = shipBlueprint.shipTemplate.image[index + 3]

      var showHere = (r, g, b, a) == (0u8, 0u8, 0u8, 255u8)
      if showHere:
        blackX = column
        blackY = row

      showHere = showHere or ((r, g, b, a) == (255u8, 255u8, 255u8, 255u8) and seeded_noise.noise((column + xStructureOffset).float * (10.0 / shipBlueprint.width.float), (row + yStructureOffset).float * (10.0 / shipBlueprint.height.float), spaceship.seed) > 0)

      if showHere:
        spaceship.writeToBothSides(column, row, CellKind.Count)

  spaceship.trimNonContiguous(blackX, blackY)

proc testBothSides(dungeon: Dungeon, column, row: int, cellKind: CellKind): bool =
  result = dungeon[column, row].kind == cellKind and dungeon[dungeon.width - 1 - column, row].kind == cellKind

proc testRoom(spaceship: Dungeon, xLow, yLow, xHigh, yHigh: int, cellKind: CellKind): bool =
  if xLow < 0 or yLow < 0 or xHigh >= spaceship.width div 2 or yHigh >= spaceship.height:
    return false
  
  for column in xLow..<xHigh:
    for row in yLow..<yHigh:
      if not spaceship.testBothSides(column, row, cellKind):
        return false
  return true

proc writeRoom(spaceship: var Dungeon, xLow, yLow, xHigh, yHigh: int, floorKind: CellKind, wallKind: CellKind) =
  for column in xLow..xHigh:
    for row in yLow..yHigh:
      if column == xLow or row == yLow or column == xHigh or row == yHigh:
        spaceship.writeToBothSides(column, row, wallKind)
      else:
        spaceship.writeToBothSides(column, row, floorKind)

proc generateRooms(spaceship: var Dungeon, shipBlueprint: ShipBlueprint) =
  spaceship.rooms = @[]

  for i in 0..<100:
    let roomX = random(10) + ((100 - i) div 10) + 2
    let roomY = random(10) + ((100 - i) div 10) + 2

    var column = random(spaceship.width div 2 - roomX)
    var row = random(spaceship.height - roomY)

    var primed, placed = false

    while not placed:
      inc(column)
      let valid = spaceship.testRoom(column - 1, row - 1, column + roomX + 1, row + roomY + 1, CellKind.Count)
      if valid:
        primed = true
      elif primed:
        placed = true
        dec(column)
      
      if column >= spaceship.width:
        break
    
    primed = false
    placed = false

    while not placed:
      inc(row)
      let valid = spaceship.testRoom(column - 1, row - 1, column + roomX + 1, row + roomY + 1, CellKind.Count)
      if valid:
        primed = true
      elif primed:
        placed = true
        dec(row)
      
      if row >= spaceship.height:
        break
    
    if spaceship.testRoom(column, row, column + roomX, row + roomY, CellKind.Count):
      let roomOne = Rectangle(x: column, y: row, width: (column + roomX) - column, height: (row + roomY) - row)
      spaceship.rooms.add(roomOne)
      discard spaceship.roomGraph.addNode(newDungeonGraphNode(roomOne.center()), true)
      
      let roomTwo = Rectangle(x: spaceship.width - (column + roomX) - 1, y: row, width: (spaceship.width - column - 1) - (spaceship.width - (column + roomX) - 1), height: (row + roomY) - row)
      spaceship.rooms.add(roomTwo)
      discard spaceship.roomGraph.addNode(newDungeonGraphNode(roomTwo.center()), true)
      
      spaceship.writeRoom(column, row, column + roomX, row + roomY, CellKind.Floor, CellKind.Wall)

proc doAstar(spaceship: Dungeon, r1, r2: int): seq[tuple[x,y:int]] =
  let roomOneCenter = spaceship.rooms[r1].center()
  let roomTwoCenter = spaceship.rooms[r2].center()

  result = path[Dungeon, tuple[x,y:int], float](spaceship, roomOneCenter, roomTwoCenter)

proc placeDoors(spaceship: var Dungeon, graph: var DungeonGraph, stepSets: seq[seq[tuple[x,y:int]]]) =
  for steps in stepSets:
    for s in 0..<steps.len:
      let 
        stepX = steps[s].x
        stepY = steps[s].y
        cellKind = spaceship[stepX, stepY].kind
      
      if cellKind == CellKind.Wall:
        spaceship.write(stepX, stepY, CellKind.Door)

        let roomReceivingDoor = spaceship.findRoomContaining((stepX, stepY))
        assert roomReceivingDoor.found
        let roomReceivingDoorCenter = roomReceivingDoor.room.center()

        var temp = s + 1
        while not spaceship.findRoomContaining((steps[temp].x, steps[temp].y)).found:
          inc(temp)

        let roomDoorTo = spaceship.findRoomContaining((steps[temp].x, steps[temp].y))
        assert roomDoorTo.found
        let roomDoorToCenter = roomDoorTo.room.center()

        discard graph.addEdge(graph.nodes[(roomReceivingDoorCenter.x, roomReceivingDoorCenter.y)], graph.nodes[(roomDoorToCenter.x, roomDoorToCenter.y)], 1)

      elif cellKind != CellKind.Door:
        spaceship.write(stepX, stepY, CellKind.Floor)
      elif cellKind == CellKind.Door:
        let roomReceivingDoor = spaceship.findRoomContaining((stepX, stepY))
        assert roomReceivingDoor.found
        let roomReceivingDoorCenter = roomReceivingDoor.room.center()

        var temp = s + 1
        while not spaceship.findRoomContaining((steps[temp].x, steps[temp].y)).found:
          inc(temp)

        let roomDoorTo = spaceship.findRoomContaining((steps[temp].x, steps[temp].y))
        assert roomDoorTo.found
        let roomDoorToCenter = roomDoorTo.room.center()
        
        discard graph.addEdge(graph.nodes[(roomReceivingDoorCenter.x, roomReceivingDoorCenter.y)], graph.nodes[(roomDoorToCenter.x, roomDoorToCenter.y)], 1)

proc findHallways(spaceship: Dungeon, edge: DungeonGraphEdge): seq[tuple[x,y:int]] =
  let roomCenterFrom = edge.one.id
  let roomCenterTo = edge.two.id

  result = path[Dungeon, tuple[x,y:int], float](spaceship, roomCenterFrom, roomCenterTo)

proc carveHallway(spaceship: var Dungeon, hallways: seq[seq[tuple[x,y:int]]]) =
  for hallway in hallways:
    for s in 0..<hallway.len:
      let 
        stepX = hallway[s].x
        stepY = hallway[s].y
        cellKind = spaceship[stepX, stepY].kind
    
      if cellKind == CellKind.Wall:
        
        spaceship.write(stepX, stepY, CellKind.Door)
      elif cellKind != CellKind.Door:
        spaceship.write(stepX, stepY, CellKind.Floor)

proc generateHallways(spaceship: var Dungeon) =
  var tempSpaceship = spaceship
  var stepSetsInProgress: seq[FlowVar[seq[tuple[x,y:int]]]] = @[]
  var setStepsCompleted: seq[seq[tuple[x,y:int]]] = @[]
  #parallel:
  for r1 in 0..<spaceship.rooms.len:
    for r2 in 0..<spaceship.rooms.len:
      stepSetsInProgress.add(spawn doAstar(spaceship, r1, r2))

  sync()

  for stepSetInProgress in stepSetsInProgress:
    setStepsCompleted.add(^stepSetInProgress)
    
  tempSpaceship.placeDoors(spaceship.roomGraph, setStepsCompleted)
  stepSetsInProgress.setLen(0)
  setStepsCompleted.setLen(0)
  let edges = toSeq(spaceship.roomGraph.edges.values)

  #parallel:
  for i in 0..<edges.len:
    stepSetsInProgress.add(spawn spaceship.findHallways(edges[i]))

  sync()
  
  for stepSetInProgress in stepSetsInProgress:
    setStepsCompleted.add(^stepSetInProgress)

  spaceship.carveHallway(setStepsCompleted)


proc generate*(spaceship: var Dungeon, shipBlueprint: ShipBlueprint, seed: int32) =
  spaceship.seed = seed
  spaceship.partOfShip = newSeq[bool](spaceship.width * spaceship.height)
  spaceship.roomGraph = newDungeonGraph()
  generateUnderlyingStructure(spaceship, shipBlueprint)
  generateRooms(spaceship, shipBlueprint)
  generateHallways(spaceship)