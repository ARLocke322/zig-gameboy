const std = @import("std");
const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../register.zig").Register;
const set_NHC_flags_r8_SHIFT = @import("../helpers.zig").set_NHC_flags_r8_SHIFT;
const set_NHC_flags_r16_ADD = @import("../helpers.zig").set_NHC_flags_r16_ADD;
const set_NHC_flags_r16_SUB = @import("../helpers.zig").set_NHC_flags_r16_SUB;
const set_Z_flag = @import("../helpers.zig").set_Z_flag;

// Rotate bits in register r8 left, through the carry flag.
pub fn execute_RL_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const current: u8 = if (isHi) r.getHi() else r.getLo();
    const carry: u1 = cpu.get_c();
    const new_carry: u1 = @truncate(current >> 7);

    const result: u8 = (current << 1) | carry;

    if (isHi) r.setHi(result) else r.setLo(result);

    cpu.set_z(result == 0);
    set_NHC_flags_r8_SHIFT(cpu, new_carry);
}

// Rotate the byte pointed to by HL left, through the carry flag.
pub fn execute_RL_HL(cpu: *Cpu) void {
    const addr = cpu.HL.getHiLo();
    const current: u8 = cpu.mem.read8(addr);
    const carry: u1 = cpu.get_c();
    const new_carry: u1 = @truncate(current >> 7);

    const result: u8 = (current << 1) | carry;

    cpu.mem.write8(addr, result);

    cpu.set_z(result == 0);
    set_NHC_flags_r8_SHIFT(cpu, new_carry);
}

// Rotate register A left, through the carry flag.
pub fn execute_RLA(cpu: *Cpu) void {
    const current: u8 = cpu.AF.getHi();
    const carry: u1 = cpu.get_c();
    const new_carry: u1 = @truncate(current >> 7);

    const result: u8 = (current << 1) | carry;

    cpu.AF.setHi(result);

    cpu.set_z(false);
    set_NHC_flags_r8_SHIFT(cpu, new_carry);
}

// Rotate register r8 left.
pub fn execute_RLC_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const current: u8 = if (isHi) r.getHi() else r.getLo();
    const new_carry: u1 = @truncate(current >> 7);

    const result: u8 = (current << 1) | new_carry;

    if (isHi) r.setHi(result) else r.setLo(result);

    cpu.set_z(result == 0);
    set_NHC_flags_r8_SHIFT(cpu, new_carry);
}

// Rotate the byte pointed to by HL left.
pub fn execute_RLC_HL(cpu: *Cpu) void {
    const addr = cpu.HL.getHiLo();
    const current: u8 = cpu.mem.read8(addr);
    const new_carry: u1 = @truncate(current >> 7);

    const result: u8 = (current << 1) | new_carry;

    cpu.mem.write8(addr, result);

    cpu.set_z(result == 0);
    set_NHC_flags_r8_SHIFT(cpu, new_carry);
}

// Rotate register A left.
pub fn execute_RLCA(cpu: *Cpu) void {
    const current: u8 = cpu.AF.getHi();
    const new_carry: u1 = @truncate(current >> 7);

    const result: u8 = (current << 1) | new_carry;

    cpu.AF.setHi(result);

    cpu.set_z(false);
    set_NHC_flags_r8_SHIFT(cpu, new_carry);
}

// Rotate register r8 right, through the carry flag.
pub fn execute_RR_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const current: u8 = if (isHi) r.getHi() else r.getLo();
    const carry: u1 = cpu.get_c();
    const new_carry: u1 = @truncate(current);

    const result: u8 = (carry << 7) | (current >> 1);

    if (isHi) r.setHi(result) else r.setLo(result);

    cpu.set_z(result == 0);
    set_NHC_flags_r8_SHIFT(cpu, new_carry);
}

// Rotate the byte pointed to by HL right, through the carry flag.
pub fn execute_RR_HL(cpu: *Cpu) void {
    const addr = cpu.HL.getHiLo();
    const current: u8 = cpu.mem.read8(addr);
    const carry: u1 = cpu.get_c();
    const new_carry: u1 = @truncate(current);

    const result: u8 = (carry << 7) | (current >> 1);

    cpu.mem.write8(addr, result);

    cpu.set_z(result == 0);
    set_NHC_flags_r8_SHIFT(cpu, new_carry);
}

// Rotate register A right, through the carry flag.
pub fn execute_RRA(cpu: *Cpu) void {
    const current: u8 = cpu.AF.getHi();
    const carry: u1 = cpu.get_c();
    const new_carry: u1 = @truncate(current);

    const result: u8 = (carry << 7) | (current >> 1);

    cpu.AF.setHi(result);

    cpu.set_z(false);
    set_NHC_flags_r8_SHIFT(cpu, new_carry);
}

// Rotate register r8 right.
pub fn execute_RRC_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const current: u8 = if (isHi) r.getHi() else r.getLo();
    const new_carry: u1 = @truncate(current);

    const result: u8 = (new_carry << 7) | (current >> 1);

    if (isHi) r.setHi(result) else r.setLo(result);

    cpu.set_z(result == 0);
    set_NHC_flags_r8_SHIFT(cpu, new_carry);
}

// Rotate the byte pointed to by HL right.
pub fn execute_RRC_HL(
    cpu: *Cpu,
) void {
    const addr = cpu.HL.getHiLo();
    const current: u8 = cpu.mem.read8(addr);
    const new_carry: u1 = @truncate(current);

    const result: u8 = (new_carry << 7) | (current >> 1);

    cpu.mem.write8(addr, result);

    cpu.set_z(result == 0);
    set_NHC_flags_r8_SHIFT(cpu, new_carry);
}

// Rotate register A right.
pub fn execute_RRCA(cpu: *Cpu) void {
    const current: u8 = cpu.AF.getHi();
    const new_carry: u1 = @truncate(current);

    const result: u8 = (new_carry << 7) | (current >> 1);

    cpu.AF.setHi(result);

    cpu.set_z(false);
    set_NHC_flags_r8_SHIFT(cpu, new_carry);
}

// Shift Left Arithmetically register r8.
pub fn execute_SLA_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const current: u8 = if (isHi) r.getHi() else r.getLo();
    const new_carry: u1 = @truncate(current >> 7);
    const result = current << 1;
    if (isHi) r.setHi(result) else r.setLo(result);

    cpu.set_z(result == 0);
    set_NHC_flags_r8_SHIFT(cpu, new_carry);
}

// Shift Left Arithmetically the byte pointed to by HL.
pub fn execute_SLA_HL(cpu: *Cpu) void {
    const addr = cpu.HL.getHiLo();
    const current: u8 = cpu.mem.read8(addr);
    const new_carry: u1 = @truncate(current >> 7);

    const result = current << 1;
    cpu.mem.write8(addr, result);

    cpu.set_z(result == 0);
    set_NHC_flags_r8_SHIFT(cpu, new_carry);
}

// Shift Right Arithmetically register r8 (bit 7 of r8 is unchanged).
pub fn execute_SRA_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const current: u8 = if (isHi) r.getHi() else r.getLo();
    const new_carry: u1 = @truncate(current);

    const msb = current & 0x80;
    const result = (current >> 1) | msb;

    if (isHi) r.setHi(result) else r.setLo(result);

    cpu.set_z(result == 0);
    set_NHC_flags_r8_SHIFT(cpu, new_carry);
}

// Shift Right Arithmetically the byte pointed to by HL (bit 7 of the byte
// pointed to by HL is unchanged).
pub fn execute_SRA_HL(cpu: *Cpu) void {
    const addr = cpu.HL.getHiLo();
    const current: u8 = cpu.mem.read8(addr);
    const new_carry: u1 = @truncate(current);

    const msb = current & 0x80;
    const result = (current >> 1) | msb;

    cpu.mem.write8(addr, result);

    cpu.set_z(result == 0);
    set_NHC_flags_r8_SHIFT(cpu, new_carry);
}

// Shift Right Logically register r8.
pub fn execute_SRL_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const current: u8 = if (isHi) r.getHi() else r.getLo();
    const new_carry: u1 = @truncate(current);
    const result = current >> 1;
    if (isHi) r.setHi(result) else r.setLo(result);

    cpu.set_z(result == 0);
    set_NHC_flags_r8_SHIFT(cpu, new_carry);
}

// Shift Right Logically the byte pointed to by HL.
pub fn execute_SRL_HL(cpu: *Cpu) void {
    const addr = cpu.HL.getHiLo();
    const current: u8 = cpu.mem.read8(addr);
    const new_carry: u1 = @truncate(current);

    const result = current >> 1;
    cpu.mem.write8(addr, result);

    cpu.set_z(result == 0);
    set_NHC_flags_r8_SHIFT(cpu, new_carry);
}

// Swap the upper 4 bits in register r8 and the lower 4 ones.
pub fn execute_SWAP_r8(cpu: *Cpu, r: *Register, isHi: bool) void {
    const current: u8 = if (isHi) r.getHi() else r.getLo();

    const result: u8 = (current << 4) | (current >> 4);

    if (isHi) r.setHi(result) else r.setLo(result);

    cpu.set_z(result == 0);
    set_NHC_flags_r8_SHIFT(cpu, 0);
}

// Swap the upper 4 bits in the byte pointed by HL and the lower 4 ones.
pub fn execute_SWAP_HL(cpu: *Cpu) void {
    const addr = cpu.HL.getHiLo();
    const current: u8 = cpu.mem.read8(addr);

    const result: u8 = (current << 4) | (current >> 4);

    cpu.mem.write8(addr, result);

    cpu.set_z(result == 0);
    set_NHC_flags_r8_SHIFT(cpu, 0);
}
