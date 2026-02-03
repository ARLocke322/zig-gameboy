const Cpu = @import("../cpu.zig").Cpu;

pub fn execute_CCF(cpu: *Cpu) void {
    cpu.set_c(~cpu.get_c() == 1);
}

pub fn execute_SCF(cpu: *Cpu) void {
    cpu.set_c(true);
}
