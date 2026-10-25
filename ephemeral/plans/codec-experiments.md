# JSON codec architecture experiments

Status: **deferred, unexecuted**. The [mapping proposal](mapping-contract.md) is now the primary next task, including both TypeScript and JavaScript with JSDoc. Resolve the shared value/admission semantics before comparing codec implementation mechanisms. This document preserves the earlier architecture discussion and comparison; it accepts no exact API, representation, performance target, or implementation milestone. Keep the separate Type Projector repository as the workspace for now; merging it elsewhere remains possible later.

Terminology: the current preferred proposal uses ordinary native Zig optionals `?T` plus a type-owned comptime constant carrying per-field required overrides: ?T defaults omittable; required ?T emits null for native null. There is no separate Nullable or Presence wrapper. The same two native states map either to required key with value/null, or to omitted key/non-null value; own undefined is rejected. Exact metadata spelling remains open. The comparison below must use these current semantics when eventually executed.

## Direction and the question to resolve

Investigate a small library that takes native Zig type reflection plus explicit metadata, validates and lowers a deliberately restricted shared wire model, and computes a dependency-inclusive semantic fingerprint with that normalized model. Native JSON codecs and runtime-accessible JSON Schema belong in the library's direction. Foreign-language declarations are projected in an explicit generator phase: compilation can compute metadata; filesystem output occurs when the compiled build program or generator runs. The exact public interfaces remain open.

A portable wire model can retain names and shapes while losing the native type and field associations needed to read or construct Zig values. Find the smallest information that must survive lowering: native `T`, field access/construction, deterministically inflected wire fields, presence policy, and enum/union associations. A codec can receive `T` alongside admitted metadata, or a typed descriptor can retain these associations at comptime. Zig type values cannot simply become runtime IR data. Calling this representation a descriptor does not remove its role as an IR. Avoid rebuilding independent wire policy in each consumer.

## Compare two primary approaches

| | A — Generic codec specialization | B — Generated Zig codec source |
| --- | --- | --- |
| Mechanism | Ordinary generic encoder and strict decoder, specialized at comptime over native `T` plus validated lowered information, or a typed descriptor retaining `T`. | Host generator emits a Zig source file with the JSON encoder/strict decoder; the application then compiles it. |
| Phase | Reflection/admission and specialization during application compilation; runtime code reads and constructs native values. No emitted Zig file or heap-IR interpreter is required. | Reflection/admission during host-generator compilation; filesystem output when that executable runs; emitted codecs compile for the application target. |
| Main question | Can the shared lowering retain native associations simply, without duplicating policy or excessive comptime work? | Does explicit source improve diagnostics, ergonomics, or build behavior enough to justify the generator and output lifecycle? |
| Build responsibility | Use ordinary compiler specialization and caching. | Declare generator inputs, generated output, and consumer dependencies in the build graph. Exercise missing/stale output recovery. |

For B, keep the generator's host configuration separate from the application's target and build mode. Explicitly resolve target-dependent types/options so reflecting on the host cannot silently select host wire semantics for a different target. Both approaches must consume equivalent admitted information.

## One small fixture set for both

Use the same representative native types, metadata, literal expected JSON, and invalid-input cases. Begin with a nested record containing an inflected/described field, a collection, an enum, and a tagged union. Freeze the trial's wire names, tags, numeric policy, and ordering/format expectations before comparing; these are fixture choices, not a public API decision.

| Field policy | Valid JSON cases | Rejection cases |
| --- | --- | --- |
| Required non-null | Key with a valid value | Missing key, explicit `null`, wrong kind |
| Native optional configured required | Key with a valid value or `null` | Missing key, explicit undefined, wrong kind |
| Native optional (default omittable) | Absent key or key with a valid value | Explicit `null` or undefined, wrong kind |

Three distinct wire states (absent/null/value) on one field remain outside the proposed contract; native ?T has only two states, so require an admission diagnostic for a policy requesting that combination. Also exercise unknown and duplicate keys, invalid enum/tag values, malformed variant payloads, and an invalid nested value with a useful field path. Assert literal encoding and successful native decoding against independently stated expectations; round trips alone can hide matching mistakes.

Explicitly consider productive recursive types and allocator/lifetime behavior. After the first slice, use one finite recursive value to expose representation/specialization issues; distinguish recursive types from cyclic runtime graphs. Record any deferred capability rather than claiming coverage. For allocated decoding, account for borrowed versus owned strings, input-buffer lifetime, successful-result cleanup, and cleanup on partial failure. Do not build an exhaustive serializer before learning from the small comparison.

JSON and devalue are different formats. The existing Zig devalue runtime in the cache is relevant to later work; `std.json` behavior or this JSON comparison does not prove devalue parity.

## Evidence to collect when authorized to run

Compare call-site and metadata ergonomics, retained native associations, handwritten/generated code size and complexity, admission/compiler/runtime diagnostics, JSON parity, and strict rejection behavior. Record the exact compiler version/source pin, host, target, optimization mode, commands, and cache conditions with later results. No experiments have run for this plan.

For each approach, observe a cold build, unchanged rebuild, native/wire shape edit, and descriptions-only edit. Record which phases rerun and which outputs change, alongside timings; use comparable conditions without inventing a speed target. For B, also delete a generated output and test stale/corrupted output handling. Correct dependencies and repair matter before timing improvements. Leave a short result table and a reasoned recommendation, including remaining uncertainty; either approach can win.

## Fingerprint and library boundary

The fingerprint produced with the normalized model supports semantic/foreign-projection reuse. A hit need not skip reflection, traversal, or lowering. Future projection identity must cover reachable dependencies, descriptions, backend version, and output options. Recursive identity and normalization need explicit treatment; a historical fingerprint experiment is not a canonical format. Do not invent a custom native compilation cache prematurely.

The shared model earns its place when schemas, codecs, and foreign declarations agree on wire policy. Framework operation identity, routes, forms/uploads, transported classes, and deferred values stay with the SKGo successor. No separate grammar repository/lifecycle or broad plugin framework is decided.

## Local evidence and limits

Follow the repository's Zig reference rule. The following citations resolve under `/Users/tyler/zig-token-cache`; they are source bookmarks, not copied research or new execution results.

- Zig 0.17.0 source snapshot, commit `7647adab80dd088f4de3610fd245915a912eb6ad`: `official/language-reference-0.17.0.txt:11578` (comptime type parameters), `official/source/zig-0.17.0/lib/std/lang.zig:750` (native field metadata), and `official/source/zig-0.17.0/lib/std/json/Stringify.zig:448` (generic field traversal). These establish mechanisms, not this library's admission or decoder policy.
- Native associations retained at comptime: `supplemental/candidate/OrlovEvgeny--serde.zig/source/src/core/fields.zig:6-65`. Prior-art snapshot `87425173b8807d5e2bbb6e15d09a4b14de91f217`, not an adopted dependency or full compatibility claim.
- Host generator and generated module: `toolchain/examples/build-sdk/build.zig:7`; tracked input/output APIs: `official/source/zig-0.17.0/lib/std/Build/Step/Run.zig:310-387`. Read as pinned examples/source, not proof our proposed generator is correct.
- Existing Go model separates native/wire names and field states: `polytype/source/typegrammar/grammar.go:159`. Snapshot `fd1f0eff0bdb6d7c886a51e60e2b8c207f5440e2` is context, not an exact Zig grammar mandate.
- Prior direction and open decisions: `branch/snapshot/ephemeral/zig-analysis/DIRECTION.md:30`, `branch/snapshot/ephemeral/zig-analysis/voice-notes.md:92` (field states), and `branch/snapshot/ephemeral/zig-analysis/voice-notes.md:111` (fingerprint staging). Historical prototype: `branch/archive/ephemeral/zig-analysis/codegen-performance/generator.zig:5`; its choices and measurements do not select this architecture.
