# Agent instructions

All agents doing Zig work must consult `/Users/tyler/zig-token-cache` throughout the work, especially before architecture or design decisions and questions about idiomatic Zig, APIs, ownership, or builds.

Start at `/Users/tyler/zig-token-cache/index/README.md`. For prior Polytype direction and behavior, follow `index/routes/polytype/README.md`; follow the language, memory, build, and wire routes as needed. Read the relevant leaves and open the original sources they cite. Citation paths resolve from the cache root.

Check source versions and provenance against the target toolchain. Distinguish accepted decisions from proposals and historical experiments. Report missing or inaccessible evidence instead of guessing. The cache is maintained separately; do not modify it.

Do task work in a worktree. For non-trivial repository work, follow `/Users/tyler/.agents/skills/session-worklog/SKILL.md`, keep a tracked worklog under `ephemeral/worklog/`, and keep raw or temporary session artifacts under `ephemeral/`. Only polished, durable documentation belongs in `docs/`.
