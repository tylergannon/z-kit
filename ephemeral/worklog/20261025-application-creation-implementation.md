# Application creation implementation

decision: The user authorized the source-backed application-creation plan. Completion requires real fresh empty/examples applications building and working through the Zig server. Continue using the cache index and actual SKGo source; no native remotes, loads or backend reload implementation is authorized by this slice.

decision: Keep Zig CLI ownership of orchestration/native files and native sv add-on ownership of frontend edits. Preserve SKGo's default Vitest/Storybook setup and selected unit-only testing. Use VitePlus 1.4.0 and its managed pnpm 12.14.0.

friction: Zig 0.18 path APIs differ from older signatures and std.zig.fmtString escapes string contents without supplying quotes. The first attempted app correctly failed at its build stage and printed no success. Fixed the native template and regenerated in a new destination rather than repairing the application by hand.

decision: Build options record the actual framework source directory for this development CLI; an untracked LazyPath option alone emitted an empty root-relative path. Generated builds consume a declared local z-kit dependency and the Vite launcher resolves the app's own Vite installation, following SKGo's launcher.

proof: Fresh minimal TypeScript and demo JSDoc/Tailwind/unit-only apps passed creation, Svelte checks and full root builds. Both loaded through Zig. The examples counter changed 0 -> 2, and an edited page reached the open browser at the same Zig URL with explicit Vite hot-update messages. Both generated Vitest suites and Storybook builds pass on VitePlus 1.4.0. The default component suite runs in Chromium; the selected unit-only app has only its unit suite.

friction: An interactive creation exposed pnpm's isolated dlx build-approval prompt for esbuild despite CI mode, followed by a frozen-lockfile mismatch from inherited workspace policy. The installed managed pnpm's own help exposes --allow-build and --ignore-workspace; use those through the project's VitePlus exec for the native Storybook installer. Fresh noninteractive and interactive creation now complete without a second approval prompt.

friction: Initial PTY Ctrl-C checks released processes/ports but left private socket directories. Direct/group SIGINT checks isolated terminal hangup as the additional lifecycle condition. Handle SIGHUP with the normal stop flag and finish bounded filesystem cleanup with cancellation blocked, as the cache's I/O leaf prescribes. Five open-browser sessions and two same-port restart cycles for both final starters now remove their socket directories. Removed only this task's initially leaked diagnostics directories.

proof: Final minimal app was created with omitted unattended choices; final JSDoc/Tailwind/unit-only examples was created from /tmp using the source-recording installed CLI. Both were generated while framework node_modules was unavailable. Both built and ran through Zig, and the examples counter and source-edit HMR worked. A separate app had dependencies and all build caches removed, then installed with its lockfile, checked, built and hydrated while framework frontend dependencies remained unavailable.

proof: Repeated TS examples creation and terminal-selected demo both built, started and hydrated. The real Playwright upstream fixture launched the Zig root command and passed. Final starters' Vitest suites passed (two default unit/component tests and one selected unit-only test), and empty/examples Storybook builds passed on VitePlus 1.4.0. Root zig build test and repository Svelte checks passed; the add-on bundle rebuilt to the same bytes used in application creation.

proof: Nonempty destinations, canceled upstream creation, an upstream exit-42 failure and a zero-exit no-op sv add all returned failure without a usable-app success message. Temporary root package-manager metadata was removed on cancellation/failure. Source checkout SKGo remained clean; all task-owned servers were stopped. Removed generated research apps/install outputs after retaining screenshots and concise logs; restored framework node_modules.

proof: Focused documentation/artifact validation resolves all 108 local links. The proof record distinguishes real app/browser demonstrations, regression checks, expected failure injections and deferred native/production features. Final source and add-on bundle correspond to the demonstrated behavior; no unrelated SKGo/cache files were changed.
