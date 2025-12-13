const std = @import("std");

pub const CPU = struct {
    const Self = @This();

    allocator: std.mem.Allocator,

    opcode: u16,
    memory: []u8,
    gfx: []u8,
    V: []u8, // V0 through VF registers
    I: u16, // Index register
    pc: u16,
    delay_timer: u8,
    sound_timer: u8,
    stack: []u16,
    stack_pointer: u8,
    keys: []u8,

    // Create and initialise CHIP-8 CPU
    pub fn create(allocator: std.mem.Allocator) !Self {
        // Memory Layout (4096bytes)
        // 0x000 - 0x1FF (CHIP-8 interpreter)
        // 0x050 - 0x0A0 (Default fontset)
        // 0x200 - 0xFFF (Program ROM and RAM)
        const memory = try allocator.alloc(u8, 4096);
        const gfx = try allocator.alloc(u8, 2048);
        const v_reg = try allocator.alloc(u8, 16);
        const stack = try allocator.alloc(u16, 16);
        const keys = try allocator.alloc(u8, 16);

        // Zero-initialise all of the memory regions
        @memset(memory, 0);
        @memset(gfx, 0);
        @memset(v_reg, 0);
        @memset(stack, 0);
        @memset(keys, 0);

        // Load default font into memory
        @memcpy(memory[0x050..0x0A0], chip_font[0..80]);

        // Fully initialise registers
        return Self{
            .allocator = allocator,
            .opcode = 0,
            .memory = memory,
            .gfx = gfx,
            .V = v_reg,
            .I = 0,
            .pc = 0x0200, // Start of program
            .delay_timer = 0,
            .sound_timer = 0,
            .stack = stack,
            .stack_pointer = 0,
            .keys = keys,
        };
    }

    // Free memory
    pub fn free(self: *Self) void {
        self.allocator.free(self.memory);
        self.allocator.free(self.gfx);
        self.allocator.free(self.V);
        self.allocator.free(self.stack);
        self.allocator.free(self.keys);
    }

    // Dump contents of memory to console, pair with breakpoint
    pub fn dumpMemory(self: *Self) void {
        // TODO Format output to print in rows of 16 bytes
        // ...

        for (self.memory) |byte| {
            std.debug.print("0x{x} ", .{byte});
        }
    }

    // TODO Load a ROM into program memory from file
    // ... pub fn loadROM(self: *Self, filepath: ???)

    // Perform one emulation cycle
    pub fn cycle(self: *Self) void {
        // Fetch opcode
        self.opcode = @shlExact(@as(u16, self.memory[self.pc]), 8) | self.memory[self.pc + 1];

        // Increment program counter
        self.pc += 2;

        // TODO Decode and execute
        // ...

        // TODO Update timers
        // ...
    }

    // INSTRUCTIONS
    // (N = 4-bits)
    // (X = Lower 4-bits of high byte)
    // (Y = Upper 4-bits of low byte)

    // Clear the display
    fn _00E0(self: *Self) void {
        @memset(self.gfx, 0);
    }

    // Return from a subroutine
    fn _00EE() void {}

    // Jump to location NNN
    fn _1NNN(self: *@This()) void {
        self.pc = (self.opcode & 0x0FFF);
    }

    // Call subroutine at NNN
    fn _2NNN() void {}

    // Skip next instruction if VX == NN
    fn _3XNN() void {}

    // Skip next instruction if VX != NN
    fn _4XNN() void {}

    // Skip next instruction if VX == VY
    fn _5XY0() void {}

    // Set VX = NN
    fn _6XNN() void {}

    // Set VX = VX + NN
    fn _7XNN() void {}

    // Set VX = VY
    fn _8XY0() void {}

    // Set VX = VX | VY
    fn _8XY1() void {}

    // Set VX = VX & VY
    fn _8XY2() void {}

    // Set VX = VX ^ VY
    fn _8XY3() void {}

    // Set VX = VX + VY, set VF = carry
    fn _8XY4() void {}

    // Set VX = VX - VY, set VF = !borrow
    fn _8XY5() void {}

    // Set VX = VX SHR 1
    fn _8XY6() void {}

    // Set VX = VY - VX, set VF = !borrow
    fn _8XY7() void {}

    // Set VX = VX SHL 1
    fn _8XYE() void {}

    // Skip next instruction if VX != VY
    fn _9XY0() void {}

    // Set I Register to NNN
    fn _ANNN(self: *@This()) void {
        self.I = (self.opcode & 0x0FFF);
        self.pc += 2;
    }

    // Jump to location NNN + V[0]
    fn _BNNN() void {}

    // Set VX = (random byte & NN)
    fn _CXNN() void {}

    // Display N-byte starting at memory location I, at (VX, VY), VF = collision
    fn _DXYN() void {}

    // Skip next instruction if key with value VX is pressed
    fn _EX9E() void {}

    // Skip next instruction if key with value VX is not pressed
    fn _EXA1() void {}

    // Set VX = delay timer value
    fn _FX07() void {}

    // Wait for a keypress, store valye of the key in VX
    fn _FX0A() void {}

    // Set delay timer = VX
    fn _FX15() void {}

    // Set sound timer = VX
    fn _FX18() void {}

    // Set I = I + VX
    fn _FX1E() void {}

    // Set I = location of sprite for Digit VX
    fn _FX29() void {}

    // Store BCD representation of VX in memory locations I, I+1, I+2
    fn _FX33() void {}

    // Store registers V0 through VX in memory starting at I
    fn _FX55() void {}

    // Read registers V0 through VX from memory starting at I
    fn _FX65() void {}

    fn unhandledOpcode(self: *Self) void {
        std.debug.print("Opcode not handled: 0x{X}\n", .{self.opcode});
    }
};

// Default fontset used by the Chip-8
const chip_font = [80]u8{
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
};
