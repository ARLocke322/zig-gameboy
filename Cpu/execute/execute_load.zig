const std = @import("std");
const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../register.zig").Register;
const set_NHC_FLAGS_r8_ADD = @import("../helpers.zig").set_NHC_flags_r8_ADD;

// Copy (aka Load) the value in register on the right into the register on the
// left.
pub fn execute_LD_r8_r8(
    r1: *Register,
    r2: *Register,
    r1Hi: bool,
    r2Hi: bool,
) void {
    const val: u8 = if (r2Hi) r2.getHi() else r2.getLo();
    if (r1Hi) r1.setHi(val) else r1.setLo(val);
}

// Copy the value n8 into register r8.
pub fn execute_LD_r8_n8(r: *Register, val: u8) void {
    r.set(val);
}

// Copy the value n16 into register r16.
pub fn execute_LD_r16_n16(r: *Register, val: u16) void {
    r.set(val);
}

// Copy the value in register r8 into the byte pointed to by HL.
pub fn execute_LD_HL_r8(cpu: *Cpu, r: Register, isHi: bool) void {
    const val: u8 = if (isHi) r.getHi() else r.getLo();
    cpu.mem.write8(cpu.HL.HiLo(), val);
}

// Copy the value n8 into the byte pointed to by HL.
pub fn execute_LD_HL_n8(cpu: *Cpu, val: u8) void {
    cpu.mem.write8(cpu.HL.HiLo(), val);
}

// Copy the value pointed to by HL into register r8.
pub fn execute_LD_r8_HL(cpu: *Cpu, r: *Register, isHi: bool) void {
    const val: u8 = cpu.mem.read8(cpu.HL.getHiLo());
    if (isHi) r.setHi(val) else r.setLo(val);
}

// Copy the value in register A into the byte pointed to by r16.
pub fn execute_LD_r16_A(cpu: *Cpu, r: Register) void {
    const val: u8 = cpu.AF.getHi();
    cpu.mem.write8(r.HiLo(), val);
}

// Copy the value in register A into the byte at address n16.
pub fn execute_LD_n16_A(cpu: *Cpu, addr: u16) void {
    const val: u8 = cpu.AF.getHi();
    cpu.mem.write8(addr, val);
}

// Copy the value in register A into the byte at address n16.
// The destination address n16 is encoded as its 8-bit low byte and assumes a
// high byte of $FF, so it must be between $FF00 and $FFFF.
pub fn execute_LDH_n16_A(cpu: *Cpu, addrLo: u8) void {
    const val: u8 = cpu.AF.getHi();
    const addr: u16 = 0xFF00 | addrLo;
    cpu.mem.write8(addr, val);
}

// Copy the value in register A into the byte at address $FF00+C.
pub fn execute_LDH_C_A(cpu: *Cpu, c: u8) void {
    const val: u8 = cpu.AF.getHi();
    const addr: u16 = 0xFF00 | c;
    cpu.mem.write8(addr, val);
}

// Copy the byte pointed to by r16 into register A.
pub fn execute_LD_A_r16(cpu: *Cpu, r: Register) void {
    const val: u8 = cpu.mem.read8(r.HiLo());
    cpu.AF.setHi(val);
}

// Copy the byte at address n16 into register A.
pub fn execute_LD_A_n16(cpu: *Cpu, addr: u16) void {
    const val: u8 = cpu.mem.read8(addr);
    cpu.AF.setHi(val);
}

// Copy the byte at address n16 into register A.
// The source address n16 is encoded as its 8-bit low byte and assumes a high
// byte of $FF, so it must be between $FF00 and $FFFF.
pub fn execute_LDH_A_n16(cpu: *Cpu, addrLo: u8) void {
    const addr: u16 = 0xFF00 | addrLo;
    const val: u8 = cpu.mem.read8(addr);
    cpu.AF.setHi(val);
}

// Copy the byte at address $FF00+C into register A.
pub fn execute_LDH_A_c(cpu: *Cpu, addrLo: u8) void {
    const addr: u16 = 0xFF00 | addrLo;
    const val: u8 = cpu.mem.read8(addr);
    cpu.AF.setHi(val);
}

// Copy the value in register A into the byte pointed by HL and increment HL
// afterwards.
pub fn execute_LDH_HLI_A(cpu: *Cpu) void {
    const val: u8 = cpu.AF.getHi();
    const addr: u16 = cpu.HL.HiLo();
    cpu.mem.write8(addr, val);
    cpu.HL.inc();
}

// Copy the value in register A into the byte pointed by HL and decrement HL
// afterwards.
pub fn execute_LDH_HLD_A(cpu: *Cpu) void {
    const val: u8 = cpu.AF.getHi();
    const addr: u16 = cpu.HL.HiLo();
    cpu.mem.write8(addr, val);
    cpu.HL.dec();
}

// Copy the byte pointed to by HL into register A, and decrement HL
// afterwards.
pub fn execute_LD_A_HLD(cpu: *Cpu) void {
    const addr: u16 = cpu.HL.HiLo();
    const val: u8 = cpu.mem.read8(addr);
    cpu.AF.setHi(val);
    cpu.HL.dec();
}

// Copy the byte pointed to by HL into register A, and decrement HL
// afterwards.
pub fn execute_LD_A_HLI(cpu: *Cpu) void {
    const addr: u16 = cpu.HL.HiLo();
    const val: u8 = cpu.mem.read8(addr);
    cpu.AF.setHi(val);
    cpu.HL.inc();
}

// Copy the value n16 into register SP.
pub fn execute_LD_SP_n16(cpu: *Cpu, val: u16) void {
    cpu.SP.set(val);
}

// Copy SP & $FF at address n16 and SP >> 8 at address n16 + 1.
pub fn execute_LD_n16_SP(cpu: *Cpu, addr: u16) void {
    const val1: u8 = cpu.SP.getLo();
    const val2: u8 = cpu.SP.getHi();
    cpu.mem.write8(addr, val1);
    cpu.mem.write8(addr + 1, val2);
}

// Add the signed value e8 to SP and copy the result in HL.
pub fn execute_LD_HL_SP_plus_e8(cpu: *Cpu, e8: i8) void {
    const sp = cpu.SP.getHiLo();
    const result: u16 = @bitCast(@as(i16, sp) + @as(i16, e8));
    cpu.HL.set(result);
    set_NHC_FLAGS_r8_ADD(cpu, @truncate(sp), @bitCast(e8));
}

// Copy register HL into register SP.
pub fn execute_LD_SP_HL(cpu: *Cpu) void {
    const val: u16 = cpu.HL.getHiLo();
    cpu.SP.set(val);
}
