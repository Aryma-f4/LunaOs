
calculator_show:
 ; has the first value been confirmed?
 cmp r11b, STATIC_FALSE
 je .end ; no

 ; size of the value string
 xor edx, edx

 ; pointer to the beginning of the value string
 mov rdi, calculator_window.element_label_value_string

 ; fetch the result of the operation
 mov rax, qword [calculator_value_first]

 ; negative value?
 bt rax, STATIC_QWORD_BIT_sign
 jnc .positive ; no

 ; insert a "-" character into the value string
 mov byte [calculator_window.element_label_value_string], STATIC_SCANCODE_MINUS

 ; move the value string pointer to the next position and its size
 inc rdx
 inc rdi

 ; work with the absolute value of the number from now on
 neg rax

.positive:
 ; extract the integer part from the floating point value
 mov qword [calculator_fpu_float_result], rax
 call calculator_fpu_float_to_integer
 mov qword [calculator_fpu_precision], 4 ; maximum number of places after the comma
 call calculator_fpu_float_to_fraction ; and the fraction

.unsigned:
 ; load the integer part of the fraction
 mov rax, qword [calculator_fpu_integer]
 mov bl, STATIC_NUMBER_SYSTEM_decimal
 xor ecx, ecx
 macro_library LIBRARY_STRUCTURE_ENTRY.integer_to_string

 ; move the value string pointer past the integer part of the fraction and count the size
 add rdx, rcx
 add rdi, rcx

 ; is the fraction of the fraction empty?
 cmp qword [calculator_fpu_fraction], STATIC_EMPTY
 je .ready ; yes

 ; insert a "," character into the value string
 mov byte [rdi], ","

 ; move the value string pointer to the next position and its size
 inc rdx
 inc rdi

 ; load the integer part of the fraction
 push rdx
 mov rax, qword [calculator_fpu_fraction]
 mov bl, STATIC_NUMBER_SYSTEM_decimal
 mov rcx, qword [calculator_fpu_precision]
 mov dl, STATIC_SCANCODE_DIGIT_0
 macro_library LIBRARY_STRUCTURE_ENTRY.integer_to_string
 pop rdx

 ; move the value string pointer past the integer part of the fraction and count the size
 add rdx, rcx
 add rdi, rcx

.ready:
 ; the label can only display a limited number of characters
 mov rax, CALCULATOR_INPUT_VALUE_WIDTH_char
 cmp rdx, rax
 cmova rdx, rax

 ; update the size of the value string
 mov byte [calculator_window.element_label_value_length], dl

.end:
 ; report the procedure as successful, regardless of the internal flag state
 clc

 ; return from the procedure
 ret
