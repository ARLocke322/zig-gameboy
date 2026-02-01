const Cpu = @import("./Cpu/cpu.zig").Cpu;
const std = @import("std");

pub fn main() void {
    var cpu = Cpu.init();
    std.debug.print("{x}\n", .{cpu.AF.HiLo()});
    cpu.AF.Set(0xAFAF);
    std.debug.print("{x}\n", .{cpu.AF.HiLo()});
    std.debug.print("{x}\n", .{cpu.AF.Hi()});
    std.debug.print("{x}\n", .{cpu.AF.Lo()});
}
