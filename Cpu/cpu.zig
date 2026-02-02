pub const Register = struct {
    value: u16,

    pub fn init(val: u16) Register {
        return Register{ .value = val };
    }

    pub fn getHi(self: Register) u8 {
        return @truncate(self.value >> 8);
    }

    pub fn getLo(self: Register) u8 {
        return @truncate(self.value);
    }

    pub fn getHiLo(self: Register) u16 {
        return self.value;
    }

    pub fn setHi(self: *Register, val: u8) void {
        self.value = val << 8 | (self.value & 0xFF);
    }

    pub fn setLo(self: *Register, val: u8) void {
        self.value = (self.value & 0xFF00) | val;
    }

    pub fn set(self: *Register, val: u16) void {
        self.value = val;
    }

    pub fn inc(self: *Register) void {
        self.value += 1;
    }

    pub fn dec(self: *Register) void {
        self.value -= 1;
    }
};

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

    pub fn decode_execute(self: *Cpu) void {
        const instruction = self.pc_pop_8();
        switch (instruction) {
            0x00 => {},
            0x11, 0x21, 0x31 => {},
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
};
