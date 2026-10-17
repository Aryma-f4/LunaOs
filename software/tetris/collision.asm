
; entry:
;	bx - block pattern (active rotation state, low word)
;	r8 - position on the X axis (bit shift into the platform row)
;	r9 - position on the Y axis (platform row of pattern row 0)
; exit:
;	CF - set on collision, clear when the position is free
;	r8, r9, bx preserved
tetris_collision:
 ; save the original registers
 push rax
 push rbx
 push rcx
 push rdx
 push r9 ; also restored per call, keeps the entry value

 ; local variable
 push TETRIS_BRICK_STRUCTURE_height

.loop:
 ; fetch the current row of the block structure (zero-extended: ah must not
 ; leak into the shifted value — the original mov al, bl left it as garbage)
 movzx eax, bl
 and al, STATIC_BYTE_LOW_mask

 ; move the row of the block structure into the place
 mov cl, r8b
 shl ax, cl

 ; an empty row can never collide (keeps trailing gaps above the floor clean)
 test ax, ax
 jz .next

 ; cells pushed outside the playfield (bit 0 or bits 11..15)?
 mov dx, ax
 and dx, 1111100000000001b
 jnz .collision

 ; past the floor row (index 22)?
 cmp r9, TETRIS_PLAYGROUND_HEIGHT_brick
 ja .collision

 ; fetch the board space line matching the line position of the block structure
 mov rdx, tetris_brick_platform
 mov dx, word [rdx + r9 * STATIC_WORD_SIZE_byte]

 ; did a collision occur?
 test ax, dx
 jnz .collision

.next:
 ; next line of the block pattern structure
 shr bx, STATIC_MOVE_AL_HALF_TO_LOW_shift

 ; next line of the board space
 inc r9

 ; has the whole block pattern been processed?
 dec qword [rsp]
 jnz .loop ; no

 ; free position
 clc
 jmp .end

.collision:
 stc

.end:
 ; free the local variable
 pop rax

 ; restore the original registers
 pop r9
 pop rdx
 pop rcx
 pop rbx
 pop rax

 ; return from the procedure
 ret
