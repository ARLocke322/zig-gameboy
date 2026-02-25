const std = @import("std");
const Cartridge = @import("../cartridge/cartridge.zig").Cartridge;
const Timer = @import("timer.zig").Timer;
const InterruptController = @import("interrupt_controller.zig").InterruptController;
const Ppu = @import("ppu.zig").Ppu;
const Joypad = @import("joypad.zig").Joypad;
const assert = std.debug.assert;

pub const Bus = struct {
    vram: [0x2000]u8, // 0x8000-0x9FFF: 8 KiB VRAM
    wram_0: [0x1000]u8, // 0xC000-0xCFFF: 4 KiB WRAM
    wram_n: [0x1000]u8, // 0xD000-0xDFFF: 4 KiB WRAM (switchable in CGB)
    hram: [0x7F]u8, // 0xFF80-0xFFFE: HRAM
    audio_regs: [0x30]u8, // FF10-FF3F

    cgb: bool,
    wbk: u3,

    cartridge: *Cartridge,
    timer: *Timer,
    interrupts: *InterruptController,
    ppu: *Ppu,
    joypad: *Joypad, // future
    // apu: *APU,        // future

    pub fn init(
        cartridge: *Cartridge,
        timer: *Timer,
        interrupts: *InterruptController,
        ppu: *Ppu,
        joypad: *Joypad,
        cgb: bool,
    ) Bus {
        return Bus{
            .vram = [_]u8{0} ** 0x2000,
            .wram_0 = [_]u8{0} ** 0x1000,
            .wram_n = [_]u8{0} ** 0x1000,
            .hram = [_]u8{0} ** 0x7F,
            .audio_regs = [_]u8{0} ** 0x30,
            .cgb = cgb,
            .wbk = 0x1,
            .cartridge = cartridge,
            .timer = timer,
            .interrupts = interrupts,
            .ppu = ppu,
            .joypad = joypad,
        };
    }
    pub fn read8(self: *Bus, address: u16) u8 {
        return switch (address) {
            0x0000...0x7FFF => self.cartridge.read(address),
            0x8000...0x9FFF => self.ppu.read8(address),
            0xA000...0xBFFF => self.cartridge.read(address),
            0xC000...0xCFFF => self.wram_0[address - 0xC000],
            0xD000...0xDFFF => {
                if (self.cgb) {
                    const ix = address + ((@as(u16, self.wbk) - 1) * 0xD000);
                    assert(ix < self.wram_n.len);
                    return self.wram_n[ix];
                } else return self.wram_n[address - 0xD000];
            },
            0xE000...0xFDFF => {
                const mirrored = address - 0x2000;
                if (mirrored < 0xD000) {
                    return self.wram_0[mirrored - 0xC000];
                } else {
                    return self.wram_n[mirrored - 0xD000];
                }
            },
            0xFE00...0xFE9F => self.ppu.read8(address),
            0xFEA0...0xFEFF => 0xFF,

            0xFF00 => self.joypad.read(address), // joypad
            0xFF01 => 0xFF, // serial data
            0xFF02 => 0x7C, // serial control

            0xFF03 => 0xFF,
            // Timer registers
            0xFF04...0xFF07 => self.timer.read8(address),

            // Interrupt controller
            0xFF0F => self.interrupts.read8(address),
            0xFF08...0xFF0E => 0xFF,
            0xFF10...0xFF25 => self.audio_regs[address - 0xFF10],
            0xFF26 => 0xF0 | (self.audio_regs[0x16] & 0x80), // preserve master enable, channels always inactive
            0xFF27...0xFF2F => 0xFF,
            0xFF30...0xFF3F => self.audio_regs[address - 0xFF10],

            0xFF40...0xFF4B => self.ppu.read8(address),
            0xFF4C...0xFF4D => 0xFF, // KEY CGB
            0xFF70 => @as(u8, self.wbk),

            0xFF80...0xFFFE => self.hram[address - 0xFF80],
            0xFFFF => self.interrupts.read8(address),
            else => 0xFF,
        };
    }

    pub fn write8(self: *Bus, address: u16, value: u8) void {
        switch (address) {
            0x0000...0x7FFF => self.cartridge.write(address, value),
            0x8000...0x9FFF => self.ppu.write8(address, value),
            0xA000...0xBFFF => self.cartridge.write(address, value),
            0xC000...0xCFFF => self.wram_0[address - 0xC000] = value,
            0xD000...0xDFFF => self.wram_n[address - 0xD000] = value,
            0xE000...0xFDFF => {},
            0xFE00...0xFE9F => self.ppu.write8(address, value),
            0xFEA0...0xFEFF => {},

            0xFF00 => self.joypad.write(address, value),
            0xFF01 => {},
            0xFF02 => {},
            0xFF03 => {},

            // Timer registers
            0xFF04...0xFF07 => self.timer.write8(address, value),
            0xFF08...0xFF0E => {}, // Unimplemented
            0xFF0F => self.interrupts.write8(address, value),
            0xFF10...0xFF3F => {
                self.audio_regs[address - 0xFF10] = value;
            },
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
            0xFF4C...0xFF4D => {}, // KEY1 KEY2
            0xFF4F => self.ppu.write8(address, value),
            0xFF50 => {}, // Boot ROM mapping control
            0xFF51...0xFF55 => {}, // vram dma
            0xFF56 => {}, // IR
            0xFF68...0xFF6C => self.ppu.write8(address, value),
            0xFF70 => {
                const u3_val: u3 = @truncate(value);
                if (u3_val == 0) {
                    self.wbk = 1;
                } else self.wbk = u3_val;
            },
            0xFF80...0xFFFE => self.hram[address - 0xFF80] = value,
            0xFFFF => self.interrupts.write8(address, value),
            else => {},
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
