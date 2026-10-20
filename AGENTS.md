# Project instructions

Instructions in this file apply repository-wide. Read nested `AGENTS.md` files before changing files below their directories; nested files add or override local guidance.

## Project map

- `lua/` contains Lua port of Dear ImGui. Read `lua/AGENTS.md` before changing it.
- `lua/backends/` contains platform/render backends. Read `lua/backends/AGENTS.md` too.
- `lua/autorun/` contains Garry's Mod loading, tests, and temporary profiling workloads.
- C++ sync source is `~/Documents/REPO/imgui`, with `upstream` pointing to `ocornut/imgui`.
- Use C++ `master` for core changes and official `docking` for viewport-related changes.

## Upstream sync workflow

1. In C++ checkout, run `git log --oneline <last-synced>..<target>` and review every commit and diff.
2. Skip backend/example/docs/CI-only commits and C++-only annotations or macros when they have no Lua-visible effect.
3. Port applicable behavior into corresponding files under `lua/`.
4. Preserve upstream names, structure, ordering, and behavior unless Lua or Garry's Mod requires adaptation.
5. Record meaningful Lua-specific divergence using the `LUA:` convention in `lua/AGENTS.md`, and report unnecessary structural divergence.
6. Stage changed project files. Do not commit, push, rewrite history, or fast-forward C++ checkout unless user explicitly asks.
7. If asked to commit a sync, use header `Sync some changes until ocornut/imgui@<full-hash> (included)`; add details only when requested.
8. If asked to advance C++ fork, use `git merge --ff-only <target>`; user handles pushes unless explicitly delegated.

## Git and change discipline

- Preserve unrelated user changes. Never reset, discard, or overwrite them.
- Stage only intended project files. Keep temporary benchmarks and generated profiler workloads unstaged.
- Exact upstream enum renames should not retain compatibility aliases unless requested.
- Do not activate upstream `#if 0` or disabled experiments.
- Preserve known upstream oddities unless Lua correctness requires a documented adaptation.
- Use `--force-with-lease`, never plain `--force`, if user explicitly asks to push rewritten `sync` history.

## Validation

- Run `git diff --check` and inspect staged diff before reporting completion.
- Garry's Mod behavior still needs runtime validation for rendering, input, callbacks, and engine API limits.
- Use deterministic workloads and compare like-for-like profiles; profiling procedure is in `lua/AGENTS.md`.

## Profiling and experiments

- Supported in-game profiling uses `gm_jit_profile` and `gmcl_lj_flamegraph`.
- IDA Pro 9.1 is available for headless native-code analysis at `~/.ida-pro-9.1/idat`. Use it to inspect Garry's Mod engine bindings when Lua-visible behavior cannot explain a limit; keep analysis scripts and generated reports outside repository, normally under `/tmp`.
- Reverse engineering is for understanding exposed behavior and performance, not modifying game binaries or bypassing security controls.
- Garry's Mod intentionally disables `jit.attach`, `jit.util`, `jit.dump`, and related introspection APIs. Do not binary-patch or bypass those controls.
- Flamegraphs identify CPU costs; constructor counters and GC deltas identify allocation costs. Use both.
- Optimize measured hotspots, not syntax volume. Re-run equivalent workloads and separate inclusive attribution from exclusive work.
- Remove temporary stress tests from `lua/autorun/imgui_test.lua` when profiling ends.
