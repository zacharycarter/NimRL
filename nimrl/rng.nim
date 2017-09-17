import random, math

const MAX_GAUSS = 6.418382187553036

var 
  haveNextNextGaussian: bool = false
  nextNextGaussian: float64


proc between*(lower, upper: int): int =
  result = lower + random(upper - lower)

proc oneIn*(chance: int): bool = 
  result = 0 == 0 + random(chance - 0)

proc nextBoolean*(): bool = 
  random(1) != 0

proc nextGaussian*(): float64 =
  if haveNextNextGaussian:
    haveNextNextGaussian = false
    return nextNextGaussian

  var
    v1, v2, s: float64 = 0.0
    
  while not (s > 0.0 and s < 1.0):
    v1 = 2 * random(1.0) - 1
    v2 = 2 * random(1.0) - 1
    s = v1 * v1 + v2 * v2

  let 
    multiplier = sqrt(-2.0 * ln(s)/s)

  nextNextGaussian = v2 * multiplier
  haveNextNextGaussian = true
  return v1 * multiplier

proc nextClampedGaussian*(): float =
  var g = nextGaussian()
  g = if g < 0: -g else: g
  g /= MAX_GAUSS
  return if g > 1.0: 1.0 else: g

when isMainModule:
  randomize()

  var lower = 1
  let upper = 5

  let result = between(lower, upper)
  assert result >= 1 and result < 5

  discard nextGaussian()