//! These assertions execute during compilation; no test executable is needed.
const std = @import("std");
const projector = @import("projector.zig");
const external = @import("external.zig");

const Profile = struct {
    display_name: []const u8,
    nickname: ?[]const u8,
    owner: ?[]const u8,

    pub const projection: projector.Projection(@This()) = .{
        .description = std.fmt.comptimePrint("Profile with {d} fields", .{
            @typeInfo(@This()).@"struct".field_names.len,
        }),
        .fields = .{
            .owner = .{ .description = "Profile owner", .required = true },
        },
    };
};

const Batch = struct {
    address: external.Address,
    elements: [2]struct {
        value: u16,
        note: ?[]const u8,

        pub const projection: projector.Projection(@This()) = .{
            .description = std.fmt.comptimePrint("Element with {d} fields", .{
                @typeInfo(@This()).@"struct".field_names.len,
            }),
        };
    },
    pub const projection: projector.Projection(@This()) = .{};
};

const Node = struct {
    value: u16,
    next: ?*const @This(),
    pub const projection: projector.Projection(@This()) = .{
        .description = "Recursive node",
    };
};

fn requiredCount(comptime T: type) usize {
    var count: usize = 0;
    for (@typeInfo(T).@"struct".field_names) |name| {
        if (projector.isRequired(T, name)) count += 1;
    }
    return count;
}

/// Demonstrates a downstream type generator consuming the completed metadata.
/// Required key presence retains the original native optional field type.
fn RequiredFields(comptime T: type) type {
    const count = requiredCount(T);
    var names: [count][:0]const u8 = undefined;
    var types: [count]type = undefined;
    var index: usize = 0;
    for (@typeInfo(T).@"struct".field_names, @typeInfo(T).@"struct".field_types) |name, Field| {
        if (projector.isRequired(T, name)) {
            names[index] = name;
            types[index] = Field;
            index += 1;
        }
    }
    return @Struct(.auto, null, &names, &types, &@splat(.{}));
}

comptime {
    const config = projector.config(Profile);
    if (!std.mem.eql(u8, config.description.?, "Profile with 3 fields")) {
        @compileError("self-reflected configuration initialization did not complete");
    }
    const text = std.fmt.comptimePrint("{s}: required={}", .{
        config.fields.owner.description.?, projector.isRequired(Profile, "owner"),
    });
    if (!std.mem.eql(u8, text, "Profile owner: required=true")) {
        @compileError("configuration must be consumable as compile-time text");
    }

    const Required = RequiredFields(Profile);
    if (!@hasField(Required, "display_name") or !@hasField(Required, "owner") or @hasField(Required, "nickname")) {
        @compileError("generated fields must reflect configured presence, not just native optionality");
    }
    if (@FieldType(Required, "owner") != ?[]const u8) {
        @compileError("required key presence must preserve the optional native field type");
    }
    const value: Required = .{ .display_name = "A name", .owner = null };
    if (value.owner != null) @compileError("generated optional field must accept null");
    const slots: [requiredCount(Profile)]u8 = .{ 1, 2 };
    if (slots.len != 2) @compileError("metadata must drive a compile-time array length");

    const Element = @typeInfo(@FieldType(Batch, "elements")).array.child;
    if (!std.mem.eql(u8, projector.config(Element).description.?, "Element with 2 fields")) {
        @compileError("anonymous child must initialize and expose its own configuration at comptime");
    }
    const ElementRequired = RequiredFields(Element);
    if (!@hasField(ElementRequired, "value") or @hasField(ElementRequired, "note")) {
        @compileError("anonymous child metadata must be usable for type construction");
    }
    const AddressRequired = RequiredFields(external.Address);
    if (!@hasField(AddressRequired, "street_name") or @hasField(AddressRequired, "unit")) {
        @compileError("imported metadata must be usable for type construction");
    }
    const NodeRequired = RequiredFields(Node);
    if (!@hasField(NodeRequired, "value") or @hasField(NodeRequired, "next")) {
        @compileError("recursive native types must permit compile-time metadata consumption");
    }
    if (projector.inspect(Node, .{}).records.len != 1) {
        @compileError("compile-time recursive traversal must terminate by type identity");
    }
}
