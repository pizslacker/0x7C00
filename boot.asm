[org 0x7C00]
[bits 16]

KERNEL_OFFSET equ 0x1000        ; Load address for our kernel

start:
    cli                         ; Clear interrupts
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00              ; Setup stack growing downwards from bootloader
    sti

    ; Save boot drive number provided by BIOS in DL
    mov [BOOT_DRIVE], dl

    ; Load kernel sectors from disk
    call load_kernel

    ; Switch to 32-bit Protected Mode
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 0x1                 ; Set PE (Protection Enable) bit
    mov cr0, eax

    ; Far jump to flush CPU pipeline and enter 32-bit mode
    jmp CODE_SEG:init_pm

; -----------------------------------------------------------------------------
; BIOS Disk Read Routine
; -----------------------------------------------------------------------------
load_kernel:
    mov ah, 0x02                ; BIOS read sectors function
    mov al, 15                  ; Number of sectors to read
    mov ch, 0                   ; Cylinder 0
    mov dh, 0                   ; Head 0
    mov cl, 2                   ; Sector 2 (Sector 1 is the bootloader itself)
    mov dl, [BOOT_DRIVE]        ; Drive number
    mov bx, KERNEL_OFFSET       ; Destination ES:BX = 0x0000:0x1000
    int 0x13
    jc disk_error
    ret

disk_error:
    mov si, MSG_DISK_ERROR
.loop:
    lodsb
    or al, al
    jz .hang
    mov ah, 0x0E
    int 0x10
    jmp .loop
.hang:
    jmp $

; -----------------------------------------------------------------------------
; Global Descriptor Table (GDT)
; -----------------------------------------------------------------------------
gdt_start:
    ; Null Descriptor (8 bytes)
    dd 0x0
    dd 0x0

gdt_code:
    ; Base: 0x0, Limit: 0xFFFFF, Access: Present, Ring 0, Exec/Read (0x9A), Flags: 32-bit, 4KB gran (0xCF)
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00

gdt_data:
    ; Base: 0x0, Limit: 0xFFFFF, Access: Present, Ring 0, Read/Write (0x92), Flags: 32-bit, 4KB gran (0xCF)
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; GDT size - 1
    dd gdt_start                ; GDT address

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; -----------------------------------------------------------------------------
; 32-bit Protected Mode Initialization
; -----------------------------------------------------------------------------
[bits 32]
init_pm:
    mov ax, DATA_SEG            ; Update segment registers to point to GDT data segment
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    mov ebp, 0x90000            ; Set stack far above loaded kernel
    mov esp, ebp

    call KERNEL_OFFSET          ; Jump to kernel
    jmp $                       ; Hang if kernel returns

BOOT_DRIVE:     db 0
MSG_DISK_ERROR: db "Disk read error!", 0

times 510 - ($ - $$) db 0       ; Pad to 510 bytes
dw 0xAA55                       ; Standard MBR boot signature