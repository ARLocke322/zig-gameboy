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
    dma: u8, // FF46
    bgp: u8, // FF47
    obp0: u8, // FF48
    obp1: u8, // FF49
    wy: u8, // FF4A
    wx: u8, // FF4B
    window_line: u8,
    cycles: u16,
    interrupt_controller: *InterruptController,
    display_buffer: []u8,
    // Internal latched values
    latched_scx: u8 = 0,
    latched_scy: u8 = 0,
    latched_bgp: u8 = 0,
    latched_obp0: u8 = 0,
    latched_obp1: u8 = 0,
    latched_lcd_control: u8 = 0,
    latched_wy: u8 = 0,
    latched_wx: u8 = 0,

    const PALETTE: [4]u32 = .{ 0xFFE0F8D0, 0xFF88C070, 0xFF346856, 0xFF081820 };

    pub fn init(interrupt_controller: *InterruptController) Ppu {
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
            .dma = 0,
            .bgp = 0,
            .obp0 = 0,
            .obp1 = 0,
            .wy = 0,
            .wx = 0,
            .window_line = 0,
            .cycles = 0,
            .interrupt_controller = interrupt_controller,
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
            0xFF46 => self.dma, // reading DMA doesnt do anything
            0xFF47 => self.bgp,
            0xFF48 => self.obp0,
            0xFF49 => self.obp1,
            0xFF4A => self.wy,
            0xFF4B => self.wx,
            else => unreachable,
        };
    }

    pub fn write8(
        self: *Ppu,
        addr: u16,
        val: u8,
    ) void {
        assert((addr >= 0x8000 and addr <= 0x9FFF) or
            (addr >= 0xFE00 and addr <= 0xFF4B));
        switch (addr) {
            0x8000...0x97FF => self.tile_data[addr - 0x8000] = val,
            0x9800...0x9BFF => self.tile_map_1[addr - 0x9800] = val,
            0x9C00...0x9FFF => self.tile_map_2[addr - 0x9C00] = val,
            0xFE00...0xFE9F => self.oam[addr - 0xFE00] = val,
            0xFF40 => self.lcd_control = val,
            0xFF41 => self.stat = (val & 0xF8) | (self.stat & 0x07),
            0xFF42 => self.scy = val,
            0xFF43 => self.scx = val,
            0xFF44 => {},
            0xFF45 => {
                self.lyc = val;
            },
            0xFF46 => {
                self.dma = val;
                self.handle_dma();
            },
            0xFF47 => self.bgp = val,
            0xFF48 => self.obp0 = val,
            0xFF49 => self.obp1 = val,
            0xFF4A => self.wy = val,
            0xFF4B => self.wx = val,
            else => unreachable,
        }
    }

    pub fn tick(self: *Ppu, cycles: u8) void {
        if ((self.lcd_control & 0x80) == 0) {
            self.set_ppu_mode(2);
            return;
        }

        self.cycles += cycles;
        const mode: u2 = @truncate(self.stat);
        switch (mode) {
            0x00 => self.handle_hblank(),
            0x01 => self.handle_vblank(),
            0x02 => self.handle_oam_scan(),
            0x03 => self.handle_render(),
        }

        self.check_lyc_match();
    }

    fn handle_hblank(self: *Ppu) void {
        if (self.cycles >= 204) {
            self.ly +%= 1;
            self.cycles -= 204;
            if (self.ly == 144) {
                self.set_ppu_mode(1);
                self.interrupt_controller.request(InterruptController.VBLANK);
            } else self.set_ppu_mode(2);
        }
    }

    fn handle_vblank(self: *Ppu) void {
        if (self.cycles >= 456) {
            self.ly +%= 1;
            self.cycles -= 456;
            if (self.ly > 153) {
                self.ly = 0;
                self.window_line = 0;
                self.set_ppu_mode(2);
            }
        }
    }

    fn handle_oam_scan(self: *Ppu) void {
        if (self.cycles >= 80) {
            self.latched_scx = self.scx;
            self.latched_scy = self.scy;
            self.latched_bgp = self.bgp;
            self.latched_obp0 = self.obp0;
            self.latched_obp1 = self.obp1;
            self.latched_lcd_control = self.lcd_control;
            self.latched_wx = self.wx;
            self.latched_wy = self.wy;
            self.set_ppu_mode(3);
            self.cycles -= 80;
        }
    }

    fn handle_render(self: *Ppu) void {
        if (self.cycles >= 172) {
            self.render_scanline();
            self.set_ppu_mode(0);
            self.cycles -= 172;
        }
    }

    fn render_scanline(self: *Ppu) void {
        self.render_background();
        if ((self.latched_lcd_control & 0x20) != 0 and
            self.ly >= self.latched_wy and
            self.latched_wx <= 159) self.render_window();
        if ((self.latched_lcd_control & 0x2) != 0) self.render_sprites();
    }

    fn render_background(self: *Ppu) void {
        const map_base = if (self.latched_lcd_control & 0x08 != 0) 0x9C00 else 0x9800;
        const tile_base = if (self.latched_lcd_control & 0x10 != 0) 0x8000 else 0x9000;
        const use_unsigned_tiles = (self.latched_lcd_control & 0x10) != 0;

        var palette: [4]u32 = undefined;
        for (0..4) |i| {
            palette[i] = self.PALETTE[(self.latched_bgp >> @intCast(i * 2)) & 3];
        }

        for (0..160) |x| {
            const map_x: u8 = x +% self.latched_scx;
            const map_y: u8 = self.ly +% self.latched_scy;
            //
            // const tile_col = map_x / 8;
            // const tile_row = map_y / 8;
            // const tilemap_addr = map_base + tile_row * 32 + tile_col;
            // const tile_id = self.read8(tilemap_addr);

            // const tile_addr = tile_base ;
            //

            const tile_idx_addr = map_base + (map_y / 8) * 32 + (map_x / 8);
            const tile_idx = self.read8(tile_idx_addr);
            const tile_addr = tile_base + tile_idx * 16;
            const row = map_y % 8;
            const b1 = self.read8(tile_addr + row * 2);
            const b2 = self.read8(tile_addr + row * 2 + 1);
            const bit = 7 - (map_x % 8);
            const color_id = ((b1 >> bit) & 1) | (((b2 >> bit) & 1) << 1);
            self.screen_buffer[self.window_line * 160 + x] = palette[color_id];
        }
    }

    fn render_window(self: *Ppu) void {
        for (0..160) |x| {
            if (x >= self.latched_wx) {
                self.wx = x - self.latched_wx;
            }
        }
    }

    fn set_ppu_mode(self: *Ppu, mode: u2) void {
        self.stat = (self.stat & 0xFC) | mode;
    }

    fn check_lyc_match(self: *Ppu) void {
        if (self.lyc == self.ly) {
            self.stat |= 0x4;
            if ((self.stat & 0x40) != 0) {
                self.interrupt_controller.request(InterruptController.LCD_STAT);
            }
        } else self.stat &= 0xFB;
    }

    fn handle_dma() void {
        std.debug.print("dma", .{});
    }
};
