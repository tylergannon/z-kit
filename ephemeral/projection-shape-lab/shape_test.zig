const std = @import("std");
const projector = @import("projector.zig");
const external = @import("external.zig");

const Profile = struct {
    display_name: []const u8,
    nickname: ?[]const u8,
    owner: ?[]const u8,

    pub const projection: projector.Projection(@This()) = .{
        .description = "A delivery profile.",
        .fields = .{
            .display_name = .{ .description = "Name shown to the recipient." },
            .owner = .{ .required = true },
        },
    };
};

const Order = struct {
    shipping: external.Address,
    billing: ?external.Address,
    lines: []const struct {
        sku: []const u8,
        quantity: u16,
        destination: external.Address,

        pub const projection: projector.Projection(@This()) = .{
            .description = "An order line.",
            .fields = .{
                .quantity = .{ .description = "Units in this line." },
            },
        };
    },
    snapshots: [2]struct {
        label: []const u8,
        position: struct {
            latitude: f64,
            longitude: f64,

            pub const projection: projector.Projection(@This()) = .{
                .description = "A geographic position.",
                .fields = .{ .latitude = .{ .description = "Latitude in degrees." } },
            };
        },

        pub const projection: projector.Projection(@This()) = .{
            .fields = .{ .label = .{ .description = "Snapshot label." } },
        };
    },
    imported_defaults: external.Unconfigured,

    pub const projection: projector.Projection(@This()) = .{
        .description = "An order.",
        .fields = .{
            .shipping = .{ .description = "Where this order is delivered." },
            .billing = .{ .required = true },
            .lines = .{ .description = "Purchased items, in order." },
        },
    };
};

const Node = struct {
    label: []const u8,
    next: ?*const @This(),
    children: []const @This(),

    pub const projection: projector.Projection(@This()) = .{
        .description = "A recursive node.",
        .fields = .{ .next = .{ .description = "The next node, if any." } },
    };
};

const Left = struct {
    right: ?*Right,
    pub const projection: projector.Projection(@This()) = .{
        .description = "The left side.",
    };
};
const Right = struct {
    left: ?*Left,
    pub const projection: projector.Projection(@This()) = .{
        .description = "The right side.",
    };
};

const Event = union(enum) {
    created: struct {
        actor: external.Address,
        pub const projection: projector.Projection(@This()) = .{
            .description = "A creation payload.",
        };
    },
    updated: *const Profile,
    removed: void,
};

test "self-owned configuration has known types, sparse defaults and no instance field" {
    try std.testing.expect(@TypeOf(Profile.projection) == projector.Projection(Profile));
    try std.testing.expect(@TypeOf(Profile.projection.fields.owner) == projector.FieldOptions);
    try std.testing.expectEqualStrings("A delivery profile.", Profile.projection.description.?);
    try std.testing.expectEqual(@as(?[]const u8, null), Profile.projection.fields.nickname.description);
    try std.testing.expect(!@hasField(Profile, "projection"));
    try std.testing.expect(@hasDecl(Profile, "projection"));
    const WithoutMetadata = struct {
        display_name: []const u8,
        nickname: ?[]const u8,
        owner: ?[]const u8,
    };
    try std.testing.expectEqual(@sizeOf(WithoutMetadata), @sizeOf(Profile));
    try std.testing.expect(projector.isRequired(Profile, "display_name"));
    try std.testing.expect(!projector.isRequired(Profile, "nickname"));
    try std.testing.expect(projector.isRequired(Profile, "owner"));
}

test "anonymous slice and fixed-array elements own their configuration" {
    const Line = @typeInfo(@FieldType(Order, "lines")).pointer.child;
    const Snapshot = @typeInfo(@FieldType(Order, "snapshots")).array.child;
    const Position = @FieldType(Snapshot, "position");
    try std.testing.expectEqualStrings("An order line.", (comptime projector.config(Line)).description.?);
    try std.testing.expectEqualStrings("Units in this line.", Line.projection.fields.quantity.description.?);
    try std.testing.expectEqualStrings("Snapshot label.", Snapshot.projection.fields.label.description.?);
    try std.testing.expectEqualStrings("A geographic position.", Position.projection.description.?);
    try std.testing.expect(@TypeOf(Line.projection) == projector.Projection(Line));
    try std.testing.expect(@TypeOf(Position.projection) == projector.Projection(Position));
}

test "field descriptions and reusable imported type descriptions remain distinct" {
    try std.testing.expectEqualStrings("Where this order is delivered.", Order.projection.fields.shipping.description.?);
    try std.testing.expectEqualStrings("A reusable postal address.", external.Address.projection.description.?);
    try std.testing.expectEqualStrings("Street and number.", external.Address.projection.fields.street_name.description.?);
    try std.testing.expect(!projector.isRequired(external.Address, "unit"));
    try std.testing.expect(projector.isRequired(Order, "billing"));
    const graph = comptime projector.inspect(Order, .{});
    try std.testing.expectEqual(6, graph.records.len);
    try std.testing.expectEqual(0, graph.unions.len);
}

test "configuration is optional for roots and dependencies" {
    const Plain = struct { value: u32 };
    const Empty = struct {};
    try std.testing.expectEqual(@as(?[]const u8, null), (comptime projector.config(Plain)).description);
    try std.testing.expectEqual(@as(?bool, null), (comptime projector.config(external.Unconfigured)).fields.value.required);
    try std.testing.expectEqual(0, @typeInfo(@TypeOf((comptime projector.config(Empty)).fields)).@"struct".field_names.len);
}

test "configuration synthesis is shallow and recursive type inspection terminates" {
    const node_graph = comptime projector.inspect(Node, .{});
    const mutual_graph = comptime projector.inspect(Left, .{});
    try std.testing.expectEqual(1, node_graph.records.len);
    try std.testing.expectEqual(2, mutual_graph.records.len);
    try std.testing.expect(@TypeOf(Node.projection.fields.next) == projector.FieldOptions);
    const node: Node = .{ .label = "root", .next = null, .children = &.{} };
    try std.testing.expectEqualStrings("root", node.label);
}

test "union payload records and optional pointer collection wrappers do not alter config ownership" {
    const graph = comptime projector.inspect([]const ?*const Event, .{});
    try std.testing.expectEqual(3, graph.records.len);
    try std.testing.expectEqual(1, graph.unions.len);
    const Created = @FieldType(Event, "created");
    try std.testing.expectEqualStrings("A creation payload.", Created.projection.description.?);
}

test "aliases preserve type and configuration identity" {
    const Alias = Profile;
    try std.testing.expect(projector.Projection(Alias) == projector.Projection(Profile));
    try std.testing.expectEqualStrings(Profile.projection.description.?, Alias.projection.description.?);
}

test "typed array alternative is readable and iterable at compile time" {
    const alternative = @import("array_alternative.zig");
    const Sample = struct {
        title: []const u8,
        owner: ?[]const u8,

        pub const projection: alternative.Projection(@This()) = .{
            .fields = &.{
                .{ .field = .title, .options = .{ .description = "A title." } },
                .{ .field = .owner, .options = .{ .required = true } },
            },
        };
    };
    const names = comptime blk: {
        var joined: []const u8 = "";
        for (alternative.config(Sample).fields) |entry| {
            joined = joined ++ @tagName(entry.field) ++ ";";
        }
        break :blk joined;
    };
    try std.testing.expectEqualStrings("title;owner;", names);
    try std.testing.expect((comptime alternative.config(Sample)).fields[1].options.required.?);
}

test "native values with anonymous elements remain ordinary literals" {
    const order: Order = .{
        .shipping = .{ .street_name = "Main Street", .unit = null },
        .billing = null,
        .lines = &.{.{
            .sku = "SKU-1",
            .quantity = 2,
            .destination = .{ .street_name = "Other Street", .unit = "B" },
        }},
        .snapshots = .{
            .{ .label = "start", .position = .{ .latitude = 45.0, .longitude = -122.0 } },
            .{ .label = "end", .position = .{ .latitude = 46.0, .longitude = -123.0 } },
        },
        .imported_defaults = .{ .value = 42 },
    };
    try std.testing.expectEqual(2, order.lines[0].quantity);
    try std.testing.expectEqualStrings("Other Street", order.lines[0].destination.street_name);
    try std.testing.expectEqual(46.0, order.snapshots[1].position.latitude);
}

test "configuration annotation does not evaluate unrelated namespace declarations" {
    const Sample = struct {
        value: u8,
        pub const unrelated = @compileError("An unrelated declaration must remain lazy");
        pub const projection: projector.Projection(@This()) = .{};
    };
    const graph = comptime projector.inspect(Sample, .{});
    try std.testing.expectEqual(1, graph.records.len);
}

test "nested namespace type and multidimensional anonymous records keep local This" {
    const Container = struct {
        pub const Item = struct {
            code: u16,
            pub const projection: projector.Projection(@This()) = .{
                .fields = .{ .code = .{ .description = "A nested type code." } },
            };
        };
        matrix: [2][3]struct {
            code: u16,
            pub const projection: projector.Projection(@This()) = .{
                .fields = .{ .code = .{ .description = "A matrix element code." } },
            };
        },
        item: Item,
        pub const projection: projector.Projection(@This()) = .{};
    };
    const MatrixItem = @typeInfo(@typeInfo(@FieldType(Container, "matrix")).array.child).array.child;
    try std.testing.expectEqualStrings("A matrix element code.", MatrixItem.projection.fields.code.description.?);
    try std.testing.expectEqualStrings("A nested type code.", Container.Item.projection.fields.code.description.?);
    const graph = comptime projector.inspect(Container, .{});
    try std.testing.expectEqual(3, graph.records.len);
}

test "private or misspelled metadata is not discoverable through the public convention" {
    const Private = struct {
        value: u8,
        const projection: projector.Projection(@This()) = .{
            .description = "Private metadata is not a public contract.",
        };
    };
    const Misspelled = struct {
        value: u8,
        pub const projeciton: projector.Projection(@This()) = .{
            .description = "Misspelled metadata is not discovered.",
        };
    };
    try std.testing.expect(!@hasDecl(Private, "projection"));
    try std.testing.expect(!@hasDecl(Misspelled, "projection"));
    try std.testing.expectEqual(@as(?[]const u8, null), (comptime projector.config(Private)).description);
    try std.testing.expectEqual(@as(?[]const u8, null), (comptime projector.config(Misspelled)).description);
}

test "field order and native struct defaults are independent from metadata defaults" {
    const Sample = struct {
        zeta: u16 = 10,
        alpha: ?u16 = 20,
        pub const projection: projector.Projection(@This()) = .{
            .fields = .{
                .alpha = .{ .description = "Declared second, configured first." },
                .zeta = .{ .description = "Declared first, configured second." },
            },
        };
    };
    const field_names = @typeInfo(@TypeOf(Sample.projection.fields)).@"struct".field_names;
    try std.testing.expectEqualStrings("zeta", field_names[0]);
    try std.testing.expectEqualStrings("alpha", field_names[1]);
    try std.testing.expect(projector.isRequired(Sample, "zeta"));
    try std.testing.expect(!projector.isRequired(Sample, "alpha"));
    const value: Sample = .{};
    try std.testing.expectEqual(10, value.zeta);
    try std.testing.expectEqual(@as(?u16, 20), value.alpha);
}
