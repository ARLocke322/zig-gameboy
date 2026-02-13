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

pub fn get_r8(cpu: *Cpu, index: u3) struct {
    reg: *Register,
    get: *const fn (*Register) u8,
    set: *const fn (*Register, u8) void,
} {
    std.debug.assert(index != 6);
    return switch (index) {
        0 => .{ .reg = &cpu.BC, .get = Register.getHi, .set = Register.setHi },
        1 => .{ .reg = &cpu.BC, .get = Register.getLo, .set = Register.setLo },
        2 => .{ .reg = &cpu.DE, .get = Register.getHi, .set = Register.setHi },
        3 => .{ .reg = &cpu.DE, .get = Register.getLo, .set = Register.setLo },
        4 => .{ .reg = &cpu.HL, .get = Register.getHi, .set = Register.setHi },
        5 => .{ .reg = &cpu.HL, .get = Register.getLo, .set = Register.setLo },
        6 => unreachable,
        7 => .{ .reg = &cpu.AF, .get = Register.getHi, .set = Register.setHi },
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

pub fn get_r16mem(cpu: *Cpu, index: u2) *Register {
    std.debug.assert(index == 0 or index == 1);
    return switch (index) {
        0 => &cpu.BC,
        1 => &cpu.DE,
        2 => unreachable,
        3 => unreachable,
    };
}

pub fn get_r16stk(cpu: *Cpu, index: u2) *Register {
    return switch (index) {
        0 => &cpu.BC,
        1 => &cpu.DE,
        2 => &cpu.HL,
        3 => &cpu.AF,
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
