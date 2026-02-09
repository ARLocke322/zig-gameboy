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

    // INC r8 (00-r8-100)
    table[0x04] = inst(&INC_B, 1);
    table[0x0C] = inst(&INC_C, 1);
    table[0x14] = inst(&INC_D, 1);
    table[0x1C] = inst(&INC_E, 1);
    table[0x24] = inst(&INC_H, 1);
    table[0x2C] = inst(&INC_L, 1);
    table[0x34] = inst(&INC_HL_mem, 3);
    table[0x3C] = inst(&INC_A, 1);

    // DEC r8 (00-r8-101)
    table[0x05] = inst(&DEC_B, 1);
    table[0x0D] = inst(&DEC_C, 1);
    table[0x15] = inst(&DEC_D, 1);
    table[0x1D] = inst(&DEC_E, 1);
    table[0x25] = inst(&DEC_H, 1);
    table[0x2D] = inst(&DEC_L, 1);
    table[0x35] = inst(&DEC_HL_mem, 3);
    table[0x3D] = inst(&DEC_A, 1);

    // LD r8, n8 (00-r8-110) - 2 cycles for registers, 3 cycles for (HL)
    table[0x06] = inst(&LD_B_n8, 2);
    table[0x0E] = inst(&LD_C_n8, 2);
    table[0x16] = inst(&LD_D_n8, 2);
    table[0x1E] = inst(&LD_E_n8, 2);
    table[0x26] = inst(&LD_H_n8, 2);
    table[0x2E] = inst(&LD_L_n8, 2);
    table[0x36] = inst(&LD_HL_mem_n8, 3);
    table[0x3E] = inst(&LD_A_n8, 2);

    // Rotate/adjust instructions (00-xxx-111)
    table[0x07] = inst(&RLCA, 1);
    table[0x0F] = inst(&RRCA, 1);
    table[0x17] = inst(&RLA, 1);
    table[0x1F] = inst(&RRA, 1);
    table[0x27] = inst(&DAA, 1);
    table[0x2F] = inst(&CPL, 1);
    table[0x37] = inst(&SCF, 1);
    table[0x3F] = inst(&CCF, 1);

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

// 00-r8-100
fn INC_B(cpu: *Cpu) void {
    x.execInc8(cpu.BC, Register.setHi, cpu.BC.getHi());
}
fn INC_C(cpu: *Cpu) void {
    x.execInc8(cpu.BC, Register.setLo, cpu.BC.getLo());
}
fn INC_D(cpu: *Cpu) void {
    x.execInc8(cpu.DE, Register.setHi, cpu.DE.getHi());
}
fn INC_E(cpu: *Cpu) void {
    x.execInc8(cpu.DE, Register.setLo, cpu.DE.getLo());
}
fn INC_H(cpu: *Cpu) void {
    x.execInc8(cpu.HL, Register.setHi, cpu.HL.getHi());
}
fn INC_L(cpu: *Cpu) void {
    x.execInc8(cpu.HL, Register.setLo, cpu.HL.getLo());
}
fn INC_HL_mem(cpu: *Cpu) void {
    const addr: u16 = cpu.HL.getHiLo();
    cpu.mem.write8(addr, cpu.mem.read8(addr) + 1);
}
fn INC_A(cpu: *Cpu) void {
    x.execInc8(cpu.AF, Register.setHi, cpu.AF.getHi());
}

// 00-r8-101
fn DEC_B(cpu: *Cpu) void {
    x.execDec8(cpu.BC, Register.setHi, cpu.BC.getHi());
}
fn DEC_C(cpu: *Cpu) void {
    x.execDec8(cpu.BC, Register.setLo, cpu.BC.getLo());
}
fn DEC_D(cpu: *Cpu) void {
    x.execDec8(cpu.DE, Register.setHi, cpu.DE.getHi());
}
fn DEC_E(cpu: *Cpu) void {
    x.execDec8(cpu.DE, Register.setLo, cpu.DE.getLo());
}
fn DEC_H(cpu: *Cpu) void {
    x.execDec8(cpu.HL, Register.setHi, cpu.HL.getHi());
}
fn DEC_L(cpu: *Cpu) void {
    x.execDec8(cpu.HL, Register.setLo, cpu.HL.getLo());
}
fn DEC_HL_mem(cpu: *Cpu) void {
    const addr: u16 = cpu.HL.getHiLo();
    cpu.mem.write8(addr, cpu.mem.read8(addr) + 1);
}
fn DEC_A(cpu: *Cpu) void {
    x.execDec8(cpu.AF, Register.setHi, cpu.AF.getHi());
}

fn LD_B_n8(cpu: *Cpu) void {
    cpu.BC.setHi(cpu.pc_pop_8());
}
fn LD_C_n8(cpu: *Cpu) void {
    cpu.BC.setLo(cpu.pc_pop_8());
}
fn LD_D_n8(cpu: *Cpu) void {
    cpu.DE.setHi(cpu.pc_pop_8());
}
fn LD_E_n8(cpu: *Cpu) void {
    cpu.DE.setLo(cpu.pc_pop_8());
}
fn LD_H_n8(cpu: *Cpu) void {
    cpu.HL.setHi(cpu.pc_pop_8());
}
fn LD_L_n8(cpu: *Cpu) void {
    cpu.HL.setLo(cpu.pc_pop_8());
}
fn LD_HL_mem_n8(cpu: *Cpu) void {
    const addr: u16 = cpu.HL.getHiLo();
    cpu.mem.write8(addr, cpu.pc_pop_8());
}
fn LD_A_n8(cpu: *Cpu) void {
    cpu.AF.setHi(cpu.pc_pop_8());
}

fn RLCA(cpu: *Cpu) void {
    x.execRotateLeft(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), false);
}
fn RRCA(cpu: *Cpu) void {
    x.execRotateRight(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), false);
}
fn RLA(cpu: *Cpu) void {
    x.execRotateLeft(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), true);
}
fn RRA(cpu: *Cpu) void {
    x.execRotateRight(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), true);
}
fn DAA(cpu: *Cpu) void {
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
}
fn CPL(cpu: *Cpu) void {
    cpu.AF.setHi(~cpu.AF.getHi());
    cpu.set_n(true);
    cpu.set_h(true);
}
fn SCF(cpu: *Cpu) void {
    cpu.set_c(true);
}
fn CCF(cpu: *Cpu) void {
    cpu.set_c(~cpu.get_c() == 1);
}

// add opcode to table
fn JR_n8(cpu: *Cpu) void {
    const signed_offset: i8 = @bitCast(cpu.pc_pop_8());
    const offset_u16: u16 = @bitCast(@as(i16, signed_offset));
    x.execJump(cpu, cpu.PC.getHiLo() +% offset_u16);
}

// fn JR_C0_n8(cpu: *Cpu) void {
// const signed_offset: i8 = @bitCast(cpu.pc_pop_8());
// const offset_u16: u16 = @bitCast(@as(i16, signed_offset));
// if (cpu.get_z() == 0) x.execJump(cpu, cpu.PC.getHiLo() +% offset_u16);
// }
// fn JR_C1_n8(cpu: *Cpu) void {
// const signed_offset: i8 = @bitCast(cpu.pc_pop_8());
// const offset_u16: u16 = @bitCast(@as(i16, signed_offset));
// if (cpu.get_z() == 0) x.execJump(cpu, cpu.PC.getHiLo() +% offset_u16);
// }
// fn JR_C2_n8(cpu: *Cpu) void {
// const signed_offset: i8 = @bitCast(cpu.pc_pop_8());
// const offset_u16: u16 = @bitCast(@as(i16, signed_offset));
// if (cpu.get_z() == 0) x.execJump(cpu, cpu.PC.getHiLo() +% offset_u16);
// }
// fn JR_C3_n8(cpu: *Cpu) void {
// const signed_offset: i8 = @bitCast(cpu.pc_pop_8());
// const offset_u16: u16 = @bitCast(@as(i16, signed_offset));
// if (cpu.get_z() == 0) x.execJump(cpu, cpu.PC.getHiLo() +% offset_u16);
// }
