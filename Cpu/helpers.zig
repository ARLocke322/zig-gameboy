const std = @import("std");
const Cpu = @import("cpu.zig").Cpu;
const Register = @import("register.zig").Register;

pub fn halfCarryAdd(a: u4, b: u4, c: u1) bool {
    const hc1 = @addWithOverflow(a, b);
    const hc2 = @addWithOverflow(hc1[0], c);
    return hc1[1] == 1 or hc2[1] == 1;
}

pub fn halfCarrySub(a: u4, b: u4, c: u1) bool {
    const hc1 = @subWithOverflow(a, b);
    const hc2 = @subWithOverflow(hc1[0], c);
    return hc1[1] == 1 or hc2[1] == 1;
}

pub fn set_NHC_flags_r8_ADD(
    cpu: *Cpu,
    op1: u8,
    op2: u8,
    carry: u1,
    carrySet: bool,
) void {
    cpu.set_n(false);
    cpu.set_h(halfCarryAdd(@truncate(op1), @truncate(op2), carry));
    cpu.set_c(carrySet);
}

pub fn set_NHC_flags_r16_ADD(
    cpu: *Cpu,
    op1: u16,
    op2: u16,
    carrySet: bool,
) void {
    cpu.set_n(false);
    cpu.set_h(halfCarryAdd(@truncate(op1 >> 8), @truncate(op2 >> 8), 0));
    cpu.set_c(carrySet);
}

pub fn set_NHC_flags_r8_SUB(
    cpu: *Cpu,
    op1: u8,
    op2: u8,
    carry: u1,
    carrySet: bool,
) void {
    cpu.set_n(true);
    cpu.set_h(halfCarrySub(@truncate(op1), @truncate(op2), carry));
    cpu.set_c(carrySet);
}

pub fn set_NHC_flags_r8_SHIFT(cpu: *Cpu, new_carry: u1) void {
    cpu.set_n(false);
    cpu.set_h(false);
    cpu.set_c(new_carry == 1);
}

pub fn set_NHC_flags_r16_SUB(cpu: *Cpu, op1: u16, op2: u16) void {
    const h: bool = (op1 & 0x0FFF) < (op2 & 0x0FFF);
    const c: bool = op1 < op2;

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
    cpu.set_z(result == 0);
}

pub fn get_r8(cpu: *Cpu, index: u3) struct {
    reg: *Register,
    isHi: bool,
    isHL: bool,
} {
    return switch (index) {
        0 => .{ .reg = &cpu.BC, .isHi = true, .isHL = false },
        1 => .{ .reg = &cpu.BC, .isHi = false, .isHL = false },
        2 => .{ .reg = &cpu.DE, .isHi = true, .isHL = false },
        3 => .{ .reg = &cpu.DE, .isHi = false, .isHL = false },
        4 => .{ .reg = &cpu.HL, .isHi = true, .isHL = false },
        5 => .{ .reg = &cpu.HL, .isHi = false, .isHL = false },
        6 => .{ .reg = &cpu.HL, .isHi = false, .isHL = true },
        7 => .{ .reg = &cpu.AF, .isHi = true, .isHL = false },
    };
}

pub fn get_r16(cpu: *Cpu, index: u2) *Register {
    return switch (index) {
        0 => &cpu.BC,
        1 => &cpu.DE,
        2 => &cpu.HL,
        3 => &cpu.SP,
    };
}
pub fn get_r16mem(cpu: *Cpu, index: u2) struct {
    reg: *Register,
    inc: bool,
    dec: bool,
} {
    return switch (index) {
        0 => .{ .reg = &cpu.BC, .inc = false, .dec = false },
        1 => .{ .reg = &cpu.DE, .inc = false, .dec = false },
        2 => .{ .reg = &cpu.HL, .inc = true, .dec = false },
        3 => .{ .reg = &cpu.HL, .inc = false, .dec = true },
    };
}

pub fn check_condition(cpu: *Cpu, cond: u2) bool {
    switch (cond) {
        0x0 => return cpu.get_z() == 0,
        0x1 => return cpu.get_z() == 1,
        0x2 => return cpu.get_c() == 0,
        0x3 => return cpu.get_c() == 1,
    }
}
