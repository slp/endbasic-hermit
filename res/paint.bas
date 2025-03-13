width = 70
height = 50
psize = 10
offset = 40
DIM image(width, height) AS INTEGER

CLS
GFX_SYNC FALSE

k = ""
x = 0
y = 0
c = 15
p = FALSE
blink = 0
redraw = TRUE
WHILE k <> "ESC"
    k = INKEY

    IF k <> "" OR p THEN
        COLOR image(x, y)
        GFX_RECTF offset + x * psize, offset + y * psize, offset + (x + 1) * psize, offset + (y + 1) * psize
        blink = 0
    END IF

    IF k = "z" OR p THEN: image(x, y) = c: END IF

    IF k = "w" AND c < 255 THEN: c = c + 1: END IF
    IF k = "s" AND c > 0 THEN: c = c - 1: END IF
    IF k = " " THEN: p = NOT p: END IF

    IF k = "+" THEN: psize = psize + 1: redraw = TRUE: END IF
    IF k = "-" AND psize > 1 THEN: psize = psize - 1: redraw = TRUE: END IF

    IF k = "UP" AND y > 0 THEN: y = y - 1: END IF
    IF k = "DOWN" AND y < height - 1 THEN: y = y + 1: END IF
    IF k = "LEFT" AND x > 0 THEN: x = x - 1: END IF
    IF k = "RIGHT" AND x < width - 1 THEN: x = x + 1: END IF

    IF redraw THEN
        CLS
        COLOR 15
        PRINT "ESC Exit  SPC Pen up/down  ARROWS Move  W Color up  S Color down  Z Plot"
        FOR i = 0 to width - 1
            FOR j = 0 to height - 1
                COLOR image(i, j)
                GFX_RECTF offset + i * psize, offset + j * psize, offset + (i + 1) * psize, offset + (j + 1) * psize
            NEXT
        NEXT
        redraw = FALSE
        GFX_SYNC
    END IF

    IF blink < 50 THEN
        IF c = image(x, y) THEN
            COLOR 255 - c
        ELSE
                    COLOR c
        END IF
        GFX_RECTF offset + x * psize, offset + y * psize, offset + (x + 1) * psize, offset + (y + 1) * psize
    ELSE
        COLOR image(x, y)
        GFX_RECTF offset + x * psize, offset + y * psize, offset + (x + 1) * psize, offset + (y + 1) * psize
    END IF
    blink = (blink + 1) MOD 100

    COLOR 7
    GFX_RECT offset, offset, offset + width * psize, offset + height * psize

    SLEEP 0.01
    GFX_SYNC
WEND
GFX_SYNC TRUE
COLOR