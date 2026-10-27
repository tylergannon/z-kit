const std = @import("std");
const Io = std.Io;
const frontend = @import("frontend.zig");
const Runner = frontend.Runner;
const Allocator = std.mem.Allocator;

fn equal(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

// SKGo's svCreateArgs: defaults precede the variadic --add argument, and
// terminal choices are left to sv. The wrapper never invents another prompt.
pub fn upstreamArgs(a: Allocator, args: []const []const u8, interactive: bool) ![]const []const u8 {
    var template = false;
    var types = false;
    var addons = false;
    var variadic = false;
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        const arg = args[i];
        const split = std.mem.indexOfScalar(u8, arg, '=');
        const key = arg[0..(split orelse arg.len)];
        var value: []const u8 = if (split) |p| arg[p + 1 ..] else "";
        if (!std.mem.startsWith(u8, key, "-")) {
            if (!variadic) return error.UpstreamTargetMustBeWeb;
            if (equal(key, "ai-tools")) return error.AgentToolsBelongAtApplicationRoot;
            continue;
        }
        variadic = false;
        if (equal(key, "--template") or equal(key, "--types")) {
            if (split == null) {
                i += 1;
                if (i == args.len or std.mem.startsWith(u8, args[i], "-")) return error.MissingUpstreamOptionValue;
                value = args[i];
            }
            if (equal(key, "--template")) {
                template = true;
                if (!equal(value, "minimal") and !equal(value, "demo")) return error.ChooseMinimalOrDemo;
            } else types = true;
        } else if (equal(key, "--no-types")) {
            types = true;
        } else if (equal(key, "--add")) {
            addons = true;
            variadic = split == null;
            if (std.mem.startsWith(u8, value, "ai-tools")) return error.AgentToolsBelongAtApplicationRoot;
        } else if (equal(key, "--no-add-ons")) {
            addons = true;
        } else if (equal(key, "--install") or equal(key, "--no-install")) {
            return error.VitePlusOwnsDependencyInstallation;
        } else if (equal(key, "--from-playground") or equal(key, "--addon-name")) {
            return error.OptionIsNotForAnApplication;
        }
    }
    var out: std.ArrayList([]const u8) = .empty;
    if (!interactive) {
        if (!template) try out.appendSlice(a, &.{ "--template", "minimal" });
        if (!types) try out.appendSlice(a, &.{ "--types", "ts" });
        if (!addons) try out.append(a, "--no-add-ons");
    }
    try out.appendSlice(a, args);
    return out.toOwnedSlice(a);
}

fn path(a: Allocator, root: []const u8, name: []const u8) ![]const u8 {
    return std.fs.path.join(a, &.{ root, name });
}

fn exists(io: Io, name: []const u8) bool {
    Io.Dir.cwd().access(io, name, .{}) catch return false;
    return true;
}

fn read(a: Allocator, io: Io, name: []const u8) ![]const u8 {
    return Io.Dir.cwd().readFileAlloc(io, name, a, .limited(8 * 1024 * 1024));
}

fn write(io: Io, name: []const u8, contents: []const u8) !void {
    try Io.Dir.cwd().writeFile(io, .{ .sub_path = name, .data = contents });
}

fn package(a: Allocator, io: Io, web: []const u8) !std.json.Value {
    const bytes = try read(a, io, try path(a, web, "package.json"));
    return (try std.json.parseFromSlice(std.json.Value, a, bytes, .{ .allocate = .alloc_always })).value;
}

fn field(value: std.json.Value, key: []const u8) std.json.Value {
    if (value == .object) return value.object.get(key) orelse .null;
    return .null;
}

fn has(value: std.json.Value, key: []const u8) bool {
    return field(value, key) != .null;
}

pub fn verifyIntegration(a: Allocator, io: Io, web: []const u8, examples: bool) !void {
    const pkg = try package(a, io, web);
    const scripts = field(pkg, "scripts");
    const dev = field(scripts, "dev");
    if (dev != .string or !equal(dev.string, "cd .. && zig build dev")) return error.SvDidNotApplyZkitIntegration;
    if (examples) {
        if (exists(io, try path(a, web, "src/routes/sverdle"))) return error.StockDemoStillPresent;
        const page = try read(a, io, try path(a, web, "src/routes/+page.svelte"));
        if (std.mem.indexOf(u8, page, "z-kit / first application") == null) return error.ZkitExamplesMissing;
    }
}

pub fn create(init: std.process.Init, args: []const []const u8) !void {
    const a = init.arena.allocator();
    const io = init.io;
    var dir: ?[]const u8 = null;
    var name: ?[]const u8 = null;
    var framework: []const u8 = @import("options").framework_root;
    var supplied: []const []const u8 = &.{};
    var i: usize = 0;
    while (i < args.len) : (i += 1) {
        if (equal(args[i], "--")) {
            supplied = args[i + 1 ..];
            break;
        }
        if (equal(args[i], "-h") or equal(args[i], "--help")) {
            std.debug.print("Usage: zkit new [--name NAME] [--zkit-path PATH] DIR [-- SV_CREATE_OPTIONS]\n", .{});
            return;
        }
        if (equal(args[i], "--name") or equal(args[i], "--zkit-path")) {
            const flag = args[i];
            i += 1;
            if (i == args.len) return error.MissingOptionValue;
            if (equal(flag, "--name")) name = args[i] else framework = args[i];
        } else if (!std.mem.startsWith(u8, args[i], "-") and dir == null) {
            dir = args[i];
        } else return error.UnknownNewArgument;
    }
    const requested = dir orelse return error.MissingDestination;
    const ci: []const u8 = if (init.environ_map.get("CI")) |value| value else "";
    const interactive = ci.len == 0 and
        try Io.File.stdin().isTty(io) and try Io.File.stdout().isTty(io);
    const upstream = upstreamArgs(a, supplied, interactive) catch |err| {
        if (err == error.AgentToolsBelongAtApplicationRoot)
            std.debug.print("zkit: sv's ai-tools writes inside web/; configure coding agents at the application root instead.\n", .{});
        return err;
    };
    const cwd = try std.process.currentPathAlloc(io, a);
    framework = try Io.Dir.cwd().realPathFileAlloc(io, framework, a);
    if (!exists(io, try path(a, framework, "tooling/sv/addon.js"))) return error.BuildFrameworkAddonFirst;
    const destination = try std.fs.path.resolve(a, &.{ cwd, requested });
    const app_name = name orelse std.fs.path.basename(destination);
    if (app_name.len == 0 or !std.ascii.isAlphanumeric(app_name[0])) return error.InvalidApplicationName;
    for (app_name) |c| if (!std.ascii.isAlphanumeric(c) and c != '-' and c != '_' and c != '.') return error.InvalidApplicationName;
    try Io.Dir.cwd().createDirPath(io, destination);
    var target = try Io.Dir.cwd().openDir(io, destination, .{ .iterate = true });
    defer target.close(io);
    var entries = target.iterate();
    if (try entries.next(io) != null) return error.DestinationNotEmpty;
    var runner = try Runner.prepare(init, destination);
    const stage = try stageAddon(&runner, framework);
    const web = try path(a, destination, "web");
    {
        // SKGo's temporary enclosing packageManager declaration pins vp create.
        const bootstrap = try path(a, destination, "package.json");
        try write(io, bootstrap, "{\"private\":true,\"packageManager\":\"pnpm@" ++ frontend.pnpm ++ "\"}\n");
        defer Io.Dir.cwd().deleteFile(io, bootstrap) catch {};
        var create_args: std.ArrayList([]const u8) = .empty;
        try create_args.appendSlice(a, &.{ runner.vp, "create", "svelte@" ++ frontend.sv });
        if (!interactive) {
            try create_args.append(a, "--no-interactive");
            try runner.env.put("CI", "1");
        }
        try create_args.appendSlice(a, &.{ "--no-git", "--no-agent", "--no-editor", "--no-hooks", "--approve-builds", "--package-manager", "pnpm", "--", "web" });
        try create_args.appendSlice(a, upstream);
        try runner.run("create upstream SvelteKit application", destination, create_args.items);
    }
    const pkg = package(a, io, web) catch |err| {
        std.debug.print("zkit: upstream creation did not produce a readable web/package.json (canceled or incomplete): {s}\n", .{@errorName(err)});
        return error.UpstreamCreationIncomplete;
    };
    const deps = field(pkg, "devDependencies");
    const scripts = field(pkg, "scripts");
    if (!has(deps, "@sveltejs/kit") or has(deps, "@sveltejs/package")) return error.UpstreamDidNotCreateSvelteKitApplication;
    for ([_][]const u8{ "AGENTS.md", "CLAUDE.md", "GEMINI.md", ".mcp.json", ".claude", ".cursor", ".gemini", ".opencode", ".vscode/mcp.json", ".github/skills", ".github/agents" }) |agent_file| {
        if (exists(io, try path(a, web, agent_file))) return error.AgentToolsBelongAtApplicationRoot;
    }
    const examples = exists(io, try path(a, web, "src/routes/sverdle"));
    const vitest = has(deps, "vitest") and has(scripts, "test:unit");
    const storybook = has(scripts, "storybook") and
        (exists(io, try path(a, web, ".storybook/main.ts")) or exists(io, try path(a, web, ".storybook/main.js")));
    const addon = try std.fmt.allocPrint(a, "file:{s}=starter:{s}+name:{s}", .{ stage, if (examples) "examples" else "minimal", try encode(a, app_name) });
    var add: std.ArrayList([]const u8) = .empty;
    try add.appendSlice(a, &.{ "node_modules/.bin/vp", "dlx", "--", "sv@" ++ frontend.sv, "add" });
    if (!vitest) try add.append(a, "vitest=usages:unit,component");
    try add.appendSlice(a, &.{ addon, "--no-git-check", "--no-download-check", "--no-install" });
    try runner.env.put("CI", "1");
    try runner.run("apply z-kit through sv add", web, add.items);
    try verifyIntegration(a, io, web, examples);
    // The isolated installer needs its own esbuild allowance, without taking
    // the app workspace's catalog/overrides into its temporary installation.
    if (!storybook) try runner.run("install upstream Storybook", web, &.{
        "node_modules/.bin/vp", "exec",              "--",   "pnpm",           "dlx",      "--ignore-workspace", "--allow-build", "esbuild",             "--package", "create-storybook@10.6.2", "--package", "@storybook/sveltekit@10.6.2", "--",
        "create-storybook",     "--package-manager", "pnpm", "--skip-install", "--no-dev", "--no-features",      "--yes",         "--disable-telemetry",
    });
    try runner.run("install frontend dependencies", web, &.{ "node_modules/.bin/vp", "install", "--no-frozen-lockfile" });
    const installed = try package(a, io, web);
    for ([_][]const u8{ "build", "check", "test:unit", "storybook" }) |script| {
        if (!has(field(installed, "scripts"), script)) return error.UpstreamToolSetupIncomplete;
    }
    for ([_][]const u8{ "vp", "vitest", "storybook" }) |tool| {
        if (!exists(io, try path(a, web, try std.fmt.allocPrint(a, "node_modules/.bin/{s}", .{tool})))) return error.UpstreamToolNotInstalled;
    }
    const component_tests = has(field(installed, "devDependencies"), "@vitest/browser-playwright");
    if (component_tests)
        try runner.run("install component-test browser", web, &.{ "node_modules/.bin/vp", "exec", "--", "playwright", "install", "chromium" });
    try scaffold(&runner, destination, framework, app_name, component_tests);
    try runner.run("format and check frontend", web, &.{ "node_modules/.bin/vp", "check", "--fix" });
    try runner.run("check Svelte", web, &.{ "node_modules/.bin/vp", "run", "check" });
    try runner.run("build application", destination, &.{ "zig", "build" });
    std.debug.print("\nzkit: created {s} application in {s}\n\n  cd {s}\n  zig build dev\n\nOpen http://127.0.0.1:5173\n", .{ if (examples) "examples" else "empty", destination, destination });
}

fn stageAddon(runner: *Runner, framework: []const u8) ![]const u8 {
    const a = runner.allocator;
    const io = runner.init.io;
    const source = try path(a, framework, "tooling/sv");
    const body = try read(a, io, try path(a, source, "addon.js"));
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(body, &digest, .{});
    const home = runner.env.get("HOME") orelse return error.HomeNotFound;
    const stage = try std.fmt.allocPrint(a, "{s}/Library/Caches/zkit/sv-{x}", .{ home, digest[0..8] });
    const pkg = try path(a, stage, "package");
    if (exists(io, try path(a, pkg, "node_modules/sv/package.json"))) return pkg;
    try Io.Dir.cwd().createDirPath(io, stage);
    try runner.run("pack isolated sv add-on", source, &.{ runner.vp, "pm", "pack", "--pack-destination", stage });
    const tarball = try path(a, stage, "zkit-sv-0.0.0-dev.tgz");
    try runner.run("unpack isolated sv add-on", stage, &.{ "tar", "-xzf", tarball });
    try runner.run("install sv add-on peer", pkg, &.{ runner.vp, "install", "--prod", "--", "--ignore-workspace" });
    return pkg;
}

fn encode(a: Allocator, value: []const u8) ![]const u8 {
    var out: std.ArrayList(u8) = .empty;
    for (value) |c| {
        if (std.ascii.isAlphanumeric(c) or c == '-' or c == '_' or c == '.') {
            try out.append(a, c);
        } else try out.appendSlice(a, try std.fmt.allocPrint(a, "%{X:0>2}", .{c}));
    }
    return out.toOwnedSlice(a);
}

fn scaffold(runner: *Runner, destination: []const u8, framework: []const u8, name: []const u8, component_tests: bool) !void {
    const a = runner.allocator;
    const io = runner.init.io;
    const relative = try std.fs.path.relativeAlloc(a, "/", null, destination, framework);
    // Escape the contents of the Zig string, including unusual paths.
    const zon = try std.fmt.allocPrint(a,
        \\.{{
        \\    .name = .zkit_app,
        \\    .fingerprint = 0x{x},
        \\    .version = "0.0.0",
        \\    .minimum_zig_version = "0.18.0-dev.543+fa4f5b262",
        \\    .dependencies = .{{ .zkit = .{{ .path = "{f}" }} }},
        \\    .paths = .{{ "build.zig", "build.zig.zon", "web" }},
        \\}}
        \\
    , .{ fingerprint(io), std.zig.fmtString(relative) });
    try write(io, try path(a, destination, "build.zig.zon"), zon);
    try write(io, try path(a, destination, "build.zig"), @embedFile("templates/build.zig"));
    try write(io, try path(a, destination, ".gitignore"), "/.zig-cache/\n/zig-out/\n/web/node_modules/\n/web/.svelte-kit/\n/web/build/\n");
    try write(io, try path(a, destination, "README.md"), try std.fmt.allocPrint(a,
        \\# {s}
        \\
        \\An ordinary SvelteKit application behind the Zig development server.
        \\
        \\Use the current Zig development build, Node 24 and VitePlus 1.4.0.
        \\The CLI installed dependencies and built this application. From this root:
        \\
        \\```sh
        \\zig build install-web  # fresh clone: install locked frontend dependencies
        \\zig build check
        \\zig build
        \\zig build dev
        \\```
        \\
        \\Open http://127.0.0.1:5173. Ctrl-C stops Vite and releases its socket/port.
        \\Use `zig build dev -- --port 5180` to select another port.
        \\`web/` contains the upstream frontend, Vitest and Storybook.
        \\Run `vp run test` or `vp run storybook` from `web/`.
        \\{s}
        \\
        \\The local z-kit source dependency is declared in `build.zig.zon`; preserve
        \\or update that path when moving/cloning the app. Framework releases are not
        \\published yet. This foundation uses Vite for rendering and frontend HMR;
        \\native remotes and standalone production serving are later features.
        \\Frontend `dev` and `preview` also start this Zig development session.
        \\
    , .{ name, if (component_tests) "Component tests need `vp exec playwright install chromium` after a fresh clone." else "" }));
}

fn fingerprint(io: Io) u64 {
    var random: [4]u8 = undefined;
    io.random(&random);
    const id = std.math.clamp(std.mem.readInt(u32, &random, .little), 1, 0xfffffffe);
    const checksum = std.hash.Crc32.hash("zkit_app");
    return @as(u64, checksum) << 32 | id;
}

test "unattended defaults precede variadic addons and preserve demo/jsdoc" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const result = try upstreamArgs(arena.allocator(), &.{ "--template", "demo", "--types", "jsdoc", "--add", "tailwindcss=plugins:none" }, false);
    try std.testing.expectEqualStrings("demo", result[1]);
    try std.testing.expectEqual(@as(usize, 6), result.len);
    const partial = try upstreamArgs(arena.allocator(), &.{ "--add", "tailwindcss=plugins:none" }, false);
    try std.testing.expectEqualStrings("--template", partial[0]);
    try std.testing.expectEqualStrings("--add", partial[4]);
    const terminal = try upstreamArgs(arena.allocator(), &.{}, true);
    try std.testing.expectEqual(@as(usize, 0), terminal.len);
    try std.testing.expectError(error.ChooseMinimalOrDemo, upstreamArgs(arena.allocator(), &.{"--template=library"}, true));
    try std.testing.expectError(error.UpstreamTargetMustBeWeb, upstreamArgs(arena.allocator(), &.{"elsewhere"}, false));
    try std.testing.expectError(error.AgentToolsBelongAtApplicationRoot, upstreamArgs(arena.allocator(), &.{ "--add", "ai-tools=ide:cursor" }, true));
}

test "successful sv exit is insufficient without the integration edits" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(std.testing.io, .{ .sub_path = "package.json", .data = "{\"scripts\":{\"dev\":\"vp dev\"}}" });
    const root = try tmp.dir.realPathFileAlloc(std.testing.io, ".", std.testing.allocator);
    defer std.testing.allocator.free(root);
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    try std.testing.expectError(error.SvDidNotApplyZkitIntegration, verifyIntegration(arena.allocator(), std.testing.io, root, false));
}
