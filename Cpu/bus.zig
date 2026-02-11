const std = @import("std");

pub const Bus = struct {
    rom_bank_0: [0x4000]u8, // 0x0000-0x3FFF: 16 KiB ROM bank 00
    rom_bank_n: [0x4000]u8, // 0x4000-0x7FFF: 16 KiB ROM bank 01-NN (switchable)
    vram: [0x2000]u8, // 0x8000-0x9FFF: 8 KiB VRAM
    external_ram: [0x2000]u8, // 0xA000-0xBFFF: 8 KiB External RAM
    wram_0: [0x1000]u8, // 0xC000-0xCFFF: 4 KiB WRAM
    wram_n: [0x1000]u8, // 0xD000-0xDFFF: 4 KiB WRAM (switchable in CGB)
    // 0xE000-0xFDFF: Echo RAM (mirror, don't allocate)
    oam: [0xA0]u8, // 0xFE00-0xFE9F: OAM
    // 0xFEA0-0xFEFF: Not usable (don't allocate)
    io_registers: [0x80]u8, // 0xFF00-0xFF7F: I/O Registers
    hram: [0x7F]u8, // 0xFF80-0xFFFE: HRAM
    ie_register: u8,

    pub fn init() Bus {
        return Bus{
            .rom_bank_0 = [_]u8{0} ** 0x4000,
            .rom_bank_n = [_]u8{0} ** 0x4000,
            .vram = [_]u8{0} ** 0x2000,
            .external_ram = [_]u8{0} ** 0x2000,
            .wram_0 = [_]u8{0} ** 0x1000,
            .wram_n = [_]u8{0} ** 0x1000,
            .oam = [_]u8{0} ** 0xA0,
            .io_registers = [_]u8{0} ** 0x80,
            .hram = [_]u8{0} ** 0x7F,
            .ie_register = 0,
        };
    }

    pub fn read8(self: *Bus, address: u16) u8 {
        return switch (address) {
            0x0000...0x3FFF => self.rom_bank_0[address],
            0x4000...0x7FFF => self.rom_bank_n[address - 0x4000],
            0x8000...0x9FFF => self.vram[address - 0x8000],
            0xA000...0xBFFF => self.external_ram[address - 0xA000],
            0xC000...0xCFFF => self.wram_0[address - 0xC000],
            0xD000...0xDFFF => self.wram_n[address - 0xD000],
            0xE000...0xFDFF => self.wram_0[address - 0xE000], // Mirrors C000-DDFF
            0xFE00...0xFE9F => self.oam[address - 0xFE00],
            0xFEA0...0xFEFF => 0xFF, // Prohibited
            0xFF00...0xFF7F => self.io_registers[address - 0xFF00],
            0xFF80...0xFFFE => self.hram[address - 0xFF80],
            0xFFFF => self.ie_register,
        };
    }

    pub fn write8(self: *Bus, address: u16, value: u8) void {
        switch (address) {
            0x0000...0x7FFF => {}, // ROM, ignore writes
            0x8000...0x9FFF => self.vram[address - 0x8000] = value,
            0xA000...0xBFFF => self.external_ram[address - 0xA000] = value,
            0xC000...0xCFFF => self.wram_0[address - 0xC000] = value,
            0xD000...0xDFFF => self.wram_n[address - 0xD000] = value,
            0xE000...0xFDFF => {}, // Prohibited
            0xFE00...0xFE9F => self.oam[address - 0xFE00] = value,
            0xFEA0...0xFEFF => {}, // Prohibited
            0xFF00...0xFF7F => self.io_registers[address - 0xFF00] = value,
            0xFF80...0xFFFE => self.hram[address - 0xFF80] = value,
            0xFFFF => self.ie_register = value,
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
