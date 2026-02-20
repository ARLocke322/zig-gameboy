const std = @import("std");
const assert = std.debug.assert;

pub const MBC3 = struct {
    allocator: std.mem.Allocator,

    rom: []u8,
    ram: []u8,

    rom_bank: u8,
    ram_bank: u4,

    ram_timer_enabled: bool,

    rtc_s: u8 = 0,
    rtc_m: u8 = 0,
    rtc_h: u8 = 0,
    rtc_dl: u8 = 0,
    rtc_dh: u8 = 0,

    latched_rtc_s: u8 = 0,
    latched_rtc_m: u8 = 0,
    latched_rtc_h: u8 = 0,
    latched_rtc_dl: u8 = 0,
    latched_rtc_dh: u8 = 0,

    rtc_latch: u8 = 0,

    pub fn init(allocator: std.mem.Allocator, data: []const u8, ram_size: usize) !MBC3 {
        assert(data.len <= (2 * 1024 * 1024)); // Up to 2 MiB
        assert(ram_size <= (32 * 1024)); // Up to 32 KiB
        assert(data.len / 0x4000 > 0 and std.math.isPowerOfTwo(data.len / 0x4000));

        const rom = try allocator.alloc(u8, data.len);
        @memcpy(rom, data);

        const ram = try allocator.alloc(u8, ram_size);
        @memset(ram, 0);

        return MBC3{
            .allocator = allocator,
            .rom = rom,
            .rom_bank = 0x1,
            .ram = ram,
            .ram_bank = 0,
            .ram_timer_enabled = false,
        };
    }

    pub fn read(self: *MBC3, addr: u16) u8 {
        assert((addr >= 0x0000 and addr <= 0x7FFF) or
            addr >= 0xA000 and addr <= 0xBFFF);
        return switch (addr) {
            0x0000...0x3FFF => self.rom[addr],
            0x4000...0x7FFF => {
                const ix = addr + ((@as(u32, self.rom_bank) - 1) * 0x4000);
                assert(ix < self.rom.len);
                return self.rom[ix];
            },
            0xA000...0xBFFF => self.readRamOrRtc(addr),
            else => unreachable,
        };
    }

    pub fn write(self: *MBC3, addr: u16, val: u8) void {
        assert((addr >= 0x0000 and addr <= 0x7FFF) or
            addr >= 0xA000 and addr <= 0xBFFF);
        switch (addr) {
            0x0000...0x1FFF => {
                self.ram_timer_enabled = if (val == 0x0A) true else false;
            },
            0x2000...0x3FFF => {
                const num_banks: u8 = @truncate(self.rom.len / 0x4000);
                const masked: u8 = val & 0x7F & (num_banks - 1);
                self.rom_bank = if (masked == 0) 0x01 else masked;
            },
            0x4000...0x5FFF => {
                if (val <= 0x0C) self.ram_bank = @truncate(val);
            },
            0x6000...0x7FFF => {
                if (self.rtc_latch == 0x00 and val == 0x01) {
                    self.latched_rtc_s = self.rtc_s;
                    self.latched_rtc_m = self.rtc_m;
                    self.latched_rtc_h = self.rtc_h;
                    self.latched_rtc_dl = self.rtc_dl;
                    self.latched_rtc_dh = self.rtc_dh;
                }
                self.rtc_latch = val;
            },
            0xA000...0xBFFF => self.writeRamOrRtc(addr, val),
            else => unreachable,
        }
    }

    fn writeRamOrRtc(self: *MBC3, addr: u16, val: u8) void {
        switch (self.ram_bank) {
            0x00...0x07 => if (self.ram_timer_enabled and self.ram.len > 0) {
                const ix = (addr - 0xA000) + (@as(u16, self.ram_bank) * 0x2000);
                assert(ix < self.ram.len);
                self.ram[ix] = val;
            },
            0x08 => self.rtc_s = val,
            0x09 => self.rtc_m = val,
            0x0A => self.rtc_h = val,
            0x0B => self.rtc_dl = val,
            0x0C => self.rtc_dh = val,
            else => {},
        }
    }

    fn readRamOrRtc(self: *MBC3, addr: u16) u8 {
        switch (self.ram_bank) {
            0x00...0x07 => {
                if (!self.ram_timer_enabled or self.ram.len == 0) return 0xFF;

                const ix = (addr - 0xA000) + (@as(u16, self.ram_bank) * 0x2000);
                assert(ix < self.ram.len);
                return self.ram[ix];
            },
            0x08 => return self.latched_rtc_s,
            0x09 => return self.latched_rtc_m,
            0x0A => return self.latched_rtc_h,
            0x0B => return self.latched_rtc_dl,
            0x0C => return self.latched_rtc_dh,
            else => return 0xFF,
        }
    }

    pub fn deinit(self: *MBC3) void {
        self.allocator.free(self.rom);
        self.allocator.free(self.ram);
    }
};
