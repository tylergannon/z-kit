# Review of application creation

Reviewed October 27, 2026. Source chat: [Start z-kit work](codex://threads/01a17617-2c9e-7190-b6b5-4750efbefab9).
Reviewed branch: `codex/upstream-app-creation`, fixed head `6738995` (full SHA recorded in `review-state.log`), against `main` at `d7f9552`.
Review took place in a separate worktree. No framework implementation fixes were made.

## What the chat did

The initial turn researched the actual SKGo CLI, qualified frontend environment,
VitePlus creation, native sv add-on, default testing/Storybook setup and completion
checks. After the user's correction, it ran real SKGo minimal/demo creation before
writing the plan in `3e60643`. The next authorized turn implemented that plan in
`6738995`.

The implementation adds `zkit new`, preserves sv's upstream prompts and
minimal/demo choices, applies frontend integration through `sv add`, installs
default Vitest/Storybook tooling without replacing an existing unit-only choice,
and writes a root Zig package/build with a declared local framework dependency.
It makes the existing Zig development host consumable by those applications,
resolves Vite from the application's own dependencies, and improves signal/socket
cleanup. It also records usage instructions and substantial original proof.

This is the application-creation/development foundation. Rendering still runs in
Vite/SvelteKit behind Zig; native Zig application remotes, loads, backend reloads,
production rendering and published framework distribution remain deferred.

## Code assessment

The implementation is compact and has sensible ownership: `new.zig` orchestrates
creation, `frontend.zig` owns the qualified child environment, the JavaScript
add-on owns frontend transforms, and `build.zig` shares application integration.
The applicable add-on transformations are recognizable adaptations of actual
SKGo source, with attribution. Read-back checks reject an incomplete upstream
result and a successful sv invocation that did not apply integration. The shared
examples page and application-local Vite resolution avoid duplicate templates
and accidental dependence on framework frontend packages.

I found one actionable defect. No other material defects were found in the
reviewed changes. This is bounded review evidence, not qualification of every
upstream add-on combination or future Zig compiler.

### P2: generated Playwright launcher bypasses session cleanup

`tooling/sv/addon.source.js:118-121` rewrites Playwright's server command and URL,
but supplies no `webServer.gracefulShutdown` policy. The installed Playwright
1.64.1 runner explicitly skips graceful shutdown when that option is absent;
its process launcher then sends SIGKILL to the entire process group. Zig's signal
handlers and deferred socket-directory cleanup cannot run.

Reproduced twice on an untouched freshly generated demo/TypeScript app with
`playwright=demo:yes vitest=usages:unit`. Both E2E tests passed, the public port
and processes were released, and both `/tmp/z-kit-*/vite.sock` files/directories
remained. See [observations](playwright-cleanup.json),
[first run](examples-playwright-test.log) and
[repeat](examples-playwright-test-repeat.log).

A temporary generated-app-only experiment adding
`gracefulShutdown: { signal: "SIGTERM", timeout: 5000 }` made the same test pass
with complete directory removal. See [experiment](playwright-graceful-experiment.log)
and [result](playwright-graceful-result.json). The generated config was restored;
the framework and tracked bundle were not changed. The narrow correction belongs
in the add-on's Playwright transform and its rebuilt bundle. This is a resource
leak in the provided E2E workflow, not a rendering or test failure.

The original proof demonstrates manual/session shutdown successfully, but it
does not establish complete cleanup after the Playwright-managed session.

## Independently reproduced behavior

All successful apps below were fresh destinations created through real upstream
VitePlus/sv and the real z-kit add-on. No manual setup repairs were needed.

| Behavior | Independent result and artifact |
| --- | --- |
| Empty starter with omitted nonterminal choices | Creation, installation, checks and Zig/frontend build passed. [Creation](empty-create.log), [browser](empty.png). |
| Examples starter, JSDoc, Tailwind, existing unit-only Vitest | Creation/build passed; Tailwind retained, stock demo removed, counter hydrated. [Creation](examples-create.log), [HMR and counter](examples-hmr-counter.png). |
| Repository example | Rendered and hydrated through Zig; source edit reached the existing page without navigation. [Start](repository-start.log), [HMR screenshot](repository-hmr.png). |
| Frontend HMR | Both repository and generated examples pages updated at their same Zig addresses; browser recorded Vite hot updates. [Browser logs](browser.json). Temporary source edits were restored. |
| Independent install/check/build | Copied only source/configuration into a separate app directory, excluding node_modules, Zig cache/output, Kit/build and Storybook outputs. With framework node_modules moved away, its documented root commands installed from the lockfile, checked and built successfully, and its browser counter worked. [Commands/output](reinstall.log), [start](reinstall-start.log), [browser](reinstall-counter.png). |
| Repeated examples creation with Playwright | Real demo/TypeScript app with selected Playwright and unit-only Vitest built without repairs. [Creation](examples-playwright-2-create.log). Its E2E fixture passed through Zig twice, with the cleanup defect above. |
| Interactive creation | Observed sv's actual template chooser in a PTY, selected demo, completed all stages with exit 0, and hydrated its counter through Zig. Framework node_modules was unavailable during creation and runtime. [Start](interactive-start.log), [browser](interactive-counter.png). Prompt/completion observations were recorded in the review tool transcript, not a complete saved creation log. |
| Unit/component tests | Empty: two tests passed, including Chromium component test. Examples: selected single unit test passed. [Empty](empty-tests.log), [examples](examples-tests.log). |
| Storybook | Empty and examples builds passed. [Empty](empty-storybook.log), [examples](examples-storybook.log). |
| Listener ownership | z-kit-dev owned public ports 5271/5272/5273; Node owned private Unix sockets. [Listeners](listeners.log), [sockets](sockets.log). |
| Restart and ordinary cleanup | Both starters answered HTTP 200 on two starts at the same port; group SIGINT removed each socket directory and released the listener. [Results](lifecycle.json), [one-off reproduction script](lifecycle.py). Additional browser sessions also cleaned up. |
| Occupied port | Failed with AddressInUse without readiness. [Output](occupied-port.log). |
| Nonempty destination / invalid template | Both refused. [Nonempty](nonempty.log), [template](invalid.log). |
| Cancellation | Ctrl-C at the actual sv chooser returned exit 1 and removed temporary root package metadata. [Output](cancellation.log). |
| Upstream failure / no-op add-on | Exit-42 upstream failure and zero-exit no-op sv add both failed without a native scaffold/success; temporary root package metadata removed. [Failure](upstream-failure.log), [no-op](unapplied-addon.log). |
| Framework checks | `zig build test`, repository Svelte check, Zig format and diff whitespace checks passed. Add-on rebuild reproduced tracked bytes. [State/check record](review-state.log), [Svelte check](repository-check.log), [add-on build](addon-build.log). |

## Reproduction boundaries and cleanup

Used the same installed Zig `0.18.0-dev.543+fa4f5b262`, VitePlus/core 1.4.0,
managed pnpm 12.14.0 and sv 1.1.1. Managed creation used Node 24.22.1; direct
development commands also ran successfully with the shell's Node 26.12.1.
The current upstream fresh apps resolved Svelte 5.57.3 and TypeScript 6.0.3,
rather than the original record's 5.57.2/6.0.2. This is a functional reproduction
of the current generator, not byte-for-byte recreation of the old app lockfiles.
The ordinary package store and isolated add-on cache remained available.

Read the required Zig cache entrypoint, build/I/O routes and relevant leaves,
then the original local-dependency and process-child lifetime sources; checked
the relevant Child API against the installed development compiler. The cache
is historical 0.17 evidence and was not changed. Inspected actual SKGo source;
the earlier SKGo reference creation runs were not rerun for this review.

All review-owned servers are stopped, framework dependencies and temporary
source edits restored, and the two review-created leaked sockets removed after
recording their paths. The source chat's worktree and branch were preserved.
Generated apps remain local under this review directory for inspection; the
checkpoint tracks the report and selected evidence rather than generated apps
or dependency trees. No remote proof upload service was requested/configured;
these artifacts are local and inspectable in Codex.
