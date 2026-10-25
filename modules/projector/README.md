# Internal projector module

z-kit’s data projection component, maintained in the same repository and release. It depends on native types and the Zig standard library; routing, HTTP, Vite and renderer code must remain outside this module. Native mapping/schema helpers must be usable without constructing a server.

The implemented [configuration core](src/projector.zig) supports this verified shape:

```zig
const Account = struct {
    account_id: u32,
    contact: ?[]const u8,

    pub const projection: projector.Projection(@This()) = .{
        .fields = .{ .contact = .{ .required = true } },
    };
};
```

The root build gives model and consumer modules the same `projector` module identity. Completed configuration can drive new types, array lengths and text at comptime, including nested, imported and recursive types. `config`, `isRequired` and `inspect` are internal helpers; the walker is not a complete wire-domain validator.

The [concise mapping brief](ephemeral/plans/mapping-contract.md) locks in ordinary native data, presence rules, descriptions and deterministic JavaScript wire names. Naming, mapping, codecs and JS/TS backends remain to be implemented. Swift and Kotlin data-class projections remain later work.

[Compile evidence and reproduction](ephemeral/projection-shape-lab/README.md), [component acceptance catalog](ephemeral/plans/example-acceptance.md), [language projections](ephemeral/plans/language-projections.md) and [OpenAI schema reference](docs/openai-json-schema.md) retain the research supporting this component. Application integration and generation ownership are defined by the [z-kit baseline](../../ephemeral/plans/z-kit-bringup.md) and [generation lifecycle](../../ephemeral/plans/generation-lifecycle.md).

Run `zig build test` from the repository root with Zig 0.17.0. There is no separate projector package, command or release.
