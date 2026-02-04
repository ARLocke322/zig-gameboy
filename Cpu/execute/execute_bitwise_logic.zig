const std = @import("std");
const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../register.zig").Register;
const set_NHCZ_flags_logic = @import("../helpers.zig").set_NHCZ_flags_logic;

pub fn execute_AND_A_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const op1: u8 = if (isHi) r.getHi() else r.getLo();
    const op2: u8 = cpu.AF.getHi();

    const result = op1 & op2;

    cpu.AF.setHi(result);
    set_NHCZ_flags_logic(cpu, result, true);
}

pub fn execute_AND_A_HL(cpu: *Cpu) void {
    const addr: u16 = cpu.HL.getHiLo();
    const op1: u8 = cpu.mem.read8(addr);
    const op2: u8 = cpu.AF.getHi();

    const result = op1 & op2;

    cpu.AF.setHi(result);
    set_NHCZ_flags_logic(cpu, result, true);
}

pub fn execute_AND_A_n8(cpu: *Cpu, op1: u8) void {
    const op2: u8 = cpu.AF.getHi();

    const result = op1 & op2;

    cpu.AF.setHi(result);
    set_NHCZ_flags_logic(cpu, result, true);
}

pub fn execute_CPL(cpu: *Cpu) void {
    cpu.AF.setHi(~cpu.AF.getHi());
    cpu.set_n(true);
    cpu.set_h(true);
}

pub fn execute_OR_A_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const op1: u8 = if (isHi) r.getHi() else r.getLo();
    const op2: u8 = cpu.AF.getHi();

    const result = op1 | op2;

    cpu.AF.setHi(result);
    set_NHCZ_flags_logic(cpu, result, false);
}

pub fn execute_OR_A_HL(cpu: *Cpu) void {
    const addr: u16 = cpu.HL.getHiLo();
    const op1: u8 = cpu.mem.read8(addr);
    const op2: u8 = cpu.AF.getHi();

    const result = op1 | op2;

    cpu.AF.setHi(result);
    set_NHCZ_flags_logic(cpu, result, false);
}

pub fn execute_OR_A_n8(cpu: *Cpu, op1: u8) void {
    const op2: u8 = cpu.AF.getHi();

    const result = op1 | op2;

    cpu.AF.setHi(result);
    set_NHCZ_flags_logic(cpu, result, false);
}

pub fn execute_XOR_A_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const op1: u8 = if (isHi) r.getHi() else r.getLo();
    const op2: u8 = cpu.AF.getHi();

    const result = op1 ^ op2;

    cpu.AF.setHi(result);
    set_NHCZ_flags_logic(cpu, result, false);
}

pub fn execute_XOR_A_HL(cpu: *Cpu) void {
    const addr: u16 = cpu.HL.getHiLo();
    const op1: u8 = cpu.mem.read8(addr);
    const op2: u8 = cpu.AF.getHi();

    const result = op1 ^ op2;

    cpu.AF.setHi(result);
    set_NHCZ_flags_logic(cpu, result, false);
}

pub fn execute_XOR_A_n8(cpu: *Cpu, op1: u8) void {
    const op2: u8 = cpu.AF.getHi();

    const result = op1 ^ op2;

    cpu.AF.setHi(result);
    set_NHCZ_flags_logic(cpu, result, false);
}
