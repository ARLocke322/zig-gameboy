const std = @import("std");
const execute = @import("execute.zig").execute;
const helpers = @import("helpers.zig");

const Register = @import("register.zig").Register;
const Bus = @import("bus.zig").Bus;

pub const Cpu = struct {
    AF: Register,
    BC: Register,
    DE: Register,
    HL: Register,
    SP: Register,
    PC: Register,

    mem: *Bus,

    IME: bool,

    pub fn init(mem: *Bus) Cpu {
        return Cpu{
            .AF = Register.init(0),
            .BC = Register.init(0),
            .DE = Register.init(0),
            .HL = Register.init(0),
            .SP = Register.init(0),
            .PC = Register.init(0),
            .mem = mem,
            .IME = false,
        };
    }

    pub fn fetch(self: *Cpu) u8 {
        return self.pc_pop_8();
    }

    pub fn decode_execute(self: *Cpu, instruction: u8) void {
        std.debug.print("Executing: {x}\n", .{instruction});
        const cycles: u8 = execute(self, instruction);
        std.debug.print("Cycles: {x}\n", .{cycles});
    }

    pub fn pc_pop_16(self: *Cpu) u16 {
        const b1: u8 = self.mem.read8(self.PC.getHiLo());
        self.PC.inc();
        const b2: u8 = self.mem.read8(self.PC.getHiLo());
        self.PC.inc();
        return @as(u16, b2) << 8 | b1;
    }

    pub fn pc_pop_8(self: *Cpu) u8 {
        const b: u8 = self.mem.read8(self.PC.getHiLo());
        self.PC.inc();
        return b;
    }

    pub fn sp_pop_16(self: *Cpu) u16 {
        const b1: u8 = self.mem.read8(self.SP.getHiLo());
        self.SP.inc();
        const b2: u8 = self.mem.read8(self.SP.getHiLo());
        self.SP.inc();
        return @as(u16, b2) << 8 | b1;
    }

    pub fn sp_push_16(self: *Cpu, val: u16) void {
        self.SP.dec();
        self.mem.write8(self.SP.getHiLo(), @truncate(val >> 8));
        self.SP.dec();
        self.mem.write8(self.SP.getHiLo(), @truncate(val));
    }

    pub fn set_c(self: *Cpu, flag: bool) void {
        const current: u8 = self.AF.getLo();
        if (flag) {
            self.AF.setLo(current | 0x10);
        } else {
            self.AF.setLo(current & ~@as(u8, 0x10));
        }
    }

    pub fn set_h(self: *Cpu, flag: bool) void {
        const current: u8 = self.AF.getLo();
        if (flag) {
            self.AF.setLo(current | 0x20);
        } else {
            self.AF.setLo(current & ~@as(u8, 0x20));
        }
    }

    pub fn set_n(self: *Cpu, flag: bool) void {
        const current: u8 = self.AF.getLo();
        if (flag) {
            self.AF.setLo(current | 0x40);
        } else {
            self.AF.setLo(current & ~@as(u8, 0x40));
        }
    }

    pub fn set_z(self: *Cpu, flag: bool) void {
        const current: u8 = self.AF.getLo();
        if (flag) {
            self.AF.setLo(current | 0x80);
        } else {
            self.AF.setLo(current & ~@as(u8, 0x80));
        }
    }

    pub fn get_c(self: *Cpu) u1 {
        return @truncate((self.AF.getLo() & 0x10) >> 4);
    }

    pub fn get_h(self: *Cpu) u1 {
        return @truncate((self.AF.getLo() & 0x20) >> 5);
    }

    pub fn get_n(self: *Cpu) u1 {
        return @truncate((self.AF.getLo() & 0x40) >> 6);
    }

    pub fn get_z(self: *Cpu) u1 {
        return @truncate((self.AF.getLo() & 0x80) >> 7);
    }
};
