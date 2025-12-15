const std = @import("std");
const rl = @import("raylib");
const Chip8 = @import("chip8.zig").CPU;

const screen_width: u16 = 640;
const screen_height: u16 = 320;
const screen_scale_x: u16 = screen_width / 64;
const screen_scale_y: u16 = screen_height / 32;
const target_fps: u8 = 60; // Chip-8's cpu runs at 60Hz

pub fn main() !void {
    // Allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Catch any potential memory leaks
    defer {
        const leaked = gpa.deinit();
        if (leaked == .leak) {
            @panic("Memory leak detected!");
        }
    }

    // Initialise CPU
    var cpu = try Chip8.create(allocator);
    defer cpu.free();

    // Load ROM
    try cpu.loadROM("roms/1-chip8-logo.ch8");
    cpu.dumpMemory();

    // Initialise Raylib
    rl.initWindow(
        screen_width,
        screen_height,
        "CHIP-8 Emulator",
    );
    defer rl.closeWindow();
    rl.setTargetFPS(target_fps);

    // Core loop
    while (!rl.windowShouldClose()) {

        // TODO Get Input
        // ...
        handleInput(&cpu);

        // Cycle once
        cpu.cycle();

        // Draw graphics
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);
        generatePixelGrid(&cpu);
    }
}

// Update cpu's keys register with raylib input
pub fn handleInput(cpu: *Chip8) void {
    // 4x4 Hex keypad will instead be QWERTY columns 1 through 4
    // 1 2 3 C  ->  1 2 3 4
    // 4 5 6 D      Q W E R
    // 7 8 9 E      A S D F
    // A 0 B F      Z X C V

    cpu.keys[0x1] = if (rl.isKeyDown(rl.KeyboardKey.one)) 1 else 0;
    cpu.keys[0x2] = if (rl.isKeyDown(rl.KeyboardKey.two)) 1 else 0;
    cpu.keys[0x3] = if (rl.isKeyDown(rl.KeyboardKey.three)) 1 else 0;
    cpu.keys[0xC] = if (rl.isKeyDown(rl.KeyboardKey.four)) 1 else 0;

    cpu.keys[0x4] = if (rl.isKeyDown(rl.KeyboardKey.q)) 1 else 0;
    cpu.keys[0x5] = if (rl.isKeyDown(rl.KeyboardKey.w)) 1 else 0;
    cpu.keys[0x6] = if (rl.isKeyDown(rl.KeyboardKey.e)) 1 else 0;
    cpu.keys[0xD] = if (rl.isKeyDown(rl.KeyboardKey.r)) 1 else 0;

    cpu.keys[0x7] = if (rl.isKeyDown(rl.KeyboardKey.a)) 1 else 0;
    cpu.keys[0x8] = if (rl.isKeyDown(rl.KeyboardKey.s)) 1 else 0;
    cpu.keys[0x9] = if (rl.isKeyDown(rl.KeyboardKey.d)) 1 else 0;
    cpu.keys[0xE] = if (rl.isKeyDown(rl.KeyboardKey.f)) 1 else 0;

    cpu.keys[0xA] = if (rl.isKeyDown(rl.KeyboardKey.z)) 1 else 0;
    cpu.keys[0x0] = if (rl.isKeyDown(rl.KeyboardKey.x)) 1 else 0;
    cpu.keys[0xB] = if (rl.isKeyDown(rl.KeyboardKey.c)) 1 else 0;
    cpu.keys[0xF] = if (rl.isKeyDown(rl.KeyboardKey.v)) 1 else 0;
}

// Create a grid of pixel rectangles to fill the screen
pub fn generatePixelGrid(cpu: *Chip8) void {
    var y: usize = 0;
    while (y < 32) : (y += 1) {
        var x: usize = 0;
        while (x < 64) : (x += 1) {
            // Parse index from coordinates
            const index = y * 64 + x;

            // Draw a pixel if there is one there
            if (cpu.gfx[index] == 1) {
                rl.drawRectangle(
                    @intCast(x * screen_scale_x),
                    @intCast(y * screen_scale_y),
                    screen_scale_x,
                    screen_scale_y,
                    rl.Color.white,
                );
            }
        }
    }
}
