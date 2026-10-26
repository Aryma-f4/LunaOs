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

 mov byte [rdi], STATIC_SCANCODE_SLASH
 inc rdi
 inc rbx

.rel_copy_arg:
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
 mov rcx, qword [rel shell_cwd_path_length]
 test rcx, rcx
 jz .parent_root
 cmp rcx, 1
 je .parent_root

  mov rsi, shell_cwd_path
 add rsi, rcx
 dec rsi

.parent_walk:
 cmp byte [rsi], STATIC_SCANCODE_SLASH
 je .parent_found
 dec rsi
 jmp .parent_walk

.parent_found:
 mov rcx, rsi
 sub rcx, shell_cwd_path
 test rcx, rcx
 jz .parent_root
 mov rbx, rcx
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
