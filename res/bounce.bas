on error goto @nographics

input "Number of dots to render"; n

dim pos(n, 2) as integer
dim off(n, 2) as integer

for i = 0 to n - 1
    pos(i, 0) = 50 + rnd() * 690.0
    pos(i, 1) = 50 + rnd() * 490.0
    while off(i, 0) = 0
        off(i, 0) = 5 - rnd() * 10.0
    wend
    while off(i, 1) = 0
        off(i, 1) = 5 - rnd() * 10.0
    wend
next

gfx_sync false
while inkey <> "ESC"
    cls
    color 15
    locate 25, 26
    print "Bouncing"; n; "dots! Press ESC to stop"
    color 4
    gfx_rectf 100, 100, 700, 500
    color 15
    gfx_rect 99, 99, 701, 501

    for i = 0 to n - 1
        x = pos(i, 0) + off(i, 0)
        if x < 100 then
            x = 100
            off(i, 0) = -off(i, 0)
        elseif x > 690 then
            x = 690
            off(i, 0) = -off(i, 0)
        end if

        y = pos(i, 1) + off(i, 1)
        if y < 100 then
            y = 100
            off(i, 1) = -off(i, 1)
        elseif y > 490 then
            y = 490
            off(i, 1) = -off(i, 1)
        end if

        color i mod 255
        gfx_rectf x, y, x + 10, y + 10

        pos(i, 0) = x
        pos(i, 1) = y
    next

    gfx_sync
    wend
color
cls
goto @end

@nographics
color
cls
print "No graphics support in this console"

@end
gfx_sync true