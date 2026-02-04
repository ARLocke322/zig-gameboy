const std = @import("std");
const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../cpu.zig").Register;

pub fn set_NHC_flags_r8_ADD(cpu: *Cpu, op1: u8, op2: u8) void {
    const h = ((op1 & 0x0F) + (op2 & 0x0F)) > 0x0F;
    const c = (op1 + op2) > 0xFF;

    cpu.set_c(c);
    cpu.set_h(h);
    cpu.set_n(false);
}

pub fn set_NHC_flags_r8_SUB(cpu: *Cpu, op1: u8, op2: u8) void {
    const h = (op1 & 0x0F) < (op2 & 0x0F);
    const c = op1 < op2;

    cpu.set_c(c);
    cpu.set_h(h);
    cpu.set_n(true);
}

pub fn set_NHC_flags_r8_SHIFT(cpu: *Cpu, new_carry: u1) void {
    cpu.set_n(false);
    cpu.set_h(false);
    cpu.set_c(new_carry == 1);
}

pub fn set_NHC_flags_r16_ADD(cpu: *Cpu, op1: u16, op2: u16) void {
    const h = ((op1 & 0x0FFF) + (op2 & 0x0FFF)) > 0x0FFF;
    const c = (op1 + op2) > 0xFFFF;

    cpu.set_c(c);
    cpu.set_h(h);
    cpu.set_n(true);
}

pub fn set_NHC_flags_r16_SUB(cpu: *Cpu, op1: u16, op2: u16) void {
    const h: u16 = (op1 & 0x0FFF) < (op2 & 0x0FFF);
    const c: u16 = op1 < op2;

    cpu.set_c(c);
    cpu.set_h(h);
    cpu.set_n(true);
}

pub fn set_NHCZ_flags_logic(cpu: *Cpu, result: u8, h: bool) void {
    cpu.set_z(result == 0);
    cpu.set_n(false);
    cpu.set_h(h);
    cpu.set_c(false);
}

pub fn set_Z_flag(
    cpu: *Cpu,
    result: u16,
) void {
    cpu.set_Z(result == 0);
}

pub fn get_r8(cpu: *Cpu, index: u2) struct {
    reg: *Register,
    isHi: bool,
    isHL: bool,
} {
    return switch (index) {
        0 => .{ &cpu.BC, true, false },
        1 => .{ &cpu.BC, false, false },
        2 => .{ &cpu.DE, true, false },
        3 => .{ &cpu.DE, false, false },
        4 => .{ &cpu.HL, true, false },
        5 => .{ &cpu.HL, false, false },
        6 => .{ &cpu.HL, false, true },
        7 => .{ &cpu.AF, true, false },
    };
}

pub fn get_r16(cpu: *Cpu, index: u2) *Register {
    return switch (index) {
        0 => &cpu.BC,
        1 => &cpu.DE,
        2 => &cpu.HL,
        3 => &cpu.SP,
        else => {},
    };
}
pub fn get_r16mem(cpu: *Cpu, index: u2) struct {
    reg: *Register,
    inc: bool,
    dec: bool,
} {
    return switch (index) {
        0 => .{ &cpu.BC, false, false },
        1 => .{ &cpu.DE, false, false },
        2 => .{ &cpu.HL, true, false },
        3 => .{ &cpu.HL, false, true },
    };
}
