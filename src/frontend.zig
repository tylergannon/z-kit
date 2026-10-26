const std = @import("std");
const interrupt = @import("interrupt.zig");

pub const viteplus = "1.4.0";
pub const pnpm = "12.14.0";
pub const sv = "1.1.1";

// Port of SKGo's internal/newapp/environment.go. Every creation child runs
// through the qualified VitePlus environment, including local vp and Zig.
pub const Runner = struct {
    init: std.process.Init,
    allocator: std.mem.Allocator,
    env: std.process.Environ.Map,
    vp: []const u8,

    pub fn prepare(init: std.process.Init, cwd: []const u8) !Runner {
        const a = init.arena.allocator();
        var self: Runner = .{ .init = init, .allocator = a, .env = try init.environ_map.clone(a), .vp = "vp" };
        const found = try self.captureRaw(cwd, &.{ "which", "vp" });
        self.vp = std.mem.trim(u8, found, "\r\n ");
        if (!std.fs.path.isAbsolute(self.vp)) return error.VitePlusNotFound;
        const version = try self.captureRaw(cwd, &.{ self.vp, "--version" });
        if (!std.mem.startsWith(u8, version, "vp v" ++ viteplus ++ "\n")) {
            std.debug.print("zkit: requires VitePlus {s}; run vp upgrade {s}\n", .{ viteplus, viteplus });
            return error.UnsupportedVitePlus;
        }
        try self.env.put("VP_PACKAGE_MANAGER", "pnpm@" ++ pnpm);
        try self.env.put("VP_PNPM_VERSION", pnpm);
        const managed = std.mem.trim(u8, try self.capture(cwd, &.{ "which", "pnpm" }), "\r\n ");
        if (!std.fs.path.isAbsolute(managed)) return error.ManagedPnpmNotFound;
        const actual = try self.capture(cwd, &.{ managed, "--version" });
        if (!std.mem.eql(u8, std.mem.trim(u8, actual, "\r\n "), pnpm)) return error.UnsupportedPnpm;
        return self;
    }

    fn arguments(self: *Runner, args: []const []const u8) ![]const []const u8 {
        return std.mem.concat(self.allocator, []const u8, &.{ &.{ self.vp, "env", "exec", "--package-manager", "pnpm@" ++ pnpm, "--" }, args });
    }

    fn captureRaw(self: *Runner, cwd: []const u8, args: []const []const u8) ![]const u8 {
        const result = try std.process.run(self.allocator, self.init.io, .{
            .argv = args,
            .cwd = .{ .path = cwd },
            .environ_map = &self.env,
            .stdout_limit = .limited(1024 * 1024),
            .stderr_limit = .limited(1024 * 1024),
        });
        if (result.stderr.len > 0) std.debug.print("{s}", .{result.stderr});
        if (!result.term.success()) return error.FrontendCommandFailed;
        return result.stdout;
    }

    pub fn capture(self: *Runner, cwd: []const u8, args: []const []const u8) ![]const u8 {
        return self.captureRaw(cwd, try self.arguments(args));
    }

    pub fn run(self: *Runner, step: []const u8, cwd: []const u8, args: []const []const u8) !void {
        if (interrupt.requested.load(.acquire)) return error.Interrupted;
        std.debug.print("\nzkit: {s}\n", .{step});
        var child = std.process.spawn(self.init.io, .{
            .argv = try self.arguments(args),
            .cwd = .{ .path = cwd },
            .environ_map = &self.env,
        }) catch |err| {
            std.debug.print("zkit: {s}: {s}\n", .{ step, @errorName(err) });
            return err;
        };
        defer child.kill(self.init.io);
        interrupt.child.store(child.id.?, .release);
        defer interrupt.child.store(0, .release);
        if (interrupt.requested.load(.acquire)) _ = std.posix.system.kill(child.id.?, .INT);
        const term = try child.wait(self.init.io);
        if (!term.success() or interrupt.requested.load(.acquire)) {
            std.debug.print("zkit: {s} failed ({f})\n", .{ step, term });
            return error.FrontendCommandFailed;
        }
    }
};

pub fn task(init: std.process.Init, name: []const u8) !void {
    const root = try std.process.currentPathAlloc(init.io, init.arena.allocator());
    var runner = try Runner.prepare(init, root);
    const web = try std.fs.path.join(runner.allocator, &.{ root, "web" });
    if (std.mem.eql(u8, name, "install-web")) {
        try runner.run("install frontend", web, &.{ runner.vp, "install", "--frozen-lockfile" });
    } else if (std.mem.eql(u8, name, "check")) {
        try runner.run("check Svelte", web, &.{ "node_modules/.bin/vp", "run", "check" });
        try runner.run("check frontend tools", web, &.{ "node_modules/.bin/vp", "check" });
    } else if (std.mem.eql(u8, name, "build-web")) {
        try runner.run("build frontend", web, &.{ "node_modules/.bin/vp", "build" });
    } else return error.UnknownFrontendTask;
}
