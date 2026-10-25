const projector = @import("projector.zig");
const Sample = struct {
    title: []const u8,
    owner: ?[]const u8,
    pub const projection = .{
        .description = "This value already has its own anonymous type.",
        .fields = .{ .owner = .{ .required = true } },
    };
};
test {
    _ = comptime projector.config(Sample);
}
