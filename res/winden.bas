rem input "Number of layers to render"; nl


cenx# = 4.0
ceny# = 1.0

dim pos2(15, 2) as integer
dim pos3(15, 2) as integer


rem E

pos3( 0, 0) = 2
pos3( 0, 1) = 0

pos3( 1, 0) = 0
pos3( 1, 1) = 0

pos3( 2, 0) = 1
pos3( 2, 1) = 1

pos3( 3, 0) = 0
pos3( 3, 1) = 2

pos3( 4, 0) = 2
pos3( 4, 1) = 2


rem N

pos3( 5, 0) = 3
pos3( 5, 1) = 2

pos3( 6, 0) = 3
pos3( 6, 1) = 0

pos3( 7, 0) = 5
pos3( 7, 1) = 2

pos3( 8, 0) = 5
pos3( 8, 1) = 0


rem D

pos3( 9, 0) = 6
pos3( 9, 1) = 0

pos3(10, 0) = 7
pos3(10, 1) = 0

pos3(11, 0) = 8
pos3(11, 1) = 1

pos3(12, 0) = 8
pos3(12, 1) = 2
pos3(13, 0) = 6
pos3(13, 1) = 2

pos3(14, 0) = 6
pos3(14, 1) = 0


rem ubound$(pos3,0) causes an infinite loop
rem to assign we start at index 0 but in ubound we start at index 1??

for i = 0 to ubound%(pos3, 1)
  print pos3(i, 0), pos3(i,1)
next

deg

rem ideally we'd get a variable that returns
rem the number of seconds since start,
rem so that animations can run the same on all machines

frame% = 0

gfx_sync false
while inkey <> "ESC"
    frame% = frame% + 1
    sleep 0.01
    cls

    a$ = "Winden / Capsule ^ Batman.Group"
    for i = 0 to len%(a$)
      color 8 + (((frame/4) +i) mod 7)
      locate scrcols / 2 - len(a) / 2 + i, scrrows - 2
      print mid$(a$, i, 1)
    next

    color 15
    locate 0, 0
    print "Press ESC to stop"

    rem color 4
    rem gfx_rectf 10, 50, 502, 50+288
    rem color 12
    rem gfx_rect 10, 50, 502, 50+288

    ay# = frame% * 17
    ay# = 180.0 + 210.0 * sin(ay# * 0.1)
    cy# = cos(ay#)
    sy# = sin(ay#)

    ax# = frame% * 19
    ax# = 30.0 * sin(ax# * 0.1)
    cx# = cos(ax#)
    sx# = sin(ax#)

    for i = 0 to ubound%(pos3, 1)

      x0# = pos3(i, 0) - cenx#
            y0# = pos3(i, 1) - ceny#
      z0# = 0.0

      x1# = x0# *  cy# + z0# * sy#
      y1# = y0#
      z1# = x0# * -sy# + z0# * cy#

      x2# = x1#
      y2# = y1# *  cx# + z1# * sx#
      z2# = y1# * -sx# + z1# * cx#

      zz# = 7.0 + z2#
      xx# = (10.0 + 256.5) + 256.0 * x2# / zz#
      yy# = (50.0 + 144.5 - 25.0) + 256.0 * y2# / zz#

      pos2(i, 0) = xx#
      pos2(i, 1) = yy#
    next

    ps% = 5
    for i = 0 to ubound%(pos2, 1) - 1
      if i <> 4 and i <> 8 then
        for j = 0 to 19
          xxx0% = pos2(i, 0) * j
          xxx0% = xxx0% + pos2(i+1, 0) * (20-j)
          xxx0% = xxx0% / 20

          yyy0% = pos2(i, 1) * j
          yyy0% = yyy0% + pos2(i+1, 1) * (20-j)
          yyy0% = yyy0% / 20

          xxx0% = xxx0% + 48.0 * sin#(3 * frame + yyy0%)

          xxx0% = xxx0% - ps%
          yyy0% = yyy0% - ps%
          xxx1% = xxx0% + ps% + ps%
          yyy1% = yyy0% + ps% + ps%
          color 10
          gfx_rectf xxx0% * 2, yyy0% * 2, xxx1% * 2, yyy1% * 2
        next
      end if
    next

    gfx_sync
wend
gfx_sync true
color
cls