const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../register.zig").Register;
const Bus = @import("../../bus.zig").Bus;

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

pub fn execAdd8(
    cpu: *Cpu,
    ctx: anytype,
    set: *const fn (val: u8) void,
    op1: u8,
    op2: u8,
    useCarry: bool,
) void {
    const carry = if (useCarry) cpu.get_c() else 0;
    const r1 = @addWithOverflow(op1, op2);
    const r2 = @addWithOverflow(r1[0], carry);

    set(ctx, r2[0]);

    cpu.set_z(r2[0] == 0);
    cpu.set_n(false);
    cpu.set_h(halfCarryAdd(@truncate(op1), @truncate(op2), carry));
    cpu.set_c(r1[1] == 1 or r2[1] == 1);
}

pub fn execSub8(
    cpu: *Cpu,
    set: *const fn (u8) void,
    op1: u8,
    op2: u8,
    useCarry: bool,
) void {
    const carry = if (useCarry) cpu.get_c() else 0;
    const r1 = @subWithOverflow(op1, op2);
    const r2 = @subWithOverflow(r1[0], carry);

    set(r2[0]);

    cpu.set_z(r2[0] == 0);
    cpu.set_n(true);
    cpu.set_h(halfCarrySub(@truncate(op1), @truncate(op2), carry));
    cpu.set_c(r1[1] == 1 or r2[1] == 1);
}

pub fn execAdd16(
    cpu: *Cpu,
    ctx: anytype,
    set: fn (@TypeOf(ctx), u16) void,
    op1: u16,
    op2: u16,
) void {
    const result = @addWithOverflow(op1, op2);

    set(result[0]);

    cpu.set_n(false);
    cpu.set_h(halfCarryAdd(@truncate(op1), @truncate(op2), 0));
    cpu.set_c(result[1] == 1);
}

pub fn execLoad16(
    ctx: anytype,
    set: fn (@TypeOf(ctx), u16) void,
    val: u16,
) void {
    set(ctx, val);
}

pub fn execInc16(
    ctx: anytype,
    set: fn (@TypeOf(ctx), u16) void,
    current: u16,
) void {
    set(ctx, current + 1);
}

pub fn execDec16(
    ctx: anytype,
    set: fn (@TypeOf(ctx), u16) void,
    current: u16,
) void {
    set(ctx, current + 1);
}

pub fn execInc8(
    ctx: anytype,
    set: fn (@TypeOf(ctx), u8) void,
    current: u8,
) void {
    set(ctx, current + 1);
}

pub fn execDec8(
    ctx: anytype,
    set: fn (@TypeOf(ctx), u8) void,
    current: u8,
) void {
    set(ctx, current - 1);
}

pub fn execRotateLeft(
    cpu: *Cpu,
    ctx: anytype,
    set: *const fn (val: u8) void,
    current: u8,
    useCarry: bool,
) void {
    const new_carry: u1 = @truncate(current >> 7);
    const new_bit_0: u1 = if (useCarry) cpu.get_c() else new_carry;

    const result: u8 = @as(u8, current) << 1 | new_bit_0;

    set(ctx, result);

    cpu.set_z(false);
    cpu.set_n(false);
    cpu.set_h(false);
    cpu.set_c(new_carry == 1);
}

pub fn execRotateRight(
    cpu: *Cpu,
    ctx: anytype,
    set: *const fn (val: u8) void,
    current: u8,
    useCarry: bool,
) void {
    const new_carry: u1 = @truncate(current);
    const new_bit_7: u1 = if (useCarry) cpu.get_c() else new_carry;

    const result: u8 = @as(u8, new_bit_7) << 7 | (current >> 1);

    set(ctx, result);

    cpu.set_z(false);
    cpu.set_n(false);
    cpu.set_h(false);
    cpu.set_c(new_carry == 1);
}

pub fn execJump(cpu: *Cpu, val: u16) void {
    cpu.PC.set(val);
}
