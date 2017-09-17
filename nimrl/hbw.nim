import stb_image/read as stbi, stb_image/write as stbiw, math

{.compile: "compile_stb_herringbone_wang_tile.c".}

type
  stbhw_tile* = object
    a*: cchar                  ##  the edge or vertex constraints, according to diagram below
    b*: cchar
    c*: cchar
    d*: cchar
    e*: cchar
    f*: cchar ##  The herringbone wang tile data; it is a bitmap which is either
            ##  w=2*short_sidelen,h=short_sidelen, or w=short_sidelen,h=2*short_sidelen.
            ##  it is always RGB, stored row-major, with no padding between rows.
            ##  (allocate stbhw_tile structure to be large enough for the pixel data)
    pixels*: array[1, cuchar]

  stbhw_tileset* = object
    is_corner*: cint
    num_color*: array[6, cint]  ##  number of colors for each of 6 edge types or 4 corner types
    short_side_len*: cint
    h_tiles*: ptr ptr stbhw_tile
    v_tiles*: ptr ptr stbhw_tile
    num_h_tiles*: cint
    max_h_tiles*: cint
    num_v_tiles*: cint
    max_v_tiles*: cint

proc stbhw_build_tileset_from_image*(ts: ptr stbhw_tileset; data: ptr cuchar; stride: cint; w: cint; h: cint): cint {.importc.}

proc stbhw_generate_image*(ts: ptr stbhw_tileset; weighting: ptr ptr cint;
pixels: ptr cuchar; stride_in_bytes: cint; w: cint; h: cint): cint {.importc.}

proc srand*(a2: cuint) {.importc.}
proc time*(a2: ptr clong): clong {.importc.}

proc stbi_write_png(
  filename: cstring;
  w, h, comp: cint;
  data: pointer,
  stride_in_bytes: int
): cint
  {.importc: "stbi_write_png".}


proc generate*(filename: string, w, h: int) =
  srand(time(nil).cuint)
  var
    xs, ys: int
    width, height, channels: int
    data: seq[uint8]
    ts: stbhw_tileset
  
  
  data = stbi.load(filename, width, height, channels, stbi.Default)
  xs = w
  ys = h
  
  assert stbhw_build_tileset_from_image(addr ts, cast[ptr cuchar](addr data[0]), cint width * 3, cint width, cint height) != 0
  
  var imgData = createShared(cuchar, 3 * xs * ys)
  assert stbhw_generate_image(addr ts, nil, imgData, cint xs * 3, cint xs, cint ys) != 0
  assert stbi_write_png(cstring "out.png", cint xs, cint ys, 3, imgData, xs * 3) != 0