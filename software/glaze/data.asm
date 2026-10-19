align STATIC_QWORD_SIZE_byte, db STATIC_NOTHING
glaze_window dw STATIC_EMPTY ; position on the X axis
 dw STATIC_EMPTY ; position on the Y axis
 dw GLAZE_WINDOW_WIDTH_pixel ; window width
 dw GLAZE_WINDOW_HEIGHT_pixel ; window height
 dq STATIC_EMPTY ; pointer to the window data space (filled in by Bosu)
.extra: dd STATIC_EMPTY ; size of the window data space in bytes (filled in by Bosu)
 dw LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_border | LIBRARY_BOSU_WINDOW_FLAG_BUTTON_close | LIBRARY_BOSU_WINDOW_FLAG_BUTTON_min
 dq STATIC_EMPTY ; window identifier (filled in by Bosu)
 db 5
 db "Glaze                          " ; fill up to 31 bytes with STATIC_SCANCODE_SPACE characters
 dq STATIC_EMPTY ; window data space width in bytes (filled in by Bosu)
.elements:
 ; element "window close"
.element_button_close: db LIBRARY_BOSU_ELEMENT_TYPE_button_close
 dw .element_button_close_end - .element_button_close
 dq glaze.close
.element_button_close_end:
 ; element "window minimize"
.element_button_minimize: db LIBRARY_BOSU_ELEMENT_TYPE_button_minimize
 dw .element_button_minimize_end - .element_button_minimize
 dq glaze.minimize
.element_button_minimize_end:
 ; end of the window elements
 db STATIC_EMPTY
glaze_window_end:

 align STATIC_QWORD_SIZE_byte, db STATIC_NOTHING
glaze_ipc_data:
 times KERNEL_IPC_STRUCTURE.SIZE db STATIC_EMPTY