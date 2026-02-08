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

    table[0x01] = inst(&LD_BC_n16, 3);
    table[0x11] = inst(&LD_DE_n16, 3);
    table[0x21] = inst(&LD_HL_n16, 3);
    table[0x31] = inst(&LD_SP_n16, 3);

    table[0x02] = inst(&LD_BC_A, 2);
    table[0x12] = inst(&LD_DE_A, 2);
    table[0x22] = inst(&LD_HLI_A, 2);
    table[0x32] = inst(&LD_HLD_A, 2);

    table[0x02] = inst(&LD_BC_A, 2);
    table[0x12] = inst(&LD_DE_A, 2);
    table[0x22] = inst(&LD_HLI_A, 2);
    table[0x32] = inst(&LD_HLD_A, 2);

    table[0x0A] = inst(&LD_A_BC, 2);
    table[0x1A] = inst(&LD_A_DE, 2);
    table[0x2A] = inst(&LD_A_HLI, 2);
    table[0x3A] = inst(&LD_A_HLD, 2);

    table[0x08] = inst(&LD_n16_SP, 5);

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
    x.execLoad(&cpu.SP, Register.set, cpu.pc_pop_16());
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
