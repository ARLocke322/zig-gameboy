const std = @import("std");
const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../register.zig").Register;
const set_NHC_flags_r8_ADD = @import("../helpers.zig").set_NHC_flags_r8_ADD;
const set_NHC_flags_r16_ADD = @import("../helpers.zig").set_NHC_flags_r16_ADD;
const set_NHC_flags_r8_SUB = @import("../helpers.zig").set_NHC_flags_r8_SUB;
const set_NHC_flags_r16_SUB = @import("../helpers.zig").set_NHC_flags_r16_SUB;
const halfCarryAdd = @import("../helpers.zig").halfCarryAdd;
const halfCarrySub = @import("../helpers.zig").halfCarrySub;
const set_Z_flag = @import("../helpers.zig").set_Z_flag;

// Add the value in r8 plus the carry flag to A.
pub fn execute_ADC_A_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = if (isHi) r.getHi() else r.getLo();
    const carry: u1 = cpu.get_c();

    const r1 = @addWithOverflow(op1, op2);
    const r2 = @addWithOverflow(r1[0], carry);
    cpu.AF.setHi(r2[0]);

    set_NHC_flags_r8_ADD(cpu, op1, op2, carry, r1[1] == 1 or r2[1] == 1);
    cpu.set_z(r2[0] == 0);
}

// Add the byte pointed to by HL plus the carry flag to A.
pub fn execute_ADC_A_HL(cpu: *Cpu) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = cpu.mem.read8(cpu.HL.getHiLo());
    const carry: u1 = cpu.get_c();

    const r1 = @addWithOverflow(op1, op2);
    const r2 = @addWithOverflow(r1[0], carry);
    cpu.AF.setHi(r2[0]);

    set_NHC_flags_r8_ADD(cpu, op1, op2, carry, r1[1] == 1 or r2[1] == 1);
    cpu.set_z(r2[0] == 0);
}

// Add the value n8 plus the carry flag to A.
pub fn execute_ADC_A_n8(cpu: *Cpu, op2: u8) void {
    const op1: u8 = cpu.AF.getHi();
    const carry: u1 = cpu.get_c();

    const r1 = @addWithOverflow(op1, op2);
    const r2 = @addWithOverflow(r1[0], carry);
    cpu.AF.setHi(r2[0]);

    set_NHC_flags_r8_ADD(cpu, op1, op2, carry, r1[1] == 1 or r2[1] == 1);
    cpu.set_z(r2[0] == 0);
}

// Add the value in r8 to A.
pub fn execute_ADD_A_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = if (isHi) r.getHi() else r.getLo();

    const result = @addWithOverflow(op1, op2);
    cpu.AF.setHi(result[0]);

    set_NHC_flags_r8_ADD(cpu, op1, op2, 0, result[1] == 1);
    cpu.set_z(result[0] == 0);
}

// Add the byte pointed to by HL to A.
pub fn execute_ADD_A_HL(cpu: *Cpu) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = cpu.mem.read8(cpu.HL.getHiLo());

    const result = @addWithOverflow(op1, op2);
    cpu.AF.setHi(result[0]);

    set_NHC_flags_r8_ADD(cpu, op1, op2, 0, result[1] == 1);
    cpu.set_z(result[0] == 0);
}

// Add the value n8 to A.
pub fn execute_ADD_A_n8(cpu: *Cpu, op2: u8) void {
    const op1: u8 = cpu.AF.getHi();

    const result = @addWithOverflow(op1, op2);
    cpu.AF.setHi(result[0]);

    set_NHC_flags_r8_ADD(cpu, op1, op2, 0, result[1] == 1);
    cpu.set_z(result[0] == 0);
}

// Add the value in r16 to HL.
pub fn execute_ADD_HL_r16(cpu: *Cpu, r: *Register) void {
    const op1: u16 = cpu.HL.getHiLo();
    const op2: u16 = r.getHiLo();

    const result = @addWithOverflow(op1, op2);
    cpu.HL.set(result[0]);

    set_NHC_flags_r16_ADD(cpu, op1, op2, result[1] == 1);
}

// ComPare the value in A with the value in r8.
pub fn execute_CP_A_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = if (isHi) r.getHi() else r.getLo();

    const result = @subWithOverflow(op1, op2);

    set_NHC_flags_r8_SUB(cpu, op1, op2, 0, result[1] == 1);
    cpu.set_z(result[0] == 0);
}

// ComPare the value in A with the byte pointed to by HL.
// This subtracts the byte pointed to by HL from A and sets flags accordingly,
// but discards the result.
pub fn execute_CP_A_HL(cpu: *Cpu) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = cpu.mem.read8(cpu.HL.getHiLo());

    const result = @subWithOverflow(op1, op2);

    set_NHC_flags_r8_SUB(cpu, op1, op2, 0, result[1] == 1);
    cpu.set_z(result[0] == 0);
}

// ComPare the value in A with the value n8.
// This subtracts the value n8 from A and sets flags accordingly, but discards
// the result.
pub fn execute_CP_A_n8(cpu: *Cpu, op2: u8) void {
    const op1: u8 = cpu.AF.getHi();

    const result = @subWithOverflow(op1, op2);

    set_NHC_flags_r8_SUB(cpu, op1, op2, 0, result[1] == 1);
    cpu.set_z(result[0] == 0);
}

// Decrement the value in register r8 by 1.
pub fn execute_DEC_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const current: u8 = if (isHi) r.getHi() else r.getLo();

    const result = @subWithOverflow(current, 0x1);
    if (isHi) r.setHi(result[0]) else r.setLo(result[0]);

    cpu.set_h(halfCarrySub(@truncate(current), 0x1, 0));
    cpu.set_n(true);
    cpu.set_z(result[0] == 0);
}

// Decrement the byte pointed to by HL by 1.
pub fn execute_DEC_HL(cpu: *Cpu) void {
    const addr: u16 = cpu.HL.getHiLo();
    const current: u8 = cpu.mem.read8(addr);

    const result = @subWithOverflow(current, 0x1);
    cpu.mem.write8(addr, result[0]);

    cpu.set_h(halfCarrySub(@truncate(current), 0x1, 0));
    cpu.set_n(true);
    cpu.set_z(result[0] == 0);
}

// Decrement the value in register r16 by 1.
pub fn execute_DEC_r16(r: *Register) void {
    const current: u16 = r.getHiLo();

    const result = @subWithOverflow(current, 0x1);

    r.set(result[0]);
}

// Increment the value in register r8 by 1.
pub fn execute_INC_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const current: u8 = if (isHi) r.getHi() else r.getLo();

    const result = @addWithOverflow(current, 0x1);
    if (isHi) r.setHi(result[0]) else r.setLo(result[0]);

    cpu.set_h(halfCarryAdd(@truncate(current), 0x1, 0));
    cpu.set_n(false);
    cpu.set_z(result[0] == 0);
}

// Increment the byte pointed to by HL by 1.
pub fn execute_INC_HL(cpu: *Cpu) void {
    const addr: u16 = cpu.HL.getHiLo();
    const current: u8 = cpu.mem.read8(addr);

    const result = @addWithOverflow(current, 0x1);
    cpu.mem.write8(addr, result[0]);

    cpu.set_h(halfCarryAdd(@truncate(current), 0x1, 0));
    cpu.set_n(false);
    cpu.set_z(result[0] == 0);
}

// Increment the value in register r16 by 1.
pub fn execute_INC_r16(r: *Register) void {
    const current: u16 = r.getHiLo();

    const result = @addWithOverflow(current, 0x1);
    r.set(result[0]);
}

// Subtract the value in r8 and the carry flag from A.
pub fn execute_SBC_A_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = if (isHi) r.getHi() else r.getLo();
    const carry: u1 = cpu.get_c();

    const r1 = @subWithOverflow(op1, op2);
    const r2 = @subWithOverflow(r1[0], carry);
    cpu.AF.setHi(r2[0]);

    set_NHC_flags_r8_SUB(cpu, op1, op2, carry, r1[1] == 1 or r2[1] == 1);
    cpu.set_z(r2[0] == 0);
}

// Subtract the byte pointed to by HL and the carry flag from A.
pub fn execute_SBC_A_HL(cpu: *Cpu) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = cpu.mem.read8(cpu.HL.getHiLo());
    const carry: u1 = cpu.get_c();

    const r1 = @subWithOverflow(op1, op2);
    const r2 = @subWithOverflow(r1[0], carry);
    cpu.AF.setHi(r2[0]);

    set_NHC_flags_r8_SUB(cpu, op1, op2, carry, r1[1] == 1 or r2[1] == 1);
    cpu.set_z(r2[0] == 0);
}

// Subtract the value n8 and the carry flag from A.
pub fn execute_SBC_A_n8(cpu: *Cpu, op2: u8) void {
    const op1: u8 = cpu.AF.getHi();
    const carry: u1 = cpu.get_c();

    const r1 = @subWithOverflow(op1, op2);
    const r2 = @subWithOverflow(r1[0], carry);
    cpu.AF.setHi(r2[0]);

    set_NHC_flags_r8_SUB(cpu, op1, op2, carry, r1[1] == 1 or r2[1] == 1);
    cpu.set_z(r2[0] == 0);
}

// Subtract the value in r8 from A.
pub fn execute_SUB_A_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = if (isHi) r.getHi() else r.getLo();

    const result = @subWithOverflow(op1, op2);
    cpu.AF.setHi(result[0]);

    set_NHC_flags_r8_SUB(cpu, op1, op2, 0, result[1] == 1);
    cpu.set_z(result[0] == 0);
}

// Subtract the byte pointed to by HL from A.
pub fn execute_SUB_A_HL(cpu: *Cpu) void {
    const op1: u8 = cpu.AF.getHi();
    const op2: u8 = cpu.mem.read8(cpu.HL.getHiLo());

    const result = @subWithOverflow(op1, op2);
    cpu.AF.setHi(result[0]);

    set_NHC_flags_r8_SUB(cpu, op1, op2, 0, result[1] == 1);
    cpu.set_z(result[0] == 0);
}

// Subtract the value n8 from A.
pub fn execute_SUB_A_n8(cpu: *Cpu, op2: u8) void {
    const op1: u8 = cpu.AF.getHi();

    const result = @subWithOverflow(op1, op2);
    cpu.AF.setHi(result[0]);

    set_NHC_flags_r8_SUB(cpu, op1, op2, 0, result[1] == 1);
    cpu.set_z(result[0] == 0);
}
