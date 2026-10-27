# Application-creation reference work

October 25, 2026. Evidence for the [implementation plan](../../plans/upstream-application-creation.md), not evidence that `zkit new` exists.

## Sources and versions

- SKGo checkout: `/Users/tyler/src/skgo`, clean at `618f467b93d5371ebdccfb7f6b59b24814a454f6` before and after the runs.
- Zig: `0.18.0-dev.543+fa4f5b262`; reference cache: historical 0.17.0, consulted through its index and cited originals.
- Node: 24.22.1. sv: 1.1.1. Managed pnpm for the qualified runs: 12.14.0.
- Unmodified SKGo requires VitePlus 1.3.0. Its historical CLI was acquired from the official npm platform package and selected only for reference commands.
- Global VitePlus was updated from 0.3.3 to **1.4.0** and verified after the reference runs. [Official release](https://github.com/voidzero-dev/vite-plus/releases/tag/v1.4.0), [managed-environment documentation](https://viteplus.dev/guide/env), [upstream creation documentation](https://viteplus.dev/guide/create). The reference version is not the proposed z-kit pin.

## Full SKGo creation

Ran from the source checkout, with the 1.3.0 platform binary's directory prepended to PATH. Used the documented checkout overrides rather than modifying SKGo to accept another toolchain or substituting fake upstream processes:

```sh
go run ./cmd/skgo new \
  --sv-addon file:/Users/tyler/src/skgo/internal/sv \
  --adapter file:/Users/tyler/src/skgo/internal/adapter \
  --skgo-replace /Users/tyler/src/skgo \
  --skgo-version v0.45.1 DESTINATION -- SV_OPTIONS
```

| Fresh destination | Upstream options | Result |
| --- | --- | --- |
| `skgo-minimal` | `--template minimal --types ts --no-add-ons` | Exit 0; [complete output](skgo-minimal.log). Added Vitest unit/component setup, Chromium and Storybook, applied/verified the Kit correction, generated native files and completed the initial frontend build before printing success. |
| `skgo-demo` | `--template demo --types jsdoc --add tailwindcss=plugins:none vitest=usages:unit` | Exit 0; [complete output](skgo-demo.log). Detected examples, preserved selected unit-only testing and Tailwind, installed missing Storybook and completed the initial frontend build. No component-browser installation was requested. |

Inspected generated package/config/layout/style files after completion. Both used the VitePlus 1.3.0 catalog, Kit 3.1.0 and Vitest 5.0.5. `skgo-demo` had no stock Sverdle page, used the native remote example page, retained `@import "tailwindcss"` in `layout.css`, and retained that stylesheet import in the reduced layout. Both replaced frontend preview with `cd .. && just serve` and removed the misleading standalone frontend dev script.

These are successful creation/build demonstrations. No SKGo app server or browser was launched; browser/runtime parity is not claimed.

## Interactive ownership and cancellation

Ran the same source CLI in a PTY with `-- --types ts --no-add-ons`, leaving the template unset. VitePlus printed:

```text
Running: pnpm dlx sv@1.1.1 create web --types ts --no-add-ons --no-install
Welcome to the Svelte CLI! (v1.1.1)
Which template would you like?
  SvelteKit minimal
  SvelteKit demo
  Svelte library
  sv community add-on
```

Sent Ctrl-C at that upstream prompt. sv reported cancellation; SKGo then refused the missing emitted `web/package.json` and exited 1. It printed no created-application success. This confirms ownership of the actual template question; it does not qualify every interactive add-on combination.

The real upstream [create help](sv-create-help.log) and [add help](sv-add-help.log) were also captured through managed pnpm. Wrapper help flags require separators at each forwarding layer so the intended tool, rather than an outer `vp` parser, receives them.

## Latest VitePlus creation/build

Created a separate fresh ordinary upstream demo using **VitePlus 1.4.0**, with a root bootstrap `package.json` declaring `pnpm@12.14.0` and companion environment variables:

```sh
VP_PACKAGE_MANAGER=pnpm@12.14.0 VP_PNPM_VERSION=12.14.0 \
vp env exec --package-manager pnpm@12.14.0 -- \
  vp create svelte@1.1.1 --no-interactive --no-git --no-agent \
  --no-editor --no-hooks --approve-builds --package-manager pnpm -- \
  web --template demo --types jsdoc --add tailwindcss=plugins:none
```

Creation exited 0; [output](upstream-1.4-demo.log) confirms Node 24.22.1 and pnpm 12.14.0. The emitted workspace catalog selected VitePlus and its Vite core at **1.4.0**. Installed Kit was **3.1.0**. The project preserved upstream `lazyPlugins`, `enhancedImages`, Tailwind and SvelteKit plugin configuration.

Ran `vp env exec --package-manager pnpm@12.14.0 -- vp build` from its `web/`; exit 0, [output](upstream-1.4-demo-build.log). The standard adapter-auto production-environment warning remained. This proves ordinary upstream creation/build with the new toolchain; it does not qualify the proposed z-kit add-on or the complete Storybook/Vitest setup on 1.4.0.

An earlier throwaway invocation had the wrong bootstrap working directory and therefore selected pnpm 12.15.0. It is excluded from the qualified result. The successful run above used another fresh destination, not a repaired app.

Generated research applications, their installed dependencies and task-local acquisition tools were removed after collecting the outputs. Logs remain; no generated application or dependency tree is committed as framework source.
