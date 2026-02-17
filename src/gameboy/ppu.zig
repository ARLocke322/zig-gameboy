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
    display_buffer: [160 * 144]u32,
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
            .display_buffer = [_]u32{0} ** (160 * 144),
        };
    }

    pub fn read8(self: *Ppu, addr: u16) u8 {
        assert((addr >= 0x8000 and addr <= 0x9FFF) or
            (addr >= 0xFE00 and addr <= 0xFF4B) and
                addr != 0xFF46);
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
            0xFF46 => unreachable,
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
            0xFF46 => unreachable,
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
        // starting addr of background tilemap, 2 possible regions
        const map_base: u16 = if ((self.latched_lcd_control & 0x08) != 0) 0x9C00 else 0x9800;
        // starting addr of tile, 2 possible tiles
        const tile_base: u16 = if ((self.latched_lcd_control & 0x10) != 0) 0x8000 else 0x9000;
        const use_unsigned_tiles = (self.latched_lcd_control & 0x10) != 0;

        var palette: [4]u32 = undefined;
        for (0..4) |i| {
            palette[i] = PALETTE[(self.latched_bgp >> @intCast(i * 2)) & 3];
        }

        for (0..160) |x| {
            // absolute x and y positions with scroll
            const map_x: u8 = @as(u8, x) +% self.latched_scx;
            const map_y: u8 = self.ly +% self.latched_scy;
            self.render_pixel(map_base, tile_base, use_unsigned_tiles, palette, @as(u8, x), map_x, map_y);
        }
    }

    fn render_window(self: *Ppu) void {
        const map_base: u16 = if ((self.latched_lcd_control & 0x40) != 0) 0x9C00 else 0x9800;
        const tile_base: u16 = if ((self.latched_lcd_control & 0x10) != 0) 0x8000 else 0x9000;
        const use_unsigned_tiles = (self.latched_lcd_control & 0x10) != 0;
        var palette: [4]u32 = undefined;
        for (0..4) |i| {
            palette[i] = PALETTE[(self.latched_bgp >> @intCast(i * 2)) & 3];
        }

        assert(self.latched_wx > 6);
        const window_x_start: u16 = self.latched_wx - 7;

        for (0..160) |x| {
            if (@as(u8, x) < window_x_start) continue;
            // absolute x, y positions in window
            const map_x: u8 = @as(u8, x) - window_x_start;
            const map_y: u8 = self.window_line;
            self.render_pixel(map_base, tile_base, use_unsigned_tiles, palette, @as(u8, x), map_x, map_y);
        }

        self.window_line +%= 1;
    }

    fn render_pixel(
        self: *Ppu,
        map_base: u16,
        tile_base: u16,
        use_unsigned_tiles: bool,
        palette: [4]u32,
        x: u8,
        map_x: u8,
        map_y: u8,
    ) void {
        // which tile the pixel falls in
        const tile_x: u8 = @divFloor(map_x, 8);
        const tile_y: u8 = @divFloor(map_y, 8);

        // calculate tile index address and read it
        const tilemap_addr: u16 = map_base + @as(u16, tile_y) * 32 + tile_x;
        const tile_idx = self.read8(tilemap_addr); // e.g. we are drawing tile 4

        // calculate offset based on lcd control + tile index
        const tile_offset: i16 = if (use_unsigned_tiles)
            @as(i16, tile_idx)
        else
            @as(i8, @bitCast(tile_idx));

        // address of actual tiles pixel data, each tile is 16 bytes
        const tile_addr: u16 = tile_base +% @as(u16, @bitCast(tile_offset * 16));

        // which pixel in 8x8 tile
        const pixel_x: u8 = map_x % 8;
        const pixel_y: u8 = map_y % 8;

        // the two bytes encoding the row of the tile
        const byte1: u8 = self.read8(tile_addr + pixel_y * 2);
        const byte2: u8 = self.read8(tile_addr + pixel_y * 2 + 1);

        // calculate the pixels position in this row of bytes, then get the color idx
        const bit_pos: u3 = @intCast(7 - pixel_x);
        const color_idx: u2 = @intCast(((byte1 >> bit_pos) & 1) | (((byte2 >> bit_pos) & 1) << 1));

        self.display_buffer[self.ly * 160 + x] = palette[color_idx];
    }

    fn render_sprites(self: *Ppu) void {
        const sprite_height: u8 = if ((self.latched_lcd_control & 0x04) != 0) 16 else 8;
        var sprites_on_line: [10]u8 = undefined;
        var sprite_count: u8 = 0;

        // Scan OAM for sprites on this line (max 10)
        var i: u8 = 0;
        while (i < 40 and sprite_count < 10) : (i += 1) {
            const oam_addr = i * 4;
            const sprite_y = self.oam[oam_addr];
            const sprite_line = @as(i16, self.ly) - (@as(i16, sprite_y) - 16);

            if (sprite_line >= 0 and sprite_line < sprite_height) {
                sprites_on_line[sprite_count] = i;
                sprite_count += 1;
            }
        }

        // Render sprites in reverse priority (lowest priority first)
        var s: i8 = @as(i8, @intCast(sprite_count)) - 1;
        while (s >= 0) : (s -= 1) {
            const sprite_idx = sprites_on_line[@intCast(s)];
            const oam_addr = sprite_idx * 4;
            const sprite_y = self.oam[oam_addr];
            const sprite_x = self.oam[oam_addr + 1];
            var tile_idx = self.oam[oam_addr + 2];
            const flags = self.oam[oam_addr + 3];

            const palette_num = (flags >> 4) & 1;
            const x_flip = (flags & 0x20) != 0;
            const y_flip = (flags & 0x40) != 0;
            const behind_bg = (flags & 0x80) != 0;

            var palette: [4]u32 = undefined;
            const palette_data = if (palette_num == 0) self.latched_obp0 else self.latched_obp1;
            for (0..4) |p| {
                palette[p] = PALETTE[(palette_data >> @intCast(p * 2)) & 3];
            }

            const sprite_line = @as(i16, self.ly) - (@as(i16, sprite_y) - 16);
            var pixel_y: u8 = @intCast(sprite_line);
            if (y_flip) pixel_y = (sprite_height - 1) - pixel_y;

            if (sprite_height == 16) tile_idx &= 0xFE;

            const tile_addr = 0x8000 + @as(u16, tile_idx) * 16;
            const byte1 = self.read8(tile_addr + pixel_y * 2);
            const byte2 = self.read8(tile_addr + pixel_y * 2 + 1);

            for (0..8) |px| {
                const screen_x = @as(i16, sprite_x) - 8 + @as(i16, @intCast(px));
                if (screen_x < 0 or screen_x >= 160) continue;

                var pixel_x: u8 = @intCast(px);
                if (x_flip) pixel_x = 7 - pixel_x;

                const bit_pos: u3 = @intCast(7 - pixel_x);
                const color_id: u2 = @intCast(((byte1 >> bit_pos) & 1) | (((byte2 >> bit_pos) & 1) << 1));

                if (color_id == 0) continue; // Transparent

                const buffer_idx = self.ly * 160 + @as(usize, @intCast(screen_x));
                if (!behind_bg or self.display_buffer[buffer_idx] == palette[0]) {
                    self.display_buffer[buffer_idx] = palette[color_id];
                }
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
};
