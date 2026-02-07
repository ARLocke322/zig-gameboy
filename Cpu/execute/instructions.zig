const std = @import("std");
const Cpu = @import("../cpu.zig").Cpu;
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

    break :blk table;
};

fn ILLEGAL(cpu: *Cpu) void {
    _ = cpu;
    @panic("Illegal instruction");
}

fn NOP(cpu: *Cpu) void {
    _ = cpu;
}

fn LD_BC_n16(cpu: *Cpu) void {
    x.execLoad(cpu.BC.set, cpu.pc_pop_16());
}
fn LD_DE_n16(cpu: *Cpu) void {
    x.execLoad(cpu.DE.set, cpu.pc_pop_16());
}
fn LD_HL_n16(cpu: *Cpu) void {
    x.execLoad(cpu.HL.set, cpu.pc_pop_16());
}
fn LD_SP_n16(cpu: *Cpu) void {
    x.execLoad(cpu.SP.set, cpu.pc_pop_16());
}

fn LD_mem_BC_A(cpu: *Cpu) void {
    const set = struct {
        fn set(val: u8) void {
            const addr: u16 = cpu.BC.getHiLo();
            cpu.mem.write8(addr, val);
        }
    }.set;
    x.execLoad(set, cpu.AF.getHi());
}
