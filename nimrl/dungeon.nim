import astar, nimrl/geom, dungeon_graph

type
    DungeonKind* {.pure.} = enum
      CACaves, HBWDungeon, Spaceship
  
    DungeonSubKind* {.pure.} = enum
      SeanDungeon, RoomsAndCorridors, LimitConnectivity, HorizontalCorridors, HorizontalCorridorsV2, HorizontalCorridorsV3, OpenAreas, WideDiagonalBias, RoundRoomsDiagonalCorridors 
  
    CellKind* {.pure.} = enum
      Empty, Floor, Wall, Door, Count
  
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
        rooms*: seq[Rectangle]
        roomGraph*: DungeonGraph
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
        
proc findRoom*(dungeon: Dungeon, point: tuple[x,y:int]): Rectangle =
  for room in dungeon.rooms:
    if room.center() == point:
      return room

proc findRoomContaining*(dungeon: Dungeon, point: tuple[x,y:int]): tuple[room: Rectangle, found: bool] =
  result.found = false
  for room in dungeon.rooms:
    if room.contains(point):
      result.room = room
      result.found = true
      
proc isBlocked*( dungeon: Dungeon, a: tuple[x, y: int] ): bool =
  if dungeon[a.x, a.y].kind == CellKind.Empty:
    result = true
  
proc isValidLocation*( dungeon: Dungeon, a, b: tuple[x, y: int] ): bool =
  result = b.x < 0 or b.y < 0 or b.x >= dungeon.width or b.y >= dungeon.height

  if not result and a.x != b.x and a.y != b.y:
    result = isBlocked(dungeon, b)

  result = not result

template yieldIfExists( dungeon: Dungeon, point: tuple[x, y: int] ) =
  ## Checks if a point exists within a grid, then calls yield it if it does
  let exists =
    point.y >= 0 and point.y < dungeon.height and
    point.x >= 0 and point.x < dungeon.width and
    dungeon[point.x, point.y].kind != CellKind.Empty
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
  case dungeon[a.x, a.y].kind
  of CellKind.Floor:
    result = 0.0
  else:
    result = 999.0

proc cost*(dungeon: Dungeon, a, b: tuple[x, y: int], r1, r2: Rectangle): float =
  ## Returns the cost of moving from point `a` to point `b`
  case dungeon[a.x, a.y].kind
  of CellKind.Floor:
    result = 0.0
  of CellKind.Count:
    result = 1.0
  of CellKind.Wall:
    result = 2.0
  else:
    result = 999.0

proc heuristic*( dungeon: Dungeon, node, goal: Point ): float =
  ## Returns the priority of inspecting the given node
  manhattan[tuple[x, y: int], float](node, goal)
