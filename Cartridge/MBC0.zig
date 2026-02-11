const std = @import("std");
const assert = std.debug.assert;

const MBC0 = struct {
    allocator: std.mem.Allocator,

    rom: []u8,
    ram: []u8,

    pub fn init(allocator: std.mem.Allocator, data: []u8, ram_size: usize) !MBC0 {
        assert(data.len <= (32 * 1024)); // Up to 32 KiB
        assert(ram_size <= (8 * 1024)); // Up to 8 KiB

        const rom = try allocator.alloc(u8, data.len);
        @memcpy(rom, data);

        const ram = try allocator.alloc(u8, ram_size);
        @memset(ram, 0);

        return MBC0{
            .allocator = allocator,
            .rom = rom,
            .ram = ram,
        };
    }

    pub fn read8(self: *MBC0, addr: u16) u8 {
        assert(addr >= 0x000 and addr <= 0xBFFF);
        return switch (addr) {
            0x0000...0x7FFF => self.rom[addr],
            0xA000...0xBFFF => {
                if (self.ram.len > 0) {
                    return self.ram[addr - 0xA000];
                } else return 0xFF;
            },
            else => unreachable,
        };
    }

    pub fn write8(self: *MBC0, addr: u16, val: u8) void {
        if (addr >= 0xA000 and addr <= 0xBFFF and self.ram.len > 0) {
            self.ram[addr - 0xA000] = val;
        }
    }

    pub fn deinit(self: *MBC0) void {
        self.allocator.free(self.rom);
        self.allocator.free(self.ram);
    }
};
