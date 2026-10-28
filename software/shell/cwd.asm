shell_cwd_compute:
 push rax
 push rbx
 push rcx
 push rdx
 push rsi
 push rdi
 push r8
 push r9

 mov r9, rsi
 mov r8, rcx

 mov rdi, shell_cwd_tmp
 xor ebx, ebx

 test r8, r8
 jz .use_current

 cmp r8, 1
 jne .check_dotdot
 cmp byte [r9], STATIC_SCANCODE_DOT
 je .use_current

.check_dotdot:
 cmp r8, 2
 jne .check_absolute
 cmp word [r9], 0x2E2E
 je .parent

.check_absolute:
 cmp byte [r9], STATIC_SCANCODE_SLASH
 je .absolute

 mov rcx, qword [rel shell_cwd_path_length]
 test rcx, rcx
 jz .rel_no_current

 mov rsi, shell_cwd_path
 rep movsb
 mov rbx, qword [rel shell_cwd_path_length]

 cmp byte [rdi - STATIC_BYTE_SIZE_byte], STATIC_SCANCODE_SLASH
 je .rel_copy_arg

 ; no room for the separator
 cmp rbx, SHELL_CWD_MAX
 jae .rel_copy_arg

 mov byte [rdi], STATIC_SCANCODE_SLASH
 inc rdi
 inc rbx

.rel_copy_arg:
 ; never write past shell_cwd_tmp
 mov rax, SHELL_CWD_MAX
 sub rax, rbx
 cmp r8, rax
 jbe .rel_copy_arg_room
 mov r8, rax

.rel_copy_arg_room:
 mov rcx, r8
 mov rsi, r9
 rep movsb
 add rbx, r8
 jmp .strip_trailing

.rel_no_current:
 mov byte [rdi], STATIC_SCANCODE_SLASH
 inc rdi
 inc rbx
 jmp .rel_copy_arg

.absolute:
 mov rcx, r8
 mov rsi, r9
 rep movsb
 mov rbx, r8

.strip_trailing:
 cmp rbx, 1
 jbe .done
 cmp byte [rdi - STATIC_BYTE_SIZE_byte], STATIC_SCANCODE_SLASH
 jne .done
 dec rdi
 dec rbx
 jmp .strip_trailing

.use_current:
 mov rcx, qword [rel shell_cwd_path_length]
 test rcx, rcx
 jz .use_current_root
 mov rsi, shell_cwd_path
 rep movsb
 mov rbx, qword [rel shell_cwd_path_length]
 jmp .done

.use_current_root:
 mov byte [rdi], STATIC_SCANCODE_SLASH
 inc rdi
 mov rbx, 1
 jmp .done

.parent:
 ; rbx tracks the offset of the last separator, so it never needs the
 ; full address of shell_cwd_path (an immediate would lose the base)
 mov rbx, qword [rel shell_cwd_path_length]
 cmp rbx, 1
 jbe .parent_root

.parent_walk:
 dec rbx
 jz .parent_root ; the leading separator is the parent
 mov rsi, shell_cwd_path
 add rsi, rbx
 cmp byte [rsi], STATIC_SCANCODE_SLASH
 jne .parent_walk

 mov rcx, rbx
 mov rsi, shell_cwd_path
 rep movsb
 jmp .done

.parent_root:
 mov byte [rdi], STATIC_SCANCODE_SLASH
 inc rdi
 mov rbx, 1
 jmp .done

.done:
 mov qword [rel shell_cwd_tmp_length], rbx

 pop r9
 pop r8
 pop rdi
 pop rsi
 pop rdx
 pop rcx
 pop rbx
 pop rax

 ret
