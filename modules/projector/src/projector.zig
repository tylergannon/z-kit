//! z-kit projector configuration core. Mapping, codecs and backends are not yet implemented.
const std = @import("std");

pub const FieldOptions = struct {
    description: ?[]const u8 = null,
    required: ?bool = null,
};

/// Only the immediate field names affect this type. Child configuration is
/// owned by the child type, not recursively embedded in the parent's options.
pub fn Projection(comptime T: type) type {
    switch (@typeInfo(T)) {
        .@"struct" => {},
        else => @compileError("Projection expects a struct type"),
    }
    return struct {
        description: ?[]const u8 = null,
        fields: std.enums.EnumFieldStruct(std.meta.FieldEnum(T), FieldOptions, .{}) = .{},
    };
}

pub fn config(comptime T: type) Projection(T) {
    return comptime blk: {
        const result: Projection(T) = if (@hasDecl(T, "projection")) T.projection else .{};
        const info = @typeInfo(T).@"struct";
        for (info.field_names, info.field_types) |name, Field| {
            const options = @field(result.fields, name);
            if (options.required != null and @typeInfo(Field) != .optional) {
                @compileError(@typeName(T) ++ "." ++ name ++ ": required override requires an optional field");
            }
        }
        break :blk result;
    };
}

pub fn isRequired(comptime T: type, comptime name: []const u8) bool {
    if (@typeInfo(@FieldType(T, name)) != .optional) return true;
    return @field(config(T).fields, name).required orelse false;
}

pub const Graph = struct {
    records: []const type = &.{},
    unions: []const type = &.{},
};

fn contains(comptime types: []const type, comptime T: type) bool {
    for (types) |Seen| if (Seen == T) return true;
    return false;
}

/// Exercises configuration discovery separately from configuration synthesis.
/// This is an intentionally small type walker, not a wire-domain validator.
pub fn inspect(comptime T: type, comptime initial: Graph) Graph {
    switch (@typeInfo(T)) {
        .@"struct" => |info| {
            if (contains(initial.records, T)) return initial;
            _ = config(T);
            var graph = initial;
            graph.records = graph.records ++ .{T};
            for (info.field_types) |Field| graph = inspect(Field, graph);
            return graph;
        },
        .@"union" => |info| {
            if (contains(initial.unions, T)) return initial;
            var graph = initial;
            graph.unions = graph.unions ++ .{T};
            for (info.field_types) |Field| graph = inspect(Field, graph);
            return graph;
        },
        .array => |info| return inspect(info.child, initial),
        .optional => |info| return inspect(info.child, initial),
        .pointer => |info| return inspect(info.child, initial),
        else => return initial,
    }
}
