const std = @import("std");
const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../cpu.zig").Register;

pub fn set_HC_flags_r8(
    cpu: *Cpu,
    op1: u8,
    op2: u8,
) void {
    const h = ((op1 & 0x0F) + (op2 & 0x0F)) > 0x0F;
    const c = (op1 + op2) > 0xFF;

    cpu.set_c(c);
    cpu.set_h(h);
}

pub fn set_HC_flags_r16(
    cpu: *Cpu,
    op1: u16,
    op2: u16,
) void {
    const h = ((op1 & 0x0FFF) + (op2 & 0x0FFF)) > 0x0FFF;
    const c = (op1 + op2) > 0xFFFF;

    cpu.set_c(c);
    cpu.set_h(h);
}

pub fn set_NZ_flags(
    cpu: *Cpu,
    result: u16,
) void {
    const N: bool = (result >> 15) & 0x1 == 0x1;
    const Z: bool = result == 0x0;

    cpu.set_N(N);
    cpu.set_Z(Z);
}
