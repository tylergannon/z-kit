const projector = @import("projector.zig");
const Sample = struct {
    owner: ?[]const u8,
    pub const projection: projector.Projection(@This()) = .{
        .fields = .{ .owner = .{ .requried = true } },
    };
};
test {
    _ = comptime projector.config(Sample);
}
