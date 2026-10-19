
KERNEL_WM_OBJECT_NAME_length equ 31

; KERNEL_WM_OBJECT_FLAG_* - see kernel/header/wm.asm (window owners need them too)

; the last element of the list is always empty
KERNEL_WM_OBJECT_LIST_limit equ (STATIC_PAGE_SIZE_byte / KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.SIZE) - 0x01
KERNEL_WM_FILL_LIST_limit equ (STATIC_PAGE_SIZE_byte / KERNEL_WM_STRUCTURE_FILL.SIZE) - 0x01
KERNEL_WM_ZONE_LIST_limit equ (STATIC_PAGE_SIZE_byte / KERNEL_WM_STRUCTURE_ZONE.SIZE) - 0x01

KERNEL_WM_OBJECT_LIST_ENTRY_SIZE_shift equ STATIC_MULTIPLE_BY_8_shift

 struc KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY
.object_address resb 8
.SIZE:
 endstruc

 struc KERNEL_WM_STRUCTURE_FIELD
.x resb 2
.y resb 2
.width resb 2
.height resb 2
.SIZE:
 endstruc

 struc KERNEL_WM_STRUCTURE_OBJECT
.field resb KERNEL_WM_STRUCTURE_FIELD.SIZE
.address resb 8
.SIZE:
 endstruc

 struc KERNEL_WM_STRUCTURE_OBJECT_EXTRA
.size resb 4
.flags resb 2
.id resb 8
.length resb 1
.name resb KERNEL_WM_OBJECT_NAME_length
 ;--- data specific to the WM
.pid resb 8
.SIZE:
 endstruc

 struc KERNEL_WM_STRUCTURE_FILL
.field resb KERNEL_WM_STRUCTURE_FIELD.SIZE
.object resb 8
.SIZE:
 endstruc

 struc KERNEL_WM_STRUCTURE_ZONE
.field resb KERNEL_WM_STRUCTURE_FIELD.SIZE
.object resb 8
.SIZE:
 endstruc
