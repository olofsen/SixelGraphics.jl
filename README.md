# SixelGraphics

A module for Julia implementing simple Sixel graphics using XTerm
(or another terminal capable of displaying Sixel graphics).
XTerm needs to be compiled with --enable-sixel-graphics, run
with the "-ti 340" option, and with sixelScrolling enabled.

The module exports:

function sixelplot(x=[], y=[]; title="", xlab="x", ylab="f(x)", xsize=384, ysize=288,
                   xlim=[0,0], ylim=[0,0],
                   typ='l', pch=1, clr=2, dclr=[0,0,0],
                   showframe=true, showlogo=false)

which returns a screen, which may be used for adding another plot:

function sixelplot(s::Screen, x=[], y=[]; typ='l', pch=2, clr=3, dclr=[-1,-1,-1])

Some inspiration was drawn from R's plot().

Sixel graphics do six lines at a time and therefore ysize has to be a
multiple of six. The console font used is eight bits heigh.

Just a few plotting characters are defined. pch=0 is a pixel, and
pch<0 plots ASCII characters starting from 'a'.

The (emulated) VT340 has a palette of 16 colors. Color 1 is used for
the frame. Parameter clr is used for the plot. The color may be
defined with parameter dcl which are the RGB colors in the range 0..100.

The file in the "test" directory provides a few examples; the output
of the first one was converted to file "logo.png".

Disclaimer: The author was just beginning to learn Julia while writing
this module.
