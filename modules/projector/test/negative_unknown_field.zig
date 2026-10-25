const projector = @import("projector");
const Sample = struct {
    owner: ?[]const u8,
    pub const projection: projector.Projection(@This()) = .{
        .fields = .{ .owenr = .{ .required = true } },
    };
};
test {
    _ = comptime projector.config(Sample);
}
