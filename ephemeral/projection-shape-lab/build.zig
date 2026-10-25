const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const projector = b.addModule("projector", .{
        .root_source_file = b.path("projector.zig"),
        .target = target,
        .optimize = optimize,
    });
    const models = b.createModule(.{
        .root_source_file = b.path("module_model.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "projector", .module = projector }},
    });
    const consumer = b.createModule(.{
        .root_source_file = b.path("module_consumer.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "projector", .module = projector },
            .{ .name = "models", .module = models },
        },
    });
    const tests = b.addTest(.{ .root_module = consumer });
    const run = b.addRunArtifact(tests);
    b.step("test", "Check configuration across separate modules").dependOn(&run.step);
}
