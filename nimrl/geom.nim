type
  Rectangle* = object
    x*, y*, width*, height*: int

proc center*(self: Rectangle): tuple[x, y: int] =
  result = (self.x + self.width div 2, self.y + self.height div 2)

proc contains*(self: Rectangle, point: tuple[x, y: int]): bool =
  self.x <= point.x and self.y <= point.y and self.x + self.width >= point.x and self.y + self.height >= point.y

when isMainModule:
  let rectangle = Rectangle(x: 0, y: 0, width: 10, height: 10)
  assert((5, 5) == rectangle.center())