# a demo plot with logo

using SixelGraphics

x = linspace(1,26,26)
y = -sin(x)./x

sixelplot(x,y, ylab="-sin(x)/x", typ='b', pch=-1, showlogo=true,
          clr=16, dclr=[100,65,0])
