
 align STATIC_QWORD_SIZE_byte, db STATIC_NOTHING
tetris_ipc_data:
 times KERNEL_IPC_STRUCTURE.SIZE db STATIC_EMPTY

tetris_limit dq (tetris_bricks_end - tetris_bricks) / STATIC_QWORD_SIZE_byte
tetris_limit_model dq STATIC_QWORD_SIZE_byte / STATIC_WORD_SIZE_byte
tetris_seed dd 0x681560BA

 align STATIC_QWORD_SIZE_byte, db STATIC_NOTHING
tetris_window dw STATIC_EMPTY ; position on the X axis
 dw STATIC_EMPTY ; position on the Y axis
 dw TETRIS_WINDOW_WIDTH_pixel ; window width
 dw TETRIS_WINDOW_HEIGHT_pixel ; window height
 dq STATIC_EMPTY ; pointer to the window data space (filled in by Bosu)
.extra: dd STATIC_EMPTY ; size of the window data space in bytes (filled in by Bosu)
 dw LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_header | LIBRARY_BOSU_WINDOW_FLAG_border | LIBRARY_BOSU_WINDOW_FLAG_BUTTON_close
 dq STATIC_EMPTY ; window identifier (filled in by Bosu)
 db 6 ; length of the title: "Tetris" (was 5 -> showed "Tetri")
 db "Tetris                         " ; fill up to 31 bytes with STATIC_SCANCODE_SPACE characters
 dq STATIC_EMPTY ; window width in bytes (filled in by Bosu)
.elements:
.element_button_close: ; element "window close"
 db LIBRARY_BOSU_ELEMENT_TYPE_button_close
 dw .element_button_close_end - .element_button_close
 dq tetris.close
.element_button_close_end:
 ; element "playground"
.element_playground: db LIBRARY_BOSU_ELEMENT_TYPE_draw
 dw .element_playground_end - .element_playground
 dw 0 ; position on the X axis relative to the window data space
 dw LIBRARY_BOSU_HEADER_HEIGHT_pixel
 dw TETRIS_PLAYGROUND_WIDTH_pixel
 dw TETRIS_PLAYGROUND_HEIGHT_pixel ; content height, NOT window height
 dq STATIC_EMPTY ; event slot (filled in by Bosu)
.element_playground_end:
 ; element "next piece"
.element_next: db LIBRARY_BOSU_ELEMENT_TYPE_draw
 dw .element_next_end - .element_next
 dw TETRIS_PLAYGROUND_WIDTH_pixel
 dw LIBRARY_BOSU_HEADER_HEIGHT_pixel
 dw TETRIS_PANEL_WIDTH_pixel
 dw TETRIS_PANEL_NEXT_height
 dq STATIC_EMPTY
.element_next_end:
 ; element "label score"
.element_label_score: db LIBRARY_BOSU_ELEMENT_TYPE_label
 dw .element_label_score_end - .element_label_score
 dw TETRIS_PLAYGROUND_WIDTH_pixel
 dw LIBRARY_BOSU_HEADER_HEIGHT_pixel + TETRIS_PANEL_NEXT_height
 dw TETRIS_PANEL_WIDTH_pixel
 dw TETRIS_PANEL_LABEL_height
 dq STATIC_EMPTY
 db LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_default
 .element_label_score_length: db 7
 .element_label_score_string: db "SCORE 0"
 times TETRIS_PANEL_LABEL_MAX_char - 0x07 db STATIC_EMPTY
.element_label_score_end:
 ; element "label lines"
.element_label_lines: db LIBRARY_BOSU_ELEMENT_TYPE_label
 dw .element_label_lines_end - .element_label_lines
 dw TETRIS_PLAYGROUND_WIDTH_pixel
 dw LIBRARY_BOSU_HEADER_HEIGHT_pixel + TETRIS_PANEL_NEXT_height + TETRIS_PANEL_LABEL_height
 dw TETRIS_PANEL_WIDTH_pixel
 dw TETRIS_PANEL_LABEL_height
 dq STATIC_EMPTY
 db LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_default
 .element_label_lines_length: db 7
 .element_label_lines_string: db "LINES 0"
 times TETRIS_PANEL_LABEL_MAX_char - 0x07 db STATIC_EMPTY
.element_label_lines_end:
 ; element "label level"
.element_label_level: db LIBRARY_BOSU_ELEMENT_TYPE_label
 dw .element_label_level_end - .element_label_level
 dw TETRIS_PLAYGROUND_WIDTH_pixel
 dw LIBRARY_BOSU_HEADER_HEIGHT_pixel + TETRIS_PANEL_NEXT_height + TETRIS_PANEL_LABEL_height + TETRIS_PANEL_LABEL_height
 dw TETRIS_PANEL_WIDTH_pixel
 dw TETRIS_PANEL_LABEL_height
 dq STATIC_EMPTY
 db LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_default
 .element_label_level_length: db 7
 .element_label_level_string: db "LEVEL 0"
 times TETRIS_PANEL_LABEL_MAX_char - 0x07 db STATIC_EMPTY
.element_label_level_end:
 ; end of the window elements
 db STATIC_EMPTY
tetris_window_end:

 align STATIC_QWORD_SIZE_byte, db STATIC_NOTHING
tetris_bricks dq 0x0720232027002620
 dq 0x6220074022301700
 dq 0x2310360023103600
 dq 0x6600660066006600
 dq 0x1320630013206300
 dq 0x0710226047003220
 dq 0x0F0022220F002222
tetris_bricks_end:

tetris_bricks_color: ; one color per piece index, 0x00RRGGBB
 dd 0x0000FFFF ; 0 - I, cyan
 dd 0x00FFFF00 ; 1 - O, yellow
 dd 0x00800080 ; 2 - T, purple
 dd 0x0000FF00 ; 3 - S, green
 dd 0x00FF0000 ; 4 - Z, red
 dd 0x000000FF ; 5 - J, blue
 dd 0x00FFA500 ; 6 - L, orange

tetris_cell_color:
 times TETRIS_PLAYGROUND_HEIGHT_brick * TETRIS_PLAYGROUND_WIDTH_brick db STATIC_EMPTY

tetris_score_table dq 40, 100, 300, 1200 ; points per lines cleared x (level + 1)

tetris_string_title db "Tetris"
tetris_string_game_over db "Tetris - game over, press R"
tetris_string_score db "SCORE "
tetris_string_lines db "LINES "
tetris_string_level db "LEVEL "

 align STATIC_QWORD_SIZE_byte, db STATIC_NOTHING
tetris_brick_pattern dq STATIC_EMPTY ; full piece (4 rotation words), low word = active
tetris_brick_next dq STATIC_EMPTY ; pending piece for the preview, 0 = none yet
tetris_brick_piece db STATIC_EMPTY
tetris_brick_next_piece db STATIC_EMPTY
tetris_random_index db STATIC_EMPTY
tetris_game_over db STATIC_EMPTY
tetris_tick db STATIC_EMPTY ; nonzero = state changed, redraw
tetris_score dq 0
tetris_lines dq 0
tetris_level dq 0
tetris_cleared dq 0 ; lines cleared by the last settle
tetris_interval dq TETRIS_GRAVITY_initial
tetris_next_tick dq STATIC_EMPTY
tetris_position_backup_x dq STATIC_EMPTY
tetris_position_backup_y dq STATIC_EMPTY

 align STATIC_QWORD_SIZE_byte, db STATIC_NOTHING
tetris_brick_platform:
 TIMES TETRIS_PLAYGROUND_HEIGHT_brick dw 0000100000000001b
 dw 0000111111111111b
