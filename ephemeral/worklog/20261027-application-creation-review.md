# Review of application creation

decision: Review the fixed implementation head 6738995 in an isolated worktree; preserve the source branch and do not implement fixes during this review.

finding: The generated Playwright webServer lacks gracefulShutdown. Two passing E2E runs each left a private socket directory because Playwright defaults to SIGKILL of the process group. A generated-app-only SIGTERM/5s experiment removed the directory; framework source remains unchanged. Add the policy through the add-on rather than trying to handle SIGKILL in Zig.

proof: Independently reproduced fresh empty and JSDoc/Tailwind/unit-only examples creation, repository/generated browser hydration and HMR, default Chromium component tests, selected unit tests, both Storybook builds, clean reinstall/check/build without framework frontend dependencies, interactive upstream demo creation, cancellation/failure detection, occupied-port refusal and twice-repeated same-port starts/cleanup for both starters. Current upstream patch dependencies differ from the older proof; retain that evidence boundary.

friction: Bare noninteractive --add playwright still asks sv's demo question and exits incomplete without stdin; use the fully specified playwright=demo:yes form when reproducing an unattended successful creation. This is upstream option ownership, not a reason to add another wrapper prompt.

correction: In the follow-up add-command discussion, the user bounded dependable behavior to vanilla applications and accepted best-effort behavior after customization. Do not expand this into arbitrary-project merging or a provenance system. Inspected installed sv 1.1.1: its general cleanliness warning checks uncommitted Git changes, not whether committed source still matches an upstream template. Keep that distinction explicit; no add implementation is authorized by this exploratory discussion.

correction: The user explicitly required prohibiting coding agents from pursuing these systems, rather than merely calling them unnecessary. Added the prohibition to AGENTS.md and the controlling feature specification, including a ban on introducing them as acceptance prerequisites. This is a documentation-only scope constraint, not authorization to implement zkit add.

discovery: SKGo's generated Playwright launcher uses just serve, whose generated recipe runs the standalone built Go application; z-kit's uses zig build dev and therefore creates the Vite Unix socket. This source-verified topology difference explains exposure of the socket leak without attributing it to Zig or changed Playwright behavior. Historical SKGo test sessions were not rerun. The leak is minor test-integration housekeeping; describing it as a merge blocker overstated its impact.

decision: The user authorized merging the reviewed application-creation feature with the documented minor Playwright cleanup issue, then starting the next steps with opportunities for concurrent improvements. Merge the implementation, independently reproduced evidence and explicit add-on scope prohibition together. The future add command is deferred; next-feature work begins with specifying the bounded native remote and shared interfaces before parallel implementation.
