const std = @import("std");

pub var requested: std.atomic.Value(bool) = .init(false);
pub var child: std.atomic.Value(i32) = .init(0);

fn stop(signal: std.posix.SIG) callconv(.c) void {
    requested.store(true, .release);
    const pid = child.load(.acquire);
    if (pid > 0) _ = std.posix.system.kill(pid, signal);
}

pub fn install() void {
    const action: std.posix.Sigaction = .{
        .handler = .{ .handler = stop },
        .mask = std.posix.sigemptyset(),
        .flags = 0,
    };
    std.posix.sigaction(.INT, &action, null);
    std.posix.sigaction(.TERM, &action, null);
    std.posix.sigaction(.HUP, &action, null);
}
