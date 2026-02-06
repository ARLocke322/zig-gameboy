const Cpu = @import("../cpu.zig").Cpu;

pub fn execute_DAA(cpu: *Cpu) void {
    var adjustment: u8 = 0;
    const current: u8 = cpu.AF.getHi();
    if (cpu.get_n() == 1) {
        if (cpu.get_h() == 1) adjustment = 0x6;
        if (cpu.get_c() == 1) adjustment += 0x60;
        cpu.AF.setHi(current -% adjustment);
    } else {
        if (cpu.get_h() == 1 or (current & 0xF) > 0x9) adjustment = 0x6;
        if (cpu.get_c() == 1 or current > 0x99) {
            adjustment += 0x60;
            cpu.set_c(true);
        }
        cpu.AF.setHi(current +% adjustment);
    }

    cpu.set_z(cpu.AF.getHi() == 0);
    cpu.set_h(false);
}

pub fn execute_NOP() void {}

pub fn execute_STOP() void {}
