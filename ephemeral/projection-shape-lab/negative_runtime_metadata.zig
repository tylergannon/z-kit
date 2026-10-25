const projector = @import("projector.zig");
var runtime_required: bool = false;
const Sample = struct {
    owner: ?[]const u8,
    pub const projection: projector.Projection(@This()) = .{
        .fields = .{ .owner = .{ .required = runtime_required } },
    };
};
comptime {
    _ = projector.config(Sample);
}
