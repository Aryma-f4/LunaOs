
; fill a rectangle of the window data area
; entry: r8 - X, r9 - Y, r10 - width, r11 - height, r12 - color (0x00RRGGBB)
tetris_fill:
 push rax
 push rbx
 push rcx
 push rdx
 push rdi

 ; start = address + Y * scanline + X * 4
 mov eax, dword [tetris_window + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline_byte]
 mul r9d
 mov rdi, rax
 mov rax, r8
 shl rax, KERNEL_VIDEO_DEPTH_shift
 add rdi, rax
 add rdi, qword [tetris_window + LIBRARY_BOSU_STRUCTURE_WINDOW.address]

 mov rdx, r11 ; height counter
.row:
 mov rcx, r10 ; width counter
 mov rax, r12
 rep stosd

 ; step to the next scanline: scanline - width * 4
 mov eax, dword [tetris_window + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline_byte]
 mov rbx, r10
 shl rbx, KERNEL_VIDEO_DEPTH_shift
 sub rax, rbx
 add rdi, rax

 dec rdx
 jnz .row

 pop rdi
 pop rdx
 pop rcx
 pop rbx
 pop rax
 ret

; full redraw of the game state, then flush + window update
tetris_draw:
 push rax
 push rbx
 push rcx
 push rdx
 push rsi
 push rdi
 push r8
 push r9
 push r10
 push r11
 push r12
 push r13
 push r14

 ; r8/r9 are the live piece position — keep copies before they become
 ; fill arguments (the cell loops below reuse r8/r9 freely)
 mov r13, r8
 mov r14, r9

 ; ---- playground background (also clears the previous piece) ----
 movzx r8, word [tetris_window.element_playground + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
 movzx r9, word [tetris_window.element_playground + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
 movzx r10, word [tetris_window.element_playground + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
 movzx r11, word [tetris_window.element_playground + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
 mov r12, LIBRARY_BOSU_WINDOW_BACKGROUND_color
 call tetris_fill

 ; ---- locked cells ----
 mov rdi, tetris_cell_color ; absolute index needs a register base (disp32 would truncate)
 mov rsi, tetris_bricks_color
 mov rcx, TETRIS_PLAYGROUND_HIDDEN_brick ; first visible row (2)
.cell_row:
 xor ebx, ebx ; column 0..9
.cell_col:
 ; index = row * 10 + column
 mov rax, rcx
 imul rax, TETRIS_PLAYGROUND_WIDTH_brick
 add rax, rbx
 movzx eax, byte [rdi + rax]
 test eax, eax
 jz short .cell_next
 dec eax ; palette index
 mov r12d, dword [rsi + rax * 4]

 movzx r8, word [tetris_window.element_playground + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
 mov rax, rbx
 imul rax, TETRIS_BRICK_WIDTH_pixel + TETRIS_BRICK_PADDING_pixel
 add r8, rax
 movzx r9, word [tetris_window.element_playground + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
 mov rax, rcx
 sub rax, TETRIS_PLAYGROUND_HIDDEN_brick
 imul rax, TETRIS_BRICK_HEIGHT_pixel + TETRIS_BRICK_PADDING_pixel
 add r9, rax
 mov r10, TETRIS_BRICK_WIDTH_pixel
 mov r11, TETRIS_BRICK_HEIGHT_pixel
 call tetris_fill
.cell_next:
 inc rbx
 cmp rbx, TETRIS_PLAYGROUND_WIDTH_brick
 jb .cell_col
 inc rcx
 cmp rcx, TETRIS_PLAYGROUND_HEIGHT_brick
 jb .cell_row

 ; ---- active piece ----
 cmp byte [tetris_game_over], STATIC_EMPTY
 je short .piece_draw
 jmp .preview ; frozen board: the colliding piece is not drawn
.piece_draw:

 ; r13/r14 already hold the live position (saved in the prologue)
 movzx esi, word [tetris_brick_pattern]
 xor ecx, ecx ; pattern row 0..3
.piece_row:
 mov rdx, r14
 add rdx, rcx ; platform row of this pattern row
 cmp rdx, TETRIS_PLAYGROUND_HIDDEN_brick
 jb short .piece_next ; hidden rows live above the header — never draw them

 xor ebx, ebx ; cell 0..3
.piece_col:
 bt rsi, rbx
 jnc short .piece_col_next

 ; playfield column = x + cell - 1
 mov rdi, r13
 add rdi, rbx
 dec rdi

 movzx r8, word [tetris_window.element_playground + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
 mov rax, rdi
 imul rax, TETRIS_BRICK_WIDTH_pixel + TETRIS_BRICK_PADDING_pixel
 add r8, rax
 movzx r9, word [tetris_window.element_playground + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
 mov rax, rdx
 sub rax, TETRIS_PLAYGROUND_HIDDEN_brick
 imul rax, TETRIS_BRICK_HEIGHT_pixel + TETRIS_BRICK_PADDING_pixel
 add r9, rax
 mov r10, TETRIS_BRICK_WIDTH_pixel
 mov r11, TETRIS_BRICK_HEIGHT_pixel
 movzx eax, byte [tetris_brick_piece]
 mov rdi, tetris_bricks_color ; rdi (column) is dead here — register base again
 mov r12d, dword [rdi + rax * 4]
 call tetris_fill

.piece_col_next:
 inc rbx
 cmp rbx, TETRIS_BRICK_STRUCTURE_width
 jb .piece_col
.piece_next:
 shr rsi, STATIC_MOVE_AL_HALF_TO_LOW_shift
 inc rcx
 cmp rcx, TETRIS_BRICK_STRUCTURE_height
 jb .piece_row

.preview:
 ; ---- next piece area ----
 movzx r8, word [tetris_window.element_next + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
 movzx r9, word [tetris_window.element_next + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
 movzx r10, word [tetris_window.element_next + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.width]
 movzx r11, word [tetris_window.element_next + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.height]
 mov r12, LIBRARY_BOSU_WINDOW_BACKGROUND_color
 call tetris_fill

 ; 4x4 tiles (28 px) centred in the 70x64 area: offsets 21 / 18
 movzx esi, word [tetris_brick_next]
 mov rdi, tetris_bricks_color ; register base (disp32 would truncate)
 xor ecx, ecx
.next_row:
 xor ebx, ebx
.next_col:
 bt rsi, rbx
 jnc short .next_col_next

 movzx r8, word [tetris_window.element_next + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.x]
 mov rax, rbx
 imul rax, TETRIS_BRICK_WIDTH_pixel + TETRIS_BRICK_PADDING_pixel
 add rax, 0x15 ; (70 - 28) / 2 = 21
 add r8, rax
 movzx r9, word [tetris_window.element_next + LIBRARY_BOSU_STRUCTURE_TYPE.SIZE + LIBRARY_BOSU_STRUCTURE_ELEMENT.field + LIBRARY_BOSU_STRUCTURE_FIELD.y]
 mov rax, rcx
 imul rax, TETRIS_BRICK_HEIGHT_pixel + TETRIS_BRICK_PADDING_pixel
 add rax, 0x12 ; (64 - 28) / 2 = 18
 add r9, rax
 mov r10, TETRIS_BRICK_WIDTH_pixel
 mov r11, TETRIS_BRICK_HEIGHT_pixel
 movzx eax, byte [tetris_brick_next_piece]
 mov r12d, dword [rdi + rax * 4]
 call tetris_fill

.next_col_next:
 inc rbx
 cmp rbx, TETRIS_BRICK_STRUCTURE_width
 jb .next_col
 shr rsi, STATIC_MOVE_AL_HALF_TO_LOW_shift
 inc rcx
 cmp rcx, TETRIS_BRICK_STRUCTURE_height
 jb .next_row

 ; ---- labels ----
 ; SCORE
 mov rdi, tetris_window.element_label_score_string
 mov rsi, tetris_string_score
 mov rcx, TETRIS_LABEL_PREFIX_length
 rep movsb
 mov rax, qword [tetris_score]
 cmp rax, 99999
 jbe short .score_fit
 mov rax, 99999 ; keep prefix + value inside the 11-byte buffer
.score_fit:
 mov rbx, STATIC_NUMBER_SYSTEM_decimal
 mov rcx, STATIC_EMPTY
 mov dl, STATIC_SCANCODE_DIGIT_0
 mov rdi, tetris_window.element_label_score_string + TETRIS_LABEL_PREFIX_length
 macro_library LIBRARY_STRUCTURE_ENTRY.integer_to_string
 add cl, TETRIS_LABEL_PREFIX_length
 mov byte [tetris_window.element_label_score_length], cl
 mov rsi, tetris_window.element_label_score
 mov rdi, tetris_window
 macro_library LIBRARY_STRUCTURE_ENTRY.bosu_element_label

 ; LINES
 mov rdi, tetris_window.element_label_lines_string
 mov rsi, tetris_string_lines
 mov rcx, TETRIS_LABEL_PREFIX_length
 rep movsb
 mov rax, qword [tetris_lines]
 cmp rax, 99999
 jbe short .lines_fit
 mov rax, 99999
.lines_fit:
 mov rbx, STATIC_NUMBER_SYSTEM_decimal
 mov rcx, STATIC_EMPTY
 mov dl, STATIC_SCANCODE_DIGIT_0
 mov rdi, tetris_window.element_label_lines_string + TETRIS_LABEL_PREFIX_length
 macro_library LIBRARY_STRUCTURE_ENTRY.integer_to_string
 add cl, TETRIS_LABEL_PREFIX_length
 mov byte [tetris_window.element_label_lines_length], cl
 mov rsi, tetris_window.element_label_lines
 mov rdi, tetris_window
 macro_library LIBRARY_STRUCTURE_ENTRY.bosu_element_label

 ; LEVEL
 mov rdi, tetris_window.element_label_level_string
 mov rsi, tetris_string_level
 mov rcx, TETRIS_LABEL_PREFIX_length
 rep movsb
 mov rax, qword [tetris_level]
 cmp rax, 99999
 jbe short .level_fit
 mov rax, 99999
.level_fit:
 mov rbx, STATIC_NUMBER_SYSTEM_decimal
 mov rcx, STATIC_EMPTY
 mov dl, STATIC_SCANCODE_DIGIT_0
 mov rdi, tetris_window.element_label_level_string + TETRIS_LABEL_PREFIX_length
 macro_library LIBRARY_STRUCTURE_ENTRY.integer_to_string
 add cl, TETRIS_LABEL_PREFIX_length
 mov byte [tetris_window.element_label_level_length], cl
 mov rsi, tetris_window.element_label_level
 mov rdi, tetris_window
 macro_library LIBRARY_STRUCTURE_ENTRY.bosu_element_label

 ; ---- push the whole frame to the screen ----
 mov al, KERNEL_WM_WINDOW_update
 mov rsi, tetris_window
 or qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags], LIBRARY_BOSU_WINDOW_FLAG_flush
 int KERNEL_WM_IRQ

 pop r14
 pop r13
 pop r12
 pop r11
 pop r10
 pop r9
 pop r8
 pop rdi
 pop rsi
 pop rdx
 pop rcx
 pop rbx
 pop rax
 ret
