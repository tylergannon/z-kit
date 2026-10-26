# z-kit

A Zig backend for ordinary SvelteKit applications, building on SKGo’s application model.

The first working feature is a macOS development host: **browser → Zig network listener → Unix socket → Vite/SvelteKit**. The example renders, hydrates and receives Vite hot updates through the Zig address.

Use the current Zig development build, Node.js 24 and pnpm. Tested with Zig `0.18.0-dev.543+fa4f5b262`, SvelteKit `3.1.0`, Vite `8.3.5` and Svelte `5.57.2`; frontend dependencies are recorded in the lockfile.

From the repository root:

```sh
pnpm install --frozen-lockfile
zig build dev
```

Open [localhost:5173](http://127.0.0.1:5173), click the counter, then edit [the page](example/src/routes/+page.svelte) to see it update. Ctrl-C stops the session and removes its Vite process and socket. An occupied port fails explicitly. To choose a different port or SvelteKit application:

```sh
zig build dev -- --port 5180 --app example
```

The host binds loopback only. Vite uses the private socket for HTTP and HMR, and the host announces readiness after the application renders successfully. Startup diagnostics remain visible; an unready application times out after 30 seconds. A Vite crash ends the session with a failure status.

```sh
zig build test
pnpm check
```

These compile the host, run 14 projector configuration/module tests plus the comptime proof, and check the Svelte application. [Application evidence](ephemeral/proof/dev-server/README.md) records browser, transport and lifecycle demonstrations. For the projector’s expected compiler refusals, run `python3 modules/projector/ephemeral/projection-shape-lab/run.py`; it uses `zig` from PATH, or `ZIG_EXE` when supplied.

The [feature specification](ephemeral/plans/first-application-spec.md) guides the next additions: Zig remotes, page loads and backend reloads. Those features are not implemented yet. The [internal projector](modules/projector/README.md) currently implements projection configuration; mapping and codecs remain future work. The [bring-up baseline](ephemeral/plans/z-kit-bringup.md) covers broader milestones; [generation lifecycle](ephemeral/plans/generation-lifecycle.md) is deferred design material.
