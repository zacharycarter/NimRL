import stb_image/read as stbi, dungeon, random, seeded_noise, geom

proc newShipBlueprint*(width, height: int, shipTemplateFilename: string): ShipBlueprint = 
  var channels: int
  
  result = ShipBlueprint(
      width: width,
      height: height,
      shipTemplate: ShipTemplate()
  )

  result.shipTemplate.image = stbi.load(shipTemplateFilename, result.shipTemplate.width, result.shipTemplate.height, channels, stbi.Default)

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
      spaceship.rooms.add(Rectangle(x: column, y: row, width: column + roomX, height: row + roomY))
      spaceship.rooms.add(Rectangle(x: spaceship.width - (column + roomX) - 1, y: row, width: spaceship.width - column - 1, height: row + roomY))
      spaceship.writeRoom(column, row, column + roomX, row + roomY, CellKind.Floor, CellKind.Wall)
      
    
proc generate*(spaceship: var Dungeon, shipBlueprint: ShipBlueprint, seed: int32) =
  spaceship.seed = seed
  spaceship.partOfShip = newSeq[bool](spaceship.width * spaceship.height)
  generateUnderlyingStructure(spaceship, shipBlueprint)
  generateRooms(spaceship, shipBlueprint)