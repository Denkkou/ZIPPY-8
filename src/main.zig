const std = @import("std");
const rl = @import("raylib");
const chip8 = @import("chip8.zig").CPU;

const screen_width: u16 = 640;
const screen_height: u16 = 320;

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

    // Load ROM

    // Initialise Raylib
    rl.initWindow(screen_width, screen_height, "CHIP-8 Emulator");
    defer rl.closeWindow();

    var image: rl.Image = undefined;
    var tex: rl.Texture2D = undefined;

    while (!rl.windowShouldClose()) {
        // Get Input
        // Cycle once

        // Draw graphics from gfx array
        rl.beginDrawing();
        defer rl.endDrawing();

        if (cpu.should_draw == 1) {
            image = try imageFromGFX(&cpu);
            tex = try rl.loadTextureFromImage(image);
            std.debug.print("Drew texture from image", .{});
        }

        rl.drawTexture(tex, 0, 0, rl.Color.white);
        cpu.should_draw = 0;
    }
}

pub fn imageFromGFX(cpu: *chip8) !rl.Image {
    // initRaw wants a null terminated file as its first arg
    // however cpu.gfx is a 2048 byte array of pixel data
    // not sure how I can make an array that it'll accept :[
    const img = try rl.Image.initRaw(
        cpu.gfx, // DOESNT LIKE THIS!
        64,
        32,
        rl.PixelFormat.uncompressed_grayscale,
        0,
    );

    return img;
}

// Raylib needs only to capture input and draw graphics
// We capture the inputs and tell our chip8's input array
// Likewise, we read the gfx array and draw that.
// We dont need to worry about the chip8 implementation
// and only interface with its IO

// For now, the emulator will only run on the predetermined ROM files
// we feed it. It will be possible to run it from CLI and pass in filepath
// but lets not overcomplicate it.

// could use an enum for the 16 input keys and just directly set the
// array using the enum value

// for the gfx array, we could either draw rects in accordance with
// the pixels, or we can build a bitmap? then draw the bitmap to the screen
// to automatically scale it

// Emulate cycle
// Fetch opcode
// Decode opcode
// Run opcode
// if shouldDraw = 1
// update graphics array
