
KERNEL_WM_IRQ equ 0x41

KERNEL_WM_WINDOW_close equ 0x00
KERNEL_WM_WINDOW_create equ 0x01
KERNEL_WM_WINDOW_update equ 0x02
KERNEL_WM_WINDOW_minimize equ 0x03 ; toggle the visibility of the window

; flags of the window object, shared by the window manager and the window owner
; the same bits as LIBRARY_BOSU_WINDOW_FLAG_* - the object IS the window structure
KERNEL_WM_OBJECT_FLAG_flush equ 1 << 0 ; the object has been updated
 ; the flags below are reserved for the GUI
KERNEL_WM_OBJECT_FLAG_visible equ 1 << 1 ; the object is visible
KERNEL_WM_OBJECT_FLAG_fixed_xy equ 1 << 2 ; the object is fixed on the X,Y axis
KERNEL_WM_OBJECT_FLAG_fixed_z equ 1 << 3 ; the object is fixed on the Z axis
KERNEL_WM_OBJECT_FLAG_fragile equ 1 << 4 ; the object is hidden on the occurrence of an LMB or RMB action
KERNEL_WM_OBJECT_FLAG_pointer equ 1 << 5 ; the object of the "cursor" type
KERNEL_WM_OBJECT_FLAG_arbiter equ 1 << 6 ; superobject
KERNEL_WM_OBJECT_FLAG_undraw equ 1 << 7 ; redraw the space under the object
