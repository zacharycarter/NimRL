import stb_image/read as stbi, dungeon, random, seeded_noise

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
        if spaceship[column, row].kind == CellKind.Floor and spaceship.partOfShip[row * spaceship.width + column] == false:
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
        spaceship.writeToBothSides(column, row, CellKind.Floor)

  spaceship.trimNonContiguous(blackX, blackY)
    
proc generate*(spaceship: var Dungeon, shipBlueprint: ShipBlueprint, seed: int32) =
  spaceship.seed = seed
  spaceship.partOfShip = newSeq[bool](spaceship.width * spaceship.height)
  generateUnderlyingStructure(spaceship, shipBlueprint)
