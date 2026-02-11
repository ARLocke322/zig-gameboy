const assert = @import("std").debug.assert;

pub const InterruptController = struct {
    IE: u8,
    IF: u8,

    pub const VBLANK = 0;
    pub const LCD_STAT = 1;
    pub const TIMER = 2;
    pub const SERIAL = 3;
    pub const JOYPAD = 4;

    pub fn init() InterruptController {
        return InterruptController{
            .IE = 0,
            .IF = 0,
        };
    }

    pub fn read8(self: *InterruptController, addr: u16) u8 {
        assert(addr == 0xFFFF or addr == 0xFF0F);
        return switch (addr) {
            0xFFFF => self.IE,
            0xFF0F => self.IF,
        };
    }

    pub fn write8(self: *InterruptController, addr: u16, val: u8) void {
        assert(addr == 0xFFFF or addr == 0xFF0F);
        switch (addr) {
            0xFFFF => self.IE = val,
            0xFF0F => self.IF = val,
            else => unreachable,
        }
    }

    pub fn request(self: *InterruptController, interrupt_bit: u3) void {
        self.IF |= (@as(u8, 1) << interrupt_bit);
    }

    pub fn acknowledge(self: *InterruptController, interrupt_bit: u3) void {
        self.IF &= ~(@as(u8, 1) << interrupt_bit);
    }

    pub fn get_pending(self: *InterruptController) u8 {
        return self.IF & self.IE;
    }
};
