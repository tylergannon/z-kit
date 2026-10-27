# z-kit

A Zig backend for ordinary SvelteKit applications, building on SKGo's application model.

Create an empty application or choose SvelteKit's demo to get the z-kit examples.
The real upstream Svelte CLI owns template, language and add-on choices; z-kit
adds the Zig build/development host and integrates the frontend through `sv add`.

Use macOS, the current Zig development build, Node.js 24 and VitePlus **1.4.0**.
Tested with Zig `0.18.0-dev.543+fa4f5b262`, Kit `3.1.0`, Svelte `5.57.2` and
VitePlus's Vite core `1.4.0`. Creation and installation use its managed pnpm
`12.14.0`; dependencies and resolved versions live in each app's lockfile.

Build the CLI from this checkout:

```sh
zig build install
./zig-out/bin/zkit new myapp
cd myapp
zig build dev
```

Open [localhost:5173](http://127.0.0.1:5173). The path is
**browser → Zig listener → Unix socket → Vite/SvelteKit**. Ctrl-C stops the
session and removes its socket. Use `zig build dev -- --port 5180` for another
port. The host binds loopback and reports readiness after the application renders.

Forward explicit upstream choices after `--`:

```sh
./zig-out/bin/zkit new empty-app -- --template minimal --types ts --no-add-ons
./zig-out/bin/zkit new examples-app -- --template demo --types jsdoc --add tailwindcss=plugins:none
```

Creation installs dependencies, checks Svelte/configured frontend tools, builds
the frontend and Zig host, and sets up upstream Vitest/Storybook. Existing
unit-only Vitest selections stay unit-only. A nonempty destination is refused;
without a terminal, omitted choices use minimal TypeScript.

In a generated application's root:

```sh
zig build install-web  # fresh clone: install the locked dependencies
zig build check
zig build              # frontend and Zig host
zig build dev
```

Generated apps declare a local z-kit source dependency in `build.zig.zon`.
Keep or update that path when moving/cloning an app; `--zkit-path PATH` selects
an explicit checkout at creation. Published distribution is later work.

For the repository example and framework checks:

```sh
vp install --frozen-lockfile
zig build dev
zig build test
vp run check
```

The maintained examples page is [here](example/src/routes/+page.svelte).
After changing it or the installer, run `vp run build:addon` to rebuild the
tracked [sv add-on bundle](tooling/sv/README.md).

[Application-creation evidence](ephemeral/proof/application-creation/README.md)
records fresh empty/examples builds, browser interaction/HMR, independent
reinstallation and lifecycle checks. This foundation uses Vite for rendering;
Zig remotes, loads, native reloads and standalone production serving remain
future [features](ephemeral/plans/first-application-spec.md). The
[internal projector](modules/projector/README.md) currently supplies projection
configuration. For its full diagnostic runner, see that module's README.
