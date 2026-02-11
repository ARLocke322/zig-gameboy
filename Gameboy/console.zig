const Cpu = @import("cpu.zig").Cpu;
const Bus = @import("bus.zig").Bus;

pub const Console = struct {
    bus: *Bus,
    cpu: *Cpu,
    cycles: u64,

    pub fn init() Console {
        var bus = Bus.init();
        const cpu = Cpu.init(&bus);

        return Console{
            .bus = bus,
            .cpu = cpu,
            .cycles = 0,
        };
    }

    pub fn step(self: *Console) u8 {
        const opcode = self.cpu.fetch();
        const cycles = self.cpu.decode_execute(opcode);
        self.cycles += cycles;
        return cycles;
    }

    pub fn run(self: *Console) void {
        while (true) {
            _ = self.step();
        }
    }
};
