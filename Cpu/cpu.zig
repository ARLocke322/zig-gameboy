const Register = struct {
    value: u16,

    pub fn init(val: u16) Register {
        return Register{ .value = val };
    }

    pub fn Hi(self: Register) u8 {
        return @truncate(self.value >> 8);
    }

    pub fn Lo(self: Register) u8 {
        return @truncate(self.value);
    }

    pub fn HiLo(self: Register) u16 {
        return self.value;
    }

    pub fn SetHi(self: *Register, val: u8) void {
        self.value = val << 8 | (self.value & 0xFF);
    }

    pub fn SetLo(self: *Register, val: u8) void {
        self.value = (self.value & 0xFF00) | val;
    }

    pub fn Set(self: *Register, val: u16) void {
        self.value = val;
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
};
