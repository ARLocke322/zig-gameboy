const Cpu = @import("../cpu.zig").Cpu;
const Register = @import("../register.zig").Register;
const set_NHC_flags_r8_ADD = @import("../helpers.zig").set_NHC_flags_r8_ADD;
const set_NHC_flags_r16_ADD = @import("../helpers.zig").set_NHC_flags_r16_ADD;

// Add the value in SP to HL.
pub fn execute_ADD_HL_SP(cpu: *Cpu) void {
    const op1: u16 = cpu.HL.getHiLo();
    const op2: u16 = cpu.SP.getHiLo();

    const result = @addWithOverflow(op1, op2);
    cpu.HL.set(result[0]);

    set_NHC_flags_r16_ADD(cpu, op1, op2, result[1] == 1);
}

// Add the signed value e8 to SP.
pub fn execute_ADD_SP_e8(cpu: *Cpu, e8: i8) void {
    const sp = cpu.SP.getHiLo();
    const e8_u16: u16 = @bitCast(@as(i16, e8));

    const result = @addWithOverflow(sp, e8_u16);
    const low_result = @addWithOverflow(
        @as(u8, @truncate(sp)),
        @as(u8, @truncate(e8_u16)),
    );

    cpu.SP.set(result[0]);

    set_NHC_flags_r8_ADD(cpu, @truncate(sp), @truncate(e8_u16), 0, low_result[1] == 1);
    cpu.set_z(false);
}

// Decrement the value in register SP by 1.
pub fn execute_DEC_SP(cpu: *Cpu) void {
    cpu.SP.dec();
}

// Increment the value in register SP by 1.
pub fn execute_INC_SP(cpu: *Cpu) void {
    cpu.SP.inc();
}

// Copy the value n16 into register SP.
pub fn execute_LD_SP_n16(cpu: *Cpu, val: u16) void {
    cpu.SP.set(val);
}

// Copy SP & $FF at address n16 and SP >> 8 at address n16 + 1.
pub fn execute_LD_n16_SP(cpu: *Cpu, addr: u16) void {
    cpu.mem.write8(addr, cpu.SP.getLo());
    cpu.mem.write8(addr + 1, cpu.SP.getHi());
}

// Add the signed value e8 to SP and copy the result in HL.
pub fn execute_LD_HL_SP_plus_e8(cpu: *Cpu, e8: i8) void {
    const sp = cpu.SP.getHiLo();
    const e8_u16: u16 = @bitCast(@as(i16, e8));

    const result = @addWithOverflow(sp, e8_u16);
    const low_result = @addWithOverflow(
        @as(u8, @truncate(sp)),
        @as(u8, @truncate(e8_u16)),
    );

    cpu.HL.set(result[0]);

    set_NHC_flags_r8_ADD(cpu, @truncate(sp), @truncate(e8_u16), 0, low_result[1] == 1);
    cpu.set_z(false);
}

// Copy register HL into register SP.
pub fn execute_LD_SP_HL(cpu: *Cpu) void {
    cpu.SP.set(cpu.HL.getHiLo());
}

// Pop register AF from the stack.
pub fn execute_POP_AF(cpu: *Cpu) void {
    cpu.AF.set(cpu.sp_pop_16());
}

// Pop register r16 from the stack.
pub fn execute_POP_r16(cpu: *Cpu, r: *Register) void {
    r.set(cpu.sp_pop_16());
}

// Push register AF into the stack.
pub fn execute_PUSH_AF(cpu: *Cpu) void {
    cpu.sp_push_16(cpu.AF.getHiLo());
}

// Push register r16 into the stack.
pub fn execute_PUSH_r16(cpu: *Cpu, r: *Register) void {
    cpu.sp_push_16(r.getHiLo());
}
