[bits 32]
[extern main]

global _start
_start:
    call main
    jmp $                       ; Infinite loop if main() exits