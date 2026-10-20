# Lua port instructions

Applies to all files under `lua/`. Repository-wide workflow remains in root `AGENTS.md`. Backend work also follows `lua/backends/AGENTS.md`.

## Source mapping

Lua files mirror upstream Dear ImGui files where practical:

- `imgui.cpp` → `imgui.lua`
- `imgui_draw.cpp` → `imgui_draw.lua`
- `imgui_widgets.cpp` → `imgui_widgets.lua`
- `imgui_demo.cpp` → `imgui_demo.lua`
- `imgui_internal.h` → `imgui_internal.lua`
- public declarations and shared types → `imgui_h.lua`

Keep upstream helper/type names and control-flow shape unless Lua requires adaptation. Unsupported table demos remain explicit `-- TODO:` stubs rather than invented substitutes.

## Lua and LuaJIT semantics

- Lua numbers are doubles. Integer overflow, casts, and integer-width fixes are usually no-ops; note skipped upstream changes when relevant.
- LuaJIT `bit.*` is signed 32-bit and wraps. Guard negative shifts and shifts `>= 32` where C++ semantics differ.
- `0` is truthy. Audit C++ boolean/numeric conversions and ternary translations carefully.
- Do not use `a and nil or b` or similar chains when true branch may be `false` or `nil`; use explicit branches.
- Arrays and `ImVector.Data` are 1-based. Translate pointer arithmetic, parity tricks, and end conditions deliberately.
- `goto` cannot jump forward into scope of locals declared after it. Hoist locals when needed. Use labels such as `__CONTINUE__`, never `continue`.
- LuaJIT has a 200-local limit per function/chunk. Avoid unnecessary file-scope aliases and large local declarations.
- Runtime-conditional C macros may become zero-argument functions preserving exact upstream names. Keep callable helpers outside numeric enum tables.
- Scalar truncation should use `_Trunc()` where overloaded vector dispatch is unwanted.

## Values, references, and storage

- C++ struct assignment is by value. Use `ImVec2_Copy`, `ImRect_Copy`, `ImVec4_Copy`, or direct destination mutation where aliasing matters.
- Copy helpers mutate explicit destinations and return nothing.
- When C++ element-pointer identity matters, represent pointers as 1-based indices. Example: `item_ref = 1`, value `items[item_ref]`, and `&item != item_ref` → `i ~= item_ref`.
- `ImTextureRef` is a value type: equality compares `_TexData` and `_TexID`; assignments copy fields.
- Non-owning registries use weak references. `ImDrawListSharedData.DrawLists` is a weak-key set.
- Do not reinterpret typed `ImVector` storage as heterogeneous C++ scratch bytes.
- Raw scratch reinterpretation uses one flat Lua-specific buffer mirroring upstream regions. Do not add nested owner tables, scratch wrapper classes, or cached stack objects.
- Triangulator pointers become node indices and spans use private offsets into flat scratch storage.
- `ImDrawListSplitter._Channels` is untyped `ImVector()` storage. Lua swaps transfer ownership; do not preserve C++ alias-skipping logic that no longer applies.
- `ImSmallStack_(CAPACITY)` captures capacity at construction; do not turn it into a mutable object field.

## API behavior

- Value widgets return `updated_value, changed`. Follow each existing wrapper's established ordering; for example `Checkbox()` returns `pressed, updated_value`.
- Demo state should persist or reset according to upstream intent.
- Lua strings replace temporary C++ character buffers when equivalent. Display-only scalar formatting should consume strings directly.
- `ImBuf2Str()` uses chunked conversion; avoid unpacking huge buffers into one call.
- Drop `[OBSOLETE]` code and fallback paths entirely.

## Draw and math hot paths

- `ImVec2`/`ImVec4` storage is numeric-backed. Keep it that way; `{ x = ..., y = ... }` is slower in this workload.
- Numeric `[1]`/`[2]` indexing is appropriate in measured low-level math and rendering loops. Keep `.x`/`.y` in high-level code when readability matters.
- Direct `ImVector.Data` access is valid inside loops where buffers cannot reallocate during iteration.
- Prefer direct destination mutation or scalar streaming over temporary arenas and vector objects.
- `_ImVec2()` is one reusable temporary for proven synchronous value-copy operations. Never retain it and never use it twice in one argument list.
- Generic `ImArena` use is secondary; do not introduce arenas when direct writes are simpler.
- `bit.*` calls are LuaJIT-recognized builtins. Do not mechanically alias them project-wide; localize only in measured hot functions.
- Hybrid helpers such as `ImMin`/`ImMax` support numbers and vectors. In numeric-only measured loops, direct `math.min`/`math.max`, function-local aliases, or explicit scalar branches may avoid type dispatch. Profile before broad replacement.
- LuaJIT may hoist stable `math.*`/`bit.*` table and function guards, but not operations whose operands change each iteration.
- Preserve upstream tessellation and DrawList behavior. Avoid specialized widget-only renderers unless measured gain clearly justifies divergence.
- Allocation reduction and CPU reduction are separate claims; measure both.

## Style

- Preserve CRLF line endings; verify after edits.
- Comments added during ports have no trailing period.
- Keep comments sparse. Use concise `LUA:` comments only for necessary semantic divergence.
- Keep `--- @field` annotations aligned within their block.
- Drop upstream FIXME, NB, and issue-reference comments when surrounding code is ported unless comment remains essential locally.
- Preserve upstream naming even when Lua style would normally differ.

## Validation

- Syntax-check every changed Lua file with local LuaJIT when available:
  ```sh
  ~/Documents/REPO/LuaJIT/src/luajit -e 'assert(loadfile("path/to/file.lua"))'
  ```
- Review `goto` scope manually; one invalid jump can prevent entire file from loading in Garry's Mod.
- For DrawList changes, check vertex/index counts, command boundaries, channel split/switch/merge, clipping, and visual output.
- For performance changes, warm workload, collect repeated profiles, and compare exact parent/child frames. A single profile may reflect trace compilation or blacklisting rather than source-level regression.
