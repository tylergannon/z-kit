# Mapping contract proposal — 2026-10-25

decision: Work is a mapping/admission proposal, source-backed parity map and acceptance design. No library, codec experiment, dependency installation, publication, push or PR is authorized by this task.

branch_state: Managed worktree starts at dd0bf05, the same commit as saved main, including both local planning commits ahead of origin/main. Created codex/mapping-contract without resetting or changing the saved checkout.

correction: The latest user clarification makes TypeScript and JavaScript with JSDoc first-class outputs of ONE shared semantic admission contract. Printer limitations must not create different wire policies. Start from primitives/basic structs, then a restricted set of web API compositions; avoid a general serializer.

decision: Cache index/routes/leaves were consulted before proposing reflection, field-state, number, ownership and build rules. Opened original pinned Zig reflection/layout/build/allocator sources, prior direction/voice notes, cached devalue runtime and canonical JS sources. Cache files remain read-only.

discovery: Live peer Polytype is clean at c9ae9678816768776569e1157bd3c4372e1be5c6, newer than cache snapshot fd1f0eff0bdb6d7c886a51e60e2b8c207f5440e2. Parity links must use the live inspected commit and distinguish source-inspected tests from historical execution records. Peer source is reference material; no Polytype code is being changed or tests claimed executed here.

discovery: Polytype's typed devalue intentionally rounds wide numbers, including numeric enum 9007199254740993, while TS rejects that inexact enum literal. Propose safe-integer runtime checks and admission refusal for unsafe numeric enum members for Zig, explicitly marking the change from Go. Native fixed-width representation and JS number semantics need separate treatment.

correction: During review the user explicitly retained Zig's own optional terminology for ?T. Do not introduce Nullable(T), a separate nullable wrapper/type, or rename field omission to Optional. ?T keeps a required wire key whose value can be null; omission remains distinct absent/present state, with Presence only an unresolved placeholder. Update semantic grammar/tables and companion acceptance prose accordingly; peer Go Optional/Nullable names remain source evidence only.

decision: Primary artifact is ephemeral/plans/mapping-contract.md, already created when the later request suggested type-mapping.md but expressly allowed retaining an existing suitable filename. Companion artifacts are feature-parity.md (37 source/test rows), example-acceptance.md (primitive/record checkpoint then bounded canonical-JS exchange), and mapping-evidence.md. README now leads there; codec-experiments.md is preserved and explicitly deferred.

decision: Proposed contract uses one TS/JSDoc mapping, safe-integer checks, finite floats with exact f32 decode and signed-zero normalization, explicit text/numeric byte-list metadata, reserved discriminator keys and owned typed decode. These stricter-than-Go policies remain proposals. Target-sized integer source spelling cannot be reliably distinguished after reflection; require expected width/sign plus actual target checks rather than promising an impossible usize ban. Refuse unlisted compositions and implicit implementation-container traversal.

proof: A local Python Markdown-link check resolved 137 repository/peer/cache links and checked pinned peer commit/line bounds plus balanced code fences; it also checked the primary grammar contains no Nullable abstraction. git diff --check passed. A final small citation/wording edit follows and will receive the same focused checks before checkpoint. No implementation, runtime, foreign-language compiler or peer Go tests ran; all future acceptance and source-inspected tests are labeled accordingly.

branch_state: Saved main remains clean at dd0bf05 (ahead of origin/main by its two original planning commits). User explicitly authorized safe local fast-forward delivery. Recheck saved state immediately before delivery; retain task branch/worktree if incompatible. No push, PR or release.

correction: User's optional rationale is language-enforced explicit handling before payload use. Proposal now distinguishes conditional/fallback unwrap from forced .? assertion using pinned original language reference; do not claim the compiler statically proves all null checks. User is actively reviewing the worktree artifact: preserve this managed worktree even after saved-main integration.

proof: Final focused check passed for 140 Markdown links with existing files and pinned source line bounds, balanced fences, all distinct M01–M37 rows, absence of a Nullable grammar/API, and git diff --check. Peer checkout remains unchanged. Saved checkout rechecked clean on main at dd0bf054016ca85ad680a26c7a38d1773cd50e25 immediately before checkpoint/integration.
