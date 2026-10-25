const projector = @import("projector");
const Sample = struct {
    projection: u8,
    pub const projection: projector.Projection(@This()) = .{};
};
test {
    _ = comptime projector.config(Sample);
}
