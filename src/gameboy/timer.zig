const InterruptController = @import("interrupt_controller.zig").InterruptController;
const assert = @import("std").debug.assert;
const std = @import("std");

pub const Timer = struct {
    DIV: u8,
    TIMA: u8,
    TMA: u8,
    TAC: u8,
    div_counter: u16,
    tima_counter: u16,
    interrupt_controller: *InterruptController,

    pub fn init(interrupt_controller: *InterruptController) Timer {
        return Timer{
            .DIV = 0x00,
            .TIMA = 0x00,
            .TMA = 0x00,
            .TAC = 0x00,
            .div_counter = 0x00,
            .tima_counter = 0x00,
            .interrupt_controller = interrupt_controller,
        };
    }

    pub fn read8(self: *Timer, addr: u16) u8 {
        assert(addr >= 0xFF04 and addr <= 0xFF07);
        return switch (addr) {
            0xFF04 => self.DIV,
            0xFF05 => self.TIMA,
            0xFF06 => self.TMA,
            0xFF07 => self.TAC,
            else => unreachable,
        };
    }

    pub fn write8(self: *Timer, addr: u16, value: u8) void {
        assert(addr >= 0xFF04 and addr <= 0xFF07);
        switch (addr) {
            0xFF04 => {
                self.DIV = 0x00;
                // self.div_counter = 0;
                // self.tima_counter = 0;
            },
            0xFF05 => self.TIMA = value,
            0xFF06 => self.TMA = value,
            0xFF07 => {
                self.TAC = value & 0x07;
                // self.tima_counter = 0;
            },
            else => unreachable,
        }
    }

    pub fn tick(self: *Timer, cycles: u8) void {
        self.div_counter += cycles;
        if (self.div_counter >= 256) {
            self.div_counter -= 256;
            self.DIV +%= 1;
        }

        if (self.TAC & 0x04 != 0) {
            self.tima_counter += cycles;
            const increment_rate = get_clock_select(@truncate(self.TAC & 0x03));
            if (self.tima_counter >= increment_rate) {
                self.tima_counter -= increment_rate;
                if (self.TIMA == 0xFF) {
                    self.TIMA = self.TMA;
                    self.interrupt_controller.request(InterruptController.TIMER);
                } else {
                    self.TIMA += 1;
                }
            }
        }
    }

    fn get_clock_select(val: u2) u16 {
        return switch (val) {
            0 => 1024, // 4096 Hz
            1 => 16, // 262144 Hz
            2 => 64, // 65536 Hz
            3 => 256, // 16384 Hz
        };
    }
};
