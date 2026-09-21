# **0x7C00:** The iconic BIOS load address

A bare-metal `x86` bootloader and minimal `C` kernel demonstration built from scratch without external libraries or standard runtimes.

**0x7C00** boots an `x86` machine or an emulator (`QEMU`) in `16-bit Real Mode` via the `Master Boot Record` (`MBR`), loads a freestanding `C` kernel from disk into memory, transitions the CPU to `32-bit Protected Mode`, and prints directly to the VGA text video memory (`0xB8000`).

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
```

### Memory Map

|Address Range | Description |
|--------------|-------------------------------------------------|
| 0x00000 - 0x003FF | Real Mode Interrupt Vector Table (IVT) |
| 0x00400 - 0x004FF | BIOS Data Area (BDA) |
| 0x01000 - 0x07BFF | Loaded Kernel Code & Data (kernel.bin) |
| 0x07C00 - 0x07DFF | MBR Bootloader Sector (boot.bin) |
| 0x07E00 - 0x8FFFF § Usable Low RAM / Initial Stack Region |
| 0xB8000 - 0xB8FA0 § VGA Color Text Mode Buffer (80x25 characters) |

### Building and Running
1. Compile and Link
Build the bootloader, compile the kernel, link them to flat binaries, and combine them into a bootable image:

```Bash
make
```

Artifacts will be placed in the build/ directory:
```text
build/boot.bin (512 bytes with 0xAA55 signature)

build/kernel.bin (Flat raw binary starting at 0x1000)

build/0x7C00.img (Final bootable disk image padded to 8 KB)
```

2. Run with QEMU
Launch the image inside a virtual x86 environment:

```Bash
make run
```

3. Debug with GDB
To pause the CPU at the reset vector (0xFFF0 / 0x7C00) and attach GDB:

```Bash
make debug
```

In another terminal:

```Bash
gdb -ex "target remote localhost:1234" -ex "set architecture i8086"
```

4. Clean Build Artifacts
```Bash
make clean
```

## License

This project is licensed under the GNU General Public License v3.0 (GPLv3). See the [LICENSE](LICENSE) file for the full license text.
