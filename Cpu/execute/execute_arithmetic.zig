const std = @import("std");
const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../register.zig").Register;
const set_NHC_flags_r8_ADD = @import("../helpers.zig").set_NHC_flags_r8_ADD;
const set_NHC_flags_r16_ADD = @import("../helpers.zig").set_NHC_flags_r16_ADD;
const set_NHC_flags_r8_SUB = @import("../helpers.zig").set_NHC_flags_r8_SUB;
const set_NHC_flags_r16_SUB = @import("../helpers.zig").set_NHC_flags_r16_SUB;
const set_Z_flag = @import("../helpers.zig").set_Z_flag;

// Add the value in r8 plus the carry flag to A.
pub fn execute_ADC_A_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = if (isHi) r.getHi() else r.getLo();
    const carry: u1 = @truncate(cpu.AF.getLo() >> 4);

    const result = op1 + op2 + carry;
    cpu.AF.setHi(result);

    set_NHC_flags_r8_ADD(cpu, op1, op2 + carry);
    set_Z_flag(cpu, result);
}

// Add the byte pointed to by HL plus the carry flag to A.
pub fn execute_ADC_A_HL(cpu: *Cpu) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = cpu.mem.read8(cpu.HL.getHiLo());
    const carry: u1 = @truncate(cpu.AF.getLo() >> 4);

    const result = op1 + op2 + carry;
    cpu.AF.setHi(result);

    set_NHC_flags_r8_ADD(cpu, op1, op2 + carry);
    set_Z_flag(cpu, result);
}

// Add the value n8 plus the carry flag to A.
pub fn execute_ADC_A_n8(cpu: *Cpu, op2: u8) void {
    const op1: u8 = cpu.AF.getHi();
    const carry: u1 = @truncate(cpu.AF.getLo() >> 4);

    const result = op1 + op2 + carry;
    cpu.AF.setHi(result);

    set_NHC_flags_r8_ADD(cpu, op1, op2 + carry);
    set_Z_flag(cpu, result);
}

// Add the value in r8 to A.
pub fn execute_ADD_A_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = if (isHi) r.getHi() else r.getLo();

    const result = op1 + op2;
    cpu.AF.setHi(result);

    set_NHC_flags_r8_ADD(cpu, op1, op2);
    set_Z_flag(cpu, result);
}

// Add the byte pointed to by HL to A.
pub fn execute_ADD_A_HL(cpu: *Cpu) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = cpu.mem.read8(cpu.HL.getHiLo());

    const result = op1 + op2;
    cpu.AF.setHi(result);

    set_NHC_flags_r8_ADD(cpu, op1, op2);
    set_Z_flag(cpu, result);
}

// Add the value n8 to A.
pub fn execute_ADD_A_n8(cpu: *Cpu, op2: u8) void {
    const op1: u8 = cpu.AF.getHi();

    const result = op1 + op2;
    cpu.AF.setHi(result);

    set_NHC_flags_r8_ADD(cpu, op1, op2);
    set_Z_flag(cpu, result);
}

// Add the value in r16 to HL.
pub fn execute_ADD_HL_r16(cpu: *Cpu, r: *Register) void {
    const op1: u16 = cpu.HL.getHiLo();
    const op2: u16 = r.getHiLo();

    const result = op1 + op2;
    cpu.HL.set(result);

    set_NHC_flags_r16_ADD(cpu, op1, op2);
}

// Add the value in SP to HL.
pub fn execute_ADD_HL_SP(cpu: *Cpu) void {
    const op1: u16 = cpu.HL.getHiLo();
    const op2: u16 = cpu.SP.getHiLo();

    const result = op1 + op2;
    cpu.HL.set(result);

    set_NHC_flags_r16_ADD(cpu, op1, op2);
}

pub fn execute_ADD_SP_e8(cpu: *Cpu, e8: i8) void {
    const sp = cpu.SP.getHiLo();
    const result: u16 = @bitCast(@as(i16, sp) + @as(i16, e8));
    cpu.SP.set(result);
    set_NHC_flags_r8_ADD(cpu, @truncate(sp), @bitCast(e8));
}

// ComPare the value in A with the value in r8.
pub fn execute_CP_A_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = if (isHi) r.getHi() else r.getLo();

    const result = op1 - op2;

    set_NHC_flags_r8_SUB(cpu, op1, op2);
    set_Z_flag(cpu, result);
}

// ComPare the value in A with the byte pointed to by HL.
// This subtracts the byte pointed to by HL from A and sets flags accordingly,
// but discards the result.
pub fn execute_CP_A_HL(cpu: *Cpu) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = cpu.mem.read8(cpu.HL.getHiLo());

    const result = op1 - op2;

    set_NHC_flags_r8_SUB(cpu, op1, op2);
    set_Z_flag(cpu, result);
}

// ComPare the value in A with the value n8.
// This subtracts the value n8 from A and sets flags accordingly, but discards
// the result.
pub fn execute_CP_A_n8(cpu: *Cpu, op2: u8) void {
    const op1: u8 = cpu.AF.getHi();

    const result = op1 - op2;

    set_NHC_flags_r8_SUB(cpu, op1, op2);
    set_Z_flag(cpu, result);
}

// Decrement the value in register r8 by 1.
pub fn execute_DEC_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const current: u8 = if (isHi) r.getHi() else r.getLo();

    const result: u8 = current - 0x1;
    if (isHi) r.setHi(result) else r.setLo(result);

    set_NHC_flags_r8_SUB(cpu, current, 0x1);
    set_Z_flag(cpu, result);
}

// Decrement the byte pointed to by HL by 1.
pub fn execute_DEC_HL(cpu: *Cpu) void {
    const addr: u16 = cpu.HL.getHiLo();
    const current: u8 = cpu.mem.read8(addr);

    const result: u8 = current - 0x1;
    cpu.mem.write8(addr, result);

    set_NHC_flags_r8_SUB(cpu, current, 0x1);
    set_Z_flag(cpu, result);
}

// Decrement the value in register r16 by 1.
pub fn execute_DEC_r16(r: *Register) void {
    const current: u16 = r.getHiLo();

    const result: u16 = current - 0x1;
    r.set(result);
}

// Increment the value in register r8 by 1.
pub fn execute_INC_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const current: u8 = if (isHi) r.getHi() else r.getLo();

    const result: u8 = current + 0x1;
    if (isHi) r.setHi(result) else r.setLo(result);

    set_NHC_flags_r8_ADD(cpu, current, 0x1);
    set_Z_flag(cpu, result);
}

// Increment the byte pointed to by HL by 1.
pub fn execute_INC_HL(cpu: *Cpu) void {
    const addr: u16 = cpu.HL.getHiLo();
    const current: u8 = cpu.mem.read8(addr);

    const result: u8 = current + 0x1;
    cpu.mem.write8(addr, result);

    set_NHC_flags_r8_ADD(cpu, current, 0x1);
    set_Z_flag(cpu, result);
}

// Increment the value in register r16 by 1.
pub fn execute_INC_r16(r: *Register) void {
    const current: u16 = r.getHiLo();

    const result: u16 = current + 0x1;
    r.set(result);
}

// Subtract the value in r8 and the carry flag from A.
pub fn execute_SBC_A_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = if (isHi) r.getHi() else r.getLo();
    const carry: u1 = @truncate(cpu.AF.getLo() >> 4);

    const result = op1 - (op2 + carry);
    cpu.AF.setHi(result);

    set_NHC_flags_r8_SUB(cpu, op1, op2 + carry);
    set_Z_flag(cpu, result);
}

// Subtract the byte pointed to by HL and the carry flag from A.
pub fn execute_SBC_A_HL(cpu: *Cpu) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = cpu.mem.read8(cpu.HL.getHiLo());
    const carry: u1 = @truncate(cpu.AF.getLo() >> 4);

    const result = op1 - (op2 + carry);
    cpu.AF.setHi(result);

    set_NHC_flags_r8_SUB(cpu, op1, op2 + carry);
    set_Z_flag(cpu, result);
}

// Subtract the value n8 and the carry flag from A.
pub fn execute_SBC_A_n8(cpu: *Cpu, op2: u8) void {
    const op1: u8 = cpu.AF.getHi();
    const carry: u1 = @truncate(cpu.AF.getLo() >> 4);

    const result = op1 - (op2 + carry);
    cpu.AF.setHi(result);

    set_NHC_flags_r8_SUB(cpu, op1, op2 + carry);
    set_Z_flag(cpu, result);
}

// Subtract the value in r8 from A.
pub fn execute_SUB_A_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = if (isHi) r.getHi() else r.getLo();

    const result = op1 - op2;
    cpu.AF.setHi(result);

    set_NHC_flags_r8_SUB(cpu, op1, op2);
    set_Z_flag(cpu, result);
}

// Subtract the byte pointed to by HL from A.
pub fn execute_SUB_A_HL(cpu: *Cpu) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = cpu.mem.read8(cpu.HL.getHiLo());

    const result = op1 - op2;
    cpu.AF.setHi(result);

    set_NHC_flags_r8_SUB(cpu, op1, op2);
    set_Z_flag(cpu, result);
}

// Subtract the value n8 from A.
pub fn execute_SUB_A_n8(cpu: *Cpu, op2: u8) void {
    const op1: u8 = cpu.AF.getHi();

    const result = op1 - op2;
    cpu.AF.setHi(result);

    set_NHC_flags_r8_SUB(cpu, op1, op2);
    set_Z_flag(cpu, result);
}
