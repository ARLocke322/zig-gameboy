const std = @import("std");

const Bus = @import("bus.zig").Bus;
const Cpu = @import("./cpu/cpu.zig").Cpu;

// ------------------------------------------------------------
// Helpers
// ------------------------------------------------------------

fn setup() struct { bus: Bus, cpu: Cpu } {
    var bus = Bus.init();
    var cpu = Cpu.init(&bus);

    // Common initial state.
    cpu.PC.set(0x0000);
    cpu.SP.set(0xFFFE);

    // Clear registers
    cpu.AF.set(0x0000);
    cpu.BC.set(0x0000);
    cpu.DE.set(0x0000);
    cpu.HL.set(0x0000);

    cpu.IME = false;

    return .{ .bus = bus, .cpu = cpu };
}

fn loadRom(bus: *Bus, bytes: []const u8) void {
    for (bytes, 0..) |b, i| {
        bus.rom_bank_0[i] = b;
    }
}

fn step(cpu: *Cpu) void {
    const op = cpu.fetch();
    cpu.decode_execute(op);
}

fn expectFlags(cpu: *Cpu, z: u1, n: u1, h: u1, c: u1) !void {
    try std.testing.expectEqual(z, cpu.get_z());
    try std.testing.expectEqual(n, cpu.get_n());
    try std.testing.expectEqual(h, cpu.get_h());
    try std.testing.expectEqual(c, cpu.get_c());
}

fn setFlags(cpu: *Cpu, z: bool, n: bool, h: bool, c: bool) void {
    cpu.set_z(z);
    cpu.set_n(n);
    cpu.set_h(h);
    cpu.set_c(c);
}

fn u16lo(x: u16) u8 {
    return @as(u8, @truncate(x & 0x00FF));
}
fn u16hi(x: u16) u8 {
    return @as(u8, @truncate((x >> 8) & 0x00FF));
}

// Signed 8-bit
fn i8FromU8(x: u8) i8 {
    return @bitCast(x);
}

fn addSpSigned(sp: u16, imm: u8) u16 {
    const off: i8 = i8FromU8(imm);
    return @as(u16, @intCast(@as(i32, @intCast(sp)) + @as(i32, off)));
}

// Flag helpers for 8-bit add/sub
fn halfCarryAdd8(a: u8, b: u8, carry: u8) bool {
    return ((a & 0x0F) + (b & 0x0F) + carry) > 0x0F;
}
fn carryAdd8(a: u8, b: u8, carry: u8) bool {
    return (@as(u16, a) + @as(u16, b) + @as(u16, carry)) > 0xFF;
}
fn halfBorrowSub8(a: u8, b: u8, carry: u8) bool {
    // a - (b + carry)
    return (a & 0x0F) < ((b & 0x0F) + carry);
}
fn borrowSub8(a: u8, b: u8, carry: u8) bool {
    return @as(u16, a) < (@as(u16, b) + @as(u16, carry));
}

// ------------------------------------------------------------
// Block 0 (00xxxxxx)
// ------------------------------------------------------------

test "NOP (0x00) increments PC and changes nothing" {
    var s = setup();
    loadRom(&s.bus, &.{0x00});

    s.cpu.PC.set(0x0000);
    s.cpu.AF.set(0x1230);
    s.cpu.BC.set(0x4567);
    s.cpu.DE.set(0x89AB);
    s.cpu.HL.set(0xCDEF);
    s.cpu.SP.set(0xFFF0);
    s.cpu.IME = true;
    setFlags(&s.cpu, true, true, true, true);

    step(&s.cpu);

    try std.testing.expectEqual(@as(u16, 0x0001), s.cpu.PC.getHiLo());
    try std.testing.expectEqual(@as(u16, 0x1230), s.cpu.AF.getHiLo());
    try std.testing.expectEqual(@as(u16, 0x4567), s.cpu.BC.getHiLo());
    try std.testing.expectEqual(@as(u16, 0x89AB), s.cpu.DE.getHiLo());
    try std.testing.expectEqual(@as(u16, 0xCDEF), s.cpu.HL.getHiLo());
    try std.testing.expectEqual(@as(u16, 0xFFF0), s.cpu.SP.getHiLo());
    try std.testing.expectEqual(true, s.cpu.IME);

    // Flags should be unchanged
    try expectFlags(&s.cpu, 1, 1, 1, 1);
}

test "STOP (0x10) basic execution advances PC by 2 (functional only)" {
    var s = setup();
    loadRom(&s.bus, &.{ 0x10, 0x00 });

    s.cpu.PC.set(0x0000);
    step(&s.cpu);

    try std.testing.expectEqual(@as(u16, 0x0002), s.cpu.PC.getHiLo());
}

// ------------------------------------------------------------
// 16-bit loads: LD r16, imm16 (0x01,0x11,0x21,0x31)
// ------------------------------------------------------------

fn testLdR16Imm16(op: u8, which: u2, imm: u16) !void {
    var s = setup();
    loadRom(&s.bus, &.{ op, u16lo(imm), u16hi(imm) });

    s.cpu.PC.set(0x0000);
    setFlags(&s.cpu, true, true, true, true);

    step(&s.cpu);

    switch (which) {
        0 => try std.testing.expectEqual(imm, s.cpu.BC.getHiLo()),
        1 => try std.testing.expectEqual(imm, s.cpu.DE.getHiLo()),
        2 => try std.testing.expectEqual(imm, s.cpu.HL.getHiLo()),
        3 => try std.testing.expectEqual(imm, s.cpu.SP.getHiLo()),
    }

    // Flags unaffected
    try expectFlags(&s.cpu, 1, 1, 1, 1);
    try std.testing.expectEqual(@as(u16, 0x0003), s.cpu.PC.getHiLo());
}

test "LD r16, imm16 (0x01/11/21/31) loads little-endian and advances PC" {
    // BC
    try testLdR16Imm16(0x01, 0, 0x0000);
    try testLdR16Imm16(0x01, 0, 0xFFFF);
    try testLdR16Imm16(0x01, 0, 0x1234);

    // DE
    try testLdR16Imm16(0x11, 1, 0x0000);
    try testLdR16Imm16(0x11, 1, 0xFFFF);
    try testLdR16Imm16(0x11, 1, 0x1234);

    // HL
    try testLdR16Imm16(0x21, 2, 0x0000);
    try testLdR16Imm16(0x21, 2, 0xFFFF);
    try testLdR16Imm16(0x21, 2, 0x1234);

    // SP
    try testLdR16Imm16(0x31, 3, 0x0000);
    try testLdR16Imm16(0x31, 3, 0xFFFF);
    try testLdR16Imm16(0x31, 3, 0x1234);
}

// ------------------------------------------------------------
// LD [r16mem], A (0x02,0x12,0x22,0x32)
// ------------------------------------------------------------

fn testLdMemR16A(op: u8, mode: u2, addr: u16, a: u8) !void {
    var s = setup();
    loadRom(&s.bus, &.{op});

    s.cpu.PC.set(0x0000);
    s.cpu.AF.setHi(a);

    // Flags should not change
    setFlags(&s.cpu, true, false, true, false);

    switch (mode) {
        0 => s.cpu.BC.set(addr),
        1 => s.cpu.DE.set(addr),
        2, 3 => s.cpu.HL.set(addr),
    }

    step(&s.cpu);

    // Determine target address and HL post effect
    const target: u16 = addr;

    try std.testing.expectEqual(a, s.bus.read8(target));

    if (mode == 2) {
        try std.testing.expectEqual(@as(u16, addr +% 1), s.cpu.HL.getHiLo());
    } else if (mode == 3) {
        try std.testing.expectEqual(@as(u16, addr -% 1), s.cpu.HL.getHiLo());
    }

    try expectFlags(&s.cpu, 1, 0, 1, 0);
    try std.testing.expectEqual(@as(u16, 0x0001), s.cpu.PC.getHiLo());
}

test "LD [r16mem], A (0x02/12/22/32) writes A and HL+/HL- update HL" {
    // [BC]
    try testLdMemR16A(0x02, 0, 0xC000, 0x42);
    // [DE]
    try testLdMemR16A(0x12, 1, 0xD000, 0x99);
    // [HL+]
    try testLdMemR16A(0x22, 2, 0xC123, 0xAB);
    try testLdMemR16A(0x22, 2, 0xFFFF, 0x01); // overflow
    // [HL-]
    try testLdMemR16A(0x32, 3, 0xC123, 0xCD);
    try testLdMemR16A(0x32, 3, 0x0000, 0x02); // underflow
}

// ------------------------------------------------------------
// LD A, [r16mem] (0x0A,0x1A,0x2A,0x3A)
// ------------------------------------------------------------

fn testLdAR16Mem(op: u8, mode: u2, addr: u16, memv: u8) !void {
    var s = setup();
    loadRom(&s.bus, &.{op});

    s.cpu.PC.set(0x0000);
    s.cpu.AF.setHi(0x00);

    setFlags(&s.cpu, false, true, false, true);

    switch (mode) {
        0 => s.cpu.BC.set(addr),
        1 => s.cpu.DE.set(addr),
        2, 3 => s.cpu.HL.set(addr),
    }

    s.bus.write8(addr, memv);

    step(&s.cpu);

    try std.testing.expectEqual(memv, s.cpu.AF.getHi());

    if (mode == 2) {
        try std.testing.expectEqual(@as(u16, addr +% 1), s.cpu.HL.getHiLo());
    } else if (mode == 3) {
        try std.testing.expectEqual(@as(u16, addr -% 1), s.cpu.HL.getHiLo());
    }

    try expectFlags(&s.cpu, 0, 1, 0, 1);
    try std.testing.expectEqual(@as(u16, 0x0001), s.cpu.PC.getHiLo());
}

test "LD A, [r16mem] (0x0A/1A/2A/3A) reads memory and HL+/HL- update HL" {
    try testLdAR16Mem(0x0A, 0, 0xC000, 0x42);
    try testLdAR16Mem(0x1A, 1, 0xD000, 0x99);
    try testLdAR16Mem(0x2A, 2, 0xC123, 0xAB);
    try testLdAR16Mem(0x2A, 2, 0xFFFF, 0x01);
    try testLdAR16Mem(0x3A, 3, 0xC123, 0xCD);
    try testLdAR16Mem(0x3A, 3, 0x0000, 0x02);
}

// ------------------------------------------------------------
// LD [imm16], SP (0x08)
// ------------------------------------------------------------

test "LD [imm16], SP (0x08) stores SP little-endian and advances PC" {
    var s = setup();
    loadRom(&s.bus, &.{ 0x08, 0x00, 0xC0 }); // addr=0xC000

    s.cpu.PC.set(0x0000);
    s.cpu.SP.set(0x1234);
    setFlags(&s.cpu, true, true, false, false);

    step(&s.cpu);

    try std.testing.expectEqual(@as(u8, 0x34), s.bus.read8(0xC000));
    try std.testing.expectEqual(@as(u8, 0x12), s.bus.read8(0xC001));
    try expectFlags(&s.cpu, 1, 1, 0, 0);
    try std.testing.expectEqual(@as(u16, 0x0003), s.cpu.PC.getHiLo());
}

// ------------------------------------------------------------
// INC r16 (0x03,13,23,33) / DEC r16 (0x0B,1B,2B,3B)
// ------------------------------------------------------------

fn testIncR16(op: u8, which: u2, initial: u16, expected: u16) !void {
    var s = setup();
    loadRom(&s.bus, &.{op});

    setFlags(&s.cpu, true, true, true, true);

    switch (which) {
        0 => s.cpu.BC.set(initial),
        1 => s.cpu.DE.set(initial),
        2 => s.cpu.HL.set(initial),
        3 => s.cpu.SP.set(initial),
    }

    step(&s.cpu);

    switch (which) {
        0 => try std.testing.expectEqual(expected, s.cpu.BC.getHiLo()),
        1 => try std.testing.expectEqual(expected, s.cpu.DE.getHiLo()),
        2 => try std.testing.expectEqual(expected, s.cpu.HL.getHiLo()),
        3 => try std.testing.expectEqual(expected, s.cpu.SP.getHiLo()),
    }

    // Flags unaffected
    try expectFlags(&s.cpu, 1, 1, 1, 1);
}

fn testDecR16(op: u8, which: u2, initial: u16, expected: u16) !void {
    var s = setup();
    loadRom(&s.bus, &.{op});

    setFlags(&s.cpu, false, false, true, true);

    switch (which) {
        0 => s.cpu.BC.set(initial),
        1 => s.cpu.DE.set(initial),
        2 => s.cpu.HL.set(initial),
        3 => s.cpu.SP.set(initial),
    }

    step(&s.cpu);

    switch (which) {
        0 => try std.testing.expectEqual(expected, s.cpu.BC.getHiLo()),
        1 => try std.testing.expectEqual(expected, s.cpu.DE.getHiLo()),
        2 => try std.testing.expectEqual(expected, s.cpu.HL.getHiLo()),
        3 => try std.testing.expectEqual(expected, s.cpu.SP.getHiLo()),
    }

    try expectFlags(&s.cpu, 0, 0, 1, 1);
}

test "INC r16 (0x03/13/23/33) increments and wraps; flags unchanged" {
    // BC
    try testIncR16(0x03, 0, 0x1234, 0x1235);
    try testIncR16(0x03, 0, 0xFFFF, 0x0000);

    // DE
    try testIncR16(0x13, 1, 0x1234, 0x1235);
    try testIncR16(0x13, 1, 0xFFFF, 0x0000);

    // HL
    try testIncR16(0x23, 2, 0x1234, 0x1235);
    try testIncR16(0x23, 2, 0xFFFF, 0x0000);

    // SP
    try testIncR16(0x33, 3, 0x1234, 0x1235);
    try testIncR16(0x33, 3, 0xFFFF, 0x0000);
}

test "DEC r16 (0x0B/1B/2B/3B) decrements and wraps; flags unchanged" {
    // BC
    try testDecR16(0x0B, 0, 0x1235, 0x1234);
    try testDecR16(0x0B, 0, 0x0000, 0xFFFF);

    // DE
    try testDecR16(0x1B, 1, 0x1235, 0x1234);
    try testDecR16(0x1B, 1, 0x0000, 0xFFFF);

    // HL
    try testDecR16(0x2B, 2, 0x1235, 0x1234);
    try testDecR16(0x2B, 2, 0x0000, 0xFFFF);

    // SP
    try testDecR16(0x3B, 3, 0x1235, 0x1234);
    try testDecR16(0x3B, 3, 0x0000, 0xFFFF);
}

// ------------------------------------------------------------
// ADD HL, r16 (0x09,19,29,39)
// ------------------------------------------------------------

fn addHlFlags(hl: u16, r: u16) struct { h: u1, c: u1, res: u16 } {
    const res = hl +% r;
    const h = @as(u1, @intFromBool(((hl & 0x0FFF) + (r & 0x0FFF)) > 0x0FFF));
    const c = @as(u1, @intFromBool(@as(u32, hl) + @as(u32, r) > 0xFFFF));
    return .{ .h = h, .c = c, .res = res };
}

fn testAddHlR16(op: u8, which: u2, hl: u16, r: u16) !void {
    var s = setup();
    loadRom(&s.bus, &.{op});

    s.cpu.HL.set(hl);
    setFlags(&s.cpu, true, true, false, false); // Z should remain 1, N cleared by op

    switch (which) {
        0 => s.cpu.BC.set(r),
        1 => s.cpu.DE.set(r),
        2 => s.cpu.HL.set(r), // special: HL + HL; set HL to r then override? We want HL initial separate.
        3 => s.cpu.SP.set(r),
    }

    // If which==2 (HL), we need HL initial and operand both. So adjust:
    if (which == 2) {
        s.cpu.HL.set(hl);
        // use DE as temp? can't. We'll just set HL operand by copying to BC and use op 0x09? Not.
        // For HL+HL instruction (0x29), operand is HL itself.
        // So r should equal hl for this case.
    }

    step(&s.cpu);

    const f = addHlFlags(hl, if (which == 2) hl else r);

    try std.testing.expectEqual(f.res, s.cpu.HL.getHiLo());
    // Z unchanged (1)
    try std.testing.expectEqual(@as(u1, 1), s.cpu.get_z());
    // N cleared
    try std.testing.expectEqual(@as(u1, 0), s.cpu.get_n());
    try std.testing.expectEqual(f.h, s.cpu.get_h());
    try std.testing.expectEqual(f.c, s.cpu.get_c());
}

test "ADD HL, r16 (0x09/19/29/39) sets N=0, Z unchanged, H/C from bit11/15" {
    // No overflow: HL=0x1000 + BC=0x0234 -> 0x1234, H=0,C=0
    try testAddHlR16(0x09, 0, 0x1000, 0x0234);

    // Half-carry: HL=0x0F00 + DE=0x0200 -> H=1,C=0
    try testAddHlR16(0x19, 1, 0x0F00, 0x0200);

    // Carry: HL=0xF000 + HL=0x2000 -> C=1
    try testAddHlR16(0x29, 2, 0xF000, 0xF000);

    // Both: HL=0xFF00 + SP=0x0F00 -> H=1,C=1
    try testAddHlR16(0x39, 3, 0xFF00, 0x0F00);
}

// ------------------------------------------------------------
// INC r8 (0x04..0x3C) and DEC r8 (0x05..0x3D)
// ------------------------------------------------------------

fn inc8Expected(v: u8) struct { res: u8, z: u1, n: u1, h: u1 } {
    const res = v +% 1;
    const z: u1 = @intFromBool(res == 0);
    const n: u1 = 0;
    const h: u1 = @intFromBool(((v & 0x0F) + 1) > 0x0F);
    return .{ .res = res, .z = z, .n = n, .h = h };
}

fn dec8Expected(v: u8) struct { res: u8, z: u1, n: u1, h: u1 } {
    const res = v -% 1;
    const z: u1 = @intFromBool(res == 0);
    const n: u1 = 1;
    const h: u1 = @intFromBool((v & 0x0F) == 0); // borrow from bit4 when low nibble is 0
    return .{ .res = res, .z = z, .n = n, .h = h };
}

fn setR8(cpu: *Cpu, idx: u3, value: u8, bus: *Bus) void {
    switch (idx) {
        0 => cpu.BC.setHi(value),
        1 => cpu.BC.setLo(value),
        2 => cpu.DE.setHi(value),
        3 => cpu.DE.setLo(value),
        4 => cpu.HL.setHi(value),
        5 => cpu.HL.setLo(value),
        6 => {
            // [HL]
            const addr = cpu.HL.getHiLo();
            bus.write8(addr, value);
        },
        7 => cpu.AF.setHi(value),
    }
}

fn getR8(cpu: *Cpu, idx: u3, bus: *Bus) u8 {
    return switch (idx) {
        0 => cpu.BC.getHi(),
        1 => cpu.BC.getLo(),
        2 => cpu.DE.getHi(),
        3 => cpu.DE.getLo(),
        4 => cpu.HL.getHi(),
        5 => cpu.HL.getLo(),
        6 => bus.read8(cpu.HL.getHiLo()),
        7 => cpu.AF.getHi(),
    };
}

fn testIncR8(op: u8, idx: u3, initial: u8) !void {
    var s = setup();
    loadRom(&s.bus, &.{op});

    s.cpu.PC.set(0x0000);
    s.cpu.HL.set(0xC000);
    setR8(&s.cpu, idx, initial, &s.bus);

    // Carry must be unchanged; set it to 1 to verify.
    setFlags(&s.cpu, false, true, false, true);

    const e = inc8Expected(initial);

    step(&s.cpu);

    try std.testing.expectEqual(e.res, getR8(&s.cpu, idx, &s.bus));
    try std.testing.expectEqual(e.z, s.cpu.get_z());
    try std.testing.expectEqual(@as(u1, 0), s.cpu.get_n());
    try std.testing.expectEqual(e.h, s.cpu.get_h());
    try std.testing.expectEqual(@as(u1, 1), s.cpu.get_c()); // unchanged
}

fn testDecR8(op: u8, idx: u3, initial: u8) !void {
    var s = setup();
    loadRom(&s.bus, &.{op});

    s.cpu.PC.set(0x0000);
    s.cpu.HL.set(0xC000);
    setR8(&s.cpu, idx, initial, &s.bus);

    setFlags(&s.cpu, true, false, false, true);

    const e = dec8Expected(initial);

    step(&s.cpu);

    try std.testing.expectEqual(e.res, getR8(&s.cpu, idx, &s.bus));
    try std.testing.expectEqual(e.z, s.cpu.get_z());
    try std.testing.expectEqual(@as(u1, 1), s.cpu.get_n());
    try std.testing.expectEqual(e.h, s.cpu.get_h());
    try std.testing.expectEqual(@as(u1, 1), s.cpu.get_c()); // unchanged
}

test "INC r8 (0x04..0x3C) sets Z/H, clears N, preserves C" {
    const ops = [_]u8{ 0x04, 0x0C, 0x14, 0x1C, 0x24, 0x2C, 0x34, 0x3C };
    for (ops, 0..) |op, i| {
        const idx: u3 = @intCast(i);
        try testIncR8(op, idx, 0x12);
        try testIncR8(op, idx, 0x0F);
        try testIncR8(op, idx, 0xFF);
    }
}

test "DEC r8 (0x05..0x3D) sets Z/H, sets N, preserves C" {
    const ops = [_]u8{ 0x05, 0x0D, 0x15, 0x1D, 0x25, 0x2D, 0x35, 0x3D };
    for (ops, 0..) |op, i| {
        const idx: u3 = @intCast(i);
        try testDecR8(op, idx, 0x13);
        try testDecR8(op, idx, 0x10);
        try testDecR8(op, idx, 0x01);
        try testDecR8(op, idx, 0x00);
    }
}

// ------------------------------------------------------------
// LD r8, imm8 (0x06..0x3E)
// ------------------------------------------------------------

fn testLdR8Imm8(op: u8, idx: u3, imm: u8) !void {
    var s = setup();
    loadRom(&s.bus, &.{ op, imm });

    s.cpu.PC.set(0x0000);
    s.cpu.HL.set(0xC000);
    setFlags(&s.cpu, true, true, true, true);

    step(&s.cpu);

    try std.testing.expectEqual(imm, getR8(&s.cpu, idx, &s.bus));
    try expectFlags(&s.cpu, 1, 1, 1, 1);
    try std.testing.expectEqual(@as(u16, 0x0002), s.cpu.PC.getHiLo());
}

test "LD r8, imm8 (0x06..0x3E) loads immediate into register or [HL]" {
    const ops = [_]u8{ 0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x36, 0x3E };
    for (ops, 0..) |op, i| {
        const idx: u3 = @intCast(i);
        try testLdR8Imm8(op, idx, 0x00);
        try testLdR8Imm8(op, idx, 0xFF);
        try testLdR8Imm8(op, idx, 0x42);
    }
}

// ------------------------------------------------------------
// Accumulator rotates: RLCA, RRCA, RLA, RRA
// ------------------------------------------------------------

test "RLCA (0x07) rotates A left; Z=0,N=0,H=0,C=old bit7" {
    const cases = [_]struct { a: u8, res: u8, c: u1 }{
        .{ .a = 0x80, .res = 0x01, .c = 1 },
        .{ .a = 0x01, .res = 0x02, .c = 0 },
        .{ .a = 0x85, .res = 0x0B, .c = 1 },
    };

    for (cases) |tc| {
        var s = setup();
        loadRom(&s.bus, &.{0x07});

        s.cpu.AF.setHi(tc.a);
        setFlags(&s.cpu, true, true, true, false);

        step(&s.cpu);

        try std.testing.expectEqual(tc.res, s.cpu.AF.getHi());
        try expectFlags(&s.cpu, 0, 0, 0, tc.c);
    }
}

test "RRCA (0x0F) rotates A right; Z=0,N=0,H=0,C=old bit0" {
    const cases = [_]struct { a: u8, res: u8, c: u1 }{
        .{ .a = 0x01, .res = 0x80, .c = 1 },
        .{ .a = 0x02, .res = 0x01, .c = 0 },
        .{ .a = 0xA1, .res = 0xD0, .c = 1 },
    };

    for (cases) |tc| {
        var s = setup();
        loadRom(&s.bus, &.{0x0F});

        s.cpu.AF.setHi(tc.a);
        setFlags(&s.cpu, true, true, true, false);

        step(&s.cpu);

        try std.testing.expectEqual(tc.res, s.cpu.AF.getHi());
        try expectFlags(&s.cpu, 0, 0, 0, tc.c);
    }
}

test "RLA (0x17) rotates A left through carry; Z=0,N=0,H=0,C=old bit7" {
    const cases = [_]struct { a: u8, c_in: u1, res: u8, c_out: u1 }{
        .{ .a = 0x80, .c_in = 0, .res = 0x00, .c_out = 1 },
        .{ .a = 0x01, .c_in = 1, .res = 0x03, .c_out = 0 },
        .{ .a = 0x95, .c_in = 0, .res = 0x2A, .c_out = 1 },
    };

    for (cases) |tc| {
        var s = setup();
        loadRom(&s.bus, &.{0x17});

        s.cpu.AF.setHi(tc.a);
        setFlags(&s.cpu, true, true, true, tc.c_in == 1);

        step(&s.cpu);

        try std.testing.expectEqual(tc.res, s.cpu.AF.getHi());
        try expectFlags(&s.cpu, 0, 0, 0, tc.c_out);
    }
}

test "RRA (0x1F) rotates A right through carry; Z=0,N=0,H=0,C=old bit0" {
    const cases = [_]struct { a: u8, c_in: u1, res: u8, c_out: u1 }{
        .{ .a = 0x01, .c_in = 0, .res = 0x00, .c_out = 1 },
        .{ .a = 0x02, .c_in = 1, .res = 0x81, .c_out = 0 },
        .{ .a = 0x8A, .c_in = 1, .res = 0xC5, .c_out = 0 },
    };

    for (cases) |tc| {
        var s = setup();
        loadRom(&s.bus, &.{0x1F});

        s.cpu.AF.setHi(tc.a);
        setFlags(&s.cpu, true, true, true, tc.c_in == 1);

        step(&s.cpu);

        try std.testing.expectEqual(tc.res, s.cpu.AF.getHi());
        try expectFlags(&s.cpu, 0, 0, 0, tc.c_out);
    }
}

// ------------------------------------------------------------
// DAA (0x27) - per prompt: test after ADD and SUB situations.
// This test assumes your DAA implementation follows standard LR35902 rules.
// ------------------------------------------------------------

fn runDaaCase(a: u8, n: u1, h: u1, c: u1, expected_a: u8, expected_z: u1, expected_c: u1) !void {
    var s = setup();
    loadRom(&s.bus, &.{0x27});

    s.cpu.AF.setHi(a);
    // Set flags as if previous op already occurred.
    s.cpu.set_n(n == 1);
    s.cpu.set_h(h == 1);
    s.cpu.set_c(c == 1);
    s.cpu.set_z(false);

    step(&s.cpu);

    try std.testing.expectEqual(expected_a, s.cpu.AF.getHi());
    try std.testing.expectEqual(expected_z, s.cpu.get_z());
    try std.testing.expectEqual(n, s.cpu.get_n()); // N unchanged
    try std.testing.expectEqual(@as(u1, 0), s.cpu.get_h()); // H cleared
    try std.testing.expectEqual(expected_c, s.cpu.get_c());
}

test "DAA (0x27) after ADD cases" {
    // After ADD (N=0)
    try runDaaCase(0x09, 0, 0, 0, 0x09, 0, 0);
    try runDaaCase(0x0A, 0, 0, 0, 0x10, 0, 0);
    try runDaaCase(0x9A, 0, 0, 0, 0x00, 1, 1);
    try runDaaCase(0x0F, 0, 1, 0, 0x15, 0, 0);
    try runDaaCase(0xA0, 0, 0, 0, 0x00, 1, 1);
}

test "DAA (0x27) after SUB cases" {
    // After SUB (N=1)
    try runDaaCase(0x00, 1, 1, 0, 0xFA, 0, 0);
    try runDaaCase(0x00, 1, 0, 1, 0xA0, 0, 1);
}

// ------------------------------------------------------------
// CPL (0x2F), SCF (0x37), CCF (0x3F)
// ------------------------------------------------------------

test "CPL (0x2F) complements A; N=1,H=1; Z and C unchanged" {
    const cases = [_]struct { a: u8, res: u8 }{
        .{ .a = 0x00, .res = 0xFF },
        .{ .a = 0xFF, .res = 0x00 },
        .{ .a = 0xF0, .res = 0x0F },
    };

    for (cases) |tc| {
        var s = setup();
        loadRom(&s.bus, &.{0x2F});

        s.cpu.AF.setHi(tc.a);
        setFlags(&s.cpu, true, false, false, true);

        step(&s.cpu);

        try std.testing.expectEqual(tc.res, s.cpu.AF.getHi());
        try std.testing.expectEqual(@as(u1, 1), s.cpu.get_z());
        try std.testing.expectEqual(@as(u1, 1), s.cpu.get_n());
        try std.testing.expectEqual(@as(u1, 1), s.cpu.get_h());
        try std.testing.expectEqual(@as(u1, 1), s.cpu.get_c());
    }
}

test "SCF (0x37) sets carry; clears N,H; Z unchanged" {
    var s = setup();
    loadRom(&s.bus, &.{0x37});

    setFlags(&s.cpu, true, true, true, false);
    step(&s.cpu);

    try expectFlags(&s.cpu, 1, 0, 0, 1);
}

test "CCF (0x3F) toggles carry; clears N,H; Z unchanged" {
    // C=0 -> 1
    {
        var s = setup();
        loadRom(&s.bus, &.{0x3F});

        setFlags(&s.cpu, false, true, true, false);
        step(&s.cpu);

        try expectFlags(&s.cpu, 0, 0, 0, 1);
    }
    // C=1 -> 0
    {
        var s = setup();
        loadRom(&s.bus, &.{0x3F});

        setFlags(&s.cpu, false, true, true, true);
        step(&s.cpu);

        try expectFlags(&s.cpu, 0, 0, 0, 0);
    }
}

// ------------------------------------------------------------
// JR imm8 (0x18) and JR cond, imm8 (0x20,28,30,38)
// ------------------------------------------------------------

test "JR imm8 (0x18) relative jump uses signed offset from PC after imm read" {
    // Forward: PC=0x0100, offset=+5 -> PC=0x0107
    {
        var s = setup();
        loadRom(&s.bus, &.{ 0x18, 0x05 });

        s.cpu.PC.set(0x0100);
        // Mirror ROM at that offset by writing into rom_bank_0 at index 0x0100? In this harness,
        // fetch reads from bus at PC. If bus maps ROM 0x0000.., we must write at exact address.
        s.bus.rom_bank_0[0x0100] = 0x18;
        s.bus.rom_bank_0[0x0101] = 0x05;

        step(&s.cpu);
        try std.testing.expectEqual(@as(u16, 0x0107), s.cpu.PC.getHiLo());
    }

    // Backward: PC=0x0100, offset=-2 -> PC=0x0100 (loops to self after fetch)
    {
        var s = setup();
        s.bus.rom_bank_0[0x0100] = 0x18;
        s.bus.rom_bank_0[0x0101] = 0xFE; // -2

        s.cpu.PC.set(0x0100);
        step(&s.cpu);

        try std.testing.expectEqual(@as(u16, 0x0100), s.cpu.PC.getHiLo());
    }

    // Max forward: +127
    {
        var s = setup();
        s.bus.rom_bank_0[0x0100] = 0x18;
        s.bus.rom_bank_0[0x0101] = 0x7F;

        s.cpu.PC.set(0x0100);
        step(&s.cpu);

        try std.testing.expectEqual(@as(u16, 0x0181), s.cpu.PC.getHiLo());
    }

    // Max backward: -128
    {
        var s = setup();
        s.bus.rom_bank_0[0x0100] = 0x18;
        s.bus.rom_bank_0[0x0101] = 0x80;

        s.cpu.PC.set(0x0100);
        step(&s.cpu);

        try std.testing.expectEqual(@as(u16, 0x0082), s.cpu.PC.getHiLo());
    }
}

fn condTaken(cond: u2, z: u1, c: u1) bool {
    return switch (cond) {
        0 => z == 0, // NZ
        1 => z == 1, // Z
        2 => c == 0, // NC
        3 => c == 1, // C
    };
}

fn testJrCond(op: u8, cond: u2, z: u1, c: u1, off: u8) !void {
    var s = setup();
    s.bus.rom_bank_0[0x0100] = op;
    s.bus.rom_bank_0[0x0101] = off;

    s.cpu.PC.set(0x0100);
    setFlags(&s.cpu, z == 1, false, false, c == 1);

    step(&s.cpu);

    const taken = condTaken(cond, z, c);
    if (taken) {
        const base = @as(u16, 0x0102);
        const expected = addSpSigned(base, off);
        try std.testing.expectEqual(expected, s.cpu.PC.getHiLo());
    } else {
        try std.testing.expectEqual(@as(u16, 0x0102), s.cpu.PC.getHiLo());
    }
}

test "JR cond, imm8 (0x20/28/30/38) taken and not taken" {
    // NZ (0x20)
    try testJrCond(0x20, 0, 0, 0, 0x05);
    try testJrCond(0x20, 0, 1, 0, 0x05);

    // Z (0x28)
    try testJrCond(0x28, 1, 1, 0, 0x05);
    try testJrCond(0x28, 1, 0, 0, 0x05);

    // NC (0x30)
    try testJrCond(0x30, 2, 0, 0, 0xFE);
    try testJrCond(0x30, 2, 0, 1, 0xFE);

    // C (0x38)
    try testJrCond(0x38, 3, 0, 1, 0x7F);
    try testJrCond(0x38, 3, 0, 0, 0x7F);
}

// ------------------------------------------------------------
// Block 1: LD r8, r8 (0x40-0x7F except 0x76), HALT (0x76)
// ------------------------------------------------------------

fn ldOpcode(dest: u3, src: u3) u8 {
    // 01 ddd sss
    return 0x40 | (@as(u8, dest) << 3) | @as(u8, src);
}

fn testLdR8R8(dest: u3, src: u3) !void {
    // Exclude [HL],[HL] (0x76) here.
    var s = setup();
    const op = ldOpcode(dest, src);
    loadRom(&s.bus, &.{op});

    s.cpu.PC.set(0x0000);
    s.cpu.HL.set(0xC000);

    // Fill regs with recognizable values
    setR8(&s.cpu, 0, 0x10, &s.bus);
    setR8(&s.cpu, 1, 0x11, &s.bus);
    setR8(&s.cpu, 2, 0x12, &s.bus);
    setR8(&s.cpu, 3, 0x13, &s.bus);
    setR8(&s.cpu, 4, 0x14, &s.bus);
    setR8(&s.cpu, 5, 0x15, &s.bus);
    setR8(&s.cpu, 6, 0x99, &s.bus); // [HL]
    setR8(&s.cpu, 7, 0x17, &s.bus);

    setFlags(&s.cpu, true, true, true, true);

    const srcv = getR8(&s.cpu, src, &s.bus);

    step(&s.cpu);

    // destination equals source
    try std.testing.expectEqual(srcv, getR8(&s.cpu, dest, &s.bus));

    // flags unaffected
    try expectFlags(&s.cpu, 1, 1, 1, 1);
}

test "LD r8, r8 (0x40-0x7F excluding 0x76) all combinations" {
    var dest: u3 = 0;
    while (dest < 8) : (dest += 1) {
        var src: u3 = 0;
        while (src < 8) : (src += 1) {
            if (dest == 6 and src == 6) continue; // HALT
            try testLdR8R8(dest, src);
        }
    }
}

test "HALT (0x76) basic execution advances PC by 1" {
    var s = setup();
    loadRom(&s.bus, &.{0x76});

    s.cpu.PC.set(0x0000);
    step(&s.cpu);

    try std.testing.expectEqual(@as(u16, 0x0001), s.cpu.PC.getHiLo());
}

// ------------------------------------------------------------
// Block 2: ALU A,r8 (0x80-0xBF)
// ------------------------------------------------------------

fn aluGetOperand(cpu: *Cpu, bus: *Bus, idx: u3) u8 {
    return getR8(cpu, idx, bus);
}

fn runAddA(cpu: *Cpu, value: u8, carry_in: u8) void {
    const a = cpu.AF.getHi();
    const sum: u16 = @as(u16, a) + @as(u16, value) + @as(u16, carry_in);
    cpu.AF.setHi(@as(u8, @truncate(sum)));

    cpu.set_z(@as(u8, @truncate(sum)) == 0);
    cpu.set_n(false);
    cpu.set_h(halfCarryAdd8(a, value, carry_in));
    cpu.set_c(sum > 0xFF);
}

fn runSubA(cpu: *Cpu, value: u8, carry_in: u8) void {
    const a = cpu.AF.getHi();
    const sub: i16 = @as(i16, @intCast(a)) - @as(i16, @intCast(value)) - @as(i16, @intCast(carry_in));
    cpu.AF.setHi(@as(u8, @truncate(@as(u16, @bitCast(@as(i16, sub))))));

    const res = cpu.AF.getHi();
    cpu.set_z(res == 0);
    cpu.set_n(true);
    cpu.set_h(halfBorrowSub8(a, value, carry_in));
    cpu.set_c(borrowSub8(a, value, carry_in));
}

fn runAndA(cpu: *Cpu, value: u8) void {
    const res = cpu.AF.getHi() & value;
    cpu.AF.setHi(res);
    cpu.set_z(res == 0);
    cpu.set_n(false);
    cpu.set_h(true);
    cpu.set_c(false);
}

fn runXorA(cpu: *Cpu, value: u8) void {
    const res = cpu.AF.getHi() ^ value;
    cpu.AF.setHi(res);
    cpu.set_z(res == 0);
    cpu.set_n(false);
    cpu.set_h(false);
    cpu.set_c(false);
}

fn runOrA(cpu: *Cpu, value: u8) void {
    const res = cpu.AF.getHi() | value;
    cpu.AF.setHi(res);
    cpu.set_z(res == 0);
    cpu.set_n(false);
    cpu.set_h(false);
    cpu.set_c(false);
}

fn runCpA(cpu: *Cpu, value: u8) void {
    const a = cpu.AF.getHi();
    const sub: u8 = a -% value;
    cpu.set_z(sub == 0);
    cpu.set_n(true);
    cpu.set_h(halfBorrowSub8(a, value, 0));
    cpu.set_c(borrowSub8(a, value, 0));
    // A unchanged
}

fn testAluGroup(base: u8, op_kind: enum { add, adc, sub, sbc, and_, xor_, or_, cp }, idx: u3, a: u8, operand: u8, c_in: u1) !void {
    var s = setup();
    const op = base + @as(u8, idx);
    loadRom(&s.bus, &.{op});

    s.cpu.PC.set(0x0000);
    s.cpu.HL.set(0xC000);

    s.cpu.AF.setHi(a);
    setR8(&s.cpu, idx, operand, &s.bus);

    s.cpu.set_c(c_in == 1);
    s.cpu.set_z(false);
    s.cpu.set_n(false);
    s.cpu.set_h(false);

    // Execute real CPU instruction
    step(&s.cpu);

    // Compute expected with reference helpers
    var ref = setup();
    ref.cpu.AF.setHi(a);
    ref.cpu.set_c(c_in == 1);

    switch (op_kind) {
        .add => runAddA(&ref.cpu, operand, 0),
        .adc => runAddA(&ref.cpu, operand, @as(u8, c_in)),
        .sub => runSubA(&ref.cpu, operand, 0),
        .sbc => runSubA(&ref.cpu, operand, @as(u8, c_in)),
        .and_ => runAndA(&ref.cpu, operand),
        .xor_ => runXorA(&ref.cpu, operand),
        .or_ => runOrA(&ref.cpu, operand),
        .cp => runCpA(&ref.cpu, operand),
    }

    // Compare
    if (op_kind == .cp) {
        try std.testing.expectEqual(a, s.cpu.AF.getHi());
    } else {
        try std.testing.expectEqual(ref.cpu.AF.getHi(), s.cpu.AF.getHi());
    }

    try std.testing.expectEqual(ref.cpu.get_z(), s.cpu.get_z());
    try std.testing.expectEqual(ref.cpu.get_n(), s.cpu.get_n());
    try std.testing.expectEqual(ref.cpu.get_h(), s.cpu.get_h());
    try std.testing.expectEqual(ref.cpu.get_c(), s.cpu.get_c());
}

test "ADD A, r8 (0x80-0x87) all r8 and edge cases" {
    var idx: u3 = 0;
    while (idx < 8) : (idx += 1) {
        try testAluGroup(0x80, .add, idx, 0x10, 0x05, 0);
        try testAluGroup(0x80, .add, idx, 0x0F, 0x01, 0);
        try testAluGroup(0x80, .add, idx, 0xFF, 0x01, 0);
        try testAluGroup(0x80, .add, idx, 0xFF, 0xFF, 0);
    }
}

test "ADC A, r8 (0x88-0x8F) all r8 and carry cases" {
    var idx: u3 = 0;
    while (idx < 8) : (idx += 1) {
        try testAluGroup(0x88, .adc, idx, 0x10, 0x05, 0);
        try testAluGroup(0x88, .adc, idx, 0x10, 0x05, 1);
        try testAluGroup(0x88, .adc, idx, 0x0F, 0x00, 1);
        try testAluGroup(0x88, .adc, idx, 0xFF, 0x00, 1);
    }
}

test "SUB A, r8 (0x90-0x97) all r8 and borrow cases" {
    var idx: u3 = 0;
    while (idx < 8) : (idx += 1) {
        try testAluGroup(0x90, .sub, idx, 0x10, 0x05, 0);
        try testAluGroup(0x90, .sub, idx, 0x10, 0x01, 0);
        try testAluGroup(0x90, .sub, idx, 0x05, 0x10, 0);
        try testAluGroup(0x90, .sub, idx, 0x42, 0x42, 0);
    }
}

test "SBC A, r8 (0x98-0x9F) all r8 and carry borrow cases" {
    var idx: u3 = 0;
    while (idx < 8) : (idx += 1) {
        try testAluGroup(0x98, .sbc, idx, 0x10, 0x05, 0);
        try testAluGroup(0x98, .sbc, idx, 0x10, 0x05, 1);
        try testAluGroup(0x98, .sbc, idx, 0x10, 0x00, 1);
        try testAluGroup(0x98, .sbc, idx, 0x00, 0x00, 1);
    }
}

test "AND A, r8 (0xA0-0xA7) all r8 cases" {
    var idx: u3 = 0;
    while (idx < 8) : (idx += 1) {
        try testAluGroup(0xA0, .and_, idx, 0xFF, 0xFF, 0);
        try testAluGroup(0xA0, .and_, idx, 0xF0, 0x0F, 0);
        try testAluGroup(0xA0, .and_, idx, 0xAA, 0x55, 0);
    }
}

test "XOR A, r8 (0xA8-0xAF) all r8 cases" {
    var idx: u3 = 0;
    while (idx < 8) : (idx += 1) {
        // self xor case only meaningful when operand is A; but we still test for all.
        try testAluGroup(0xA8, .xor_, idx, 0x42, 0x42, 0);
        try testAluGroup(0xA8, .xor_, idx, 0xFF, 0xAA, 0);
    }
}

test "OR A, r8 (0xB0-0xB7) all r8 cases" {
    var idx: u3 = 0;
    while (idx < 8) : (idx += 1) {
        try testAluGroup(0xB0, .or_, idx, 0x00, 0x00, 0);
        try testAluGroup(0xB0, .or_, idx, 0xF0, 0x0F, 0);
    }
}

test "CP A, r8 (0xB8-0xBF) all r8 cases" {
    var idx: u3 = 0;
    while (idx < 8) : (idx += 1) {
        try testAluGroup(0xB8, .cp, idx, 0x42, 0x42, 0);
        try testAluGroup(0xB8, .cp, idx, 0x10, 0x20, 0);
        try testAluGroup(0xB8, .cp, idx, 0x20, 0x10, 0);
    }
}

// ------------------------------------------------------------
// Block 3: ALU A, imm8 (0xC6,CE,D6,DE,E6,EE,F6,FE)
// ------------------------------------------------------------

fn testAluImm(op: u8, kind: enum { add, adc, sub, sbc, and_, xor_, or_, cp }, a: u8, imm: u8, c_in: u1) !void {
    var s = setup();
    loadRom(&s.bus, &.{ op, imm });

    s.cpu.AF.setHi(a);
    s.cpu.set_c(c_in == 1);
    step(&s.cpu);

    var ref = setup();
    ref.cpu.AF.setHi(a);
    ref.cpu.set_c(c_in == 1);

    switch (kind) {
        .add => runAddA(&ref.cpu, imm, 0),
        .adc => runAddA(&ref.cpu, imm, @as(u8, c_in)),
        .sub => runSubA(&ref.cpu, imm, 0),
        .sbc => runSubA(&ref.cpu, imm, @as(u8, c_in)),
        .and_ => runAndA(&ref.cpu, imm),
        .xor_ => runXorA(&ref.cpu, imm),
        .or_ => runOrA(&ref.cpu, imm),
        .cp => runCpA(&ref.cpu, imm),
    }

    if (kind == .cp) {
        try std.testing.expectEqual(a, s.cpu.AF.getHi());
    } else {
        try std.testing.expectEqual(ref.cpu.AF.getHi(), s.cpu.AF.getHi());
    }

    try std.testing.expectEqual(ref.cpu.get_z(), s.cpu.get_z());
    try std.testing.expectEqual(ref.cpu.get_n(), s.cpu.get_n());
    try std.testing.expectEqual(ref.cpu.get_h(), s.cpu.get_h());
    try std.testing.expectEqual(ref.cpu.get_c(), s.cpu.get_c());

    try std.testing.expectEqual(@as(u16, 0x0002), s.cpu.PC.getHiLo());
}

test "ADD/ADC/SUB/SBC/AND/XOR/OR/CP A, imm8 opcodes" {
    // ADD A,imm8
    try testAluImm(0xC6, .add, 0x10, 0x05, 0);
    try testAluImm(0xC6, .add, 0xFF, 0x01, 0);

    // ADC
    try testAluImm(0xCE, .adc, 0x10, 0x05, 1);

    // SUB
    try testAluImm(0xD6, .sub, 0x10, 0x05, 0);

    // SBC
    try testAluImm(0xDE, .sbc, 0x00, 0x00, 1);

    // AND
    try testAluImm(0xE6, .and_, 0xF0, 0x0F, 0);

    // XOR
    try testAluImm(0xEE, .xor_, 0x42, 0x42, 0);

    // OR
    try testAluImm(0xF6, .or_, 0xF0, 0x0F, 0);

    // CP
    try testAluImm(0xFE, .cp, 0x10, 0x20, 0);
}

// ------------------------------------------------------------
// RET/RETI and JP/CALL/RST
// ------------------------------------------------------------

fn writeStackReturn(bus: *Bus, sp: u16, addr: u16) void {
    // low at [SP], high at [SP+1]
    bus.write8(sp, u16lo(addr));
    bus.write8(sp +% 1, u16hi(addr));
}

fn pushReturn(bus: *Bus, sp: u16, addr: u16) u16 {
    // Push order: high to [SP-1], low to [SP-2]
    const sp1 = sp -% 1;
    const sp2 = sp -% 2;
    bus.write8(sp1, u16hi(addr));
    bus.write8(sp2, u16lo(addr));
    return sp2;
}

test "RET (0xC9) pops PC from stack and SP increases by 2" {
    var s = setup();
    loadRom(&s.bus, &.{0xC9});

    s.cpu.SP.set(0xD000);
    writeStackReturn(&s.bus, 0xD000, 0x1234);

    step(&s.cpu);

    try std.testing.expectEqual(@as(u16, 0x1234), s.cpu.PC.getHiLo());
    try std.testing.expectEqual(@as(u16, 0xD002), s.cpu.SP.getHiLo());
}

fn testRetCond(op: u8, z: u1, c: u1, taken: bool) !void {
    var s = setup();
    loadRom(&s.bus, &.{op});

    s.cpu.SP.set(0xD000);
    writeStackReturn(&s.bus, 0xD000, 0x5678);

    setFlags(&s.cpu, z == 1, false, false, c == 1);

    step(&s.cpu);

    if (taken) {
        try std.testing.expectEqual(@as(u16, 0x5678), s.cpu.PC.getHiLo());
        try std.testing.expectEqual(@as(u16, 0xD002), s.cpu.SP.getHiLo());
    } else {
        try std.testing.expectEqual(@as(u16, 0x0001), s.cpu.PC.getHiLo());
        try std.testing.expectEqual(@as(u16, 0xD000), s.cpu.SP.getHiLo());
    }
}

test "RET cond (0xC0,C8,D0,D8) taken and not taken" {
    // NZ
    try testRetCond(0xC0, 0, 0, true);
    try testRetCond(0xC0, 1, 0, false);
    // Z
    try testRetCond(0xC8, 1, 0, true);
    try testRetCond(0xC8, 0, 0, false);
    // NC
    try testRetCond(0xD0, 0, 0, true);
    try testRetCond(0xD0, 0, 1, false);
    // C
    try testRetCond(0xD8, 0, 1, true);
    try testRetCond(0xD8, 0, 0, false);
}

test "RETI (0xD9) pops PC and sets IME=1" {
    var s = setup();
    loadRom(&s.bus, &.{0xD9});

    s.cpu.SP.set(0xD000);
    writeStackReturn(&s.bus, 0xD000, 0x9ABC);
    s.cpu.IME = false;

    step(&s.cpu);

    try std.testing.expectEqual(@as(u16, 0x9ABC), s.cpu.PC.getHiLo());
    try std.testing.expectEqual(@as(u16, 0xD002), s.cpu.SP.getHiLo());
    try std.testing.expectEqual(true, s.cpu.IME);
}

// JP cond, imm16 / JP imm16 / JP HL
fn testJpImm(op: u8, z: u1, c: u1, cond: ?u2, target: u16, taken: bool) !void {
    var s = setup();
    loadRom(&s.bus, &.{ op, u16lo(target), u16hi(target) });

    setFlags(&s.cpu, z == 1, false, false, c == 1);

    step(&s.cpu);

    if (cond == null) {
        try std.testing.expectEqual(target, s.cpu.PC.getHiLo());
    } else {
        if (taken) {
            try std.testing.expectEqual(target, s.cpu.PC.getHiLo());
        } else {
            try std.testing.expectEqual(@as(u16, 0x0003), s.cpu.PC.getHiLo());
        }
    }
}

test "JP imm16 (0xC3) jumps to target" {
    try testJpImm(0xC3, 0, 0, null, 0x0000, true);
    try testJpImm(0xC3, 0, 0, null, 0x8000, true);
    try testJpImm(0xC3, 0, 0, null, 0xFFFF, true);
}

test "JP cond, imm16 (0xC2,CA,D2,DA) taken and not taken" {
    // NZ
    try testJpImm(0xC2, 0, 0, 0, 0x1234, true);
    try testJpImm(0xC2, 1, 0, 0, 0x1234, false);

    // Z
    try testJpImm(0xCA, 1, 0, 1, 0x1234, true);
    try testJpImm(0xCA, 0, 0, 1, 0x1234, false);

    // NC
    try testJpImm(0xD2, 0, 0, 2, 0x1234, true);
    try testJpImm(0xD2, 0, 1, 2, 0x1234, false);

    // C
    try testJpImm(0xDA, 0, 1, 3, 0x1234, true);
    try testJpImm(0xDA, 0, 0, 3, 0x1234, false);
}

test "JP HL (0xE9) sets PC=HL" {
    var s = setup();
    loadRom(&s.bus, &.{0xE9});

    s.cpu.HL.set(0xBEEF);
    s.cpu.PC.set(0x0000);

    step(&s.cpu);

    try std.testing.expectEqual(@as(u16, 0xBEEF), s.cpu.PC.getHiLo());
    try std.testing.expectEqual(@as(u16, 0xBEEF), s.cpu.HL.getHiLo());
}

// CALL cond, imm16 / CALL imm16
fn testCall(op: u8, z: u1, c: u1, cond: ?u2, target: u16, taken: bool) !void {
    var s = setup();
    loadRom(&s.bus, &.{ op, u16lo(target), u16hi(target) });

    s.cpu.SP.set(0xD000);
    s.cpu.PC.set(0x0000);
    setFlags(&s.cpu, z == 1, false, false, c == 1);

    step(&s.cpu);

    if (cond == null or taken) {
        // return address should be 0x0003
        try std.testing.expectEqual(@as(u16, 0xCFFE), s.cpu.SP.getHiLo());
        try std.testing.expectEqual(target, s.cpu.PC.getHiLo());
        // high at [SP+1], low at [SP]
        try std.testing.expectEqual(@as(u8, 0x00), s.bus.read8(0xCFFF)); // high
        try std.testing.expectEqual(@as(u8, 0x03), s.bus.read8(0xCFFE)); // low
    } else {
        try std.testing.expectEqual(@as(u16, 0xD000), s.cpu.SP.getHiLo());
        try std.testing.expectEqual(@as(u16, 0x0003), s.cpu.PC.getHiLo());
    }
}

test "CALL imm16 (0xCD) pushes return address and jumps" {
    try testCall(0xCD, 0, 0, null, 0x1234, true);
}

test "CALL cond, imm16 (0xC4,CC,D4,DC) taken and not taken" {
    // NZ
    try testCall(0xC4, 0, 0, 0, 0x1234, true);
    try testCall(0xC4, 1, 0, 0, 0x1234, false);

    // Z
    try testCall(0xCC, 1, 0, 1, 0x1234, true);
    try testCall(0xCC, 0, 0, 1, 0x1234, false);

    // NC
    try testCall(0xD4, 0, 0, 2, 0x1234, true);
    try testCall(0xD4, 0, 1, 2, 0x1234, false);

    // C
    try testCall(0xDC, 0, 1, 3, 0x1234, true);
    try testCall(0xDC, 0, 0, 3, 0x1234, false);
}

// RST tgt3 (0xC7,CF,D7,DF,E7,EF,F7,FF)
fn rstTarget(op: u8) u16 {
    const tgt3 = (op >> 3) & 0x07;
    return @as(u16, tgt3) * 8;
}

test "RST tgt3 (0xC7..0xFF) pushes return and jumps to fixed vector" {
    const ops = [_]u8{ 0xC7, 0xCF, 0xD7, 0xDF, 0xE7, 0xEF, 0xF7, 0xFF };
    for (ops) |op| {
        var s = setup();
        loadRom(&s.bus, &.{op});

        s.cpu.SP.set(0xD000);
        s.cpu.PC.set(0x0000);

        step(&s.cpu);

        const target = rstTarget(op);
        try std.testing.expectEqual(target, s.cpu.PC.getHiLo());
        try std.testing.expectEqual(@as(u16, 0xCFFE), s.cpu.SP.getHiLo());
        // Return address is 0x0001
        try std.testing.expectEqual(@as(u8, 0x00), s.bus.read8(0xCFFF));
        try std.testing.expectEqual(@as(u8, 0x01), s.bus.read8(0xCFFE));
    }
}

// ------------------------------------------------------------
// POP r16stk (0xC1,D1,E1,F1) and PUSH r16stk (0xC5,D5,E5,F5)
// ------------------------------------------------------------

fn testPop(op: u8, which: u2, value: u16) !void {
    var s = setup();
    loadRom(&s.bus, &.{op});

    s.cpu.SP.set(0xD000);
    writeStackReturn(&s.bus, 0xD000, value);

    // Pre-set flags to something else for AF case check.
    setFlags(&s.cpu, false, false, false, false);

    step(&s.cpu);

    try std.testing.expectEqual(@as(u16, 0xD002), s.cpu.SP.getHiLo());

    switch (which) {
        0 => try std.testing.expectEqual(value, s.cpu.BC.getHiLo()),
        1 => try std.testing.expectEqual(value, s.cpu.DE.getHiLo()),
        2 => try std.testing.expectEqual(value, s.cpu.HL.getHiLo()),
        3 => {
            // POP AF: flags from low byte bits 7..4
            try std.testing.expectEqual(u16hi(value), s.cpu.AF.getHi());

            const f = u16lo(value);
            try std.testing.expectEqual(@as(u1, @intFromBool((f & 0x80) != 0)), s.cpu.get_z());
            try std.testing.expectEqual(@as(u1, @intFromBool((f & 0x40) != 0)), s.cpu.get_n());
            try std.testing.expectEqual(@as(u1, @intFromBool((f & 0x20) != 0)), s.cpu.get_h());
            try std.testing.expectEqual(@as(u1, @intFromBool((f & 0x10) != 0)), s.cpu.get_c());
        },
    }
}

test "POP r16stk (0xC1,D1,E1,F1) pops little-endian and SP+=2; POP AF extracts flags" {
    try testPop(0xC1, 0, 0x1234);
    try testPop(0xD1, 1, 0xABCD);
    try testPop(0xE1, 2, 0x0F0F);

    // POP AF with different flag patterns
    try testPop(0xF1, 3, 0x5600); // all flags clear
    try testPop(0xF1, 3, 0x56F0); // Z,N,H,C all set (bits 7..4)
    try testPop(0xF1, 3, 0x5680); // Z only
    try testPop(0xF1, 3, 0x5640); // N only
    try testPop(0xF1, 3, 0x5620); // H only
    try testPop(0xF1, 3, 0x5610); // C only
}

fn testPush(op: u8, which: u2, value: u16) !void {
    var s = setup();
    loadRom(&s.bus, &.{op});

    s.cpu.SP.set(0xD000);

    switch (which) {
        0 => s.cpu.BC.set(value),
        1 => s.cpu.DE.set(value),
        2 => s.cpu.HL.set(value),
        3 => {
            // AF packs flags in low byte bits 7..4
            s.cpu.AF.setHi(u16hi(value));
            const f = u16lo(value);
            s.cpu.set_z((f & 0x80) != 0);
            s.cpu.set_n((f & 0x40) != 0);
            s.cpu.set_h((f & 0x20) != 0);
            s.cpu.set_c((f & 0x10) != 0);
        },
    }

    step(&s.cpu);

    try std.testing.expectEqual(@as(u16, 0xCFFE), s.cpu.SP.getHiLo());
    // High at [SP+1], low at [SP]
    try std.testing.expectEqual(u16lo(value), s.bus.read8(0xCFFE));
    try std.testing.expectEqual(u16hi(value), s.bus.read8(0xCFFF));
}

test "PUSH r16stk (0xC5,D5,E5,F5) pushes high then low and SP-=2; PUSH AF packs flags" {
    try testPush(0xC5, 0, 0x1234);
    try testPush(0xD5, 1, 0xABCD);
    try testPush(0xE5, 2, 0x0F0F);

    // AF with flags
    try testPush(0xF5, 3, 0x5600);
    try testPush(0xF5, 3, 0x56F0);
}

// ------------------------------------------------------------
// LDH / LD absolute (I/O + imm16) (0xE0,E2,EA,F0,F2,FA)
// ------------------------------------------------------------

test "LDH [C], A (0xE2) writes A to 0xFF00+C" {
    var s = setup();
    loadRom(&s.bus, &.{0xE2});

    s.cpu.BC.setLo(0x10);
    s.cpu.AF.setHi(0x77);

    step(&s.cpu);

    try std.testing.expectEqual(@as(u8, 0x77), s.bus.read8(0xFF10));
}

test "LDH [imm8], A (0xE0) writes A to 0xFF00+imm8" {
    var s = setup();
    loadRom(&s.bus, &.{ 0xE0, 0x42 });

    s.cpu.AF.setHi(0x99);
    step(&s.cpu);

    try std.testing.expectEqual(@as(u8, 0x99), s.bus.read8(0xFF42));
}

test "LD [imm16], A (0xEA) writes A to absolute address" {
    var s = setup();
    loadRom(&s.bus, &.{ 0xEA, 0x00, 0xC0 }); // 0xC000

    s.cpu.AF.setHi(0x55);
    step(&s.cpu);

    try std.testing.expectEqual(@as(u8, 0x55), s.bus.read8(0xC000));
}

test "LDH A, [C] (0xF2) reads A from 0xFF00+C" {
    var s = setup();
    loadRom(&s.bus, &.{0xF2});

    s.cpu.BC.setLo(0xFF);
    s.bus.write8(0xFFFF, 0x33);

    step(&s.cpu);

    try std.testing.expectEqual(@as(u8, 0x33), s.cpu.AF.getHi());
}

test "LDH A, [imm8] (0xF0) reads A from 0xFF00+imm8" {
    var s = setup();
    loadRom(&s.bus, &.{ 0xF0, 0x00 });

    s.bus.write8(0xFF00, 0x44);
    step(&s.cpu);

    try std.testing.expectEqual(@as(u8, 0x44), s.cpu.AF.getHi());
}

test "LD A, [imm16] (0xFA) reads A from absolute address" {
    var s = setup();
    loadRom(&s.bus, &.{ 0xFA, 0x00, 0xC0 });

    s.bus.write8(0xC000, 0x88);
    step(&s.cpu);

    try std.testing.expectEqual(@as(u8, 0x88), s.cpu.AF.getHi());
}

// ------------------------------------------------------------
// ADD SP, imm8 (0xE8), LD HL, SP+imm8 (0xF8), LD SP, HL (0xF9)
// ------------------------------------------------------------

fn addSpFlags(sp: u16, imm: u8) struct { res: u16, h: u1, c: u1 } {
    const off: i8 = i8FromU8(imm);
    const res = @as(u16, @intCast(@as(i32, @intCast(sp)) + @as(i32, off)));

    // Flags based on low byte only
    const lo = @as(u8, @truncate(sp));
    const uoff = imm;
    const h = @as(u1, @intFromBool(((lo & 0x0F) + (uoff & 0x0F)) > 0x0F));
    const c = @as(u1, @intFromBool(@as(u16, lo) + @as(u16, uoff) > 0xFF));
    return .{ .res = res, .h = h, .c = c };
}

test "ADD SP, imm8 (0xE8) adds signed and sets flags from low byte; Z=0,N=0" {
    const cases = [_]struct { sp: u16, imm: u8 }{
        .{ .sp = 0xFFF0, .imm = 0x10 },
        .{ .sp = 0x0010, .imm = 0xF0 }, // -16
        .{ .sp = 0xFF0F, .imm = 0x01 },
        .{ .sp = 0xFFFF, .imm = 0x01 },
    };

    for (cases) |tc| {
        var s = setup();
        loadRom(&s.bus, &.{ 0xE8, tc.imm });

        s.cpu.SP.set(tc.sp);
        step(&s.cpu);

        const f = addSpFlags(tc.sp, tc.imm);

        try std.testing.expectEqual(f.res, s.cpu.SP.getHiLo());
        try expectFlags(&s.cpu, 0, 0, f.h, f.c);
    }
}

test "LD HL, SP+imm8 (0xF8) stores result in HL; SP unchanged; flags like ADD SP" {
    var s = setup();
    loadRom(&s.bus, &.{ 0xF8, 0x10 });

    s.cpu.SP.set(0xFFF0);
    step(&s.cpu);

    const f = addSpFlags(0xFFF0, 0x10);
    try std.testing.expectEqual(f.res, s.cpu.HL.getHiLo());
    try std.testing.expectEqual(@as(u16, 0xFFF0), s.cpu.SP.getHiLo());
    try expectFlags(&s.cpu, 0, 0, f.h, f.c);
}

test "LD SP, HL (0xF9) copies HL to SP; flags unaffected" {
    var s = setup();
    loadRom(&s.bus, &.{0xF9});

    s.cpu.HL.set(0xBEEF);
    setFlags(&s.cpu, true, true, true, false);

    step(&s.cpu);

    try std.testing.expectEqual(@as(u16, 0xBEEF), s.cpu.SP.getHiLo());
    try expectFlags(&s.cpu, 1, 1, 1, 0);
}

// ------------------------------------------------------------
// DI (0xF3) / EI (0xFB)
// ------------------------------------------------------------

test "DI (0xF3) sets IME=0" {
    var s = setup();
    loadRom(&s.bus, &.{0xF3});

    s.cpu.IME = true;
    step(&s.cpu);
    try std.testing.expectEqual(false, s.cpu.IME);

    // repeat
    s = setup();
    loadRom(&s.bus, &.{0xF3});
    s.cpu.IME = false;
    step(&s.cpu);
    try std.testing.expectEqual(false, s.cpu.IME);
}

test "EI (0xFB) sets IME=1" {
    var s = setup();
    loadRom(&s.bus, &.{0xFB});

    s.cpu.IME = false;
    step(&s.cpu);
    try std.testing.expectEqual(true, s.cpu.IME);

    // repeat
    s = setup();
    loadRom(&s.bus, &.{0xFB});
    s.cpu.IME = true;
    step(&s.cpu);
    try std.testing.expectEqual(true, s.cpu.IME);
}

// ------------------------------------------------------------
// Prefix CB (0xCB) instructions
// ------------------------------------------------------------

fn stepCb(cpu: *Cpu) void {
    const op = cpu.fetch();
    cpu.decode_execute(op);
}

fn runCb(bus: *Bus, cpu: *Cpu, cbop: u8) void {
    bus.rom_bank_0[0] = 0xCB;
    bus.rom_bank_0[1] = cbop;
    cpu.PC.set(0);
    const p = cpu.fetch();
    cpu.decode_execute(p); // should handle prefix and fetch cbop internally
}

fn rlc(v: u8) struct { res: u8, c: u1, z: u1 } {
    const c = @as(u1, @intFromBool((v & 0x80) != 0));
    const res = (v << 1) | (v >> 7);
    return .{ .res = res, .c = c, .z = @intFromBool(res == 0) };
}
fn rrc(v: u8) struct { res: u8, c: u1, z: u1 } {
    const c = @as(u1, @intFromBool((v & 0x01) != 0));
    const res = (v >> 1) | (v << 7);
    return .{ .res = res, .c = c, .z = @intFromBool(res == 0) };
}
fn rl(v: u8, c_in: u1) struct { res: u8, c: u1, z: u1 } {
    const c = @as(u1, @intFromBool((v & 0x80) != 0));
    const res = (v << 1) | @as(u8, c_in);
    return .{ .res = res, .c = c, .z = @intFromBool(res == 0) };
}
fn rr(v: u8, c_in: u1) struct { res: u8, c: u1, z: u1 } {
    const c = @as(u1, @intFromBool((v & 0x01) != 0));
    const res = (v >> 1) | (@as(u8, c_in) << 7);
    return .{ .res = res, .c = c, .z = @intFromBool(res == 0) };
}
fn sla(v: u8) struct { res: u8, c: u1, z: u1 } {
    const c = @as(u1, @intFromBool((v & 0x80) != 0));
    const res = v << 1;
    return .{ .res = res, .c = c, .z = @intFromBool(res == 0) };
}
fn sra(v: u8) struct { res: u8, c: u1, z: u1 } {
    const c = @as(u1, @intFromBool((v & 0x01) != 0));
    const msb = v & 0x80;
    const res = (v >> 1) | msb;
    return .{ .res = res, .c = c, .z = @intFromBool(res == 0) };
}
fn srl(v: u8) struct { res: u8, c: u1, z: u1 } {
    const c = @as(u1, @intFromBool((v & 0x01) != 0));
    const res = v >> 1;
    return .{ .res = res, .c = c, .z = @intFromBool(res == 0) };
}
fn swap(v: u8) struct { res: u8, z: u1 } {
    const res = (v << 4) | (v >> 4);
    return .{ .res = res, .z = @intFromBool(res == 0) };
}

fn cbOpcode(base: u8, idx: u3) u8 {
    return base + @as(u8, idx);
}

fn testCbUnary(base: u8, idx: u3, initial: u8, kind: enum { rlc, rrc, rl, rr, sla, sra, srl, swap }) !void {
    var s = setup();
    s.cpu.HL.set(0xC000);
    setR8(&s.cpu, idx, initial, &s.bus);

    // For RL/RR, test with carry-in=1 also in separate calls.
    s.cpu.set_c(true);

    // Run CB prefixed
    s.bus.rom_bank_0[0] = 0xCB;
    s.bus.rom_bank_0[1] = cbOpcode(base, idx);
    s.cpu.PC.set(0);
    step(&s.cpu); // prefix handling

    // Compute expected
    var exp_res: u8 = 0;
    var exp_z: u1 = 0;
    var exp_c: u1 = 0;

    switch (kind) {
        .rlc => {
            const r = rlc(initial);
            exp_res = r.res;
            exp_z = r.z;
            exp_c = r.c;
        },
        .rrc => {
            const r = rrc(initial);
            exp_res = r.res;
            exp_z = r.z;
            exp_c = r.c;
        },
        .rl => {
            const r = rl(initial, 1);
            exp_res = r.res;
            exp_z = r.z;
            exp_c = r.c;
        },
        .rr => {
            const r = rr(initial, 1);
            exp_res = r.res;
            exp_z = r.z;
            exp_c = r.c;
        },
        .sla => {
            const r = sla(initial);
            exp_res = r.res;
            exp_z = r.z;
            exp_c = r.c;
        },
        .sra => {
            const r = sra(initial);
            exp_res = r.res;
            exp_z = r.z;
            exp_c = r.c;
        },
        .srl => {
            const r = srl(initial);
            exp_res = r.res;
            exp_z = r.z;
            exp_c = r.c;
        },
        .swap => {
            const r = swap(initial);
            exp_res = r.res;
            exp_z = r.z;
            exp_c = 0;
        },
    }

    try std.testing.expectEqual(exp_res, getR8(&s.cpu, idx, &s.bus));
    try std.testing.expectEqual(exp_z, s.cpu.get_z());
    try std.testing.expectEqual(@as(u1, 0), s.cpu.get_n());
    try std.testing.expectEqual(@as(u1, 0), s.cpu.get_h());
    try std.testing.expectEqual(exp_c, s.cpu.get_c());
}

test "CB RLC r8 (0x00-0x07) all r8 and cases" {
    var idx: u3 = 0;
    while (idx < 8) : (idx += 1) {
        try testCbUnary(0x00, idx, 0x00, .rlc);
        try testCbUnary(0x00, idx, 0x80, .rlc);
        try testCbUnary(0x00, idx, 0x85, .rlc);
    }
}

test "CB RRC r8 (0x08-0x0F) all r8 and cases" {
    var idx: u3 = 0;
    while (idx < 8) : (idx += 1) {
        try testCbUnary(0x08, idx, 0x00, .rrc);
        try testCbUnary(0x08, idx, 0x01, .rrc);
        try testCbUnary(0x08, idx, 0xA1, .rrc);
    }
}

test "CB RL r8 (0x10-0x17) all r8 and cases (carry-in=1)" {
    var idx: u3 = 0;
    while (idx < 8) : (idx += 1) {
        try testCbUnary(0x10, idx, 0x80, .rl);
        try testCbUnary(0x10, idx, 0x11, .rl);
    }
}

test "CB RR r8 (0x18-0x1F) all r8 and cases (carry-in=1)" {
    var idx: u3 = 0;
    while (idx < 8) : (idx += 1) {
        try testCbUnary(0x18, idx, 0x01, .rr);
        try testCbUnary(0x18, idx, 0x80, .rr);
    }
}

test "CB SLA r8 (0x20-0x27) all r8 and cases" {
    var idx: u3 = 0;
    while (idx < 8) : (idx += 1) {
        try testCbUnary(0x20, idx, 0x80, .sla);
        try testCbUnary(0x20, idx, 0xFF, .sla);
        try testCbUnary(0x20, idx, 0x01, .sla);
    }
}

test "CB SRA r8 (0x28-0x2F) all r8 and cases" {
    var idx: u3 = 0;
    while (idx < 8) : (idx += 1) {
        try testCbUnary(0x28, idx, 0x7F, .sra);
        try testCbUnary(0x28, idx, 0x80, .sra);
        try testCbUnary(0x28, idx, 0x01, .sra);
    }
}

test "CB SWAP r8 (0x30-0x37) all r8 and cases" {
    var idx: u3 = 0;
    while (idx < 8) : (idx += 1) {
        try testCbUnary(0x30, idx, 0x12, .swap);
        try testCbUnary(0x30, idx, 0xF0, .swap);
        try testCbUnary(0x30, idx, 0x00, .swap);
    }
}

test "CB SRL r8 (0x38-0x3F) all r8 and cases" {
    var idx: u3 = 0;
    while (idx < 8) : (idx += 1) {
        try testCbUnary(0x38, idx, 0x80, .srl);
        try testCbUnary(0x38, idx, 0xFF, .srl);
        try testCbUnary(0x38, idx, 0x01, .srl);
    }
}

// BIT/RES/SET
fn testCbBit(bit: u3, idx: u3, value: u8) !void {
    var s = setup();
    s.cpu.HL.set(0xC000);
    setR8(&s.cpu, idx, value, &s.bus);

    // C should remain unchanged
    s.cpu.set_c(true);

    const cbop: u8 = 0x40 | (@as(u8, bit) << 3) | @as(u8, idx);
    s.bus.rom_bank_0[0] = 0xCB;
    s.bus.rom_bank_0[1] = cbop;
    s.cpu.PC.set(0);
    step(&s.cpu);

    const bit_set = (value & (@as(u8, 1) << bit)) != 0;
    const z: u1 = @intFromBool(!bit_set);

    try std.testing.expectEqual(z, s.cpu.get_z());
    try std.testing.expectEqual(@as(u1, 0), s.cpu.get_n());
    try std.testing.expectEqual(@as(u1, 1), s.cpu.get_h());
    try std.testing.expectEqual(@as(u1, 1), s.cpu.get_c()); // unchanged
    // operand unchanged
    try std.testing.expectEqual(value, getR8(&s.cpu, idx, &s.bus));
}

fn testCbRes(bit: u3, idx: u3, value: u8) !void {
    var s = setup();
    s.cpu.HL.set(0xC000);
    setR8(&s.cpu, idx, value, &s.bus);

    setFlags(&s.cpu, true, true, true, true);

    const cbop: u8 = 0x80 | (@as(u8, bit) << 3) | @as(u8, idx);
    s.bus.rom_bank_0[0] = 0xCB;
    s.bus.rom_bank_0[1] = cbop;
    s.cpu.PC.set(0);
    step(&s.cpu);

    const expected = value & ~(@as(u8, 1) << bit);
    try std.testing.expectEqual(expected, getR8(&s.cpu, idx, &s.bus));
    // flags unchanged
    try expectFlags(&s.cpu, 1, 1, 1, 1);
}

fn testCbSet(bit: u3, idx: u3, value: u8) !void {
    var s = setup();
    s.cpu.HL.set(0xC000);
    setR8(&s.cpu, idx, value, &s.bus);

    setFlags(&s.cpu, false, false, false, false);

    const cbop: u8 = 0xC0 | (@as(u8, bit) << 3) | @as(u8, idx);
    s.bus.rom_bank_0[0] = 0xCB;
    s.bus.rom_bank_0[1] = cbop;
    s.cpu.PC.set(0);
    step(&s.cpu);

    const expected = value | (@as(u8, 1) << bit);
    try std.testing.expectEqual(expected, getR8(&s.cpu, idx, &s.bus));
    try expectFlags(&s.cpu, 0, 0, 0, 0);
}

test "CB BIT b,r8 (0x40-0x7F) all bits and r8" {
    var bit: u3 = 0;
    while (bit < 8) : (bit += 1) {
        var idx: u3 = 0;
        while (idx < 8) : (idx += 1) {
            // bit set
            try testCbBit(bit, idx, @as(u8, 1) << bit);
            // bit clear
            try testCbBit(bit, idx, 0x00);
        }
    }
}

test "CB RES b,r8 (0x80-0xBF) all bits and r8" {
    var bit: u3 = 0;
    while (bit < 8) : (bit += 1) {
        var idx: u3 = 0;
        while (idx < 8) : (idx += 1) {
            try testCbRes(bit, idx, 0xFF);
            try testCbRes(bit, idx, 0x00);
        }
    }
}

test "CB SET b,r8 (0xC0-0xFF) all bits and r8" {
    var bit: u3 = 0;
    while (bit < 8) : (bit += 1) {
        var idx: u3 = 0;
        while (idx < 8) : (idx += 1) {
            try testCbSet(bit, idx, 0x00);
            try testCbSet(bit, idx, 0xFF);
        }
    }
}
