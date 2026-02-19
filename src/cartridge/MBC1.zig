const std = @import("std");
const assert = std.debug.assert;

pub const MBC1 = struct {
    allocator: std.mem.Allocator,

    rom: []u8,
    ram: []u8,

    rom_bank: u8,
    ram_bank: u2,

    ram_enabled: bool,

    rom_banking: bool,

    pub fn init(allocator: std.mem.Allocator, data: []const u8, ram_size: usize) !MBC1 {
        assert(data.len <= (2 * 1024 * 1024)); // Up to 2 MiB
        assert(ram_size <= (32 * 1024)); // Up to 32 KiB
        assert(data.len / 0x4000 > 0 and std.math.isPowerOfTwo(data.len / 0x4000));

        const rom = try allocator.alloc(u8, data.len);
        @memcpy(rom, data);

        const ram = try allocator.alloc(u8, ram_size);
        @memset(ram, 0);

        return MBC1{
            .allocator = allocator,
            .rom = rom,
            .rom_bank = 0x1,
            .ram = ram,
            .ram_bank = 0,
            .ram_enabled = false,
            .rom_banking = false,
        };
    }

    pub fn read(self: *MBC1, addr: u16) u8 {
        assert((addr >= 0x000 and addr <= 0x7FFF) or
            (addr >= 0xA000 and addr <= 0xBFFF));
        return switch (addr) {
            0x0000...0x3FFF => self.rom[addr],
            0x4000...0x7FFF => {
                const ix = addr + ((@as(u16, self.rom_bank) - 1) * 0x4000);
                assert(ix < self.rom.len);
                return self.rom[ix];
            },
            0xA000...0xBFFF => {
                if (!self.ram_enabled or self.ram.len == 0) return 0xFF;

                const ix = (addr - 0xA000) + (@as(u16, self.ram_bank) * 0x2000);
                assert(ix < self.ram.len);
                return self.ram[ix];
            },
            else => unreachable,
        };
    }

    pub fn write(self: *MBC1, addr: u16, val: u8) void {
        assert((addr >= 0x000 and addr <= 0x7FFF) or
            (addr >= 0xA000 and addr <= 0xBFFF));
        switch (addr) {
            0x0000...0x1FFF => {
                if (val & 0xF == 0xA) {
                    self.ram_enabled = true;
                } else self.ram_enabled = false;
            },
            0x2000...0x3FFF => {
                const num_banks: usize = self.rom.len / 0x4000;
                const masked_val: u8 = val & (@as(u8, @truncate(num_banks)) - 1);
                if (masked_val == 0x00) {
                    self.rom_bank = (self.rom_bank & 0x60) | 0x1;
                } else self.rom_bank = (self.rom_bank & 0x60) | masked_val;
                self.update_invalid_rom_bank();
            },
            0x4000...0x5FFF => {
                if (self.rom_banking) {
                    self.rom_bank = ((val & 0x03) << 5) | (self.rom_bank & 0x1F);
                } else self.ram_bank = @truncate(val & 0x3);
            },
            0x6000...0x7FFF => {
                self.rom_banking = (val & 0x1 == 0x0);
                if (self.rom_banking) self.ram_bank = 0 else self.rom_bank &= 0x1F;
            },
            0xA000...0xBFFF => {
                if (self.ram_enabled and self.ram.len > 0) {
                    const ix = (addr - 0xA000) + (@as(u16, self.ram_bank) * 0x2000);
                    assert(ix < self.ram.len);
                    self.ram[ix] = val;
                }
            },
            else => unreachable,
        }
    }

    fn update_invalid_rom_bank(self: *MBC1) void {
        if (self.rom_bank == 0x00 or self.rom_bank == 0x20 or self.rom_bank == 0x40 or self.rom_bank == 0x60) {
            self.rom_bank += 1;
        }
    }

    pub fn deinit(self: *MBC1) void {
        self.allocator.free(self.rom);
        self.allocator.free(self.ram);
    }
};
