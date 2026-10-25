# First application specification

correction: The user rejected framing z-kit as a settled architecture or partially completed framework. Existing projection code is experimental evidence; requirements and construction order remain under discussion. Begin with what the product does and the overall SKGo feature terrain before component design artifacts.

decision: The user proposed a very small SvelteKit app compiled into a Zig executable, with one remote function and possibly one page load. Include a basic browser-facing development host coordinating Vite, watching, generation and native rebuilds. This makes adapter, generated integration, native runtime and development workflow part of the same architectural exercise.

correction: Specify the included behavior instead of maintaining an exhaustive out-of-scope catalog. The full SKGo inventory supplies context, not authorization to implement extra features. “Maybe one load” is unresolved and must not become a firm requirement by repetition.

decision: The user requested a specification informed by the natural-language spec skills' level of requirements/contracts, explicitly grounded in Zig and SvelteKit toolchains and without requiring formal nlspec format. Read spec-writing and spec-authoring; use intent, observable claims, responsibility contracts and explicit open decisions. Do not invent code budgets or a final cell decomposition.

decision: Keep this collaborative spec discussion and authoring in the requesting chat. Use a task worktree for repository edits. Draft under ephemeral/plans; preserve the broader accepted baseline and generation lifecycle. No framework implementation is authorized by this drafting request.

decision: Consulted the required read-only Zig cache routes/leaves and pinned original build/process/I/O/allocator sources, plus current SKGo generator, adapter, native composition and development-session code. Leave platform selection, HTTP/I/O composition, native declaration/discovery and renderer selection open. Current SKGo Kit pin is a candidate reference, not a selected z-kit compatibility promise.

proof: Reviewed the discussion draft for consistent scope, behavior-to-claim coverage, responsibility boundaries and explicit unresolved decisions. It deliberately does not claim formal nlspec spanning, finalized cells/budgets or implementation readiness. The existing generation lifecycle and broader milestone baseline remain separate references; the optional load and proposed read-only query are labeled accurately.

proof: All 17 local document/source links resolve; acceptance identifiers are unique and Markdown fences balance. Diff whitespace checks pass. This task adds only a draft specification and this worklog, so no Zig or SKGo runtime tests were rerun. Preserve the draft on its local task branch for user review; no push, PR, merge or framework implementation.

correction: The user rejects coded claim labels because agents discuss identifiers instead of meaningful feature names. Observable claims must describe actual developer-facing features; technical requirements belong underneath the features they support. Reorganized the draft around named features and removed its separate technical-claim catalog.

decision: The first feature is the trivial development server: a real SvelteKit app served by Vite on a Unix domain socket, reached through a Zig network listener/proxy. Extend that same app progressively. Remote functions, then page loads, then backend reloads are the preferred near-term direction, with each next feature chosen for usefulness and project-wide value. The previous bundled first slice and optional-load framing are superseded by this progression.

doc_bug: The broader baseline required all production/platform/discovery choices before any implementation. That would block the newly selected trivial dev server on unrelated decisions. Clarified its first-increment link and scoped prerequisites to their relevant features while preserving the larger product milestones.

proof: Reviewed feature ordering and each feature's observable behavior against the user's correction. All coded claim labels are absent from the specification, and supporting technical sections sit beneath their corresponding features. All 66 local links across the two plans resolve, fences balance and diff whitespace checks pass. Documentation changes only; no application implementation or runtime test execution.

decision: The user requested consensus review from Claude Opus. Review must preserve scope and must not introduce correctness machinery, elaborate proof infrastructure or heavyweight testing. Unit tests are hygiene; proof is building the real example and demonstrating its feature claims. Added this authority directly to the specification before independent review.

proof: Launched /adversarial-review through agent with the explicit opus model flag. The Claude transcript reports claude-opus-5-5. Retained reviewer session 1e05dde4-152e-4ac1-841d-199006cb77da and round-01 artifact under ephemeral/reviews/.

decision: Round 01 found three material ambiguities in the specification and its authorities. Accepted the conflicts around first-generator publication machinery and early engine qualification; the latest user direction supersedes those older assignments. Marked the lifecycle design deferred and aligned the baseline, mapper/example references and README. Clarified that the development host remains tooling, with a separate application backend introduced with remotes; manual backend rebuild/restart precedes automatic reloads. No native backend is added to the trivial proxy feature. Also clarified first-feature launcher ownership/version recording and the implemented-source baseline label. These are document changes only.

proof: Resumed the same Claude Opus session with the minimal full-target re-review prompt. Round 02 outcome is "only nitpicks remain": no critical or material issues, all round-01 findings resolved. Stopped the consensus loop per the skill. Remaining minor notes concern superseded wording in secondary references and deciding backend launch ownership when selecting the remote feature; neither adds a current acceptance gate.

proof: All 88 local links in the seven changed documents resolve; Markdown fences balance, coded claim labels remain absent from the feature spec, and diff whitespace checks pass. No runtime code, tests, correctness/proof infrastructure or implementation scope was added. Unit tests were not rerun for these documentation edits; no application feature is claimed implemented or demonstrated. The review artifacts and session/request logs remain under ephemeral/reviews/.
