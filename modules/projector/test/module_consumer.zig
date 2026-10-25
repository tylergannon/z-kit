const std = @import("std");
const projector = @import("projector");
const models = @import("models");

const Batch = struct {
    account: models.Account,
    entries: []const struct {
        account: models.Account,
        note: ?[]const u8,

        pub const projection: projector.Projection(@This()) = .{
            .description = "One batch entry.",
            .fields = .{ .note = .{ .description = "Optional entry note." } },
        };
    },

    pub const projection: projector.Projection(@This()) = .{
        .fields = .{ .entries = .{ .description = "Entries in this batch." } },
    };
};

comptime {
    const imported = projector.config(models.Account);
    const text = std.fmt.comptimePrint("{s}: contact required={}", .{
        imported.description.?, projector.isRequired(models.Account, "contact"),
    });
    if (!std.mem.eql(u8, text, "An account from the models module.: contact required=true")) {
        @compileError("imported module configuration must be fully usable at comptime");
    }
}

test "consumer and imported model share the same generated configuration identity" {
    try std.testing.expect(@TypeOf(models.Account.projection) == projector.Projection(models.Account));
    try std.testing.expectEqualStrings("An account from the models module.", (comptime projector.config(models.Account)).description.?);
    try std.testing.expect(projector.isRequired(models.Account, "contact"));
    const graph = comptime projector.inspect(Batch, .{});
    try std.testing.expectEqual(3, graph.records.len);
    const Entry = @typeInfo(@FieldType(Batch, "entries")).pointer.child;
    try std.testing.expectEqualStrings("One batch entry.", Entry.projection.description.?);
    try std.testing.expect(!projector.isRequired(Entry, "note"));
    const value: Batch = .{
        .account = .{ .account_id = 42, .contact = null },
        .entries = &.{.{ .account = .{ .account_id = 43, .contact = "a@example.test" }, .note = null }},
    };
    try std.testing.expectEqual(43, value.entries[0].account.account_id);
}
