import tables, sets, hashes

type
  DungeonGraph* = object
    nodes*: Table[tuple[x,y:int], DungeonGraphNode]
    edges*: Table[int, DungeonGraphEdge]

  Neighborhood = seq[DungeonGraphEdge]
  
  DungeonGraphNode* = object
    id*: tuple[x,y:int]
    neighbors: Neighborhood
    children: seq[DungeonGraphNode]

  DungeonGraphEdge* = object
    one*, two*: DungeonGraphNode
    weight*: int

proc newDungeonGraph*(): DungeonGraph =
  result = DungeonGraph(
    nodes: initTable[tuple[x,y:int], DungeonGraphNode](),
    edges: initTable[int, DungeonGraphEdge]()
  )

proc newDungeonGraphNode*(id: tuple[x,y:int]): DungeonGraphNode =
  result = DungeonGraphNode(
    id: id,
    neighbors: @[],
    children: @[]
  )

proc removeNeighbor(self: var Neighborhood, edge: DungeonGraphEdge) =
  var i = 0
  for neighbor in self:
    if neighbor == edge:
      self.del(i)
      inc(i)
  
proc hash*(edge: DungeonGraphEdge): int =
  return hashes.hash(edge.one.id) + hashes.hash(edge.two.id)

proc addEdge*(self: var DungeonGraph, one, two: var DungeonGraphNode, weight: int): bool = 
  if one.id == two.id:
    return false

  let e = DungeonGraphEdge(one: one, two: two, weight: weight)
  if self.edges.contains(e.hash()):
    return false
  
  elif one.neighbors.contains(e) or two.neighbors.contains(e):
    return false
  
  self.edges.add(e.hash(), e)
  one.neighbors.add(e)
  two.neighbors.add(e)
  return true


proc addNeighbor*(self: var DungeonGraphNode, edge: DungeonGraphEdge) =
  if self.neighbors.contains(edge):
    return
  
  self.neighbors.add(edge)

proc removeEdge(self: var DungeonGraph, edge: var DungeonGraphEdge) =
  edge.one.neighbors.removeNeighbor(edge)
  edge.two.neighbors.removeNeighbor(edge)
  self.edges.del(edge.hash())


proc addNode*(self: var DungeonGraph, node: DungeonGraphNode, overwriteExisting: bool): bool =
  if self.nodes.contains(node.id) and not overwriteExisting:
    return false
  elif self.nodes.contains(node.id):
    var current = self.nodes[node.id]


    for neighbor in current.neighbors.mitems:
      self.removeEdge(neighbor)
  
  self.nodes.add(node.id, node)
  result = true

when isMainModule:
  var graph = newDungeonGraph()
  var node = newDungeonGraphNode((0, 0))
  var otherNode = newDungeonGraphNode((1,0))

  discard graph.addNode(node, false)
  discard graph.addNode(otherNode, false)

  var edge = DungeonGraphEdge(one: node, two: otherNode)
  node.addNeighbor(edge)
  

