
; entry:
;	rcx - size of the string
;	rsi - pointer to the current beginning of the data in the buffer
shell_prompt_relocate:
 ; save the original registers
 push rcx
 push rdi

 ; beginning of the buffer space
 mov rdi, shell_cache

 ; buffer contents at the beginning of its space?
 cmp rsi, shell_cache
 je .at_begin ; yes

 ; move the buffer contents to the beginning of the space
 rep movsb

 ; return the new pointer to the beginning of the string
 mov rsi, shell_cache

.at_begin:
 ; restore the original registers
 pop rdi
 pop rcx

 ; return from the procedure
 ret

; entry:
;	rbx - previous size of the "word"
;	r8 - current size of the string
;	rsi - pointer to the current position in the string
; exit:
;	CF flag, if the string is empty
;	registers updated
shell_prompt_clean:
 ; move the pointer past the "ip" command and decrease the number of characters in the remaining string
 add rsi, rbx
 sub r8, rbx

 ; remove the white characters from the beginning and the end of the rest of the string
 mov rcx, r8
 macro_library LIBRARY_STRUCTURE_ENTRY.string_trim

 ; save the remaining size of the command
 mov r8, rcx

.error:
 ; return from the procedure
 ret

; entry:
;	rbx - size of the command in characters
;	rsi - pointer to the command
shell_prompt_internal:
 ; save the original registers
 push rax
 push rdi
 push rcx

 ; probably the command: clear
 cmp rbx, shell_command_clear_end - shell_command_clear
 jne .no_clear ; no

 ; check for the "clear" command
 mov ecx, ebx ; size of the compared string
 mov rdi, shell_command_clear
 macro_library LIBRARY_STRUCTURE_ENTRY.string_compare
 jc .no_clear ; the strings differ

 ; send the character space clearing sequence
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, shell_string_sequence_clear_end - shell_string_sequence_clear
 mov rsi, shell_string_sequence_clear
 int KERNEL_SERVICE

 ; the command has been executed
 jmp .end

.no_clear:
 ; probably the command: exit
 cmp rbx, shell_command_exit_end - shell_command_exit
 jne .no_exit ; no

 ; check for the "exit" command
 mov ecx, ebx ; size of the compared string
 mov rdi, shell_command_exit
 macro_library LIBRARY_STRUCTURE_ENTRY.string_compare
 jc .no_exit ; the strings differ

 ; terminate the shell
 xor ax, ax
 int KERNEL_SERVICE

.no_exit:
 ; probably the command: cd
 cmp rbx, shell_command_cd_end - shell_command_cd
 jne .no_cd ; no

 ; check for the "cd" command
 mov ecx, ebx ; size of the compared string
 mov rdi, shell_command_cd
 macro_library LIBRARY_STRUCTURE_ENTRY.string_compare
 jc .no_cd ; the strings differ

 ; set the registers to the access path
 mov rcx, qword [rsp]
 sub rcx, rbx
 add rsi, rbx

 ; remove the "white characters" from the path, at the beginning and the end of the string
 macro_library LIBRARY_STRUCTURE_ENTRY.string_trim

 ; change the working directory
 mov ax, KERNEL_SERVICE_PROCESS_dir_change
 int KERNEL_SERVICE

 ; the command has been executed
 jmp .end

.no_cd:
 ; probably the command: echo
 cmp rbx, shell_command_echo_end - shell_command_echo
 jne .no_echo ; no

 ; check for the "echo" command
 mov ecx, ebx ; size of the compared string
 mov rdi, shell_command_echo
 macro_library LIBRARY_STRUCTURE_ENTRY.string_compare
 jc .no_echo ; the strings differ

 ; set the registers to the argument list
 mov rcx, qword [rsp]
 sub rcx, rbx
 add rsi, rbx

 ; remove the "white characters" from the arguments, at the beginning and the end of the string
 macro_library LIBRARY_STRUCTURE_ENTRY.string_trim

 ; the arguments are entitled to a new line, spliced over the separator so the
 ; whole line leaves in one write - the console publishes the cursor column
 ; between writes, and a stale column glues the prompt to the output
 mov byte [rsi - STATIC_BYTE_SIZE_byte], STATIC_SCANCODE_NEW_LINE
 dec rsi
 inc rcx

 ; display the arguments
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 int KERNEL_SERVICE

 ; the command has been executed
 jmp .end

.no_echo:
 cmp rbx, shell_command_kill_end - shell_command_kill
 jne .no_kill

 mov ecx, ebx
 mov rdi, shell_command_kill
 macro_library LIBRARY_STRUCTURE_ENTRY.string_compare
 jc .no_kill

 mov rcx, qword [rsp]
 sub rcx, rbx
 add rsi, rbx
 macro_library LIBRARY_STRUCTURE_ENTRY.string_trim
 jc .kill_usage

 macro_library LIBRARY_STRUCTURE_ENTRY.string_digits
 jc .kill_usage

 mov rbx, rcx
 macro_library LIBRARY_STRUCTURE_ENTRY.string_to_integer

 mov rcx, rax
 mov ax, KERNEL_SERVICE_PROCESS_kill
 int KERNEL_SERVICE
 jc .kill_denied

 clc
 jmp .end

.kill_usage:
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, shell_kill_usage_end - shell_kill_usage
 mov rsi, shell_kill_usage
 int KERNEL_SERVICE
 clc
 jmp .end

.kill_denied:
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, shell_kill_denied_end - shell_kill_denied
 mov rsi, shell_kill_denied
 int KERNEL_SERVICE
 clc
 jmp .end

.no_kill:
 cmp rbx, shell_command_help_end - shell_command_help
 jne .no_help

 mov ecx, ebx
 mov rdi, shell_command_help
 macro_library LIBRARY_STRUCTURE_ENTRY.string_compare
 jc .no_help

 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, shell_help_text_end - shell_help_text
 mov rsi, shell_help_text
 int KERNEL_SERVICE
 clc
 jmp .end

.no_help:
 cmp rbx, shell_command_pidof_end - shell_command_pidof
 jne .no_pidof

 mov ecx, ebx
 mov rdi, shell_command_pidof
 macro_library LIBRARY_STRUCTURE_ENTRY.string_compare
 jc .no_pidof

 mov r10, rsi
 mov r11, rcx

 mov ax, KERNEL_SERVICE_PROCESS_list
 int KERNEL_SERVICE
 jc .pidof_usage

 push rsi
 push rcx
 mov r8, rsi
 mov r9, rbx
 xor r15, r15

.pidof_loop:
 test r9, r9
 jz .pidof_done

 movzx ecx, byte [r8 + KERNEL_TASK_STRUCTURE_ENTRY.length]
 cmp rcx, r11
 jne .pidof_next

 mov rsi, r8
 add rsi, KERNEL_TASK_STRUCTURE_ENTRY.name
 mov rdi, r10
 macro_library LIBRARY_STRUCTURE_ENTRY.string_compare
 jc .pidof_next

 mov rax, qword [r8 + KERNEL_TASK_STRUCTURE_ENTRY.pid]
 mov rbx, STATIC_NUMBER_SYSTEM_decimal
 xor ecx, ecx
 mov dl, STATIC_SCANCODE_SPACE
 mov rdi, shell_pidof_buffer
 macro_library LIBRARY_STRUCTURE_ENTRY.integer_to_string
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov rsi, shell_pidof_buffer
 int KERNEL_SERVICE

 mov ax, KERNEL_SERVICE_PROCESS_stream_out_char
 mov ecx, 1
 mov dl, STATIC_SCANCODE_SPACE
 int KERNEL_SERVICE

 inc r15

.pidof_next:
 movzx eax, byte [r8 + KERNEL_TASK_STRUCTURE_ENTRY.length]
 lea r8, [r8 + KERNEL_TASK_STRUCTURE_ENTRY.name + rax]
 dec r9
 jmp .pidof_loop

.pidof_done:
 mov ax, KERNEL_SERVICE_PROCESS_stream_out_char
 mov ecx, 1
 mov dl, STATIC_SCANCODE_NEW_LINE
 int KERNEL_SERVICE

 pop rcx
 pop rdi
 mov ax, KERNEL_SERVICE_PROCESS_memory_release
 int KERNEL_SERVICE

 clc
 jmp .end

.pidof_usage:
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, shell_pidof_usage_end - shell_pidof_usage
 mov rsi, shell_pidof_usage
 int KERNEL_SERVICE
 clc
 jmp .end

.no_pidof:
 stc

.end:
 pop rcx
 pop rdi
 pop rax

 ret
