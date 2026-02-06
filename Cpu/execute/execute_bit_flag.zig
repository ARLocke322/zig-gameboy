const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../register.zig").Register;

pub fn execute_BIT_u3_r8(cpu: *Cpu, ix: u3, r: *Register, isHi: bool) void {
    const test_byte: u8 = if (isHi) r.getHi() else r.getLo();
    const test_bit: u1 = @truncate(test_byte >> ix);
    cpu.set_z(test_bit == 0);
    cpu.set_n(false);
    cpu.set_h(true);
}

pub fn execute_BIT_u3_HL(cpu: *Cpu, ix: u3) void {
    const addr: u16 = cpu.HL.getHiLo();
    const test_byte: u8 = cpu.mem.read8(addr);
    const test_bit: u1 = @truncate(test_byte >> ix);

    cpu.set_z(test_bit == 0);
    cpu.set_n(false);
    cpu.set_h(true);
}

pub fn execute_RES_u3_r8(ix: u3, r: *Register, isHi: bool) void {
    const current: u8 = if (isHi) r.getHi() else r.getLo();
    const mask: u8 = ~(@as(u8, 0x1) << ix);
    if (isHi) r.setHi(current & mask) else r.setLo(current & mask);
}

pub fn execute_RES_u3_HL(cpu: *Cpu, ix: u3) void {
    const addr: u16 = cpu.HL.getHiLo();
    const current: u8 = cpu.mem.read8(addr);
    const mask: u8 = ~(@as(u8, 0x1) << ix);
    cpu.mem.write8(addr, current & mask);
}

pub fn execute_SET_u3_r8(ix: u3, r: *Register, isHi: bool) void {
    const current: u8 = if (isHi) r.getHi() else r.getLo();
    const mask: u8 = @as(u8, 0x1) << ix;
    if (isHi) r.setHi(current | mask) else r.setLo(current | mask);
}

pub fn execute_SET_u3_HL(cpu: *Cpu, ix: u3) void {
    const addr: u16 = cpu.HL.getHiLo();
    const current: u8 = cpu.mem.read8(addr);
    const mask: u8 = @as(u8, 0x1) << ix;
    cpu.mem.write8(addr, current | mask);
}
