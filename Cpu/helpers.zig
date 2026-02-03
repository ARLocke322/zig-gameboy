const std = @import("std");
const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../cpu.zig").Register;

pub fn set_NHC_flags_r8_ADD(
    cpu: *Cpu,
    op1: u8,
    op2: u8,
) void {
    const h = ((op1 & 0x0F) + (op2 & 0x0F)) > 0x0F;
    const c = (op1 + op2) > 0xFF;

    cpu.set_c(c);
    cpu.set_h(h);
    cpu.set_n(false);
}

pub fn set_NHC_flags_r8_SUB(
    cpu: *Cpu,
    op1: u8,
    op2: u8,
) void {
    const h = (op1 & 0x0F) < (op2 & 0x0F);
    const c = op1 < op2;

    cpu.set_c(c);
    cpu.set_h(h);
    cpu.set_n(true);
}

pub fn set_NHC_flags_r16_ADD(
    cpu: *Cpu,
    op1: u16,
    op2: u16,
) void {
    const h = ((op1 & 0x0FFF) + (op2 & 0x0FFF)) > 0x0FFF;
    const c = (op1 + op2) > 0xFFFF;

    cpu.set_c(c);
    cpu.set_h(h);
    cpu.set_n(true);
}

pub fn set_NHC_flags_r16_SUB(
    cpu: *Cpu,
    op1: u16,
    op2: u16,
) void {
    const h: u16 = (op1 & 0x0FFF) < (op2 & 0x0FFF);
    const c: u16 = op1 < op2;

    cpu.set_c(c);
    cpu.set_h(h);
    cpu.set_n(true);
}

pub fn set_Z_flag(
    cpu: *Cpu,
    result: u16,
) void {
    cpu.set_Z(result == 0);
}
