# z-kit: develop the application one useful feature at a time

Status: **progressive feature specification**, October 25, 2026. The development-server portion is implemented and [demonstrated on macOS](../proof/dev-server/README.md). The required base application generator, `zkit new`, is not implemented; complete it against that server before proceeding to native remotes. The initial foundation and preferred progression come from the user's current instructions. Further features will be selected progressively for their usefulness and value to the whole application.

## What we are building

z-kit is the Zig successor to SKGo: a framework for building ordinary SvelteKit applications with native server-side application logic written in Zig. Application authors write Svelte components and native functions. z-kit connects those functions to Kit's application model and eventually builds the application into a native executable.

Start with a developer creating a new application through `zkit new`, choosing an empty starter or one with examples, and running the resulting real SvelteKit application behind a Zig development server. Extend the examples as we add remote functions, page loads and backend reloads. Each increment must give the developer useful application behavior in both the repository example and a freshly generated application.

Use the **current Zig development build**, the Zig build system, and the actual SvelteKit/Vite toolchain. The specification describes features and the behavior that demonstrates them; supporting technical requirements belong under the feature they enable.

## Map of the SKGo terrain

This is a map of responsibilities and capabilities to consider for z-kit, not a promise to implement the whole table in this slice.

| Area | Existing SKGo capabilities to account for |
| --- | --- |
| Application APIs | Page/layout server loads; query, command, batch/live query, remote form and prerender operations; form actions and HTTP endpoints. |
| Routes and requests | Route discovery/matching, concrete parameter/event types, hooks, locals, cookies, headers, redirects, errors and request isolation. |
| Data integration | Native input/result types, validation, JS/TS declarations, codecs, presence/null rules, custom transports and deferred values. |
| Application generation | Discover native operations; derive signatures and wire roots; emit Kit-facing modules, native registration, route/event types and shared identity metadata. |
| Kit/Vite integration | Compile real generated modules, reconcile operation identities, produce client assets/rendering bundle/manifest, support build-time native execution and page options. |
| Native runtime | Dispatch operations and data requests, serve assets, render pages, implement request-aware fetch/streaming/cancellation, manage configuration and shutdown. |
| Development session | Stable browser-facing HTTP listener; Vite and native child processes; watching, generation, rebuild/publication, HMR/data refresh, errors and cleanup. |
| Developer utilities | Project creation, add-ons, dependency/toolchain updates, incremental builds, checks, diagnostic guidance, environment tools and developer MCP. |
| Additional consumers | Generated CLI/MCP clients, Swift/native application integration and related extension tooling. |

The [broader bring-up baseline](z-kit-bringup.md) retains the product's feature inventory and development-online, deployable and customer-ready milestones. Those milestones describe larger outcomes. Application creation and the development server below form the initial foundation.

## Required foundation: create a new application

The developer runs `zkit new <directory>` and chooses an empty application or an application with examples. z-kit wraps and decorates the real upstream SvelteKit application generator, following the approach of `skgo new`. Upstream owns ordinary SvelteKit scaffolding and its supported frontend choices; z-kit adds its own integration rather than reimplementing that generator.

### Observable behavior

- The empty starter creates a minimal runnable z-kit application without feature demonstrations. The examples starter creates a runnable application demonstrating the z-kit features implemented so far.
- From the generated application's own directory, the developer follows the documented dependency-installation, generation, build and development-start commands and opens a working SvelteKit page through the Zig listener. No manual source repairs or copying of pre-generated artifacts are needed.
- Both starter choices work when creation is repeated in fresh destinations. Neither relies on the repository example's installed dependencies, generated files, build outputs or working directory.
- As remote functions, page loads and subsequent features land, the generated examples starter includes working demonstrations of them. The empty starter continues to build and start through the same integration without requiring demo handlers.
- Upstream creation or z-kit setup failures identify the failing step; an incomplete setup is not reported as a usable application.

### Supporting technical requirements

Delegate frontend creation to the actual upstream SvelteKit generator and preserve supported user selections. Apply the z-kit additions afterward: Zig package/build configuration, framework dependencies, development-host/Vite integration, documented commands and the selected examples. Copying the repository's hand-assembled frontend as a substitute for invoking upstream creation does not satisfy this contract.

Upstream scaffolding and the z-kit additions have separate ownership. z-kit owns its integration and native examples; it must not maintain a parallel implementation of SvelteKit's project templates or frontend option handling. The empty/examples choice must also be available without an interactive terminal so fresh application creation can be repeated.

The repository example and generated examples starter use the same maintained example content and framework integration. Keep them aligned as features land. Project scaffolding is distinct from the application-wide generator that later derives bindings and native registrations from application declarations; having that binding generator does not satisfy `zkit new`.

A generated application must declare the framework/tooling dependencies it uses and run independently of the framework checkout's private paths. An explicit local z-kit dependency is acceptable during framework development; implicit sibling-file imports and dependence on the repository example's artifacts are not. Record the upstream and frontend versions used by the generated application in its normal dependency setup and lockfile.

The required build produces the artifacts needed for the currently selected development features. Production rendering and native executable packaging retain their later feature scope. The application generator ships with the initial foundation, before native remote or load features are accepted.

## First feature: trivial development server

The developer starts the example application, opens the Zig server's network address in a browser, and uses a working SvelteKit page. Vite serves the application over a Unix domain socket. The Zig server owns the public network listener and proxies browser traffic to that socket.

The same example content is the foundation for later features in both the repository example and freshly generated examples applications. Native remotes, page loads, backend rebuilds and an embedded production renderer become useful additions to an already running application.

### Observable behavior

- Starting the development application starts Vite with the SvelteKit application on a Unix domain socket and starts the Zig server on its documented network address.
- Opening that network address loads the real SvelteKit page, its assets and client JavaScript. The page hydrates and its client-side interactions work through the Zig proxy.
- Editing a Svelte component updates the open browser through Vite's normal frontend hot reload, using the same Zig address.
- Startup reports a usable address only once the application can answer. A failed startup explains the failure. Stopping the development session releases its listener, its owned Vite process and its socket so the application can be started again.
- These behaviors work in fresh applications created through both starter choices. The repository example alone does not complete the initial foundation.

### Supporting technical requirements

The traffic path is **browser → Zig network listener → HTTP over Unix domain socket → Vite/SvelteKit**. Vite's application listener uses the socket; the browser reaches the application through Zig.

The proxy carries HTTP methods, request paths and queries, bodies, response status and headers without changing application meaning. It supports the WebSocket upgrade and ongoing connection used by Vite HMR. URLs and HMR configuration refer the browser back to the Zig address.

Vite remains responsible for development rendering, module serving and frontend change detection. The Zig development host owns the public listener and the lifecycle of the Vite child. Socket paths, readiness, failure reporting and cleanup have one owner. Choose the first supported host platform and the Zig HTTP/std.Io composition before implementing this feature. The exact command spelling and private process communication are implementation choices unless they affect the developer-facing behavior described here.

The development host is tooling, independent of application-native handlers. This feature introduces no native application backend. z-kit owns the Vite launcher/integration that binds the socket; record the selected Kit/Vite versions in the example's dependencies and lockfile.

Use only the Vite integration needed for this feature. Native operation discovery, generated bindings and production adapter output acquire requirements when their corresponding features are selected.

## Preferred next feature: call a Zig remote function from the application

The developer writes a native function, imports its generated binding in the SvelteKit page and calls it from the browser. The page displays a result produced by Zig. This is the next useful connection to establish after application creation and the development server work.

### Observable behavior

- A browser interaction calls the native function through its generated frontend binding and displays the expected result in the same running application.
- The frontend binding describes the function's actual input and result types. Valid callers type-check; invalid callers receive useful type errors.
- Editing the selected native input/result shape and explicitly rebuilding/regenerating produces matching frontend and native behavior. Automatic backend rebuild is a later feature.
- A fresh `zkit new` application with examples builds and starts with this remote demonstration already wired up. Its browser interaction displays the actual Zig result without manual integration repairs. Demonstrate this alongside the repository example; the empty starter still builds and starts without the demo.

### Supporting technical requirements

Select the first remote kind and bounded input/result shapes when this feature is specified for implementation. A read-only query accepting text and returning a small record is a possible fixture, not a settled API.

Native declarations are the source for frontend bindings and native registrations. Define how declarations are authored and discovered, and generate any prerequisites before compiling handlers that import them. One application-wide generation owner produces compatible frontend modules, native registration and shared operation metadata. The z-kit adapter/Vite integration must give Kit real modules and connect Kit's operation identities to native dispatch.

Introduce application-native code in a backend process separate from the development host. The host sends browser remote requests to that backend; Vite's server-side calls reach the same native implementation. At this stage the developer explicitly regenerates, rebuilds and restarts the backend while the host and Vite remain running. Automatic rebuilding and replacement arrive with the later reload feature. Choose the private backend transport when implementing remotes.

Diagnose unsupported signatures. Build and run the generated binding and native implementation together to demonstrate agreement; a separate revision-coherence system is not required.

The internal projector supplies only the admitted mapping and typed codec support needed here, following the existing [mapping contract](../../modules/projector/ephemeral/plans/mapping-contract.md). It remains independent of routing, HTTP, Vite and rendering. Wire exchange follows Kit's protocol and the brief's devalue major-5 profile pinned to 5.9.4; reuse the shared Go/Zig devalue runtime as an independent dependency.

Use ordinary tracked build steps and Zig's caches to generate the selected operation's integration. Demonstrate that regeneration makes the edited operation work in the example. The earlier [generation lifecycle design](generation-lifecycle.md) is deferred reference material; ownership manifests, check-only, custom fingerprints and resumable publication are not requirements of this feature.

Pin the Kit/frontend versions used by this integration and define input/result ownership and failure behavior before implementing the bridge.

## Preferred following feature: load page data in Zig

The developer writes a native page load and uses its data in the SvelteKit page. The page receives actual Zig-produced data during development rendering and retains the expected data when the browser hydrates.

### Observable behavior

- Visiting the page produces server-rendered HTML containing the expected native load result.
- The hydrated page receives the same load data and its frontend code can use the generated data type.
- Changing the load's result and explicitly rebuilding/regenerating changes the displayed page data without hand-maintaining a parallel frontend declaration.
- A fresh `zkit new` application with examples builds and starts with the native page-load demonstration and previously added remote working together. Verify the native result in its server-rendered HTML and hydrated page as well as in the repository example; the empty starter remains runnable.

### Supporting technical requirements

Generate the Kit-facing server-load module and matching native registration from the selected native declaration. Use Kit's route/module metadata to associate the load with its page. Pass request-owned data and results across the Vite/native boundary with explicit lifetimes and cleanup.

Specify the first load's application-facing signature and request facilities when selecting this feature for implementation. The feature establishes page loads in the existing example; its requirements should follow that concrete behavior.

## Preferred subsequent feature: refresh the app after native code changes

The developer edits Zig application code and sees the new behavior in the open application without manually rebuilding or restarting the development session.

### Observable behavior

- A native function-body edit reaches the browser after an automatic rebuild and backend replacement, at the same public address.
- A supported native shape edit regenerates compatible bindings, rebuilds the backend and refreshes the affected browser data.
- Invalid native source produces a source-oriented diagnostic while preserving the previous working backend when one exists. Correcting the source makes the new behavior available without restarting the whole development session.

### Supporting technical requirements

Extend the existing development host to coordinate watching, generation, compilation, readiness and backend replacement. An obsolete build cannot replace a newer accepted application. Preserve Vite's frontend HMR connection across native replacements. Agree on the handling of in-flight requests, startup failure and browser refresh before implementing the replacement boundary. Stopping the session terminates the processes and watches it owns.

A rebuild-and-restart implementation can establish this behavior. In-process native code replacement or a retained compiler service needs its own demonstrated value before it becomes a requirement. A compiler success event is insufficient to announce application readiness; compatible generated/frontend artifacts and a running backend must agree.

## Later product feature: run the built application as a Zig executable

The developer builds the same application and runs the resulting Zig executable to serve its pages and execute native application logic without a Vite or Node server.

### Observable behavior

The built executable serves the application's assets and server-rendered page, the browser hydrates, and the remote and page load work for whichever application features have been selected by then. Demonstrate this with the real frontend build embedded in the executable and literal expected native results.

### Supporting technical requirements

The production z-kit adapter produces frontend assets, rendering code and metadata for the native application. The Zig build graph generates integration, runs the frontend build and compiles the executable with compatible artifacts, without a cycle in which the generator needs final embedded frontend output.

Select the initial execution platform, embedded JS engine and packaging when this feature is taken up. Engine qualification must exercise actual Kit rendering and the relevant async/native callback behavior; preserve the broader baseline's fetch streaming and abort/cleanup requirements. The historical synchronous JSC probe does not establish this behavior. One executable does not yet promise static linkage or the absence of system-library dependencies.

This feature's placement here does not fix its position after every preferred development feature. Select it when it provides the most value; its engine work is not a prerequisite for the trivial server, first remote or first page load.

## Choosing the next feature

Complete the initial foundation: `zkit new` wrapping upstream SvelteKit creation, both starter choices, and the trivial development server in freshly generated applications. The existing repository-only server demonstration leaves application creation outstanding. The current preferred progression after that foundation is remote functions, then page loads, then automatic native backend reloads. After each working feature, choose the next addition by its usefulness and value to the whole application. This is a direction for progressive decisions, not a fixed implementation schedule for every feature in the SKGo map.

Specify each selected feature's developer-visible behavior and put the necessary generated integration, adapter, codec, lifetime and build details underneath it. Use feature names when discussing work and evidence.

Resolve design questions when they become prerequisites for the selected feature. Production engine selection and full generation/publication behavior do not block the initial Vite proxy. Preserve the current configuration tests and compile-only proof as relevant regression checks; demonstrate new application features through the running example and actual toolchains.

## How features are demonstrated

Unit tests are good engineering hygiene. Proof comes from building and running the repository example and freshly generated applications, then demonstrating the expected feature behavior through the actual development server and browser.

For the initial foundation, invoke `zkit new` against the real upstream generator for each starter choice in a fresh destination, install its declared dependencies, run its documented build/start steps from that destination, and use the page through the Zig listener. Repeating creation in fresh destinations must reproduce the working result without retained application artifacts or manual edits to repair setup.

For each later selected feature, extend the shared examples content, create a fresh examples application, build it and demonstrate the feature there as well as in the repository example. In particular, a remote must display an actual Zig-produced result and a native page load must supply the demonstrated SSR and hydration data. Keep the empty starter runnable as the shared integration evolves. Feature completion includes this generated-application behavior; editing the checked-in example, compiling template files, or reusing an already prepared destination is insufficient.

Retain concise creation/build/start output and browser observations so a reviewer can follow the generated application's result. Use the ordinary application workflow; these requirements do not call for a separate acceptance framework or an exhaustive matrix of upstream add-ons.

Review and implementation must preserve the selected feature scope. They must not introduce correctness machinery, elaborate proof infrastructure or heavyweight testing. Supporting technical requirements serve the actual features; they do not authorize additional systems or acceptance projects.

## Evidence and provenance

Implemented-source baseline before these specification changes: `3c2dd52`. Implemented code is the configuration experiment under `modules/projector`; its mapper, codecs and framework are not materialized. Existing plans are design material, not runtime proof.

Inspected SKGo base: `618f467b93d5371ebdccfb7f6b59b24814a454f6`. Source entry points: [application structure](/Users/tyler/src/skgo/project-structure.md), [generator](/Users/tyler/src/skgo/internal/gen/gen.go), [generated Kit stubs](/Users/tyler/src/skgo/internal/gen/emit.go), [adapter](/Users/tyler/src/skgo/internal/adapter/skgo-adapter.js), [development session](/Users/tyler/src/skgo/internal/devserver/session.go), [public proxy](/Users/tyler/src/skgo/internal/devserver/router.go), [Vite lifecycle](/Users/tyler/src/skgo/internal/devserver/frontend.go), [native composition](/Users/tyler/src/skgo/example/server.go) and [developer commands](/Users/tyler/src/skgo/internal/commands/commands.go). No new SKGo execution proof was collected.

The application-creation amendment follows the user's explicit requirement to wrap upstream generation from the outset and prove features in new applications. Rechecked the same SKGo base's [upstream creation and integration orchestration](/Users/tyler/src/skgo/internal/newapp/newapp.go:142) and [setup completion](/Users/tyler/src/skgo/internal/newapp/newapp.go:265). These are source references for the wrapper approach, not new execution evidence or a requirement to port every SKGo option or workaround.

Consulted the read-only Zig cache's build, SKGo/supervisor, I/O, memory and Polytype routes and relevant leaves. Pinned original sources opened include [build configuration/cache semantics](/Users/tyler/zig-token-cache/official/source/zig-0.17.0/lib/std/Build.zig:75), [host generation and target consumption example](/Users/tyler/zig-token-cache/toolchain/examples/build-sdk/build.zig:1), [embedding generated bytes](/Users/tyler/zig-token-cache/toolchain/examples/build-sdk/root.zig:1), [explicit process I/O/allocators](/Users/tyler/zig-token-cache/official/source/zig-0.17.0/lib/std/process.zig:31) and [task cancellation/completion](/Users/tyler/zig-token-cache/official/source/zig-0.17.0/lib/std/Io.zig:1296). The cache pins Zig 0.17.0 source; these mechanisms do not establish z-kit compatibility or implementation. No compiler or runtime experiment was run for this draft.
