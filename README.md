# z-kit

A Zig backend for SvelteKit, building on SKGo’s application model.

Start with the [feature specification](ephemeral/plans/first-application-spec.md): a real SvelteKit app running in Vite on a Unix domain socket, reached through a Zig network listener/proxy. Extend the same app progressively, with remotes, page loads and backend reloads as the current preferred direction. The [build baseline](ephemeral/plans/z-kit-bringup.md) records larger product milestones, including production rendering and packaging.

The [internal projector module](modules/projector/README.md) owns data configuration, mapping and codecs. z-kit will own one application-wide generator for routing, bindings and publication. The shared devalue runtime remains a separate dependency.

Current code proves typed projection configuration and its use at comptime; the framework, full mapper and codecs are not implemented yet. The earlier [generation lifecycle design](ephemeral/plans/generation-lifecycle.md) is deferred reference material.

Use **Zig 0.17.0**:

```sh
zig build test
```

This runs 14 configuration/module tests and a compile-only comptime proof. For the full experiment, including 11 expected compiler refusals, set `ZIG017_EXE` to that compiler and run:

```sh
python3 modules/projector/ephemeral/projection-shape-lab/run.py
```

Choose the initial development platform and HTTP/std.Io composition for the first feature. Resolve native handler discovery and production rendering when their features are selected. Unit tests are hygiene; proof is building the example and demonstrating its feature claims.
