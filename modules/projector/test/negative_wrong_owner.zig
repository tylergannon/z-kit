const projector = @import("projector");
const Other = struct { owner: ?[]const u8 };
const Sample = struct {
    owner: ?[]const u8,
    pub const projection: projector.Projection(Other) = .{};
};
test {
    _ = comptime projector.config(Sample);
}
