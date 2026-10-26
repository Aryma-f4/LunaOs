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
; exit:
;	CF flag, if the string is not an internal command
shell_prompt_internal:
 ; save the original registers
 push rax
 push rdi
 push rcx

 cmp rbx, shell_command_clear_end - shell_command_clear
 jne .no_clear

 mov ecx, ebx
 mov rdi, shell_command_clear
 macro_library LIBRARY_STRUCTURE_ENTRY.string_compare
 jc .no_clear

 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, shell_string_sequence_clear_end - shell_string_sequence_clear
 mov rsi, shell_string_sequence_clear
 int KERNEL_SERVICE

 jmp .end

.no_clear:
 cmp rbx, shell_command_exit_end - shell_command_exit
 jne .no_exit

 mov ecx, ebx
 mov rdi, shell_command_exit
 macro_library LIBRARY_STRUCTURE_ENTRY.string_compare
 jc .no_exit

 xor ax, ax
 int KERNEL_SERVICE

.no_exit:
 cmp rbx, shell_command_cd_end - shell_command_cd
 jne .no_cd

 mov ecx, ebx
 mov rdi, shell_command_cd
 macro_library LIBRARY_STRUCTURE_ENTRY.string_compare
 jc .no_cd

 mov rcx, qword [rsp]
 sub rcx, rbx
 add rsi, rbx
 macro_library LIBRARY_STRUCTURE_ENTRY.string_trim

 mov ax, KERNEL_SERVICE_PROCESS_dir_change
 int KERNEL_SERVICE

 jmp .end

.no_cd:
 cmp rbx, shell_command_cd_end - shell_command_cd
 jne .no_echo

 mov ecx, ebx
 mov rdi, shell_command_cd
 macro_library LIBRARY_STRUCTURE_ENTRY.string_compare
 jc .no_echo

 mov rcx, qword [rsp]
 sub rcx, rbx
 add rsi, rbx
 macro_library LIBRARY_STRUCTURE_ENTRY.string_trim
 jc .cd_home

 call shell_cwd_compute

 mov ax, KERNEL_SERVICE_PROCESS_dir_change
 int KERNEL_SERVICE
 jc .cd_fail

 mov rcx, qword [rel shell_cwd_tmp_length]
 mov qword [rel shell_cwd_path_length], rcx
 mov rsi, shell_cwd_tmp
 mov rdi, shell_cwd_path
 rep movsb

 clc
 jmp .end

.cd_home:
 clc
 jmp .end

.cd_fail:
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, shell_cd_failed_end - shell_cd_failed
 mov rsi, shell_cd_failed
 int KERNEL_SERVICE
 clc
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

 ; ---------------- pidof <name> ----------------
.no_help:
 cmp rbx, shell_command_pidof_end - shell_command_pidof
 jne .no_pidof

 mov ecx, ebx
 mov rdi, shell_command_pidof
 macro_library LIBRARY_STRUCTURE_ENTRY.string_compare
 jc .no_pidof

 ; extract the name argument BEFORE iterating (fixes the previous bug)
 mov rcx, qword [rsp]
 sub rcx, rbx
 add rsi, rbx
 macro_library LIBRARY_STRUCTURE_ENTRY.string_trim
 jc .pidof_usage

 mov r10, rsi   ; r10 = start of the searched name
 mov r11, rcx   ; r11 = length of the searched name

 mov ax, KERNEL_SERVICE_PROCESS_list
 int KERNEL_SERVICE
 jc .pidof_usage

 push rsi       ; save the buffer pointer
 push rcx       ; save the buffer size
 mov r8, rsi
 mov r9, rbx

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

.pidof_next:
 movzx eax, byte [r8 + KERNEL_TASK_STRUCTURE_ENTRY.length]
 lea r8, [r8 + KERNEL_TASK_STRUCTURE_ENTRY.name + rax]
 dec r9
 jmp .pidof_loop

.pidof_done:
 ; final newline
 mov ax, KERNEL_SERVICE_PROCESS_stream_out_char
 mov ecx, 1
 mov dl, STATIC_SCANCODE_NEW_LINE
 int KERNEL_SERVICE

 ; free the process-list buffer (kernel returns size in RCX and address in RSI)
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
 cmp rbx, shell_command_mkdir_end - shell_command_mkdir
 jne .no_mkdir

 mov ecx, ebx
 mov rdi, shell_command_mkdir
 macro_library LIBRARY_STRUCTURE_ENTRY.string_compare
 jc .no_mkdir

 mov rcx, qword [rsp]
 sub rcx, rbx
 add rsi, rbx
 macro_library LIBRARY_STRUCTURE_ENTRY.string_trim
 jc .mkdir_usage

 ; the kernel allocates the data page and fills in "." and ".."
 mov dl, KERNEL_VFS_FILE_TYPE_directory
 mov ax, KERNEL_SERVICE_VFS_touch
 int KERNEL_SERVICE
 jc .mkdir_denied

 clc
 jmp .end

.mkdir_usage:
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, shell_mkdir_usage_end - shell_mkdir_usage
 mov rsi, shell_mkdir_usage
 int KERNEL_SERVICE
 clc
 jmp .end

.mkdir_denied:
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, shell_mkdir_denied_end - shell_mkdir_denied
 mov rsi, shell_mkdir_denied
 int KERNEL_SERVICE
 clc
 jmp .end

.no_mkdir:
 cmp rbx, shell_command_rm_end - shell_command_rm
 jne .no_rm

 mov ecx, ebx
 mov rdi, shell_command_rm
 macro_library LIBRARY_STRUCTURE_ENTRY.string_compare
 jc .no_rm

 mov rcx, qword [rsp]
 sub rcx, rbx
 add rsi, rbx
 macro_library LIBRARY_STRUCTURE_ENTRY.string_trim
 jc .rm_usage

 mov ax, KERNEL_SERVICE_VFS_remove
 int KERNEL_SERVICE
 jc .rm_denied

 clc
 jmp .end

.rm_usage:
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, shell_rm_usage_end - shell_rm_usage
 mov rsi, shell_rm_usage
 int KERNEL_SERVICE
 clc
 jmp .end

.rm_denied:
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, shell_rm_denied_end - shell_rm_denied
 mov rsi, shell_rm_denied
 int KERNEL_SERVICE
 clc
 jmp .end

.no_rm:
 stc

.end:
 ; restore the original registers
 pop rcx
 pop rdi
 pop rax

 ; return from the procedure
 ret
