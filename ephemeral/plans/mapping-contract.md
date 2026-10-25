# Zig → JavaScript mapping build brief

Build Type Projector for Zig 0.17.0: ordinary native types become JavaScript application values, with TypeScript and checked-JavaScript/JSDoc declarations generated from **one mapping**. Documentation only. Start with the slice below; eventual Go Polytype parity and Swift support can follow on Zig's terms.

## Mapping

Select roots explicitly and traverse their reachable types. Metadata is optional when defaults suffice.

| Zig data | JavaScript / declaration meaning |
| --- | --- |
| bool | boolean |
| Runtime signed/unsigned integers through 64 bits, including u7/u24 | number, with integer/native-range/precision checks |
| f16, f32, f64 | number, using ordinary float conversion |
| []const u8, []u8 | UTF-8 string by default; reject invalid text |
| Struct, named or anonymous | Object with its fields; native names are default wire names |
| [N]T; []T / []const T | Array of mapped T; fixed arrays retain and enforce exact N |
| Exhaustive enum | String labels, defaulting to native tag names |
| Tagged union | Object with discriminator "type" by default and a tag-name string label |
| Single-item *T / *const T | T's mapped value; indirection alone adds no null |
| ?T | Record-field rules below; elsewhere, null or mapped T |

Compose types recursively: lists of unions, required optional lists, anonymous record roots and collection elements need no Go-derived position restrictions. Support productive recursive types with finite values. Stage combinations as needed; diagnose unfinished cases.

Union object payloads contribute fields alongside the discriminator. Inline and pointer-backed payloads have the same wire shape; authors choose native storage. A tag-only variant emits just its discriminator. Allow explicit enum/tag labels and discriminator names; reject duplicate labels or discriminator/payload name collisions.

A byte-slice override can request a numeric byte array instead of text. Binary transports can follow later. Slices carry runtime length without automatic growth; callers can use an ArrayList's items slice, but do not reflect ArrayList/HashMap internals as API records.

## Native fields and configuration

A public namespace constant configures names, descriptions and required overrides. Spelling is illustrative; no empty configuration is required.

```zig
const Profile = struct {
    display_name: []const u8,
    nickname: ?[]const u8,
    owner: ?[]const u8,

    pub const projection = .{
        .description = "A delivery profile.",
        .fields = .{
            .display_name = .{
                .name = "display-name",
                .description = "Name shown to the recipient.",
            },
            .owner = .{ .required = true },
        },
    };
};
```

There are three field cases:

- Plain T: required key with a non-null value.
- Default ?T, such as nickname: native null omits the key; an absent key decodes to native null; explicit wire null rejects. Declare `nickname?: string`.
- Configured required ?T, such as owner: native null emits explicit null; a missing key rejects. Declare `owner: string | null`.

“Required” means **key presence**, not forced unwrapping or changing ?T into T. There is no Presence/Nullable wrapper or separate nullable flag. Native ?T cannot preserve absent/null/value as three distinct states. Reject own properties containing undefined; reading an absent property as undefined does not make it an explicit property. Validate configuration keys; descriptions come from metadata, not reflected comments.

## Safety and implementation boundaries

Initially, require integers to fit both native bounds and JavaScript's safe-integer domain (±9007199254740991). Reject fractional integer input, nonfinite floats and conversion overflow. Ordinary float rounding is allowed, including JS 0.1 into f16/f32. Use application-target semantics rather than accidentally reflecting host widths; choose the mechanism during implementation.

Decode rejects wrong kinds and unknown/missing required keys. Reject comptime_int/comptime_float runtime fields; ordinary literals coerced to supported types are fine. Keep this a data mapper: refuse maps, functions, errors, type/opaque values and unsupported pointer forms with a useful path, rather than any. Wider integers/f80/f128 and graph cycles are outside the first implementation, not inherently invalid future features. Document allocator ownership, borrowed-input lifetimes and result cleanup; clean up partial failures. Owned decoding is a starting strategy, not a required API.

## First build and proof

1. Create one public ./example using the package interface and a real Zig build. Project basic scalars and a record into both TS and JSDoc. Compile representative valid and invalid consumers; check the intended type errors, not merely any compiler failure.
2. Extend that same example with enums, unions, native optionals and pointer payloads. Independently check JavaScript values, key absence/null and native ranges/lengths. Exercise allocation cleanup where decoding allocates.
3. Add a small Zig→canonical-JS→Zig devalue exchange using the standalone shared Go/Zig runtime: major 5, pinned to 5.9.4 for reproducibility. JSON and devalue are distinct encodings of mapped values; do not build another runtime here.

These checks establish the slice. Full parity, malformed-wire corpora, cache/publication behavior and future features are not first-delivery gates.

## Schema and later work

Every unsigned integer's JSON Schema **must** emit `type: "integer"` and explicit `minimum: 0`. Preserve fixed-array length; standard OpenAI minItems/maxItems are planned supported capability. Profiles must report/refuse unrepresentable constraints, including omission-versus-null conflicts. A modern general-schema dialect remains post-initial-release work; no schema backend is implemented here.

Optional references: [example fixture](example-acceptance.md), [peer feature/test research](feature-parity.md), [pinned sources](mapping-evidence.md), [OpenAI compatibility](../../docs/openai-json-schema.md). References are optional, not additional acceptance gates.
