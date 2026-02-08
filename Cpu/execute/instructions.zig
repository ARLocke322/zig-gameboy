const std = @import("std");
const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../register.zig").Register;
const Bus = @import("../../bus.zig").Bus;
const x = @import("testing.zig");

// could use array of functions, with a step function, current index, cycles
const Instruction = struct { execute: *const fn (*Cpu) void, cycles: u8 };

fn inst(execute: *const fn (*Cpu) void, cycles: u8) Instruction {
    return Instruction{ .execute = execute, .cycles = cycles };
}

pub const instructions: [256]Instruction = blk: {
    var table: [256]Instruction = undefined;
    @memset(&table, inst(&ILLEGAL, 0));

    table[0x00] = inst(&NOP, 1);
    // double check cycles
    // LD r16, n16 (00-r16-0001)
    table[0x01] = inst(&LD_BC_n16, 3);
    table[0x11] = inst(&LD_DE_n16, 3);
    table[0x21] = inst(&LD_HL_n16, 3);
    table[0x31] = inst(&LD_SP_n16, 3);

    // LD (r16), A (00-r16-0010)
    table[0x02] = inst(&LD_BC_A, 2);
    table[0x12] = inst(&LD_DE_A, 2);
    table[0x22] = inst(&LD_HLI_A, 2);
    table[0x32] = inst(&LD_HLD_A, 2);

    // INC r16 (00-r16-0011)
    table[0x03] = inst(&INC_BC, 2);
    table[0x13] = inst(&INC_DE, 2);
    table[0x23] = inst(&INC_HL, 2);
    table[0x33] = inst(&INC_SP, 2);

    table[0x08] = inst(&LD_n16_SP, 5);

    // ADD HL, r16 (00-r16-1001)
    table[0x09] = inst(&ADD_HL_BC, 2);
    table[0x19] = inst(&ADD_HL_DE, 2);
    table[0x29] = inst(&ADD_HL_HL, 2);
    table[0x39] = inst(&ADD_HL_SP, 2);

    // LD A, (r16) (00-r16-1010)
    table[0x0A] = inst(&LD_A_BC, 2);
    table[0x1A] = inst(&LD_A_DE, 2);
    table[0x2A] = inst(&LD_A_HLI, 2);
    table[0x3A] = inst(&LD_A_HLD, 2);

    // DEC r16 (00-r16-1011)
    table[0x0B] = inst(&DEC_BC, 2);
    table[0x1B] = inst(&DEC_DE, 2);
    table[0x2B] = inst(&DEC_HL, 2);
    table[0x3B] = inst(&DEC_SP, 2);

    break :blk table;
};

fn ILLEGAL(cpu: *Cpu) void {
    _ = cpu;
    @panic("Illegal instruction");
}

fn NOP(cpu: *Cpu) void {
    _ = cpu;
}

// x.execLoad(&cpu.BC, Register.set, cpu.pc_pop_16());
fn LD_BC_n16(cpu: *Cpu) void {
    cpu.BC.set(cpu.pc_pop_16());
}
fn LD_DE_n16(cpu: *Cpu) void {
    cpu.DE.set(cpu.pc_pop_16());
}
fn LD_HL_n16(cpu: *Cpu) void {
    cpu.HL.set(cpu.pc_pop_16());
}
fn LD_SP_n16(cpu: *Cpu) void {
    cpu.SP.set(cpu.pc_pop_16());
}

fn LD_BC_A(cpu: *Cpu) void {
    cpu.mem.write8(cpu.BC.getHiLo(), cpu.AF.getHi());
}
fn LD_DE_A(cpu: *Cpu) void {
    cpu.mem.write8(cpu.DE.getHiLo(), cpu.AF.getHi());
}
fn LD_HLI_A(cpu: *Cpu) void {
    cpu.mem.write8(cpu.HL.getHiLo(), cpu.AF.getHi());
    cpu.HL.inc();
}
fn LD_HLD_A(cpu: *Cpu) void {
    cpu.mem.write8(cpu.HL.getHiLo(), cpu.AF.getHi());
    cpu.HL.dec();
}

fn LD_A_BC(cpu: *Cpu) void {
    cpu.AF.setHi(cpu.mem.read8(cpu.BC.getHiLo()));
}
fn LD_A_DE(cpu: *Cpu) void {
    cpu.AF.setHi(cpu.mem.read8(cpu.DE.getHiLo()));
}
fn LD_A_HLI(cpu: *Cpu) void {
    cpu.AF.setHi(cpu.mem.read8(cpu.HL.getHiLo()));
    cpu.HL.inc();
}
fn LD_A_HLD(cpu: *Cpu) void {
    cpu.AF.setHi(cpu.mem.read8(cpu.HL.getHiLo()));
    cpu.HL.dec();
}

fn LD_n16_SP(cpu: *Cpu) void {
    cpu.mem.write16(cpu.pc_pop_16(), cpu.SP.getHiLo());
}

// 00-r16-0011
fn INC_BC(cpu: *Cpu) void {
    x.execInc16(cpu.BC, Register.set, cpu.BC.getHiLo());
}
fn INC_DE(cpu: *Cpu) void {
    x.execInc16(cpu.DE, Register.set, cpu.DE.getHiLo());
}
fn INC_HL(cpu: *Cpu) void {
    x.execInc16(cpu.HL, Register.set, cpu.HL.getHiLo());
}
fn INC_SP(cpu: *Cpu) void {
    x.execInc16(cpu.SP, Register.set, cpu.SP.getHiLo());
}

// 00-r16-1011
fn DEC_BC(cpu: *Cpu) void {
    x.execDec16(cpu.BC, Register.set, cpu.BC.getHiLo());
}
fn DEC_DE(cpu: *Cpu) void {
    x.execDec16(cpu.DE, Register.set, cpu.DE.getHiLo());
}
fn DEC_HL(cpu: *Cpu) void {
    x.execDec16(cpu.HL, Register.set, cpu.HL.getHiLo());
}
fn DEC_SP(cpu: *Cpu) void {
    x.execDec16(cpu.SP, Register.set, cpu.SP.getHiLo());
}

// 00-r16-1001
fn ADD_HL_BC(cpu: *Cpu) void {
    x.execAdd16(cpu, cpu.HL, Register.set, cpu.HL.getHiLo(), cpu.BC.getHiLo());
}
fn ADD_HL_DE(cpu: *Cpu) void {
    x.execAdd16(cpu, cpu.HL, Register.set, cpu.HL.getHiLo(), cpu.DE.getHiLo());
}
fn ADD_HL_HL(cpu: *Cpu) void {
    x.execAdd16(cpu, cpu.HL, Register.set, cpu.HL.getHiLo(), cpu.HL.getHiLo());
}
fn ADD_HL_SP(cpu: *Cpu) void {
    x.execAdd16(cpu, cpu.HL, Register.set, cpu.HL.getHiLo(), cpu.SP.getHiLo());
}
