const projector = @import("projector.zig");
const Sample = struct {
    owner: []const u8,
    pub const projection: projector.Projection(@This()) = .{
        .fields = .{ .owner = .{ .required = true } },
    };
};
test {
    _ = comptime projector.config(Sample);
}
