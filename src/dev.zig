const std = @import("std");
const Io = std.Io;
const net = Io.net;

comptime {
    if (@import("builtin").os.tag != .macos)
        @compileError("The initial z-kit development host supports macOS");
}

// A signal handler only publishes a lock-free flag. Normal control flow owns
// cancellation, closing streams, reaping the child and removing its socket.
var stopping: std.atomic.Value(bool) = .init(false);

fn stop(_: std.posix.SIG) callconv(.c) void {
    stopping.store(true, .release);
}

pub fn main(init: std.process.Init) void {
    session(init) catch |err| {
        std.debug.print("z-kit: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };
}

fn session(init: std.process.Init) !void {
    const io = init.io;
    const allocator = init.arena.allocator();
    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.next();
    var port: u16 = 5173;
    var app: []const u8 = "example";
    var launcher: []const u8 = "tooling/vite.mjs";
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--port")) {
            port = try std.fmt.parseInt(u16, args.next() orelse return error.MissingPort, 10);
        } else if (std.mem.eql(u8, arg, "--app")) {
            app = args.next() orelse return error.MissingApplicationPath;
        } else if (std.mem.eql(u8, arg, "--vite-launcher")) {
            launcher = args.next() orelse return error.MissingLauncherPath;
        } else {
            std.debug.print("Usage: zig build dev -- [--port 5173] [--app example]\n", .{});
            return error.UnknownArgument;
        }
    }
    // Reserve the public port before starting Vite; never silently move ports.
    const address: net.IpAddress = .{ .ip4 = .loopback(port) };
    var server = address.listen(io, .{ .reuse_address = true }) catch |err| {
        std.debug.print("z-kit: cannot listen on 127.0.0.1:{d}: {s}\n", .{ port, @errorName(err) });
        return err;
    };
    defer server.deinit(io);
    // std.Io couples REUSEADDR to REUSEPORT. Keep immediate restart but make
    // this session the exclusive owner of its public listener.
    const no_port_sharing: c_int = 0;
    try std.posix.setsockopt(server.socket.handle, std.posix.SOL.SOCKET, std.posix.SO.REUSEPORT, std.mem.asBytes(&no_port_sharing));
    const origin = try std.fmt.allocPrint(allocator, "http://127.0.0.1:{d}", .{server.socket.address.getPort()});

    const action: std.posix.Sigaction = .{
        .handler = .{ .handler = stop },
        .mask = std.posix.sigemptyset(),
        .flags = 0,
    };
    std.posix.sigaction(.INT, &action, null);
    std.posix.sigaction(.TERM, &action, null);
    std.posix.sigaction(.HUP, &action, null);

    var random: [8]u8 = undefined;
    io.random(&random);
    const directory = try std.fmt.allocPrint(allocator, "/tmp/z-kit-{x}", .{std.mem.readInt(u64, &random, .little)});
    const socket_path = try std.fmt.allocPrint(allocator, "{s}/vite.sock", .{directory});
    try Io.Dir.createDirAbsolute(io, directory, .fromMode(0o700));
    defer {
        // Cancellation may already be pending when the build runner stops us.
        // The session owner must finish these bounded filesystem operations.
        const protection = io.swapCancelProtection(.blocked);
        defer _ = io.swapCancelProtection(protection);
        Io.Dir.deleteFileAbsolute(io, socket_path) catch |err| switch (err) {
            error.FileNotFound => {}, // Node may have closed/unlinked it first.
            else => std.debug.print("z-kit: removing socket: {s}\n", .{@errorName(err)}),
        };
        Io.Dir.deleteDirAbsolute(io, directory) catch |err|
            std.debug.print("z-kit: removing session directory: {s}\n", .{@errorName(err)});
    }
    const unix_address = try net.UnixAddress.init(socket_path);

    var child = std.process.spawn(io, .{
        .argv = &.{ "node", launcher, app, socket_path, origin },
        .stdin = .ignore,
        .stdout = .pipe,
    }) catch |err| {
        std.debug.print("z-kit: cannot start Vite (install Node and run pnpm install): {s}\n", .{@errorName(err)});
        return err;
    };
    defer child.kill(io);

    var startup: std.atomic.Value(bool) = .init(false);
    var readiness = try io.concurrent(readReady, .{ io, child.stdout.?, &startup });
    // Cancel/join the reader before Child.kill closes its pipe.
    defer readiness.cancel(io) catch {};
    const start = Io.Clock.awake.now(io);
    while (!startup.load(.acquire)) {
        if (stopping.load(.acquire)) return;
        if (start.durationTo(Io.Clock.awake.now(io)).toMilliseconds() >= 30_000) {
            std.debug.print("z-kit: Vite/application startup timed out after 30 seconds\n", .{});
            return error.StartupTimeout;
        }
        try io.sleep(.fromMilliseconds(50), .awake);
    }
    readiness.await(io) catch |err| {
        std.debug.print("z-kit: Vite exited before the application was ready; see diagnostics above\n", .{});
        return err;
    };
    var child_done: std.atomic.Value(bool) = .init(false);
    var child_watch = try io.concurrent(watchChild, .{ io, child.stdout.?, &child_done });
    defer child_watch.cancel(io) catch {};
    var serving_done: std.atomic.Value(bool) = .init(false);
    var serving = try io.concurrent(serve, .{ io, &server, unix_address, &serving_done });
    defer serving.cancel(io) catch {};
    std.debug.print("\nz-kit ready at {s}\nVite socket: {s}\nPress Ctrl-C to stop.\n", .{ origin, socket_path });
    while (!stopping.load(.acquire)) {
        if (serving_done.load(.acquire)) return serving.await(io);
        if (child_done.load(.acquire)) {
            child_watch.await(io) catch {};
            const term = try child.wait(io);
            std.debug.print("z-kit: Vite {f}\n", .{term});
            return error.ViteExited;
        }
        try io.sleep(.fromMilliseconds(50), .awake);
    }
    std.debug.print("\nz-kit: stopping\n", .{});
}

fn readReady(io: Io, file: Io.File, done: *std.atomic.Value(bool)) !void {
    defer done.store(true, .release);
    var buffer: [1]u8 = undefined;
    var reader = file.reader(io, &buffer);
    if (try reader.interface.takeByte() != 'R') return error.InvalidReadinessMessage;
}

// Watch pipe EOF without waiting/reaping concurrently with Child.kill.
fn watchChild(io: Io, file: Io.File, done: *std.atomic.Value(bool)) !void {
    defer done.store(true, .release);
    var buffer: [256]u8 = undefined;
    var reader = file.reader(io, &buffer);
    while (true) {
        const byte = reader.interface.takeByte() catch |err| switch (err) {
            error.EndOfStream => return,
            else => return err,
        };
        std.debug.print("{c}", .{byte});
    }
}

fn serve(io: Io, server: *net.Server, address: net.UnixAddress, done: *std.atomic.Value(bool)) !void {
    defer done.store(true, .release);
    var connections: Io.Group = .init;
    defer connections.cancel(io);
    while (true) {
        const client = server.accept(io) catch |err| switch (err) {
            error.Canceled => return error.Canceled,
            else => {
                std.debug.print("z-kit: accept failed: {s}\n", .{@errorName(err)});
                return err;
            },
        };
        connections.concurrent(io, proxy, .{ io, client, address }) catch {
            client.close(io);
            std.debug.print("z-kit: cannot start another proxy connection\n", .{});
        };
    }
}

fn proxy(io: Io, client: net.Stream, address: net.UnixAddress) Io.Cancelable!void {
    defer client.close(io);
    const upstream = address.connect(io) catch |err| switch (err) {
        error.Canceled => return error.Canceled,
        else => return,
    };
    defer upstream.close(io);
    var upload = io.concurrent(copy, .{ io, client, upstream }) catch return;
    defer upload.cancel(io) catch {};
    try copy(io, upstream, client);
}

// Transport bytes unchanged, including chunked bodies, interim responses,
// upgrades and WebSocket frames. EOF half-closes the destination, preserving
// the upstream server's transport behavior.
fn copy(io: Io, source: net.Stream, destination: net.Stream) Io.Cancelable!void {
    defer destination.shutdown(io, .send) catch {};
    var buffer: [16 * 1024]u8 = undefined;
    var slices = [_][]u8{&buffer};
    var writer = destination.writer(io, &.{});
    while (true) {
        const n = source.read(io, &slices) catch |err| switch (err) {
            error.Canceled => return error.Canceled,
            else => return,
        };
        if (n == 0) return;
        writer.interface.writeAll(buffer[0..n]) catch {
            if (writer.err) |err| {
                if (err == error.Canceled) return error.Canceled;
            }
            return;
        };
    }
}
