const Cpu = @import("cpu.zig").Cpu;
const Register = @import("register.zig").Register;
const Bus = @import("../bus.zig").Bus;
const x = @import("functions.zig");
const helpers = @import("helpers.zig");
const CB_PREFIX = @import("./CB.zig").CB_PREFIX;

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

        0x40...0x45,
        0x47...0x4D,
        0x4F...0x55,
        0x57...0x5D,
        0x5F...0x65,
        0x67...0x6D,
        0x6F,
        0x78...0x7D,
        0x7F,
        => LD_r8_r8(cpu, instruction),

        // BLOCK 2
        0x86 => ADD_A_HL(cpu),
        0x80...0x85, 0x87 => ADD_A_r8(cpu, instruction),
        0x8E => ADC_A_HL(cpu),
        0x88...0x8D, 0x8F => ADC_A_r8(cpu, instruction),
        0x96 => SUB_A_HL(cpu),
        0x90...0x95, 0x97 => SUB_A_r8(cpu, instruction),
        0x9E => SBC_A_HL(cpu),
        0x98...0x9D, 0x9F => SBC_A_r8(cpu, instruction),
        0xA6 => AND_A_HL(cpu),
        0xA0...0xA5, 0xA7 => AND_A_r8(cpu, instruction),
        0xAE => XOR_A_HL(cpu),
        0xA8...0xAD, 0xAF => XOR_A_r8(cpu, instruction),
        0xB6 => OR_A_HL(cpu),
        0xB0...0xB5, 0xB7 => OR_A_r8(cpu, instruction),
        0xBE => CP_A_HL(cpu),
        0xB8...0xBD, 0xBF => CP_A_r8(cpu, instruction),

        // BLOCK 3
        0xC6 => ADD_A_n8(cpu),
        0xCE => ADC_A_n8(cpu),
        0xD6 => SUB_A_n8(cpu),
        0xDE => SBC_A_n8(cpu),
        0xE6 => AND_A_n8(cpu),
        0xEE => XOR_A_n8(cpu),
        0xF6 => OR_A_n8(cpu),
        0xFE => CP_A_n8(cpu),

        0xC0, 0xC8, 0xD0, 0xD8 => RET_cond(cpu, instruction),
        0xC9 => RET(cpu),
        0xD9 => RETI(cpu),

        0xC2, 0xCA, 0xD2, 0xDA => JP_cond_n16(cpu, instruction),
        0xC3 => JP_n16(cpu),
        0xE9 => JP_HL(cpu),

        0xC4, 0xCC, 0xD4, 0xDC => CALL_cond_n16(cpu, instruction),
        0xCD => CALL_n16(cpu),

        0xC7, 0xCF, 0xD7, 0xDF, 0xE7, 0xEF, 0xF7, 0xFF => RST(cpu, instruction),

        0xC1, 0xD1, 0xE1, 0xF1 => POP_r16stk(cpu, instruction),
        0xC5, 0xD5, 0xE5, 0xF5 => PUSH_r16stk(cpu, instruction),

        0xCB => CB_PREFIX(cpu),

        0xE2 => LDH_C_A(cpu),
        0xE0 => LDH_n8_A(cpu),
        0xEA => LD_n16_A(cpu),
        0xF2 => LDH_A_C(cpu),
        0xF0 => LDH_A_n8(cpu),
        0xFA => LD_A_n16(cpu),

        0xE8 => ADD_SP_n8(cpu),
        0xF8 => LD_HL_SP_n8(cpu),
        0xF9 => LD_SP_HL(cpu),

        0xF3 => DI(cpu),
        0xFB => EI(cpu),

        else => 0x00,
    };
}

fn NOP(cpu: *Cpu) u8 {
    _ = cpu;
    return 1;
}

fn LD_r16_n16(cpu: *Cpu, opcode: u8) u8 {
    const r = helpers.get_r16(cpu, @truncate(opcode >> 4));
    r.set(cpu.pc_pop_16());
    return 3;
}

fn LD_r16_A(cpu: *Cpu, opcode: u8) u8 {
    const r = helpers.get_r16(cpu, @truncate(opcode >> 4));
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
    const r = helpers.get_r16mem(cpu, @truncate(opcode >> 4));
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
    const r = helpers.get_r16(cpu, @truncate(opcode >> 4));
    x.execInc16(r, Register.set, r.getHiLo());
    return 2;
}

fn DEC_r16(cpu: *Cpu, opcode: u8) u8 {
    const r = helpers.get_r16(cpu, @truncate(opcode >> 4));
    x.execDec16(r, Register.set, r.getHiLo());
    return 2;
}

fn ADD_HL_r16(cpu: *Cpu, opcode: u8) u8 {
    const r = helpers.get_r16(cpu, @truncate(opcode >> 4));
    x.execAdd16(cpu, r, Register.set, cpu.HL.getHiLo(), r.getHiLo());
    return 2;
}

fn LD_r8_n8(cpu: *Cpu, opcode: u8) u8 {
    const r = helpers.get_r8(cpu, @truncate(opcode >> 3));
    r.set(r.reg, cpu.pc_pop_8());
    return 2;
}

fn LD_HL_mem_n8(cpu: *Cpu) u8 {
    const addr: u16 = cpu.HL.getHiLo();
    cpu.mem.write8(addr, cpu.pc_pop_8());
    return 3;
}

fn INC_r8(cpu: *Cpu, opcode: u8) u8 {
    const r = helpers.get_r8(cpu, @truncate(opcode >> 3));
    x.execInc8(r.reg, r.set, r.get(r.reg));
    return 1;
}

fn INC_HL_mem(cpu: *Cpu) u8 {
    const addr: u16 = cpu.HL.getHiLo();
    cpu.mem.write8(addr, cpu.mem.read8(addr) + 1);
    return 3;
}

fn DEC_r8(cpu: *Cpu, opcode: u8) u8 {
    const r = helpers.get_r8(cpu, @truncate(opcode >> 3));
    x.execDec8(r.reg, r.set, r.get(r.reg));
    return 1;
}

fn DEC_HL_mem(cpu: *Cpu) u8 {
    const addr: u16 = cpu.HL.getHiLo();
    cpu.mem.write8(addr, cpu.mem.read8(addr) - 1);
    return 3;
}

fn RLCA(cpu: *Cpu) u8 {
    x.execRotateLeft(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), false);
    return 1;
}
fn RRCA(cpu: *Cpu) u8 {
    x.execRotateRight(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), false);
    return 1;
}
fn RLA(cpu: *Cpu) u8 {
    x.execRotateLeft(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), true);
    return 1;
}
fn RRA(cpu: *Cpu) u8 {
    x.execRotateRight(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), true);
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
    const r_d = helpers.get_r8(cpu, @truncate(opcode >> 3));
    const r_s = helpers.get_r8(cpu, @truncate(opcode));
    r_d.set(r_d.reg, r_s.get(r_s.reg));
    return 1;
}

fn LD_r8_HL(cpu: *Cpu, opcode: u8) u8 {
    const r_d = helpers.get_r8(cpu, @truncate(opcode >> 3));
    r_d.set(r_d.reg, cpu.mem.read8(cpu.HL.getHiLo()));
    return 2;
}

fn LD_HL_r8(cpu: *Cpu, opcode: u8) u8 {
    const r_s = helpers.get_r8(cpu, @truncate(opcode));
    cpu.mem.write8(cpu.HL.getHiLo(), r_s.get(r_s.reg));
    return 2;
}
// cpu: *Cpu
fn HALT() u8 {
    // cpu.halted = true;
    return 1;
}

// ------ BLOCK 2 ------
fn ADD_A_HL(cpu: *Cpu) u8 {
    x.execAdd8(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.mem.read8(cpu.HL.getHiLo()), false);
    return 2;
}
fn ADD_A_r8(cpu: *Cpu, opcode: u8) u8 {
    const r = helpers.get_r8(cpu, @truncate(opcode));
    x.execAdd8(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), r.get(r.reg), false);
    return 1;
}
fn ADC_A_HL(cpu: *Cpu) u8 {
    x.execAdd8(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.mem.read8(cpu.HL.getHiLo()), true);
    return 2;
}
fn ADC_A_r8(cpu: *Cpu, opcode: u8) u8 {
    const r = helpers.get_r8(cpu, @truncate(opcode));
    x.execAdd8(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), r.get(r.reg), true);
    return 1;
}
fn SUB_A_HL(cpu: *Cpu) u8 {
    x.execSub8(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.mem.read8(cpu.HL.getHiLo()), false);
    return 2;
}
fn SUB_A_r8(cpu: *Cpu, opcode: u8) u8 {
    const r = helpers.get_r8(cpu, @truncate(opcode));
    x.execSub8(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), r.get(r.reg), false);
    return 1;
}
fn SBC_A_HL(cpu: *Cpu) u8 {
    x.execSub8(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.mem.read8(cpu.HL.getHiLo()), true);
    return 2;
}
fn SBC_A_r8(cpu: *Cpu, opcode: u8) u8 {
    const r = helpers.get_r8(cpu, @truncate(opcode));
    x.execSub8(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), r.get(r.reg), true);
    return 1;
}
fn AND_A_HL(cpu: *Cpu) u8 {
    x.execAnd(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.mem.read8(cpu.HL.getHiLo()));
    return 2;
}
fn AND_A_r8(cpu: *Cpu, opcode: u8) u8 {
    const r = helpers.get_r8(cpu, @truncate(opcode));
    x.execAnd(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), r.get(r.reg));
    return 1;
}
fn XOR_A_HL(cpu: *Cpu) u8 {
    x.execXor(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.mem.read8(cpu.HL.getHiLo()));
    return 2;
}
fn XOR_A_r8(cpu: *Cpu, opcode: u8) u8 {
    const r = helpers.get_r8(cpu, @truncate(opcode));
    x.execXor(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), r.get(r.reg));
    return 1;
}
fn OR_A_HL(cpu: *Cpu) u8 {
    x.execOr(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.mem.read8(cpu.HL.getHiLo()));
    return 2;
}
fn OR_A_r8(cpu: *Cpu, opcode: u8) u8 {
    const r = helpers.get_r8(cpu, @truncate(opcode));
    x.execOr(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), r.get(r.reg));
    return 1;
}
fn CP_A_HL(cpu: *Cpu) u8 {
    x.execCp(cpu, cpu.AF.getHi(), cpu.mem.read8(cpu.HL.getHiLo()));
    return 2;
}
fn CP_A_r8(cpu: *Cpu, opcode: u8) u8 {
    const r = helpers.get_r8(cpu, @truncate(opcode));
    x.execCp(cpu, cpu.AF.getHi(), r.get(r.reg));
    return 1;
}

// ----- BLOCK 3 -----
fn ADD_A_n8(cpu: *Cpu) u8 {
    x.execAdd8(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.pc_pop_8(), false);
    return 2;
}

fn ADC_A_n8(cpu: *Cpu) u8 {
    x.execAdd8(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.pc_pop_8(), true);
    return 2;
}

fn SUB_A_n8(cpu: *Cpu) u8 {
    x.execSub8(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.pc_pop_8(), false);
    return 2;
}

fn SBC_A_n8(cpu: *Cpu) u8 {
    x.execSub8(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.pc_pop_8(), true);
    return 2;
}

fn AND_A_n8(cpu: *Cpu) u8 {
    x.execAnd(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.pc_pop_8());
    return 2;
}

fn XOR_A_n8(cpu: *Cpu) u8 {
    x.execXor(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.pc_pop_8());
    return 2;
}

fn OR_A_n8(cpu: *Cpu) u8 {
    x.execOr(cpu, &cpu.AF, Register.setHi, cpu.AF.getHi(), cpu.pc_pop_8());
    return 2;
}

fn CP_A_n8(cpu: *Cpu) u8 {
    x.execCp(cpu, cpu.AF.getHi(), cpu.pc_pop_8());
    return 2;
}

fn RET_cond(cpu: *Cpu, opcode: u8) u8 {
    if (helpers.check_condition(cpu, @truncate(opcode >> 3))) {
        x.execRet(cpu);
        return 5;
    } else {
        return 2;
    }
}

fn RET(cpu: *Cpu) u8 {
    x.execRet(cpu);
    return 4;
}

fn RETI(cpu: *Cpu) u8 {
    x.execRet(cpu);
    cpu.IME = true;
    return 4;
}

fn JP_cond_n16(cpu: *Cpu, opcode: u8) u8 {
    const addr = cpu.pc_pop_16();
    if (helpers.check_condition(cpu, @truncate(opcode >> 3))) {
        x.execJump(cpu, addr);
        return 4;
    } else {
        return 3;
    }
}

fn JP_n16(cpu: *Cpu) u8 {
    x.execJump(cpu, cpu.pc_pop_16());
    return 4;
}

fn JP_HL(cpu: *Cpu) u8 {
    x.execJump(cpu, cpu.HL.getHiLo());
    return 1;
}

fn CALL_cond_n16(cpu: *Cpu, opcode: u8) u8 {
    const addr = cpu.pc_pop_16();
    if (helpers.check_condition(cpu, @truncate(opcode >> 3))) {
        x.execCall(cpu, addr);
        return 6;
    } else {
        return 3;
    }
}

fn CALL_n16(cpu: *Cpu) u8 {
    x.execCall(cpu, cpu.pc_pop_16());
    return 6;
}

fn RST(cpu: *Cpu, instruction: u8) u8 {
    const val: u8 = instruction & 0x38;
    x.execCall(cpu, val);
    return 4;
}

fn POP_r16stk(cpu: *Cpu, instruction: u8) u8 {
    const r = helpers.get_r16stk(cpu, @truncate(instruction >> 4));
    r.set(cpu.sp_pop_16());
    return 3;
}

fn PUSH_r16stk(cpu: *Cpu, instruction: u8) u8 {
    const r = helpers.get_r16stk(cpu, @truncate(instruction >> 4));
    cpu.sp_push_16(r.getHiLo());
    return 4;
}

fn LDH_n8_A(cpu: *Cpu) u8 {
    const addr: u16 = 0xFF00 | @as(u16, cpu.pc_pop_8());
    cpu.mem.write8(addr, cpu.AF.getHi());
    return 3;
}

fn LDH_C_A(cpu: *Cpu) u8 {
    const addr: u16 = 0xFF00 | @as(u16, cpu.BC.getLo());
    cpu.mem.write8(addr, cpu.AF.getHi());
    return 2;
}

fn LD_n16_A(cpu: *Cpu) u8 {
    cpu.mem.write8(cpu.pc_pop_16(), cpu.AF.getHi());
    return 4;
}

fn LDH_A_C(cpu: *Cpu) u8 {
    const addr: u16 = 0xFF00 | @as(u16, cpu.BC.getLo());
    cpu.AF.setHi(cpu.mem.read8(addr));
    return 2;
}

fn LDH_A_n8(cpu: *Cpu) u8 {
    const val: u8 = cpu.mem.read8(@as(u16, cpu.pc_pop_8()) | 0xFF00);
    cpu.AF.setHi(val);
    return 3;
}

fn LD_A_n16(cpu: *Cpu) u8 {
    cpu.AF.setHi(cpu.mem.read8(cpu.pc_pop_16()));
    return 4;
}

fn ADD_SP_n8(cpu: *Cpu) u8 {
    const offset: i8 = @bitCast(cpu.pc_pop_8());
    x.execAdd16Signed(cpu, &cpu.SP, Register.set, cpu.SP.getHiLo(), @as(i16, offset));
    return 4;
}

fn LD_HL_SP_n8(cpu: *Cpu) u8 {
    const offset: i8 = @bitCast(cpu.pc_pop_8());
    x.execAdd16Signed(cpu, &cpu.HL, Register.set, cpu.SP.getHiLo(), @as(i16, offset));
    return 3;
}

fn LD_SP_HL(cpu: *Cpu) u8 {
    cpu.SP.set(cpu.HL.getHiLo());
    return 2;
}

// change to after following instruction
pub fn EI(cpu: *Cpu) u8 {
    cpu.IME = true;
    return 1;
}

pub fn DI(cpu: *Cpu) u8 {
    cpu.IME = false;
    return 1;
}
