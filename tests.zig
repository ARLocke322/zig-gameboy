const std = @import("std");
const Bus = @import("bus.zig").Bus;
const Cpu = @import("./cpu/cpu.zig").Cpu;

// Helper to run one instruction
fn runOne(bus: *Bus, cpu: *Cpu, opcode: u8) void {
    bus.rom_bank_0[cpu.PC.getHiLo()] = opcode;
    const op = cpu.fetch();
    cpu.decode_execute(op);
}

// NOP - does nothing
test "NOP" {
    var bus = Bus.init();
    var cpu = Cpu.init(&bus);
    cpu.PC.set(0);

    runOne(&bus, &cpu, 0x00);

    try std.testing.expectEqual(@as(u16, 1), cpu.PC.getHiLo());
}

// LD BC, 0x1234
test "LD BC, imm16" {
    var bus = Bus.init();
    var cpu = Cpu.init(&bus);
    cpu.PC.set(0);
    cpu.BC.set(0);

    bus.rom_bank_0[0] = 0x01;
    bus.rom_bank_0[1] = 0x34;
    bus.rom_bank_0[2] = 0x12;

    const op = cpu.fetch();
    cpu.decode_execute(op);

    try std.testing.expectEqual(@as(u16, 0x1234), cpu.BC.getHiLo());
    try std.testing.expectEqual(@as(u16, 3), cpu.PC.getHiLo());
}

// LD A, 0x42
test "LD A, imm8" {
    var bus = Bus.init();
    var cpu = Cpu.init(&bus);
    cpu.PC.set(0);

    bus.rom_bank_0[0] = 0x3E;
    bus.rom_bank_0[1] = 0x42;

    const op = cpu.fetch();
    cpu.decode_execute(op);

    try std.testing.expectEqual(@as(u8, 0x42), cpu.AF.getHi());
    try std.testing.expectEqual(@as(u16, 2), cpu.PC.getHiLo());
}

// LD B, C
test "LD B, C" {
    var bus = Bus.init();
    var cpu = Cpu.init(&bus);
    cpu.PC.set(0);
    cpu.BC.setHi(0);
    cpu.BC.setLo(0x55);

    runOne(&bus, &cpu, 0x41); // LD B, C

    try std.testing.expectEqual(@as(u8, 0x55), cpu.BC.getHi());
}

// INC A
test "INC A" {
    var bus = Bus.init();
    var cpu = Cpu.init(&bus);
    cpu.PC.set(0);
    cpu.AF.setHi(0x10);

    runOne(&bus, &cpu, 0x3C); // INC A

    try std.testing.expectEqual(@as(u8, 0x11), cpu.AF.getHi());
    try std.testing.expectEqual(@as(u1, 0), cpu.get_z());
}

// DEC A
test "DEC A" {
    var bus = Bus.init();
    var cpu = Cpu.init(&bus);
    cpu.PC.set(0);
    cpu.AF.setHi(0x10);

    runOne(&bus, &cpu, 0x3D); // DEC A

    try std.testing.expectEqual(@as(u8, 0x0F), cpu.AF.getHi());
    try std.testing.expectEqual(@as(u1, 0), cpu.get_z());
}

// ADD A, B
test "ADD A, B" {
    var bus = Bus.init();
    var cpu = Cpu.init(&bus);
    cpu.PC.set(0);
    cpu.AF.setHi(0x10);
    cpu.BC.setHi(0x05);

    runOne(&bus, &cpu, 0x80); // ADD A, B

    try std.testing.expectEqual(@as(u8, 0x15), cpu.AF.getHi());
    try std.testing.expectEqual(@as(u1, 0), cpu.get_z());
    try std.testing.expectEqual(@as(u1, 0), cpu.get_c());
}

// SUB A, B
test "SUB A, B" {
    var bus = Bus.init();
    var cpu = Cpu.init(&bus);
    cpu.PC.set(0);
    cpu.AF.setHi(0x10);
    cpu.BC.setHi(0x05);

    runOne(&bus, &cpu, 0x90); // SUB A, B

    try std.testing.expectEqual(@as(u8, 0x0B), cpu.AF.getHi());
    try std.testing.expectEqual(@as(u1, 0), cpu.get_z());
    try std.testing.expectEqual(@as(u1, 1), cpu.get_n());
}

// JP 0x1234
test "JP imm16" {
    var bus = Bus.init();
    var cpu = Cpu.init(&bus);
    cpu.PC.set(0);

    bus.rom_bank_0[0] = 0xC3;
    bus.rom_bank_0[1] = 0x34;
    bus.rom_bank_0[2] = 0x12;

    const op = cpu.fetch();
    cpu.decode_execute(op);

    try std.testing.expectEqual(@as(u16, 0x1234), cpu.PC.getHiLo());
}

// PUSH BC / POP BC
test "PUSH and POP" {
    var bus = Bus.init();
    var cpu = Cpu.init(&bus);
    cpu.PC.set(0);
    cpu.SP.set(0xFFFE);
    cpu.BC.set(0x1234);

    // PUSH BC
    runOne(&bus, &cpu, 0xC5);
    try std.testing.expectEqual(@as(u16, 0xFFFC), cpu.SP.getHiLo());
    try std.testing.expectEqual(@as(u8, 0x34), bus.read8(0xFFFC));
    try std.testing.expectEqual(@as(u8, 0x12), bus.read8(0xFFFD));

    // Change BC
    cpu.BC.set(0);

    // POP BC
    runOne(&bus, &cpu, 0xC1);
    try std.testing.expectEqual(@as(u16, 0x1234), cpu.BC.getHiLo());
    try std.testing.expectEqual(@as(u16, 0xFFFE), cpu.SP.getHiLo());
}
