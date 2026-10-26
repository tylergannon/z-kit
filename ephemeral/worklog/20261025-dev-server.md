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

proof: The specification amendment follows the user's direct correction. Checked the new creation/empty/examples/feature-proof requirements against the baseline and agent guidance, distinguished project scaffolding from binding generation, and verified 81 document links and whitespace. The existing server checkpoint remains valid; the amendment does not claim the generator was implemented by documentation alone.

decision: Implement zkit as a Zig CLI that delegates project creation to the real pinned sv CLI. A small embedded Node script performs frontend orchestration and z-kit additions; it reuses the checked-in example page. Generated Zig builds consume the declared z-kit source dependency's development-host artifact. The host embeds its launcher and resolves Vite from the generated application's package rather than the framework checkout.

friction: Zig development manifests require dependency paths relative to the generated build root; an absolute .path is rejected. Emit an explicit relative dependency path after resolving the created application's real directory. The failed creation retained its files and reported the build step, rather than announcing success.

proof: zkit new delegates to real sv 1.1.1. Fresh empty and examples applications installed, checked and built; JSDoc/Tailwind choices and layouts were preserved. Repeated creation covered TypeScript, no-types, a path containing a space, and the interactive starter plus upstream questions. Generated example pages match the maintained repository example; editing one produced browser HMR. The empty starter stayed upstream-minimal.

proof: Zig fetch produced a filtered source archive without node_modules or a prebuilt host. Invoking the CLI from /tmp with that extracted source as an explicit local dependency produced another fresh examples app that built, served and hydrated in the real browser. Each generated app resolved its own Vite installation. This is local development scaffolding proof, not registry distribution or native remote/load functionality.

proof: Six generated sessions returned HTTP 200; stopping them removed owned children/socket directories and released the public ports. The documented build/dev command restarted an examples app on the same port and stopped cleanly via SIGINT. Existing-destination, invalid-starter and invalid-upstream-option cases failed without a success announcement, preserving existing files. Root Zig checks and Svelte checking passed. Native remotes/loads remain future work with generated-application proof required.

proof: Final source formatting and diff checks pass; 107 local links across the current spec, baseline, README, agent instructions and generator evidence resolve. Temporary generated applications were removed after collecting evidence. Only the repository example's updated host remains running. No remote publication, registry installation, native handler feature or merge is claimed by this checkpoint.
