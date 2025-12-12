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

    // TODO Load ROM
    // ... cpu.LoadROM(filepath)

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

        // Cycle once
        cpu.cycle();

        // Draw graphics
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);
        GeneratePixelGrid(&cpu);
    }
}

// Create a grid of pixel rectangles to fill the screen
pub fn GeneratePixelGrid(cpu: *Chip8) void {
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
