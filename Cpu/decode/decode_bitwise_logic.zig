const x_ld = @import("../execute/execute_load.zig");
const x_bl = @import("../execute/execute_bitwise_logic.zig");
const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../register.zig").Register;
const helpers = @import("../helpers.zig");

pub fn decode_AND_A_r8(cpu: *Cpu, register_number: u3) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_bl.execute_AND_A_HL(cpu);
    } else x_bl.execute_AND_A_r8(cpu, opts.reg, opts.isHi);
}

pub fn decode_LD_r16_n16(cpu: *Cpu, register_number: u2) void {
    const register: Register = helpers.get_r16(cpu, register_number);
    x_ld.execute_LD_r16_n16(cpu, register, cpu.pc_pop_16());
}

pub fn decode_LD_r16_A(cpu: *Cpu, register_number: u2) void {
    const opts = helpers.get_r16mem(cpu, register_number);
    if (opts.inc) {
        x_ld.execute_LDH_HLI_A(cpu);
    } else if (opts.dec) {
        x_ld.execute_LDH_HLD_A(cpu);
    } else {
        x_ld.execute_LD_r16_A(cpu, opts.reg);
    }
}

pub fn decode_LD_A_r16(cpu: *Cpu, register_number: u2) void {
    const opts = helpers.get_r16mem(cpu, register_number);
    if (opts.inc) {
        x_ld.execute_LD_A_HLI(cpu);
    } else if (opts.dec) {
        x_ld.execute_LD_A_HLD(cpu);
    } else {
        x_ld.execute_LD_A_r16(cpu, opts.reg);
    }
}

pub fn decode_LD_n16_SP(cpu: *Cpu) void {
    x_ld.execute_LD_n16_SP(cpu, cpu.pc_pop_16());
}

pub fn decode_LD_r8_n8(cpu: *Cpu, register_number: u3) void {
    const opts = helpers.get_r8(cpu, register_number);
    const n8 = cpu.pc_pop_8();
    if (opts.isHL) {
        x_ld.execute_LD_HL_n8(cpu, n8);
    } else x_ld.execute_LD_r8_n8(opts.reg, opts.isHi, n8);
}
