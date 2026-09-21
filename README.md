# **0x7C000:** The iconic BIOS load address

A bare-metal `x86` bootloader and minimal `C` kernel demonstration built from scratch without external libraries or standard runtimes.

**0x700** boots an x86 machine in `16-bit Real Mode` via the `Master Boot Record` (`MBR`), loads a freestanding `C` kernel from disk into memory, transitions the CPU to `32-bit Protected Mode`, and prints directly to the VGA text video memory (`0xB8000`).

---

## Features

- **Custom MBR Bootloader (`boot.asm`)**:
  - Initializes segments and stack in 16-bit Real Mode.
  - Issues BIOS disk interrupt `INT 0x13, AH=0x02` to load raw kernel sectors into RAM at physical address `0x1000`.
  - Configures a basic Global Descriptor Table (GDT) defining flat 4GB code and data segments.
  - Sets the `PE` (Protection Enable) bit in `CR0` and performs a far jump to flush the pipeline and transition to 32-bit Protected Mode.
- **Kernel Bridge (`kernel_entry.asm`)**:
  - Minimal 32-bit assembly entry point that aligns the execution flow with `_start` and calls C `main()`.
- **Bare-Metal C Kernel (`kernel.c`)**:
  - Built with `-ffreestanding` (zero libc dependencies).
  - Drives the VGA hardware text buffer directly at `0xB8000`, rendering text using memory-mapped I/O.
- **Linker Control (`linker.ld`)**:
  - Positions executable code precisely at `0x1000` to match the bootloader's disk load target.

---

### Prerequisites
To build and run the project, ensure you have an x86 toolchain and QEMU installed:

#### Debian / Ubuntu / Linux Mint
```Bash
sudo apt update
sudo apt install build-essential nasm qemu-system-x86 gcc-multilib
```

#### Fedora / RHEL / AlmaLinux
```Bash
sudo dnf install gcc nasm qemu-system-x86 glibc-devel.i686
```

#### Arch Linux
```Bash
sudo pacman -S base-devel nasm qemu-system-x86 lib32-glibc
```

#### Directory Structure

```text
.
├── Makefile          # Build recipes and QEMU run targets
├── README.md         # Documentation
├── boot.asm          # 16-bit Real Mode MBR bootloader + GDT setup
├── kernel_entry.asm  # 32-bit assembly wrapper calling C main()
├── kernel.c          # Freestanding C kernel drawing to VGA buffer
└── linker.ld         # Linker script mapping kernel code to 0x1000
