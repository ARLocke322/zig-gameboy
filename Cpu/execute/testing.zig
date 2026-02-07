const Cpu = @import("../cpu.zig").Cpu;

fn halfCarryAdd(a: u4, b: u4, c: u1) bool {
    const hc1 = @addWithOverflow(a, b);
    const hc2 = @addWithOverflow(hc1[0], c);
    return hc1[1] == 1 or hc2[1] == 1;
}

fn halfCarrySub(a: u4, b: u4, c: u1) bool {
    const hc1 = @subWithOverflow(a, b);
    const hc2 = @subWithOverflow(hc1[0], c);
    return hc1[1] == 1 or hc2[1] == 1;
}

pub fn execAdd8(cpu: *Cpu, set: fn (u8) void, op1: u8, op2: u8, useCarry: bool) void {
    const carry = if (useCarry) cpu.get_c() else 0;
    const r1 = @addWithOverflow(op1, op2);
    const r2 = @addWithOverflow(r1[0], carry);

    set(r2[0]);

    cpu.set_z(r2[0] == 0);
    cpu.set_n(false);
    cpu.set_h(halfCarryAdd(@truncate(op1), @truncate(op2), carry));
    cpu.set_c(r1[1] == 1 or r2[1] == 1);
}

pub fn execSub8(cpu: *Cpu, set: fn (u8) void, op1: u8, op2: u8, useCarry: bool) void {
    const carry = if (useCarry) cpu.get_c() else 0;
    const r1 = @subWithOverflow(op1, op2);
    const r2 = @subWithOverflow(r1[0], carry);

    set(r2[0]);

    cpu.set_z(r2[0] == 0);
    cpu.set_n(true);
    cpu.set_h(halfCarrySub(@truncate(op1), @truncate(op2), carry));
    cpu.set_c(r1[1] == 1 or r2[1] == 1);
}

pub fn execAdd16(cpu: *Cpu, set: fn (u8) void, op1: u16, op2: u16) void {
    const result = @addWithOverflow(op1, op2);

    set(result[0]);

    cpu.set_n(false);
    cpu.set_h(halfCarryAdd(@truncate(op1), @truncate(op2), 0));
    cpu.set_c(result[1] == 1);
}
