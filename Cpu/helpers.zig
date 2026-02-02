const std = @import("std");
const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../cpu.zig").Register;

pub fn set_HC_flags(
    cpu: *Cpu,
    op1: u8,
    op2: u8,
) void {
    const h = ((op1 & 0x0F) + (op2 & 0x0F)) > 0x0F;
    const c = ((op1 & 0xFF) + (op2 & 0xFF)) > 0xFF;

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
