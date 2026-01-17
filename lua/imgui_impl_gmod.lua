--- All the things strongly related to GMod go here
-- TODO: Rename the dummy panel?
-- TODO: investigate: this dummy panel is actually a valid viewport? Derma panels can be fake viewports?

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
    local io = ImGui.GetIO()

    ImGui_ImplGMOD_Data = {
        Window = nil,
        Time = 0
    }

    SetupDummyPanel()

    local main_viewport = ImGui.GetMainViewport()
    main_viewport.PlatformHandle = GDummyPanel

    io.BackendFlags = bit.bor(io.BackendFlags, ImGuiBackendFlags.RendererHasTextures)
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

local function ImGui_ImplGMOD_RenderDrawData(draw_data)
    local global_idx_offset = 0
    local global_vtx_offset = 0
    for _, draw_list in draw_data.CmdLists:iter() do
        for _, pcmd in draw_list.CmdBuffer:iter() do
            if pcmd.ElemCount > 0 then
                for i = 0, pcmd.ElemCount - 1, 3 do
                    local idx0 = draw_list.IdxBuffer.Data[global_idx_offset + pcmd.IdxOffset + 1 + i]
                    local idx1 = draw_list.IdxBuffer.Data[global_idx_offset + pcmd.IdxOffset + 2 + i]
                    local idx2 = draw_list.IdxBuffer.Data[global_idx_offset + pcmd.IdxOffset + 3 + i]

                    print("pcmd TexRef:", pcmd:GetTexID())
                    -- FIXME: 
                    if not idx0 then print("idx 0 == nil!") continue end

                    local vtx0 = draw_list.VtxBuffer.Data[global_vtx_offset + idx0]
                    local vtx1 = draw_list.VtxBuffer.Data[global_vtx_offset + idx1]
                    local vtx2 = draw_list.VtxBuffer.Data[global_vtx_offset + idx2]

                    local col = vtx0.col
                    surface.SetTexture(0)
                    surface.SetDrawColor(col.x * 255, col.y * 255, col.z * 255, col.w * 255)
                    surface.DrawPoly({
                        {x = vtx0.pos.x, y = vtx0.pos.y},
                        {x = vtx1.pos.x, y = vtx1.pos.y},
                        {x = vtx2.pos.x, y = vtx2.pos.y}
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