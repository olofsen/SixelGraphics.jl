# demonstrates the use of just an y argument

using SixelGraphics

x = Array{Float64}(0:0.1:6*pi)
y = sin.(x)

s = sixelplot(y, typ='b')
