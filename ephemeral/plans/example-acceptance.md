# One public example: proposed acceptance

Status: **design only**, 2026-10-25. Updated preferred direction: native ?T defaults omittable, with a type-owned per-field required override; no dedicated missing-field wrapper. No `example/` sources, library, generated files, dependency lockfile or passing tests exist yet. The primary [mapping proposal](mapping-contract.md) controls semantics; [feature parity IDs](feature-parity.md) connect these cases to peer source. This describes one growing consumer project at exactly `./example`, used for both adopter documentation and integration acceptance. Focused admission/printer tests stay beside future library code; invalid fixtures may live under that example's test inputs without becoming separate projects.

## Checkpoint A: primitives and a basic struct

First prove native `bool`, `u32`, `f64`, text and one named ordinary record. A small public-interface generator projects the record to both `types.ts` and JSDoc `types.js`. Handwritten TS and checked-JS consumers import the respective types. Valid values must compile; missing required, wrong scalar kind and null must fail for the intended reason. Independently assert the intended JS object before adding any round trip. Test `u32` boundaries, fractional integer refusal, nonfinite float refusal and bad UTF-8 separately. This checkpoint does not require devalue, schemas, generated Zig codecs, recursion, or a new runtime implementation.

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
    pub const projection = .{};
};
const Deleted = struct {
    reason: []const u8,
    pub const projection = .{ .fields = .{
        .reason = .{ .bytes = .utf8_text },
    } };
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
    samples: [2]i16,
    event: Event,

    pub const projection = .{
        .description = "A queued delivery.",
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

An otherwise equivalent `PointerEnvelope` changes only the native event field to `PointerEvent` and supplies the same type-owned configuration. Both models are selected through the eventual public interface. Native fields remain idiomatic Zig data; the inline namespace constant configures wire/projection behavior without adding per-instance fields. **All configuration names above are illustrative and uncompiled, not a finalized API.** Unknown description/rename keys and a misspelled/missing required configuration constant must reject. Labels are tag-name enum strings, not bytes or numeric backing tags.

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
  "display-name": "Ada",
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
  "display-name": string;
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
 * display-name: Name shown to the recipient.
 * @typedef {{ "display-name": string, count: number, active: boolean,
 * status: Status, nickname?: string, owner: string | null,
 * labels: Array<Status>, samples: Array<number>, event: Event }} Envelope
 */
export {};
```

PointerEnvelope may have a separate emitted alias, but must have the same structural meaning in both outputs. Compare semantics, not coincidental declaration names or all serialized byte ordering. Separately unit-test exact devalue bytes against the pinned runtime only where protocol parity is the claim.

## Exchange and consumer proof

Pin Zig 0.17.0, a concrete shared devalue-runtime source revision/content hash, canonical JS `devalue` exactly 5.9.4, Node, and an exact TS checker with its lockfile when implementing. The cached runtime's commit is prior art, not a published dependency selected by this proposal. Record actual tool versions, command results and skips. Do not use `latest`, a directory named v6, or moving Svelte/Kit main manifests as a reproducible protocol pin. Svelte/Kit major-5 selection is existing discussion context; the cached exact sources substantiate 5.9.4's behavior.

The example should expose a readable generate step and an acceptance step. Its own realistic `build.zig`/manifest use the library's public package module, initially through a local path dependency to the repository root. No private source imports, copied internal helpers, second integration project, web server, or SKGo dependency. A host-built generator shares the model module and runs through an explicit tracked build Run step, producing TS and JSDoc into distinct output directories. Test executables need actual run edges, not only compilation. Host/target-dependent metadata must be explicit and compared; the simple fixture uses fixed-width numbers. The native codec mechanism remains undecided.

1. Zig encodes both native representations through the typed adapter and shared runtime; canonical JS 5.9.4 parses each document. JS asserts the literal expected value and own-key/type facts above.
2. JS independently constructs a second value: same required basics, `nickname: "Countess"`, `owner: "Grace"`, `labels: []`, `samples: [32767, -32768]`, `event: { kind: "deleted", reason: "duplicate" }`. JS stringifies it with 5.9.4; Zig decodes separately into Envelope and PointerEnvelope and asserts every native field, active union tag and payload. Do not generate this producer from the Zig output.
3. Both typed decoders also consume the first JS expected object, checking absence/null. Destroy raw bytes and the parsed graph before reading the owned typed result; prove its strings and pointer payloads remain valid, then release it exactly once. Exercise allocation failure after a nested allocation and invalid nested data after earlier successful allocation; assert cleanup with a checking allocator. Do not use process exit 0 alone as leak proof.
4. Compile real positive TS and checked-JS ESM consumers separately using strict checking, `exactOptionalPropertyTypes`, and JS `allowJs`/`checkJs`. Prove omitted nickname, required owner null, both event tags and discriminator narrowing. Compile each negative consumer and assert the intended diagnostic location/category; no blanket “any compiler failure counts” or unused suppression comments. Import runtime JS module to confirm typedefs are not runtime values. Parse/lint both printer outputs as an additional syntax gate.

The planned commands/step names are interface goals, not commands that currently exist. Their implementation should make the ordinary adopter path the acceptance path. Record absent tools as **not qualified**, rather than skipping a required output and reporting acceptance passed.

## Negative cases and limits

| Case | Required observation | Layer |
| --- | --- | --- |
| Missing display-name; owner absent | missing required key at `/display-name`, `/owner` | runtime + TS/JSDoc consumers |
| display-name number; nickname null; owner undefined | expected text/non-null omittable value/required optional value at exact path | runtime + consumer checks where expressible |
| Explicit nickname undefined | own undefined rejected; distinguish hasOwn from reading an omitted key; checker behavior tested explicitly in each output | runtime + TS/JSDoc |
| Wrong status or kind literal | invalid enum/tag at `/status`, `/event/kind` | runtime + both foreign consumers |
| kind created with reason but missing id | selected-payload missing/unknown property; no acceptance through another branch | runtime + both consumers |
| Extra top-level/payload property | closed-record error identifying offending key; TS fresh-literal diagnostic only approximates runtime closure | runtime + fresh foreign literal |
| labels element wrong; samples wrong length | `/labels/0` wrong enum; `/samples` exact length 2 | runtime; TS cannot enforce this fixed length |
| Count -1, 1.5, 4294967296 | native u32 constraint, before native cast | runtime; `number` annotation cannot reject them |
| Unsafe i64/u64 boundary probe | ±9007199254740991 valid when native range allows; ±9007199254740992 rejected on encode/decode | focused numeric test, no broad model extension |
| f32 exactness probe | native 0.1 widens to 0.10000000149011612; JS 0.1 rejected for f32; finite exact values pass | focused numeric test |
| NaN, infinity, -0, BigInt, sparse array, Date | nonfinite/wrong kind/hole rejected; -0 normalizes to +0 | runtime; devalue parser can represent these |
| Invalid UTF-8; unpaired JS surrogate | reject invalid native text / unsupported received string, never replacement silently | typed text + runtime boundary |
| Duplicate input property, unknown tag, malformed devalue reference | reject at parser/typed boundary with useful path/format error; verify parser preserves enough evidence | raw-format and typed tests |
| Metadata typo, unsafe numeric enum, discriminator collision, untagged/scalar-payload union, combined absent/null/value acceptance | deterministic admission failure before either file is published | focused negative/compile fixtures |
| Punctuated key and malicious description text | valid type-checkable declarations, escaped comment delimiters/controls; no source injection | both printers/consumers |
| Partial output failure | failure reported even if a preceding file was written | publication test, after basic generator exists |

Checkpoint B is complete only when both foreign consumers and canonical JS exchange actually execute with no required skips, pointer/inline semantics agree independently, strict failures occur for the right reason, and ownership cleanup is demonstrated. Golden strings and matching round trips alone do not meet it. A smaller A-only delivery must be labeled A-only.

## Grow this same example

After B, add one named Node with a text label and `[]const Node` children; test a finite tree in Zig, JS, TS and JSDoc. Add a pointer-backed optional parent/next case, a finite mutual-reference case and a recursive union payload case. Test runtime cycle refusal separately; no need to fabricate undefined/dangling native pointers. Extend through the parity matrix in the same example as features land. Eventually demonstrate native schema/JSON validation, JSON codecs, publication/no-change/repair, public custom backend access and Swift compiler consumers there. Swift is not an existing peer backend or first-slice acceptance. Framework forms/routes and remote-operation policies stay outside this example/library boundary.
