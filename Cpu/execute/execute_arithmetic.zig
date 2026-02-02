const std = @import("std");
const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../register.zig").Register;
const set_HC_flags_r8 = @import("../helpers.zig").set_HC_flags_r8;
const set_HC_flags_r16 = @import("../helpers.zig").set_HC_flags_r16;
const set_NZ_flags = @import("../helpers.zig").set_NZ_flags;

// Add the value in r8 plus the carry flag to A.
pub fn execute_ADC_A_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = if (isHi) r.getHi() else r.getLo();
    const carry: u1 = @truncate(cpu.AF.getLo());

    const result = op1 + op2 + carry;
    cpu.AF.setLo(result);

    set_HC_flags_r8(cpu, op1, op2 + carry);
    set_NZ_flags(cpu, result);
}

// Add the byte pointed to by HL plus the carry flag to A.
pub fn execute_ADC_A_HL(cpu: *Cpu) void {
    const op1: u8 = cpu.mem.read8(cpu.HL.HiLo());
    const op2: u8 = cpu.AF.getHi();
    const carry: u1 = @truncate(cpu.AF.getLo());

    const result = op1 + op2 + carry;
    cpu.AF.setHi(result);

    set_HC_flags_r8(cpu, op1, op2 + carry);
    set_NZ_flags(cpu, result);
}

// Add the value n8 plus the carry flag to A.
pub fn execute_ADC_A_n8(cpu: *Cpu) void {
    const op1: u8 = cpu.pc_pop_8();
    const op2: u8 = cpu.AF.getHi();
    const carry: u1 = @truncate(cpu.AF.getLo());

    const result = op1 + op2 + carry;
    cpu.AF.setHi(result);

    set_HC_flags_r8(cpu, op1, op2 + carry);
    set_NZ_flags(cpu, result);
}

// Add the value in r8 to A.
pub fn execute_ADD_A_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = if (isHi) r.getHi() else r.getLo();

    const result = op1 + op2;
    cpu.AF.setHi(result);

    set_HC_flags_r8(cpu, op1, op2);
    set_NZ_flags(cpu, result);
}

// Add the byte pointed to by HL to A.
pub fn execute_ADD_A_HL(cpu: *Cpu) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = cpu.mem.read8(cpu.HL.getHiLo());

    const result = op1 + op2;
    cpu.AF.setHi(result);

    set_HC_flags_r8(cpu, op1, op2);
    set_NZ_flags(cpu, result);
}

// Add the value n8 to A.
pub fn execute_ADD_A_n8(cpu: *Cpu) void {
    const op1: u8 = cpu.pc_pop_8();
    const op2: u8 = cpu.AF.getHi();

    const result = op1 + op2;
    cpu.AF.setHi(result);

    set_HC_flags_r8(cpu, op1, op2);
    set_NZ_flags(cpu, result);
}

// Add the value in r16 to HL.
pub fn execute_ADD_HL_r16(cpu: *Cpu, r: *Register) void {
    const op1: u16 = cpu.HL.getHiLo();
    const op2: u16 = r.getHiLo();

    const result = op1 + op2;
    cpu.AF.setHi(result);

    set_HC_flags_r16(cpu, op1, op2);
    set_NZ_flags(cpu, result);
}
