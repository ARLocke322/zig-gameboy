const Cpu = @import("cpu.zig").Cpu;
const Ppu = @import("ppu.zig").Ppu;
const Bus = @import("bus.zig").Bus;
const Cartridge = @import("../cartridge/MBC1.zig").MBC1;
const Timer = @import("timer.zig").Timer;
const InterruptController = @import("interrupt_controller.zig").InterruptController;
const std = @import("std");

pub const Console = struct {
    interrupt_controller: *InterruptController,
    timer: *Timer,
    bus: *Bus,
    cpu: *Cpu,
    ppu: *Ppu,
    cycles: u64,

    pub fn init(interrupt_controller: *InterruptController, timer: *Timer, bus: *Bus, cpu: *Cpu, ppu: *Ppu) Console {
        return Console{
            .interrupt_controller = interrupt_controller,
            .timer = timer,
            .bus = bus,
            .cpu = cpu,
            .ppu = ppu,
            .cycles = 0,
        };
    }

    pub fn step(self: *Console) u8 {
        const opcode = self.cpu.fetch();
        var cycles = self.cpu.decode_execute(opcode);

        if (self.cpu.IME and self.cpu.interrupt_controller.get_pending() != 0) {
            self.cpu.handle_interrupt();
            cycles += 20;
        }

        if (self.cpu.IME_scheduled) {
            self.cpu.IME = true;
            self.cpu.IME_scheduled = false;
        }

        self.timer.tick(cycles);
        self.ppu.tick(cycles);

        self.cycles += cycles;
        return cycles;
    }

    pub fn run(self: *Console) void {
        var count: u64 = 0;
        while (true) {
            _ = self.step();
            count += 1;

            std.debug.print("\nPC: 0x{X:0>4}\n", .{self.cpu.PC.getHiLo()});
            std.debug.print("Opcode: 0x{X:0>2}\n", .{self.bus.read8(self.cpu.PC.getHiLo())});
            if (count > 50_000_000) {
                std.debug.print("\nPC: 0x{X:0>4}\n", .{self.cpu.PC.getHiLo()});
                std.debug.print("Last opcode: 0x{X:0>2}\n", .{self.bus.read8(self.cpu.PC.getHiLo())});
                break;
            }
        }
    }
};
