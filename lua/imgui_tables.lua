--- ImGui Sincerely WIP
-- (Tables and Columns Code)

--- @type ImGuiContext?
local GImGui

-- Sets local `GImGui` in this file(imgui_tables.lua).
-- This is currently only used in main code `ImGui.SetCurrentContext()`
--- @param ctx ImGuiContext?
function ImGui._SetCurrentContext_Tables(ctx)
    GImGui = ctx
end
