const Cartridge = @import("./cartridge/MBC1.zig").MBC1;
const Console = @import("./gameboy/console.zig").Console;
const Cpu = @import("./gameboy/cpu.zig").Cpu;
const Bus = @import("./gameboy/bus.zig").Bus;
const Ppu = @import("./gameboy/ppu.zig").Ppu;
const Timer = @import("./gameboy/timer.zig").Timer;
const InterruptController = @import("./gameboy/interrupt_controller.zig").InterruptController;
const std = @import("std");
const SDL = @cImport({
    @cInclude("SDL3/SDL.h");
});

const FRAME_TIME_MS: u32 = 16; // ~60 FPS, close enough
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
    const path: [:0]const u8 = args.next() orelse return error.MissingArgs;

    // Allocate buffer to store ROM
    const buffer = try allocator.alloc(u8, 4 * 1024 * 1024);
    defer allocator.free(buffer);

    // Load ROM into buffer
    const rom_buffer = try load_file_into_buffer(allocator, io, path, buffer);
    defer allocator.free(rom_buffer);

    // Initialise Cartridge
    var cart = try Cartridge.init(allocator, rom_buffer, get_ram_bytes(buffer[0x0149]));
    defer cart.deinit();

    var interrupt_controller = InterruptController.init();
    var timer = Timer.init(&interrupt_controller);
    var ppu = Ppu.init(&interrupt_controller);
    var bus = Bus.init(&cart, &timer, &interrupt_controller, &ppu);
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
            if (ev.type == SDL.SDL_EVENT_QUIT) break :mainLoop;
        }

        var frame_cycles: u64 = 0;
        while (frame_cycles < CYCLES_PER_FRAME) {
            frame_cycles += try gb.step();
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

        if (elapsed_ms < FRAME_TIME_MS) {
            SDL.SDL_Delay(FRAME_TIME_MS - elapsed_ms);
        }
    }
}

fn sdlPanic() noreturn {
    const str = @as(?[*:0]const u8, SDL.SDL_GetError()) orelse "unknown error";
    @panic(std.mem.sliceTo(str, 0));
}

fn load_file_into_buffer(
    allocator: std.mem.Allocator,
    io: std.Io,
    path: [:0]const u8,
    buffer: []u8,
) ![:0]u8 {
    // Open file based on CWD and provided relative path
    const cwd: std.Io.Dir = std.Io.Dir.cwd();
    const file: std.Io.File = try cwd.openFile(io, path, .{ .mode = .read_only });
    defer file.close(io);

    var reader = file.reader(io, buffer);

    // Read the file contents into the buffer
    const rom_buffer = try std.zig.readSourceFileToEndAlloc(allocator, &reader);
    return rom_buffer;
}

fn get_ram_bytes(code: u16) usize {
    return switch (code) {
        0x00 => 0,
        else => 0,
    };
}
