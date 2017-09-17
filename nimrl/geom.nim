type
  Rectangle* = object
    x*, y*, width*, height*: int

proc center*(self: Rectangle): tuple[x, y: int] =
  result = (self.x + self.width div 2, self.y + self.height div 2)

when isMainModule:
  let rectangle = Rectangle(x: 0, y: 0, width: 10, height: 10)
  assert((5, 5) == rectangle.center())