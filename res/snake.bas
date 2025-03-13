REM Copyright 2022 Julio Merino
REM
REM Licensed under the Apache License, Version 2.0 (the "License"); you may not
REM use this file except in compliance with the License.  You may obtain a copy
REM of the License at:
REM
REM     http://www.apache.org/licenses/LICENSE-2.0
REM
REM Unless required by applicable law or agreed to in writing, software
REM distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
REM WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
REM License for the specific language governing permissions and limitations
REM under the License.

REM
REM Snake game.
REM

' Customization variables.
CELL_SIZE = 20
PUT_OBSTACLES_EVERY = 5
SPEED = 10

' Constants for the types of cells in the board.
CELL_EMPTY = 0
CELL_WALL = 1
CELL_FOOD = 2
CELL_PLAYER = 3

' Initialize the board.
ON ERROR GOTO @nographics
pad_top = CELL_SIZE * 2
pad_right = CELL_SIZE
pad_bottom = CELL_SIZE
pad_left = CELL_SIZE
bg = 4
cols = int((GFX_WIDTH - pad_left - pad_right) / CELL_SIZE)
rows = int((GFX_HEIGHT - pad_top - pad_bottom) / CELL_SIZE)
DIM board(rows, cols)
ON ERROR GOTO 0

' Entry point.  Game can be restarted on loss from here.
@retry

FOR r = 0 TO rows - 1
    FOR c = 0 TO cols - 1
        board(r, c) = CELL_EMPTY
    NEXT
NEXT

' Start with an empty board that only contains a surrounding box.
FOR r = 0 TO rows - 1
    board(r, 0) = 1
    board(r, cols - 1) = CELL_WALL
NEXT
FOR c = 0 TO cols - 1
    board(0, c) = 1
    board(rows - 1, c) = CELL_WALL
NEXT

GFX_SYNC FALSE
headx = cols / 2
heady = rows / 2
deltax = 1
deltay = 0

tailx = headx
taily = heady
length = 2
cell = 0
dx = deltax: dy = deltay: GOSUB @encodeplayer: board(heady, headx) = cell
headx = headx + deltax

max_length = length
cycles = 0
cell_type = 2: GOSUB @putcell
COLOR 0, bg
CLS
GOSUB @drawboard
c = 10: title = "Current length:" + STR(length): GOSUB @drawtitle
DO
    SELECT CASE INKEY
        CASE "UP"
            IF deltay <> 1 THEN
                deltax = 0: deltay = -1
            END IF
        CASE "DOWN"
            IF deltay <> -1 THEN
                deltax = 0: deltay = 1
            END IF
        CASE "LEFT"
            IF deltax <> 1 THEN
                deltax = -1: deltay = 0
            END IF
        CASE "RIGHT"
            IF deltax <> -1 THEN
                deltax = 1: deltay = 0
            END IF
        CASE "ESC", "Q", "q"
            EXIT DO
    END SELECT

    GFX_SYNC

    IF cycles = SPEED THEN
        next_cell = board(heady + deltay, headx + deltax)
        SELECT CASE next_cell
            CASE CELL_EMPTY
                cell = board(taily, tailx): GOSUB @decodeplayer
                board(taily, tailx) = CELL_EMPTY
                y = taily: x = tailx: GOSUB @drawcell
                taily = taily + dy
                tailx = tailx + dx

            CASE CELL_FOOD
                length = length + 1
                c = 10: title = "Current length:" + STR(length): GOSUB @drawtitle

                cell_type = CELL_FOOD: GOSUB @putcell
                IF PUT_OBSTACLES_EVERY > 0 AND length MOD PUT_OBSTACLES_EVERY = 0 THEN
                    cell_type = CELL_WALL: GOSUB @putcell
                END IF

            CASE ELSE
                IF length > max_length THEN max_length = length
                COLOR 9
                c = 9: title = "Game over -- ENTER to retry, Q to exit": GOSUB @drawtitle
                GFX_SYNC
                DO
                    SELECT CASE INKEY
                        CASE "ENTER"
                            GOTO @retry
                        CASE "ESC", "Q", "q"
                            CLS
                            GOTO @end
                    END SELECT
                    REM SLEEP 0.01
                LOOP
        END SELECT

        dx = deltax: dy = deltay: GOSUB @encodeplayer: board(heady, headx) = cell
        y = heady: x = headx: GOSUB @drawcell
        headx = headx + deltax
        heady = heady + deltay
        dx = deltax: dy = deltay: GOSUB @encodeplayer: board(heady, headx) = cell
        y = heady: x = headx: GOSUB @drawcell
        cycles = 0
    END IF
    cycles = cycles + 1

    REM SLEEP 0.01
LOOP

@end
COLOR
CLS
GFX_SYNC TRUE
IF ERRMSG <> "" THEN PRINT ERRMSG
PRINT "Maximum length achieved:"; max_length
END

@nographics
COLOR 9
PRINT "Sorry, this game requires a console with graphics support"
COLOR
END

@drawtitle
COLOR bg
GFX_RECTF 0, 0, GFX_WIDTH, pad_top - 1
l = LEN(title)
LOCATE SCRCOLS / 2 - l / 2, 0
COLOR c, bg
PRINT title
RETURN

@drawboard
FOR r = 0 TO rows - 1
    FOR c = 0 TO cols - 1
        x = c: y = r: GOSUB @drawcell
    NEXT
NEXT
RETURN

@drawcell
cell = board(y, x) AND &x_00ff

x1 = pad_left + x * CELL_SIZE
y1 = pad_top + y * CELL_SIZE
x2 = x1 + CELL_SIZE
y2 = y1 + CELL_SIZE

SELECT CASE cell
    CASE CELL_EMPTY
        COLOR 233
        GFX_RECT x1, y1, x2, y2
        COLOR 234
        GFX_RECTF x1 + 1, y1 + 1, x2 - 1, y2 - 1

    CASE CELL_WALL
        COLOR 250
        GFX_RECT x1 + 1, y1 + 1, x2 - 1, y2 - 1
        COLOR 255
        GFX_RECTF x1 + 2, y1 + 2, x2 - 2, y2 - 2
        COLOR 245
        GFX_RECT x1, y1, x2, y2
        GFX_LINE x1 + 1, y1 + 1, x2 - 1, y2 - 1
        GFX_LINE x1 + 1, y2 + 1, x2 - 1, y1 + 1

    CASE CELL_FOOD
        COLOR 234
        GFX_RECTF x1 + 1, y1 + 1, x2 - 1, y2 - 1
        COLOR 13
        radius = CELL_SIZE / 2
        GFX_CIRCLEF pad_left + x * CELL_SIZE + radius, pad_top + y * CELL_SIZE + radius, radius - 3

    CASE CELL_PLAYER
        COLOR 14
        GFX_RECTF x1 + 1, y1 + 1, x2 - 1, y2 - 1
END SELECT
RETURN

@putcell
DO
    x = INT(RND(1) * cols)
    y = INT(RND(1) * rows)
    IF board(y, x) = 0 THEN
            board(y, x) = cell_type
        EXIT DO
    END IF
LOOP
GOSUB @drawcell
RETURN

@encodeplayer
cell = 3
SELECT CASE dx
    CASE -1: cell = cell OR &x_0100
    CASE  0: cell = cell OR &x_0200
    CASE  1: cell = cell OR &x_0400
    CASE ELSE: PRINT "ERROR encode dx": GOTO @end
END SELECT
SELECT CASE dy
    CASE -1: cell = cell OR &x_1000
    CASE  0: cell = cell OR &x_2000
    CASE  1: cell = cell OR &x_4000
    CASE ELSE: PRINT "ERROR encode dy": GOTO @end
END SELECT
RETURN

@decodeplayer
SELECT CASE cell AND &x_0f00
    CASE &x_0100: dx = -1
    CASE &x_0200: dx = 0
    CASE &x_0400: dx = 1
    CASE ELSE: PRINT "ERROR decode dx"; cell: GOTO @end
END SELECT
SELECT CASE cell AND &x_f000
    CASE &x_1000: dy = -1
    CASE &x_2000: dy = 0
    CASE &x_4000: dy = 1
    CASE ELSE: PRINT "ERROR decode dy"; cell: GOTO @end
END SELECT
RETURN