# First development server

correction: The user explicitly rejected the Zig 0.17.0 release pin and requested the development build. The old pin came from AGENTS.md, the feature spec and build.zig, not from a toolchain requirement. Use installed Zig 0.18.0-dev.543+fa4f5b262, remove the exact-release guard, update current guidance, and retain old evidence as historical. The separately maintained token cache stays read-only; verify APIs against the installed compiler's source.

decision: First supported host is macOS. Use std.Io network streams and structured concurrency for an unchanged byte tunnel from the public loopback listener to Vite's Unix socket. Vite middleware mode and HMR share one Node HTTP server bound only to that socket. The Zig tooling process owns listener, Vite child, startup deadline and socket directory; there is no native application backend in this feature.

friction: SvelteKit 3.1 rejects svelte.config.js and the old generated-tsconfig path. Configure Kit in vite.config.js and extend $app/tsconfig; the installed package's source and diagnostics are current authority.

friction: Passing Vite a relative app root from the repository cwd produced generated Kit imports pointing one directory too high and HTTP 500. Resolve the app root and chdir there before creating Vite; the startup render correctly caught this before readiness.

friction: std.Io's reuse_address sets both SO_REUSEADDR and SO_REUSEPORT, allowing simultaneous sessions to share the port. Disable SO_REUSEPORT immediately after listening while retaining SO_REUSEADDR; the real occupied-port and immediate-restart demonstrations now pass.

friction: The inspected Threaded childWaitPosix defers process cleanup even on cancellation. Avoid a concurrent Child.wait/Child.kill ownership race: observe the child's stdout pipe for EOF, cancel/join that reader first, and let one session owner reap or kill the child.

proof: The real browser loaded the example through Zig, clicking changed the counter, and two source edits produced Vite client hot-update messages at the same public address. Svelte's component update reset the local counter; preserving component state was not claimed. The byte tunnel also preserves direct Vite behavior on early TCP half-close; it does not add HTTP interpretation to change that upstream behavior.

proof: Final development-host source passed zig build test and pnpm check. Repeated the application transport/lifecycle demonstration after the final listener/task-handling edits; all cases passed, including the actual 30-second deadline. lsof confirms that only Zig owns TCP 127.0.0.1:5173; the owned Vite child has no TCP listener and owns its Unix socket. The browser demonstration was repeated against this final host. The complete example remains running for inspection; all fault-injection sessions and the temporary Kit route were cleaned up.

proof: The full projector runner passed with the installed development compiler: 13 configuration tests, one module consumer, the explicit comptime compilation and all 11 intended compiler refusals. The old release-only guard is removed; minimum_zig_version is a lower bound at the tested development version, not an exact-version restriction. Fresh results preserve the original release evidence.

correction: The user requires the base application generator from the outset. `zkit new` must wrap upstream SvelteKit creation, offer empty/examples starters, and produce applications that build/start from fresh destinations. Remote/load features are incomplete until demonstrated in a newly generated examples app as well as the repository example; the empty starter must remain runnable. Project scaffolding and native binding generation are distinct responsibilities.

decision: The user explicitly preserves the existing server work as a valid commit/checkpoint: it is the current state, not sufficient reason to declare the full initial foundation done. Updated the feature specification, baseline, README and agent instructions accordingly. The user's subsequent "start" authorizes beginning the generator implementation after this specification checkpoint.

correction: The user rejected ba23bf2 because the instruction to work like skgo new required substantive reference work, not just invoking sv create and adding files. The rejected implementation invented a starter prompt, forced the upstream minimal template, bypassed SKGo's VitePlus-owned environment, and performed frontend decoration directly instead of through a native sv add-on. Reverted that commit as 346855f, preserving the server and specification checkpoints.

decision: The user's latest instruction supersedes the earlier implementation authorization: undo the generator, update the natural-language specification, and stop for a new session. Do not begin another implementation or create a coordinating chat.

proof: Inspected SKGo commit 618f467b93d5371ebdccfb7f6b59b24814a454f6, tracing cmd/skgo/templates.go, internal/newapp orchestration/environment/choice detection/completion and internal/sv/sv-addon.source.js. Executed the source CLI's new -h. The reference delegates questions and minimal/demo selection to upstream, detects choices from generated output, applies frontend integration with sv add, and separately owns native scaffolding and setup completion. No full SKGo application creation was executed; the next session must not claim that it was.

proof: After the revert, runtime/build/package source matches 2d1d736 exactly; rejected CLI sources and its installed binary are absent. The owned development session was stopped. zig build test and zig build install pass, 85 documentation links resolve, and whitespace checks pass. Remaining changes are the source-backed specification amendment, matching agent guidance and this worklog; no replacement implementation was begun.
