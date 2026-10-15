
 ; constants, variables, globals, structures, objects, macros
 %include "software/header.asm"
 %include "software/console/header.asm"

 %define PROGRAM_NAME "fetch"
 %define PROGRAM_VERSION "0.1"

FETCH_WINDOW_WIDTH_pixel equ 320
FETCH_WINDOW_HEIGHT_pixel equ 112

FETCH_WINDOW_LABEL_X_pixel equ 0x08
FETCH_WINDOW_LABEL_WIDTH_pixel equ FETCH_WINDOW_WIDTH_pixel - 0x10
FETCH_WINDOW_LABEL_HEIGHT_pixel equ 0x0E
FETCH_WINDOW_LABEL_Y_first equ LIBRARY_BOSU_HEADER_HEIGHT_pixel + 0x04
FETCH_WINDOW_LABEL_Y_step equ 0x12

 ; size of the static part of a label, e.g. "Host:     "
FETCH_WINDOW_LABEL_PREFIX_length_byte equ 0x0A

 ; largest value written into a label during runtime
FETCH_WINDOW_VALUE_LENGTH_byte equ 32
