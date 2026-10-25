# Typed projection configuration experiment

**Selected in the build brief:** use `pub const projection: projector.Projection(@This()) = ...`. Generate only the immediate configuration fields. Each child struct owns its own configuration, including anonymous structs written inside arrays or slices. Do not recursively mirror the entire native type graph into the parent's configuration type.

These retained experiments now exercise the internal z-kit projector module. They prove the configuration core, not the full mapping implementation. The [build brief](../plans/mapping-contract.md) adopts this verified struct-configuration shape; the experiment does not implement its remaining mapping policies.

## What the author writes

```zig
const Order = struct {
    shipping: Address, // Can be imported from another file or module.
    lines: []const struct {
        sku: []const u8,
        quantity: u16,

        pub const projection: projector.Projection(@This()) = .{
            .description = "An order line.",
            .fields = .{
                .quantity = .{ .description = "Units in this line." },
            },
        };
    },

    pub const projection: projector.Projection(@This()) = .{
        .fields = .{
            .shipping = .{ .description = "Delivery address for this order." },
            .lines = .{ .description = "Purchased items, in order." },
        },
    };
};
```

The parent describes its `lines` field; the anonymous element describes its own fields. The imported `Address` owns its reusable description and field options. A field's contextual description and its type's description remain separate. This requires no parent-side element paths, nested override trees, or special naming test for “anonymous” types. Extract an inline struct into a named type when reuse or readability warrants it; naming is not required for configuration to work.

## Why the helper stays small

[Projection](../../src/projector.zig) derives an enum from the immediate native field names, then uses the standard library's `EnumFieldStruct` to construct a record whose fields all hold `FieldOptions`, with defaults. The outer record holds the type description and that field record. This has direct pinned standard-library precedent, rather than merely being possible with compiler internals.

It does not ask for each child's configuration while constructing the parent's configuration type. A separate type walker discovers child configurations through arrays, slices, pointers, optionals and union payloads, remembering visited types. This separation is why self-recursive and mutually recursive records terminate. It does not prove runtime cycle handling or serialization.

## Executed evidence

The [fixtures](../../test/shape_test.zig) exercise actual values and generated types. The [module consumer](../../test/module_consumer.zig) also checks an imported model through a real Zig build graph with a shared projector module.

The [explicit comptime proof](../../test/comptime_test.zig) compiles with `-fno-emit-bin`: its top-level `comptime` assertions read the completed self-owned configuration, derive another struct type and an array length from it, and construct text. The configuration initializer itself also reflects its enclosing native struct. Anonymous children, imported types and a recursive record participate in these assertions. No executable is produced for this proof. A runtime-dependent metadata initializer is separately required to fail compilation.

| Case | Result established |
| --- | --- |
| Exact `Projection(@This())` declaration | Resolves inside its own struct; configured and omitted option defaults are available. |
| Forced compile-time consumption | Completed metadata drives new types, array lengths and text entirely at comptime; importing modules also consume it in a top-level comptime block. |
| Anonymous array/slice elements, nested records, multidimensional arrays | Each local `@This()` identifies its own struct; child metadata is recovered correctly. |
| Imported/reused types, aliases and unconfigured dependencies | Configuration identity is preserved; repeated types are visited once; absent metadata uses defaults. |
| Self and mutual recursion; unions with inline/pointer payloads | Configuration synthesis stays shallow; type discovery terminates. |
| Native construction, field order and defaults | Ordinary literals work; metadata follows native field order; native default values do not determine key presence. |
| Invalid field/option/value, wrong owner, non-struct target | Compilation refuses the intended misuse. |
| Typed array alternative | Entries can be read at compile time; field enums are checked; duplicate entries need explicit validation. |

The compact machine-readable outcome is [results.json](results.json). The runner checks compiler failure reasons, not just nonzero exits.

## Tradeoffs and limits

- Prefer the named configuration record to the array: less syntax, native named-field checking and no duplicate-entry scan. The array is a working alternative, not a requirement imposed by Zig.
- Keep the explicit type annotation. A previously inferred `projection = .{ ... }` value has its own anonymous type and does **not** automatically convert to this generated type. Supporting that spelling would require additional normalization.
- Discovery uses the exact public declaration name. A private or misspelled declaration is undiscovered, and Zig's lazy analysis means its annotation alone does not guarantee a diagnostic. Do not claim metadata declaration typos are checked. The pinned `@hasDecl` documentation warns about this class of fallback.
- A data field and namespace declaration cannot both be named `projection`. The brief now selects this spelling with the demonstrated collision.
- For types whose source the caller cannot edit, defaults work and the parent can describe its own field. Child-field metadata overrides would need a separate explicit mechanism; none is designed here.
- Metadata adds no instance field; the fixture also checks equal native sizes. This does not promise every metadata byte disappears from every compiled binary.
- The helper currently configures structs. Union/enum options, naming inflection, foreign declarations, codecs, complete admission rules, allocator behavior and performance are outside this proof.

## Reproduction and source authority

Run `python3 run.py` here with `ZIG017_EXE` set to an external Zig **0.17.0** compiler, or use the ignored local distribution. The runner keeps caches and full diagnostic logs under `.local/`; it writes the compact tracked result separately. It also runs the repository-root `zig build test` for the 14 configuration/module tests and the compile-only proof. Fixtures live in `../../test`; the shared implementation lives in `../../src/projector.zig`. Source hashes cover the module, fixtures, root build/manifest and runner.

The local Darwin arm64 release archive was reacquired from the official URL and its SHA256 verified against the cache's acquisition record. Exact compiler/archive/source identities are recorded in the result. The installed Homebrew compiler is a later development version and was not substituted. The reference cache was not modified.

Original pinned sources consulted: [EnumFieldStruct](/Users/tyler/zig-token-cache/official/source/zig-0.17.0/lib/std/enums.zig:29), [FieldEnum](/Users/tyler/zig-token-cache/official/source/zig-0.17.0/lib/std/meta.zig:405), [typed std options](/Users/tyler/zig-token-cache/official/source/zig-0.17.0/lib/std/std.zig:118), [type construction test](/Users/tyler/zig-token-cache/official/source/zig-0.17.0/test/behavior/type.zig:129), [public declaration discovery](/Users/tyler/zig-token-cache/official/language-reference-0.17.0.txt:14115), and [build modules](/Users/tyler/zig-token-cache/official/source/zig-0.17.0/lib/std/Build.zig:704).
