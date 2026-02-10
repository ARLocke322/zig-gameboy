const std = @import("std");
const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../register.zig").Register;
const Bus = @import("../../bus.zig").Bus;
const x = @import("testing.zig");

// could use array of functions, with a step function, current index, cycles
const Instruction = struct { execute: *const fn (*Cpu) u8 };

fn inst(execute: *const fn (*Cpu) void) Instruction {
    return Instruction{ .execute = execute };
}

pub const instructions: [256]Instruction = blk: {
    var table: [256]Instruction = undefined;
    @memset(&table, inst(&ILLEGAL, 0));

    table[0x00] = inst(&NOP, 1);
    // double check cycles
    // LD r16, n16 (00-r16-0001)
    table[0x01] = inst(&LD_BC_n16);
    table[0x11] = inst(&LD_DE_n16);
    table[0x21] = inst(&LD_HL_n16);
    table[0x31] = inst(&LD_SP_n16);

    // LD (r16), A (00-r16-0010)
    table[0x02] = inst(&LD_BC_A);
    table[0x12] = inst(&LD_DE_A);
    table[0x22] = inst(&LD_HLI_A);
    table[0x32] = inst(&LD_HLD_A);

    // INC r16 (00-r16-0011)
    table[0x03] = inst(&INC_BC);
    table[0x13] = inst(&INC_DE);
    table[0x23] = inst(&INC_HL);
    table[0x33] = inst(&INC_SP);

    table[0x08] = inst(&LD_n16_SP);

    // ADD HL, r16 (00-r16-1001)
    table[0x09] = inst(&ADD_HL_BC);
    table[0x19] = inst(&ADD_HL_DE);
    table[0x29] = inst(&ADD_HL_HL);
    table[0x39] = inst(&ADD_HL_SP);

    // LD A, (r16) (00-r16-1010)
    table[0x0A] = inst(&LD_A_BC);
    table[0x1A] = inst(&LD_A_DE);
    table[0x2A] = inst(&LD_A_HLI);
    table[0x3A] = inst(&LD_A_HLD);

    // DEC r16 (00-r16-1011)
    table[0x0B] = inst(&DEC_BC);
    table[0x1B] = inst(&DEC_DE);
    table[0x2B] = inst(&DEC_HL);
    table[0x3B] = inst(&DEC_SP);

    // INC r8 (00-r8-100)
    table[0x04] = inst(&INC_B);
    table[0x0C] = inst(&INC_C);
    table[0x14] = inst(&INC_D);
    table[0x1C] = inst(&INC_E);
    table[0x24] = inst(&INC_H);
    table[0x2C] = inst(&INC_L);
    table[0x34] = inst(&INC_HL_mem);
    table[0x3C] = inst(&INC_A);

    // DEC r8 (00-r8-101)
    table[0x05] = inst(&DEC_B);
    table[0x0D] = inst(&DEC_C);
    table[0x15] = inst(&DEC_D);
    table[0x1D] = inst(&DEC_E);
    table[0x25] = inst(&DEC_H);
    table[0x2D] = inst(&DEC_L);
    table[0x35] = inst(&DEC_HL_mem);
    table[0x3D] = inst(&DEC_A);

    // LD r8, n8 (00-r8-110)
    table[0x06] = inst(&LD_B_n8);
    table[0x0E] = inst(&LD_C_n8);
    table[0x16] = inst(&LD_D_n8);
    table[0x1E] = inst(&LD_E_n8);
    table[0x26] = inst(&LD_H_n8);
    table[0x2E] = inst(&LD_L_n8);
    table[0x36] = inst(&LD_HL_mem_n8);
    table[0x3E] = inst(&LD_A_n8);

    // Rotate/adjust instructions
    table[0x07] = inst(&RLCA);
    table[0x0F] = inst(&RRCA);
    table[0x17] = inst(&RLA);
    table[0x1F] = inst(&RRA);
    table[0x27] = inst(&DAA);
    table[0x2F] = inst(&CPL);
    table[0x37] = inst(&SCF);
    table[0x3F] = inst(&CCF);

    table[0x18] = inst(&JR_n8);
    table[0x20] = inst(&JR_C0_n8);
    table[0x28] = inst(&JR_C1_n8);
    table[0x30] = inst(&JR_C2_n8);
    table[0x38] = inst(&JR_C3_n8);

    table[0x10] = inst(&STOP);
    // LD r8, r8 (0x40-0x7F) - 1 cycle for registers, 2 cycles for [HL]
    table[0x40] = inst(&LD_B_B);
    table[0x41] = inst(&LD_B_C);
    table[0x42] = inst(&LD_B_D);
    table[0x43] = inst(&LD_B_E);
    table[0x44] = inst(&LD_B_H);
    table[0x45] = inst(&LD_B_L);
    table[0x46] = inst(&LD_B_HL);
    table[0x47] = inst(&LD_B_A);

    table[0x48] = inst(&LD_C_B);
    table[0x49] = inst(&LD_C_C);
    table[0x4A] = inst(&LD_C_D);
    table[0x4B] = inst(&LD_C_E);
    table[0x4C] = inst(&LD_C_H);
    table[0x4D] = inst(&LD_C_L);
    table[0x4E] = inst(&LD_C_HL);
    table[0x4F] = inst(&LD_C_A);

    table[0x50] = inst(&LD_D_B);
    table[0x51] = inst(&LD_D_C);
    table[0x52] = inst(&LD_D_D);
    table[0x53] = inst(&LD_D_E);
    table[0x54] = inst(&LD_D_H);
    table[0x55] = inst(&LD_D_L);
    table[0x56] = inst(&LD_D_HL);
    table[0x57] = inst(&LD_D_A);

    table[0x58] = inst(&LD_E_B);
    table[0x59] = inst(&LD_E_C);
    table[0x5A] = inst(&LD_E_D);
    table[0x5B] = inst(&LD_E_E);
    table[0x5C] = inst(&LD_E_H);
    table[0x5D] = inst(&LD_E_L);
    table[0x5E] = inst(&LD_E_HL);
    table[0x5F] = inst(&LD_E_A);

    table[0x60] = inst(&LD_H_B);
    table[0x61] = inst(&LD_H_C);
    table[0x62] = inst(&LD_H_D);
    table[0x63] = inst(&LD_H_E);
    table[0x64] = inst(&LD_H_H);
    table[0x65] = inst(&LD_H_L);
    table[0x66] = inst(&LD_H_HL);
    table[0x67] = inst(&LD_H_A);

    table[0x68] = inst(&LD_L_B);
    table[0x69] = inst(&LD_L_C);
    table[0x6A] = inst(&LD_L_D);
    table[0x6B] = inst(&LD_L_E);
    table[0x6C] = inst(&LD_L_H);
    table[0x6D] = inst(&LD_L_L);
    table[0x6E] = inst(&LD_L_HL);
    table[0x6F] = inst(&LD_L_A);

    table[0x70] = inst(&LD_HL_B);
    table[0x71] = inst(&LD_HL_C);
    table[0x72] = inst(&LD_HL_D);
    table[0x73] = inst(&LD_HL_E);
    table[0x74] = inst(&LD_HL_H);
    table[0x75] = inst(&LD_HL_L);
    table[0x76] = inst(&HALT);
    table[0x77] = inst(&LD_HL_A);

    table[0x78] = inst(&LD_A_B);
    table[0x79] = inst(&LD_A_C);
    table[0x7A] = inst(&LD_A_D);
    table[0x7B] = inst(&LD_A_E);
    table[0x7C] = inst(&LD_A_H);
    table[0x7D] = inst(&LD_A_L);
    table[0x7E] = inst(&LD_A_HL);
    table[0x7F] = inst(&LD_A_A);

    // ADD A, r8 (0x80-0x87) - 1 cycle for registers, 2 cycles for [HL]
    table[0x80] = inst(&ADD_A_B);
    table[0x81] = inst(&ADD_A_C);
    table[0x82] = inst(&ADD_A_D);
    table[0x83] = inst(&ADD_A_E);
    table[0x84] = inst(&ADD_A_H);
    table[0x85] = inst(&ADD_A_L);
    table[0x86] = inst(&ADD_A_HL);
    table[0x87] = inst(&ADD_A_A);

    // ADC A, r8 (0x88-0x8F) - 1 cycle for registers, 2 cycles for [HL]
    table[0x88] = inst(&ADC_A_B);
    table[0x89] = inst(&ADC_A_C);
    table[0x8A] = inst(&ADC_A_D);
    table[0x8B] = inst(&ADC_A_E);
    table[0x8C] = inst(&ADC_A_H);
    table[0x8D] = inst(&ADC_A_L);
    table[0x8E] = inst(&ADC_A_HL);
    table[0x8F] = inst(&ADC_A_A);

    // SUB A, r8 (0x90-0x97) - 1 cycle for registers, 2 cycles for [HL]
    table[0x90] = inst(&SUB_A_B);
    table[0x91] = inst(&SUB_A_C);
    table[0x92] = inst(&SUB_A_D);
    table[0x93] = inst(&SUB_A_E);
    table[0x94] = inst(&SUB_A_H);
    table[0x95] = inst(&SUB_A_L);
    table[0x96] = inst(&SUB_A_HL);
    table[0x97] = inst(&SUB_A_A);

    // SBC A, r8 (0x98-0x9F) - 1 cycle for registers, 2 cycles for [HL]
    table[0x98] = inst(&SBC_A_B);
    table[0x99] = inst(&SBC_A_C);
    table[0x9A] = inst(&SBC_A_D);
    table[0x9B] = inst(&SBC_A_E);
    table[0x9C] = inst(&SBC_A_H);
    table[0x9D] = inst(&SBC_A_L);
    table[0x9E] = inst(&SBC_A_HL);
    table[0x9F] = inst(&SBC_A_A);

    // AND A, r8 (0xA0-0xA7) - 1 cycle for registers, 2 cycles for [HL]
    table[0xA0] = inst(&AND_A_B);
    table[0xA1] = inst(&AND_A_C);
    table[0xA2] = inst(&AND_A_D);
    table[0xA3] = inst(&AND_A_E);
    table[0xA4] = inst(&AND_A_H);
    table[0xA5] = inst(&AND_A_L);
    table[0xA6] = inst(&AND_A_HL);
    table[0xA7] = inst(&AND_A_A);

    // XOR A, r8 (0xA8-0xAF) - 1 cycle for registers, 2 cycles for [HL]
    table[0xA8] = inst(&XOR_A_B);
    table[0xA9] = inst(&XOR_A_C);
    table[0xAA] = inst(&XOR_A_D);
    table[0xAB] = inst(&XOR_A_E);
    table[0xAC] = inst(&XOR_A_H);
    table[0xAD] = inst(&XOR_A_L);
    table[0xAE] = inst(&XOR_A_HL);
    table[0xAF] = inst(&XOR_A_A);

    // OR A, r8 (0xB0-0xB7) - 1 cycle for registers, 2 cycles for [HL]
    table[0xB0] = inst(&OR_A_B);
    table[0xB1] = inst(&OR_A_C);
    table[0xB2] = inst(&OR_A_D);
    table[0xB3] = inst(&OR_A_E);
    table[0xB4] = inst(&OR_A_H);
    table[0xB5] = inst(&OR_A_L);
    table[0xB6] = inst(&OR_A_HL);
    table[0xB7] = inst(&OR_A_A);

    // CP A, r8 (0xB8-0xBF) - 1 cycle for registers, 2 cycles for [HL]
    table[0xB8] = inst(&CP_A_B);
    table[0xB9] = inst(&CP_A_C);
    table[0xBA] = inst(&CP_A_D);
    table[0xBB] = inst(&CP_A_E);
    table[0xBC] = inst(&CP_A_H);
    table[0xBD] = inst(&CP_A_L);
    table[0xBE] = inst(&CP_A_HL);
    table[0xBF] = inst(&CP_A_A);

    break :blk table;
};

fn ILLEGAL(cpu: *Cpu) void {
    _ = cpu;
    @panic("Illegal instruction");
}

fn NOP(cpu: *Cpu) void {
    _ = cpu;
    return 1;
}

// x.execLoad(&cpu.BC, Register.set, cpu.pc_pop_16());
fn LD_BC_n16(cpu: *Cpu) void {
    cpu.BC.set(cpu.pc_pop_16());
    return 3;
}
fn LD_DE_n16(cpu: *Cpu) void {
    cpu.DE.set(cpu.pc_pop_16());
    return 3;
}
fn LD_HL_n16(cpu: *Cpu) void {
    cpu.HL.set(cpu.pc_pop_16());
    return 3;
}
fn LD_SP_n16(cpu: *Cpu) void {
    cpu.SP.set(cpu.pc_pop_16());
    return 3;
}

fn LD_BC_A(cpu: *Cpu) void {
    cpu.mem.write8(cpu.BC.getHiLo(), cpu.AF.getHi());
    return 2;
}
fn LD_DE_A(cpu: *Cpu) void {
    cpu.mem.write8(cpu.DE.getHiLo(), cpu.AF.getHi());
    return 2;
}
fn LD_HLI_A(cpu: *Cpu) void {
    cpu.mem.write8(cpu.HL.getHiLo(), cpu.AF.getHi());
    cpu.HL.inc();
    return 2;
}
fn LD_HLD_A(cpu: *Cpu) void {
    cpu.mem.write8(cpu.HL.getHiLo(), cpu.AF.getHi());
    cpu.HL.dec();
    return 2;
}

fn LD_A_BC(cpu: *Cpu) void {
    cpu.AF.setHi(cpu.mem.read8(cpu.BC.getHiLo()));
    return 2;
}
fn LD_A_DE(cpu: *Cpu) void {
    cpu.AF.setHi(cpu.mem.read8(cpu.DE.getHiLo()));
    return 2;
}
fn LD_A_HLI(cpu: *Cpu) void {
    cpu.AF.setHi(cpu.mem.read8(cpu.HL.getHiLo()));
    cpu.HL.inc();
    return 2;
}
fn LD_A_HLD(cpu: *Cpu) void {
    cpu.AF.setHi(cpu.mem.read8(cpu.HL.getHiLo()));
    cpu.HL.dec();
    return 2;
}

fn LD_n16_SP(cpu: *Cpu) void {
    cpu.mem.write16(cpu.pc_pop_16(), cpu.SP.getHiLo());
    return 5;
}

// 00-r16-0011
fn INC_BC(cpu: *Cpu) void {
    x.execInc16(cpu.BC, Register.set, cpu.BC.getHiLo());
    return 2;
}
fn INC_DE(cpu: *Cpu) void {
    x.execInc16(cpu.DE, Register.set, cpu.DE.getHiLo());
    return 2;
}
fn INC_HL(cpu: *Cpu) void {
    x.execInc16(cpu.HL, Register.set, cpu.HL.getHiLo());
    return 2;
}
fn INC_SP(cpu: *Cpu) void {
    x.execInc16(cpu.SP, Register.set, cpu.SP.getHiLo());
    return 2;
}

// 00-r16-1011
fn DEC_BC(cpu: *Cpu) void {
    x.execDec16(cpu.BC, Register.set, cpu.BC.getHiLo());
    return 2;
}
fn DEC_DE(cpu: *Cpu) void {
    x.execDec16(cpu.DE, Register.set, cpu.DE.getHiLo());
    return 2;
}
fn DEC_HL(cpu: *Cpu) void {
    x.execDec16(cpu.HL, Register.set, cpu.HL.getHiLo());
    return 2;
}
fn DEC_SP(cpu: *Cpu) void {
    x.execDec16(cpu.SP, Register.set, cpu.SP.getHiLo());
    return 2;
}

// 00-r16-1001
fn ADD_HL_BC(cpu: *Cpu) void {
    x.execAdd16(cpu, cpu.HL, Register.set, cpu.HL.getHiLo(), cpu.BC.getHiLo());
    return 2;
}
fn ADD_HL_DE(cpu: *Cpu) void {
    x.execAdd16(cpu, cpu.HL, Register.set, cpu.HL.getHiLo(), cpu.DE.getHiLo());
    return 2;
}
fn ADD_HL_HL(cpu: *Cpu) void {
    x.execAdd16(cpu, cpu.HL, Register.set, cpu.HL.getHiLo(), cpu.HL.getHiLo());
    return 2;
}
fn ADD_HL_SP(cpu: *Cpu) void {
    x.execAdd16(cpu, cpu.HL, Register.set, cpu.HL.getHiLo(), cpu.SP.getHiLo());
    return 2;
}

// 00-r8-100
fn INC_B(cpu: *Cpu) void {
    x.execInc8(cpu.BC, Register.setHi, cpu.BC.getHi());
    return 1;
}
fn INC_C(cpu: *Cpu) void {
    x.execInc8(cpu.BC, Register.setLo, cpu.BC.getLo());
    return 1;
}
fn INC_D(cpu: *Cpu) void {
    x.execInc8(cpu.DE, Register.setHi, cpu.DE.getHi());
    return 1;
}
fn INC_E(cpu: *Cpu) void {
    x.execInc8(cpu.DE, Register.setLo, cpu.DE.getLo());
    return 1;
}
fn INC_H(cpu: *Cpu) void {
    x.execInc8(cpu.HL, Register.setHi, cpu.HL.getHi());
    return 1;
}
fn INC_L(cpu: *Cpu) void {
    x.execInc8(cpu.HL, Register.setLo, cpu.HL.getLo());
    return 1;
}
fn INC_HL_mem(cpu: *Cpu) void {
    const addr: u16 = cpu.HL.getHiLo();
    cpu.mem.write8(addr, cpu.mem.read8(addr) + 1);
    return 3;
}
fn INC_A(cpu: *Cpu) void {
    x.execInc8(cpu.AF, Register.setHi, cpu.AF.getHi());
    return 1;
}

// 00-r8-101
fn DEC_B(cpu: *Cpu) void {
    x.execDec8(cpu.BC, Register.setHi, cpu.BC.getHi());
    return 1;
}
fn DEC_C(cpu: *Cpu) void {
    x.execDec8(cpu.BC, Register.setLo, cpu.BC.getLo());
    return 1;
}
fn DEC_D(cpu: *Cpu) void {
    x.execDec8(cpu.DE, Register.setHi, cpu.DE.getHi());
    return 1;
}
fn DEC_E(cpu: *Cpu) void {
    x.execDec8(cpu.DE, Register.setLo, cpu.DE.getLo());
    return 1;
}
fn DEC_H(cpu: *Cpu) void {
    x.execDec8(cpu.HL, Register.setHi, cpu.HL.getHi());
    return 1;
}
fn DEC_L(cpu: *Cpu) void {
    x.execDec8(cpu.HL, Register.setLo, cpu.HL.getLo());
    return 1;
}
fn DEC_HL_mem(cpu: *Cpu) void {
    const addr: u16 = cpu.HL.getHiLo();
    cpu.mem.write8(addr, cpu.mem.read8(addr) + 1);
    return 3;
}
fn DEC_A(cpu: *Cpu) void {
    x.execDec8(cpu.AF, Register.setHi, cpu.AF.getHi());
    return 1;
}

fn LD_B_n8(cpu: *Cpu) void {
    cpu.BC.setHi(cpu.pc_pop_8());
    return 2;
}
fn LD_C_n8(cpu: *Cpu) void {
    cpu.BC.setLo(cpu.pc_pop_8());
    return 2;
}
fn LD_D_n8(cpu: *Cpu) void {
    cpu.DE.setHi(cpu.pc_pop_8());
    return 2;
}
fn LD_E_n8(cpu: *Cpu) void {
    cpu.DE.setLo(cpu.pc_pop_8());
    return 2;
}
fn LD_H_n8(cpu: *Cpu) void {
    cpu.HL.setHi(cpu.pc_pop_8());
    return 2;
}
fn LD_L_n8(cpu: *Cpu) void {
    cpu.HL.setLo(cpu.pc_pop_8());
    return 2;
}
fn LD_HL_mem_n8(cpu: *Cpu) void {
    const addr: u16 = cpu.HL.getHiLo();
    cpu.mem.write8(addr, cpu.pc_pop_8());
    return 3;
}
fn LD_A_n8(cpu: *Cpu) void {
    cpu.AF.setHi(cpu.pc_pop_8());
    return 2;
}

fn RLCA(cpu: *Cpu) void {
    x.execRotateLeft(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), false);
    return 1;
}
fn RRCA(cpu: *Cpu) void {
    x.execRotateRight(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), false);
    return 1;
}
fn RLA(cpu: *Cpu) void {
    x.execRotateLeft(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), true);
    return 1;
}
fn RRA(cpu: *Cpu) void {
    x.execRotateRight(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), true);
    return 1;
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
    return 1;
}
fn CPL(cpu: *Cpu) void {
    cpu.AF.setHi(~cpu.AF.getHi());
    cpu.set_n(true);
    cpu.set_h(true);
    return 1;
}
fn SCF(cpu: *Cpu) void {
    cpu.set_c(true);
    return 1;
}
fn CCF(cpu: *Cpu) void {
    cpu.set_c(~cpu.get_c() == 1);
    return 1;
}

fn JR_n8(cpu: *Cpu) void {
    const signed_offset: i8 = @bitCast(cpu.pc_pop_8());
    const offset_u16: u16 = @bitCast(@as(i16, signed_offset));
    x.execJump(cpu, cpu.PC.getHiLo() +% offset_u16);
    return 3;
}

fn JR_C0_n8(cpu: *Cpu) void {
    if (cpu.get_z() == 0) JR_n8(cpu) else return 2;
}
fn JR_C1_n8(cpu: *Cpu) void {
    if (cpu.get_z() == 1) JR_n8(cpu) else return 2;
}
fn JR_C2_n8(cpu: *Cpu) void {
    if (cpu.get_c() == 0) JR_n8(cpu) else return 2;
}
fn JR_C3_n8(cpu: *Cpu) void {
    if (cpu.get_c() == 1) JR_n8(cpu) else return 2;
}

fn STOP() void {
    return 1;
}

// --- BLOCK 1 ---
// LD B, r8
fn LD_B_B(cpu: *Cpu) u8 {
    _ = cpu;
    return 1;
}
fn LD_B_C(cpu: *Cpu) u8 {
    cpu.BC.setHi(cpu.BC.getLo());
    return 1;
}
fn LD_B_D(cpu: *Cpu) u8 {
    cpu.BC.setHi(cpu.DE.getHi());
    return 1;
}
fn LD_B_E(cpu: *Cpu) u8 {
    cpu.BC.setHi(cpu.DE.getLo());
    return 1;
}
fn LD_B_H(cpu: *Cpu) u8 {
    cpu.BC.setHi(cpu.HL.getHi());
    return 1;
}
fn LD_B_L(cpu: *Cpu) u8 {
    cpu.BC.setHi(cpu.HL.getLo());
    return 1;
}
fn LD_B_HL(cpu: *Cpu) u8 {
    cpu.BC.setHi(cpu.mem.read8(cpu.HL.getHiLo()));
    return 2;
}
fn LD_B_A(cpu: *Cpu) u8 {
    cpu.BC.setHi(cpu.AF.getHi());
    return 1;
}

// LD C, r8
fn LD_C_B(cpu: *Cpu) u8 {
    cpu.BC.setLo(cpu.BC.getHi());
    return 1;
}
fn LD_C_C(cpu: *Cpu) u8 {
    _ = cpu;
    return 1;
}
fn LD_C_D(cpu: *Cpu) u8 {
    cpu.BC.setLo(cpu.DE.getHi());
    return 1;
}
fn LD_C_E(cpu: *Cpu) u8 {
    cpu.BC.setLo(cpu.DE.getLo());
    return 1;
}
fn LD_C_H(cpu: *Cpu) u8 {
    cpu.BC.setLo(cpu.HL.getHi());
    return 1;
}
fn LD_C_L(cpu: *Cpu) u8 {
    cpu.BC.setLo(cpu.HL.getLo());
    return 1;
}
fn LD_C_HL(cpu: *Cpu) u8 {
    cpu.BC.setLo(cpu.mem.read8(cpu.HL.getHiLo()));
    return 2;
}
fn LD_C_A(cpu: *Cpu) u8 {
    cpu.BC.setLo(cpu.AF.getHi());
    return 1;
}

// LD D, r8
fn LD_D_B(cpu: *Cpu) u8 {
    cpu.DE.setHi(cpu.BC.getHi());
    return 1;
}
fn LD_D_C(cpu: *Cpu) u8 {
    cpu.DE.setHi(cpu.BC.getLo());
    return 1;
}
fn LD_D_D(cpu: *Cpu) u8 {
    _ = cpu;
    return 1;
}
fn LD_D_E(cpu: *Cpu) u8 {
    cpu.DE.setHi(cpu.DE.getLo());
    return 1;
}
fn LD_D_H(cpu: *Cpu) u8 {
    cpu.DE.setHi(cpu.HL.getHi());
    return 1;
}
fn LD_D_L(cpu: *Cpu) u8 {
    cpu.DE.setHi(cpu.HL.getLo());
    return 1;
}
fn LD_D_HL(cpu: *Cpu) u8 {
    cpu.DE.setHi(cpu.mem.read8(cpu.HL.getHiLo()));
    return 2;
}
fn LD_D_A(cpu: *Cpu) u8 {
    cpu.DE.setHi(cpu.AF.getHi());
    return 1;
}

// LD E, r8
fn LD_E_B(cpu: *Cpu) u8 {
    cpu.DE.setLo(cpu.BC.getHi());
    return 1;
}
fn LD_E_C(cpu: *Cpu) u8 {
    cpu.DE.setLo(cpu.BC.getLo());
    return 1;
}
fn LD_E_D(cpu: *Cpu) u8 {
    cpu.DE.setLo(cpu.DE.getHi());
    return 1;
}
fn LD_E_E(cpu: *Cpu) u8 {
    _ = cpu;
    return 1;
}
fn LD_E_H(cpu: *Cpu) u8 {
    cpu.DE.setLo(cpu.HL.getHi());
    return 1;
}
fn LD_E_L(cpu: *Cpu) u8 {
    cpu.DE.setLo(cpu.HL.getLo());
    return 1;
}
fn LD_E_HL(cpu: *Cpu) u8 {
    cpu.DE.setLo(cpu.mem.read8(cpu.HL.getHiLo()));
    return 2;
}
fn LD_E_A(cpu: *Cpu) u8 {
    cpu.DE.setLo(cpu.AF.getHi());
    return 1;
}

// LD H, r8
fn LD_H_B(cpu: *Cpu) u8 {
    cpu.HL.setHi(cpu.BC.getHi());
    return 1;
}
fn LD_H_C(cpu: *Cpu) u8 {
    cpu.HL.setHi(cpu.BC.getLo());
    return 1;
}
fn LD_H_D(cpu: *Cpu) u8 {
    cpu.HL.setHi(cpu.DE.getHi());
    return 1;
}
fn LD_H_E(cpu: *Cpu) u8 {
    cpu.HL.setHi(cpu.DE.getLo());
    return 1;
}
fn LD_H_H(cpu: *Cpu) u8 {
    _ = cpu;
    return 1;
}
fn LD_H_L(cpu: *Cpu) u8 {
    cpu.HL.setHi(cpu.HL.getLo());
    return 1;
}
fn LD_H_HL(cpu: *Cpu) u8 {
    cpu.HL.setHi(cpu.mem.read8(cpu.HL.getHiLo()));
    return 2;
}
fn LD_H_A(cpu: *Cpu) u8 {
    cpu.HL.setHi(cpu.AF.getHi());
    return 1;
}

// LD L, r8
fn LD_L_B(cpu: *Cpu) u8 {
    cpu.HL.setLo(cpu.BC.getHi());
    return 1;
}
fn LD_L_C(cpu: *Cpu) u8 {
    cpu.HL.setLo(cpu.BC.getLo());
    return 1;
}
fn LD_L_D(cpu: *Cpu) u8 {
    cpu.HL.setLo(cpu.DE.getHi());
    return 1;
}
fn LD_L_E(cpu: *Cpu) u8 {
    cpu.HL.setLo(cpu.DE.getLo());
    return 1;
}
fn LD_L_H(cpu: *Cpu) u8 {
    cpu.HL.setLo(cpu.HL.getHi());
    return 1;
}
fn LD_L_L(cpu: *Cpu) u8 {
    _ = cpu;
    return 1;
}
fn LD_L_HL(cpu: *Cpu) u8 {
    cpu.HL.setLo(cpu.mem.read8(cpu.HL.getHiLo()));
    return 2;
}
fn LD_L_A(cpu: *Cpu) u8 {
    cpu.HL.setLo(cpu.AF.getHi());
    return 1;
}

// LD [HL], r8
fn LD_HL_B(cpu: *Cpu) u8 {
    cpu.mem.write8(cpu.HL.getHiLo(), cpu.BC.getHi());
    return 2;
}
fn LD_HL_C(cpu: *Cpu) u8 {
    cpu.mem.write8(cpu.HL.getHiLo(), cpu.BC.getLo());
    return 2;
}
fn LD_HL_D(cpu: *Cpu) u8 {
    cpu.mem.write8(cpu.HL.getHiLo(), cpu.DE.getHi());
    return 2;
}
fn LD_HL_E(cpu: *Cpu) u8 {
    cpu.mem.write8(cpu.HL.getHiLo(), cpu.DE.getLo());
    return 2;
}
fn LD_HL_H(cpu: *Cpu) u8 {
    cpu.mem.write8(cpu.HL.getHiLo(), cpu.HL.getHi());
    return 2;
}
fn LD_HL_L(cpu: *Cpu) u8 {
    cpu.mem.write8(cpu.HL.getHiLo(), cpu.HL.getLo());
    return 2;
}
fn LD_HL_A(cpu: *Cpu) u8 {
    cpu.mem.write8(cpu.HL.getHiLo(), cpu.AF.getHi());
    return 2;
}

// LD A, r8
fn LD_A_B(cpu: *Cpu) u8 {
    cpu.AF.setHi(cpu.BC.getHi());
    return 1;
}
fn LD_A_C(cpu: *Cpu) u8 {
    cpu.AF.setHi(cpu.BC.getLo());
    return 1;
}
fn LD_A_D(cpu: *Cpu) u8 {
    cpu.AF.setHi(cpu.DE.getHi());
    return 1;
}
fn LD_A_E(cpu: *Cpu) u8 {
    cpu.AF.setHi(cpu.DE.getLo());
    return 1;
}
fn LD_A_H(cpu: *Cpu) u8 {
    cpu.AF.setHi(cpu.HL.getHi());
    return 1;
}
fn LD_A_L(cpu: *Cpu) u8 {
    cpu.AF.setHi(cpu.HL.getLo());
    return 1;
}
fn LD_A_HL(cpu: *Cpu) u8 {
    cpu.AF.setHi(cpu.mem.read8(cpu.HL.getHiLo()));
    return 2;
}
fn LD_A_A(cpu: *Cpu) u8 {
    _ = cpu;
    return 1;
}

fn ADD_A_B(cpu: *Cpu) u8 {
    x.execAdd8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.BC.getHi(), false);
    return 1;
}
fn ADD_A_C(cpu: *Cpu) u8 {
    x.execAdd8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.BC.getLo(), false);
    return 1;
}
fn ADD_A_D(cpu: *Cpu) u8 {
    x.execAdd8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.DE.getHi(), false);
    return 1;
}
fn ADD_A_E(cpu: *Cpu) u8 {
    x.execAdd8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.DE.getLo(), false);
    return 1;
}
fn ADD_A_H(cpu: *Cpu) u8 {
    x.execAdd8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.HL.getHi(), false);
    return 1;
}
fn ADD_A_L(cpu: *Cpu) u8 {
    x.execAdd8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.HL.getLo(), false);
    return 1;
}
fn ADD_A_HL(cpu: *Cpu) u8 {
    x.execAdd8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.mem.read8(cpu.HL.getHiLo()), false);
    return 2;
}
fn ADD_A_A(cpu: *Cpu) u8 {
    x.execAdd8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.AF.getHi(), false);
    return 1;
}

// ADC
fn ADC_A_B(cpu: *Cpu) u8 {
    x.execAdd8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.BC.getHi(), true);
    return 1;
}
fn ADC_A_C(cpu: *Cpu) u8 {
    x.execAdd8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.BC.getLo(), true);
    return 1;
}
fn ADC_A_D(cpu: *Cpu) u8 {
    x.execAdd8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.DE.getHi(), true);
    return 1;
}
fn ADC_A_E(cpu: *Cpu) u8 {
    x.execAdd8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.DE.getLo(), true);
    return 1;
}
fn ADC_A_H(cpu: *Cpu) u8 {
    x.execAdd8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.HL.getHi(), true);
    return 1;
}
fn ADC_A_L(cpu: *Cpu) u8 {
    x.execAdd8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.HL.getLo(), true);
    return 1;
}
fn ADC_A_HL(cpu: *Cpu) u8 {
    x.execAdd8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.mem.read8(cpu.HL.getHiLo()), true);
    return 2;
}
fn ADC_A_A(cpu: *Cpu) u8 {
    x.execAdd8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.AF.getHi(), true);
    return 1;
}

fn SUB_A_B(cpu: *Cpu) u8 {
    x.execSub8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.BC.getHi(), false);
    return 1;
}
fn SUB_A_C(cpu: *Cpu) u8 {
    x.execSub8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.BC.getLo(), false);
    return 1;
}
fn SUB_A_D(cpu: *Cpu) u8 {
    x.execSub8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.DE.getHi(), false);
    return 1;
}
fn SUB_A_E(cpu: *Cpu) u8 {
    x.execSub8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.DE.getLo(), false);
    return 1;
}
fn SUB_A_H(cpu: *Cpu) u8 {
    x.execSub8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.HL.getHi(), false);
    return 1;
}
fn SUB_A_L(cpu: *Cpu) u8 {
    x.execSub8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.HL.getLo(), false);
    return 1;
}
fn SUB_A_HL(cpu: *Cpu) u8 {
    x.execSub8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.mem.read8(cpu.HL.getHiLo()), false);
    return 2;
}
fn SUB_A_A(cpu: *Cpu) u8 {
    x.execSub8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.AF.getHi(), false);
    return 1;
}

// SBC
fn SBC_A_B(cpu: *Cpu) u8 {
    x.execSub8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.BC.getHi(), true);
    return 1;
}
fn SBC_A_C(cpu: *Cpu) u8 {
    x.execSub8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.BC.getLo(), true);
    return 1;
}
fn SBC_A_D(cpu: *Cpu) u8 {
    x.execSub8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.DE.getHi(), true);
    return 1;
}
fn SBC_A_E(cpu: *Cpu) u8 {
    x.execSub8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.DE.getLo(), true);
    return 1;
}
fn SBC_A_H(cpu: *Cpu) u8 {
    x.execSub8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.HL.getHi(), true);
    return 1;
}
fn SBC_A_L(cpu: *Cpu) u8 {
    x.execSub8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.HL.getLo(), true);
    return 1;
}
fn SBC_A_HL(cpu: *Cpu) u8 {
    x.execSub8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.mem.read8(cpu.HL.getHiLo()), true);
    return 2;
}
fn SBC_A_A(cpu: *Cpu) u8 {
    x.execSub8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.AF.getHi(), true);
    return 1;
}

// AND
fn AND_A_B(cpu: *Cpu) u8 {
    x.execAnd(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.BC.getHi());
    return 1;
}
fn AND_A_C(cpu: *Cpu) u8 {
    x.execAnd(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.BC.getLo());
    return 1;
}
fn AND_A_D(cpu: *Cpu) u8 {
    x.execAnd(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.DE.getHi());
    return 1;
}
fn AND_A_E(cpu: *Cpu) u8 {
    x.execAnd(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.DE.getLo());
    return 1;
}
fn AND_A_H(cpu: *Cpu) u8 {
    x.execAnd(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.HL.getHi());
    return 1;
}
fn AND_A_L(cpu: *Cpu) u8 {
    x.execAnd(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.HL.getLo());
    return 1;
}
fn AND_A_HL(cpu: *Cpu) u8 {
    x.execAnd(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.mem.read8(cpu.HL.getHiLo()));
    return 2;
}
fn AND_A_A(cpu: *Cpu) u8 {
    x.execAnd(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.AF.getHi());
    return 1;
}

// XOR
fn XOR_A_B(cpu: *Cpu) u8 {
    x.execXor(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.BC.getHi());
    return 1;
}
fn XOR_A_C(cpu: *Cpu) u8 {
    x.execXor(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.BC.getLo());
    return 1;
}
fn XOR_A_D(cpu: *Cpu) u8 {
    x.execXor(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.DE.getHi());
    return 1;
}
fn XOR_A_E(cpu: *Cpu) u8 {
    x.execXor(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.DE.getLo());
    return 1;
}
fn XOR_A_H(cpu: *Cpu) u8 {
    x.execXor(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.HL.getHi());
    return 1;
}
fn XOR_A_L(cpu: *Cpu) u8 {
    x.execXor(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.HL.getLo());
    return 1;
}
fn XOR_A_HL(cpu: *Cpu) u8 {
    x.execXor(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.mem.read8(cpu.HL.getHiLo()));
    return 2;
}
fn XOR_A_A(cpu: *Cpu) u8 {
    x.execXor(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.AF.getHi());
    return 1;
}

// OR
fn OR_A_B(cpu: *Cpu) u8 {
    x.execOr(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.BC.getHi());
    return 1;
}
fn OR_A_C(cpu: *Cpu) u8 {
    x.execOr(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.BC.getLo());
    return 1;
}
fn OR_A_D(cpu: *Cpu) u8 {
    x.execOr(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.DE.getHi());
    return 1;
}
fn OR_A_E(cpu: *Cpu) u8 {
    x.execOr(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.DE.getLo());
    return 1;
}
fn OR_A_H(cpu: *Cpu) u8 {
    x.execOr(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.HL.getHi());
    return 1;
}
fn OR_A_L(cpu: *Cpu) u8 {
    x.execOr(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.HL.getLo());
    return 1;
}
fn OR_A_HL(cpu: *Cpu) u8 {
    x.execOr(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.mem.read8(cpu.HL.getHiLo()));
    return 2;
}
fn OR_A_A(cpu: *Cpu) u8 {
    x.execOr(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.AF.getHi());
    return 1;
}

// CP
fn CP_A_B(cpu: *Cpu) u8 {
    x.execCp(cpu, cpu.AF.getHi(), cpu.BC.getHi());
    return 1;
}
fn CP_A_C(cpu: *Cpu) u8 {
    x.execCp(cpu, cpu.AF.getHi(), cpu.BC.getLo());
    return 1;
}
fn CP_A_D(cpu: *Cpu) u8 {
    x.execCp(cpu, cpu.AF.getHi(), cpu.DE.getHi());
    return 1;
}
fn CP_A_E(cpu: *Cpu) u8 {
    x.execCp(cpu, cpu.AF.getHi(), cpu.DE.getLo());
    return 1;
}
fn CP_A_H(cpu: *Cpu) u8 {
    x.execCp(cpu, cpu.AF.getHi(), cpu.HL.getHi());
    return 1;
}
fn CP_A_L(cpu: *Cpu) u8 {
    x.execCp(cpu, cpu.AF.getHi(), cpu.HL.getLo());
    return 1;
}
fn CP_A_HL(cpu: *Cpu) u8 {
    x.execCp(cpu, cpu.AF.getHi(), cpu.mem.read8(cpu.HL.getHiLo()));
    return 2;
}
fn CP_A_A(cpu: *Cpu) u8 {
    x.execCp(cpu, cpu.AF.getHi(), cpu.AF.getHi());
    return 1;
}

fn ADD_A_n8(cpu: *Cpu) u8 {
    x.execAdd8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.pc_pop_8(), false);
}

fn ADC_A_n8(cpu: *Cpu) u8 {
    x.execAdd8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.pc_pop_8(), true);
}

fn SUB_A_n8(cpu: *Cpu) u8 {
    x.execSub8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.pc_pop_8(), false);
}

fn SBC_A_n8(cpu: *Cpu) u8 {
    x.execSub8(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.pc_pop_8(), true);
}

fn AND_A_n8(cpu: *Cpu) u8 {
    x.execAnd(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.pc_pop_8());
}

fn XOR_A_n8(cpu: *Cpu) u8 {
    x.execXor(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.pc_pop_8());
}

fn OR_A_n8(cpu: *Cpu) u8 {
    x.execOr(cpu, cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.pc_pop_8());
}

fn CP_A_n8(cpu: *Cpu) u8 {
    x.execCp(cpu, cpu.AF.getHi(), cpu.pc_pop_8());
}
