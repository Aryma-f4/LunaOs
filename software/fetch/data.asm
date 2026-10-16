
 fetch_file_hostname db "/etc/hostname"
 fetch_file_hostname_end:

 fetch_string_os db "OS:       LunaOs", STATIC_SCANCODE_NEW_LINE
 fetch_string_os_end:

 fetch_string_unit_kib db " KiB"
 fetch_string_unit_kib_end:

 align STATIC_QWORD_SIZE_byte, db STATIC_NOTHING
 fetch_stream_meta: dw STATIC_EMPTY ; width
  dw STATIC_EMPTY ; height
  dw STATIC_EMPTY ; x
  dw STATIC_EMPTY ; y

 fetch_string_host db "Host:     "
  times FETCH_VALUE_LENGTH_byte + 1 db STATIC_EMPTY ; value, end of line

 fetch_string_uptime db "Uptime:   "
  times FETCH_VALUE_LENGTH_byte + 1 db STATIC_EMPTY ; value, end of line

 fetch_string_memory db "Memory:   "
  times FETCH_VALUE_LENGTH_byte + 1 db STATIC_EMPTY ; value, end of line

 fetch_string_terminal db "Terminal: "
  times FETCH_VALUE_LENGTH_byte + 1 db STATIC_EMPTY ; value, end of line
