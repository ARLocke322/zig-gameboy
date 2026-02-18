const std = @import("std");
const MCB0 = @import("../cartridge/MBC1.zig").MBC1;
const Timer = @import("timer.zig").Timer;
const InterruptController = @import("interrupt_controller.zig").InterruptController;
const Ppu = @import("ppu.zig").Ppu;

pub const Bus = struct {
    wram_0: [0x1000]u8, // 0xC000-0xCFFF: 4 KiB WRAM
    wram_n: [0x1000]u8, // 0xD000-0xDFFF: 4 KiB WRAM (switchable in CGB)
    hram: [0x7F]u8, // 0xFF80-0xFFFE: HRAM

    cartridge: *MCB0,
    timer: *Timer,
    interrupts: *InterruptController,
    ppu: *Ppu,
    // joypad: *Joypad,  // future
    // apu: *APU,        // future

    pub fn init(
        cartridge: *MCB0,
        timer: *Timer,
        interrupts: *InterruptController,
        ppu: *Ppu,
    ) Bus {
        return Bus{
            .wram_0 = [_]u8{0} ** 0x1000,
            .wram_n = [_]u8{0} ** 0x1000,
            .hram = [_]u8{0} ** 0x7F,
            .cartridge = cartridge,
            .timer = timer,
            .interrupts = interrupts,
            .ppu = ppu,
        };
    }
    pub fn read8(self: *Bus, address: u16) u8 {
        return switch (address) {
            0x0000...0x7FFF => self.cartridge.read8(address),
            0x8000...0x9FFF => self.ppu.read8(address),
            0xA000...0xBFFF => self.cartridge.read8(address),
            0xC000...0xCFFF => self.wram_0[address - 0xC000],
            0xD000...0xDFFF => self.wram_n[address - 0xD000],
            0xE000...0xFDFF => blk: {
                const mirrored = address - 0x2000; // 0xE000 -> 0xC000
                if (mirrored < 0xD000) {
                    break :blk self.wram_0[mirrored - 0xC000];
                } else {
                    break :blk self.wram_n[mirrored - 0xD000];
                }
            },
            0xFE00...0xFE9F => self.ppu.read8(address),
            0xFEA0...0xFEFF => 0xFF,

            // Timer registers
            0xFF04...0xFF07 => self.timer.read8(address),

            // Interrupt controller
            0xFF0F => self.interrupts.read8(address),
            // Other I/O (split around specific registers)
            0xFF00...0xFF03 => 0xFF,
            0xFF08...0xFF0E => 0xFF,
            0xFF10...0xFF43, 0xFF45...0xFF7F => 0xFF,

            0xFF44 => return 0x90, // Always report VBlank (scanline 144)
            // HRAM and IE
            0xFF80...0xFFFE => self.hram[address - 0xFF80],
            0xFFFF => self.interrupts.read8(address),
        };
    }

    pub fn write8(self: *Bus, address: u16, value: u8) void {
        switch (address) {
            0x0000...0x7FFF => self.cartridge.write8(address, value),
            0x8000...0x9FFF => self.ppu.write8(address, value),
            0xA000...0xBFFF => self.cartridge.write8RAM(address, value),
            0xC000...0xCFFF => self.wram_0[address - 0xC000] = value,
            0xD000...0xDFFF => self.wram_n[address - 0xD000] = value,
            0xE000...0xFDFF => {},
            0xFE00...0xFE9F => self.ppu.write8(address, value),
            0xFEA0...0xFEFF => {},

            0xFF01 => {},
            0xFF02 => {},
            // Timer registers
            0xFF04...0xFF07 => self.timer.write8(address, value),
            0xFF08...0xFF0E => {}, // Unimplemented
            0xFF0F => self.interrupts.write8(address, value),
            0xFF10...0xFF3F => {}, // Sound
            0xFF40...0xFF45, 0xFF47...0xFF4B => self.ppu.write8(address, value),
            0xFF46 => {
                self.ppu.dma = value; // Store DMA register
                // DMA transfer
                const source = @as(u16, value) << 8;
                for (0..0xA0) |i| {
                    const byte = self.read8(source + @as(u16, @intCast(i)));
                    self.ppu.oam[i] = byte;
                }
            },
            0xFF4C...0xFF7F => {},
            0xFF80...0xFFFE => self.hram[address - 0xFF80] = value,
            0xFFFF => self.interrupts.write8(address, value),
            else => std.debug.print("attempted to write to: {x}", .{address}),
        }
    }
    pub fn read16(self: *Bus, address: u16) u16 {
        const low = self.read8(address);
        const high = self.read8(address + 1);
        return (@as(u16, high) << 8) | low;
    }

    pub fn write16(self: *Bus, address: u16, value: u16) void {
        self.write8(address, @truncate(value));
        self.write8(address + 1, @truncate(value >> 8));
    }
};
