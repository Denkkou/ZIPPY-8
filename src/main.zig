const std = @import("std");
const rl = @import("raylib");

pub fn main() !void {
    // Allocator

    // Initialise CPU

    // Load ROM

    // Initialise Raylib
    rl.initWindow(640, 320, "CHIP-8 Emulator");
    defer rl.closeWindow();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        // Get Input

        // Perform one emulation cycle

        // Draw gfx array scaled up to window size
    }
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
