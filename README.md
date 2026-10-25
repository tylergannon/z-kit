# Zig Type Projector

Type Projector is a planned Zig library for projecting Zig types into schemas, codecs, and foreign-language declarations.

It will evolve independently of Go Polytype. Architecture, public APIs, and implementation milestones are still being planned.

This repository currently contains project documentation and isolated research experiments. There is no implemented library, install procedure, or usage API yet.

Start with the [Zig → JavaScript build brief](ephemeral/plans/mapping-contract.md): the mapping, native optional defaults, configuration example, and first implementation steps for both TypeScript and JavaScript/JSDoc. Supporting research and the larger example plan are optional references, not extra first-delivery gates.

The [typed configuration experiment](ephemeral/projection-shape-lab/README.md) demonstrates nested anonymous records, imported types and recursion with a pinned compiler. The [brief delta review](ephemeral/plans/mapping-delta-review.md) records the decisions folded into the brief from the larger proposal.

[Generation design](ephemeral/plans/generation-lifecycle.md) covers ownership, publication and cache decisions for the first generator. [Language projections](ephemeral/plans/language-projections.md) separates JavaScript-style wire keys from idiomatic Swift/Kotlin declarations; Kotlin data classes are deferred.

The [JSON codec mechanism experiment](ephemeral/plans/codec-experiments.md) is deferred until the mapping and literal acceptance cases can hold both approaches to the same semantics.

See the [OpenAI JSON Schema compatibility reference](docs/openai-json-schema.md) for current documented strict/non-strict behavior, supported idioms and Type Projector profile boundaries (checked 2026-10-25).
