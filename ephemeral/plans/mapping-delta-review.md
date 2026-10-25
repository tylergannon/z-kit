# Mapping brief: decisions lost in compression

Reviewed the first proposal (`026411b`), the last exhaustive version (`df35b9b`), and the short brief (`c77d7bf`). The newer field-presence defaults and deliberate simplifications take precedence over the old proposal. This review proposes a few clarifications; it does not restore the original admission matrix or add acceptance gates.

## Resolve before the affected slice

| Topic | What needs an explicit decision |
| --- | --- |
| Configuration shape | The [compiler experiment](../projection-shape-lab/README.md) supports a typed, shallow `Projection(@This())`. Anonymous children and imported types own their own configuration. This replaces the brief's untyped illustrative literal without requiring a recursive configuration tree. |
| Naming | Replace arbitrary per-field names with a deterministic convention if accepted. Specify word/acronym handling and collisions; language keyword escaping is separate from the shared wire key. Lower camel case is a recommendation, not yet an accepted spelling rule. Type-name collisions also need deterministic handling before public declarations. |
| Stacked optional/null mappings | Direct `??T` at value positions collapses different native states into the same null. A plain pointer to an optional also conflicts with an unconditional promise that plain fields are non-null. Initially diagnose these cases unless a distinct representation is deliberately selected; do not accidentally introduce absent/null/value support. |
| Struct fields and defaults | Namespace declarations are not data fields. Native default values must not change required/omittable semantics; the experiment demonstrates this. Specify comptime-field handling before admitting those records. Packed/extern/tuple handling should be a conscious Zig decision, not a restriction copied from the old proposal. |
| Union payload shapes | The brief defines flattened object payloads and tag-only cases. Explicitly diagnose scalar/optional payloads until their representation is designed; the brief does not define a payload property for them. |
| Fixed-array declarations | Preserve N in the mapping and enforce it in native decoding/schema. Decide whether foreign declarations initially use ordinary arrays with runtime length checks or express N statically; the old document chose ordinary arrays. Neither choice follows automatically from preserving N. |
| Runtime identity | Distinguish recursive types from cyclic values. Initial codecs can reject cycles and copy repeated references; preserving object identity is a separate capability. The type-configuration experiment proves only terminating type discovery. |

The first scalar/record declaration checkpoint does not need every codec answer. Resolve each short rule before implementing the slice that depends on it.

## Keep deferred or removed

Keep the user's native optional defaults, per-field required override, ordinary float conversions, default UTF-8 slices, recursive composition, anonymous records, and optional metadata. Do not restore Presence wrappers, exact-f32 round-trip requirements, signed-zero normalization, mandatory empty config, per-byte annotations, Go-specific field-position rules or compulsory owned-result APIs.

Keep the selected unsigned-schema lower bound and fixed-array constraints. The OpenAI capability reference already records profile limits and the omission/null mismatch; it does not need another specification here.

Sparse arrays, special JavaScript runtime values and duplicate wire keys need explicit treatment when the codec input surface is chosen. Diagnostics should identify the bad field/value, but frozen categories, message text and a full malformed-wire corpus are not first-delivery gates. Cache fingerprints, publication repair, packaging and larger parity suites remain later work.

These findings support a handful of short decisions, not a return to the exhaustive contract. No implementation of the mapper or change to the main brief is made by this review.
