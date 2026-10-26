# Upstream application creation

decision: The user's new-session "let's get going" resumes the required `zkit new` foundation from the accepted feature specification. Native remotes, loads and reloads remain outside this task.

decision: Traced SKGo's command handling, qualified environment, upstream choice detection, sv add-on, setup completion and creation behavior tests at 618f467b93d5371ebdccfb7f6b59b24814a454f6. Upstream owns prompts and minimal/demo selection. The framework add-on owns frontend decoration; the CLI owns orchestration and native scaffolding.

decision: Use the reference's VitePlus 1.3.0 only to execute unmodified SKGo. The z-kit plan targets latest VitePlus 1.4.0, managed pnpm 12.14.0 and sv 1.1.1. The user's explicit instruction is to update VitePlus, not reproduce SKGo's older tool pin.

friction: The active VitePlus is 0.3.3 and the old reference worklog's ~/.local/share/vite-plus/1.3.0 path does not exist on this host. Acquire task-local qualification tools under ephemeral/tools without switching the user's global tools.

correction: The user requires knowing the feature and inspecting upstream SKGo before planning z-kit, and explicitly requested a plan before implementation. The initial intention to omit SKGo's default Vitest/Storybook setup was premature. The plan now preserves that useful creation behavior and explicitly defers only native/runtime features absent from this foundation. No generator implementation was started.

proof: Updated global VitePlus from 0.3.3 to latest 1.4.0 and verified it. The historical 1.3.0 CLI binary auto-installed itself on first use and temporarily changed the global current link; restored 1.4.0 using the supported upgrade command and reverified after all reference runs. The old binary remains only for unmodified SKGo qualification.

proof: Full unmodified SKGo creation succeeded for minimal TypeScript/no optional add-ons and demo JavaScript/Tailwind/unit-only Vitest. Both reached initial frontend build completion. Interactive SKGo displayed sv's own template chooser, and cancellation exited nonzero without a success message. Local add-on and adapter qualification used explicit supported overrides; source checkout stayed clean.

friction: An initial VitePlus 1.4 research command used the wrong working directory for bootstrap package.json and created a throwaway unpinned scaffold with pnpm 12.15.0. A separate fresh destination with the proper root packageManager declaration and companion environment created and built successfully with 12.14.0. Keep SKGo's temporary bootstrap declaration: an outer managed environment alone does not pin vp create's package-manager selection.

proof: Read cache entrypoint, build/I/O/SKGo routes, package/build/I/O/Kit-contract/supervisor leaves and cited original sources. Reconciled historical Zig 0.17 sources with installed Zig 0.18.0-dev.543+fa4f5b262. Current work is planning and live upstream qualification, not z-kit runtime proof.

decision: SKGo's Vite launcher resolves Vite from the application's package.json; z-kit's current launcher imports it from the framework checkout. Make that explicit application dependency work before claiming generated applications run independently. Reuse the small upstream JS launcher mechanism rather than introducing another runtime owner.

proof: Saved a concrete implementation plan with source-linked reuse/port/defer decisions and explicit application completion gates. All 68 local links in the affected plan/spec/reference documents resolve. No Zig/runtime source changed, so validation is focused document/link checking; future Zig implementation still requires root zig build test and real generated-app browser proof. Removed task-owned generated research apps/dependencies and acquisition tools after retaining concise evidence.
