
shell_string_console_header db "^[hShell]"
shell_string_console_header_end:

shell_pid_parent dq STATIC_EMPTY

 align STATIC_QWORD_SIZE_byte, db STATIC_NOTHING
shell_ipc_data:
 times KERNEL_IPC_STRUCTURE.SIZE db STATIC_EMPTY

shell_string_cursor_reset db STATIC_SEQUENCE_CURSOR_ENABLE
shell_string_cursor_reset_end:

shell_string_prompt_with_new_line db STATIC_SCANCODE_NEW_LINE
shell_string_prompt db STATIC_SEQUENCE_COLOR_RED_LIGHT
shell_string_prompt_type db "# "
shell_string_prompt_type_end db STATIC_SEQUENCE_COLOR_DEFAULT
shell_string_prompt_end:
shell_string_sequence_clear db STATIC_SEQUENCE_CLEAR
shell_string_sequence_clear_end:
shell_exec_path db "/bin/"
shell_exec_path_end:

shell_cache:
 times SHELL_CACHE_SIZE_byte db STATIC_EMPTY

shell_command_kill db "kill"
shell_command_kill_end:
shell_command_help db "help"
shell_command_help_end:
shell_command_clear db "clear"
shell_command_clear_end:
shell_command_exit db "exit"
shell_command_exit_end:
shell_command_cd db "cd"
shell_command_cd_end:
shell_command_echo db "echo"
shell_command_echo_end:

shell_command_mkdir db "mkdir"
shell_command_mkdir_end:
shell_command_rm db "rm"
shell_command_rm_end:

shell_rm_usage db STATIC_SEQUENCE_COLOR_RED_LIGHT, "usage: rm <path>", STATIC_SEQUENCE_COLOR_DEFAULT, STATIC_SCANCODE_NEW_LINE
shell_rm_usage_end:

shell_rm_denied db STATIC_SEQUENCE_COLOR_RED_LIGHT, "cannot remove file", STATIC_SEQUENCE_COLOR_DEFAULT, STATIC_SCANCODE_NEW_LINE
shell_rm_denied_end:

shell_command_pidof db "pidof"
shell_command_pidof_end:

shell_kill_usage db STATIC_SEQUENCE_COLOR_RED_LIGHT, "usage: kill <pid>", STATIC_SEQUENCE_COLOR_DEFAULT, STATIC_SCANCODE_NEW_LINE
shell_kill_usage_end:
shell_kill_denied db STATIC_SEQUENCE_COLOR_RED_LIGHT, "cannot terminate this process", STATIC_SEQUENCE_COLOR_DEFAULT, STATIC_SCANCODE_NEW_LINE
shell_kill_denied_end:

shell_help_text db STATIC_SEQUENCE_COLOR_GRAY_LIGHT, STATIC_SCANCODE_NEW_LINE, "internal commands:", STATIC_SCANCODE_NEW_LINE
 db STATIC_SEQUENCE_COLOR_DEFAULT
 db "  clear    clear the terminal", STATIC_SCANCODE_NEW_LINE
 db "  exit     leave the shell", STATIC_SCANCODE_NEW_LINE
 db "  cd <dir> change working directory", STATIC_SCANCODE_NEW_LINE
 db "  echo     print the arguments", STATIC_SCANCODE_NEW_LINE
 db "  kill <pid> terminate process by PID", STATIC_SCANCODE_NEW_LINE
 db "  pidof <name>   print the PID of matching processes", STATIC_SCANCODE_NEW_LINE
 db "  mkdir <path>   create a directory", STATIC_SCANCODE_NEW_LINE
 db "  rm <path>      remove a file", STATIC_SCANCODE_NEW_LINE
 db "  help     this list", STATIC_SCANCODE_NEW_LINE
shell_help_text_end:

shell_pidof_usage db STATIC_SEQUENCE_COLOR_RED_LIGHT, "usage: pidof <name>", STATIC_SEQUENCE_COLOR_DEFAULT, STATIC_SCANCODE_NEW_LINE
shell_pidof_usage_end:


shell_mkdir_usage db STATIC_SEQUENCE_COLOR_RED_LIGHT, "usage: mkdir <path>", STATIC_SEQUENCE_COLOR_DEFAULT, STATIC_SCANCODE_NEW_LINE
shell_mkdir_usage_end:
shell_mkdir_denied db STATIC_SEQUENCE_COLOR_RED_LIGHT, "cannot create directory", STATIC_SEQUENCE_COLOR_DEFAULT, STATIC_SCANCODE_NEW_LINE
shell_mkdir_denied_end:

shell_command_unknown db STATIC_SEQUENCE_COLOR_GREEN_LIGHT, "?", STATIC_SCANCODE_NEW_LINE
shell_command_unknown_end:

 align STATIC_QWORD_SIZE_byte, db STATIC_EMPTY
shell_pidof_buffer:
 times 32 db STATIC_EMPTY
shell_stream_meta:
 times KERNEL_STREAM_META_SIZE_byte db STATIC_EMPTY
