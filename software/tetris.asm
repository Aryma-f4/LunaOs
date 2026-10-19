 %include "software/tetris/config.asm"

tetris:
 ; create the window
 mov rsi, tetris_window
 macro_library LIBRARY_STRUCTURE_ENTRY.bosu
 jc tetris.close ; not enough memory space

 ; start a new game and render it once
 call tetris_reset
 call tetris_spawn
 call tetris_timer_next
 call tetris_draw
 mov byte [tetris_tick], STATIC_EMPTY

.loop:
 ; check the incoming events (keyboard: CF clear, key in dx;
 ; mouse actions incl. the close button are handled inside the macro)
 mov rsi, tetris_window
 macro_library LIBRARY_STRUCTURE_ENTRY.bosu_event
 jc .timer ; no key

 ; apply the key
 call tetris_input

.timer:
 ; frozen after a game over (Task 4 sets the flag)
 cmp byte [tetris_game_over], STATIC_EMPTY
 jne .render

 ; gravity due?
 mov ax, KERNEL_SERVICE_SYSTEM_time
 int KERNEL_SERVICE
 cmp eax, dword [tetris_next_tick]
 jb .render ; not yet

 ; re-arm, fall one row (or settle when blocked)
 call tetris_timer_next
 xor edx, edx
 mov dh, 0x01
 call tetris_try_move
 jnc .render
 call tetris_settle

.render:
 ; redraw only when the state changed
 cmp byte [tetris_tick], STATIC_EMPTY
 je .loop
 mov byte [tetris_tick], STATIC_EMPTY
 call tetris_draw
 jmp .loop

 ; ---- input ----
 ; entry: dx - key code
tetris_input:
 push rax

 ; after a game over only a restart is accepted
 cmp byte [tetris_game_over], STATIC_EMPTY
 jne .over_state

 cmp dx, STATIC_SCANCODE_LEFT
 je .left
 cmp dx, STATIC_SCANCODE_RIGHT
 je .right
 cmp dx, STATIC_SCANCODE_UP
 je .up
 cmp dx, STATIC_SCANCODE_DOWN
 je .down
 cmp dx, STATIC_SCANCODE_SPACE
 je .drop
 jmp .end ; unknown key (incl. releases): ignore

.left:
 mov dl, -0x01
 xor dh, dh
 call tetris_try_move
 jmp .end

.right:
 mov dl, 0x01
 xor dh, dh
 call tetris_try_move
 jmp .end

.up:
 call tetris_try_rotate
 jmp .end

.down:
 xor edx, edx
 mov dh, 0x01
 call tetris_try_move
 jnc .retime
 call tetris_settle ; resting against the stack: lock immediately
.retime:
 call tetris_timer_next
 jmp .end

.drop:
 xor edx, edx
 mov dh, 0x01
.hard:
 call tetris_try_move
 jnc .hard ; keep falling
 call tetris_settle
 jmp .end

.over_state:
 cmp dx, "r"
 je .restart
 cmp dx, "R"
 je .restart
 cmp dx, STATIC_SCANCODE_RETURN
 jne .end

.restart:
 call tetris_reset
 call tetris_spawn
 call tetris_timer_next

.end:
 pop rax
 ret

tetris.minimize:
 ; hide the window, the process keeps running
 mov al, KERNEL_WM_WINDOW_minimize
 mov rsi, tetris_window
 int KERNEL_WM_IRQ

 ; return from the action handler procedure
 ret

tetris.close:
 ; terminate the program
 xor ax, ax
 int KERNEL_SERVICE

 macro_debug "software: tetris"

 %include "software/tetris/data.asm"
 %include "software/tetris/random.asm"
 %include "software/tetris/collision.asm"
 %include "software/tetris/game.asm"
 %include "software/tetris/draw.asm"
