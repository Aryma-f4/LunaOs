
 fetch_file_hostname db "/etc/hostname"
 fetch_file_hostname_end:

 fetch_string_unit_kib db " KiB"
 fetch_string_unit_kib_end:

 align STATIC_QWORD_SIZE_byte, db STATIC_NOTHING
 fetch_stream_meta: dw STATIC_EMPTY ; width
  dw STATIC_EMPTY ; height
  dw STATIC_EMPTY ; x
  dw STATIC_EMPTY ; y

 align STATIC_QWORD_SIZE_byte, db STATIC_NOTHING
 fetch_window dw STATIC_EMPTY ; position on the X axis
  dw STATIC_EMPTY ; position on the Y axis
  dw FETCH_WINDOW_WIDTH_pixel ; window width
  dw FETCH_WINDOW_HEIGHT_pixel ; window height
  dq STATIC_EMPTY ; pointer to the window data space (filled in by Bosu)
 .extra: dd STATIC_EMPTY ; size of the window data space in bytes (filled in by Bosu)
  dw LIBRARY_BOSU_WINDOW_FLAG_visible | LIBRARY_BOSU_WINDOW_FLAG_header | LIBRARY_BOSU_WINDOW_FLAG_border | LIBRARY_BOSU_WINDOW_FLAG_BUTTON_close
  dq STATIC_EMPTY ; window identifier (filled in by Bosu)
  db 5
  db "Fetch                          " ; fill up to 31 bytes with STATIC_SCANCODE_SPACE characters
  dq STATIC_EMPTY ; window data space width in bytes (filled in by Bosu)
 .elements:
  ; element "window close"
 .element_button_close: db LIBRARY_BOSU_ELEMENT_TYPE_button_close
  dw .element_button_close_end - .element_button_close
  dq fetch.close
 .element_button_close_end:
  ; element "operating system"
 .element_os: db LIBRARY_BOSU_ELEMENT_TYPE_label
  dw .element_os_end - .element_os
  dw FETCH_WINDOW_LABEL_X_pixel
  dw FETCH_WINDOW_LABEL_Y_first + 0x00 * FETCH_WINDOW_LABEL_Y_step
  dw FETCH_WINDOW_LABEL_WIDTH_pixel
  dw FETCH_WINDOW_LABEL_HEIGHT_pixel
  dq STATIC_EMPTY ; no action
  db LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_default
 .element_os_length: db .element_os_string_end - .element_os_string
 .element_os_string: db "OS:       LunaOs"
 .element_os_string_end:
 .element_os_end:
  ; element "name of the machine"
 .element_host: db LIBRARY_BOSU_ELEMENT_TYPE_label
  dw .element_host_end - .element_host
  dw FETCH_WINDOW_LABEL_X_pixel
  dw FETCH_WINDOW_LABEL_Y_first + 0x01 * FETCH_WINDOW_LABEL_Y_step
  dw FETCH_WINDOW_LABEL_WIDTH_pixel
  dw FETCH_WINDOW_LABEL_HEIGHT_pixel
  dq STATIC_EMPTY ; no action
  db LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_default
 .element_host_length: db FETCH_WINDOW_LABEL_PREFIX_length_byte
 .element_host_string: db "Host:     "
  times FETCH_WINDOW_VALUE_LENGTH_byte db STATIC_EMPTY
 .element_host_end:
  ; element "system uptime"
 .element_uptime: db LIBRARY_BOSU_ELEMENT_TYPE_label
  dw .element_uptime_end - .element_uptime
  dw FETCH_WINDOW_LABEL_X_pixel
  dw FETCH_WINDOW_LABEL_Y_first + 0x02 * FETCH_WINDOW_LABEL_Y_step
  dw FETCH_WINDOW_LABEL_WIDTH_pixel
  dw FETCH_WINDOW_LABEL_HEIGHT_pixel
  dq STATIC_EMPTY ; no action
  db LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_default
 .element_uptime_length: db FETCH_WINDOW_LABEL_PREFIX_length_byte
 .element_uptime_string: db "Uptime:   "
  times FETCH_WINDOW_VALUE_LENGTH_byte db STATIC_EMPTY
 .element_uptime_end:
  ; element "total size of the RAM memory"
 .element_memory: db LIBRARY_BOSU_ELEMENT_TYPE_label
  dw .element_memory_end - .element_memory
  dw FETCH_WINDOW_LABEL_X_pixel
  dw FETCH_WINDOW_LABEL_Y_first + 0x03 * FETCH_WINDOW_LABEL_Y_step
  dw FETCH_WINDOW_LABEL_WIDTH_pixel
  dw FETCH_WINDOW_LABEL_HEIGHT_pixel
  dq STATIC_EMPTY ; no action
  db LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_default
 .element_memory_length: db FETCH_WINDOW_LABEL_PREFIX_length_byte
 .element_memory_string: db "Memory:   "
  times FETCH_WINDOW_VALUE_LENGTH_byte db STATIC_EMPTY
 .element_memory_end:
  ; element "size of the terminal"
 .element_terminal: db LIBRARY_BOSU_ELEMENT_TYPE_label
  dw .element_terminal_end - .element_terminal
  dw FETCH_WINDOW_LABEL_X_pixel
  dw FETCH_WINDOW_LABEL_Y_first + 0x04 * FETCH_WINDOW_LABEL_Y_step
  dw FETCH_WINDOW_LABEL_WIDTH_pixel
  dw FETCH_WINDOW_LABEL_HEIGHT_pixel
  dq STATIC_EMPTY ; no action
  db LIBRARY_BOSU_ELEMENT_LABEL_FLAG_ALIGN_default
 .element_terminal_length: db FETCH_WINDOW_LABEL_PREFIX_length_byte
 .element_terminal_string: db "Terminal: "
  times FETCH_WINDOW_VALUE_LENGTH_byte db STATIC_EMPTY
 .element_terminal_end:
  ; end of the window elements
  db STATIC_EMPTY
 fetch_window_end:
