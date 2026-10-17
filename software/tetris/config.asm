
 ; constants, variables, globals, structures, objects, macros
 %include "software/header.asm"

 %define PROGRAM_NAME "tetris"
 %define PROGRAM_VERSION "0.1"

TETRIS_BRICK_START_POSITION_x equ 6
TETRIS_BRICK_START_POSITION_y equ 0

TETRIS_BRICK_STRUCTURE_width equ 4
TETRIS_BRICK_STRUCTURE_height equ 4

TETRIS_BRICK_PADDING_pixel equ 1
TETRIS_BRICK_WIDTH_pixel equ 6
TETRIS_BRICK_HEIGHT_pixel equ 6

TETRIS_PLAYGROUND_WIDTH_brick equ 10
TETRIS_PLAYGROUND_HEIGHT_brick equ 22
TETRIS_PLAYGROUND_HIDDEN_brick equ 2

TETRIS_PLAYGROUND_WIDTH_pixel equ TETRIS_PLAYGROUND_WIDTH_brick * (TETRIS_BRICK_WIDTH_pixel + TETRIS_BRICK_PADDING_pixel)
TETRIS_PLAYGROUND_HEIGHT_pixel equ (TETRIS_PLAYGROUND_HEIGHT_brick - TETRIS_PLAYGROUND_HIDDEN_brick) * (TETRIS_BRICK_HEIGHT_pixel + TETRIS_BRICK_PADDING_pixel)

TETRIS_PANEL_WIDTH_pixel equ TETRIS_PLAYGROUND_WIDTH_pixel
TETRIS_PANEL_NEXT_height equ 64
TETRIS_PANEL_LABEL_height equ 16
TETRIS_PANEL_LABEL_MAX_char equ 11 ; 70 px / 6 px font
TETRIS_LABEL_PREFIX_length equ 6   ; "SCORE ", "LINES ", "LEVEL "

; declared window = header + content; Bosu adds 2 * border thickness itself
; and sizes the data buffer from THIS number — it must equal the element
; extent, or draws run past the buffer (the skeleton's 140 overran by 17 rows)
TETRIS_WINDOW_WIDTH_pixel equ TETRIS_PLAYGROUND_WIDTH_pixel + TETRIS_PANEL_WIDTH_pixel
TETRIS_WINDOW_HEIGHT_pixel equ LIBRARY_BOSU_HEADER_HEIGHT_pixel + TETRIS_PLAYGROUND_HEIGHT_pixel

TETRIS_GRAVITY_initial equ 1024 ; level 0: one row per second (1024 ticks)
TETRIS_GRAVITY_step equ 102     ; ticks removed per level
TETRIS_GRAVITY_minimum equ 102  ; floor: 0.1 s per row
