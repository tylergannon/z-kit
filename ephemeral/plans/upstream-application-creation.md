# Implement `zkit new` from the working SKGo creation flow

Status: implemented, October 25, 2026; see [fresh-application proof](../proof/application-creation/README.md). The source comparison below records the implementation plan and its reference work. The [feature specification](first-application-spec.md#required-foundation-create-a-new-application) controls scope.

## The feature we are building

A developer runs `zkit new myapp`, answers the real Svelte CLI's questions, then runs a working z-kit application from `myapp/`. Upstream minimal produces the empty starter. Upstream demo becomes the z-kit examples starter. Both use an ordinary SvelteKit frontend in `web/`, with the Zig build and development commands at the application root.

The examples page demonstrates the current feature: SvelteKit rendering, browser hydration, the counter and frontend HMR through the Zig listener. It does not pretend to execute a Zig remote. The shared examples acquire native remotes, loads and reload behavior when those features are implemented later.

This completes the outstanding initial foundation. It does not implement native declarations, projection, wire codecs, native dispatch, backend replacement or a production renderer.

## What SKGo actually does

Inspected checkout: `618f467b93d5371ebdccfb7f6b59b24814a454f6`, unchanged by this research. The [live-reference record](../proof/new-app/README.md) includes successful full minimal and demo creation runs, plus interactive prompt/cancellation observations.

| Responsibility | Actual source and behavior | z-kit treatment |
| --- | --- | --- |
| Command contract | [CLI](/Users/tyler/src/skgo/cmd/skgo/templates.go:151): wrapper flags precede the destination; arguments after `--` belong to `sv create`. Interactive means a terminal on stdin/stdout and no CI. Top-level `--template` selects a separate plugin recipe. | Port argument ownership and terminal detection into Zig. Do not add a starter question or port the separate plugin-recipe feature. |
| Frontend environment | [qualifiedRunner](/Users/tyler/src/skgo/internal/newapp/environment.go:18): resolve/check VitePlus, resolve and verify its managed pnpm, and run every child in that environment. [createFrontend](/Users/tyler/src/skgo/internal/newapp/newapp.go:246) supplies temporary root package-manager metadata because `vp create` otherwise selects its own companion. | Port these semantics. Target **VitePlus 1.4.0**, not SKGo's historical 1.3.0 requirement. Keep an explicit managed pnpm pin and bootstrap metadata. |
| Upstream creation | [Create](/Users/tyler/src/skgo/internal/newapp/newapp.go:144): `vp create svelte@VERSION ... -- web SV_OPTIONS`; the developer answers sv's own questions. | Port the command sequence. Keep minimal/demo, TypeScript/JSDoc, optional add-ons and upstream configuration. |
| Unattended defaults | [svCreateArgs](/Users/tyler/src/skgo/internal/newapp/newapp.go:358): default only omitted choices to minimal, TypeScript and no optional add-ons. Defaults precede variadic `--add`. Refuse alternate target/install/template forms incompatible with the application layout. | Port parsing/defaulting behavior and relevant refusals. Never force minimal when demo was selected. |
| Read-back | [inspectChoices](/Users/tyler/src/skgo/internal/newapp/newapp.go:431): inspect emitted package/files to detect demo, existing Vitest and Storybook rather than trying to capture prompt answers. | Port detection. Interpret restrictions for this current Vite-served feature instead of copying Go-specific refusals blindly. |
| Default development tools | [Create/finish](/Users/tyler/src/skgo/internal/newapp/newapp.go:202): add unit/component Vitest only if absent; install Storybook through its native installer only if absent; install Chromium only for a selected component-browser setup. | Preserve this behavior. Existing unit-only Vitest stays unit-only. An empty z-kit starter has no z-kit feature demo, while retaining upstream test/story fixtures. |
| Frontend decoration | [native add-on](/Users/tyler/src/skgo/internal/sv/sv-addon.source.js:231): real `sv add` runs the framework add-on after the developer's add-ons; `sv.file`, transforms and `svelteConfig.edit` own frontend changes. | **Reuse the JavaScript add-on structure and applicable transforms directly**, with z-kit names and integration. Do not rewrite these operations in the Zig CLI. |
| Demo replacement | [demo conversion](/Users/tyler/src/skgo/internal/sv/sv-addon.source.js:352): remove stock demo routes/assets/dependencies, retain compatible layout/style additions, and install framework examples. | Port the conversion, sourcing the page from the maintained repository example. Preserve Tailwind and other compatible additions. Do not copy SKGo's Go-remote page. |
| Tool version alignment | [add-on](/Users/tyler/src/skgo/internal/sv/sv-addon.source.js:247): align Vitest packages with installed VitePlus; handle its JS fixture typing; record necessary workspace build/peer policies. | Reuse the applicable logic, reading VitePlus **1.4.0** metadata. Qualify Storybook with this version before carrying an old peer exception forward. |
| Checkout add-on use | [stageAddon](/Users/tyler/src/skgo/internal/newapp/newapp.go:533): pack and isolate a local add-on rather than letting sv link its mutable shared extraction directory into the source checkout. | Port this protection and keep the stage usable for sv's subsequent shared-store operations. Bundle build-only sv-utils; the add-on is not an application runtime dependency. |
| Native scaffold | [writeGoFiles](/Users/tyler/src/skgo/internal/newapp/newapp.go:940), [templates](/Users/tyler/src/skgo/internal/newapp/gofiles/README.md.tmpl): root native package, framework/tool dependency, build commands, examples and instructions. | Replace Go-specific files with a Zig package/build and explicit z-kit source dependency. No dummy native handler or fake binding generator. |
| Setup completion | [finish](/Users/tyler/src/skgo/internal/newapp/newapp.go:265), [verification](/Users/tyler/src/skgo/internal/newapp/newapp.go:499): verify add-on effects, install declared dependencies, initialize native files/bindings, check and build before printing success. | Preserve the completion boundary. Verify actual frontend edits/tools, build the Zig host and frontend, and fail at the named stage. Native binding generation is absent until remotes exist. |
| Public application tools | [Playwright repair](/Users/tyler/src/skgo/internal/sv/sv-addon.source.js:101), [preview rewrite](/Users/tyler/src/skgo/internal/newapp/newapp.go:808): point tools at the real native server instead of a second Kit server. | Adapt selected Playwright/dev/preview entry points to the Zig public address and root development command. This slice's preview uses development; do not promise standalone production serving. Keep these frontend edits in the add-on. |
| Vite process | [dev-host.js](/Users/tyler/src/skgo/internal/adapter/skgo-adapter/dev-host.js:1): resolve Vite from the **application's** package, use middleware/upgrade handling on a private socket, and close it on termination. | Reuse the applicable launcher code. Fix the repository launcher's current framework-relative Vite resolution before relying on it in generated apps. Retain the existing Zig listener/session owner. |

### Deliberate differences from SKGo

- Native generation, Go tooling and Go package files become Zig-specific orchestration/build files. The native application backend starts with the remote feature, so this slice has no Go-equivalent handler registry to generate.
- SKGo's adapter, generated throwing remote stubs, Goja output, embedded assets and standalone `just serve` are production/native integration. They are deferred, not emulated with placeholders. Ordinary Kit/Vite builds remain useful and required now.
- SKGo's Kit 3.1.0 queue correction enables its declared native prerender-input integration. This feature introduces no native prerender execution, so it does not port that patch. An ordinary upstream Kit 3.1.0 demo already builds on VitePlus 1.4.0 without it.
- Go-version pinning, native loader/hot replacement and rejection of all JavaScript server code do not describe the current z-kit Vite-serving capability. Preserve supported upstream additions; fail specifically if an addition cannot work with the selected topology. Do not silently claim native Zig support for its server code.
- Upstream ai-tools currently writes inside `web/`, as SKGo's explicit refusal explains. Refuse that selection with a root-location explanation for this slice; do not silently configure agents in the wrong directory or add a new agent installer.

## Toolchain and cache authority

The user requested latest VitePlus. Global `vp` is updated and verified at **1.4.0**; generated projects and the repository example will use that same exact project version and its Vite catalog. Keep managed pnpm **12.14.0**, already exercised with VitePlus 1.4.0, and sv **1.1.1**, the current release resolved during research. The first generated applications will record exact selected framework/frontend dependencies and their lockfile. Installed VitePlus 1.4.0 still supplies Vitest 5.0.5; compatibility of the complete default tools remains an implementation qualification task.

Use the installed Zig development build, currently `0.18.0-dev.543+fa4f5b262`. Consult the read-only [token-cache entrypoint](/Users/tyler/zig-token-cache/index/README.md) throughout the work, following route → leaf → cited original source:

- [Build route](/Users/tyler/zig-token-cache/index/routes/build/README.md) → [package contracts](/Users/tyler/zig-token-cache/index/leaves/build/package.md), [build graph](/Users/tyler/zig-token-cache/index/leaves/build/system.md) → [local dependencies](/Users/tyler/zig-token-cache/official/source/zig-0.17.0/doc/build.zig.zon.md:95), [host/build example](/Users/tyler/zig-token-cache/toolchain/examples/build-sdk/build.zig:1).
- [I/O route](/Users/tyler/zig-token-cache/index/routes/io/README.md) → [process/ownership leaf](/Users/tyler/zig-token-cache/index/leaves/stdlib/io.md) → [explicit process context](/Users/tyler/zig-token-cache/official/source/zig-0.17.0/lib/std/process.zig:31), [child cleanup](/Users/tyler/zig-token-cache/official/source/zig-0.17.0/lib/std/process/Child.zig:127).
- [SKGo route](/Users/tyler/zig-token-cache/index/routes/skgo/README.md) → [Kit obligations](/Users/tyler/zig-token-cache/index/leaves/branch/requirements.md), [supervisor](/Users/tyler/zig-token-cache/index/leaves/toolchain/supervisor-bsp.md) → [original Kit seam](/Users/tyler/zig-token-cache/branch/snapshot/ephemeral/zig-analysis/ssr-seam/README.md:9), [actual session owner](/Users/tyler/zig-token-cache/supervisor/skgo-baseline/internal/devserver/session.go:1).

The cache is historical 0.17 material. Check APIs against the installed compiler's `zig env` std source. This session verified current `process` spawn/replace ownership and `Build.Dependency.path`, Run file arguments and working-directory APIs. No cache proposal overrides the selected feature, and no BSP/watch/engine project is needed here.

## Implementation order

### 1. Make the existing host consumable by an application

Expose the host artifact through the framework's ordinary Zig dependency build. Generated applications declare their z-kit dependency in `build.zig.zon`; an explicit local source path is supported during development. Build-file references to the launcher come from that declared dependency, not a sibling checkout or copied build artifact.

Change the Vite launcher to resolve the generated application's installed Vite as SKGo does. Let the root build supply its application directory and framework launcher path explicitly. Carry stdin/stdout/stderr, working directory, public port and process cleanup through the existing session owner. Migrate the repository example to project-local VitePlus 1.4.0 and keep it working before adding CLI creation.

### 2. Port creation orchestration into the Zig CLI

Add the `zkit` executable and `new` command. Proposed source ownership is `src/cli.zig` for argument handling, `src/new.zig` for creation stages and native scaffolding, and a small frontend-environment helper for the qualified runner. Keep actual add-on transformations in JavaScript.

Validate destination/name/options before subprocess work. Accept a nonexistent or existing empty destination and refuse a nonempty one. Resolve VitePlus 1.4.0 and its managed pnpm; preserve the companion environment for every child. Create temporary root package-manager metadata, delegate to upstream, then remove that temporary metadata on success or failure. Forward user options after `--`, applying only omitted noninteractive defaults. Preserve terminal streams for interactive upstream prompts.

Read the resulting frontend to choose empty/examples and detect existing tools. Add only missing default Vitest/Storybook setup through the same upstream paths as SKGo. Name failures by stage and preserve diagnostics. Cancellation or a zero-exit upstream command that wrote nothing must not produce a created-application message.

### 3. Apply the native sv add-on

Add a bundled native add-on under `tooling/sv/`, using the reference's JS APIs and transforms. Pack/stage the development add-on, then invoke real `sv add` with explicit options after user add-ons. Verify its actual scripts/configuration/example effects after it returns.

The add-on owns frontend package changes, tool version alignment, root-backed launch commands, Playwright configuration and demo conversion. Maintain one examples page source shared with the repository. Preserve TypeScript versus JSDoc and compatible layout/style/plugin changes. Remove obsolete stock demo routes, references and demo-only dependencies without erasing selected tooling.

### 4. Finish a usable root application

Write the Zig package/build, root ignore rules and short generated README. Proposed root commands are:

```sh
zig build install-web  # fresh clone: qualified VitePlus, frozen frontend lockfile
zig build check        # Svelte and configured frontend checks
zig build              # frontend build plus Zig development-host build
zig build dev          # browser -> Zig -> Unix socket -> app-local Vite
```

Pass runtime options through the existing dev interface, including `zig build dev -- --port 5180`. Keep the build/development process anchored at the app root. Explain that a local z-kit dependency must exist at its declared path; never imply a publicly distributed package already exists.

Creation itself performs the necessary dependency installation, upstream formatting/check repair, Svelte/configured frontend checks, frontend build and Zig host build before reporting success. Install Chromium when required by component tests. Verify declared tools actually installed. Do not add an empty generation command: no native bindings exist yet.

### 5. Demonstrate the complete foundation

Use the real `zkit new` command repeatedly in fresh destinations, not hand-built template fixtures:

1. Minimal TypeScript with no optional add-ons; repeat using an existing empty destination. Build/start from each root and load the real page through Zig.
2. Demo JavaScript with Tailwind and unit-only Vitest. Confirm demo-to-z-kit conversion, retained styles/tools and no forced component/browser test setup. Build/start and click the shared counter through Zig.
3. Repeat examples creation in another fresh destination. Demonstrate hydration and an actual source edit reaching the browser through HMR at the same Zig address. Keep the repository example working with the same maintained page/integration.
4. Remove install/build outputs from a generated app and follow its documented fresh-clone commands. This catches reliance on framework node_modules, pre-generated files and private checkout-relative imports.
5. Exercise one interactive run, cancellation, nonempty destination, an upstream failure and an add-on that applied nothing. Show readable failure with no false success. Stop/restart the session and confirm public port, Vite child and socket cleanup.

Run root `zig build test` for Zig changes. Add only focused tests for argument/default ownership, choice detection and false-success cases; reuse the relevant reference cases instead of building a separate acceptance framework. Run the selected frontend tools to qualify their integration. Save concise command/build/start output and browser observations under `ephemeral/proof/`.

## Completion boundary

Done means the repository example and repeatedly generated empty/examples applications build and run through the Zig listener, with browser hydration, examples interaction, frontend HMR and cleanup demonstrated. Successful template compilation or a single repository page is insufficient. The default tools and supported upstream choices must survive creation on VitePlus 1.4.0.

After that foundation is demonstrated, specify the first native remote using the real SKGo remote/generator/adapter paths and the relevant cache routes. Remote signatures, discovery and backend transport are decisions for that feature, not silently selected by this scaffold plan.
