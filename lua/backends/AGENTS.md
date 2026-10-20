# Backend instructions

Applies under `lua/backends/`. Also follow root `AGENTS.md` and `lua/AGENTS.md`.

## Scope

- Keep platform, renderer, and engine-specific behavior inside its backend.
- Follow upstream backend structure and naming where host API permits.
- Do not leak backend constraints into core DrawList generation unless constraint is part of Dear ImGui semantics.
- Document host-specific limits near affected backend code or in a clearly scoped section below.

## Rendering invariants

Backend batching and submission must preserve:

- draw-command order and triangle order
- clip rectangle and scissor state
- texture and sampler changes
- user callback boundaries
- `IdxOffset` and `VtxOffset`
- render-state restoration after callbacks and errors

Use direct `draw_list.IdxBuffer.Data` and `draw_list.VtxBuffer.Data` in submission loops when buffers cannot reallocate during consumption.

## Garry's Mod backend

Garry's Mod dynamic `mesh.Begin()` expands each index into one submitted vertex and allows at most 32,768 vertices. Keep triangle batches aligned:

```lua
local MAX_MESH_ELEM_COUNT = 32766
```

Measured boundary:

- 10,922 triangles / 32,766 vertices: valid
- 10,923 triangles / 32,769 vertices: rejected

Oversized failure occurs at `mesh.Begin()` before vertex emission and may leave rendering/scissor state dirty when repeated hook errors abort frame.

`IMesh:BuildFromTriangles()` walks Lua tables and performs per-field decoding; it is suitable for retained geometry, not per-frame bulk upload. Garry's Mod exposes no Lua indexed or packed dynamic upload API, mapped buffer, partial update, draw range, or base-vertex path. Current immediate `mesh.Begin()` submission is best general pure-Lua path for changing geometry; materially faster generic submission requires native API support.

Do not add backend triangle-filtering heuristics. Measured pathological gains did not justify maintenance cost or workload dependence.

## Validation

- Test empty, small, and oversized command lists.
- Test multiple commands, textures, callbacks, clip rectangles, and nonzero offsets.
- Verify scissor and render state restoration after callbacks and failures.
- Compare emitted vertex/index counts and visual ordering against DrawList data.
- Test host-specific submission boundaries where applicable.
