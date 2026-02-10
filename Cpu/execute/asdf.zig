const std = @import("std");
const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../register.zig").Register;
const Bus = @import("../../bus.zig").Bus;
const x = @import("testing.zig");

pub fn execute(cpu: *Cpu, instruction: u8) u8 {
    return switch (instruction) {
        // BLOCK 0
        0x00 => NOP(cpu),
        // -----
        0x01, 0x11, 0x21, 0x31 => LD_r16_n16(cpu, instruction),

        0x02,
        0x12,
        => LD_r16_A(cpu, instruction),
        0x22 => LD_HLI_A(cpu),
        0x32 => LD_HLD_A(cpu),

        0x0A, 0x1A => LD_A_r16(cpu, instruction),
        0x2A => LD_A_HLI(cpu),
        0x3A => LD_A_HLD(cpu),
        0x08 => LD_n16_SP(cpu),
        // ------
        0x03, 0x13, 0x23, 0x33 => INC_r16(cpu, instruction),
        0x0B, 0x1B, 0x2B, 0x3B => DEC_r16(cpu, instruction),
        0x09, 0x19, 0x29, 0x39 => ADD_HL_r16(cpu, instruction),
        // ------
        0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x3E => LD_r8_n8(cpu, instruction),
        0x36 => LD_HL_mem_n8(cpu),
        // -----
        0x04, 0x0C, 0x14, 0x1C, 0x24, 0x2C, 0x3C => INC_r8(cpu, instruction),
        0x34 => INC_HL_mem(cpu),

        0x05, 0x0D, 0x15, 0x1D, 0x25, 0x2D, 0x3D => DEC_r8(cpu, instruction),
        0x35 => DEC_HL_mem(cpu),
        // ---
        0x07 => RLCA(cpu),
        0x0F => RRCA(cpu),
        0x17 => RLA(cpu),
        0x1F => RRA(cpu),
        0x27 => DAA(cpu),
        0x2F => CPL(cpu),
        0x37 => SCF(cpu),
        0x3F => CCF(cpu),

        // BLOCK 1
        0x76 => HALT(),
        0x46, 0x4E, 0x56, 0x5E, 0x66, 0x6E, 0x7E => LD_r8_HL(cpu, instruction),
        0x70...0x75, 0x77 => LD_HL_r8(cpu, instruction),
        0x40...0x7F => LD_r8_r8(cpu, instruction),

        // BLOCK 2
        0x86 => ADD_A_HL(cpu),
        0x80...0x87 => ADD_A_r8(cpu, instruction),

        0x8E => ADC_A_HL(cpu),
        0x88...0x8F => ADC_A_r8(cpu, instruction),

        0x96 => SUB_A_HL(cpu),
        0x90...0x97 => SUB_A_r8(cpu, instruction),

        0x9E => SBC_A_HL(cpu),
        0x98...0x9F => SBC_A_r8(cpu, instruction),

        0xA6 => AND_A_HL(cpu),
        0xA0...0xA7 => AND_A_r8(cpu, instruction),

        0xAE => XOR_A_HL(cpu),
        0xA8...0xAF => XOR_A_r8(cpu, instruction),

        0xB6 => OR_A_HL(cpu),
        0xB0...0xB7 => OR_A_r8(cpu, instruction),

        0xBE => CP_A_HL(cpu),
        0xB8...0xBF => CP_A_r8(cpu, instruction),
    };
}

fn NOP(cpu: *Cpu) u8 {
    _ = cpu;
    return 1;
}

fn LD_r16_n16(cpu: *Cpu, opcode: u8) u8 {
    const r = get_r16(cpu, @truncate(opcode >> 4));
    r.set(cpu.pc_pop_16());
    return 3;
}

fn LD_r16_A(cpu: *Cpu, opcode: u8) u8 {
    const r = get_r16(cpu, @truncate(opcode >> 4));
    cpu.mem.write8(r.getHiLo(), cpu.AF.getHi());
    return 2;
}
fn LD_HLI_A(cpu: *Cpu) u8 {
    cpu.mem.write8(cpu.HL.getHiLo(), cpu.AF.getHi());
    cpu.HL.inc();
    return 2;
}

fn LD_HLD_A(cpu: *Cpu) u8 {
    cpu.mem.write8(cpu.HL.getHiLo(), cpu.AF.getHi());
    cpu.HL.dec();
    return 2;
}

fn LD_A_r16(cpu: *Cpu, opcode: u8) u8 {
    const r = get_r16mem(cpu, @truncate(opcode >> 4));
    cpu.AF.setHi(cpu.mem.read8(r.getHiLo()));
    return 2;
}

fn LD_A_HLI(cpu: *Cpu) u8 {
    cpu.AF.setHi(cpu.mem.read8(cpu.HL.getHiLo()));
    cpu.HL.inc();
    return 2;
}
fn LD_A_HLD(cpu: *Cpu) u8 {
    cpu.AF.setHi(cpu.mem.read8(cpu.HL.getHiLo()));
    cpu.HL.dec();
    return 2;
}
fn LD_n16_SP(cpu: *Cpu) u8 {
    cpu.mem.write16(cpu.pc_pop_16(), cpu.SP.getHiLo());
    return 5;
}

fn INC_r16(cpu: *Cpu, opcode: u8) u8 {
    const r = get_r16(cpu, @truncate(opcode >> 4));
    x.execInc16(r, Register.set, r.getHiLo());
    return 2;
}

fn DEC_r16(cpu: *Cpu, opcode: u8) u8 {
    const r = get_r16(cpu, @truncate(opcode >> 4));
    x.execDec16(r, Register.set, r.getHiLo());
    return 2;
}

fn ADD_HL_r16(cpu: *Cpu, opcode: u8) u8 {
    const r = get_r16(cpu, @truncate(opcode >> 4));
    x.execAdd16(cpu, r, Register.set, cpu.HL.getHiLo(), r.getHiLo());
    return 2;
}

fn LD_r8_n8(cpu: *Cpu, opcode: u8) u8 {
    const r = get_r8(cpu, @truncate(opcode >> 3));
    r.set(cpu.pc_pop_8());
    return 2;
}

fn LD_HL_mem_n8(cpu: *Cpu) u8 {
    const addr: u16 = cpu.HL.getHiLo();
    cpu.mem.write8(addr, cpu.pc_pop_8());
    return 3;
}

fn INC_r8(cpu: *Cpu, opcode: u8) u8 {
    const r = get_r8(cpu, @truncate(opcode >> 3));
    x.execInc8(r.reg, r.set, r.get(r.reg));
    return 1;
}

fn INC_HL_mem(cpu: *Cpu) u8 {
    const addr: u16 = cpu.HL.getHiLo();
    cpu.mem.write8(addr, cpu.mem.read8(addr) + 1);
    return 3;
}

fn DEC_r8(cpu: *Cpu, opcode: u8) u8 {
    const r = get_r8(cpu, @truncate(opcode >> 3));
    x.execDec8(r.reg, r.set, r.get(r.reg));
    return 1;
}

fn DEC_HL_mem(cpu: *Cpu) u8 {
    const addr: u16 = cpu.HL.getHiLo();
    cpu.mem.write8(addr, cpu.mem.read8(addr) - 1);
    return 3;
}

fn RLCA(cpu: *Cpu) u8 {
    x.execRotateLeft(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), false);
    return 1;
}
fn RRCA(cpu: *Cpu) u8 {
    x.execRotateRight(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), false);
    return 1;
}
fn RLA(cpu: *Cpu) u8 {
    x.execRotateLeft(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), true);
    return 1;
}
fn RRA(cpu: *Cpu) u8 {
    x.execRotateRight(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), true);
    return 1;
}
fn DAA(cpu: *Cpu) u8 {
    var adjustment: u8 = 0;
    const current: u8 = cpu.AF.getHi();
    if (cpu.get_n() == 1) {
        if (cpu.get_h() == 1) adjustment = 0x6;
        if (cpu.get_c() == 1) adjustment += 0x60;
        cpu.AF.setHi(current -% adjustment);
    } else {
        if (cpu.get_h() == 1 or (current & 0xF) > 0x9) adjustment = 0x6;
        if (cpu.get_c() == 1 or current > 0x99) {
            adjustment += 0x60;
            cpu.set_c(true);
        }
        cpu.AF.setHi(current +% adjustment);
    }

    cpu.set_z(cpu.AF.getHi() == 0);
    cpu.set_h(false);
    return 1;
}
fn CPL(cpu: *Cpu) u8 {
    cpu.AF.setHi(~cpu.AF.getHi());
    cpu.set_n(true);
    cpu.set_h(true);
    return 1;
}
fn SCF(cpu: *Cpu) u8 {
    cpu.set_n(false);
    cpu.set_h(false);
    cpu.set_c(true);
    return 1;
}
fn CCF(cpu: *Cpu) u8 {
    cpu.set_n(false);
    cpu.set_h(false);
    cpu.set_c(~cpu.get_c() == 1);
    return 1;
}

fn LD_r8_r8(cpu: *Cpu, opcode: u8) u8 {
    const r_d = get_r8(cpu, @truncate(opcode >> 3));
    const r_s = get_r8(cpu, @truncate(opcode));
    r_d.set(r_d.reg, r_s.get(r_s.reg));
    return 1;
}

fn LD_r8_HL(cpu: *Cpu, opcode: u8) u8 {
    const r_d = get_r8(cpu, @truncate(opcode >> 3));
    r_d.set(r_d.reg, cpu.mem.read8(cpu.HL.getHiLo()));
    return 2;
}

fn LD_HL_r8(cpu: *Cpu, opcode: u8) u8 {
    const r_s = get_r8(cpu, @truncate(opcode));
    cpu.mem.write8(cpu.HL.getHiLo(), r_s.get(r_s.reg));
    return 2;
}
// cpu: *Cpu
fn HALT() u8 {
    // cpu.halted = true;
    return 1;
}

// ------ BLOCK 2 ------
fn ADD_A_r8(cpu: *Cpu) u8 {}
fn ADC_A_HL(cpu: *Cpu) u8 {}
fn ADC_A_r8(cpu: *Cpu) u8 {}
fn SUB_A_HL(cpu: *Cpu) u8 {}
fn SUB_A_r8(cpu: *Cpu) u8 {}
fn SBC_A_HL(cpu: *Cpu) u8 {}
fn SBC_A_r8(cpu: *Cpu) u8 {}
fn AND_A_HL(cpu: *Cpu) u8 {}
fn AND_A_r8(cpu: *Cpu) u8 {}
fn XOR_A_HL(cpu: *Cpu) u8 {}
fn XOR_A_r8(cpu: *Cpu) u8 {}
fn OR_A_HL(cpu: *Cpu) u8 {}
fn OR_A_r8(cpu: *Cpu) u8 {}
fn CP_A_HL(cpu: *Cpu) u8 {}
fn CP_A_r8(cpu: *Cpu) u8 {}

// ------ HELPERS ------
pub fn get_r8(cpu: *Cpu, index: u3) struct {
    reg: *Register,
    get: *const fn (*Register) u8,
    set: *const fn (*Register, u8) void,
} {
    std.debug.assert(index != 6);
    return switch (index) {
        0 => .{ .reg = &cpu.BC, .get = Register.getHi, .set = Register.setHi },
        1 => .{ .reg = &cpu.BC, .get = Register.getLo, .set = Register.setLo },
        2 => .{ .reg = &cpu.DE, .get = Register.getHi, .set = Register.setHi },
        3 => .{ .reg = &cpu.DE, .get = Register.getLo, .set = Register.setLo },
        4 => .{ .reg = &cpu.HL, .get = Register.getHi, .set = Register.setHi },
        5 => .{ .reg = &cpu.HL, .get = Register.getLo, .set = Register.setLo },
        6 => unreachable,
        7 => .{ .reg = &cpu.AF, .get = Register.getHi, .set = Register.setHi },
    };
}

pub fn get_r16(cpu: *Cpu, index: u2) *Register {
    return switch (index) {
        0 => &cpu.BC,
        1 => &cpu.DE,
        2 => &cpu.HL,
        3 => &cpu.SP,
    };
}

pub fn get_r16mem(cpu: *Cpu, index: u2) *Register {
    std.debug.assert(index == 0 or index == 1);
    return switch (index) {
        0 => &cpu.BC,
        1 => &cpu.DE,
        2 => unreachable,
        3 => unreachable,
    };
}
