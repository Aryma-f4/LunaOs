
; exit:
;	rbx - size of the whole string in bytes
;	rcx - size of the first "word" in bytes
;	rsi - pointer to the string
shell_input:
 cmp word [rdi + CONSOLE_STRUCTURE_STREAM_META.x], STATIC_EMPTY
 je .no_newline

 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, shell_string_prompt_newline_end - shell_string_prompt_newline
 mov rsi, shell_string_prompt_newline
 int KERNEL_SERVICE

.no_newline:
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, shell_string_prompt_newline_end - shell_string_prompt_newline
 mov rsi, shell_string_prompt_newline
 int KERNEL_SERVICE

 ; print prompt prefix color
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, shell_string_prompt_prefix_end - shell_string_prompt_prefix
 mov rsi, shell_string_prompt_prefix
 int KERNEL_SERVICE

 ; print current working directory
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov rcx, qword [rel shell_cwd_path_length]
 mov rsi, shell_cwd_path
 int KERNEL_SERVICE

 ; print prompt suffix
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 mov ecx, shell_string_prompt_suffix_end - shell_string_prompt_suffix
 mov rsi, shell_string_prompt_suffix
 int KERNEL_SERVICE

.continue:
 ; fetch the command from the user
 mov rbx, SHELL_CACHE_SIZE_byte ; maximum buffer size
 xor ecx, ecx ; the buffer is empty
 mov rdx, shell_event ; handling of the exceptions that occurred
 mov rsi, shell_cache ; location of the buffer in the process space
 mov rdi, shell_ipc_data ; location of the process space for the incoming exceptions
 macro_library LIBRARY_STRUCTURE_ENTRY.input
 jc shell.restart ; the buffer is empty or the input was interrupted

 ; remove the white characters from the beginning and the end of the buffer
 macro_library LIBRARY_STRUCTURE_ENTRY.string_trim
 jc shell.restart ; the buffer contained only "white characters"

 ; move the buffer contents to its beginning (if there were "white characters" at its beginning)
 call shell_prompt_relocate

 ; fetch the size of the first "word" in the string
 mov al, STATIC_SCANCODE_SPACE ; separator
 macro_library LIBRARY_STRUCTURE_ENTRY.string_word_next
