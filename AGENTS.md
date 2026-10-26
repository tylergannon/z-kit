# Agent instructions

## Product and current direction

**z-kit** is a Zig backend for ordinary SvelteKit applications, building on SKGo's application model. Use the **current Zig development build** and the actual SvelteKit/Vite toolchains.

Start with [the feature specification](ephemeral/plans/first-application-spec.md). The first feature is a real SvelteKit app running in Vite on a Unix domain socket, reached through a Zig network listener/proxy. Extend that same app progressively. Remote functions, page loads and backend reloads are the current preferred progression; choose each next feature for its usefulness and value to the whole application.

The [bring-up baseline](ephemeral/plans/z-kit-bringup.md) maps broader features and product milestones. Development-online, deployable and customer-ready remain distinct outcomes. The full inventory is reference context; implement only selected, specified features. Resolve design decisions when the selected feature needs them.

The projector is an internal source module under `modules/projector`, independent of routing, HTTP, Vite and the renderer. One application-wide generator owns integration. The shared devalue runtime remains a separate dependency. The earlier [generation lifecycle design](ephemeral/plans/generation-lifecycle.md) is deferred reference material, not first-generator scope.

## Zig reference cache

- Cache root: `/Users/tyler/zig-token-cache`
- Semantic index: `/Users/tyler/zig-token-cache/index`
- Entrypoint: `/Users/tyler/zig-token-cache/index/README.md`
- Historical Zig 0.17.0 source: `/Users/tyler/zig-token-cache/official/source/zig-0.17.0/`

All agents doing Zig work must consult this cache throughout the work, especially before architecture/design decisions or questions about idiomatic Zig, APIs, ownership and builds. Follow **entrypoint → relevant route → relevant leaf → cited original source**. Use explicit paths instead of scanning the entire corpus first.

Routes below are relative to the index:

| Topic | Route |
| --- | --- |
| Syntax, reflection, comptime and tests | `routes/language/README.md` |
| Allocators, ownership and lifetimes | `routes/memory/README.md` |
| HTTP, processes, concurrency and cancellation | `routes/io/README.md` |
| Build graphs, host generators and packages | `routes/build/README.md` |
| Compiler, BSP, FFI and platform limits | `routes/toolchain/README.md` |
| Prior Polytype direction, grammar and projections | `routes/polytype/README.md` |
| Shared devalue runtime and serialization | `routes/wire/README.md` |
| SKGo contracts and development supervisor | `routes/skgo/README.md` |

Bare citation paths in the index resolve from the **cache root**, not the leaf's directory. Open the cited originals and check their versions and provenance. The cache is a historical 0.17.0 snapshot; verify current APIs against the installed development compiler's source (`zig env` reports its location). Separate accepted decisions from proposals, historical experiments and current implementation. Old experiments and unversioned examples are not current API guidance. Current user instructions and selected feature scope control over historical cache proposals.

The cache is maintained separately and is **read-only** for project work. It contains source and retained evidence, not a runnable compiler distribution. Report missing or inaccessible evidence instead of guessing; keep newly acquired tools and experiment outputs outside the cache.

## Scope and proof

Describe and discuss features by meaningful names, without coded claim labels. Observable claims describe application/developer behavior; technical requirements belong underneath the features they support.

Unit tests are good hygiene. Proof is building the example application and demonstrating its expected feature claims. Do not introduce correctness machinery, elaborate proof infrastructure or heavyweight testing, or let review expand the selected scope. Planning documents, compiler experiments and test passes do not establish working framework behavior.

For Zig code changes, run `zig build test` at the repository root. The full configuration diagnostic runner is documented in [the projector README](modules/projector/README.md). Use focused document/link checks for documentation-only changes.

## Working rules

Do task work in a worktree. For non-trivial repository work, follow `/Users/tyler/.agents/skills/session-worklog/SKILL.md` and maintain a tracked worklog under `ephemeral/worklog/`. Keep raw/temporary artifacts under `ephemeral/`; reserve `docs/` for polished, durable documentation.

Answer questions directly. A question about a decision is a request for explanation, not automatic authorization to reverse it. Keep exploration, specification and implementation authority distinct.
