const Cpu = @import("../cpu.zig").Cpu;

pub fn execute_DI(cpu: *Cpu) void {
    cpu.IME = false;
}

// change to after following instruction
pub fn execute_EI(cpu: *Cpu) void {
    cpu.IME = true;
}

pub fn execute_HALT() void {
    // maybe later
}
