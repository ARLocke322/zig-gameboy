const std = @import("std");
const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../register.zig").Register;
const set_HC_flags = @import("../helpers.zig").set_HC_flags;
const set_NZ_flags = @import("../helpers.zig").set_NZ_flags;

pub fn execute_ADC_A_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = if (isHi) r.getHi() else r.getLo();
    const carry: u1 = @truncate(cpu.AF.getLo());

    const result = op1 + op2 + carry;
    cpu.AF.setLo(result);

    set_HC_flags(cpu, op1, op2 + carry);
    set_NZ_flags(cpu, result);
}

pub fn execute_ADC_A_HL(cpu: *Cpu) void {
    const op1: u8 = cpu.mem.read8(cpu.HL.HiLo());
    const op2: u8 = cpu.AF.getHi();
    const carry: u1 = @truncate(cpu.AF.getLo());

    const result = op1 + op2 + carry;
    cpu.AF.setHi(result);

    set_HC_flags(cpu, op1, op2 + carry);
    set_NZ_flags(cpu, result);
}
