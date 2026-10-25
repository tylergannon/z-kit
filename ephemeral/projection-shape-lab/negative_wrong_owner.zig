const projector = @import("projector.zig");
const Other = struct { owner: ?[]const u8 };
const Sample = struct {
    owner: ?[]const u8,
    pub const projection: projector.Projection(Other) = .{};
};
test {
    _ = comptime projector.config(Sample);
}
