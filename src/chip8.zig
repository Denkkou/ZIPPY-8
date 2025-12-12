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

    pub fn create(allocator: std.mem.Allocator) !Self {
        const memory = try allocator.alloc(u8, 4096);
        const gfx = try allocator.alloc(u8, 2048);
        const v_reg = try allocator.alloc(u8, 16);
        const stack = try allocator.alloc(u16, 16);
        const keys = try allocator.alloc(u8, 16);

        // Zero-initialise all of the memory regions
        @memset(memory, 0);
        @memset(gfx, 1);
        @memset(v_reg, 0);
        @memset(stack, 0);
        @memset(keys, 0);

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
};
