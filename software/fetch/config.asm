
 ; constants, variables, globals, structures, objects, macros
 %include "software/header.asm"
 %include "software/console/header.asm"

 %define PROGRAM_NAME "fetch"
 %define PROGRAM_VERSION "0.1"

 ; size of the static part of a line, e.g. "Host:     "
FETCH_STRING_PREFIX_length_byte equ 0x0A

 ; largest value written into a line after the prefix during runtime
FETCH_VALUE_LENGTH_byte equ 32
