# First application specification

correction: The user rejected framing z-kit as a settled architecture or partially completed framework. Existing projection code is experimental evidence; requirements and construction order remain under discussion. Begin with what the product does and the overall SKGo feature terrain before component design artifacts.

decision: The user proposed a very small SvelteKit app compiled into a Zig executable, with one remote function and possibly one page load. Include a basic browser-facing development host coordinating Vite, watching, generation and native rebuilds. This makes adapter, generated integration, native runtime and development workflow part of the same architectural exercise.

correction: Specify the included behavior instead of maintaining an exhaustive out-of-scope catalog. The full SKGo inventory supplies context, not authorization to implement extra features. “Maybe one load” is unresolved and must not become a firm requirement by repetition.

decision: The user requested a specification informed by the natural-language spec skills' level of requirements/contracts, explicitly grounded in Zig and SvelteKit toolchains and without requiring formal nlspec format. Read spec-writing and spec-authoring; use intent, observable claims, responsibility contracts and explicit open decisions. Do not invent code budgets or a final cell decomposition.

decision: Keep this collaborative spec discussion and authoring in the requesting chat. Use a task worktree for repository edits. Draft under ephemeral/plans; preserve the broader accepted baseline and generation lifecycle. No framework implementation is authorized by this drafting request.

decision: Consulted the required read-only Zig cache routes/leaves and pinned original build/process/I/O/allocator sources, plus current SKGo generator, adapter, native composition and development-session code. Leave platform selection, HTTP/I/O composition, native declaration/discovery and renderer selection open. Current SKGo Kit pin is a candidate reference, not a selected z-kit compatibility promise.

proof: Reviewed the discussion draft for consistent scope, behavior-to-claim coverage, responsibility boundaries and explicit unresolved decisions. It deliberately does not claim formal nlspec spanning, finalized cells/budgets or implementation readiness. The existing generation lifecycle and broader milestone baseline remain separate references; the optional load and proposed read-only query are labeled accurately.

proof: All 17 local document/source links resolve; acceptance identifiers are unique and Markdown fences balance. Diff whitespace checks pass. This task adds only a draft specification and this worklog, so no Zig or SKGo runtime tests were rerun. Preserve the draft on its local task branch for user review; no push, PR, merge or framework implementation.
