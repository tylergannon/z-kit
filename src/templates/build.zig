const std = @import("std");
const zkit = @import("zkit");

pub fn build(b: *std.Build) void {
    const framework = b.dependency("zkit", .{ .target = b.graph.host });
    zkit.application(b, framework);
}
