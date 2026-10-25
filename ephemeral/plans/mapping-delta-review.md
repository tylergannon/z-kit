# Mapping brief: decisions lost in compression

Reviewed the first proposal (`026411b`), the last exhaustive version (`df35b9b`), and the short brief (`c77d7bf`). The user subsequently requested folding these findings into the [current brief](mapping-contract.md). The table records the resulting decisions; it does not restore the original admission matrix or add acceptance gates.

## Folded into the brief

| Topic | Selected direction |
| --- | --- |
| Configuration shape | The [compiler experiment](../projection-shape-lab/README.md) supports a typed, shallow `Projection(@This())`. Anonymous children and imported types own their own configuration. This replaces the brief's untyped illustrative literal without requiring a recursive configuration tree. |
| Naming | lowerCamelCase fields/default labels, UpperCamelCase type names, deterministic word/acronym splitting, no field-name overrides. Escape keywords without changing wire keys; reject empty/unrepresentable names and collisions; expose the name map. |
| Stacked optional/null mappings | Initially reject `??T` and pointers to optionals. Do not introduce an accidental third presence state or contradict the plain-field non-null rule. |
| Struct fields and defaults | Project runtime fields of auto/extern/packed structs. Initially reject tuple structs and comptime fields. Namespace declarations are not data; native defaults do not alter key presence. |
| Union payload shapes | Flattened object payloads and tag-only cases; diagnose scalar/optional payloads initially. |
| Fixed-array declarations | Preserve N and enforce it in native decoding/schema. TS/JSDoc initially use ordinary arrays. |
| Runtime identity | Reject cyclic values; repeated references may be copied without preserving identity. Recursive type discovery remains a separate capability. |

These are decisions for the affected slices, not claims that those slices have been implemented.

## Keep deferred or removed

Keep the user's native optional defaults, per-field required override, ordinary float conversions, default UTF-8 slices, recursive composition, anonymous records, and optional metadata. Do not restore Presence wrappers, exact-f32 round-trip requirements, signed-zero normalization, mandatory empty config, per-byte annotations, Go-specific field-position rules or compulsory owned-result APIs.

Keep the selected unsigned-schema lower bound and fixed-array constraints. The OpenAI capability reference already records profile limits and the omission/null mismatch; it does not need another specification here.

The brief now requires dense arrays and refusal of special runtime values and duplicate wire keys. Diagnostics should identify the bad field/value, but frozen categories, message text and a full malformed-wire corpus are not first-delivery gates. Cache fingerprints, publication repair, packaging and larger parity suites remain later work.

The findings are folded into the concise brief. The mapper remains unimplemented.
