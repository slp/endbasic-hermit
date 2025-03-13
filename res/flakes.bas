sw = GFX_WIDTH
sh = GFX_HEIGHT
sr = SCRROWS
sc = SCRCOLS

DIM flakes(50, 2)
' flakes(i) = (y, r)
FOR i = 0 TO UBOUND(flakes, 1)
    flakes(i, 0) = INT(RND(1) * sh)
    flakes(i, 1) = INT(RND(1) * 30) + 5
NEXT

DIM ground(sw)

GFX_SYNC FALSE
ON ERROR GOTO @end

WHILE INKEY = ""
    COLOR , 17
    CLS

    FOR i = 0 TO UBOUND(flakes, 1)
        x = sw / UBOUND(flakes, 1) * i
        y = flakes(i, 0)
        r = flakes(i, 1)
        GFX_LINE x, y - r, x, y + r
        GFX_LINE x - r, y, x + r, y
        GFX_LINE x - r + 5, y - r + 5, x + r - 5, y + r - 5
        GFX_LINE x + r - 5, y - r + 5, x - r + 5, y + r - 5

        IF y > sh + r THEN
            y = - INT(RND(1) * 30) + 5
            IF x > r AND x < sw - r THEN
                FOR j = x - r TO x + r
                    ground(j) = ground(j) + 3
                NEXT
            END IF
            flakes(i, 1) = -y
        ELSE
            y = y + 1
        END IF
        flakes(i, 0) = y
    NEXT

    FOR x = 0 to UBOUND(ground)
        h = ground(x)
        GFX_LINE x, sh, x, sh - h
    NEXT

    COLOR 27

    bx1 = sw / 2 - 200
    by1 = sh / 2 - 80
    bx2 = sw / 2 + 200
    by2 = sh / 2 + 80
    GFX_RECTF bx1, by1, bx2, by2
    COLOR , 27
        FOR i = 0 TO 5
        GFX_RECT bx1 + i, by1 + i, bx2 - i, by2 - i
    NEXT

    msg = "Happy holidays..."
    LOCATE sc / 2 - LEN(msg) / 2, sr / 2 - 2
    PRINT msg

    msg = "and have a great 2024!"
    LOCATE sc / 2 - LEN(msg) / 2, sr / 2 - 1
    PRINT msg

    msg = "Press ESC to explore"
    LOCATE sc / 2 - LEN(msg) / 2, sr / 2 + 2
    PRINT msg

    'SLEEP 0.01
    GFX_SYNC
WEND

@end
'IF ERRMSG <> 0 THEN PRINT ERRMSG
COLOR
CLS
GFX_SYNC TRUE