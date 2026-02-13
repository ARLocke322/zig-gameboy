const std = @import("std");
const assert = std.debug.assert;
const InterruptController = @import("interrupt_controller.zig").InterruptController;

pub const Ppu = struct {
    tile_data: [0x1800]u8, // 8000 - 97FF
    tile_map_1: [0x400]u8, // 9800 - 9BFF (fixed size)
    tile_map_2: [0x400]u8, // 9C00 - 9FFF (fixed size)
    oam: [0xA0]u8, // FE00 - FE9F (fixed size)
    lcd_control: u8, // FF40
    stat: u8, // FF41
    scy: u8, // FF42
    scx: u8, // FF43
    ly: u8, // FF44
    lyc: u8, // FF45
    bgp: u8, // FF47
    obp0: u8, // FF48
    obp1: u8, // FF49
    wy: u8, // FF4A
    wx: u8, // FF4B

    pub fn init() Ppu {
        return Ppu{
            .tile_data = [_]u8{0} ** 0x1800,
            .tile_map_1 = [_]u8{0} ** 0x400,
            .tile_map_2 = [_]u8{0} ** 0x400,
            .oam = [_]u8{0} ** 0xA0,
            .lcd_control = 0,
            .stat = 0,
            .scy = 0,
            .scx = 0,
            .ly = 0,
            .lyc = 0,
            .bgp = 0,
            .obp0 = 0,
            .obp1 = 0,
            .wy = 0,
            .wx = 0,
        };
    }

    pub fn read8(self: *Ppu, addr: u16) u8 {
        assert((addr >= 0x8000 and addr <= 0x9FFF) or
            (addr >= 0xFE00 and addr <= 0xFF4B));
        return switch (addr) {
            0x8000...0x97FF => self.tile_data[addr - 0x8000],
            0x9800...0x9BFF => self.tile_map_1[addr - 0x9800],
            0x9C00...0x9FFF => self.tile_map_2[addr - 0x9C00],
            0xFE00...0xFE9F => self.oam[addr - 0xFE00],
            0xFF40 => self.lcd_control,
            0xFF41 => self.stat,
            0xFF42 => self.scy,
            0xFF43 => self.scx,
            0xFF44 => self.ly,
            0xFF45 => self.lyc,
            0xFF47 => self.bgp,
            0xFF48 => self.obp0,
            0xFF49 => self.obp1,
            0xFF4A => self.wy,
            0xFF4B => self.wx,
        };
    }

    pub fn write8(
        self: *Ppu,
        addr: u16,
        val: u8,
        interrupt_controller: *InterruptController,
    ) void {
        assert((addr >= 0x8000 and addr <= 0x9FFF) or
            (addr >= 0xFE00 and addr <= 0xFF4B));
        switch (addr) {
            0x8000...0x97FF => self.tile_data[addr - 0x8000] = val,
            0x9800...0x9BFF => self.tile_map_1[addr - 0x9800] = val,
            0x9C00...0x9FFF => self.tile_map_2[addr - 0x9C00] = val,
            0xFE00...0xFE9F => self.oam[addr - 0xFE00] = val,
            0xFF40 => self.lcd_control = val,
            0xFF41 => self.stat = val,
            0xFF42 => self.scy = val,
            0xFF43 => self.scx = val,
            0xFF44 => {},
            0xFF45 => self.lyc = val,
            0xFF47 => self.bgp = val,
            0xFF48 => self.obp0 = val,
            0xFF49 => self.obp1 = val,
            0xFF4A => self.wy = val,
            0xFF4B => self.wx = val,
        }
        if (self.lyc == self.ly) {
            self.stat |= 0x2;
            interrupt_controller.request(InterruptController.LCD_STAT);
        }
    }
};
