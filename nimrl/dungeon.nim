import astar

type
    DungeonKind* {.pure.} = enum
      CACaves, HBWDungeon, Spaceship
  
    DungeonSubKind* {.pure.} = enum
      SeanDungeon, RoomsAndCorridors, LimitConnectivity, HorizontalCorridors, HorizontalCorridorsV2, HorizontalCorridorsV3, OpenAreas, WideDiagonalBias, RoundRoomsDiagonalCorridors 
  
    CellKind* {.pure.} = enum
      Empty, Floor, Floor2, Wall, Count
  
    Cell = object
      kind*: CellKind
  
    Dungeon* = object
      case kind*: DungeonKind
      of DungeonKind.CACaves:
        discard
      of DungeonKind.HBWDungeon:
        discard
      of DungeonKind.Spaceship:
        seed*: int32
        partOfShip*: seq[bool]
      width*, height*: int
      cells*: seq[Cell]

    ShipBlueprint* = object
      width*, height*: int
      shipTemplate*: ShipTemplate

    ShipTemplate* = object
      width*, height*: int
      image*: seq[uint8]
  
    DungeonOptions* = object
      case kind*: DungeonKind
      of DungeonKind.CACaves:
        discard
      of DungeonKind.HBWDungeon:
        subKind*: DungeonSubKind
      of DungeonKind.Spaceship:
        shipBlueprint*: ShipBlueprint
        seed*: int32
      
proc `[]`*(d: Dungeon, x, y: int): Cell = 
  d.cells[y * d.width + x]

proc `[]=`*(d: var Dungeon, x, y: int, cellKind: CellKind) = 
  d.cells[y * d.width + x].kind = cellKind

proc initialize*(dungeon: var Dungeon, columns, rows: int) =
  dungeon.width = columns
  dungeon.height = rows
  dungeon.cells = newSeq[Cell](columns * rows)

  for column in 0..<dungeon.width:
    for row in 0..<dungeon.height:
      case dungeon.kind
      of DungeonKind.CACaves, DungeonKind.HBWDungeon:
        dungeon[column, row] = CellKind.Wall
      else:
        dungeon[column, row] = CellKind.Empty

template yieldIfExists( dungeon: Dungeon, point: tuple[x, y: int] ) =
  ## Checks if a point exists within a grid, then calls yield it if it does
  let exists =
    point.y >= 0 and point.y < dungeon.height and
    point.x >= 0 and point.x < dungeon.width
  if exists:
    yield point
    
iterator neighbors*( dungeon: Dungeon, point: tuple[x, y: int] ): tuple[x, y: int] =
  ## An iterator that yields the neighbors of a given point
  yieldIfExists( dungeon, (x: point.x - 1, y: point.y) )
  yieldIfExists( dungeon, (x: point.x + 1, y: point.y) )
  yieldIfExists( dungeon, (x: point.x, y: point.y - 1) )
  yieldIfExists( dungeon, (x: point.x, y: point.y + 1) )

proc cost*(dungeon: Dungeon, a, b: tuple[x, y: int]): float =
  ## Returns the cost of moving from point `a` to point `b`
  if dungeon[a.x, a.y].kind == CellKind.Floor: result = 0.0 else: result = 1.0

proc heuristic*( dungeon: Dungeon, node, goal: Point ): float =
  ## Returns the priority of inspecting the given node
  asTheCrowFlies(node, goal)