# Adversarial review, round 02: z-kit first application specification

Target: `ephemeral/plans/first-application-spec.md` as it stands in the working tree on `codex/first-application-spec`, plus the reference documents edited alongside it in the same change: `z-kit-bringup.md`, `generation-lifecycle.md`, `README.md`, `modules/projector/ephemeral/plans/mapping-contract.md` and `example-acceptance.md`. The last commit is HEAD `e5c818d`.

Outcome: **only nitpicks remain**

## Scope and caller instructions

The launch prompt asked for a re-review of the whole current work against the same sources, with this file as the only write. It contained no narrowing. As in round 01, I treat spec lines 138–142 ("How features are demonstrated"; the user authority is recorded in worklog line 27) as a constraint on what a review may recommend. It does not limit which defects the review may report.

## Evidence inspected

- `AGENTS.md`, `README.md` and `build.zig.zon`.
- `git diff HEAD` for all seven modified files, and the full current spec.
- The worklog entries that record the round-01 response (worklog lines 27–31).
- The full current `z-kit-bringup.md` and `generation-lifecycle.md`.
- `mapping-contract.md` (generation and proof sections, and the link at `:94`).
- `example-acceptance.md`, `feature-parity.md`, `mapping-delta-review.md` and `codec-experiments.md`. I searched all of them for leftover lifecycle, check-only, stale-output, first-generator and revision-coherence requirements.
- SKGo `618f467b` development-server sources, unchanged since round 01 (`frontend.go`, `router.go`, `session.go`, `dev-host.js`).
- My round-01 review, `20261025-first-application-round-01.md`.

I ran no builds or tests. The change is documentation only.

## Round-01 findings: disposition

1. **Generation-lifecycle witnesses versus the scope constraint: resolved in the authorities.**
   - Spec `:78` now uses ordinary tracked build steps and Zig's caches, and says ownership manifests, check-only, fingerprints and resumable publication are not requirements of this feature.
   - Spec `:74` replaces revision-coherence machinery with building and running the binding and the implementation together.
   - `generation-lifecycle.md:1–5` is marked deferred.
   - The bring-up row at `:36`, the mapping contract at `:72–77` and `example-acceptance.md:3,7` now match.
2. **Host/backend boundary: resolved.**
   - Spec `:52` says the development host is tooling and that the first feature has no native backend.
   - Spec `:72` introduces a separate backend with remotes. The host routes browser remote calls to it, Vite's server-side calls reach the same implementation, and the developer restarts the backend manually while the host and Vite keep running.
   - This matches SKGo's stable-listener, replaceable-host model (`session.go:2`, `router.go:88`) and the reload feature's "extend the existing development host" (spec `:110`).
3. **Engine-qualification ordering: resolved.** `z-kit-bringup.md:64` now says outright that it replaces the earlier instruction to qualify an engine before broad generation work. Spec `:128` agrees, and so does the README.
4. **Kit/Vite pin and launcher: resolved** at spec `:52`.
5. **Stale provenance and README: resolved.** Spec `:146` and the README are updated.

## Findings

No critical issues or material issues remain. Two nitpicks follow.

### 1. Nitpick: lifecycle-gate wording is still present in documents the authorities link to

Evidence:
- `z-kit-bringup.md:62`: "Reuse this one app for publication/cache witnesses…"
- `z-kit-bringup.md:35`: the development-loop row lists "revision coherence" for first online.
- `example-acceptance.md:175`: the output lifecycle/cache row (ownership conflicts, stale cleanup, check-only, resumable publication) is still assigned to "first generator", and `:181` repeats "Ownership/publication and cache correctness belong to the first generator."
- `feature-parity.md:3`: "Publication/cache correctness now belongs to the first generator". Its M35 row (`:52`) asks for destination ownership inspection with the first generator.
- `mapping-delta-review.md:25`: "Initial generation now includes ownership/publication and cache identity/invalidation decisions."
- `codec-experiments.md:48`: still calls `generation-lifecycle.md` "the initial generation/cache design".

The spec links to `mapping-contract.md` (`:76`), which in turn links to the example and parity documents (`:94`).

Impact: low. The precedence statements settle each conflict. The bring-up status line says milestones add no gates to the first feature. The `example-acceptance.md` status says the spec governs. `feature-parity.md` defers to the build brief, which now defers the lifecycle. The reload feature's own requirement that an obsolete build never replace a newer one (spec `:110–112`) reasonably satisfies the "revision coherence" row. Even so, an agent reading one of these leaf documents without that chain will see the superseded first-generator assignment and could reopen it in a later review round. A one-line "deferred, see the spec" note at each of these points would close it.

### 2. Nitpick: the spec does not say who starts and stops the backend process introduced with remotes

Evidence: spec `:72` says the developer "explicitly regenerates, rebuilds and restarts the backend while the host and Vite remain running" and leaves the private transport open. It does not say whether the development host launches the backend as a child process or the developer runs it separately and the host dials it. The first feature's cleanup claim (`:42`, "Stopping the development session releases its listener, its owned Vite process and its socket") and the bring-up's "one owner for … child cleanup" (`z-kit-bringup.md:35`) apply to both arrangements differently.

Impact: low. This is an implementation choice the spec deliberately leaves to the remote feature (`:68`, "when this feature is specified for implementation"). Settling it then, in one sentence, keeps the remote demonstration's restart and stop behavior unambiguous.

## Checked and not reported

- The new remote-feature text does not bring in correctness machinery. "Diagnose unsupported signatures" plus a build-and-run demonstration fits the "How features are demonstrated" section.
- The reload feature's readiness and obsolete-build rules (spec `:110–112`) describe the behavior that feature exists to deliver, not separate infrastructure.
- Kit/Vite version pinning now appears at both `:52` and `:80`. The repetition does no harm.
- The development-online, deployable and customer-ready milestones remain distinct, as `AGENTS.md` requires.
