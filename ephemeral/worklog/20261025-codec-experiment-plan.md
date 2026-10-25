# JSON codec experiment planning — 2026-10-25

decision: The user wants this existing separate repository to serve as the planning workspace now; later consolidation remains possible. Record the architecture and experiment comparison without implementing codecs, executing experiments, or settling APIs.

decision: Plan compares generic comptime specialization over native types plus admitted metadata against a host generator emitting Zig codec source. Both use identical trial types and literal expectations. Native associations lost by a portable wire model are the central design question; a typed descriptor still serves as IR.

correction: JSON and devalue require separate format proof. Semantic projection reuse need not eliminate reflection/lowering, and it does not justify a custom native compilation cache.

decision: Worked from the clean new-repository checkout at `b5e3c2e` in the `codex/codec-experiment-plan` task worktree. Consulted the cache entrypoint, language/Polytype/build/wire routes and relevant leaves, then pinned original reflection, JSON traversal, typed field-descriptor, build graph, grammar, and prior-direction sources. No cache, Polytype, or SKGo files changed.

decision: Only the plan, its README link, and this worklog are in scope. Commit locally and safely fast-forward the saved checkout; do not push or open a PR. No Zig scaffold or test harness is appropriate for this documentation change.

proof: Reviewed the complete plan against the requested comparison and checked the README link and cited cache paths/line bounds. `git diff --check` passed. Experiments remain unexecuted; no code tests were introduced or run for this docs-only change.

branch_state: Local checkpoint on `codex/codec-experiment-plan`; no push or PR. The saved checkout was clean on `main` at `b5e3c2e`, so delivery uses a fast-forward after checking it remains unchanged. Integration outcome is verified at closeout.
