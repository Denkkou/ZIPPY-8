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
        var counter: usize = 0;
        for (self.memory) |byte| {
            counter += 1;
            if (counter < 16) {
                std.debug.print("{X:0>2} ", .{byte});
            } else {
                std.debug.print("{X:0>2}\n", .{byte});
                counter = 0;
            }
        }
    }

    // Load a ROM into program memory from file
    pub fn loadROM(self: *Self, filepath: []const u8) !void {
        // Open the file at given path
        const file = try std.fs.cwd().openFile(
            filepath,
            .{ .mode = .read_only },
        );
        defer file.close();

        // Create and read into a buffer
        var buffer: [4096 - 0x200]u8 = undefined;
        var fr = file.reader(std.testing.io, &buffer);
        var reader = &fr.interface;
        @memset(buffer[0..], 0); // Zero-out buffer
        _ = reader.readSliceAll(buffer[0..]) catch 0;

        // Copy contents of buffer into memory
        @memcpy(self.memory[0x200..], buffer[0..]);
    }

    // Perform one emulation cycle
    pub fn cycle(self: *Self) void {
        // Fetch opcode
        self.opcode = @shlExact(@as(u16, self.memory[self.pc]), 8) | self.memory[self.pc + 1];

        // Increment program counter
        self.pc += 2;

        // Decode and execute
        switch (self.opcode & 0xF000) { // Check first nibble
            0x0000 => switch (self.opcode & 0x000F) { // Check last if needed
                0x0000 => _00E0(self),
                0x000E => _00EE(self),
                else => unhandledOpcode(self),
            },
            0x1000 => _1NNN(self),
            0x2000 => _2NNN(self),
            0x3000 => _3XNN(self),
            0x4000 => _4XNN(self),
            0x5000 => _5XY0(self),
            0x6000 => _6XNN(self),
            0x7000 => _7XNN(self),
            0x8000 => switch (self.opcode & 0x000F) {
                0x0000 => _8XY0(self),
                0x0001 => _8XY1(self),
                0x0002 => _8XY2(self),
                0x0003 => _8XY3(self),
                0x0004 => _8XY4(self),
                0x0005 => _8XY5(self),
                0x0006 => _8XY6(self),
                0x0007 => _8XY7(self),
                0x000E => _8XYE(self),
                else => unhandledOpcode(self),
            },
            0x9000 => _9XY0(self),
            0xA000 => _ANNN(self),
            0xB000 => _BNNN(self),
            0xC000 => _CXNN(),
            0xD000 => _DXYN(self),
            0xE000 => switch (self.opcode & 0x000F) {
                0x000E => _EX9E(self),
                0x0001 => _EXA1(self),
                else => unhandledOpcode(self),
            },
            0xF000 => switch (self.opcode & 0x00FF) { // Or check last whole byte
                0x0007 => _FX07(self),
                0x000A => _FX0A(self),
                0x0015 => _FX15(self),
                0x0018 => _FX18(self),
                0x001E => _FX1E(self),
                0x0029 => _FX29(self),
                0x0033 => _FX33(self),
                0x0055 => _FX55(self),
                0x0065 => _FX65(self),
                else => unhandledOpcode(self),
            },
            else => unhandledOpcode(self),
        }

        // Update timers
        if (self.delay_timer > 0) {
            self.delay_timer -= 1;
        }

        if (self.sound_timer > 0) {
            self.sound_timer -= 1;
        }
    }

    // INSTRUCTIONS
    // (N = 4-bits)
    // (X = Lower 4-bits of high byte)
    // (Y = Upper 4-bits of low byte)

    // TODO Find alternative solution to suppressing runtime safety for
    // integer overflow panics.

    // Clear the display
    fn _00E0(self: *Self) void {
        @memset(self.gfx, 0);
    }

    // Return from a subroutine
    fn _00EE(self: *Self) void {
        self.stack_pointer -= 1;
        self.pc = self.stack[self.stack_pointer];
    }

    // Jump to location NNN
    fn _1NNN(self: *Self) void {
        self.pc = (self.opcode & 0x0FFF);
    }

    // Call subroutine at NNN
    fn _2NNN(self: *Self) void {
        self.stack[self.stack_pointer] = self.pc;
        self.stack_pointer += 1;
        self.pc = self.opcode & 0x0FFF;
    }

    // Skip next instruction if VX == NN
    fn _3XNN(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);
        const NN = self.opcode & 0x00FF;

        if (self.V[X] == NN) {
            self.pc += 2;
        }
    }

    // Skip next instruction if VX != NN
    fn _4XNN(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);
        const NN = self.opcode & 0x00FF;

        if (self.V[X] != NN) {
            self.pc += 2;
        }
    }

    // Skip next instruction if VX == VY
    fn _5XY0(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);
        const Y = @shrExact(self.opcode & 0x00F0, 4);

        if (self.V[X] == self.V[Y]) {
            self.pc += 2;
        }
    }

    // Set VX = NN
    fn _6XNN(self: *Self) void {
        const X = @shrExact((self.opcode & 0x0F00), 8);
        const NN = self.opcode & 0x00FF;
        self.V[X] = @intCast(NN);
    }

    // Set VX = VX + NN
    fn _7XNN(self: *Self) void {
        @setRuntimeSafety(false); // Removes integer overflow panic
        const X = @shrExact((self.opcode & 0x0F00), 8);
        const NN = self.opcode & 0x00FF;
        self.V[X] += @intCast(NN);
    }

    // Set VX = VY
    fn _8XY0(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);
        const Y = @shrExact(self.opcode & 0x00F0, 4);

        self.V[X] = self.V[Y];
    }

    // Set VX = VX | VY
    fn _8XY1(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);
        const Y = @shrExact(self.opcode & 0x00F0, 4);

        self.V[X] |= self.V[Y];
        self.V[0xF] = 0;
    }

    // Set VX = VX & VY
    fn _8XY2(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);
        const Y = @shrExact(self.opcode & 0x00F0, 4);

        self.V[X] &= self.V[Y];
        self.V[0xF] = 0;
    }

    // Set VX = VX ^ VY
    fn _8XY3(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);
        const Y = @shrExact(self.opcode & 0x00F0, 4);

        self.V[X] ^= self.V[Y];
        self.V[0xF] = 0;
    }

    // Set VX = VX + VY, set VF = carry
    fn _8XY4(self: *Self) void {
        @setRuntimeSafety(false); // Removes integer overflow panic
        const X = @shrExact(self.opcode & 0x0F00, 8);
        const Y = @shrExact(self.opcode & 0x00F0, 4);

        const sum = self.V[X] + self.V[Y];

        // If the sum exceeds a byte's capacity, set the carry flag
        if (sum > 255) {
            self.V[0xF] = 1;
        } else {
            self.V[0xF] = 0;
        }

        // Set V[X] to sum
        self.V[X] = @truncate(sum & 0x00FF);
    }

    // Set VX = VX - VY, set VF = !borrow
    fn _8XY5(self: *Self) void {
        @setRuntimeSafety(false); // Removes integer overflow panic
        const X = @shrExact(self.opcode & 0x0F00, 8);
        const Y = @shrExact(self.opcode & 0x00F0, 4);

        if (self.V[X] > self.V[Y]) {
            self.V[0xF] = 1;
        } else {
            self.V[0xF] = 0;
        }

        self.V[X] -= self.V[Y];
    }

    // Set VX = VX SHR 1
    fn _8XY6(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);

        // If least significant bit is 1, store 1 in V[F], else 0
        self.V[0xF] = self.V[X] & 0x1;

        // Bitshift right one (divide by 2)
        self.V[X] >>= 1; // No @shrExact as we want to shift a bit out
    }

    // Set VX = VY - VX, set VF = !borrow
    fn _8XY7(self: *Self) void {
        @setRuntimeSafety(false); // Removes integer overflow panic
        const X = @shrExact(self.opcode & 0x0F00, 8);
        const Y = @shrExact(self.opcode & 0x00F0, 4);

        self.V[X] = (self.V[Y] - self.V[X]);

        if (self.V[Y] > self.V[X]) {
            self.V[0xF] = 1;
        } else {
            self.V[0xF] = 0;
        }
    }

    // Set VX = VX SHL 1
    fn _8XYE(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);

        // If most significant bit is 1, store 1 in V[F], else 0
        self.V[0xF] = @shrExact((self.V[X] & 0x80), 7);

        // Bitshift left one (multiply by 2)
        self.V[X] <<= 1; // No @shlExact as we want to shift a bit out
    }

    // Skip next instruction if VX != VY
    fn _9XY0(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);
        const Y = @shrExact(self.opcode & 0x00F0, 4);

        if (self.V[X] != self.V[Y]) {
            self.pc += 2;
        }
    }

    // Set I Register to NNN
    fn _ANNN(self: *Self) void {
        self.I = (self.opcode & 0x0FFF);
    }

    // Jump to location NNN + V[0]
    fn _BNNN(self: *Self) void {
        const NNN = self.opcode & 0x0FFF;
        self.pc = self.V[0] + NNN;
    }

    // Set VX = (random byte & NN)
    fn _CXNN() void {}

    // Display N-byte sprite starting at memory location I, at (VX, VY), VF = collision
    fn _DXYN(self: *Self) void {
        // Thanks to @IridescentRose's implementation
        // https://github.com/IridescentRose/CHIP-8z

        self.V[0xF] = 0;

        // Extract values from opcode
        const X = self.V[(self.opcode & 0x0F00) >> 8];
        const Y = self.V[(self.opcode & 0x00F0) >> 4];
        const height = self.opcode & 0x000F;

        var y: usize = 0;
        while (y < height) : (y += 1) {
            const spr = self.memory[self.I + y];

            var x: usize = 0;
            while (x < 8) : (x += 1) {
                const v: u8 = 0x80;

                if ((spr & (v >> @intCast(x))) != 0) {
                    const tX = (X + x) % 64;
                    const tY = (Y + y) % 32;

                    // Index in the gfx array
                    const i = tX + tY * 64;

                    // XOR with current value
                    self.gfx[i] ^= 1;

                    // Collision flag
                    if (self.gfx[i] == 0) {
                        self.V[0xF] = 1;
                    }
                }
            }
        }
    }

    // Skip next instruction if key with value VX is pressed
    fn _EX9E(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);

        if (self.keys[self.V[X]] == 1) {
            self.pc += 2;
        }
    }

    // Skip next instruction if key with value VX is not pressed
    fn _EXA1(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);

        if (self.keys[self.V[X]] != 1) {
            self.pc += 2;
        }
    }

    // Set VX = delay timer value
    fn _FX07(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);
        self.V[X] = self.delay_timer;
    }

    // Wait for a keypress, store value of the key in VX
    fn _FX0A(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);

        var pressed = false;

        var i: usize = 0;
        while (i < 16) : (i += 1) {
            if (self.keys[i] != 0) {
                self.V[X] = @truncate(i);
                pressed = true;
            }
        }
    }

    // Set delay timer = VX
    fn _FX15(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);
        self.delay_timer = self.V[X];
    }

    // Set sound timer = VX
    fn _FX18(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);
        self.sound_timer = self.V[X];
    }

    // Set I = I + VX
    fn _FX1E(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);
        self.I += self.V[X];
    }

    // Set I = location of sprite for Digit VX
    fn _FX29(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);
        const digit = self.V[X];

        // Font sprites are at 0x50 in memory, and are 5 bytes wide
        self.I = 0x50 + (5 * digit);
    }

    // Store BCD representation of VX in memory locations I, I+1, I+2
    fn _FX33(self: *Self) void {
        // Thanks to @AustinMorlan's solution
        // https://austinmorlan.com/posts/chip8_emulator/

        const X = @shrExact(self.opcode & 0x0F00, 8);
        var value = self.V[X];

        // Units
        self.memory[self.I + 2] = value % 10;
        value /= 10;

        // Tens
        self.memory[self.I + 1] = value % 10;
        value /= 10;

        // Hundreds
        self.memory[self.I] = value % 10;
    }

    // Store registers V0 through VX in memory starting at I
    fn _FX55(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);

        var i: usize = 0;
        while (i <= X) : (i += 1) {
            self.memory[self.I + i] = self.V[i];
        }
    }

    // Read registers V0 through VX from memory starting at I
    fn _FX65(self: *Self) void {
        const X = @shrExact(self.opcode & 0x0F00, 8);

        var i: usize = 0;
        while (i <= X) : (i += 1) {
            self.V[i] = self.memory[self.I + i];
        }
    }

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
