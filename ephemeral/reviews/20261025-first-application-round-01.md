# Adversarial review, round 01: z-kit first application specification

Target: `ephemeral/plans/first-application-spec.md` (working tree on `codex/first-application-spec`; HEAD `e5c818d` plus the uncommitted "How features are demonstrated" section).

Outcome: **material findings remain**

## Scope and caller instructions

I took the scope from the repository instructions (`AGENTS.md`), the accepted baseline `ephemeral/plans/z-kit-bringup.md`, the user's direction as recorded in the task worklog (`ephemeral/worklog/20261025-first-application-spec.md`), and the referenced design and source material.

The launch prompt said that "How features are demonstrated" records the user's latest scope and proof constraints. I checked that claim against worklog line 27 and treat the section as an authoritative solution constraint. The findings below do not ask for new correctness machinery, proof infrastructure or heavyweight testing. Spec line 136 also says that review "must not introduce correctness machinery". I read that as limiting what a review may recommend, not which defects it may report. No other narrowing was present.

## Evidence inspected

- `AGENTS.md` (repository and user-level instructions), `README.md`, `build.zig.zon`.
- The full target spec (lines 1–144) and `git diff` of the uncommitted change.
- `ephemeral/plans/z-kit-bringup.md` (full) and its diff in `e5c818d`.
- `ephemeral/plans/generation-lifecycle.md` (full).
- `modules/projector/ephemeral/plans/mapping-contract.md` (devalue clause) and `example-acceptance.md` (checkpoint A).
- The task worklog `ephemeral/worklog/20261025-first-application-spec.md` (full).
- SKGo at `618f467b`: `internal/devserver/frontend.go`, `router.go`, `session.go` (listener, socket, readiness, routing) and `internal/adapter/skgo-adapter/dev-host.js`.
- Zig cache leaf `index/leaves/wire/devalue.md`, which confirms that the shared Zig devalue runtime exists and targets 0.17.0 / devalue 5.9.4.

I ran no builds or tests. This is a documentation review, and the spec claims no runtime proof.

## Findings

### 1. Issue: the remote-function feature requires the full generation-lifecycle witness set, which contradicts the new proof and scope constraint

Evidence:
- `first-application-spec.md:74` requires generation to follow `generation-lifecycle.md`: "owned outputs, unchanged-byte stability, safe stale removal, edited/authored conflicts, check-only and recoverable publication. Verify these properties while demonstrating…".
- `generation-lifecycle.md:33` turns these into eight witnesses for the first example. They include check-only drift, unowned or edited conflicts, owned stale removal and an interrupted, retried publication with resumable staging (`:29`).
- `first-application-spec.md:70` separately requires diagnosing "incompatible generated/frontend/native combinations" before use. That is revision-coherence machinery.
- None of this appears in the feature's observable behavior (`:60–62`). Those lines cover one call, accurate types, and an edit plus explicit regeneration that keeps working.
- `first-application-spec.md:134–136` says proof is demonstrating the feature claims in the example and that implementation "must not introduce correctness machinery, elaborate proof infrastructure or heavyweight testing … do not authorize additional systems or acceptance projects."
- The baseline assigns the generation lifecycle to the "First generator" (`z-kit-bringup.md:36`). The README calls these "selected publication and cache rules".

Impact: whoever implements or reviews the remote-function feature gets two incompatible instructions. Interrupted-publication recovery, a check-only mode and ownership-conflict detection are exactly the correctness machinery the new section forbids. Yet line 74 makes them verification gates for the first generator. A consensus loop will keep reopening this: one round reports missing lifecycle witnesses, and the next calls them out of scope. The worklog (line 27) records the new constraint but not any decision about the existing lifecycle assignment, so the documents cannot settle it.

Needed: a recorded user decision in the spec, mirrored in the baseline row. Either name the lifecycle behaviors the developer actually needs from this feature as observable behavior (for example, "regenerating does not overwrite a file I edited"), or defer the remaining witnesses to a later selected feature.

### 2. Issue: the boundary between the development host and the native backend is unstated, so "explicitly rebuilding" in the remote feature is ambiguous and the first feature may be built the wrong way

Evidence:
- First feature (`:33`, `:50`): "The Zig server owns the public network listener and proxies browser traffic." It does not say whether application native code will run in that process or in a separate backend.
- Remote feature (`:60`): the call works "in the same running application". (`:62`): "explicitly rebuilding/regenerating produces matching frontend and native behavior. Automatic backend rebuild is a later feature." Nothing says what the developer restarts to pick up a rebuilt native function, whether that is the whole dev session (Vite and the listener included) or only a backend.
- Reload feature (`:100`, `:106`): "backend replacement, at the same public address" and "Extend the existing development host". This assumes a stable host that is separate from a replaceable backend.
- How remote requests reach native code is left as "connect Kit's operation identities to native dispatch" (`:68`). SKGo answers this at the proxy, with a stable listener and replaceable host (`session.go:2`) and remote-prefix requests routed straight to the native app socket (`router.go:88`). The spec does not say whether z-kit's proxy plays that role or whether calls pass through Vite.

Impact: the "trivial" first feature naturally becomes a single Zig executable that serves as both proxy and future application. The reload feature then requires reworking the first feature's ownership. In the meantime, the remote feature's observable claim at `:62` cannot be demonstrated unambiguously, because the reviewer cannot tell whether restarting the whole session is acceptable. The spec defers most design choices to feature selection, which is reasonable. This one, however, decides what the first feature's host is.

Needed: one sentence in the first feature saying whether the development host stays independent of application native code. One sentence in the remote feature saying what an explicit rebuild restarts. The mechanism can stay open.

### 3. Issue: the deferred production-engine qualification contradicts the baseline paragraph that the same change left in place

Evidence:
- The spec puts engine selection and qualification under the "Later product feature" (`:122`), after remotes, loads and reloads (`:126`). It says engine selection does not block the Vite proxy (`:130`).
- `z-kit-bringup.md:64`, which `e5c818d` left unchanged, says: "Before spending heavily on broad code generation, qualify one real Kit bundle with the proposed production engine … Selecting JavaScriptCore, QuickJS or a packaging strategy without that proof would leave the biggest risk untouched."
- `z-kit-bringup.md:58–60` was edited to point at the spec's progression but does not reconcile `:64`.
- `README.md` still lists "the production JS engine" among "the next design decisions in the baseline".

Impact: the accepted baseline and the spec give conflicting orders for the project's stated biggest risk. The remote-function, page-load and reload features all build the application-wide generator, the Kit adapter integration and the codec bridge. That is the "broad code generation" `:64` says should wait for engine qualification. A future agent following the baseline would insert an engine spike before the remote feature, while one following the spec would not. AGENTS.md says to follow the accepted baseline, so the conflict has to be resolved explicitly. Implementers cannot be left to infer it.

Needed: record whether the user's progressive direction overrides `z-kit-bringup.md:64`, or at which feature the engine spike becomes a prerequisite, and update the baseline and README to match.

### 4. Nitpick: the first feature does not pin a Kit/Vite version or say who launches Vite on the socket

Evidence: `:39` "starts Vite with the SvelteKit application on a Unix domain socket"; `:52` "Use only the Vite integration needed for this feature"; version pinning appears only under the remote feature (`:76`). The baseline's Kit contract row (`z-kit-bringup.md:25`) requires "One selected Kit version" for first online. SKGo's prior art reaches a socket listener through a z-kit-owned Node launcher that runs Vite in middleware mode, with HMR attached to the same server (`dev-host.js:1–13`). It does not use the stock Vite CLI.

Impact: this is small. The first feature already depends on version-specific Vite HMR and socket behavior, and on a launcher script z-kit has to own. Naming the pinned versions and the launcher as part of this feature keeps the demonstration reproducible. It does not need to fix the mechanism.

### 5. Nitpick: the evidence section and README are stale

Evidence: the spec's evidence section names the z-kit base as `3c2dd52` (`:140`), while the reviewed draft sits on `e5c818d`. The intervening commits are documentation only, so the claim about implemented code still holds. `README.md` still describes the next decisions using the pre-progression framing that the spec and the edited `z-kit-bringup.md:60` replaced.

Impact: this is cosmetic, but a fresh agent starting from the README gets the superseded ordering.

## Not reported

- The Unix-socket, WebSocket and HMR proxy path is realistic. SKGo prior art demonstrates the same arrangement.
- The shared Zig devalue runtime cited at `:72` exists and targets Zig 0.17.0 and devalue 5.9.4, according to the cache leaf.
- The spec keeps development-online, deployable and customer-ready milestones distinct (`:29`), as AGENTS.md requires.
- The progressive feature order matches the user direction recorded in worklog line 21.
