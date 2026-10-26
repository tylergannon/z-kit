# z-kit

A Zig backend for ordinary SvelteKit applications, building on SKGo’s application model.

`zkit new` wraps the upstream SvelteKit generator and adds Zig build/dev integration. Choose an empty application or one with examples. The macOS development host serves the application through **browser → Zig network listener → Unix socket → Vite/SvelteKit**, including hydration and Vite hot updates.

Use the current Zig development build, Node.js 24 and pnpm. Tested with Zig `0.18.0-dev.543+fa4f5b262`, sv `1.1.1`, SvelteKit `3.1.0`, Vite `8.3.5` and Svelte `5.57.2`.

From this checkout, create and run a new application:

```sh
zig build install
./zig-out/bin/zkit new ../myapp --template examples
cd ../myapp
zig build dev
```

Open [localhost:5173](http://127.0.0.1:5173). Creation invokes the real `sv create`, installs the application's dependencies, runs its check when configured, and builds the Zig host before reporting success. Its README records the commands for subsequent work. For the empty starter, choose `--template empty`. In a terminal, omitting that option prompts for the starter and leaves frontend questions to upstream; without a terminal the defaults are empty, TypeScript and no add-ons.

Pass supported frontend choices to upstream after `--`:

```sh
./zig-out/bin/zkit new ../myapp --template examples -- --types jsdoc --add tailwindcss=plugins:none
```

During framework development, generated applications declare a local Zig dependency on the source package used to build the CLI. Use `--zkit-path PATH` to choose another source package. Each application installs and resolves its own frontend dependencies; it does not reuse this checkout's `node_modules`. This is local development scaffolding; registry distribution is not provided yet.

To run the checked-in example instead, from this repository root:

```sh
pnpm install --frozen-lockfile
zig build dev
```

Click the counter, then edit [the page](example/src/routes/+page.svelte) to see it update. The generator uses that same maintained page for the examples starter and leaves upstream's minimal page in the empty starter. Ctrl-C stops the session and removes its Vite process and private socket directory. Choose a different port with `zig build dev -- --port 5180`; an occupied port fails explicitly. The host binds loopback only and announces readiness after the application renders. Startup errors remain visible, an unready application times out after 30 seconds, and a Vite crash ends the session with a failure status.

```sh
zig build test
pnpm check
```

These compile both CLI/host binaries, run 14 projector configuration/module tests plus the comptime proof, and check the repository example. [Generator evidence](ephemeral/proof/new-app/README.md) records fresh empty/examples creation and browser demonstrations; [server evidence](ephemeral/proof/dev-server/README.md) records transport/lifecycle behavior. For the projector's expected compiler refusals, run `python3 modules/projector/ephemeral/projection-shape-lab/run.py`; it uses `zig` from PATH or `ZIG_EXE` when supplied.

The [feature specification](ephemeral/plans/first-application-spec.md) guides the next additions: Zig remotes, page loads and backend reloads. Each must work in fresh generated examples as well as the repository example, while the empty starter remains runnable. These native features and native production packaging are not implemented yet. The [internal projector](modules/projector/README.md) currently implements projection configuration; mapping and codecs remain future work. The [bring-up baseline](ephemeral/plans/z-kit-bringup.md) covers broader milestones; [generation lifecycle](ephemeral/plans/generation-lifecycle.md) is deferred design material.
