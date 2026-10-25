# z-kit

A Zig backend for SvelteKit, building on SKGo’s application model.

The [accepted build baseline](ephemeral/plans/z-kit-bringup.md) defines the features and milestones. The first product checkpoint is a browser app with a Zig server load, typed query and command, cookies/locals, SSR hydration, navigation and a working rebuild loop. Production rendering and packaging have a separate acceptance gate.

The [internal projector module](modules/projector/README.md) owns data configuration, mapping and codecs. z-kit will own one application-wide generator for routing, bindings and publication. The shared devalue runtime remains a separate dependency.

Current code proves typed projection configuration and its use at comptime; the framework, full mapper and codecs are not implemented yet. The [generation lifecycle](ephemeral/plans/generation-lifecycle.md) records the selected publication and cache rules.

Use **Zig 0.17.0**:

```sh
zig build test
```

This runs 14 configuration/module tests and a compile-only comptime proof. For the full experiment, including 11 expected compiler refusals, set `ZIG017_EXE` to that compiler and run:

```sh
python3 modules/projector/ephemeral/projection-shape-lab/run.py
```

Initial development/deployment targets, HTTP/std.Io composition, handler discovery and the production JS engine remain the next design decisions in the baseline.
