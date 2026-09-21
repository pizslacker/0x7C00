# ==============================================================================
# SectorZero - Bare-Metal x86 Bootloader & Minimal C Kernel
# ==============================================================================

CC      := gcc
LD      := ld
NASM    := nasm
QEMU    := qemu-system-i386

# Compilation flags
# -m32: Generate 32-bit x86 code
# -ffreestanding: Do not assume standard library existence
# -fno-pie / -no-pie: Prevent Position Independent Executable generation
# -fno-stack-protector: Omit stack guard checks (__stack_chk_fail)
CFLAGS  := -m32 -ffreestanding -fno-pie -fno-stack-protector -Wall -Wextra -O2
LDFLAGS := -m elf_i386 -T linker.ld --oformat binary
ASFLAGS := -f elf32

BUILD_DIR := build

TARGET_IMG := $(BUILD_DIR)/sectorzero.img
BOOT_BIN   := $(BUILD_DIR)/boot.bin
KERNEL_BIN := $(BUILD_DIR)/kernel.bin
KERNEL_OBJS := $(BUILD_DIR)/kernel_entry.o $(BUILD_DIR)/kernel.o

.PHONY: all run clean debug

all: $(TARGET_IMG)

# -----------------------------------------------------------------------------
# Disk Image Target
# -----------------------------------------------------------------------------
# Bootloader occupies sector 1 (512 bytes). Kernel follows immediately after.
$(TARGET_IMG): $(BOOT_BIN) $(KERNEL_BIN)
	@mkdir -p $(BUILD_DIR)
	cat $(BOOT_BIN) $(KERNEL_BIN) > $@
	@# Pad disk image to at least 16 sectors (8192 bytes) so INT 0x13 does not read past EOF
	truncate -s 8192 $@
	@echo "[+] Successfully built $(TARGET_IMG)"

# Boot sector binary (raw 16-bit MBR flat binary)
$(BOOT_BIN): boot.asm
	@mkdir -p $(BUILD_DIR)
	$(NASM) -f bin $< -o $@

# Kernel entry shim (ELF32)
$(BUILD_DIR)/kernel_entry.o: kernel_entry.asm
	@mkdir -p $(BUILD_DIR)
	$(NASM) $(ASFLAGS) $< -o $@

# C Kernel compilation (ELF32)
$(BUILD_DIR)/kernel.o: kernel.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Linked kernel binary (raw flat binary at 0x1000)
$(KERNEL_BIN): $(KERNEL_OBJS) linker.ld
	$(LD) $(LDFLAGS) -o $@ $(KERNEL_OBJS)

# -----------------------------------------------------------------------------
# Execution & Emulation
# -----------------------------------------------------------------------------
run: $(TARGET_IMG)
	$(QEMU) -drive format=raw,file=$(TARGET_IMG)

# Run with GDB debugging hooks (listens on localhost:1234, halted at start)
debug: $(TARGET_IMG)
	$(QEMU) -s -S -drive format=raw,file=$(TARGET_IMG)

clean:
	rm -rf $(BUILD_DIR)
	@echo "[*] Cleaned build artifacts."