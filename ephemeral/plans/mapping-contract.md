# Zig → JavaScript mapping build brief

Build Type Projector for Zig 0.17.0: native types become JavaScript values, with TypeScript and checked-JavaScript/JSDoc generated from **one mapping**. Add Swift structs and, later, Kotlin data classes here; no public backend/plugin API is required. Struct configuration is compiler-verified; the mapper remains unimplemented.

## Mapping

Select roots explicitly and traverse their reachable types. Metadata is optional when defaults suffice.

| Zig data | JavaScript / declaration meaning |
| --- | --- |
| bool | boolean |
| Runtime integers through 64 bits, including u7/u24 | number, checked for range/integrality/precision |
| f16, f32, f64 | number, using ordinary float conversion |
| []const u8, []u8 | UTF-8 string by default; reject invalid text |
| Struct, named or anonymous | Object with deterministically named fields |
| [N]T; []T / []const T | Array of mapped T; native decoding enforces fixed N |
| Exhaustive enum | String labels |
| Tagged union | Object with discriminator "type" and a string tag |
| Single-item *T / *const T | T's mapped value; indirection alone adds no null |
| ?T | Record-field rules below; elsewhere, null or mapped T |

Compose recursively, including lists of unions, required optional lists and anonymous roots/elements. Support productive recursive types; reject cyclic values. Repeated references may be copied without preserving identity. Stage coverage; diagnose unfinished cases.

Union object payloads contribute fields alongside the discriminator; inline/pointer storage has identical wire shape. Tag-only variants emit just the discriminator. Initially reject scalar/optional payloads. Explicit enum/tag labels and discriminator names are shared across outputs; reject duplicate labels and discriminator/payload collisions.

A byte-slice override requests numeric bytes instead of text. Use an ArrayList's items slice; do not reflect container internals as API records. TS/JSDoc initially use ordinary arrays; retain N in the mapping for native checks and schemas.

## Deterministic naming

Canonical JSON keys use JavaScript lowerCamelCase: `display_name`→`displayName`, `HTTPStatus`→`httpStatus`. Split underscores, lower/digit→upper and acronym→word boundaries; normalize ASCII case, preserving non-ASCII characters. Default enum/tag labels follow this rule. JSON↔JS needs ordinary parsing/stringifying, no field-renaming layer. TS/JSDoc use these keys. Swift/Kotlin use their own type/property conventions and keyword escaping; generated serialization bindings preserve canonical keys. No authored name overrides. Diagnose empty/unrepresentable names and collisions; expose name maps. Derive anonymous names from first root/field paths.

## Native fields and configuration

Use this verified declaration shape. `Projection(T)` generates a shallow struct with known options and defaulted fields matching T. Each child owns its configuration, including anonymous collection elements and imported types; traverse children separately. Metadata is optional.

```zig
const Profile = struct {
    display_name: []const u8,
    nickname: ?[]const u8,
    owner: ?[]const u8,

    pub const projection: projector.Projection(@This()) = .{
        .description = "A delivery profile.",
        .fields = .{
            .display_name = .{
                .description = "Name shown to the recipient.",
            },
            .owner = .{ .required = true },
        },
    };
};
```

The completed constant is usable at comptime for type/text generation. Use the exact public name; private/misspelled declarations are undiscovered. A native field named `projection` conflicts with this declaration. Third-party types use defaults; external metadata overrides are deferred.

Field presence:

- Plain T: required key with a non-null value.
- Default ?T: native null omits the key; absence decodes to null; explicit wire null rejects. Declare `nickname?: string`.
- Required ?T: native null emits explicit null; missing key rejects. Declare `owner: string | null`.

“Required” means **key presence**, preserving ?T. No Presence/Nullable wrapper or third presence state. Initially reject ??T and pointers to optionals. Reject own undefined properties; absence is distinct. Descriptions come from checked metadata, not reflected comments.

## Safety and implementation boundaries

Integers must fit native bounds and JavaScript's safe-integer domain (±9007199254740991). Reject fractional integer input, nonfinite floats and overflow. Ordinary float rounding is allowed, including JS 0.1 into f16/f32. Use application-target widths, not incidental host widths.

Project runtime fields regardless of auto/extern/packed layout; initially reject tuples and comptime fields. Namespace declarations are not data. Native defaults never change key presence. Reject comptime_int/comptime_float runtime values; coerced literals are fine.

Decode checks kinds, required/unknown keys, dense arrays and lengths; refuse special runtime values and duplicate wire keys. Reject maps, functions, errors, type/opaque values and unsupported pointers with a useful path. Wider numbers and binary transports can follow. Document ownership, borrowed lifetimes and cleanup; release partial allocations. The concrete ownership API remains open.

## Generation and reuse

Settle this with the first generator: explicit tracked build steps, separate generation/publication, and an internal mapping retaining native associations. Fingerprints cover reachable shapes/descriptions, target, naming, generator/backend versions and options; use deterministic graph identities, not addresses. Reuse Zig's caches; a cache hit still checks destination state. Never publish only during build configuration.

Track owned paths and hashes. Refuse unowned collisions or edited outputs; remove only unchanged owned stale files. Preserve equal bytes/mtimes. Check-only changes no outputs/ownership state. Stage publication, replace files atomically and make partial failure recoverable; automatic damaged-file repair is not required.

## First build and proof

1. Build one public ./example through the package interface. Project scalars/a record into TS and JSDoc; compile valid/invalid consumers. Check ownership/stale cleanup, unchanged rebuilds and cache invalidation. Emit ordinary modules without barrels.
2. Extend the same example with enums, unions, optionals and pointers. Independently check JS values, absence/null, ranges/lengths and allocation cleanup.
3. Demonstrate Zig→canonical-JS→Zig devalue exchange using the shared Go/Zig runtime, major 5 pinned to 5.9.4. JSON/devalue encode the same mapped values; reuse that runtime.

Full parity and broad malformed-wire corpora are not first-delivery gates.

## Schema and later work

Every unsigned integer's schema **must** emit `type: "integer"` and explicit `minimum: 0`. Preserve fixed-array length using minItems/maxItems in the planned standard OpenAI profile. Refuse/report unrepresentable constraints, including omission/null conflicts. A modern general-schema dialect remains post-initial-release work.

Defer schema generation/validation/providers, manual schema builders, numeric enums and time adapters. JSON codec mechanism comparison remains a separate deferred experiment, not a technical prerequisite for native JSON codecs.

References: [generation design](generation-lifecycle.md), [language projections](language-projections.md), [verified configuration/comptime proof](../projection-shape-lab/README.md), [example](example-acceptance.md), [parity research](feature-parity.md), [sources](mapping-evidence.md), [OpenAI compatibility](../../docs/openai-json-schema.md). These add no acceptance gates.
