ON ERROR GOTO @end
sw = GFX_WIDTH
sh = GFX_HEIGHT

brick_width = 50
brick_height = 20

bricks_rows = 8
bricks_cols = sw / brick_width

player_x = sw / 2
player_width = 100
player_y = 550
player_height = 15

ball_x = player_x
ball_y = player_y - player_height - 5
ball_r = 8

DIM board(bricks_rows, bricks_cols) AS INTEGER
FOR i = LBOUND(board, 1) + 2 TO UBOUND(board, 1)
    FOR j = LBOUND(board, 2) TO UBOUND(board, 2)
        board(i, j) = 1 + INT(RND(1) * 255)
    NEXT
NEXT

ON ERROR GOTO @end
GFX_SYNC FALSE

GOSUB @draw

ball_moving = FALSE
ball_off_x = 1
ball_off_y = -2

DO
    SELECT CASE INKEY
        CASE "ESC", "q", "Q": EXIT DO

        CASE " "
            ball_moving = TRUE

        CASE "LEFT"
            x = -10: y = 0: GOSUB @moveplayer
            IF NOT ball_moving THEN
                GOSUB @clearball
                ball_x = ball_x - 10
                GOSUB @drawball
            END IF

        CASE "RIGHT"
            x = 10: y = 0: GOSUB @moveplayer
            IF NOT ball_moving THEN
                GOSUB @clearball
                ball_x = ball_x + 10
                GOSUB @drawball
            END IF
    END SELECT

    IF ball_moving THEN
        next_x = ball_x + ball_off_x
        next_y = ball_y + ball_off_y
        IF next_x - ball_r <= 0 THEN ball_off_x = -ball_off_x
        IF next_x + ball_r >= sw THEN ball_off_x = -ball_off_x
        IF next_y - ball_r <= 0 THEN ball_off_y = -ball_off_y
        IF next_y + ball_r >= sh THEN
            GOSUB @clearball
            ball_x = player_x
            ball_y = player_y - player_height - 5
            GOSUB @drawball
            ball_moving = FALSE
            ball_off_x = 1
            ball_off_y = -2
        END IF

        IF next_y + ball_r >= player_y - player_height / 2 THEN
            IF next_x + ball_r > player_x - player_width / 2 AND next_x - ball_r < player_x + player_width / 2 THEN
                ball_off_y = -ball_off_y
            END IF
        END IF

        brick_i = next_y / brick_height
        brick_j = next_x / brick_width
        IF brick_i <= UBOUND(board, 1) AND brick_j <= UBOUND(board, 2) THEN
            IF board(brick_i, brick_j) <> 0 THEN
                board(brick_i, brick_j) = 0
                i = brick_i: j = brick_j: GOSUB @drawbrick
                ball_off_y = -ball_off_y
            END IF
        END IF

        GOSUB @clearball
        ball_x = ball_x + ball_off_x
        ball_y = ball_y + ball_off_y
        GOSUB @drawball
    END IF

    SLEEP 0.005

    GFX_SYNC
LOOP

@end
GFX_SYNC TRUE
CLS
COLOR
IF ERRMSG <> "" THEN PRINT ERRMSG
END

'
' Paints the main scene from scratch.
'
@draw
CLS
FOR i = LBOUND(board, 1) TO UBOUND(board, 1)
    FOR j = LBOUND(board, 2) TO UBOUND(board, 2)
        GOSUB @drawbrick
    NEXT
NEXT
x = 0: y = 0: GOSUB @moveplayer
GOSUB @drawball
'COLOR 15: LOCATE 0, 0: PRINT "SPC - Start  Q - Exit"
t = "Arkanoid clone in less than 200 lines of EndBASIC code!"
COLOR 15: LOCATE SCRCOLS / 2 - LEN(t) / 2, 0: PRINT t
RETURN

'
' Paints the brick with data at `i,j`.
'

@drawbrick
y = i * brick_height
x = j * brick_width
c = board(i, j)
COLOR c
GFX_RECTF x + 1, y + 1, x + brick_width - 1, y + brick_height - 1
IF c <> 0 THEN
    COLOR 15
    GFX_LINE x + 1, y + 1, x + brick_width - 1, y + 1
    GFX_RECTF x + 1, y + 1, x + 1, y + brick_height - 1
    'COLOR 1
    'GFX_RECTF x + brick_width - 1, y + 1, x + brick_width - 1, y + brick_height - 1
    'GFX_RECTF x + 1, y + brick_height - 1, x + brick_width - 1, y + brick_height - 1
END IF
RETURN

'
' Draws the ball at the recorded (ball_x, ball_y) coordinates.
'
@drawball
COLOR 7
GFX_CIRCLEF ball_x, ball_y, ball_r - 1
COLOR 15
GFX_CIRCLEF ball_x, ball_y, ball_r - 3
RETURN

'
' Clears the ball at the recorded (ball_x, ball_y) coordinates.
'
@clearball
COLOR 0
GFX_CIRCLEF ball_x, ball_y, ball_r
RETURN

'
' Clears the player, updates its coordinates based on the `x` and `y` offsets,
' and draws the player again.
'
@moveplayer

w = player_width / 2
h = player_height / 2

COLOR 0
GFX_RECTF player_x - w, player_y - h, player_x + w, player_y + h

player_x = player_x + x
player_y = player_y + y

COLOR 15
GFX_RECTF player_x - w, player_y - h, player_x + w, player_y + h

RETURN