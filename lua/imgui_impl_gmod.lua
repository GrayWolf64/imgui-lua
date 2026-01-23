--- All the things strongly related to GMod go here
-- TODO: Rename the dummy panel?
-- TODO: investigate: this dummy panel is actually a valid viewport? Derma panels can be fake viewports?
-- TODO: currently the renderer and platform are in the same backend structure, separate them

local cam     = cam
local render  = render
local surface = surface
local mesh    = mesh

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

    -- TODO: cleanup
    GDummyPanel.OnCursorMoved = function(self, x, y)
        local io = ImGui.GetIO()
        io:AddMouseSourceEvent(ImGuiMouseSource_Mouse)
        io:AddMousePosEvent(x, y)
    end

    GDummyPanel.OnMousePressed = function(self, key_code)
        local io = ImGui.GetIO()
        io:AddMouseSourceEvent(ImGuiMouseSource_Mouse)

        local mouse_button
        if key_code == MOUSE_LEFT then
            mouse_button = ImGuiMouseButton_Left
        elseif key_code == MOUSE_RIGHT then
            mouse_button = ImGuiMouseButton_Right
        end

        io:AddMouseButtonEvent(mouse_button, true)
    end

    GDummyPanel.OnMouseReleased = function(self, key_code)
        local io = ImGui.GetIO()
        io:AddMouseSourceEvent(ImGuiMouseSource_Mouse)

        local mouse_button
        if key_code == MOUSE_LEFT then
            mouse_button = ImGuiMouseButton_Left
        elseif key_code == MOUSE_RIGHT then
            mouse_button = ImGuiMouseButton_Right
        end

        io:AddMouseButtonEvent(mouse_button, false)
    end

    GDummyPanel.Think = function(self)
        if input.IsMouseDown(MOUSE_LEFT) then
            local io = ImGui.GetIO()
            io:AddMouseSourceEvent(ImGuiMouseSource_Mouse)
            io:AddMouseButtonEvent(ImGuiMouseButton_Left, true)
        elseif input.IsMouseDown(MOUSE_RIGHT) then
            local io = ImGui.GetIO()
            io:AddMouseSourceEvent(ImGuiMouseSource_Mouse)
            io:AddMouseButtonEvent(ImGuiMouseButton_Right, true)
        end
    end

    -- GDummyPanel.Paint = function(self, w, h) -- FIXME: block derma modal panels
        -- surface.SetDrawColor(0, 255, 0)
        -- surface.DrawOutlinedRect(0, 0, w, h, 4)
    -- end
end

-- FIXME: currently everything under our windows are blocked from mouse input
local function AttachDummyPanel(x, y, w, h)
    if not IsValid(GDummyPanel) then return end

    GDummyPanel:SetFocusTopLevel(true)
    GDummyPanel:SetPos(x, y)
    GDummyPanel:SetSize(w, h)
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

        Time = 0
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
    AttachDummyPanel(0, 0, io.DisplaySize.x, io.DisplaySize.y)
end

local clip_min = ImVec2()
local clip_max = ImVec2()
local clip_off = ImVec2()

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

    clip_off.x = draw_data.DisplayPos.x; clip_off.y = draw_data.DisplayPos.y

    for _, draw_list in draw_data.CmdLists:iter() do
        for _, pcmd in draw_list.CmdBuffer:iter() do
            if pcmd.ElemCount > 0 then
                clip_min.x = pcmd.ClipRect.x - clip_off.x; clip_min.y = pcmd.ClipRect.y - clip_off.y
                clip_max.x = pcmd.ClipRect.z - clip_off.x; clip_max.y = pcmd.ClipRect.w - clip_off.y
                if clip_max.x <= clip_min.x or clip_max.y <= clip_min.y then
                    continue
                end

                render.SetScissorRect(clip_min.x, clip_min.y, clip_max.x, clip_max.y, true)

                for i = 0, pcmd.ElemCount - 1, 3 do
                    local idx0 = draw_list.IdxBuffer.Data[pcmd.IdxOffset + 1 + i]
                    local idx1 = draw_list.IdxBuffer.Data[pcmd.IdxOffset + 2 + i]
                    local idx2 = draw_list.IdxBuffer.Data[pcmd.IdxOffset + 3 + i]

                    local vtx0 = draw_list.VtxBuffer.Data[pcmd.VtxOffset + idx0]
                    local vtx1 = draw_list.VtxBuffer.Data[pcmd.VtxOffset + idx1]
                    local vtx2 = draw_list.VtxBuffer.Data[pcmd.VtxOffset + idx2]

                    local tex_id = pcmd:GetTexID()

                    render.SetMaterial(bd.TextureRegistry[tex_id].Material)

                    mesh.Begin(MATERIAL_TRIANGLES, 1)

                    mesh.Position(vtx0.pos.x, vtx0.pos.y, 0)
                    mesh.TexCoord(0, vtx0.uv.x, vtx0.uv.y)
                    mesh.Color(vtx0.col.x * 255, vtx0.col.y * 255, vtx0.col.z * 255, vtx0.col.w * 255)
                    mesh.AdvanceVertex()

                    mesh.Position(vtx1.pos.x, vtx1.pos.y, 0)
                    mesh.TexCoord(0, vtx1.uv.x, vtx1.uv.y)
                    mesh.Color(vtx1.col.x * 255, vtx1.col.y * 255, vtx1.col.z * 255, vtx1.col.w * 255)
                    mesh.AdvanceVertex()

                    mesh.Position(vtx2.pos.x, vtx2.pos.y, 0)
                    mesh.TexCoord(0, vtx2.uv.x, vtx2.uv.y)
                    mesh.Color(vtx2.col.x * 255, vtx2.col.y * 255, vtx2.col.z * 255, vtx2.col.w * 255)
                    mesh.AdvanceVertex()

                    mesh.End()
                end

                render.SetScissorRect(0, 0, 0, 0, false)
            end
        end
    end

    -- Display the atlas on my screen
    -- local atlas_tex = bd.TextureRegistry[draw_data.Textures.Data[draw_data.Textures.Size].TexID]
    -- if atlas_tex then
    --     render.DrawTextureToScreenRect(atlas_tex.Material:GetTexture("$basetexture"), ScrW() - atlas_tex.Width - 10, 10, atlas_tex.Width, atlas_tex.Height)
    -- end
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

        backend_tex.RenderTarget = render_target
        backend_tex.Material = render_target_material

        render.PushRenderTarget(backend_tex.RenderTarget)

        -- https://wiki.facepunch.com/gmod/render.PushRenderTarget
        -- This is probably a hack to use proper alpha channel with RTs
        render.OverrideAlphaWriteEnable(true, true)
        render.ClearDepth()
        render.Clear(0, 0, 0, 0)

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

        render.OverrideAlphaWriteEnable(false, false)

        render.PopRenderTarget()

        tex:SetTexID(backend_tex.Handle)
        tex.BackendUserData = backend_tex
        bd.TextureRegistry[backend_tex.Handle] = backend_tex

        tex:SetStatus(ImTextureStatus.OK)
    elseif tex.Status == ImTextureStatus.WantUpdates then
        local backend_tex = tex.BackendUserData
        IM_ASSERT(tex.Format == ImTextureFormat.RGBA32)

        render.PushRenderTarget(backend_tex.RenderTarget)

        local update_x, update_y, update_w, update_h = tex.UpdateRect.x, tex.UpdateRect.y, tex.UpdateRect.w, tex.UpdateRect.h
        render.OverrideAlphaWriteEnable(true, true)
        render.ClearDepth()

        cam.Start2D()

        render.SetScissorRect(update_x, update_y, update_x + update_w, update_y + update_h, true)

        for _, r in tex.Updates:iter() do
            for y = r.y, r.y + r.h - 1 do
                local row = tex:GetPixelsAt(r.x, y)

                for x_offset = 0, r.w - 1 do
                    local pixel_offset = x_offset * 4
                    local r_byte = IM_SLICE_GET(row, pixel_offset + 0)
                    local g_byte = IM_SLICE_GET(row, pixel_offset + 1)
                    local b_byte = IM_SLICE_GET(row, pixel_offset + 2)
                    local a_byte = IM_SLICE_GET(row, pixel_offset + 3)

                    surface.SetDrawColor(r_byte, g_byte, b_byte, a_byte)
                    surface.DrawRect(r.x + x_offset, y, 1, 1)
                end
            end
        end

        render.SetScissorRect(0, 0, 0, 0, false)

        cam.End2D()

        render.OverrideAlphaWriteEnable(false, false)
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