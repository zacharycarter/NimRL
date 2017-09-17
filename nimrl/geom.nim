import basic2d

type
  Rect* = object
    center*: Point2d
    size*: Vector2d

proc left*(self: Rect): float =
  self.center.x - self.size.x

proc right*(self: Rect): float =
  self.center.x + self.size.x

proc top*(self: Rect): float =
  self.center.y + self.size.y

proc bottom*(self: Rect): float =
  self.center.y - self.size.y

proc area*(self: Rect): float =
  self.size.x * self.size.y * 4

proc isOverlap*(r1, r2: Rect): bool =
  if r1.left < r2.right and r1.right > r2.left and r1.bottom < r2.top and r1.top > r2.bottom:
    return true

when isMainModule:
  assert isOverlap(Rect(center: point2d(100, 100), size: vector2d(50, 50)), Rect(center: point2d(100, 100), size: vector2d(25, 25)))
  assert (not isOverlap(Rect(center: point2d(100, 100), size: vector2d(5, 5)), Rect(center: point2d(25, 25), size: vector2d(25, 25))))