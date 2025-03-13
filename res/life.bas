' Copyright 2024 Julio Merino
'
' Licensed under the Apache License, Version 2.0 (the "License"); you may not
' use this file except in compliance with the License.  You may obtain a copy
' of the License at:
'
'     http://www.apache.org/licenses/LICENSE-2.0
'
' Unless required by applicable law or agreed to in writing, software
' distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
' WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
' License for the specific language governing permissions and limitations
' under the License.

on error goto @error

small = gfx_width < 200
if small then
    cellsize = 10
    boardtop = 0
    boardleft = 0
else
    cellsize = 10
    boardtop = 50
    boardleft = 20
end if
boardw = (gfx_width - boardleft * 2) / cellsize
boardh = (gfx_height - boardtop - boardleft) / cellsize
dim board1(boardw + 2, boardh + 2) as integer
dim board2(boardw + 2, boardh + 2) as integer
gen = 0
curx = 1
cury = 1
auto = false

gfx_sync false
gosub @draw
gosub @showcursor
gfx_sync
do
    select case inkey
        case "ESC"
            exit do
        case "LEFT"
            gosub @clearcursor
            if curx > 1 then curx = curx - 1
            gosub @showcursor
            gfx_sync
        case "UP"
            gosub @clearcursor
            if cury > 1 then cury = cury - 1
            gosub @showcursor
            gfx_sync
        case "RIGHT"
            gosub @clearcursor
            if curx < boardw then curx = curx + 1
                        gosub @showcursor
            gfx_sync
        case "DOWN"
            gosub @clearcursor
            if cury < boardh then cury = cury + 1
            gosub @showcursor
            gfx_sync
        case " ", "ENTER"
            board1(curx, cury) = (board1(curx, cury) + 1) mod 2
            gosub @showcursor
            gfx_sync
        case "e", "E", "1"
            gosub @iterate
            gosub @draw
            gosub @showcursor
            gfx_sync
        case "p", "P", "2"
            gosub @populate
            gosub @draw
            gosub @showcursor
            gfx_sync
        case "c", "C", "3"
            gosub @clear
            gosub @draw
            gosub @showcursor
            gfx_sync
        case "g", "G"
            auto = not auto
        case else
            if auto then
                gosub @iterate
                gosub @draw
                gfx_sync
            else
                sleep 0.1
            end if
    end select
loop
color
gfx_sync true
end

@error
color
gfx_sync true
print "ERROR: "; errmsg
end 1

@clear
for y = 1 to boardh
    for x = 1 to boardw
        board1(x, y) = 0
    next
next
return

@populate
density = boardw * 0.1
for i = 0 to (density * boardh)
    x = int(rnd() * (boardw - 1))
    y = int(rnd() * (boardh - 1))
    board1(x + 1, y + 1) = 1
next
return

@draw
cls
if not small then
    color 13
    print "EndBASIC - Game of life - Generation "; ltrim(str(gen))
    print "ESC Exit  ARROWS Move  SPC Toggle  E Evolve  P Populate  C Clear  G Go"
end if

' Draw the grid first.
color 12
x1 = boardleft
x2 = x1 + boardw * cellsize
for y = 1 to boardh + 1
    y12 = boardtop + (y - 1) * cellsize
    gfx_line x1, y12, x2, y12
next
y1 = boardtop
y2 = y1 + boardh * cellsize
for x = 1 to boardw + 1
    x12 = boardleft + (x - 1) * cellsize
    gfx_line x12, y1, x12, y2
next

' Draw the cells.
color 15
for y = 1 to boardh
    y1 = boardtop + (y - 1) * cellsize
    for x = 1 to boardw
        x1 = boardleft + (x - 1) * cellsize

        if board1(x, y) = 1 then
            x2 = x1 + cellsize
            y2 = y1 + cellsize
            gfx_rectf x1 + 1, y1 + 1, x2 - 1, y2 - 1
        end if
    next
next
return

@drawcursor
x1 = boardleft + (curx - 1) * cellsize
y1 = boardtop + (cury - 1) * cellsize
x2 = x1 + cellsize
y2 = y1 + cellsize
gfx_rectf x1 + 1, y1 + 1, x2 - 1, y2 - 1
return

@clearcursor
if board1(curx, cury) = 0 then
    color 0
else
    color 15
end if
gosub @drawcursor
return

@showcursor
if board1(curx, cury) = 0 then
    color 13
else
    color 14
end if
gosub @drawcursor
return

@iterate
for y = 1 to boardh
    above = board1(0, y - 1) + board1(1, y - 1)
    below = board1(0, y + 1) + board1(1, y + 1)
    for x = 1 to boardw
        above = above + board1(x + 1, y - 1)
        below = below + board1(x + 1, y + 1)
        alive = above + below + board1(x - 1, y) + board1(x + 1, y)
        select case alive
            case is < 2
                board2(x, y) = 0
            case 2
                board2(x, y) = board1(x, y)
            case 3
                board2(x, y) = 1
            case is > 3
                board2(x, y) = 0
        end select
        above = above - board1(x - 1, y - 1)
        below = below - board1(x - 1, y + 1)
    next
next

for y = 1 to boardh
    for x = 1 to boardw
        board1(x, y) = board2(x, y)
    next
next

gen = gen + 1

return