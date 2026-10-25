const projector = @import("projector");

pub const Account = struct {
    account_id: u64,
    contact: ?[]const u8,

    pub const projection: projector.Projection(@This()) = .{
        .description = "An account from the models module.",
        .fields = .{
            .account_id = .{ .description = "Account identifier." },
            .contact = .{ .required = true },
        },
    };
};
