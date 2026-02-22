const Cartridge = @import("./cartridge/cartridge.zig").Cartridge;
const Console = @import("./gameboy/console.zig").Console;
const Cpu = @import("./gameboy/cpu.zig").Cpu;
const Bus = @import("./gameboy/bus.zig").Bus;
const Ppu = @import("./gameboy/ppu.zig").Ppu;
const Timer = @import("./gameboy/timer.zig").Timer;
const Joypad = @import("./gameboy/joypad.zig").Joypad;
const InterruptController = @import("./gameboy/interrupt_controller.zig").InterruptController;
const std = @import("std");
const SDL = @cImport({
    @cInclude("SDL3/SDL.h");
});

var frame_time_ms: u32 = 16; // ~60 FPS, close enough
// const frame_time_ms: u32 = 1; // ~60 FPS, close enough
const SCALE = 4;
const WIDTH = 160;
const HEIGHT = 144;

pub fn main(init: std.process.Init) !void {
    // Initialise allocator + io
    const allocator: std.mem.Allocator = init.gpa;
    const io: std.Io = init.io;

    // var stdout_buffer: [1024]u8 = undefined;
    // var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    // const stdout = &stdout_writer.interface;

    // Read Argv for file path
    var args = try init.minimal.args.iterateAllocator(allocator);
    _ = args.skip();
    const path: []const u8 = args.next() orelse return error.MissingArgs;

    // Allocate buffer to store ROM
    const buffer = try allocator.alloc(u8, 4 * 1024 * 1024);
    defer allocator.free(buffer);

    // Load ROM into buffer
    const rom_buffer = try loadFile(allocator, io, path, buffer);
    defer allocator.free(rom_buffer);

    // Convert ROM path to save path
    var buf: [256]u8 = undefined;
    const save_path: []const u8 = try std.fmt.bufPrint(&buf, "saves/{s}", .{path[4..]});
    @memset(buffer, 0);

    // Load Save File into buffer
    const save_file_buffer = loadFile(allocator, io, save_path, buffer) catch null;
    defer if (save_file_buffer) |s| allocator.free(s);

    // Initialise Cartridge
    var cart = try Cartridge.init(allocator, rom_buffer);

    // Load the save data if it exists
    if (save_file_buffer) |s| cart.load(s);

    defer cart.deinit();

    var interrupt_controller = InterruptController.init();
    var timer = Timer.init(&interrupt_controller);
    var ppu = Ppu.init(&interrupt_controller);
    var joypad = Joypad.init();
    var bus = Bus.init(&cart, &timer, &interrupt_controller, &ppu, &joypad);
    var cpu = Cpu.init(&bus, &interrupt_controller);

    // Initialise console
    var gb = Console.init(&interrupt_controller, &timer, &bus, &cpu, &ppu);

    // --- SDL

    if (!SDL.SDL_Init(SDL.SDL_INIT_VIDEO)) sdlPanic();
    defer SDL.SDL_Quit();

    const window = SDL.SDL_CreateWindow(
        "Game Boy",
        WIDTH * SCALE,
        HEIGHT * SCALE,
        0,
    ) orelse sdlPanic();
    defer SDL.SDL_DestroyWindow(window);

    const renderer = SDL.SDL_CreateRenderer(window, null) orelse sdlPanic();
    defer SDL.SDL_DestroyRenderer(renderer);

    const texture = SDL.SDL_CreateTexture(
        renderer,
        SDL.SDL_PIXELFORMAT_ARGB8888,
        SDL.SDL_TEXTUREACCESS_STREAMING,
        WIDTH,
        HEIGHT,
    ) orelse sdlPanic();
    defer SDL.SDL_DestroyTexture(texture);

    const CYCLES_PER_FRAME: u64 = 70224;

    mainLoop: while (true) {
        const frame_start = SDL.SDL_GetPerformanceCounter();

        var ev: SDL.SDL_Event = undefined;
        while (SDL.SDL_PollEvent(&ev)) {
            switch (ev.type) {
                SDL.SDL_EVENT_QUIT => {
                    try writeSaveData(io, save_path, cart.save());
                    std.debug.print("Game Saved\n", .{});
                    break :mainLoop;
                },

                SDL.SDL_EVENT_KEY_DOWN => {
                    if (ev.key.scancode == SDL.SDL_SCANCODE_S and !ev.key.repeat) {
                        frame_time_ms = if (frame_time_ms == 16) 4 else 16;
                    } else if (!ev.key.repeat) {
                        setKey(&joypad, ev.key.scancode, true);
                    }
                },

                SDL.SDL_EVENT_KEY_UP => {
                    setKey(&joypad, ev.key.scancode, false);
                },

                else => {},
            }
        }

        var frame_cycles: u64 = 0;
        while (frame_cycles < CYCLES_PER_FRAME) {
            frame_cycles += try gb.step() * 4;
        }

        _ = SDL.SDL_UpdateTexture(
            texture,
            null,
            @ptrCast(&gb.ppu.display_buffer),
            WIDTH * @sizeOf(u32),
        );

        _ = SDL.SDL_RenderClear(renderer);
        _ = SDL.SDL_RenderTexture(renderer, texture, null, null);
        _ = SDL.SDL_RenderPresent(renderer);

        const frame_end = SDL.SDL_GetPerformanceCounter();
        const elapsed_ms: u32 = @intCast(@divFloor(
            (frame_end - frame_start) * 1000,
            SDL.SDL_GetPerformanceFrequency(),
        ));

        if (elapsed_ms < frame_time_ms) {
            SDL.SDL_Delay(frame_time_ms - elapsed_ms);
        }
    }
}

fn sdlPanic() noreturn {
    const str = @as(?[*:0]const u8, SDL.SDL_GetError()) orelse "unknown error";
    @panic(std.mem.sliceTo(str, 0));
}

fn setKey(jp: *Joypad, sc: SDL.SDL_Scancode, pressed: bool) void {
    const value: u8 = if (pressed) 0 else 1;

    switch (sc) {
        // D-pad
        SDL.SDL_SCANCODE_RIGHT => setBit(&jp.dpad, 0, value),
        SDL.SDL_SCANCODE_LEFT => setBit(&jp.dpad, 1, value),
        SDL.SDL_SCANCODE_UP => setBit(&jp.dpad, 2, value),
        SDL.SDL_SCANCODE_DOWN => setBit(&jp.dpad, 3, value),

        // Buttons
        SDL.SDL_SCANCODE_Z => setBit(&jp.buttons, 0, value), // A
        SDL.SDL_SCANCODE_X => setBit(&jp.buttons, 1, value), // B
        SDL.SDL_SCANCODE_RSHIFT => setBit(&jp.buttons, 2, value), // Select
        SDL.SDL_SCANCODE_RETURN => setBit(&jp.buttons, 3, value), // Start

        else => {},
    }
}

fn setBit(byte: *u8, bit: u3, value: u8) void {
    if (value == 0) {
        byte.* &= ~(@as(u8, 1) << bit); // pressed
    } else {
        byte.* |= (@as(u8, 1) << bit); // released
    }
}

fn loadFile(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: []const u8,
    buffer: []u8,
) ![:0]u8 {
    // Open file based on CWD and provided relative path
    const cwd: std.Io.Dir = std.Io.Dir.cwd();
    const file: std.Io.File = try cwd.openFile(io, path, .{ .mode = .read_only });
    defer file.close(io);

    var reader = file.reader(io, buffer);

    // Read the file contents into the buffer
    return try std.zig.readSourceFileToEndAlloc(allocator, &reader);
}

fn writeSaveData(
    io: std.Io,
    path: []const u8,
    data: []const u8,
) !void {
    const cwd: std.Io.Dir = std.Io.Dir.cwd();
    const file: std.Io.File = try cwd.createFile(io, path, .{ .read = true });
    defer file.close(io);

    try file.writeStreamingAll(io, data);
}
