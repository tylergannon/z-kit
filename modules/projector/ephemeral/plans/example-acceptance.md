# One public example: proposed acceptance

Status: optional component fixture and later test catalog. The [application feature specification](../../../../ephemeral/plans/first-application-spec.md) governs construction order and proof: start with the real application through the Vite socket/Zig proxy, then select useful features progressively. The component checkpoints below can supply examples when those features need them. They are not required preliminary work or acceptance projects. One public repository-root `./example` serves z-kit adopter documentation and demonstration.

## Checkpoint A: primitives and a basic struct

Possible primitive/record fixture: native `bool`, `u32`, `f64`, text and one named ordinary record. A small public-interface generator projects the record to frontend declarations. Focused type/codec tests can check valid values, missing required fields, wrong kinds, null, numeric bounds and text handling for the selected mapping. Choose cases needed by the application feature; the full catalog and both declaration modes are not initial gates. The earlier ownership/stale cleanup, check-only and recovery witness requirements are deferred.

Then extend the same model/project to checkpoint B; do not create another consumer module or repeat package/bootstrap setup.

## Checkpoint B: a small typed devalue exchange

Native shape sketch, **not a proposed public metadata API or compiled probe**:

```zig
const Status = enum {
    queued, ready,
    pub const projection = .{
        .members = .{ .ready = .{ .description = "Ready to deliver." } },
    };
};
const Created = struct {
    id: u32,
};
const Deleted = struct {
    reason: []const u8,
};
const Event = union(enum) {
    created: Created, deleted: Deleted,
    pub const projection = .{ .discriminator = "kind" };
};
const PointerEvent = union(enum) {
    created: *const Created,
    deleted: *const Deleted,
    pub const projection = .{ .discriminator = "kind" };
};
const Envelope = struct {
    display_name: []const u8,
    count: u32,
    active: bool,
    status: Status,
    nickname: ?[]const u8,
    owner: ?[]const u8,
    labels: []const Status,
    samples: []const i16,
    event: Event,

    pub const projection: projector.Projection(@This()) = .{
        .description = "A queued delivery.",
        .fields = .{
            .display_name = .{
                .description = "Name shown to the recipient.",
            },
            .owner = .{ .required = true },
        },
    };
};
```

An otherwise equivalent `PointerEnvelope` changes only the native event field to `PointerEvent` and supplies the same type-owned configuration. Both models are selected through the eventual public interface. Native fields remain idiomatic Zig data; the inline namespace constant configures wire/projection behavior without adding per-instance fields. **The struct configuration shape is compiler-verified; enum/union options and this complete exchange remain illustrative and uncompiled.** Unknown configuration field/option keys reject; configuration is optional when defaults suffice. Byte slices default to UTF-8 text. Fields and default enum/tag labels follow the brief's deterministic naming; labels are strings, not bytes or numeric backing tags.

Samples uses an ordinary variable-length slice so this first exchange does not require fixed-array or schema-dialect proof. The contract retains fixed arrays; when supported, a separate focused `[2]i16` case must accept exactly two elements and reject other lengths. Deferring schema constraints does not relax native decoding. Array bounds remain a planned supported schema capability; the [modern general dialect](mapping-contract.md#schema-and-later-work) is post-initial-release work. Neither backend is implemented here.

Future schema acceptance for unsigned count/id must assert `type: "integer"` and explicit `minimum: 0`, and reject a negative value; any profile unable to carry that mandatory bound must report/refuse it. This adds no numeric-design work or backend to checkpoint B.

Both nickname and owner are native `?[]const u8`. Nickname uses the native optional default (omittable); owner has `.required = true`, meaning required key presence, not forced non-null payload. The same native two-state type therefore has different configured wire domains. Null nickname omits its key; null owner emits an own key containing null. An own property containing undefined is a different JS value and is rejected for both fields. Accessing the omitted nickname may return undefined in JS/TS; that is not an explicit-undefined encoding. No Presence or Nullable wrapper is needed, and the example does not request three-state absent/null/value preservation.

Native producer value:

```text
display_name = "Ada"
count = 7
active = true
status = .ready
nickname = null  // default optional: omit key
owner = null
labels = [.ready, .queued]
samples = [1, -2]
event = .created { id = 42 }
```

The pointer-backed producer uses `.created` pointing at an initialized Created with id 42. That pointee may be local stack storage while encoding is synchronous. Both producers must yield exactly this **JavaScript value**, irrespective of their native layout:

```js
{
  "displayName": "Ada",
  count: 7,
  active: true,
  status: "ready",
  owner: null,
  labels: ["ready", "queued"],
  samples: [1, -2],
  event: { kind: "created", id: 42 }
}
```

In particular, `Object.hasOwn(value, 'nickname')` is false, `Object.hasOwn(value, 'owner')` is true, `value.owner === null`, `typeof value.count === 'number'`, `typeof value.status === 'string'`, and `Array.isArray(value.labels)` is true. The event has no pointer/address wrapper and no integer tag. Assert own keys at both object levels; an independently written JS expected object must not be reconstructed from generated declarations or a Zig serializer's output.

Expected TypeScript shape (formatting/name-allocation details illustrative):

```ts
export type Status = "queued" | "ready";
export type Created = { "id": number };
export type Deleted = { "reason": string };
export type Event =
  | (Created & { "kind": "created" })
  | (Deleted & { "kind": "deleted" });
/** A queued delivery. */
export type Envelope = {
  /** Name shown to the recipient. */
  "displayName": string;
  "count": number;
  "active": boolean;
  "status": Status;
  "nickname"?: string;
  "owner": string | null;
  "labels": Array<Status>;
  "samples": Array<number>;
  "event": Event;
};
```

Expected JSDoc semantics, using an inline quoted-key form to illustrate the common expression contract (the eventual printer can use supported `@property` forms):

```js
/** @typedef {"queued" | "ready"} Status */
/** @typedef {{ id: number }} Created */
/** @typedef {{ reason: string }} Deleted */
/** @typedef {(Created & { kind: "created" }) | (Deleted & { kind: "deleted" })} Event */
/**
 * A queued delivery.
 * displayName: Name shown to the recipient.
 * @typedef {{ "displayName": string, count: number, active: boolean,
 * status: Status, nickname?: string, owner: string | null,
 * labels: Array<Status>, samples: Array<number>, event: Event }} Envelope
 */
export {};
```

PointerEnvelope may have a separate emitted alias, but must have the same structural meaning in both outputs. Compare semantics, not coincidental declaration names or all serialized byte ordering. Separately unit-test exact devalue bytes against the pinned runtime only where protocol parity is the claim.

## Exchange and consumer proof

Pin Zig 0.17.0, a concrete shared devalue-runtime source revision/content hash, canonical JS `devalue` exactly 5.9.4, Node, and an exact TS checker with its lockfile when implementing. The cached runtime's commit is prior art, not a published dependency selected by this proposal. Record actual tool versions, command results and skips. Do not use `latest`, a directory named v6, or moving Svelte/Kit main manifests as a reproducible protocol pin. Svelte/Kit major-5 selection is existing discussion context; the cached exact sources substantiate 5.9.4's behavior.

The example should expose a readable generate step and an acceptance step. Its own realistic `build.zig`/manifest use the library's public package module, initially through a local path dependency to the repository root. No private source imports, copied internal helpers, second integration project, web server, or SKGo dependency. A host-built generator shares the model module and runs through an explicit tracked build Run step, producing TS and JSDoc into distinct output directories. Test executables need actual run edges, not only compilation. Preserve application-target semantics; this fixture uses fixed-width numbers. The native codec mechanism remains undecided.

1. Zig encodes both native representations through the typed adapter and shared runtime; canonical JS 5.9.4 parses each document. JS asserts the literal expected value and own-key/type facts above.
2. JS independently constructs a second value: same required basics, `nickname: "Countess"`, `owner: "Grace"`, `labels: []`, `samples: [32767, -32768]`, `event: { kind: "deleted", reason: "duplicate" }`. JS stringifies it with 5.9.4; Zig decodes separately into Envelope and PointerEnvelope and asserts every native field, active union tag and payload. Do not generate this producer from the Zig output.
3. Both typed decoders also consume the first JS expected object, checking absence/null. Exercise the chosen API's documented lifetimes: owned results must survive input destruction; borrowed results must keep their owner alive. Check cleanup on success and partial failure where allocation occurs.
4. Compile real positive TS and checked-JS ESM consumers separately using strict checking, `exactOptionalPropertyTypes`, and JS `allowJs`/`checkJs`. Prove omitted nickname, required owner null, both event tags and discriminator narrowing. Compile each negative consumer and check that failures identify the intended type error; exact wording is not a contract. Import runtime JS module to confirm typedefs are not runtime values. Use the compiler checks as the consumer proof.

The planned commands/step names are interface goals, not commands that currently exist. Their implementation should make the ordinary adopter path the acceptance path. Record absent tools as **not qualified**, rather than skipping a required output and reporting acceptance passed.

## Candidate tests as features land

| Candidate case | Expected result for that feature | Layer |
| --- | --- | --- |
| Missing displayName; owner absent | missing required key at `/displayName`, `/owner` | runtime + TS/JSDoc consumers |
| displayName number; nickname null; owner undefined | expected text/non-null omittable value/required optional value at exact path | runtime + consumer checks where expressible |
| Explicit nickname undefined | own undefined rejected; distinguish hasOwn from reading an omitted key; checker behavior tested explicitly in each output | runtime + TS/JSDoc |
| Tag-only union variant | object containing only the discriminator; no named empty payload needed | runtime + both foreign consumers |
| Wrong status or kind literal | invalid enum/tag at `/status`, `/event/kind` | runtime + both foreign consumers |
| kind created with reason but missing id | selected-payload missing/unknown property; no acceptance through another branch | runtime + both consumers |
| Extra top-level/payload property | closed-record error identifying offending key; TS fresh-literal diagnostic only approximates runtime closure | runtime + fresh foreign literal |
| labels element wrong; samples element fractional/out of range | `/labels/0` wrong enum; `/samples/0` must be an i16 integer | runtime; TS number cannot enforce the native integer constraint |
| Count -1, 1.5, 4294967296 | native u32 constraint, before native cast | runtime; `number` annotation cannot reject them |
| Unsafe i64/u64 boundary probe | ±9007199254740991 valid when native range allows; ±9007199254740992 rejected on encode/decode | focused numeric test, no broad model extension |
| Float conversion | JS 0.1 converts normally to f16/f32; nonfinite input and conversion overflow reject | focused numeric test |
| NaN, infinity, BigInt, sparse array, Date | nonfinite/wrong kind/hole rejected | runtime; devalue parser can represent these |
| Invalid UTF-8; unpaired JS surrogate | reject invalid native text / unsupported received string, never replacement silently | typed text + runtime boundary |
| Duplicate input property, unknown tag, malformed devalue reference | reject at parser/typed boundary with useful path/format error; verify parser preserves enough evidence | raw-format and typed tests |
| Configuration field/option typo, unsafe numeric enum, discriminator collision, untagged/scalar-payload union, combined absent/null/value acceptance | deterministic admission failure before either file is published | focused negative/compile fixtures |
| Native names and malicious description text | deterministic inflection, collision/representability checks and escaped comment delimiters/controls | both printers/consumers |
| Output lifecycle/cache | ownership conflicts, stale cleanup, stable unchanged files, check-only drift and resumable partial publication; hits still inspect destinations | first generator |

For B, demonstrate both declaration consumers, the small canonical-JS exchange, representative failures and allocation cleanup for the implemented shapes. Independently expected values matter more than matching round trips. The wider test catalog and future roadmap do not gate an A-only delivery.

## Grow this same example

After B, add one named Node with a text label and `[]const Node` children; test a finite tree in Zig, JS, TS and JSDoc. Add a pointer-backed optional parent/next case, a finite mutual-reference case and a recursive union payload case. Test runtime cycle refusal separately; no need to fabricate undefined/dangling native pointers. Use the parity research to select later work in this same example. Ownership/publication and cache correctness belong to the first generator. Eventually demonstrate native schema/JSON validation, JSON codecs, Swift and later Kotlin data-class compiler consumers there. Keep backends in this project; a public custom-backend SDK and TypeScript barrels are not required. Swift is not an existing peer backend or first-slice acceptance. Framework forms/routes and remote-operation policies stay outside this example/library boundary.
