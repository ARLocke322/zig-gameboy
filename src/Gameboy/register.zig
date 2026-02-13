pub const Register = struct {
    value: u16,

    pub fn init(val: u16) Register {
        return Register{ .value = val };
    }

    pub fn getHi(self: *Register) u8 {
        return @truncate(self.value >> 8);
    }

    pub fn getLo(self: *Register) u8 {
        return @truncate(self.value);
    }

    pub fn getHiLo(self: *Register) u16 {
        return self.value;
    }

    pub fn setHi(self: *Register, val: u8) void {
        self.value = @as(u16, val) << 8 | (self.value & 0xFF);
    }

    pub fn setLo(self: *Register, val: u8) void {
        self.value = (self.value & 0xFF00) | val;
    }

    pub fn set(self: *Register, val: u16) void {
        self.value = val;
    }

    pub fn inc(self: *Register) void {
        self.value +%= 1;
    }

    pub fn dec(self: *Register) void {
        self.value -%= 1;
    }
};
