const std = @import("std");
const assert = std.debug.assert;

pub const MBC0 = struct {
    allocator: std.mem.Allocator,
    rom: []u8,

    pub fn init(allocator: std.mem.Allocator, data: []const u8, ram_size: usize) !MBC0 {
        assert(data.len <= (32 * 1024)); // Up to 32 KiB

        const rom = try allocator.alloc(u8, data.len);
        @memcpy(rom, data);

        _ = ram_size;

        return MBC0{
            .allocator = allocator,
            .rom = rom,
        };
    }

    pub fn read(self: *MBC0, addr: u16) u8 {
        assert(addr >= 0x000 and addr <= 0x7FFF);
        return switch (addr) {
            0x0000...0x7FFF => self.rom[addr],
            else => unreachable,
        };
    }

    pub fn write(self: *MBC0, addr: u16, val: u8) void {
        _ = self;
        _ = addr;
        _ = val;
    }

    pub fn deinit(self: *MBC0) void {
        self.allocator.free(self.rom);
    }
};
