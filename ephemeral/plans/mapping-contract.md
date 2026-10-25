# Zig → JavaScript mapping proposal

Status: **proposed, unimplemented**, 2026-10-25. This is the primary next task for Type Projector. It defines one closed application-value contract for TypeScript declarations, JavaScript with JSDoc type hints, and typed transport. It is deliberately smaller than a general-purpose serializer. Accepting this proposal would select semantics, not freeze the public API, IR layout, or codec implementation mechanism.

Read the [feature/test parity map](feature-parity.md), [single-example acceptance slice](example-acceptance.md), and [source/provenance ledger](mapping-evidence.md) with this document. All acceptance cases below are proposed; none has run in Type Projector.

## Recommendation

Begin with booleans, explicit integer types, finite floating-point values, explicitly classified UTF-8 text, and ordinary structs. Add only closed enums, dense arrays/slices, the three field policies, object pointers, discriminated object unions, and productive named recursion. Both declaration outputs support the same admitted values. Never replace an unsupported shape with `any`, `unknown`, a guessed string conversion, or an unchecked codec hook.

The JavaScript value is the contract. Zig storage choices do not change it: `Payload` and `*const Payload` may represent the same object; `?T` is a native Zig optional whose metadata chooses a required key with null or an omittable key; a union's integer tag representation does not choose its wire string. Devalue can represent substantially more than this subset. A protocol capability is not automatic admission to a typed API.

The first implementation should prove primitives/basic structs in the public `./example`, then extend that same example through the bounded exchange in [the acceptance plan](example-acceptance.md). JSDoc is part of that acceptance, not an eventual add-on. Swift and other projections remain future consumers of the contract, with their own capability and compiler proof.

## Authority and evidence boundary

Already agreed direction: independent evolution from Go Polytype; one example project; required keys, native optional values and field omission, with omission combined with null rejected; explicit descriptions because reflection exposes no doc strings; inline or pointer-backed union payloads; native schemas/codecs as library capabilities; generic devalue runtime in the shared Go/Zig repository. The latest user choice is per-field configuration inside the type: plain T is required/non-null; ?T defaults to omission; marking ?T required requires the key and admits null. Earlier milestone order and final metadata spelling remain proposals.

Use Zig’s normal **optional** terminology for `?T`; there is no separate Nullable wrapper, type or abstraction. Field omission is a wire policy on an ordinary native optional. The chosen default/override semantics need neither a Presence wrapper nor a Nullable wrapper: ?T is omittable by default, and a per-field required override requires the key while preserving null as a valid payload.

This preserves Zig's enforced distinction between an optional value and its payload: ordinary conditional capture or `orelse` handling yields `T` before payload use. A forced `.?` unwrap is a programmer assertion, equivalent to `orelse unreachable`; it is not a compile-time proof that a runtime value cannot be null. The language checks the optional/payload type distinction, not every programmer assertion. [Z2](mapping-evidence.md).

All choices called “proposed” here remain recommendations for review. In particular the exact numeric domain, byte classification, collision policy, and other unchosen restrictions below are not inherited decisions; the user has chosen the type-owned carrier direction and required-field default/override semantics. [Evidence Z1–Z8 and P1–P12](mapping-evidence.md) identify inspected originals. Zig target: 0.17.0 source `7647adab80dd088f4de3610fd245915a912eb6ad`. Peer Go comparison: `c9ae9678816768776569e1157bd3c4372e1be5c6`; it is newer than the cache's Polytype snapshot.

## Closed admission rules

The following is a semantic grammar, not an IR or proposed Zig API:

```text
Value       = Bool | Integer | Float | Text | Enum | Record | List | FixedArray
            | ObjectPointer | NamedReference(to Value)
RecordField = Value | ?Value [default: omittable]
            | ?NullOperand [configured required]
            | Union | ?Union [default: omittable] | UnionList
NullOperand = Bool | Integer | Float | Text | Enum | Record
            | ObjectPointer | NamedReference(to one of these)
Union       = tagged union of Record or ObjectPointer payloads
UnionList   = one direct slice of Union
```

The bracketed policies above are metadata on a native `?T` field, not type constructors. Plain `?T` defaults to an omittable key; an illustrative per-field `.required = true` override requires key presence and emits null for native null. This does not force unwrap or change ?T into T. Both retain Zig's ordinary null/value representation.

A native optional has exactly null/value states. Mapping native null to wire null or to a missing property is lossless within the selected two-state wire domain. Mapping absent, explicit null and value as three distinct wire states into the same `?T` is not lossless and is outside this proposal. The user has not requested that three-state capability. Metadata selects behavior; no wrapper is required merely to choose it.

Recursively, lists/arrays contain `Value`, not native optional elements or unions. Inline anonymous records are a direct-field exception only, not arbitrary Value operands. A record inside a collection may itself contain union fields. Only selected roots and their reachable dependencies are inspected; validate every selected root, including anonymous scalar/collection roots, and every reachable shape before any backend publishes output. Do not silently walk all application declarations.

| Native input | Admitted meaning and limits | JS value / shared foreign type |
| --- | --- | --- |
| `bool` | Exact, no coercion from numbers/strings | boolean / `boolean` |
| Explicit signed/unsigned integers, widths 1–64 | Native bounds intersected with JS safe-integer bounds; see numeric policy | number / `number` |
| `f32`, `f64` | Finite only; narrower decode must be exact; signed zero normalized | number / `number` |
| `[]const u8`, `[]u8` classified **text** by metadata | Validate UTF-8; preserve Unicode content, no normalization | string / `string` |
| Exhaustive native enum | Tag-name strings by default; explicit labels or numeric mode allowed under enum rules | literal union |
| Named `.auto`, non-tuple struct | Closed ordered record of admitted fields; defaults do not imply optionality | plain object / structural object |
| Inline anonymous `.auto` record | Allowed only as a direct record field; supply metadata at that field path | structural object |
| `[]T`, `[]const T` | Dense ordered non-null list; byte operands need explicit classification | array / `Array<T>` |
| `[N]T`, including `N = 0` | Exact native/wire length; byte arrays are numeric arrays unless explicitly given a future distinct mapping | array / `Array<T>` |
| `*T`, `*const T` where T is a named admitted record | Non-null indirection to the same object value; ownership below | payload type, no added `null` |
| `?T` direct field, configured required | Native null emits null; missing key rejects; restricted NullOperand | `T \| null`, required property |
| `?T` direct field, default omittable | Native null omits key; absent key decodes to null; explicit wire null rejects | optional property `key?: T` |
| `union(enum)` / union with exhaustive enum tag | Direct field, omittable native optional, or direct one-dimensional union slice; named record or object-pointer payloads only | discriminated object union |
| Named recursive record references | Finite, productive type graph; finite acyclic values | named references |

Every slice whose element type is u8 (including aliases) must explicitly choose `text` or `numeric_list`; neither constness nor a type alias selects semantics. `numeric_list` means dense numbers in 0…255, not base64 or `Uint8Array`. Text mode accepts only `u8` elements. This deliberately differs from Go's blanket byte-slice refusal and avoids confusing Zig strings with binary transport. String literals assigned to text fields use ordinary Zig coercion; arbitrary sentinel/many-item pointer roots are not inferred to be strings. Enum slices retain their registered enum mapping even when their tag type is u8; an enum is not implicitly a byte. No binary mode is admitted yet.

Zig terminology: `[N]T` is a fixed-length array; `[_]T` infers that still-compile-time-fixed length from an initializer. A `[]T`/`[]const T` slice is a pointer plus runtime length, not a growable container. ArrayList provides growable storage and exposes its elements through an items slice. Use slices for ordinary variable-length API collections, keeping backing-storage ownership explicit; do not admit ArrayList's capacity/implementation fields through reflection. [Pinned collection sources, Z9](mapping-evidence.md). Preserve a fixed array's exact N in the semantic mapping even when a printer cannot express it; every supported native fixed-array decoder must reject a different length, independently of deferred schema work.

Named pointer/collection roots are allowed where this grammar permits them; bare union roots and native optional roots are refused initially. Anonymous records under pointers/collections or at roots are refused for the initial contract, matching the peer typed-codec restriction rather than designing unstable external identities. A later extension needs a named acceptance case, not a permissive fallback. Zig aliases share type identity; alias names do not create independent wire contracts. A type-owned configuration supplies one shared mapping across its uses; no printer-local override is allowed. A future third-party/multiple-mapping facility would need explicit identity and conflict rules.

## Numeric policy: values, not just declarations

**Chosen mandatory schema rule:** every unsigned native Zig integer projects with `type: "integer"` and explicit `minimum: 0`. A profile unable to express that constraint must report/refuse the capability; it cannot silently drop unsignedness. Schema acceptance must check the emitted keywords and reject a negative value. This settles only the unsigned lower bound; precision and upper-bound proposals below retain their existing status.

**Proposed: no silent integer rounding.** Each integer value must be within both its native range and `[-9007199254740991, 9007199254740991]`. Check in native integer arithmetic before conversion when encoding; on decode check finite, integral, safe, then native range before casting. Reject even exactly representable integers outside that safe interval, including `9007199254740992`, to keep a uniform domain whose neighbors are representable.

Admitting `u64` or `i64` means admitting that checked value domain, not all bit patterns. For example, `u64(42)` is valid; `u64(9007199254740992)` is an encode error. A JS `256` cannot decode as `u8`; `1.5` cannot decode as any integer. A JS BigInt is the wrong kind even if it fits. There is no automatic number↔BigInt or number↔decimal-string conversion. Wide integers, BigInt, decimal/fixed-point money, and JSON string-number conventions require future explicit mappings.

`usize`/`isize` have no special source-spelling rule: reflection reports integer width/sign and may not distinguish them from explicit-width types. Require each root to declare its application target policy, and record each integer field's expected signedness/width in the admitted mapping. Both the generator and target application must check those expectations against their native reflection. A host/target width mismatch rejects admission; it must not silently select host wire semantics. Prefer fixed-width DTO fields for portable APIs. The exact metadata carrier is open; acceptance must include an actual 32/64-bit mismatch case before claiming target-sized-integer support. The fixed-width first example avoids this unresolved implementation proof.

For `f64`, admit finite binary64 numbers. For `f32`, encoding widens exactly; decoding accepts only finite numbers exactly representable as `f32` (checked conversion and equality), otherwise asks the author to use `f64` or perform application-owned rounding. Thus JS `0.1` is valid `f64`, but is not an exact `f32`; the JS value of a native `f32` initialized from `0.1` is `0.10000000149011612`. Reject NaN and infinities for both formats. Normalize `-0` to `+0` on both encode and decode; signed-zero preservation is outside this shared JSON/devalue profile. Values already rounded by a JS producer cannot reveal their original source literal; the decoder validates the received number, not an unknowable intention.

This is stricter than peer Go typed devalue, which converts all numeric kinds to float64 and explicitly tests lossy numeric enums. Peer TS rejects inexact enum literals but allows an exact literal `9007199254740992`. Proposed Zig numeric enum mode requires every member in the safe domain at admission, so declarations and codecs cannot disagree. [P2, P4, P6](mapping-evidence.md) support this distinction. TypeScript/JSDoc `number` cannot express native ranges, integrality, finiteness or f32 exactness; runtime tests remain necessary.

## Structs, native optionals, omission, names, and descriptions

| Field policy | Native representation | Encoding native null | Decoding missing / null / undefined | Foreign property |
| --- | --- | --- | --- | --- |
| Required non-null | ordinary admitted T | impossible for valid T | reject / reject / reject | `key: T` |
| Configured required optional | ordinary Zig optional `?T`, `.required = true` | emit own key with null | reject / native null / reject | `key: T \| null` |
| Default optional | ordinary Zig optional `?T` | omit the key | native null / reject / reject | `key?: T` |

A JS object with no key and an object with an own key whose value is `undefined` are distinct. Reading an omitted optional property in JS/TS yields undefined; that does **not** mean the encoder emitted an undefined property. **Proposed initial profile: never encode explicit undefined and reject it on decode, in both field policies.** Ordinary JSON has no undefined value. An eventual devalue-only explicit-undefined profile would need its own exact mapping and proof; it is not silently enabled by devalue's sentinel support.

Reject combined omit-and-null wire acceptance, nested `??T`, native optional collection elements and optional scalar pointers. For a configured required optional, arrays/slices/unions remain refused in this restricted contract; a default omittable optional may carry lists/arrays and direct object unions as non-null present values, just as the prior Go omission wrapper allowed them. Native optional object pointers `?*T` / `?*const T` may use either required-key setting: the optional carries null, while a non-null pointer is ordinary object indirection. Text is a scalar despite its byte-slice storage. Field initializer defaults do not override these rules; false, zero, empty text and empty lists stay present. This supersedes the earlier proposal requiring an absent/present wrapper and forbidding metadata-selected omission.

Later schema derives from the same categories: plain T appears in required with no null alternative; default ?T is excluded from required and its present value excludes null; configured required ?T appears in required and allows null. No separate nullable boolean is needed. Configuration cannot invent a third native state, use a zero/empty sentinel to omit a plain T, or turn required=true into a forced unwrap.

All runtime fields participate; comptime fields, tuple structs, `.extern`/`.packed` containers and native-only fields require a refusal in this initial contract. Use a separate application DTO rather than silently omit state. Declarations in the type namespace are not instance fields. Duplicate effective wire keys reject admission, with both native paths in the diagnostic. Preserve declared field order as metadata; JS enumeration of integer-like keys follows JS rules, so object order is not semantic equality.

**Preferred metadata location:** a public comptime-known namespace constant inside the native struct. Field declarations remain ordinary native data; the constant selects per-field projection/transport behavior. A plain T is required/non-null by default; a ?T is omittable unless configured required. This is an illustrative spelling, not a finalized API or compiled fixture:

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
                .bytes = .utf8_text,
                .description = "Name shown to the recipient.",
            },
            .nickname = .{ .bytes = .utf8_text },
            .owner = .{ .bytes = .utf8_text, .required = true },
        },
    };
};
```

Here nickname uses the ordinary ?T default: native `nickname = null` omits nickname. Owner is configured required: native `owner = null` emits owner:null. Non-null values of both fields emit text. The same rule feeds codec, TS, JSDoc and later schema; JSON Schema's representation follows this decision rather than defining native types.

Read the known public declaration through comptime type/namespace reflection and validate every key against reflected fields/tags. It carries wire names, descriptions (type/field/member/variant), byte interpretation, enum mode/labels, union discriminator/tags, the per-field required override and target integer policy. Default wire name/tag label is the native field/tag name. Plain T is required/non-null; ?T is omittable by default; `.required = true` on ?T requires key presence while still allowing null. Wire labels are UTF-8 strings, including empty/punctuated keys and empty variant tags; discriminator key must be nonempty. No automatic casing/inflection. Unknown keys, duplicate entries, conflicting options, `.required = false` or another omission request on non-optional T, invalid UTF-8, or incompatible options reject. Each named record must opt in with the recognized public constant (an empty .{} is sufficient if no per-field options are needed); a selected record lacking it must diagnose rather than fall back after a misspelled declaration. Explicit aliases/name allocation expose the native-to-foreign name map; native compiler names are not a promised persistent identity.

Recommend partial descriptions with checked keys. Reflection provides public declarations separately from instance fields, but no doc strings or automatic field spans. A namespace const adds no per-instance struct field/storage. It need not retain every description byte in every binary; equally, there is no universal disappearance guarantee: specialized runtime behavior, runtime-accessible schemas/docs and referenced constants may retain data they need. [Z1–Z3, Z8](mapping-evidence.md) support these distinctions. Source-comment extraction remains a separate possible feature, not the preferred path. An external override for third-party types is an open extension only if needed; it is no longer the primary authoring interface. Caller-supplied locations may enrich diagnostics; native/wire paths must work without them.

## Enums and tagged unions

Use native exhaustive enums, not marker methods. Default labels are tag names; explicit label overrides must be unique. Numeric mode uses reflected backing values, native bounds, and the safe-integer policy; it does not call arbitrary formatting methods. No nonexhaustive enum, duplicate label, mixed numeric/string mode, or unknown runtime member is admitted. Zig does not need Go's alias-value canonicalization or direct-owner restriction for integer-name enums: a configured enum has one mapping across its uses. Per-field alternate enum contracts are deferred with the external-override question; printers cannot change the configured mapping. Enum descriptions follow the semantic model into both printers.

Use native tagged unions with object payloads. Tag names select labels unless explicitly overridden; default discriminator key is `"type"`. Every wire variant is a plain object containing that required literal key plus the payload's wire fields. Both `created: Created` and `created: *const Created` with the same tags/metadata project to `{ type: "created", ...CreatedFields }`. No address, pointer wrapper or integer tag is serialized. Permit mixed inline and pointer payload choices within a union. Only the active payload is traversed.

**Proposed simplification:** reserve the discriminator property; refuse any payload wire field with that name. Peer grammar and typed codecs allow certain collisions and replacement, while the peer schema backend already rejects collisions. A single rule avoids field loss and backend disagreement. Authors can rename the payload key or change the discriminator. Preserve shared payload definitions unchanged. Reject scalar/void/optional payloads, bare/untagged unions, nonexhaustive tag sets, duplicate effective tags and unresolved payloads. A tag-only case uses a named empty record, not an implicit null or void conversion. A one-variant union remains a discriminated union.

An ordinary inline union reserves its largest inline payload with tag/alignment effects. The tag is not a fixed eight bytes; exact layout depends on tag type/target/compiler. [Z2](mapping-evidence.md) shows actual pinned layout computation. Pointer payloads reduce inline storage while adding indirection and lifetime obligations. Type Projector imposes no heap-only payload rule or universal native layout.

## References, ownership, and typed transport

Allow named recursive records through pointers/lists and admitted field policies when the graph is productive and has finite inhabitants. Reject unresolved references and nonproductive alias loops before printing. Detect recursion by identity and active traversal, not an arbitrary number of repeated type expansions. Runtime cycles are a different issue: the initial typed value domain is acyclic. Reject an ancestor back-edge with its value path on encode/decode; repeated shared subobjects on different non-active paths may be copied and do not promise identity preservation. Devalue runtime cycle/identity support does not expand this contract.

Encoding borrows native values for the call. All pointers/slices/text must be valid and remain stable while read; the library cannot validate arbitrary dangling native pointers. No native allocation is required just because an application uses an inline union; caller-owned stack, arena or heap payloads are all possible when lifetimes are valid. Creating a transport graph or output bytes can separately require allocation.

Recommend one owned typed decode result whose explicit owner releases all allocated text, slices and pointer payloads together. Decoded values must survive destruction of input bytes and the temporary devalue graph. Pointer variants allocate pointees using the caller's allocator; inline variants require no separate pointee allocation. Allocation failures and nested validation failures must clean up partial results. Const pointers constrain mutation, not allocation/ownership. A borrowed decode mode, user allocator callbacks for each field, graph identity preservation and decoding into an existing object are deferred. Exact return type and cleanup method remain API design work. [Z4, W2](mapping-evidence.md) give the allocation and runtime-owner constraints.

Decode accepts only own data properties of ordinary records and dense arrays in the admitted model; no coercion from class instances, accessors, Map/Set/Date, typed arrays, null-prototype objects or custom revived classes. Missing/extra properties, wrong kind, invalid enum/tag, bad nested value, sparse holes, undefined, and wrong fixed length reject with a path. Enforce duplicate-key detection at the format parser before hydration can erase duplicates; if a selected runtime cannot expose duplicates, qualify/fix that boundary before claiming strict wire decode. JSON and devalue parse/framing errors remain format-specific.

JSON serializes this subset as ordinary JSON. Devalue uses its own reference-slot/sentinel format. Target exact upstream **5.9.4** for initial reproducible exchange; major 5 is the selected compatibility line. Reject the runtime's extra special values even when parse succeeds. Generic parse/stringify, graph ownership and protocol evolution stay in `tylergannon/devalue`; mapping native T to that runtime's values stays here. Keep both Go and Zig there. A later Zig-only release archive from that repository is accepted packaging direction; no archive or dependency is published by this proposal. `.paths` filters package contents after fetching and cannot shrink the initial whole-repository archive download. [W1–W3, Z6](mapping-evidence.md).

## Two first-class declaration outputs

Both printers consume the same admitted mapping and name allocation. Selecting `.ts` or JSDoc cannot admit a new native type, change labels/presence/numbers, or silently erase unsupported semantics. They emit declarations only, with no runtime validator or value exports. Both need positive and negative real consumer type-checks.

| Concern | TypeScript | JavaScript with JSDoc |
| --- | --- | --- |
| Named types | exported type aliases in `types.ts` | typedefs in type-only ESM `types.js`; empty runtime export |
| Consumption | `import type { Envelope } ...` | `import('./types.js').Envelope` in annotations under `allowJs`/`checkJs` |
| Omission / native optional | `"nickname"?: string`, `"owner": string \| null` | same semantics using optional properties / union-with-null |
| Unions / references | literal tag unions, named recursive references | same contract using supported JSDoc expressions; check precedence in compiler |
| Properties / descriptions | quoted keys; escaped type/field docs | `@property` for safe names; quoted inline object form when namepaths cannot represent a key |
| Description fallback | comments remain attached to fields | retain unattachable member descriptions in type-level prose; IDE field placement may differ |
| Barrel | optional type-only barrel | no runtime re-export of typedefs; document type imports |
| Bounds / closed objects | structural types approximate the runtime contract | same approximation; no weaker typed transport |

Keep punctuation/Unicode/empty keys supported through quoting; sanitize descriptions containing `*/`, controls, CRLF and line separators in both printers. TypeScript object types do not enforce a closed wire record for all assignments; fresh-literal excess-property checks are limited. `Array<T>` does not express fixed length here. Even an empty-record projection such as `object` over-accepts arrays/functions; runtime validation supplies that boundary. Use strict checking and `exactOptionalPropertyTypes` in acceptance; prove both absence and explicit-undefined behavior with each actual checker rather than assuming the option has equal JSDoc coverage. [P4–P5](mapping-evidence.md).

## Refusal and diagnostic contract

Reject `comptime_int`/`comptime_float` roots, widths beyond 64 bits, `f16`/`f80`/`f128`, `type`, bare `null`/`undefined`, `void`/`noreturn`, error sets/unions, functions, opaque/frame/vector types, arbitrary pointer forms (`[*]`, C, sentinel, allowzero, volatile, non-default address space), pointer-to-scalar/collection/pointer, unclassified bytes, maps/sets and implementation containers, custom serializers, provided external schema holes, and every composition not explicitly enumerated above. Types such as ArrayList/HashMap must not accidentally become records by reflection: require the explicit type-owned configuration opt-in for every named record in the reachable model, including dependencies; do not implicitly register a container merely because it is structurally a struct; applications supply API DTOs using slices/records. Unknown future reflection kinds fail closed.

| Refused category | Reason and author remedy |
| --- | --- |
| Wider/other numeric kinds and untyped comptime literals | No selected lossless/shared JS representation; choose an admitted concrete type or application DTO conversion |
| Error/function/type/opaque/frame/vector values and bare null/undefined/void | No defined application-value meaning or callable/type/lane transport; expose admitted data instead |
| Untagged/open unions and scalar/void payloads | No closed object/tag contract; use an exhaustive tagged union of named records, including an empty record for tag-only cases |
| Arbitrary pointer forms and ABI/tuple/comptime records | Length, validity, ownership or structural field meaning is not supplied by this contract; convert to named ordinary records/slices |
| Unclassified bytes, maps/sets and implementation containers | Text/binary or entry/property semantics would be guessed, and native allocator/capacity fields are not API data; classify bytes or supply a record/list DTO |
| Unlisted field-state/union compositions | Preserve a small explicit state space; reshape the API or propose a bounded extension with literal/negative acceptance |
| Custom serializers and schema-only supplied shapes | Static foreign declarations and typed transport cannot infer their wire behavior; supply an admitted DTO, or later design a separate schema-only capability |

Admission errors are deterministic in root selection order, then native field/tag declaration order. A proposed stable diagnostic category plus path identifies the owner, native field, effective wire key if different, offending kind/policy, and a concrete remedy. Runtime errors use escaped JSON Pointer paths (`~`→`~0`, `/`→`~1`) and include the expected constraint; errors at root use the empty pointer. Do not promise unavailable field source coordinates.

Examples (wording illustrative; category and meaning are acceptance targets):

```text
unclassified_bytes: Envelope.display_name [wire "display-name"]: []const u8 needs text or numeric_list metadata
omission_and_null: Envelope.nickname: one ?T field cannot preserve absent, null and value distinctly; choose default omission or configure the key required
integer_precision: /count: 9007199254740992 exceeds the JavaScript safe-integer domain
enum_precision: Status.huge: numeric label 9007199254740993 is outside the shared number domain
discriminator_collision: Envelope.event.created.type: wire key "type" is reserved; rename it or change the discriminator
unsupported_kind: Envelope.callback: function values have no admitted wire representation; use a separate DTO
unsupported_composition: Envelope.labels: required ?[]const Status is outside the null operand subset; use default omission or a non-optional required list
```

Descriptions and both declaration outputs must fail together for invalid shared metadata. Validate/render all requested artifacts before publication. Later filesystem failure may still leave earlier completed writes; report it as failure plus actual mutations, not generation success. Preserve equal output bytes/mtimes, repair missing or damaged generated output, and protect application-owned files. Semantic fingerprints may later skip projection, not necessarily reflection/lowering; include dependencies, descriptions, target policy, mapping version and backend/options. No custom native compilation cache is proposed.

## Planned schema capability and post-release general dialect

The planned OpenAI-compatible profile includes the currently documented standard-model minItems/maxItems bounds; preserve native fixed-array exact length and encode it as equal lower/upper bounds when that profile is supported. Future schema acceptance must validate N and refuse wrong lengths; an incompatible fine-tuned profile must fail/report the constraint rather than drop it. This does not implement a backend or make schema proof a gate for the first primitive/record checkpoint. Native fixed-array decoders independently must enforce exact length whenever supported.

A second explicit target for a selected modern general JSON Schema dialect remains **post-initial-release** work; select its dialect then. Preserve richer semantic information for that target without adding a broad constraint framework or general serializer now. The user's historical context is that Go Polytype was intentionally constrained for OpenAI; historical restrictions are not universal current API facts.

The [current OpenAI compatibility reference](../../docs/openai-json-schema.md), checked 2026-10-25, separates strict schema support, non-strict guarantees, model caveats and evidence limits. The future OpenAI profile must validate capabilities and fail/report any loss; it must not silently replace Type Projector's agreed missing-key semantics with null. Resolve that compatibility decision when designing the profile, not in this reference. Neither target is implemented by this documentation. [Evidence O1](mapping-evidence.md).

## Chosen direction, remaining review, and delivery order

| Chosen direction or remaining recommendation | Why / cost |
| --- | --- |
| Safe integers; exact f32 decode; finite floats; normalize signed zero | One reproducible JS value domain; stricter than Go and may require application rounding or different DTO types |
| Explicit text/numeric-list bytes | No guessing binary/text; more metadata at byte fields |
| Chosen: native ?T defaults omittable; per-field required override emits null | Key presence is separate from native payload; no forced unwrap, wrapper or third state |
| Proposed: retain narrow union/composition restrictions and refuse explicit undefined | Small explicit domain; no three distinct absent/null/value states on one field |
| Type-owned public comptime constant, partial docs, checked keys | Native declarations stay idiomatic; no per-instance metadata fields; spelling still open |
| Reserved discriminator and owned decode results | Prevent field replacement and hidden lifetimes; allocation tests needed for pointer variants |
| TS and JSDoc together in the first acceptance | Both are supported products of one semantic contract; printer details remain separate |

None requires further input to finish this proposal. Review should focus on these semantic tradeoffs before implementation. First implement the primitive/record projection checkpoint, then the bounded typed exchange in the same `./example`; later add recursion and the broader parity cases there. Native JSON Schema/validation, strict JSON codecs, public custom-backend access and publication behavior remain roadmap obligations, not first-exchange claims. Schema-only provider compatibility and a Swift mapping need separate capability decisions. Keep the [generic-vs-emitted JSON codec experiment](codec-experiments.md) deferred until the contract and literal cases can hold both mechanisms to the same semantics.
