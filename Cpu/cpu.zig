const x_ld = @import("./execute/execute_load.zig");
const x_ar = @import("./execute/execute_arithmetic.zig");
const x_bs = @import("./execute/execute_bit_shift.zig");
const x_cf = @import("./execute/execute_carry_flag.zig");
const Register = @import("./register.zig");
const d_ld = @import("./decode/decode_load.zig");
const d_ar = @import("./decode/decode_arithmetic.zig");
const d_bs = @import("./decode/decode_bit_shift.zig");

pub const Cpu = struct {
    AF: Register,
    BC: Register,
    DE: Register,
    HL: Register,
    SP: Register,
    PC: Register,

    pub fn init() Cpu {
        return Cpu{
            .AF = Register.init(0),
            .BC = Register.init(0),
            .DE = Register.init(0),
            .HL = Register.init(0),
            .SP = Register.init(0),
            .PC = Register.init(0),
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
        const bits_3_4_5: u3 = @truncate(instruction >> 3);
        switch (opcode) {
            0x0 => {}, // nop / jr cond imm8
            0x1 => d_ld.decode_LD_r16_n16(self, bits_4_5),
            0x2 => d_ld.decode_LD_r16_A(self, bits_4_5),
            0xA => d_ld.decode_LD_A_r16(self, bits_4_5),
            0x8 => {
                switch (bits_4_5) {
                    0x00 => d_ld.decode_LD_n16_SP(self, bits_4_5),
                    0x01 => {}, // jr imm8
                    0x02, 0x03 => {}, // jr cond imm8
                }
            },
            0x3 => d_ar.decode_INC_r16(self, bits_4_5),
            0xB => d_ar.decode_DEC_r16(self, bits_4_5),
            0x9 => d_ar.decode_ADD_HL_r16(self, bits_4_5),
            0x4, 0xC => d_ar.decode_INC_r8(self, bits_3_4_5),
            0x5, 0xD => d_ar.decode_DEC_r8(self, bits_3_4_5),
            0x6, 0xE => d_ld.decode_LD_r8_n8(self, bits_3_4_5),
            0x7, 0xF => {
                switch (bits_3_4_5) {
                    0x0 => x_bs.execute_RLCA(self),
                    0x1 => x_bs.execute_RRCA(self),
                    0x2 => x_bs.execute_RLA(self),
                    0x3 => x_bs.execute_RRA(self),
                    0x4 => {},
                    0x5 => {},
                    0x6 => x_cf.execute_SCF(self),
                    0x7 => x_cf.execute_CCF(self),
                }
            },
        }
    }

    pub fn pc_pop_16(self: *Cpu) u16 {
        const b1: u8 = self.mem.read8(self.PC.getHiLo());
        self.PC.inc();
        const b2: u8 = self.mem.read8(self.PC.HiLo());
        self.PC.Inc();
        return b2 << 8 | b1;
    }

    pub fn pc_pop_8(self: *Cpu) u8 {
        const b: u8 = self.mem.read8(self.PC.getHiLo());
        self.PC.inc();
        return b;
    }

    pub fn set_c(self: *Cpu, flag: bool) void {
        const current: u8 = self.AF.getLo();
        if (flag) {
            self.AF.setLo(current | 0x8);
        } else {
            self.AF.setLo(current & ~@as(u8, 0x8));
        }
    }

    pub fn get_c(self: *Cpu) u1 {
        return @truncate((self.AF.getLo() & 0x10) >> 4);
    }

    pub fn set_h(self: *Cpu, flag: bool) void {
        const current: u8 = self.AF.getLo();
        if (flag) {
            self.AF.setLo(current | 0x10);
        } else {
            self.AF.setLo(current & ~@as(u8, 0x10));
        }
    }

    pub fn set_n(self: *Cpu, flag: bool) void {
        const current: u8 = self.AF.getLo();
        if (flag) {
            self.AF.setLo(current | 0x20);
        } else {
            self.AF.setLo(current & ~@as(u8, 0x20));
        }
    }

    pub fn set_z(self: *Cpu, flag: bool) void {
        const current: u8 = self.AF.getLo();
        if (flag) {
            self.AF.setLo(current | 0x40);
        } else {
            self.AF.setLo(current & ~@as(u8, 0x40));
        }
    }
};
