const projector = @import("projector");
const Sample = struct {
    owner: ?[]const u8,
    pub const projection: projector.Projection(@This()) = .{
        .fields = .{ .owner = .{ .required = "yes" } },
    };
};
test {
    _ = comptime projector.config(Sample);
}
