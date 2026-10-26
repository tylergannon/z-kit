# Trivial development server demonstration

October 25, 2026, macOS arm64. Compiler: Zig `0.18.0-dev.543+fa4f5b262`; Node `24.22.1`; pnpm `12.15.0`; SvelteKit `3.1.0`; Vite `8.3.5`; Svelte `5.57.2`. This demonstrates the first development-server feature. Native remotes, native page loads, backend reloads and production rendering remain future work.

## Running application

Opened `http://127.0.0.1:5173/` in the actual browser, clicked the counter and observed `Clicks: 1`. Changed the page text to “Hot reload is alive.” and observed it update without browser navigation. The browser's Vite logs report a connection and two hot updates to `/src/routes/+page.svelte` (the edit and its restoration). Svelte reset the component-local counter during updates; state preservation is not claimed.

- [Hydrated application screenshot](application.png)
- [Edited page screenshot](hmr.png)
- [Browser state and Vite connection/hot-update logs](browser.json)
- [Server-rendered HTML](page.html) and [HTTP headers](page.headers)
- [Listener ownership](listeners.log): the public TCP listener belongs to Zig; the Vite process listens on its Unix socket.

The second screenshot shows the temporary text; the source has been restored to “Room to grow.” Browser log timestamps use UTC; the demonstration date above uses the user's America/Costa_Rica timezone.

## HTTP forwarding and session lifecycle

[Results](lifecycle.json) and individual logs in this directory demonstrate:

- Real Kit HTML, frontend module and static asset loading through Zig; HEAD and 404 behavior.
- POST and PATCH with 256 KiB binary bodies, an encoded path/query, request headers, a response cookie and HTTP 207.
- A streamed chunked response from Kit.
- An occupied public port fails before readiness and without starting Vite.
- SIGTERM and SIGINT remove the child, listener, socket and private directory; the same public port restarts immediately.
- Killing Vite produces a failure exit and removes the listener/socket.
- Missing application startup and a deliberately hung application never announce readiness; the latter reaches the 30-second deadline.

The ad hoc [lifecycle script](lifecycle.py) uses the real SvelteKit example. To reproduce, run `zig build install`, temporarily copy [transport-fixture.js](transport-fixture.js) to `example/src/routes/proxy-check/[...tail]/+server.js`, then run `python3 ephemeral/proof/dev-server/lifecycle.py` from the root and remove that temporary route afterward. The route is not part of the shipped example. [The hung application](hanging-app/vite.config.js) is only a startup-failure fixture.

The byte tunnel preserves Vite's handling of early TCP half-close. The direct Unix socket and Zig path both close without serving the deliberately half-closed request in this fixture; no extra HTTP interpretation or stronger half-close behavior is claimed.

## Required checks

`zig build test` passes: the development host compiles, the 14 configuration/module tests pass, and the explicit comptime proof compiles. `pnpm check` reports no errors or warnings. `pnpm install --frozen-lockfile` succeeds.

The projector diagnostic runner also passes all 11 expected compiler refusals, the positive configuration test and comptime compilation on the development compiler. [Its fresh result](projector-development.json) records the actual executable/version and source hashes. [Build output](projector-build.log) retains the module checks. The original tracked Zig 0.17 results remain historical evidence.

Text snapshots normalize line endings and trailing whitespace. The terminal demo logs and screenshots are retained locally in this worktree; they have not been uploaded to a remote artifact host.
