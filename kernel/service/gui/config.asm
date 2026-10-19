
KERNEL_GUI_WINDOW_count equ 3 ; number of windows created by Cero

; Everblush palette - https://github.com/Everblush/Everblush
KERNEL_GUI_WINDOW_WORKBENCH_BACKGROUND_color equ 0x00141B1E

KERNEL_GUI_WINDOW_TASKBAR_HEIGHT_pixel equ 18
KERNEL_GUI_WINDOW_TASKBAR_MARGIN_right equ 0x02

 struc KERNEL_GUI_STRUCTURE_TASKBAR
.counter resb 8
.list:
 endstruc
