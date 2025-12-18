# About
ZIPPY-8 is an emulator for the CHIP-8 written in Zig, using the Raylib library for visuals.

![Space Invaders, implementation by David Winter](/assets/space_invaders.png)

This is my first larger scale personal project and as such may contain some bugs. 
It is also a little messy around the edges, and could do with some extra tinkering.
I had a lot of fun learning about emulation and figuring out how to set up a project like this.
It took some frustration, and a few false starts, but we got somewhere in the end.

As this was a project aimed at learning and developing problem-solving skills, I did my best to avoid
'peeking at the answers' as much as possible. Some instances of being totally lost were remedied by this,
but I did my best to tackle every problem myself.

As of right now, the implementation necessitates building from source.

# Usage
Clone the source into a directory of your choosing. Modify this line in `main.zig` to point to your desired ROM, relative to the directory of `main.zig`:

```try cpu.loadRom("roms/*.ch8");```

In your text editor or command line, from the directory of `main.zig`, run:

```zig build run```

This project depends on raylib-zig (https://github.com/raylib-zig/raylib-zig)

# Known Issues
- Currently passes the Corax+ test from Timendus' testing suite.
- Fails a few flag tests with opcodes 8XY4 and 8XY5.
- Some games run fine, like Pong, but Breakout doesn't work properly.
- Currently the random value opcode CXNN is unimplemented.
- When running Timendus' quirks test, behaviour doesn't 100% match original CHIP-8 quirks.

#### Opcodes:
![Opcode test results](assets/opcode_results.png)

#### Flags:
![Flag setting test results](assets/flags_results.png)

#### Quirks:
![Quirks test results](assets/quirks_results.png)

# To Do:
- Allow running from command line with passed filepath argument.
- Implement missing opcode.

# Resources
[Cowgod's CHIP-8 Technical Reference](http://devernay.free.fr/hacks/chip8/C8TECH10.HTM)

[Timendus' CHIP-8 Testing Suite](https://github.com/Timendus/chip8-test-suite?tab=readme-ov-file)

[IridescentRose's implementation of a CHIP-8 emulator in Zig](https://github.com/IridescentRose/CHIP-8z)

[Austin Morlan's implementation of a CHIP-8 emulator in C](https://austinmorlan.com/posts/chip8_emulator/)

[The Zig language reference](https://ziglang.org/documentation/master/#Introduction)
