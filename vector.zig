const std = @import("std");
const Allocator = std.mem.Allocator;

const stdout = std.io.getStdOut().writer();

pub fn Vec(comptime T: type) type {
    return struct {
        const Self = @This();

        alloc: Allocator,
        buffer: []T,
        element_count: usize,

        pub fn init(alloc: Allocator, size: usize) !Self {
            const buf = try alloc.alloc(T, size);
            buf[0] = 0;
            return .{
                .alloc = alloc,
                .buffer = buf,
                .element_count = 0,
            };
        }

        pub fn deinit(this: *Self) void {
            this.alloc.free(this.buffer);
            this.element_count = 0;
        }

        pub fn pushBack(this: *Self, element: T) !void {
            if (this.element_count + 1 == this.buffer.len) {
                try stdout.writeAll("Realloc\n");
                this.buffer = try this.alloc.realloc(this.buffer, this.buffer.len * 2);
            }

            this.buffer[this.element_count] = element;
            this.element_count += 1;
        }

        pub fn at(this: Self, index: usize) ?*T {
            if (this.element_count < index) {
                return null;
            }

            return &this.buffer[index];
        }
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    var vec = try Vec(usize).init(alloc, 1);
    defer vec.deinit();

    var i: usize = 1;
    while (i <= 1000) : (i += 1) {
        try vec.pushBack(i);
    }

    i = 0;
    while (i <= 1000) : (i += 1) {
        const formatted = try std.fmt.allocPrint(alloc, "{d} ", .{vec.at(i).?.*});
        defer alloc.free(formatted);
        try stdout.writeAll(formatted);
    }
    try stdout.writeAll("\n\n");
}
