# Agent instructions

## Product and current direction

**z-kit** is a Zig backend for ordinary SvelteKit applications, building on SKGo's application model. Use the **current Zig development build** and the actual SvelteKit/Vite toolchains.

Start with [the feature specification](ephemeral/plans/first-application-spec.md). The initial foundation includes `zkit new` wrapping the upstream SvelteKit generator with empty/examples choices, plus a real app running in Vite on a Unix domain socket behind a Zig network listener/proxy. Application creation and the development host are implemented; see ephemeral/proof/application-creation/README.md for fresh empty/examples proof. Preserve that generated-app behavior as features progress. Extend the shared examples progressively. Remote functions, page loads and backend reloads are the current preferred progression; choose each next feature for its usefulness and value to the whole application.

The [bring-up baseline](ephemeral/plans/z-kit-bringup.md) maps broader features and product milestones. Development-online, deployable and customer-ready remain distinct outcomes. The full inventory is reference context; implement only selected, specified features. Resolve design decisions when the selected feature needs them.

The projector is an internal source module under `modules/projector`, independent of routing, HTTP, Vite and the renderer. One application-wide generator owns integration. The shared devalue runtime remains a separate dependency. The earlier [generation lifecycle design](ephemeral/plans/generation-lifecycle.md) is deferred reference material, not first-generator scope.

When changing `zkit new`, follow the feature spec's SKGo reference-work section: trace the real CLI, VitePlus creation flow and native `sv` add-on. Preserve upstream's prompts and minimal/demo selection, and apply frontend decoration through `sv add`. The rejected `ba23bf2` implementation was reverted; do not reuse its separate starter prompt or forced-minimal/manual-decoration approach.

For creation and any future `zkit add`, dependable behavior is scoped to supported vanilla starter shapes; customized applications are best effort. Coding agents must not design or implement general-purpose merging or reconciliation of arbitrary projects, customization-history tracking, template-provenance tracking, or machinery to certify that an application is vanilla. Reuse upstream warnings and report unsupported shapes directly. Do not expand scope to make arbitrary customizations work.

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

Unit tests are good hygiene. Proof is building and running the repository example and freshly generated applications, demonstrating their expected feature claims. Both empty and examples starters must build and start; each new feature, including remotes and loads, must work in a fresh generated examples app without manual setup repairs. Wrap upstream scaffolding rather than reimplementing it. Do not introduce correctness machinery, elaborate proof infrastructure or heavyweight testing, or let review expand the selected scope. Planning documents, compiler experiments and test passes do not establish working framework behavior.

For Zig code changes, run `zig build test` at the repository root. The full configuration diagnostic runner is documented in [the projector README](modules/projector/README.md). Use focused document/link checks for documentation-only changes.

## Working rules

Do task work in a worktree. For non-trivial repository work, follow `/Users/tyler/.agents/skills/session-worklog/SKILL.md` and maintain a tracked worklog under `ephemeral/worklog/`. Keep raw/temporary artifacts under `ephemeral/`; reserve `docs/` for polished, durable documentation.

Answer questions directly. A question about a decision is a request for explanation, not automatic authorization to reverse it. Keep exploration, specification and implementation authority distinct.
