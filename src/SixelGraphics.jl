module SixelGraphics

export Screen, Bitmap, sixelplot, clear, putpixel, sixels

const NCOL = 16

# structs

struct Defaults
  ax1::Float64
  axy::Float64
  axy2::Float64
  ay1::Float64
  ayx::Float64
  tl::Float64
  function Defaults()
    new(0.2,0.1,0.9,0.15,0.15,0.01)
  end
end

mutable struct Scaler
  a::Float64
  b::Float64
  mn::Float64
  mx::Float64
  function Scaler(omn,omx,nmn,nmx)
    b = (omx-omn)/(nmx-nmn)
    a = omn - b*nmn
    new(a,b,nmn,nmx)
  end
end

struct Color
  d::Bool
  r::Int
  g::Int
  b::Int
  function Color()
    new(false,0,0,0)
  end
end

struct Palette
  colors::Vector{Color}
  function Palette()
    new([Color() for i=1:NCOL])
  end
end

struct Font
  fnt::Vector{UInt8}
  function Font()
    fid = open(joinpath(dirname(pathof(SixelGraphics)),"Lat7-VGA8.raw"),"r")
    fnt = read(fid)
    close(fid)
    new(fnt)
  end
end

struct Bitmap
  nr::Int
  nc::Int
  planes::Array{UInt8,3}
  function Bitmap(nr::Int,nc::Int)
    new(nr,nc,zeros(UInt8, NCOL, nr, nc))
  end
end

struct Screen
  d::Defaults
  b::Bitmap
  sx::Scaler
  sy::Scaler
  p::Palette
  f::Font
  function Screen(nx::Int,ny::Int)
    new(Defaults(),Bitmap(div(ny,6),nx),Scaler(0,nx-1,0,1),Scaler(0,ny-1,0,1),Palette(),Font())
  end
end

# Scaler methods

function scale(s::Scaler, x)
  if x<s.mn
    return Int(floor(s.mn))
  elseif x>s.mx
    return Int(floor(s.mx))
  end
  Int(floor(s.a+s.b*x))
end

function set(s::Scaler,omn,omx,nmn,nmx)
  s.b = (omx-omn)/(nmx-nmn)
  s.a = omn - s.b*nmn
  s.mn = nmn
  s.mx = nmx
end

# Palette methods

function setcolor(p::Palette, c, r, g, b)
  p.colors[c].d = true
  p.colors[c].r = r
  p.colors[c].g = g
  p.colors[c].b = b
end

# Bitmap methods

function clear(b::Bitmap, v)
  b.planes[:,:,:] .= v
end

function putpixel(b::Bitmap, ic::Int, ix::Int, iy::Int)
  #ix1::Int
  #ib1::Int
  #ib2::Int
  #ib3::UInt8

  if ic<1 || ic>NCOL || ix<0 || ix>=b.nc || iy<0 || iy>=b.nr*6; return; end

  ix1 = ix+1
  ib1 = div(iy,6)
  ib2 = iy - ib1*6
  ib1 += 1
  ib3 = UInt8(32 >> ib2)

  b.planes[ic,ib1,ix1] = 63 + ((b.planes[ic,ib1,ix1] - 63) | ib3)
end

function idrawline(b::Bitmap, ic::Int, ix1::Int, iy1::Int, ix2::Int, iy2::Int)
  dx = ix2-ix1
  dy = iy2-iy1
  adx = abs(dx)
  ady = abs(dy)

  n = adx>ady ? adx : ady

  ax = dx/n
  ay = dy/n

  for i = 0:n
    ix = Int(round(ix1 + i*ax))
    iy = Int(round(iy1 + i*ay))
    putpixel(b,ic,ix,iy)
  end
end

function idrawchar(b::Bitmap, f::Font, ic::Int, ix::Int, iy::Int, c::Char)
  msk = UInt8(0)

  ptr = Int(c)*8+1
  iyj = iy+7

  for j = 0:7
    msk = 0x80
    ixi = ix
    for i = 0:7
      if (f.fnt[ptr] & msk) > 0; putpixel(b,ic,ixi,iyj); end
      msk >>= 1
      ixi += 1
    end
    ptr += 1
    iyj -= 1
  end
end

function idrawlchar(b::Bitmap, f::Font, ic::Int, ix::Int, iy::Int, c::Char)
  #msk::UInt8
  msk = UInt8(0)

  ptr = Int(c)*8+1
  ixj = ix

  for j = 0:7
    msk = 0x80
    iyi = iy
    for i = 0:7
      if (f.fnt[ptr] & msk) > 0; putpixel(b,ic,ixj,iyi); end
      msk >>= 1
      iyi += 1
    end
    ptr += 1
    ixj += 1
  end
end

function idrawstring(b::Bitmap, f::Font, ic::Int, ix::Int, iy::Int, a::String)
  ix1 = ix
  for i=1:length(a); idrawchar(b, f, ic, ix1, iy, a[i]); ix1+=8; end
end

function idrawlstring(b::Bitmap, f::Font, ic::Int, ix::Int, iy::Int, a::String)
  iy1 = iy
  for i=1:length(a); idrawlchar(b, f, ic, ix, iy1, a[i]); iy1+=8; end
end

function idrawmarker(b::Bitmap, f::Font, ic::Int, ix::Int, iy::Int, m::Int)
  if m==0
    putpixel(b, ic, ix,iy)
  elseif m==1
    idrawline(b, ic, ix-2,iy, ix+2, iy)
    idrawline(b, ic, ix,iy-2, ix, iy+2)
  elseif m==2
    idrawline(b, ic, ix-2,iy-2, ix+2, iy+2)
    idrawline(b, ic, ix-2,iy+2, ix+2, iy-2)
  elseif m==3
    idrawline(b, ic, ix-2,iy-2, ix-2, iy+2)
    idrawline(b, ic, ix-2,iy+2, ix+2, iy+2)
    idrawline(b, ic, ix+2,iy+2, ix+2, iy-2)
    idrawline(b, ic, ix+2,iy-2, ix-2, iy-2)
  else
    idrawchar(b, f, ic, ix-4, iy-4, Char(m))
  end
end

# Screen methods

function drawline(s::Screen, ic::Int, x1, y1, x2, y2)
  idrawline(s.b, ic, scale(s.sx,x1), scale(s.sy,y1), scale(s.sx,x2), scale(s.sy,y2))
end

function drawstring(s::Screen, ic::Int, x, y, a::String, or::Char)
  ix = scale(s.sx,x)
  iy = scale(s.sy,y)
  n = length(a)

  if or == 'c'
    idrawstring(s.b, s.f, ic, ix-n*4, iy-4, a)
  elseif or == 'u'
    idrawstring(s.b, s.f, ic, ix-n*4, iy, a)
  elseif or == 'd'
    idrawstring(s.b, s.f, ic, ix-n*4, iy-8, a)
  elseif or == 'r'
    idrawstring(s.b, s.f, ic, ix, iy-4, a)
  elseif or == 'l'
    idrawstring(s.b, s.f, ic, ix-n*8, iy-4, a)
  end
end

function drawlstring(s::Screen, ic::Int, x, y, a::String, or::Char)
  ix = scale(s.sx,x)
  iy = scale(s.sy,y)
  n = length(a)

  if or == 'r'
    idrawlstring(s.b, s.f, ic, ix, iy-n*4, a)
  elseif or == 'l'
    idrawlstring(s.b, s.f, ic, ix-8, iy-n*4, a)
  end
end

function drawplot(s::Screen, ic::Int, x::Array, y::Array, typ::Char, pch::Int)
  dl = typ=='l' || typ=='b'
  dp = typ=='p' || typ=='b'

  n = length(x)

  for i=2:n
    ix1 = scale(s.sx,x[i-1])
    iy1 = scale(s.sy,y[i-1])
    ix2 = scale(s.sx,x[i])
    iy2 = scale(s.sy,y[i])
    if dl; idrawline(s.b,ic,ix1,iy1,ix2,iy2); end
    if pch>=0
      if i==2 && dp; idrawmarker(s.b,s.f,ic,ix1,iy1,pch); end
      if dp; idrawmarker(s.b,s.f,ic,ix2,iy2,pch); end
    else
      if i==2 && dp; idrawmarker(s.b,s.f,1,ix1,iy1,96+i-1); end
      if dp; idrawmarker(s.b,s.f,1,ix2,iy2,96+i); end
    end
  end
end

function adjust(mn, mx)
  d = exp(log(10)*Int(floor(log10(mx-mn))))
  mn = floor(mn/d)
  mx = ceil(mx/d)
  nt = Int(round(mx-mn))
  if d>=1
    [Int(round(mn*d)) Int(round(mx*d)) nt]
  else
    [mn*d mx*d nt]
  end
end

function axes(s::Screen, xlab::String, autox::Bool, xmin, xmax,
                         ylab::String, autoy::Bool, ymin, ymax)
  drawline(s, 1, s.d.ax1, s.d.axy, s.d.axy2, s.d.axy)
  drawline(s, 1, s.d.ax1, s.d.axy, 0.2, s.d.axy+s.d.tl)
  drawline(s, 1, s.d.axy2, s.d.axy, s.d.axy2, s.d.axy+s.d.tl)

  drawline(s, 1, s.d.ayx, s.d.ay1, s.d.ayx, s.d.axy2)
  drawline(s, 1, s.d.ayx, s.d.ay1, s.d.ayx+s.d.tl, 0.15)
  drawline(s, 1, s.d.ayx, s.d.axy2, s.d.ayx+s.d.tl, s.d.axy2)

  drawstring(s, 1, (s.d.ax1+s.d.axy2)/2., s.d.axy-2*s.d.tl, xlab, 'd')
  drawlstring(s, 1, s.d.ayx-2*s.d.tl, (s.d.ay1+s.d.axy2)/2., ylab, 'l')

  if autox
    xp = adjust(xmin,xmax)
  else
    xp = [xmin xmax 1]
  end
  if autoy
    yp = adjust(ymin,ymax)
  else
    yp = [ymin ymax 1]
  end

  ntx = xp[3]
  nty = yp[3]

  for i = 0:ntx
    d = s.d.ax1 + (s.d.axy2-s.d.ax1)*i/ntx
    drawline(s, 1, d, s.d.axy, d, s.d.axy-s.d.tl)
  end

  for i = 0:nty
    d = s.d.ay1 + (s.d.axy2-s.d.ay1)*i/nty
    drawline(s, 1, s.d.ayx, d, s.d.ayx-s.d.tl, d)
  end

  drawstring(s, 1, s.d.ax1,s.d.axy-2*s.d.tl, repr(xp[1]), 'd')
  drawstring(s, 1, s.d.axy2,s.d.axy-2*s.d.tl, repr(xp[2]), 'd')

  drawstring(s, 1, s.d.ayx-2*s.d.tl,s.d.ay1, repr(yp[1]), 'l')
  drawstring(s, 1, s.d.ayx-2*s.d.tl,s.d.axy2, repr(yp[2]), 'l')

  set(s.sx, scale(s.sx,s.d.ax1), scale(s.sx,s.d.axy2), xp[1],xp[2])
  set(s.sy, scale(s.sy,s.d.ay1), scale(s.sy,s.d.axy2), yp[1],yp[2])
end

function frame(s::Screen)
  drawline(s, 1, 0.,0., 1.,0.)
  drawline(s, 1, 0.,1., 1.,1.)
  drawline(s, 1, 0.,0., 0.,1.)
  drawline(s, 1, 1.,0., 1.,1.)
end

# Sixel functions

function csixels(b::Bitmap, eol::Bool, lc::Int, ic::Int, i::Int)
  dc = true
  k = 1

  while k<=b.nc
    c = b.planes[ic,i,k]

    j = k + 1
    while j<=b.nc
      if b.planes[ic,i,j] != c; break; end
      j += 1
    end

    n = j-k
    if n==b.nc && c=='?'; return true; end

    if eol; println('$'); eol=false; end

    if dc
      if ic!=lc
        print('#',ic-1)
        lc = ic
      end
      dc = false
    end

    if n>3
      print('!',n,Char(c))
      k = j
    else
      print(Char(c))
      k += 1
    end
  end

  false
end

function sixels(s::Screen)
  lc = -1

  println("\n\x1bPq\n");

  for i = 1:NCOL
    if s.p.colors[i].d
      print('#',i-1,';',2,';',s.p.colors[i].r,';',s.p.colors[i].g,';',s.p.colors[i].b);
    end
  end

  for i = s.b.nr:-1:1
    eol = false
    for ic = 1:NCOL
      empty = csixels(s.b,eol,lc,ic,i);
      if !empty; eol = true; end
      if ic==NCOL; println('-'); end
    end
  end

  println("\x1b\\\n");
end

function julialogo(s::Screen)
  ix = scale(s.sx,0.9)-8*21
  iy = 100

  idrawstring(s.b, s.f, 4, ix,iy, "               _")
  iy-=8

  idrawstring(s.b, s.f, 2, ix,iy, "   _")
  idrawstring(s.b, s.f, 1, ix,iy, "           _")
  idrawstring(s.b, s.f, 4, ix,iy, "              (_) ")
  idrawstring(s.b, s.f, 3, ix,iy, "             _")
  idrawstring(s.b, s.f, 5, ix,iy, "                 _")
  iy-=8

  idrawstring(s.b, s.f, 2, ix,iy, "  (_)")
  idrawstring(s.b, s.f, 1, ix,iy, "          |")
  idrawstring(s.b, s.f, 3, ix,iy, "            (_)")
  idrawstring(s.b, s.f, 5, ix,iy, "                (_)")
  iy-=8

  idrawstring(s.b, s.f, 1, ix,iy, "   _ _   _| |_  __ _");
  iy-=8
  idrawstring(s.b, s.f, 1, ix,iy, "  | | | | | | |/ _` |")
  iy-=8
  idrawstring(s.b, s.f, 1, ix,iy, "  | | |_| | | | (_| |")
  iy-=8
  idrawstring(s.b, s.f, 1, ix,iy, " _/ |\\__'_|_|_|\\__'_|")
  iy-=8
  idrawstring(s.b, s.f, 1, ix,iy, "|__/")
end

function sixelplot(x=[], y=[]; title="", xlab="x", ylab="f(x)", xsize=384, ysize=288,
                   xlim=[0,0], ylim=[0,0],
                   typ='l', pch=1, clr=2, dclr=[-1,-1,-1],
                   showsixels=true, showframe=true, showlogo=false)

  if y==[]
    y = x
    n = length(x)
    #x = linspace(1,n,n)
    x = Array{Int64,1}(1:n)
  end

  if length(x)!=length(y)
    error("input arrays have different lengths")
  end

  if rem(ysize,6)!=0
    error("ysize should be a multiple of 6")
  end

  if xlim[1]==xlim[2]
    xmin = minimum(x)
    xmax = maximum(x)
    autox = true
  else
    xmin = xlim[1]
    xmax = xlim[2]
    autox = false
  end

  if ylim[1]==ylim[2]
    ymin = minimum(y)
    ymax = maximum(y)
    autoy = true
  else
    ymin = ylim[1]
    ymax = ylim[2]
    autoy = false
  end

  if xmin>=xmax
    error("invalid values for xlim")
  end
  if ymin>=ymax
    error("invalid values for ylim")
  end

  s = Screen(xsize,ysize)
  clear(s.b, 63)

  if dclr[1]>=0
    setcolor(s.p, clr, dclr[1], dclr[2], dclr[3])
  end

  if showframe; frame(s); end
  if showlogo; julialogo(s); end

  if title!=""
    drawstring(s,1, 0.5,0.95, title, 'u')
  end

  axes(s, xlab,autox,xmin,xmax, ylab,autoy,ymin,ymax)

  drawplot(s, clr, x, y, typ, pch)

  if showsixels; sixels(s); end

  return s
end

function sixelplot(s::Screen, x=[], y=[]; typ='l', pch=2, clr=3, dclr=[-1,-1,-1], showsixels=true)
  if y==[]
    y = x
    n = length(x)
    #x = linspace(1,n,n)
    x = Array{Int64,1}(1:n)
  end
  if dclr[1]>=0
    setcolor(s.p, clr, dclr[1], dclr[2], dclr[3])
  end
  drawplot(s, clr, x, y, typ, pch)
  if showsixels; sixels(s); end
end

end # module
