const x_sm = @import("../execute/execute_stack_manipulation.zig");
const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../register.zig").Register;
const helpers = @import("../helpers.zig");

pub fn decode_POP_r16(cpu: *Cpu, register_number: u2) void {
    const register: *Register = helpers.get_r16(cpu, register_number);
    x_sm.execute_POP_r16(cpu, register);
}

pub fn decode_PUSH_r16(cpu: *Cpu, register_number: u2) void {
    const register: *Register = helpers.get_r16(cpu, register_number);
    x_sm.execute_PUSH_r16(cpu, register);
}

pub fn decode_LD_n16_SP(cpu: *Cpu) void {
    x_sm.execute_LD_n16_SP(cpu, cpu.pc_pop_16());
}
