# z-kit Svelte CLI add-on

`zkit new` invokes this native add-on through `sv add` after upstream creation.
It owns frontend scripts, dependency alignment, demo conversion and Playwright's
Zig launcher. The Zig CLI owns orchestration and the application's Zig files.

The add-on structure, demo cleanup, test-version alignment and defensive
Playwright transform are adapted from SKGo commit
`618f467b93d5371ebdccfb7f6b59b24814a454f6`, under the included MIT license.
The Vite launcher separately uses SKGo's application-local Vite resolution.

The examples page has one maintained source at `example/src/routes/+page.svelte`.
After changing it or this add-on, rebuild the tracked installer bundle:

```sh
vp install --frozen-lockfile
vp run build:addon
```

`build.mjs` bundles sv-utils and the page text; `sv` remains the declared host
peer. The CLI packs the bundle and installs that peer in an isolated cache
stage so sv's shared extraction directory cannot overwrite the framework
checkout. This package is creation tooling, not an app runtime dependency.
