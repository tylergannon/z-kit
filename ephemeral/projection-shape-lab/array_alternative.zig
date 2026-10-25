//! A working alternative for comparison, not the recommended spelling.
const std = @import("std");
const projector = @import("projector.zig");

pub fn Projection(comptime T: type) type {
    return struct {
        description: ?[]const u8 = null,
        fields: []const struct {
            field: std.meta.FieldEnum(T),
            options: projector.FieldOptions = .{},
        } = &.{},
    };
}

pub fn config(comptime T: type) Projection(T) {
    return comptime blk: {
        const result: Projection(T) = T.projection;
        for (result.fields, 0..) |entry, i| {
            for (result.fields[0..i]) |earlier| {
                if (entry.field == earlier.field) {
                    @compileError("duplicate field entry: " ++ @tagName(entry.field));
                }
            }
        }
        break :blk result;
    };
}
