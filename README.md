# Zig Type Projector

Type Projector is a planned Zig library for projecting Zig types into schemas, codecs, and foreign-language declarations.

It will evolve independently of Go Polytype. Architecture, public APIs, and implementation milestones are still being planned.

This repository currently contains project documentation only. There is no implemented library, install procedure, or usage API yet.

Start with the [Zig → JavaScript mapping proposal](ephemeral/plans/mapping-contract.md): one closed admission contract for TypeScript and JavaScript with JSDoc, a [source-backed feature/test parity map](ephemeral/plans/feature-parity.md), and [acceptance through one public example](ephemeral/plans/example-acceptance.md). The proposal uses ordinary native optionals: `?T` defaults to an omittable key, and a per-field required override allows null while requiring key presence. API spelling remains open; no implementation or acceptance tests have run here.

The [JSON codec mechanism experiment](ephemeral/plans/codec-experiments.md) is deferred until the mapping and literal acceptance cases can hold both approaches to the same semantics.
