const x_ar = @import("../execute/execute_arithmetic.zig");
const x_bl = @import("../execute/execute_bitwise_logic.zig");
const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../register.zig").Register;
const helpers = @import("../helpers.zig");

pub fn decode_INC_r16(cpu: *Cpu, register_number: u2) void {
    var register: Register = helpers.get_r16(cpu, register_number).*;
    x_ar.execute_INC_r16(&register);
}

pub fn decode_DEC_r16(cpu: *Cpu, register_number: u2) void {
    var register: Register = helpers.get_r16(cpu, register_number).*;
    x_ar.execute_DEC_r16(&register);
}

pub fn decode_ADD_HL_r16(cpu: *Cpu, register_number: u2) void {
    var register: Register = helpers.get_r16(cpu, register_number).*;
    x_ar.execute_ADD_HL_r16(cpu, &register);
}

pub fn decode_INC_r8(cpu: *Cpu, register_number: u3) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_ar.execute_INC_HL(cpu);
    } else x_ar.execute_INC_r8(cpu, opts.reg, opts.isHi);
}

pub fn decode_DEC_r8(cpu: *Cpu, register_number: u3) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_ar.execute_DEC_HL(cpu);
    } else x_ar.execute_DEC_r8(cpu, opts.reg, opts.isHi);
}

pub fn decode_ADD_A_r8(cpu: *Cpu, register_number: u3) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_ar.execute_ADD_A_HL(cpu);
    } else x_ar.execute_ADD_A_r8(cpu, opts.reg, opts.isHi);
}

pub fn decode_ADC_A_r8(cpu: *Cpu, register_number: u3) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_ar.execute_ADC_A_HL(cpu);
    } else x_ar.execute_ADC_A_r8(cpu, opts.reg, opts.isHi);
}

pub fn decode_SUB_A_r8(cpu: *Cpu, register_number: u3) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_ar.execute_SUB_A_HL(cpu);
    } else x_ar.execute_SUB_A_r8(cpu, opts.reg, opts.isHi);
}

pub fn decode_SBC_A_r8(cpu: *Cpu, register_number: u3) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_ar.execute_SBC_A_HL(cpu);
    } else x_ar.execute_SBC_A_r8(cpu, opts.reg, opts.isHi);
}

pub fn decode_CP_A_r8(cpu: *Cpu, register_number: u3) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_ar.execute_CP_A_HL(cpu);
    } else x_ar.execute_CP_A_r8(cpu, opts.reg, opts.isHi);
}
