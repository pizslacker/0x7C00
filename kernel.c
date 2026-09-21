// kernel.c

#define VGA_ADDRESS 0xB8000
#define WHITE_ON_BLACK 0x0F

void clear_screen(void) {
    volatile char *vga = (volatile char *)VGA_ADDRESS;
    for (int i = 0; i < 80 * 25 * 2; i += 2) {
        vga[i] = ' ';
        vga[i + 1] = WHITE_ON_BLACK;
    }
}

void print_string(const char *str, int row, int col) {
    volatile char *vga = (volatile char *)VGA_ADDRESS;
    int offset = (row * 80 + col) * 2;

    for (int i = 0; str[i] != '\0'; i++) {
        vga[offset] = str[i];
        vga[offset + 1] = WHITE_ON_BLACK;
        offset += 2;
    }
}

void main(void) {
    clear_screen();
    print_string("Hello, World!", 12, 33); // Centered on an 80x25 screen
}