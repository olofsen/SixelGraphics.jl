# demonstrates the use of sixelplot to add a plot
# and overriding the axes limits

using SixelGraphics

x = Array{Float64}(0:0.1:4*pi)
y1 = sin.(x)
y2 = cos.(x)

s = sixelplot(x,y1, typ='b', xlim=[-2,14])

sixelplot(s,x,y2, typ='b')
