const x_ld = @import("./execute/execute_load.zig");
const x_ar = @import("./execute/execute_arithmetic.zig");
const x_bs = @import("./execute/execute_bit_shift.zig");
const x_bl = @import("./execute/execute_bitwise_logic.zig");
const x_cf = @import("./execute/execute_carry_flag.zig");
const x_js = @import("./execute/execute_jump_subroutine.zig");
const Register = @import("./register.zig");
const d_ld = @import("./decode/decode_load.zig");
const d_ar = @import("./decode/decode_arithmetic.zig");
const d_bs = @import("./decode/decode_bit_shift.zig");
const d_bl = @import("./decode/decode_bitwise_logic.zig");

pub const Cpu = struct {
    AF: Register,
    BC: Register,
    DE: Register,
    HL: Register,
    SP: Register,
    PC: Register,
    IME: bool,

    pub fn init() Cpu {
        return Cpu{
            .AF = Register.init(0),
            .BC = Register.init(0),
            .DE = Register.init(0),
            .HL = Register.init(0),
            .SP = Register.init(0),
            .PC = Register.init(0),
            .IME = false,
        };
    }

    pub fn fetch(self: *Cpu) u8 {
        return self.pc_pop_8();
    }

    pub fn decode_execute(self: *Cpu, instruction: u8) void {
        switch (instruction & 0xC0) {
            0x00 => self.decode_block_0(instruction),
            0x40 => self.decode_block_1(instruction),
            0x80 => self.decode_block_2(instruction),
            0xC0 => self.decode_block_3(instruction),
        }
    }

    pub fn decode_block_0(self: *Cpu, instruction: u8) void {
        const opcode: u4 = @truncate(instruction);
        const bits_4_5: u2 = @truncate(instruction >> 4);
        const bits_3_5: u3 = @truncate(instruction >> 3);

        switch (opcode) {
            0x0 => if (bits_4_5 >= 2) x_js.execute_JR_cc_n16(self, bits_3_5, self.pc_pop_8()),
            0x1 => d_ld.decode_LD_r16_n16(self, bits_4_5),
            0x2 => d_ld.decode_LD_r16_A(self, bits_4_5),
            0xA => d_ld.decode_LD_A_r16(self, bits_4_5),
            0x8 => switch (bits_4_5) {
                0x00 => d_ld.decode_LD_n16_SP(self, bits_4_5),
                0x01 => x_js.execute_JR_n16(self, self.pc_pop_8()),
                0x02, 0x03 => x_js.execute_JP_cc_n16(self, bits_3_5, self.pc_pop_8()),
            },
            0x3 => d_ar.decode_INC_r16(self, bits_4_5),
            0xB => d_ar.decode_DEC_r16(self, bits_4_5),
            0x9 => d_ar.decode_ADD_HL_r16(self, bits_4_5),
            0x4, 0xC => d_ar.decode_INC_r8(self, bits_3_5),
            0x5, 0xD => d_ar.decode_DEC_r8(self, bits_3_5),
            0x6, 0xE => d_ld.decode_LD_r8_n8(self, bits_3_5),
            0x7, 0xF => switch (bits_3_5) {
                0x0 => x_bs.execute_RLCA(self),
                0x1 => x_bs.execute_RRCA(self),
                0x2 => x_bs.execute_RLA(self),
                0x3 => x_bs.execute_RRA(self),
                0x4 => {},
                0x5 => x_bl.execute_CPL(self),
                0x6 => x_cf.execute_SCF(self),
                0x7 => x_cf.execute_CCF(self),
            },
        }
    }

    pub fn decode_block_1(self: *Cpu, instruction: u8) void {
        const bits_3_5: u3 = @truncate(instruction >> 3);
        const bits_0_2: u3 = @truncate(instruction);
        d_ld.decode_LD_r8_r8(self, bits_0_2, bits_3_5);
    }

    pub fn decode_block_2(self: *Cpu, instruction: u8) void {
        const operand: u3 = @truncate(instruction);
        const opcode: u3 = @truncate(instruction >> 3);
        switch (opcode) {
            0x0 => d_ar.decode_ADD_A_r8(self, operand),
            0x1 => d_ar.decode_ADC_A_r8(self, operand),
            0x2 => d_ar.decode_SUB_A_r8(self, operand),
            0x3 => d_ar.decode_SBC_A_r8(self, operand),
            0x4 => d_bl.decode_AND_A_r8(self, operand),
            0x5 => d_bl.decode_XOR_A_r8(self, operand),
            0x6 => d_bl.decode_OR_A_r8(self, operand),
            0x7 => d_ar.decode_CP_A_r8(self, operand),
        }
    }

    fn decode_block_3(self: *Cpu, instruction: u8) void {
        const opcode: u6 = @truncate(instruction);
        const bits_3_4: u2 = @truncate(instruction >> 3);
        const bits_3_5: u3 = @truncate(instruction >> 3);
        switch (opcode) {
            0x06 => x_ar.execute_ADD_A_n8(self, self.pc_pop_8()),
            0x0E => x_ar.execute_ADC_A_n8(self, self.pc_pop_8()),
            0x16 => x_ar.execute_SUB_A_n8(self, self.pc_pop_8()),
            0x1E => x_ar.execute_SBC_A_n8(self, self.pc_pop_8()),
            0x26 => x_bl.execute_AND_n8(self, self.pc_pop_8()),
            0x2E => x_bl.execute_XOR_A_n8(self, self.pc_pop_8()),
            0x36 => x_bl.execute_OR_A_n8(self, self.pc_pop_8()),
            0x3E => x_ar.execute_CP_A_n8(self, self.pc_pop_8()),

            0x00, 0x08, 0x10, 0x18 => x_js.execute_RET_cc(self, bits_3_4),
            0x09 => x_js.execute_RET(self),
            0x19 => x_js.execute_RETI(self),
            0x02, 0x0A, 0x12, 0x1A => x_js.execute_JP_cc_n16(self, bits_3_4, self.pc_pop_16()),
            0x03 => x_js.execute_CALL_n16(self, self.pc_pop_16()),
            0x29 => x_js.execute_JP_HL(self),
            0x04, 0x0C, 0x14, 0x1C => x_js.execute_CALL_cc_n16(self, bits_3_4, self.pc_pop_16()),
            0x0D => x_js.execute_CALL_n16(self, self.pc_pop_16()),
            0x07, 0x0F, 0x17, 0x1F, 0x27, 0x2F, 0x37, 0x3F => x_js.execute_RST_vec(self, bits_3_5 << 3),
        }
    }

    pub fn pc_pop_16(self: *Cpu) u16 {
        const b1: u8 = self.mem.read8(self.PC.getHiLo());
        self.PC.inc();
        const b2: u8 = self.mem.read8(self.PC.getHiLo());
        self.PC.Inc();
        return b2 << 8 | b1;
    }

    pub fn pc_pop_8(self: *Cpu) u8 {
        const b: u8 = self.mem.read8(self.PC.getHiLo());
        self.PC.inc();
        return b;
    }

    pub fn sp_pop_16(self: *Cpu) u16 {
        const b1: u8 = self.mem.read8(self.SP.getHiLo());
        self.SP.inc();
        const b2: u8 = self.mem.read8(self.SP.getHiLo());
        self.SP.Inc();
        return b2 << 8 | b1;
    }

    pub fn sp_push_16(self: *Cpu, val: u16) void {
        self.SP.dec();
        self.mem.write8(self.SP.getHiLo(), @truncate(val >> 8));
        self.SP.dec();
        self.mem.write8(self.SP.getHiLo(), @truncate(val));
    }

    pub fn set_c(self: *Cpu, flag: bool) void {
        const current: u8 = self.AF.getLo();
        if (flag) {
            self.AF.setLo(current | 0x10);
        } else {
            self.AF.setLo(current & ~@as(u8, 0x10));
        }
    }

    pub fn set_h(self: *Cpu, flag: bool) void {
        const current: u8 = self.AF.getLo();
        if (flag) {
            self.AF.setLo(current | 0x20);
        } else {
            self.AF.setLo(current & ~@as(u8, 0x20));
        }
    }

    pub fn set_n(self: *Cpu, flag: bool) void {
        const current: u8 = self.AF.getLo();
        if (flag) {
            self.AF.setLo(current | 0x40);
        } else {
            self.AF.setLo(current & ~@as(u8, 0x40));
        }
    }

    pub fn set_z(self: *Cpu, flag: bool) void {
        const current: u8 = self.AF.getLo();
        if (flag) {
            self.AF.setLo(current | 0x80);
        } else {
            self.AF.setLo(current & ~@as(u8, 0x80));
        }
    }

    pub fn get_c(self: *Cpu) u1 {
        return @truncate((self.AF.getLo() & 0x10) >> 4);
    }

    pub fn get_h(self: *Cpu) u1 {
        return @truncate((self.AF.getLo() & 0x20) >> 5);
    }

    pub fn get_n(self: *Cpu) u1 {
        return @truncate((self.AF.getLo() & 0x40) >> 6);
    }

    pub fn get_z(self: *Cpu) u1 {
        return @truncate((self.AF.getLo() & 0x80) >> 7);
    }
};
