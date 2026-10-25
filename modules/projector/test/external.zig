const projector = @import("projector");

pub const Address = struct {
    street_name: []const u8,
    unit: ?[]const u8,

    pub const projection: projector.Projection(@This()) = .{
        .description = "A reusable postal address.",
        .fields = .{
            .street_name = .{ .description = "Street and number." },
        },
    };
};

// An externally defined type needs no empty opt-in declaration for defaults.
pub const Unconfigured = struct { value: u32 };
