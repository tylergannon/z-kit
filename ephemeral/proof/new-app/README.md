# Fresh application generator demonstration

October 25, 2026, macOS arm64; Zig `0.18.0-dev.543+fa4f5b262`, Node `24.22.1`, pnpm `12.15.0`, upstream sv `1.1.1`. Applications resolved SvelteKit `3.1.0`, Vite `8.3.5` and Svelte `5.57.2` through their own dependency installation.

## Upstream creation, both starters and repeatability

The actual `zkit new` binary invoked `pnpm dlx sv@1.1.1 create ... --template minimal --no-install`, then added the Zig build and development command. The empty starter retained upstream's welcome page. The examples starter reused the exact maintained `example/src/routes/+page.svelte` content. Each creation installed dependencies and built the Zig host; configured Svelte checks passed before success was printed.

Successful fresh destinations and their retained creation logs:

- [Empty, TypeScript](empty-2-create.log)
- [Examples, JSDoc and Tailwind](examples-2-create.log)
- [Repeated empty, no type checking, path containing a space](repeated-empty-create.log)
- [Repeated examples using an independent source package](packaged-examples-create.log)
- [Final CLI, examples](final-examples-create.log)
- [Final CLI, empty with upstream no-types choice](final-empty-create.log)

Also exercised creation in a real terminal: selected examples in z-kit's prompt, then accepted upstream's TypeScript and no-add-ons choices. Upstream presented its own questions; z-kit completed installation, checking and host build. That interactive creation was additional to the logged noninteractive cases above.

[Preserved upstream Vite configuration](upstream-jsdoc-tailwind.config.js) shows that the JSDoc/Tailwind choice survived decoration, including Tailwind's plugin and the upstream layout stylesheet. [The generated Zig build](generated-build.zig) consumes the public development-host artifact from its declared z-kit dependency. [The no-types README](generated-no-types-readme.md) omits a check command when upstream did not configure one.

## Actual browser and development sessions

The empty application loaded upstream's welcome page through its Zig listener: [screenshot](empty.png), [browser state](empty-browser.txt).

The examples application loaded and hydrated, and clicking changed the counter: [screenshot](examples.png). Editing its own page produced a Vite hot update through that application's Zig address: [HMR screenshot](examples-hmr.png), [browser logs](examples-browser.json). The temporary text edit was restored; it was a hot-update demonstration, not a repair needed to start the application.

The final CLI created another fresh examples application, which was built and started without repairs. Its browser counter incremented: [final screenshot](final-examples.png), [browser observations](final-browser.json).

[Application records](applications.json) identify four simultaneous independent sessions, their declared framework paths, HTTP results and Vite module resolution inside each application's own node_modules. The final empty and examples creations were also started successfully. [Lifecycle results](lifecycle.json) record all six sessions returning HTTP 200, terminating their owned child and socket directory, and releasing their public port. The documented `zig build dev` command then [restarted the examples application on the same port](restart.log) and stopped cleanly with SIGINT.

## Independence from the framework checkout's frontend

Ran `zig fetch .` against the source package and retained its filtered [source archive](source-package.tar.gz), hash `z_kit-0.0.0-w0mPeCc3AQA0Q8dbAjwA_22L2qnqnooxECEU3HHDQf3w`. The archive contains framework source/build inputs and no node_modules or prebuilt host. Extracted it into a clean directory and passed that directory explicitly with `--zkit-path` while invoking the CLI from `/tmp`.

The resulting generated application installed its own dependencies, checked, built the host from that declared source package and served a working browser page: [screenshot](packaged-examples.png), [browser observations](packaged-browser.json). Its Vite resolution is recorded in applications.json. The host embeds the launcher and extracts it to its owned temporary directory; that launcher resolves Vite from the application's package, not from the framework source directory.

This qualifies local source-package consumption. A published registry/release installation is not claimed.

## Failures and required checks

[Failure results](failures.json) show nonzero exits without a creation-success message for an existing destination, an invalid starter, and an invalid upstream option. Existing destination files were unchanged. The case-specific logs are retained alongside that result.

`zig build test --summary all` passed all nine build steps, including both CLI/host compilations and the existing projector checks. `pnpm check` reported zero errors and warnings for the repository example. Node syntax checks passed for both embedded scripts. Fresh application creation ran its own build and any configured check; no generated source was manually patched to pass.

Reproduce from the repository root:

```sh
zig build install
./zig-out/bin/zkit new ../fresh-empty --template empty
./zig-out/bin/zkit new ../fresh-examples --template examples -- --types jsdoc --add tailwindcss=plugins:none
```

Then run `zig build dev` from either newly created application's directory, choosing a free port with `-- --port 5180`. The generated README describes subsequent installation/check/build steps. Test destinations must be new. Demonstration applications and injected source-package extraction were temporary and were removed after the captured results; logs, selected generated configuration and screenshots remain here.

Native remotes, native loads, backend reloads and native production packaging remain unimplemented. Their acceptance still requires working fresh generated examples as each feature lands. Evidence is local to this worktree and has not been uploaded to a remote artifact host.
