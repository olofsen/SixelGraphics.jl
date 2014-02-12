# demonstrates the use of just an y argument

using SixelGraphics

x = linspace(0,6*pi)
y = sin(x)

s = sixelplot(y, typ='b')
