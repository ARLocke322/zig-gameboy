const Cpu = @import("cpu.zig").Cpu;
const Ppu = @import("ppu.zig").Ppu;
const Bus = @import("bus.zig").Bus;
const Cartridge = @import("../cartridge/MBC1.zig").MBC1;
const Timer = @import("timer.zig").Timer;
const InterruptController = @import("interrupt_controller.zig").InterruptController;
const std = @import("std");

pub const Console = struct {
    const CYCLES_PER_FRAME: u64 = 70224;
    const FRAME_TIME_NS: u64 = 16_742_706; // ~59.7 FPS
    //
    interrupt_controller: *InterruptController,
    timer: *Timer,
    bus: *Bus,
    cpu: *Cpu,
    ppu: *Ppu,
    cycles: u64,
    //
    pub fn init(
        interrupt_controller: *InterruptController,
        timer: *Timer,
        bus: *Bus,
        cpu: *Cpu,
        ppu: *Ppu,
    ) Console {
        return Console{
            .interrupt_controller = interrupt_controller,
            .timer = timer,
            .bus = bus,
            .cpu = cpu,
            .ppu = ppu,
            .cycles = 0,
        };
    }

    pub fn step(
        self: *Console,
        //stdout: *std.Io.Writer,
    ) !u8 {
        var cycles: u8 = 1; // minimum tick while halted

        if (self.cpu.IME_scheduled) {
            self.cpu.IME = true;
            self.cpu.IME_scheduled = false;
        }

        if (!self.cpu.halted) {
            const opcode = self.cpu.fetch();
            cycles = self.cpu.decode_execute(opcode);
        }

        if (self.cpu.interrupt_controller.get_pending() != 0) {
            self.cpu.halted = false;
            if (self.cpu.IME) {
                self.cpu.handle_interrupt();
                cycles += 5;
            }
        }

        self.timer.tick(cycles * 4);
        self.ppu.tick(cycles * 4);

        self.cycles += cycles;
        return cycles;
    }
};
