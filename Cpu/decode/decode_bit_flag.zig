const Cpu = @import("../cpu.zig").Cpu;
const helpers = @import("../helpers.zig");
const Register = @import("../register.zig").Register;
const x_bf = @import("../execute/execute_bit_flag.zig");

pub fn decode_BIT_u3_r8(cpu: *Cpu, ix: u3, register_number: u8) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_bf.execute_BIT_u3_HL(cpu, ix);
    } else x_bf.execute_BIT_u3_r8(cpu, ix, opts.reg, opts.isHi);
}

pub fn decode_RES_u3_r8(cpu: *Cpu, ix: u3, register_number: u8) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_bf.execute_RES_u3_HL(cpu, ix);
    } else x_bf.execute_RES_u3_r8(ix, opts.reg, opts.isHi);
}

pub fn decode_SET_u3_r8(cpu: *Cpu, ix: u3, register_number: u8) void {
    const opts = helpers.get_r8(cpu, register_number);
    if (opts.isHL) {
        x_bf.execute_SET_u3_HL(cpu, ix);
    } else x_bf.execute_SET_u3_r8(ix, opts.reg, opts.isHi);
}
