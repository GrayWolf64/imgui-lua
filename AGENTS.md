# AGENTS.md — Syncing with upstream dear imgui

Notes for LLM agents porting upstream C++ commits to this Lua port.

## Repos

- Lua port (this repo): `lua/` mirrors `imgui*.cpp/h` file-by-file (`imgui.cpp` → `imgui.lua`, `imgui_internal.h` → `imgui_internal.lua`, etc.)
- C++ fork used as sync source: `Documents/REPO/imgui` (has `upstream` remote = ocornut/imgui)
- Reference branch: `master` for core, **docking** for viewport-related code

## Sync workflow

1. `git log --oneline <last-synced>..<target>` in the C++ fork to list commits
2. Review each commit diff; skip backend/example/docs/CI-only commits and C++-only constructs (macros like IM_FMTARGS, static analysis annotations)
3. Port applicable changes to `lua/`
4. Stage only (`git add`) unless told to commit
5. Commit message format: header `Sync some changes until ocornut/imgui@<full-hash> (included)`, details only when asked
6. Fast-forward the C++ fork: `git merge --ff-only <target>`; user pushes

## Lua port rules

- **Numbers are doubles**: int-overflow/cast fixes are usually no-ops — note them as skipped
- **LuaJIT `bit.*` is 32-bit and wraps**: shifts >= 32 or negative need guards (example see `TREE_NODE_GET_DEPTH_MASK`)
- **`goto` cannot jump forward into scope of locals declared after it** — hoist declarations above loops (GMod LuaJIT rejects the file otherwise, killing everything the file defines)
- **1-based indexing**: `Data[i]` arrays, `(yi+1)%2` ≡ C++ `(yi^1)&1` parity tricks
- **Runtime-conditional C macros**: can port as zero-argument functions preserving exact upstream macro names if suitable
- **0 is truthy in Lua**: `and/or` chains are safe for numeric bit ops
- **Tables vs values**: use `ImVec2_Copy`/`ImRect_Copy` etc. where C++ assigns structs by value
- **Widget returns**: value widgets return `updated_value, changed`; e.g. `Checkbox()` returns `pressed, updated_value`
- **Pointer refs**: when pointer identity matters, represent C++ element pointers as 1-based indices (e.g. `item_ref = 1`, value `items[item_ref]`); translate `&item != item_ref` to `i ~= item_ref`
- **Raw scratch reinterpretation**: Lua cannot reinterpret typed `ImVector` storage as C++ does. Use one flat Lua-specific buffer mirroring upstream regions; do not add scratch wrapper classes, nested owner tables, or cached stack objects

## Style rules

- Files use CRLF line endings — preserve them
- Comments added during porting: no trailing `.`
- Drop `[OBSOLETE]` code/comments entirely — do not port obsolete fallbacks
- Keep `--- @field` annotations column-aligned within their block
- Drop upstream comments (FIXME, NB, issue refs) where the surrounding code is ported

## Environment

- No lua/luajit interpreter available — verify syntax by careful review (especially `goto` scope rules)
