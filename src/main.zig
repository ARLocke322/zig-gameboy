const Cartridge = @import("./Cartridge/MBC1.zig").MBC1;
const Console = @import("./Gameboy/console.zig").Console;
const Cpu = @import("./Gameboy/cpu.zig").Cpu;
const Bus = @import("./Gameboy/bus.zig").Bus;
const Timer = @import("./Gameboy/timer.zig").Timer;
const InterruptController = @import("./Gameboy/interrupt_controller.zig").InterruptController;
const std = @import("std");

const zig_gameboy = @import("zig_gameboy");

pub fn main(init: std.process.Init) !void {
    // Initialise allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator: std.mem.Allocator = gpa.allocator();

    // Read Argv for file path
    var args = try init.minimal.args.iterateAllocator(allocator);
    _ = args.skip();
    const path: [:0]const u8 = args.next() orelse return error.MissingArgs;

    // Initialise IO implementation
    var threaded: std.Io.Threaded = .init(allocator, .{ .environ = init.minimal.environ });
    const io = threaded.io();
    defer threaded.deinit();

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
    var bus = Bus.init(&cart, &timer, &interrupt_controller);
    var cpu = Cpu.init(&bus, &interrupt_controller);

    // Initialise console and run
    var gb = Console.init(&interrupt_controller, &timer, &bus, &cpu);
    gb.run();

    // Check result
    const result = gb.bus.read8(0xA000);
    if (result == 0x00) {
        std.debug.print("Test still running...\n", .{});
    } else if (result == 0x80) {
        std.debug.print("✓ PASSED ALL TESTS\n", .{});
    } else {
        std.debug.print("✗ FAILED with code: 0x{X:0>2}\n", .{result});
    }
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
