const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const dev = b.addExecutable(.{
        .name = "z-kit-dev",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/dev.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    b.installArtifact(dev);
    const run = b.addRunArtifact(dev);
    run.addPassthruArgs();
    b.step("dev", "Run the example through the Zig development host").dependOn(&run.step);
    // Internal source module: no separate projector package or release.
    const projector = b.createModule(.{
        .root_source_file = b.path("modules/projector/src/projector.zig"),
        .target = target,
        .optimize = optimize,
    });
    const models = b.createModule(.{
        .root_source_file = b.path("modules/projector/test/module_model.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "projector", .module = projector }},
    });
    const tests = b.step("test", "Run projector configuration and module tests; compile comptime proof");
    tests.dependOn(&dev.step);
    for ([_][]const u8{ "shape_test.zig", "module_consumer.zig", "comptime_test.zig" }) |source| {
        const fixture = b.createModule(.{
            .root_source_file = b.path(b.fmt("modules/projector/test/{s}", .{source})),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "projector", .module = projector },
                .{ .name = "models", .module = models },
            },
        });
        const compiled = b.addTest(.{ .root_module = fixture });
        if (std.mem.eql(u8, source, "comptime_test.zig")) {
            // With no requested binary, the build emits -fno-emit-bin.
            tests.dependOn(&compiled.step);
        } else {
            tests.dependOn(&b.addRunArtifact(compiled).step);
        }
    }
    b.default_step = tests;
}
