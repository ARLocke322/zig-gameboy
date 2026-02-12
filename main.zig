const Cartridge = @import("./Cartridge/MBC1.zig").MBC1;
const Console = @import("./Gameboy/console.zig").Console;
const std = @import("std");

pub fn main() !void {
    // Read Argv for file path
    var args = std.process.args();
    _ = args.skip();
    const path: [:0]const u8 = args.next() orelse return error.MissingArgs;

    // Initialise allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator: std.mem.Allocator = gpa.allocator();

    // Allocate buffer to store ROM
    const buffer = try allocator.alloc(u8, 4 * 1024 * 1024);
    defer allocator.free(buffer);

    // Initialise IO implementation
    var threaded: std.Io.Threaded = .init(allocator, .{});
    const io = threaded.io();
    defer threaded.deinit();

    // Load ROM into buffer and initialise Cartridge object
    const rom_buffer = try load_file_into_buffer(allocator, io, path, buffer);
    defer allocator.free(rom_buffer);

    // Initialise Cartridge
    var cart = try Cartridge.init(allocator, rom_buffer, get_ram_bytes(buffer[0x0149]));
    defer cart.deinit();

    // Initialise console and run
    var gb = try Console.init(allocator, &cart);
    defer gb.deinit();
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

    // Print test output message (starts at 0xA004)
    std.debug.print("Test output: ", .{});
    var addr: u16 = 0xA004;
    while (addr < 0xA0FF) : (addr += 1) {
        const byte = gb.bus.read8(addr);
        if (byte == 0) break; // Null terminator
        std.debug.print("{c}", .{byte});
    }
    std.debug.print("\n", .{});
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
