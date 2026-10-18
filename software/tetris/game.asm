
; start a new game: empty board, zeroed counters, default title
tetris_reset:
 push rax
 push rcx
 push rdi
 push rsi

 ; empty platform with walls
 mov rdi, tetris_brick_platform
 mov ax, 0000100000000001b
 mov ecx, TETRIS_PLAYGROUND_HEIGHT_brick
 rep stosw
 ; floor
 mov ax, 0000111111111111b
 stosw

 ; clear the cell colors
 mov rdi, tetris_cell_color
 xor eax, eax
 mov ecx, TETRIS_PLAYGROUND_HEIGHT_brick * TETRIS_PLAYGROUND_WIDTH_brick
 rep stosb

 ; state
 mov qword [tetris_score], STATIC_EMPTY
 mov qword [tetris_lines], STATIC_EMPTY
 mov qword [tetris_level], STATIC_EMPTY
 mov qword [tetris_interval], TETRIS_GRAVITY_initial
 mov qword [tetris_brick_pattern], STATIC_EMPTY
 mov qword [tetris_brick_next], STATIC_EMPTY
 mov byte [tetris_brick_piece], STATIC_EMPTY
 mov byte [tetris_brick_next_piece], STATIC_EMPTY
 mov byte [tetris_game_over], STATIC_EMPTY
 mov byte [tetris_tick], 0x01

 ; default title
 mov ecx, 0x06
 mov rsi, tetris_string_title
 mov rdi, tetris_window
 macro_library LIBRARY_STRUCTURE_ENTRY.bosu_header_set

 pop rsi
 pop rdi
 pop rcx
 pop rax
 ret

; place the active piece and refresh the preview
tetris_spawn:
 push rax
 push rbx

 ; promote the pending piece, if any (0 only before the first spawn)
 mov rax, qword [tetris_brick_next]
 test rax, rax
 jz .generate
 mov qword [tetris_brick_pattern], rax
 mov al, byte [tetris_brick_next_piece]
 mov byte [tetris_brick_piece], al
 jmp .preview

.generate:
 call tetris_random_block ; rbx - full pattern, [tetris_random_index] - piece
 mov qword [tetris_brick_pattern], rbx
 mov al, byte [tetris_random_index]
 mov byte [tetris_brick_piece], al

.preview:
 call tetris_random_block
 mov qword [tetris_brick_next], rbx
 mov al, byte [tetris_random_index]
 mov byte [tetris_brick_next_piece], al

 ; starting position of the block
 mov r8, TETRIS_BRICK_START_POSITION_x
 mov r9, TETRIS_BRICK_START_POSITION_y

 mov byte [tetris_tick], 0x01

 pop rbx
 pop rax
 ret

; entry: dl - shift on the X axis (signed), dh - shift on the Y axis (signed)
; exit: CF - set when blocked, clear when moved (and tick set)
tetris_try_move:
 push rax
 push rbx

 ; remember the original position
 mov qword [tetris_position_backup_x], r8
 mov qword [tetris_position_backup_y], r9

 ; trial position
 movsx rax, dl
 add r8, rax
 movsx eax, dh ; dh is not encodable with the REX.W form (becomes spl)
 add r9, rax

 ; free at the trial position?
 mov bx, word [tetris_brick_pattern]
 call tetris_collision
 jnc .moved

 ; blocked: restore the original position
 mov r8, qword [tetris_position_backup_x]
 mov r9, qword [tetris_position_backup_y]
 stc
 jmp .end

.moved:
 mov byte [tetris_tick], 0x01
 clc

.end:
 pop rbx
 pop rax
 ret

tetris_try_rotate:
 push rax
 push rbx

 ; the original state
 mov rax, qword [tetris_brick_pattern]

 ; next rotation state (4 words = 4 states, cycling)
 rol qword [tetris_brick_pattern], 16

 ; free after rotating?
 mov bx, word [tetris_brick_pattern]
 call tetris_collision
 jnc .rotated

 ; restore the original state
 mov qword [tetris_brick_pattern], rax
 stc
 jmp .end

.rotated:
 mov byte [tetris_tick], 0x01
 clc

.end:
 pop rbx
 pop rax
 ret

; write the resting piece into the platform and the color board
tetris_lock:
 push rax
 push rbx
 push rcx
 push rdx
 push rsi
 push rdi

 mov rsi, qword [tetris_brick_pattern] ; walking copy
 xor ecx, ecx                         ; row inside the piece (0..3)

.row:
 mov rdi, tetris_brick_platform ; rebuilt per row — the column loop clobbers rdi
 mov rax, rsi
 and rax, STATIC_BYTE_LOW_mask

 ; matching platform row
 mov rdx, r9
 add rdx, rcx

 ; empty row or below the playable area: nothing to write
 test rax, rax
 jz .next
 cmp rdx, TETRIS_PLAYGROUND_HEIGHT_brick - 1
 ja .next

 ; OR the cells into the platform word (shift counts go through cl)
 mov rbx, rax
 push rcx
 mov cl, r8b
 shl rbx, cl
 pop rcx
 or word [rdi + rdx * STATIC_WORD_SIZE_byte], bx

 ; and their colors (columns = platform bits 1..10 -> indexes 0..9)
 xor ebx, ebx
.column:
 bt rax, rbx
 jnc .column_next

 mov rdi, r8
 add rdi, rbx
 dec rdi
 cmp rdi, TETRIS_PLAYGROUND_WIDTH_brick - 1
 ja .column_next

 ; rdx still holds the previous cell's index — rebuild the row (rdx is dead between cells)
 mov rdx, r9
 add rdx, rcx
 imul rdx, TETRIS_PLAYGROUND_WIDTH_brick
 add rdx, rdi
 push rax
 movzx eax, byte [tetris_brick_piece]
 inc eax
 mov rdi, tetris_cell_color ; rdi (column) is dead here — register base again
 mov byte [rdi + rdx], al
 pop rax

.column_next:
 inc rbx
 cmp rbx, TETRIS_BRICK_STRUCTURE_width
 jb .column

.next:
 shr rsi, STATIC_MOVE_AL_HALF_TO_LOW_shift
 inc rcx
 cmp rcx, TETRIS_BRICK_STRUCTURE_height
 jb .row

 pop rdi
 pop rsi
 pop rdx
 pop rcx
 pop rbx
 pop rax
 ret

; lock the piece and move the game on to the next one
tetris_settle:
 call tetris_lock
 call tetris_spawn
 ret

; re-arm the gravity timer: next_tick = now + interval
tetris_timer_next:
 push rax
 push rcx
 mov ax, KERNEL_SERVICE_SYSTEM_time
 int KERNEL_SERVICE
 mov ecx, dword [tetris_interval]
 add eax, ecx
 mov dword [tetris_next_tick], eax
 pop rcx
 pop rax
 ret
