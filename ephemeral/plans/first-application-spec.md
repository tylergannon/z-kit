# z-kit: first application and development loop

Status: **discussion draft**, October 25, 2026. This records the product map and proposes a first construction slice from the current conversation. It is not an implementation instruction or a claim that the requirements and architecture are settled. Open decisions below must be resolved at the relevant boundary before implementation proceeds through it.

This uses the nlspec skills' standard of explicit intent, behavioral claims and contracts. It is a toolchain-specific working specification, not a formal nlspec with an adopted cell decomposition or code budgets.

## What we are building

z-kit is the Zig successor to SKGo: a framework for building ordinary SvelteKit applications with native server-side application logic written in Zig. Application authors write Svelte components and native functions. z-kit connects those functions to Kit's application model and builds the resulting application into a native executable.

SvelteKit supplies frontend compilation, component rendering, browser navigation and the frontend's remote-function machinery. z-kit supplies the native side of the application, generated integration, an adapter for SvelteKit, and the tools that build and develop the combined application. Routing metadata comes from Kit; native dispatch must agree with it. The precise division of runtime work is a design question to make explicit as the slice takes shape.

The first slice should make a very small application work through that entire path, including a basic development server. It will help us develop the architecture through actual construction. Completing a projector or generator alone does not meet that goal.

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

The [broader bring-up baseline](z-kit-bringup.md) retains the existing feature inventory and milestone definitions. This smaller slice does not by itself satisfy that document's development-online, deployable or customer-ready milestones. In particular, the earlier browser checkpoint's query-plus-command, cookies/locals and navigation coverage must not silently become requirements of this smaller exercise.

## First application

The requested application has one simple page and one native remote function. A page server load is a proposed addition: the user said “maybe one load,” so it remains a scope decision rather than a settled requirement.

Proposed fixture: a read-only query accepts text and returns a small native record that the page displays. This exercises argument handling, a real projected result type and the call back into Zig. The page offers a way to make a browser-originated call, so initial rendering cannot conceal a broken client call path. If the load is selected, it returns a small piece of initial page data that is visible in server-rendered HTML and available after hydration. Fixture names and UI styling are implementation details; operation kind and admitted input/result shapes must be recorded before coding their integration.

The application uses ordinary SvelteKit source and configuration, generated integration, and Zig application code. It has a documented build entry point and development entry point. Their final command spelling and the native declaration syntax are still open.

In development, the developer visits one stable address owned by the z-kit development host. Vite performs development rendering and frontend HMR. Native calls execute in the Zig application. Changes to native function bodies and admitted data shapes reach that browser through watching, generation where needed, rebuild and replacement.

The application build produces a Zig executable containing the frontend build artifacts. Running it serves the page and executes its native operation without a Vite or Node server. Server rendering executes in the native application's selected embedded JS engine; the engine and its packaging are unresolved. “One executable” does not yet promise static linkage or the absence of system-library dependencies.

## Toolchains and construction path

Use **Zig 0.17.0** and the ordinary Zig build system. Use SvelteKit's actual build and Vite integration, with a z-kit adapter written for that environment. Pin the supported Kit/frontend combination before depending on its internal contracts; current inspected SKGo targets Kit 3.1.0, which is evidence for a candidate baseline, not a compatibility proof for z-kit.

The build has these dependencies:

1. Obtain Kit's route/module metadata and identify the selected native handler modules.
2. Produce any route/event declarations required to compile those modules.
3. Compile and run a host generator over native declarations. Derive types, bindings, native registration and shared operation metadata together.
4. Run the normal frontend build with the z-kit adapter consuming the generated integration.
5. Compile the native application with the completed frontend artifacts and matching native registrations/codecs.

Development reuses the same application declarations and generation meaning, while substituting Vite rendering for the embedded production renderer. Rendering mode is an explicit composition choice, independent of optimization mode.

This ordering must work from a clean example checkout. Reflecting a handler cannot require a declaration that only that same reflection could generate. The generator must not import the final application entry point if that entry point embeds frontend output that does not exist yet. Source imports, explicit discovery and tracked build steps are the starting mechanisms; generating files only as a build-configuration side effect is insufficient.

## Responsibilities and contracts

These are proposed responsibility boundaries, not a prescribed file tree or one process/package per row.

| Responsibility | Contract with the rest of the system |
| --- | --- |
| Application generation | Consume selected native declarations, Kit metadata and target settings. Produce a coherent set of frontend declarations/modules, native registration and identity metadata. Unsupported signatures fail with source-oriented diagnostics. A Kit-visible operation must identify the same native function and wire types on both sides. |
| Data projection | Derive the bounded wire mapping and codecs needed by the selected operation. Keep native associations required for reading/constructing values. Reuse the internal projector configuration and [mapping contract](../../modules/projector/ephemeral/plans/mapping-contract.md); implement only the admitted shapes selected for this slice. Routing, HTTP, Vite and renderer dependencies stay outside the projector. |
| z-kit adapter and Vite integration | Consume generated operation metadata and Kit's discovered modules/routes. In a build, produce assets, rendering code and metadata the native runtime can consume. In development, connect Kit's rendering and native callbacks and expose readiness/configuration to the development host. Reject incompatible or mismatched artifacts with an actionable diagnostic. Exact private formats remain to be designed. |
| Native application runtime | Execute the registered Zig operation, decode inputs and encode outputs according to the shared mapping, serve the built application, and expose the native callbacks required by the selected page/renderer. Failures must reach the caller through the selected Kit contract. Application code has the same meaning in development and compiled execution. |
| Development host | Own the public listener and the lifetimes of Vite, watching/generation and the native application. Route browser traffic to the appropriate participant, preserve Vite HMR, build replacements after edits, and publish only compatible ready participants. Report errors and recover after correction without requiring the developer to restart the whole session. |

There is one application-wide generation/publication owner. The existing [generation lifecycle](generation-lifecycle.md) governs owned outputs, unchanged bytes, fingerprints, conflict detection, check-only and recoverable publication; this draft does not replace those rules with a second pipeline.

Wire exchange must follow Kit's protocol and the existing mapping brief's devalue major-5 profile, pinned to 5.9.4. Reuse the shared Go/Zig devalue runtime as an independent dependency; the internal projector supplies the native typed mapping/codecs. Qualify the selected subset against real Kit traffic rather than inventing a parallel remote protocol.

Generated artifacts and native/frontend participants must describe compatible application revisions. A failed or superseded build cannot be announced as the active application. Compilation failure preserves the previous working native application when one exists; initial failure leaves application readiness false. Exact request waiting/failure policy during replacement is still open.

Every cross-runtime value or callback needs an explicit lifetime. Request-owned buffers remain valid until their consumers finish; retained renderer/build state owns its storage. Cancellation and shutdown finish or cancel dependent work before freeing it. The HTTP/I/O composition and concrete ownership API must settle these contracts before asynchronous work crosses them.

## Observable completion claims

These are proposed acceptance claims for the slice, not reports of passing tests. Local claims exercise a responsibility's contract; integration claims require the real example and actual toolchains.

| Claim | Evidence required |
| --- | --- |
| **G1 — Generated connection (local: generation/projection)** | From the selected native signature, produce the actual frontend binding/type and native registration/codec. A typed consumer accepts a valid call and rejects an invalid one. Literal wire fixtures establish the selected input/result mapping. |
| **G2 — Artifact agreement (local: adapter/runtime contract)** | Matching generated and frontend metadata is accepted. An intentionally mismatched operation or build identity is rejected with a useful explanation. |
| **G3 — Publication correctness (local: generation)** | The same example witnesses unchanged-byte stability, input invalidation, missing output, unchanged owned stale removal, authored/edited conflicts, check-only drift and interrupted/retried publication under the existing lifecycle design. |
| **G4 — Real compiled application (integration)** | Build the example from a clean checkout with documented prerequisites. Run its executable without Vite/Node running. A browser receives server-rendered page content, hydrates successfully and invokes the native remote through the generated binding. Record literal expected native results. |
| **G5 — Real development session (integration)** | The same app runs at the development host's stable address using Vite rendering and the Zig operation. A frontend edit arrives through HMR; a native body edit changes the result; a shape edit regenerates compatible integration and reaches the browser. |
| **G6 — Failure and recovery (integration)** | Introduce invalid native source, observe a source-oriented diagnostic, and verify the failed build does not replace a working application. Correct it and observe the new result in the open browser. Verify an obsolete build cannot publish over a later admitted revision. Browser presentation of diagnostics is an open detail. |
| **G7 — Resource lifetime (local and integration)** | Local lifetime/failure checks exercise the chosen ownership contract. Repeated calls and rebuild/replacement do not retain retired native hosts or request resources. Stopping the development session terminates owned children and releases its listener/watch resources. |
| **L1 — Page load, if selected (integration)** | The native page-load value appears in server-rendered HTML and the hydrated page, in both development and compiled execution. Kit invokes the registered native load through the generated integration. |

Preserve the root configuration tests and their separate compile-only proof. Those checks do not substitute for running this application. Record the exact revision, toolchain versions, platform and observable outputs with the eventual proof.

## Decisions to resolve together

These are known design questions, not permission to let an implementer silently choose incompatible public behavior.

| Decision | Why it matters / when it must be resolved |
| --- | --- |
| Initial development and execution platforms | Sets the HTTP/I/O, watcher, JS engine and distribution constraints. Resolve before platform-specific integration. |
| Small app contract | Select the remote kind and bounded input/result shapes; decide whether the single page load joins the slice. Resolve before authoring its API and acceptance fixtures. |
| Native authoring and discovery | How an application declares/exports an operation, which source modules are found, and how generated prerequisites are imported. Resolve before the first generator integration. |
| Kit/frontend pin and adapter surface | Select the supported versions and the contracts the z-kit adapter relies on. Resolve before generating modules against Kit. |
| HTTP/std.Io and ownership composition | Specify request/response lifetime, cancellation and engine callback ownership. Resolve before implementing the runtime bridge. |
| Embedded engine and packaging | Select using a real Kit rendering qualification. The existing baseline calls for async rendering, native fetch callbacks, first bytes before producer EOF, and abort/cleanup qualification before broad generation investment. The historical synchronous JSC probe does not meet this gate. |
| Development replacement behavior | Set readiness, in-flight request handling, diagnostic presentation and refresh behavior across generation and native restarts. Resolve before the development host publishes replacements. |

Construction order should follow those decisions and concrete integration evidence. This document does not assign a sprint, select an engine, or authorize framework implementation. Only specified behavior belongs to the eventual slice; the broad SKGo map is reference context.

## Evidence and provenance

Current z-kit base: `3c2dd52`. Implemented code is the configuration experiment under `modules/projector`; its mapper, codecs and framework are not materialized. Existing plans are design material, not runtime proof.

Inspected SKGo base: `618f467b93d5371ebdccfb7f6b59b24814a454f6`. Source entry points: [application structure](/Users/tyler/src/skgo/project-structure.md), [generator](/Users/tyler/src/skgo/internal/gen/gen.go), [generated Kit stubs](/Users/tyler/src/skgo/internal/gen/emit.go), [adapter](/Users/tyler/src/skgo/internal/adapter/skgo-adapter.js), [development session](/Users/tyler/src/skgo/internal/devserver/session.go), [public proxy](/Users/tyler/src/skgo/internal/devserver/router.go), [Vite lifecycle](/Users/tyler/src/skgo/internal/devserver/frontend.go), [native composition](/Users/tyler/src/skgo/example/server.go) and [developer commands](/Users/tyler/src/skgo/internal/commands/commands.go). No new SKGo execution proof was collected.

Consulted the read-only Zig cache's build, SKGo/supervisor, I/O, memory and Polytype routes and relevant leaves. Pinned original sources opened include [build configuration/cache semantics](/Users/tyler/zig-token-cache/official/source/zig-0.17.0/lib/std/Build.zig:75), [host generation and target consumption example](/Users/tyler/zig-token-cache/toolchain/examples/build-sdk/build.zig:1), [embedding generated bytes](/Users/tyler/zig-token-cache/toolchain/examples/build-sdk/root.zig:1), [explicit process I/O/allocators](/Users/tyler/zig-token-cache/official/source/zig-0.17.0/lib/std/process.zig:31) and [task cancellation/completion](/Users/tyler/zig-token-cache/official/source/zig-0.17.0/lib/std/Io.zig:1296). The cache pins Zig 0.17.0 source; these mechanisms do not establish z-kit compatibility or implementation. No compiler or runtime experiment was run for this draft.
