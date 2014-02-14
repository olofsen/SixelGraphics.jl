using SixelGraphics

# inspiration and some code from
# http://mathemartician.blogspot.nl/2012/07/julia-set-in-julia.html

function julia(z, maxiter::Int64)
    c=-0.75+0.11im
    for n = 1:maxiter
        if abs(z) > 2
            return n-1
        end
        z = z^2 + c
    end
    return maxiter
end

w = 384
h = 288

s = Screen(w,h)

clear(s.b,63)

# for every pixel
for y=1:h, x=1:w
    # translate numbers [1:w, 1:h] -> -2.5:2.5 + -1:1 im
    c = complex((x-w/2)/(h/2.5), (y-h/2)/(h/2))
    # call the julia function and plot the distance
    putpixel(s.b, div(julia(c,255),16), x-1, y-1)
end

sixels(s)
