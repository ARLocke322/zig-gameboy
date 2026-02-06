const Cpu = @import("../cpu.zig").Cpu;
const helpers = @import("../helpers.zig");
const Register = @import("../register.zig").Register;
const x_bs = @import("../execute/execute_bit_shift.zig");

pub fn decode_RLC_r8(cpu: *Cpu, register_number: u3) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_bs.execute_RLC_HL(cpu);
    } else x_bs.execute_RLC_r8(cpu, opts.reg, opts.isHi);
}

pub fn decode_RRC_r8(cpu: *Cpu, register_number: u3) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_bs.execute_RRC_HL(cpu);
    } else x_bs.execute_RRC_r8(cpu, opts.reg, opts.isHi);
}

pub fn decode_RL_r8(cpu: *Cpu, register_number: u3) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_bs.execute_RL_HL(cpu);
    } else x_bs.execute_RL_r8(cpu, opts.reg, opts.isHi);
}

pub fn decode_RR_r8(cpu: *Cpu, register_number: u3) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_bs.execute_RR_HL(cpu);
    } else x_bs.execute_RR_r8(cpu, opts.reg, opts.isHi);
}

pub fn decode_SLA_r8(cpu: *Cpu, register_number: u3) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_bs.execute_SLA_HL(cpu);
    } else x_bs.execute_SLA_r8(cpu, opts.reg, opts.isHi);
}

pub fn decode_SRA_r8(cpu: *Cpu, register_number: u3) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_bs.execute_SRA_HL(cpu);
    } else x_bs.execute_SRA_r8(cpu, opts.reg, opts.isHi);
}

pub fn decode_SWAP_r8(cpu: *Cpu, register_number: u3) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_bs.execute_SWAP_HL(cpu);
    } else x_bs.execute_SWAP_r8(cpu, opts.reg, opts.isHi);
}

pub fn decode_SRL_r8(cpu: *Cpu, register_number: u3) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_bs.execute_SRL_HL(cpu);
    } else x_bs.execute_SRL_r8(cpu, opts.reg, opts.isHi);
}
