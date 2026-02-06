const Cpu = @import("../cpu.zig").Cpu;
const check_condition = @import("../helpers.zig").check_condition;

pub fn execute_CALL_n16(cpu: *Cpu, addr: u16) void {
    cpu.sp_push_16(cpu.PC.getHiLo());
    cpu.PC.set(addr);
}

pub fn execute_CALL_cc_n16(cpu: *Cpu, cond: u2, addr: u16) void {
    if (check_condition(cpu, cond)) execute_CALL_n16(cpu, addr);
}

pub fn execute_JP_HL(cpu: *Cpu) void {
    cpu.PC.set(cpu.HL.getHiLo());
}

pub fn execute_JP_n16(cpu: *Cpu, addr: u16) void {
    cpu.PC.set(addr);
}

pub fn execute_JP_cc_n16(cpu: *Cpu, cond: u2, addr: u16) void {
    if (check_condition(cpu, cond)) execute_JP_n16(cpu, addr);
}

pub fn execute_JR_n16(cpu: *Cpu, offset: u8) void {
    const signed_offset: i8 = @bitCast(offset);
    const offset_u16: u16 = @bitCast(@as(i16, signed_offset));
    cpu.PC.set(cpu.PC.getHiLo() +% offset_u16);
}

pub fn execute_JR_cc_n16(cpu: *Cpu, cond: u2, offset: u8) void {
    if (check_condition(cpu, cond)) execute_JR_n16(cpu, offset);
}

pub fn execute_RET(cpu: *Cpu) void {
    cpu.PC.set(cpu.sp_pop_16());
}

pub fn execute_RET_cc(cpu: *Cpu, cond: u2) void {
    if (check_condition(cpu, cond)) execute_RET(cpu);
}

pub fn execute_RETI(cpu: *Cpu) void {
    cpu.IME = true;
    execute_RET(cpu);
}

pub fn execute_RST_vec(cpu: *Cpu, vec: u8) void {
    cpu.sp_push_16(cpu.PC.getHiLo());
    cpu.PC.set(vec);
}
