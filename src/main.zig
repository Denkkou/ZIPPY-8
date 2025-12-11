const std = @import("std");
const rl = @import("raylib");
const chip8 = @import("chip8.zig").CPU;

const screen_width: u16 = 640;
const screen_height: u16 = 320;
const screen_scale_x: u16 = screen_width / 64;
const screen_scale_y: u16 = screen_height / 32;

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
    var cpu = try chip8.create(allocator);
    defer cpu.free();

    // TODO Load ROM
    // ...

    // Initialise Raylib
    rl.initWindow(
        screen_width,
        screen_height,
        "CHIP-8 Emulator",
    );
    defer rl.closeWindow();

    // Core loop
    while (!rl.windowShouldClose()) {
        // TODO Get Input
        // ...

        // TODO Cycle once
        // ...

        // Draw graphics
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        // Only process changes when cpu needs it
        if (cpu.should_draw > 0) {
            GeneratePixelGrid(&cpu);
        }

        if (cpu.should_draw - 1 > 0) cpu.should_draw -= 1;
    }
}

// Create a grid of pixel rectangles to fill the screen
pub fn GeneratePixelGrid(cpu: *chip8) void {
    var y: usize = 0;
    while (y < 32) : (y += 1) {
        var x: usize = 0;
        while (x < 64) : (x += 1) {
            // Parse index from coordinates
            const index = y * 64 + x;

            // Set colour based on value in gfx
            var colour: rl.Color = undefined;
            if (cpu.gfx[index] == 0) {
                colour = rl.Color.black;
            }
            if (cpu.gfx[index] == 1) {
                colour = rl.Color.white;
            }

            // Draw the pixel relative to position and scale
            rl.drawRectangle(
                @intCast(x * screen_scale_x),
                @intCast(y * screen_scale_y),
                screen_scale_x,
                screen_scale_y,
                colour,
            );
        }
    }
}

//pub fn UpdatePixelGrid(grid: []pixel) void {}
