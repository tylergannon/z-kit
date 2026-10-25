const alternative = @import("array_alternative.zig");
const Sample = struct {
    owner: ?[]const u8,
    pub const projection: alternative.Projection(@This()) = .{
        .fields = &.{
            .{ .field = .owner, .options = .{ .required = true } },
            .{ .field = .owner, .options = .{ .required = false } },
        },
    };
};
test {
    _ = comptime alternative.config(Sample);
}
