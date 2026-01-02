--- All the things strongly related to GMod go here
-- TODO: Rename the dummy panel?
-- TODO: investigate: this dummy panel is actually a valid viewport? Derma panels can be fake viewports?

local ImVec2 = include("imgui_h.lua").ImVec2

--- VGUIMousePressAllowed hook can only block mouse clicks to derma elements
-- and can't block mouse hovering
local GDummyPanel = GDummyPanel or nil

local function SetupDummyPanel()
    if IsValid(GDummyPanel) then
        GDummyPanel:Remove()
        GDummyPanel = nil
    end

    GDummyPanel = vgui.Create("EditablePanel")

    GDummyPanel:SetDrawOnTop(true)
    GDummyPanel:SetMouseInputEnabled(false)
    GDummyPanel:SetKeyboardInputEnabled(false)

    GDummyPanel:SetVisible(false)

    -- GDummyPanel.Paint = function(self, w, h) -- FIXME: block derma modal panels
        -- surface.SetDrawColor(0, 255, 0)
        -- surface.DrawOutlinedRect(0, 0, w, h, 4)
    -- end
end

local function AttachDummyPanel(pos, size)
    if not IsValid(GDummyPanel) then return end

    GDummyPanel:SetFocusTopLevel(true)
    GDummyPanel:SetPos(pos.x, pos.y)
    GDummyPanel:SetSize(size.x, size.y)
    GDummyPanel:SetVisible(true)
    GDummyPanel:MakePopup()
    GDummyPanel:SetKeyboardInputEnabled(false)
end

local function DetachDummyPanel()
    if not IsValid(GDummyPanel) then return end

    GDummyPanel:SetVisible(false)
end

local function SetMouseCursor(cursor_str)
    if not IsValid(GDummyPanel) then return end

    GDummyPanel:SetCursor(cursor_str)
end

local ImGui_ImplGMOD_Data = ImGui_ImplGMOD_Data or nil

local function ImGui_ImplGMOD_Init()
    ImGui_ImplGMOD_Data = {
        Window = nil,
        Time = 0
    }

    SetupDummyPanel()

    local main_viewport = ImGui.GetMainViewport()
    main_viewport.PlatformHandle = GDummyPanel
end

local function ImGui_ImplGMOD_Shutdown()
end

local function ImGui_ImplGMOD_UpdateMouseCursor(io, imgui_cursor)
    SetMouseCursor(imgui_cursor)
end

local function ImGui_ImplGMOD_NewFrame()
    local io = ImGui.GetIO()
    local bd = ImGui_ImplGMOD_Data

    io.DisplaySize = ImVec2(ScrW(), ScrH())

    local current_time = SysTime()
    io.DeltaTime = current_time - bd.Time
    bd.Time = current_time

    ImGui_ImplGMOD_UpdateMouseCursor(io, ImGui.GetMouseCursor())

    --- Our window isn't actually a window. It doesn't "exist"
    -- need to block input to other game ui like Derma panels
    if io.WantCaptureMouse then
        AttachDummyPanel({x = 0, y = 0}, io.DisplaySize)
    else
        DetachDummyPanel()
    end
end

--- TEMPORARY
local function ImGui_ImplGMOD_RenderDrawData(draw_data)
    local global_vtx_offset = 0
    local global_idx_offset = 0
    for _, draw_list in draw_data.CmdLists:iter() do
        for cmd_i = 1, draw_list.CmdBuffer.Size do
            local pcmd = draw_list.CmdBuffer.Data[cmd_i]

            if pcmd.ElemCount > 0 then
                local start_idx = pcmd.IdxOffset + global_idx_offset + 1
                local end_idx = start_idx + pcmd.ElemCount - 1

                for i = start_idx, end_idx - 2, 3 do
                    local idx1 = draw_list.IdxBuffer.Data[i]
                    local idx2 = draw_list.IdxBuffer.Data[i + 1]
                    local idx3 = draw_list.IdxBuffer.Data[i + 2]

                    local vtx_idx1 = idx1 + global_vtx_offset
                    local vtx_idx2 = idx2 + global_vtx_offset
                    local vtx_idx3 = idx3 + global_vtx_offset

                    local vtx1 = draw_list.VtxBuffer.Data[vtx_idx1]
                    local vtx2 = draw_list.VtxBuffer.Data[vtx_idx2]
                    local vtx3 = draw_list.VtxBuffer.Data[vtx_idx3]

                    local col = vtx1.col
                    surface.SetTexture(0) -- draw.NoTexture gives me invisible grips
                    surface.SetDrawColor(col.x * 255 + 0.5, col.y * 255 + 0.5, col.z * 255 + 0.5, col.w * 255 + 0.5) -- TODO: is this correct?
                    surface.DrawPoly({
                        {x = vtx1.pos.x, y = vtx1.pos.y},
                        {x = vtx2.pos.x, y = vtx2.pos.y},
                        {x = vtx3.pos.x, y = vtx3.pos.y}
                    })
                end
            end
        end

        global_idx_offset = global_idx_offset + draw_list.IdxBuffer.Size
        global_vtx_offset = global_vtx_offset + draw_list.VtxBuffer.Size
    end
end

return {
    Init           = ImGui_ImplGMOD_Init,
    Shutdown       = ImGui_ImplGMOD_Shutdown,
    NewFrame       = ImGui_ImplGMOD_NewFrame,
    RenderDrawData = ImGui_ImplGMOD_RenderDrawData
}