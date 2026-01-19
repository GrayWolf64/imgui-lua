--- All the things strongly related to GMod go here
-- TODO: Rename the dummy panel?
-- TODO: investigate: this dummy panel is actually a valid viewport? Derma panels can be fake viewports?
-- TODO: currently the renderer and platform are in the same backend structure, separate them

local ImGui_ImplGMOD_DestroyTexture
local ImGui_ImplGMOD_UpdateTexture

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

--- @class ImGui_ImplGMOD_Texture

--- @return ImGui_ImplGMOD_Texture
--- @nodiscard
local function ImGui_ImplGMOD_Texture()
    return {
        RenderTarget     = nil,
        RenderTargetName = nil,
        Handle           = nil,
        Material         = nil,

        Width  = nil,
        Height = nil
    }
end

--- @class ImGui_ImplGMOD_Data

--- @return ImGui_ImplGMOD_Data
--- @nodiscard
local function ImGui_ImplGMOD_Data()
    return {
        TextureRegistry      = {},
        CurrentTextureHandle = 1,
        NumFramesInFlight    = 2,

        Time            = 0
    }
end

local function ImGui_ImplGMOD_GetBackendData()
    return ImGui.GetCurrentContext() and ImGui.GetIO().BackendPlatformUserData or nil
end

local function ImGui_ImplGMOD_Init()
    local io = ImGui.GetIO()

    local bd = ImGui_ImplGMOD_Data()
    io.BackendPlatformUserData = bd

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
    local bd = ImGui_ImplGMOD_GetBackendData()

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
    local bd = ImGui_ImplGMOD_GetBackendData()

    if (draw_data.DisplaySize.x <= 0.0 or draw_data.DisplaySize.y <= 0.0) then
        return
    end

    if (draw_data.Textures ~= nil) then
        for _, tex in draw_data.Textures:iter() do
            if (tex.Status ~= ImTextureStatus.OK) then
                ImGui_ImplGMOD_UpdateTexture(tex)
            end
        end
    end

    local global_idx_offset = 0
    local global_vtx_offset = 0
    for _, draw_list in draw_data.CmdLists:iter() do
        for _, pcmd in draw_list.CmdBuffer:iter() do
            if pcmd.ElemCount > 0 then
                for i = 0, pcmd.ElemCount - 1, 3 do
                    local idx0 = draw_list.IdxBuffer.Data[global_idx_offset + pcmd.IdxOffset + 1 + i]
                    local idx1 = draw_list.IdxBuffer.Data[global_idx_offset + pcmd.IdxOffset + 2 + i]
                    local idx2 = draw_list.IdxBuffer.Data[global_idx_offset + pcmd.IdxOffset + 3 + i]

                    local vtx0 = draw_list.VtxBuffer.Data[global_vtx_offset + idx0]
                    local vtx1 = draw_list.VtxBuffer.Data[global_vtx_offset + idx1]
                    local vtx2 = draw_list.VtxBuffer.Data[global_vtx_offset + idx2]

                    local col = vtx0.col
                    local tex_id = pcmd:GetTexID()

                    surface.SetMaterial(bd.TextureRegistry[tex_id].Material)
                    surface.SetDrawColor(col.x * 255, col.y * 255, col.z * 255, col.w * 255)
                    surface.DrawPoly({
                        {x = vtx0.pos.x, y = vtx0.pos.y, u = vtx0.uv.x, v = vtx0.uv.y},
                        {x = vtx1.pos.x, y = vtx1.pos.y, u = vtx1.uv.x, v = vtx1.uv.y},
                        {x = vtx2.pos.x, y = vtx2.pos.y, u = vtx2.uv.x, v = vtx2.uv.y}
                    })
                end
            end
        end

        global_idx_offset = global_idx_offset + draw_list.IdxBuffer.Size
        global_vtx_offset = global_vtx_offset + draw_list.VtxBuffer.Size
    end
end

--- @param tex ImTextureData
function ImGui_ImplGMOD_DestroyTexture(tex)
    local backend_tex = tex.BackendUserData

    if (backend_tex) then
        IM_ASSERT(backend_tex.Handle == tex.TexID)

        local bd = ImGui_ImplGMOD_GetBackendData()
        bd.TextureRegistry[tex.TexID] = nil

        tex:SetTexID(ImTextureID_Invalid)
        tex.BackendUserData = nil
        backend_tex = nil
    end

    tex:SetStatus(ImTextureStatus.Destroyed)
end

--- @param tex ImTextureData
function ImGui_ImplGMOD_UpdateTexture(tex)
    local bd = ImGui_ImplGMOD_GetBackendData()

    if tex.Status == ImTextureStatus.WantCreate then
        IM_ASSERT(tex.TexID == ImTextureID_Invalid and tex.BackendUserData == nil)
        IM_ASSERT(tex.Format == ImTextureFormat.RGBA32)

        local backend_tex = ImGui_ImplGMOD_Texture()

        backend_tex.Width            = tex.Width
        backend_tex.Height           = tex.Height

        backend_tex.Handle      = bd.CurrentTextureHandle
        bd.CurrentTextureHandle = bd.CurrentTextureHandle + 1

        backend_tex.RenderTargetName = "imgui_ImplGMOD_RT#" .. tostring(backend_tex.Handle)

        local render_target = GetRenderTargetEx(
            backend_tex.RenderTargetName,
            backend_tex.Width, backend_tex.Height,
            RT_SIZE_OFFSCREEN,
            MATERIAL_RT_DEPTH_NONE,
            0, 0,
            IMAGE_FORMAT_RGBA8888
        )

        local render_target_material = CreateMaterial(backend_tex.RenderTargetName .. "MAT", "UnlitGeneric", {
            ["$basetexture"] = render_target:GetName(),
            ["$translucent"] = 1,
            ["$vertexcolor"] = 1,
            ["$vertexalpha"] = 1,
            ["$ignorez"] = 1
        })

        render_target_material:SetInt("$flags", bit.bor(render_target_material:GetInt("$flags"), 32768))

        backend_tex.RenderTarget = render_target
        backend_tex.Material = render_target_material

        render.PushRenderTarget(backend_tex.RenderTarget)

        render.Clear(0, 0, 0, 0, true, true)

        cam.Start2D()

        for y = 0, tex.Height - 1 do
            local row = tex:GetPixelsAt(0, y)
            for x = 0, tex.Width - 1 do
                local pixelOffset = x * 4
                local r = IM_SLICE_GET(row, pixelOffset + 0)
                local g = IM_SLICE_GET(row, pixelOffset + 1)
                local b = IM_SLICE_GET(row, pixelOffset + 2)
                local a = IM_SLICE_GET(row, pixelOffset + 3)

                surface.SetDrawColor(r, g, b, a)
                surface.DrawRect(x, y, 1, 1)
            end
        end

        cam.End2D()

        render.PopRenderTarget()

        tex:SetTexID(backend_tex.Handle)
        tex.BackendUserData = backend_tex
        bd.TextureRegistry[backend_tex.Handle] = backend_tex

        tex:SetStatus(ImTextureStatus.OK)
    elseif tex.Status == ImTextureStatus.WantUpdates then
        local backend_tex = tex.BackendUserData
        IM_ASSERT(tex.Format == ImTextureFormat.RGBA32)

        local upload_x = tex.UpdateRect.x
        local upload_y = tex.UpdateRect.y
        local upload_w = tex.UpdateRect.w
        local upload_h = tex.UpdateRect.h

        render.PushRenderTarget(backend_tex.RenderTarget)

        render.Clear(0, 0, 0, 0, true, true)

        cam.Start2D()

        for y = upload_y, upload_y + upload_h - 1 do
            local row = tex:GetPixelsAt(upload_x, y)
            for x = upload_x, upload_x + upload_w - 1 do
                local pixelOffset = (x - upload_x) * 4
                local r = IM_SLICE_GET(row, pixelOffset + 0)
                local g = IM_SLICE_GET(row, pixelOffset + 1)
                local b = IM_SLICE_GET(row, pixelOffset + 2)
                local a = IM_SLICE_GET(row, pixelOffset + 3)

                surface.SetDrawColor(r, g, b, a)
                surface.DrawRect(x, y, 1, 1)
            end
        end

        cam.End2D()

        render.PopRenderTarget()

        tex:SetStatus(ImTextureStatus.OK)
    elseif tex.Status == ImTextureStatus.WantDestroy then
        ImGui_ImplGMOD_DestroyTexture(tex)
    end
end

return {
    Init           = ImGui_ImplGMOD_Init,
    Shutdown       = ImGui_ImplGMOD_Shutdown,
    NewFrame       = ImGui_ImplGMOD_NewFrame,
    RenderDrawData = ImGui_ImplGMOD_RenderDrawData
}