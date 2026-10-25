# OpenAI JSON Schema compatibility

Checked **2026-10-25** against current official documentation. This is a compatibility reference and Type Projector planning input, not an implemented backend or an API qualification result. No model request, credential use or runtime test was performed. Recheck the selected API/model before implementing a profile; moving documentation is not an immutable protocol specification.

## Strict mode and API surfaces

**Strict mode still exists.** Function tools use `strict: true` to constrain generated arguments to the admitted parameter schema. Unsupported strict schemas cause request errors. Each object must forbid additional properties and list every property as required; a null alternative supplies an optional-like value while the key remains required. Function results are a separate boundary. [Function-calling guide, strict mode](https://developers.openai.com/api/docs/guides/function-calling#strict-mode).

| Surface | Schema location | Contract |
| --- | --- | --- |
| Responses structured output | `text.format`, `type: "json_schema"`, `schema`, `strict: true` | Schema-constrained response content |
| Chat Completions structured output | `response_format.json_schema`, `schema`, `strict: true` | Same purpose, different request envelope |
| Function tool | tool `parameters` plus tool `strict` (Chat Completions nests these under `function`) | Generated call arguments; not the tool's return value |

These envelopes are documented in the [Responses migration guide](https://developers.openai.com/api/docs/guides/migrate-to-responses#6-update-structured-outputs-definitions) and [function definitions](https://developers.openai.com/api/docs/guides/function-calling#defining-functions).

| Selection | Acceptance / conformance boundary |
| --- | --- |
| Explicit `strict: true` | Requires the documented subset; enables strict conformance, subject to response completion/refusal handling |
| Explicit `strict: false` for function calls | Best-effort arguments; no strict conformance guarantee |
| Function `strict` omitted | Responses attempts normalization, then may fall back with resolved `strict: false`; Chat Completions defaults non-strict |
| JSON mode (`json_object`) | JSON syntax guarantee, not schema adherence |

Defaults above concern function tools, not an inferred default for every output format. Set the intended mode explicitly. [Function strictness](https://developers.openai.com/api/docs/guides/function-calling#strict-mode), [API defaults](https://developers.openai.com/api/docs/guides/migrate-to-responses#5-update-function-definitions-and-outputs), [JSON mode](https://developers.openai.com/api/docs/guides/structured-outputs#structured-outputs-vs-json-mode).

Non-strict does **not** establish full JSON Schema acceptance or enforcement. The checked guides do not specify an exhaustive non-strict keyword vocabulary. Distinguish request acceptance, documented keyword support and guaranteed generated-value conformance; success in one does not prove the others. Unknown/unlisted features remain unqualified for our profile.

## Documented strict idioms

The following compact matrix summarizes the [Structured Outputs supported subset](https://developers.openai.com/api/docs/guides/structured-outputs#supported-schemas). “Supported” describes documentation, not execution here.

| Feature | Documented status |
| --- | --- |
| Primitives/containers | string, number, integer, boolean, object, array; enums |
| Root | object; no root anyOf |
| Alternatives | nested anyOf; every branch must satisfy subset |
| References | $defs/$ref; root and explicit-definition recursion |
| Strings | pattern; format: date-time, time, date, duration, email, hostname, ipv4, ipv6, uuid |
| Numbers | minimum, maximum, exclusiveMinimum, exclusiveMaximum, multipleOf |
| Arrays | items; minItems/maxItems |
| Excluded composition | allOf, not, dependentRequired, dependentSchemas, if/then/else |
| oneOf / other unlisted idioms | No positive allowance established here; refuse pending evidence |

The guide's [size limits](https://developers.openai.com/api/docs/guides/structured-outputs#objects-have-limitations-on-nesting-depth-and-size): 5,000 properties total; depth 10; 120,000 characters across property/definition names and enum/const values; 1,000 enum values total; over 250 string members in one enum triggers a 15,000-character aggregate limit.

Fine-tuned models have additional [exclusions](https://developers.openai.com/api/docs/guides/structured-outputs#some-type-specific-keywords-are-not-yet-supported): minLength/maxLength/pattern/format, minimum/maximum/multipleOf, patternProperties, minItems/maxItems. The guide also broadly cautions that its additional property constraints are unavailable for fine-tuned models; do not infer unmentioned fine-tuned allowances.

Evidence nuance: [migration examples](https://developers.openai.com/api/docs/guides/migrate-to-responses#6-update-structured-outputs-definitions) use minLength in a strict output schema, while the principal supported-string list names pattern/format. Treat minLength as illustrated rather than an exhaustive allow-list guarantee; maxLength lacks equivalent positive evidence in the inspected material. Do not infer standard support merely from a fine-tuned exclusion.

Model availability is a separate qualification dimension. Pin the eventual API/model and standard-versus-fine-tuned profile. The [function guide](https://developers.openai.com/api/docs/guides/function-calling#parallel-function-calling) additionally warns that multiple function calls in one turn disable strictness for fine-tuned models. Applications must handle refusals/incomplete responses separately from successful typed values; strictness is not a promise that every request returns a complete application object. [Refusal handling](https://developers.openai.com/api/docs/guides/structured-outputs#refusals).

## Consequences for Type Projector

Our [mapping contract](../ephemeral/plans/mapping-contract.md) remains authoritative for native values: plain T is required/non-null; native ?T is omittable by default; a per-field `.required = true` override requires the key and allows null. An own undefined property differs from absence and is refused in the proposed profile. Type-owned comptime configuration governs codecs, TS and JSDoc together.

Chosen mandatory projection: every unsigned native Zig integer emits `type: "integer"` with explicit `minimum: 0`. Future schema acceptance must check both keywords and reject negative input. If the selected profile cannot express the bound, report/refuse that capability rather than discard unsignedness. Other precision/upper-bound proposals are unchanged; no wider numeric design is selected here.

Strict OpenAI's required-key convention conflicts with the default omittable category. The future profile must explicitly admit a compatible configuration, refuse the incompatible field with a useful path, or propose a separately authorized adaptation. It must not silently translate missing into null, mutate shared metadata, or change the native/JS contract merely to obtain API acceptance. Profile adaptation is unresolved; this reference selects no adapter.

Array bounds are a **planned supported capability**, not blanket-deferred. Preserve native `[N]T` length; the proposed standard-profile encoding is `minItems: N` and `maxItems: N`. A future schema acceptance case must validate N elements and reject N−1/N+1 (use 1 as the wrong length for N=0), and reject/report unsupported fine-tuned profiles rather than drop bounds. Native fixed-array decoding must independently enforce exact length before claiming support. A slice has runtime length; no exact bound may be invented for it.

The selected modern general JSON Schema dialect remains **post-initial-release** work, distinct from this API-specific profile. Go Polytype's OpenAI-driven restrictions are historical context supplied by the user, not a permanent universal API limit. Neither schema backend, a broad constraint framework nor an ArrayList serializer is implemented or authorized by this reference. The first example may use slices without removing fixed-array semantics from the planned mapping.
