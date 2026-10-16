
 %include "software/fetch/config.asm"

fetch:
 ; complete the "stream" table with the properties of the output stream
 call fetch_stream_info

 ; display the operating system
 mov rsi, fetch_string_os
 mov ecx, fetch_string_os_end - fetch_string_os
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 int KERNEL_SERVICE

 ; display the remaining properties of the system
 call fetch_host
 call fetch_uptime
 call fetch_memory
 call fetch_terminal

 ; terminate the program
 xor ax, ax
 int KERNEL_SERVICE

 ; fetch the properties of the output stream
fetch_stream_info:
 ; ask about the output stream
 mov ax, KERNEL_SERVICE_PROCESS_stream_meta
 mov bl, KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_get | KERNEL_SERVICE_PROCESS_STREAM_META_FLAG_out
 mov ecx, CONSOLE_STRUCTURE_STREAM_META.SIZE
 mov rdi, fetch_stream_meta
 int KERNEL_SERVICE
 jc fetch_stream_info ; no current information

 ; return from the procedure
 ret

 ; display the name of the machine
fetch_host:
 ; load the content of the file
 mov ax, KERNEL_SERVICE_VFS_read
 mov ecx, fetch_file_hostname_end - fetch_file_hostname
 mov rsi, fetch_file_hostname
 int KERNEL_SERVICE
 jc .end ; the file does not exist

 ; set the pointer to the name of the machine
 mov rsi, rdi

 ; remove the white characters from the beginning and the end of the name
 macro_library LIBRARY_STRUCTURE_ENTRY.string_trim
 jc .end ; the file was empty

 ; remove the new line character from the end of the name
 cmp byte [rsi + rcx - STATIC_BYTE_SIZE_byte], STATIC_SCANCODE_NEW_LINE
 jne .limit
 dec rcx

.limit:
 ; limit the size of the name to the size of the line
 cmp rcx, FETCH_VALUE_LENGTH_byte
 jbe .display
 mov ecx, FETCH_VALUE_LENGTH_byte

.display:
 ; set the pointer to the end of the static part of the line
 mov rdi, fetch_string_host + FETCH_STRING_PREFIX_length_byte

 ; display the name of the machine
 rep movsb

 ; display the line
 mov rsi, fetch_string_host
 call fetch_line

.end:
 ; return from the procedure
 ret

 ; display the system uptime
fetch_uptime:
 ; fetch the number of system ticks
 mov ax, KERNEL_SERVICE_SYSTEM_time
 int KERNEL_SERVICE

 ; convert the number of ticks into seconds
 xor edx, edx
 mov ecx, 1024
 div rcx

 ; set the pointer to the end of the static part of the line
 mov rdi, fetch_string_uptime + FETCH_STRING_PREFIX_length_byte

 ; convert the number of hours
 xor edx, edx
 mov ecx, 60*60
 div rcx
 push rdx ; save the number of remaining seconds
 mov ecx, 0x02
 mov dl, "0"
 call fetch_number

 ; separator
 mov al, ":"
 stosb

 ; convert the number of minutes
 pop rax
 xor edx, edx
 mov ecx, 60
 div rcx
 push rdx ; save the number of remaining seconds
 mov ecx, 0x02
 mov dl, "0"
 call fetch_number

 ; separator
 mov al, ":"
 stosb

 ; convert the number of seconds
 pop rax
 mov ecx, 0x02
 mov dl, "0"
 call fetch_number

 ; display the line
 mov rsi, fetch_string_uptime
 call fetch_line

 ; return from the procedure
 ret

 ; display the total size of the RAM memory
fetch_memory:
 ; fetch the memory status of the system
 mov ax, KERNEL_SERVICE_SYSTEM_memory
 int KERNEL_SERVICE

 ; convert the number of pages into KiB
 mov rax, r8
 shl rax, STATIC_MULTIPLE_BY_4_shift

 ; set the pointer to the end of the static part of the line
 mov rdi, fetch_string_memory + FETCH_STRING_PREFIX_length_byte

 ; convert the value into a string of characters
 xor ecx, ecx
 mov dl, STATIC_EMPTY
 call fetch_number

 ; append the unit of the value
 mov rsi, fetch_string_unit_kib
 mov rcx, fetch_string_unit_kib_end - fetch_string_unit_kib
 rep movsb

 ; display the line
 mov rsi, fetch_string_memory
 call fetch_line

 ; return from the procedure
 ret

 ; display the size of the terminal
fetch_terminal:
 ; set the pointer to the end of the static part of the line
 mov rdi, fetch_string_terminal + FETCH_STRING_PREFIX_length_byte

 ; convert the width of the terminal into a string of characters
 movzx eax, word [fetch_stream_meta + CONSOLE_STRUCTURE_STREAM_META.width]
 xor ecx, ecx
 mov dl, STATIC_EMPTY
 call fetch_number

 ; separator
 mov al, "x"
 stosb

 ; convert the height of the terminal into a string of characters
 movzx eax, word [fetch_stream_meta + CONSOLE_STRUCTURE_STREAM_META.height]
 xor ecx, ecx
 mov dl, STATIC_EMPTY
 call fetch_number

 ; display the line
 mov rsi, fetch_string_terminal
 call fetch_line

 ; return from the procedure
 ret

 ; entry:
 ;	rsi - pointer to the beginning of the line
 ;	rdi - pointer to the end of the line
fetch_line:
 ; end of the line
 mov al, STATIC_SCANCODE_NEW_LINE
 stosb

 ; size of the line
 mov rcx, rdi
 sub rcx, rsi

 ; display the line
 mov ax, KERNEL_SERVICE_PROCESS_stream_out
 int KERNEL_SERVICE

 ; return from the procedure
 ret

 ; entry:
 ;	rax - value
 ;	rcx - number of characters of the value, filled up with the "dl" character
 ;	dl - character filling up the value
 ;	rdi - pointer to the string of characters
 ; exit:
 ;	rdi - pointer to the end of the string of characters
fetch_number:
 ; number base: decimal
 mov rbx, STATIC_NUMBER_SYSTEM_decimal

 ; convert the value into a string of characters
 macro_library LIBRARY_STRUCTURE_ENTRY.integer_to_string

 ; move the pointer past the value
 add rdi, rcx

 ; return from the procedure
 ret

 macro_debug "software: fetch"

 %include "software/fetch/data.asm"
