const MBC0 = @import("MBC0.zig").MBC0;
const MBC1 = @import("MBC1.zig").MBC1;
const MBC2 = @import("MBC2.zig").MBC2;
const MBC3 = @import("MBC3.zig").MBC3;

const std = @import("std");
const assert = std.debug.assert;

pub const Cartridge = struct {
    ptr: *anyopaque,
    readFnPtr: *const fn (ptr: *anyopaque, address: u16) u8,
    writeFnPtr: *const fn (ptr: *anyopaque, address: u16, value: u8) void,
    deinitFnPtr: *const fn (ptr: *anyopaque, allocator: std.mem.Allocator) void,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, data: []const u8) !Cartridge {
        const ram_size: usize = getRamSize(data[0x149]);
        std.debug.print("MBC Bit: {x}\n", .{data[0x147]});
        return switch (data[0x147]) {
            0x00 => initCart(MBC0, allocator, data, ram_size),
            0x01...0x03 => initCart(MBC1, allocator, data, ram_size),
            0x05...0x06 => initCart(MBC2, allocator, data, ram_size),
            0x0F...0x13 => initCart(MBC3, allocator, data, ram_size),
            else => error.UnimplementedCartridge,
        };
    }

    pub fn deinit(self: Cartridge) void {
        self.deinitFnPtr(self.ptr, self.allocator);
    }

    pub fn read(self: Cartridge, address: u16) u8 {
        return self.readFnPtr(self.ptr, address);
    }

    pub fn write(self: Cartridge, address: u16, value: u8) void {
        self.writeFnPtr(self.ptr, address, value);
    }

    // --- Private ---

    fn initCart(comptime T: type, allocator: std.mem.Allocator, data: []const u8, ram_size: usize) !Cartridge {
        const ptr = try allocator.create(T);
        ptr.* = try T.init(allocator, data, ram_size);
        const impl = struct {
            fn read(p: *anyopaque, address: u16) u8 {
                return @as(*T, @ptrCast(@alignCast(p))).read(address);
            }
            fn write(p: *anyopaque, address: u16, value: u8) void {
                @as(*T, @ptrCast(@alignCast(p))).write(address, value);
            }
            fn deinit(p: *anyopaque, alloc: std.mem.Allocator) void {
                const self: *T = @ptrCast(@alignCast(p));
                self.deinit();
                alloc.destroy(self);
            }
        };
        return Cartridge{
            .ptr = ptr,
            .readFnPtr = &impl.read,
            .writeFnPtr = &impl.write,
            .deinitFnPtr = &impl.deinit,
            .allocator = allocator,
        };
    }

    fn getRamSize(byte: u8) usize {
        // assert(byte >= 0x00 and byte <= 0x05 and byte != 0x01);
        return switch (byte) {
            0x00 => 0, // No RAM
            0x02 => 8 * 1024, // 8KiB - 1 bank
            0x03 => 32 * 1024, // 32KiB - 4 8KiB banks
            0x04 => 128 * 1024, // 128KiB - 16 8KiB banks
            0x05 => 64 * 1024, // 64KiB - 8 8KiB banks
            else => 0,
        };
    }
};
