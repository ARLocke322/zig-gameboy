const Cpu = @import("cpu.zig").Cpu;
const Bus = @import("bus.zig").Bus;
const Cartridge = @import("../Cartridge/MBC0.zig").MBC0;
const Timer = @import("timer.zig").Timer;
const InterruptController = @import("interrupt_controller.zig").InterruptController;

pub const Console = struct {
    interrupt_controller: *InterruptController,
    timer: *Timer,
    bus: *Bus,
    cpu: *Cpu,
    cycles: u64,

    pub fn init(cart: *Cartridge) Console {
        var interrupt_controller = InterruptController.init();
        var timer = Timer.init(&interrupt_controller);
        var bus = Bus.init(cart, &timer, &interrupt_controller);
        var cpu = Cpu.init(&bus, &interrupt_controller);

        return Console{
            .interrupt_controller = &interrupt_controller,
            .timer = &timer,
            .bus = &bus,
            .cpu = &cpu,
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
