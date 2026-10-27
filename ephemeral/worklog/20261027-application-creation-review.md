# Review of application creation

decision: Review the fixed implementation head 6738995 in an isolated worktree; preserve the source branch and do not implement fixes during this review.

finding: The generated Playwright webServer lacks gracefulShutdown. Two passing E2E runs each left a private socket directory because Playwright defaults to SIGKILL of the process group. A generated-app-only SIGTERM/5s experiment removed the directory; framework source remains unchanged. Add the policy through the add-on rather than trying to handle SIGKILL in Zig.

proof: Independently reproduced fresh empty and JSDoc/Tailwind/unit-only examples creation, repository/generated browser hydration and HMR, default Chromium component tests, selected unit tests, both Storybook builds, clean reinstall/check/build without framework frontend dependencies, interactive upstream demo creation, cancellation/failure detection, occupied-port refusal and twice-repeated same-port starts/cleanup for both starters. Current upstream patch dependencies differ from the older proof; retain that evidence boundary.

friction: Bare noninteractive --add playwright still asks sv's demo question and exits incomplete without stdin; use the fully specified playwright=demo:yes form when reproducing an unattended successful creation. This is upstream option ownership, not a reason to add another wrapper prompt.
