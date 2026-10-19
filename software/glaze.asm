%include "software/glaze/config.asm"

glaze:
 ; create the window
 mov rsi, glaze_window
 macro_library LIBRARY_STRUCTURE_ENTRY.bosu
 jc glaze.close ; not enough memory space

 ; display the contents of the window
 mov al, KERNEL_WM_WINDOW_update
 mov rsi, glaze_window
 or qword [rsi + LIBRARY_BOSU_STRUCTURE_WINDOW.SIZE + LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.flags], LIBRARY_BOSU_WINDOW_FLAG_flush
 int KERNEL_WM_IRQ

.loop:
 ; fetch the message
 mov ax, KERNEL_SERVICE_PROCESS_ipc_receive
 mov rdi, glaze_ipc_data
 int KERNEL_SERVICE
 jc .sleep ; no message

 ; message of the pointing device (mouse) type?
 cmp byte [rdi + KERNEL_IPC_STRUCTURE.type], KERNEL_IPC_TYPE_MOUSE
 jne .sleep ; no, ignore

 ; left mouse button press?
 cmp byte [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_IPC_STRUCTURE_DATA_MOUSE.event], KERNEL_IPC_MOUSE_EVENT_left_press
 jne .sleep ; no, ignore

 ; fetch the cursor coordinates
 movzx r8d, word [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_IPC_STRUCTURE_DATA_MOUSE.x] ; x
 movzx r9d, word [rdi + KERNEL_IPC_STRUCTURE.data + KERNEL_IPC_STRUCTURE_DATA_MOUSE.y] ; y

 ; fetch the pointer to the element taking part in the event
 mov rsi, glaze_window
 macro_library LIBRARY_STRUCTURE_ENTRY.bosu_element
 jc .sleep ; no element at this position

 ; element of the "Button Close" type?
 cmp byte [rsi], LIBRARY_BOSU_ELEMENT_TYPE_button_close
 je glaze.close ; yes, terminate the program

 ; element of the "Button Minimize" type?
 cmp byte [rsi], LIBRARY_BOSU_ELEMENT_TYPE_button_minimize
 je glaze.minimize ; yes, hide the window

.sleep:
 ; free the remaining processor time
 mov ax, KERNEL_SERVICE_PROCESS_sleep
 xor ecx, ecx ; no waiting in time
 int KERNEL_SERVICE

 ; return to the main loop
 jmp .loop

.minimize:
 ; hide the window, keep the process running
 mov al, KERNEL_WM_WINDOW_minimize
 mov rsi, glaze_window
 int KERNEL_WM_IRQ

 ; return to the main loop
 jmp .loop

.close:
 ; terminate the program
 xor ax, ax
 int KERNEL_SERVICE

 macro_debug "software: glaze"

 %include "software/glaze/data.asm"