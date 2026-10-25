# Zig Type Projector

This checkout contains type-mapping research and verified Zig experiments for the planned Zig version of SKGo, provisionally called **z-kit**.

The product goal is a usable z-kit application. The [bring-up inventory and placement comparison](ephemeral/plans/z-kit-bringup.md) recommends an internal projector module and one app-wide generator; repository placement is still a recommendation, and no repository has been moved or renamed.

This repository currently contains project documentation and isolated research experiments. There is no implemented library, install procedure, or usage API yet.

The [Zig → JavaScript build brief](ephemeral/plans/mapping-contract.md) defines the mapping component, native optional defaults, configuration shape, and TypeScript/JavaScript outputs. Its standalone example is component proof; z-kit bring-up requires the framework integration described above.

The [typed configuration experiment](ephemeral/projection-shape-lab/README.md) demonstrates nested anonymous records, imported types and recursion with a pinned compiler. The [brief delta review](ephemeral/plans/mapping-delta-review.md) records the decisions folded into the brief from the larger proposal.

[Generation design](ephemeral/plans/generation-lifecycle.md) covers ownership, publication and cache decisions for the first generator. [Language projections](ephemeral/plans/language-projections.md) separates JavaScript-style wire keys from idiomatic Swift/Kotlin declarations; Kotlin data classes are deferred.

The [JSON codec mechanism experiment](ephemeral/plans/codec-experiments.md) is deferred until the mapping and literal acceptance cases can hold both approaches to the same semantics.

See the [OpenAI JSON Schema compatibility reference](docs/openai-json-schema.md) for current documented strict/non-strict behavior, supported idioms and Type Projector profile boundaries (checked 2026-10-25).
