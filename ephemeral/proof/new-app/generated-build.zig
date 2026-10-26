const std = @import("std");

pub fn build(b: *std.Build) void {
    const zkit = b.dependency("zkit", .{ .target = b.graph.host });
    const host = zkit.artifact("z-kit-dev");
    b.installArtifact(host);
    const run = b.addRunArtifact(host);
    run.addArgs(&.{ "--app", "." });
    run.addPassthruArgs();
    b.step("dev", "Run this application through z-kit").dependOn(&run.step);
}
