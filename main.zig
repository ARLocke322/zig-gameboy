const Cartridge = @import("./Cartridge/MBC0.zig").MBC0;
const Console = @import("./Gameboy/console.zig").Console;
const std = @import("std");

pub fn main() !void {
    var cart = try loadRom(allocator, io, "./roms/cpu_instrs.gb");
    defer allocator.free(cart.rom); // Free ROM data

    var gb = Console.init(&cart);
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

pub fn loadRom(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !Cartridge {
    return Cartridge.init(allocator, data, get_ram_bytes(data[0x0149]));
}

fn get_ram_bytes(code: u16) usize {
    return switch (code) {
        0x00 => 0,
        else => 0,
    };
}
