const Cpu = @import("cpu.zig").Cpu;
const Bus = @import("bus.zig").Bus;
const Cartridge = @import("../Cartridge/MBC1.zig").MBC1;
const Timer = @import("timer.zig").Timer;
const InterruptController = @import("interrupt_controller.zig").InterruptController;
const std = @import("std");

pub const Console = struct {
    allocator: std.mem.Allocator,
    interrupt_controller: *InterruptController,
    timer: *Timer,
    bus: *Bus,
    cpu: *Cpu,
    cycles: u64,

    pub fn init(allocator: std.mem.Allocator, cart: *Cartridge) !Console {
        const ic = try allocator.create(InterruptController);
        ic.* = InterruptController.init();

        const timer = try allocator.create(Timer);
        timer.* = Timer.init(ic);

        const bus = try allocator.create(Bus);
        bus.* = Bus.init(cart, timer, ic);

        const cpu = try allocator.create(Cpu);
        cpu.* = Cpu.init(bus, ic);

        return Console{
            .allocator = allocator,
            .interrupt_controller = ic,
            .timer = timer,
            .bus = bus,
            .cpu = cpu,
            .cycles = 0,
        };
    }

    pub fn deinit(self: *Console) void {
        self.allocator.destroy(self.cpu);
        self.allocator.destroy(self.bus);
        self.allocator.destroy(self.timer);
        self.allocator.destroy(self.interrupt_controller);
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

        self.cycles += cycles;
        return cycles;
    }

    pub fn run(self: *Console) void {
        while (true) {
            _ = self.step();
            if (self.bus.read8(0xA000) != 0) break;
        }
    }
};
