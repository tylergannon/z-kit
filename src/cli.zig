const std = @import("std");

pub fn main(init: std.process.Init) void {
    @import("interrupt.zig").install();
    command(init) catch |err| {
        std.debug.print("zkit: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };
}

fn command(init: std.process.Init) !void {
    var it = std.process.Args.Iterator.init(init.minimal.args);
    _ = it.next();
    const verb = it.next() orelse return help();
    var args: std.ArrayList([]const u8) = .empty;
    while (it.next()) |arg| try args.append(init.arena.allocator(), arg);
    if (std.mem.eql(u8, verb, "new")) {
        return @import("new.zig").create(init, args.items);
    } else if (std.mem.eql(u8, verb, "frontend") and args.items.len == 1) {
        return @import("frontend.zig").task(init, args.items[0]);
    } else if (std.mem.eql(u8, verb, "--help") or std.mem.eql(u8, verb, "-h")) return help();
    help();
    return error.UnknownCommand;
}

fn help() void {
    std.debug.print(
        \\Usage: zkit new [--name NAME] [--zkit-path PATH] DIR [-- SV_CREATE_OPTIONS]
        \\VitePlus delegates to sv's own minimal/demo, language and add-on choices.
        \\Without a terminal, omitted choices use minimal TypeScript.
        \\Example: zkit new myapp -- --template demo --types jsdoc --add tailwindcss=plugins:none
        \\The development CLI defaults to its explicitly recorded framework source path.
        \\
    , .{});
}

test {
    _ = @import("new.zig");
}
