const std = @import("std");
const MCB0 = @import("../Cartridge/MBC0.zig").MBC0;

pub const Bus = struct {
    vram: [0x2000]u8, // 0x8000-0x9FFF: 8 KiB VRAM
    wram_0: [0x1000]u8, // 0xC000-0xCFFF: 4 KiB WRAM
    wram_n: [0x1000]u8, // 0xD000-0xDFFF: 4 KiB WRAM (switchable in CGB)
    // 0xE000-0xFDFF: Echo RAM (mirror, don't allocate)
    oam: [0xA0]u8, // 0xFE00-0xFE9F: OAM
    // 0xFEA0-0xFEFF: Not usable (don't allocate)
    io_registers: [0x80]u8, // 0xFF00-0xFF7F: I/O Registers
    hram: [0x7F]u8, // 0xFF80-0xFFFE: HRAM
    ie_register: u8,
    cartridge: MCB0,

    pub fn init() Bus {
        return Bus{
            .vram = [_]u8{0} ** 0x2000,
            .wram_0 = [_]u8{0} ** 0x1000,
            .wram_n = [_]u8{0} ** 0x1000,
            .oam = [_]u8{0} ** 0xA0,
            .io_registers = [_]u8{0} ** 0x80,
            .hram = [_]u8{0} ** 0x7F,
            .ie_register = 0,
            .cartridge = undefined,
        };
    }

    pub fn read8(self: *Bus, address: u16) u8 {
        return switch (address) {
            0x0000...0x3FFF => self.cartridge.read8(address),
            0x4000...0x7FFF => self.cartridge.read8(address),
            0x8000...0x9FFF => self.vram[address - 0x8000],
            0xA000...0xBFFF => self.cartridge.read8(address),
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
            0xA000...0xBFFF => self.cartridge.write8RAM(address, value),
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

    pub fn loadRom(self: *Bus, allocator: std.mem.Allocator, path: []const u8) !void {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const size = try file.getEndPos();
        const data = try file.readToEndAlloc(allocator, size);

        std.debug.assert(data.len >= 0x150);

        self.cartridge = MCB0.init(
            allocator,
            data,
            get_ram_bytes(data[0x0149]),
        );
    }

    fn get_ram_bytes(code: u16) usize {
        return switch (code) {
            0x00 => 0,
            else => 0,
        };
    }
};
