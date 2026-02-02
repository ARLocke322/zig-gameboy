const x_ld = @import("./execute/execute_load.zig");
const Register = @import("./register.zig");

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
        const bits_4_5: u2 = @truncate(instruction >> 4);
        switch (instruction) {
            0x00 => {},
            0x11, 0x21, 0x31 => x_ld.execute_LD_r16_n16(
                self,
                self.get_r16(bits_4_5),
                self.pc_pop_16,
            ),
            0x12, 0x22, 0x32 => {
                const opts = self.get_r16mem(bits_4_5);
                if (opts.inc) {
                    x_ld.execute_LDH_HLI_A(self);
                } else if (opts.dec) {
                    x_ld.execute_LDH_HLD_A(self);
                } else x_ld.execute_LD_r16_A(
                    self,
                    opts.reg,
                );
            },
            0x1A, 0x2A, 0x3A => {
                const opts = self.get_r16mem(bits_4_5);
                if (opts.inc) {
                    x_ld.execute_LD_A_HLI(self);
                } else if (opts.dec) {
                    x_ld.execute_LD_A_HLD(self);
                } else x_ld.execute_LD_A_r16(
                    self,
                    opts.reg,
                );
            },
            0x8 => x_ld.execute_LD_n16_SP(
                self,
                pc_pop_16(),
            ),
            else => {},
        }
    }

    pub fn pc_pop_16(self: *Cpu) u16 {
        const b1: u8 = Memory.read8(self.PC.getHiLo());
        self.PC.inc();
        const b2: u8 = Memory.read8(self.PC.HiLo());
        self.PC.Inc();
        return b2 << 8 | b1;
    }

    pub fn pc_pop_8(self: *Cpu) u8 {
        const b: u8 = Memory.read8(self.PC.getHiLo());
        self.PC.inc();
        return b;
    }

    pub fn set_c(self: *Cpu, flag: bool) void {
        const current: u8 = self.AF.getLo();
        if (flag) {
            self.AF.setLo(current | 0x1);
        } else {
            self.AF.setLo(current & ~@as(u8, 0x1));
        }
    }

    pub fn set_h(self: *Cpu, flag: bool) void {
        const current: u8 = self.AF.getLo();
        if (flag) {
            self.AF.setLo(current | 0x2);
        } else {
            self.AF.setLo(current & ~@as(u8, 0x2));
        }
    }

    pub fn get_r8(self: *Cpu, index: u2) *Register {
        return switch(index) {
            0 => 
        }
    }

    pub fn get_r16(self: *Cpu, index: u2) *Register {
        return switch (index) {
            0 => &self.BC,
            1 => &self.DE,
            2 => &self.HL,
            3 => &self.SP,
            else => {},
        };
    }
    pub fn get_r16mem(self: *Cpu, index: u2) struct { reg: *Register, inc: bool, dec: bool } {
        return switch (index) {
            0 => .{ &self.BC, false, false },
            1 => .{ &self.DE, false, false },
            2 => .{ &self.HL, true, false },
            3 => .{ &self.HL, false, true },
        };
    }
};
