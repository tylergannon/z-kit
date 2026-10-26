const std = @import("std");
const Io = std.Io;

pub fn main(init: std.process.Init) void {
    run(init) catch |err| {
        std.debug.print("zkit: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };
}

fn run(init: std.process.Init) !void {
    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.next();
    const command = args.next() orelse "--help";
    if (std.mem.eql(u8, command, "--help") or std.mem.eql(u8, command, "-h")) {
        std.debug.print("Usage: zkit new DIRECTORY [--template empty|examples] [--zkit-path PATH] [-- SV_OPTIONS]\n", .{});
        return;
    }
    if (!std.mem.eql(u8, command, "new")) return error.UnknownCommand;

    const io = init.io;
    const allocator = init.arena.allocator();
    var random: [8]u8 = undefined;
    io.random(&random);
    const directory = try std.fmt.allocPrint(allocator, "/tmp/zkit-new-{x}", .{std.mem.readInt(u64, &random, .little)});
    try Io.Dir.createDirAbsolute(io, directory, .fromMode(0o700));
    defer Io.Dir.deleteDirAbsolute(io, directory) catch {};
    const script = try std.fmt.allocPrint(allocator, "{s}/new.mjs", .{directory});
    try Io.Dir.cwd().writeFile(io, .{ .sub_path = script, .data = @embedFile("new_script") });
    defer Io.Dir.deleteFileAbsolute(io, script) catch {};
    const page = try std.fmt.allocPrint(allocator, "{s}/example.svelte", .{directory});
    try Io.Dir.cwd().writeFile(io, .{ .sub_path = page, .data = @embedFile("example_page") });
    defer Io.Dir.deleteFileAbsolute(io, page) catch {};

    // Zig package identity: a random non-reserved id plus CRC32(name), as in
    // this compiler's lib/compiler/Maker/Package.zig. Each app gets its own id.
    const id = 1 + std.mem.readInt(u32, random[0..4], .little) % 0xfffffffe;
    const fingerprint = (@as(u64, std.hash.Crc32.hash("zkit_app")) << 32) | id;
    const identity = try std.fmt.allocPrint(allocator, "0x{x}", .{fingerprint});
    var argv: std.ArrayList([]const u8) = .empty;
    try argv.appendSlice(allocator, &.{ "node", script, @import("build_options").source_root, identity, page });
    while (args.next()) |arg| try argv.append(allocator, arg);
    var child = std.process.spawn(io, .{ .argv = argv.items }) catch |err| {
        std.debug.print("zkit: cannot start application creation; Node.js is required\n", .{});
        return err;
    };
    defer child.kill(io);
    if (!(try child.wait(io)).success()) return error.ApplicationCreationFailed;
}
