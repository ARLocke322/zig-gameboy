const std = @import("std");
const assert = std.debug.assert;

pub const MBC5 = struct {
    allocator: std.mem.Allocator,

    rom: []u8,
    ram: []u8,

    rom_bank: u8,
    ram_bank: u2,

    ram_enabled: bool,

    rom_banking: bool,

    pub fn init(allocator: std.mem.Allocator, data: []u8, ram_size: usize) !MBC5 {
        assert(data.len <= (2 * 1024 * 1024)); // Up to 2 MiB
        assert(ram_size <= (32 * 1024)); // Up to 32 KiB

        const rom = try allocator.alloc(u8, data.len);
        @memcpy(rom, data);

        const ram = try allocator.alloc(u8, ram_size);
        @memset(ram, 0);

        return MBC5{
            .allocator = allocator,
            .rom = rom,
            .rom_bank = 0x1,
            .ram = ram,
            .ram_bank = 0,
            .ram_enabled = false,
            .rom_banking = false,
        };
    }

    pub fn read8(self: *MBC5, addr: u16) u8 {
        assert(addr >= 0x000 and addr <= 0xBFFF);
        return switch (addr) {
            0x0000...0x3FFF => self.rom[addr],
            0x4000...0x7FFF => {},
            0xA000...0xBFFF => {},
            else => unreachable,
        };
    }

    pub fn write8(self: *MBC5, addr: u16, val: u8) void {
        _ = val;
        _ = self;
        assert(addr >= 0x000 and addr <= 0x7FFF);
        switch (addr) {
            0x0000...0x1FFF => {},
            0x2000...0x3FFF => {},
            0x4000...0x5FFF => {},
            0x6000...0x7FFF => {},
            else => unreachable,
        }
    }

    pub fn write8RAM(self: *MBC5, addr: u16, val: u8) void {
        _ = addr;
        _ = val;
        if (self.ram_enabled) {}
    }

    fn update_invalid_rom_bank(self: *MBC5) void {
        if (self.rom_bank == 0x00 or self.rom_bank == 0x20 or self.rom_bank == 0x40 or self.rom_bank == 0x60) {
            self.rom_bank += 1;
        }
    }

    pub fn deinit(self: *MBC5) void {
        self.allocator.free(self.rom);
        self.allocator.free(self.ram);
    }
};
