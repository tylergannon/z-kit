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
    const options = b.addOptions();
    // Record a usable source location for this development CLI, even when it
    // is invoked outside the checkout. Do not recursively hash node_modules.
    const source_root = b.root.root_dir.handle.realPathFileAlloc(
        b.graph.io,
        if (b.root.sub_path.len == 0) "." else b.root.sub_path,
        b.allocator,
    ) catch @panic("cannot resolve framework source root");
    options.addOption([]const u8, "framework_root", source_root);
    const cli = b.addExecutable(.{
        .name = "zkit",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/cli.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    cli.root_module.addOptions("options", options);
    b.installArtifact(cli);
    const command = b.addRunArtifact(cli);
    command.addPassthruArgs();
    b.step("cli", "Run the zkit CLI").dependOn(&command.step);
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
    tests.dependOn(&cli.step);
    const cli_tests = b.addTest(.{ .root_module = cli.root_module });
    tests.dependOn(&b.addRunArtifact(cli_tests).step);
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

/// Root build integration shared by freshly generated applications.
pub fn application(b: *std.Build, framework: *std.Build.Dependency) void {
    const host = framework.artifact("z-kit-dev");
    b.installArtifact(host);
    const dev = b.addRunArtifact(host);
    dev.addArgs(&.{ "--app", "web", "--vite-launcher" });
    dev.addFileArg(framework.path("tooling/vite.mjs"));
    dev.setCwd(b.path(""));
    dev.addPassthruArgs();
    b.step("dev", "Run SvelteKit through the Zig public listener").dependOn(&dev.step);

    const cli = framework.artifact("zkit");
    for ([_][]const u8{ "install-web", "check", "build-web" }) |name| {
        const frontend = b.addRunArtifact(cli);
        frontend.addArgs(&.{ "frontend", name });
        frontend.setCwd(b.path(""));
        frontend.has_side_effects = true;
        b.step(name, name).dependOn(&frontend.step);
        if (std.mem.eql(u8, name, "build-web")) b.getInstallStep().dependOn(&frontend.step);
    }
}
