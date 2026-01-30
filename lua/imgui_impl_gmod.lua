--- All the things strongly related to GMod go here

local cam     = cam
local render  = render
local surface = surface
local mesh    = mesh

--- @type function
local ImGui_ImplGMOD_DestroyTexture

--- @type function
local ImGui_ImplGMOD_UpdateTexture

--- @type function
local ImGui_ImplGMOD_InputEventHandler

--- @type Panel? # We are at non-docking branch, only one viewport is supported
local g_Viewport = nil

--- @return Panel?
local function ImGui_ImplGMOD_CreateMainViewport()
    if IsValid(g_Viewport) then
        g_Viewport:Remove()
    end

    g_Viewport = vgui.Create("DFrame")

    g_Viewport:SetSizable(true)
    g_Viewport:SetSize(ScrW() / 2, ScrH() / 2)
    g_Viewport:MakePopup()
    g_Viewport:SetDraggable(true)
    g_Viewport:Center()
    g_Viewport:SetTitle("ImGui Main Viewport")

    g_Viewport.LocalToScreen = function(self, x, y)
        local pos_x, pos_y = self:GetPos()
        return pos_x + x, pos_y + y
    end

    g_Viewport.OnCursorMoved = function(self, x, y)
        ImGui_ImplGMOD_InputEventHandler(nil, nil, x, y)
    end

    local old_OnMousePressed = g_Viewport.OnMousePressed
    g_Viewport.OnMousePressed = function(self, key_code)
        old_OnMousePressed(self, key_code)
        ImGui_ImplGMOD_InputEventHandler(key_code, true, nil, nil)
    end

    local old_OnMouseReleased = g_Viewport.OnMouseReleased
    g_Viewport.OnMouseReleased = function(self, key_code)
        old_OnMouseReleased(self, key_code)
        ImGui_ImplGMOD_InputEventHandler(key_code, false, nil, nil)
    end

    local clear_color = ImVec4(0.45, 0.55, 0.60, 1.00) * 255
    local old_Paint = g_Viewport.Paint
    g_Viewport.Paint = function(self, w, h)
        old_Paint(self, w, h)
        surface.SetDrawColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w)
        surface.DrawRect(0, 0, w, h)
    end

    return g_Viewport
end

function ImGui_ImplGMOD_InputEventHandler(key_code, is_down, x, y)
    local io = ImGui.GetIO()

    if key_code then -- Mouse button or keyboard key
        if key_code >= MOUSE_FIRST and key_code <= MOUSE_LAST then
            io:AddMouseSourceEvent(ImGuiMouseSource_Mouse)

            local mouse_button
            if key_code == MOUSE_LEFT then
                mouse_button = ImGuiMouseButton_Left
            elseif key_code == MOUSE_RIGHT then
                mouse_button = ImGuiMouseButton_Right
            end

            io:AddMouseButtonEvent(mouse_button, is_down)
        else
            -- TODO: 
        end
    else -- cursor position update
        io:AddMouseSourceEvent(ImGuiMouseSource_Mouse)
        io:AddMousePosEvent(x, y)
    end
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
--- @field Window Panel

--- @return ImGui_ImplGMOD_Data
--- @nodiscard
local function ImGui_ImplGMOD_Data()
    return {
        TextureRegistry      = {},
        CurrentTextureHandle = 1,
        NumFramesInFlight    = 2,

        Time = 0,
        Window = nil
    }
end

local function ImGui_ImplGMOD_GetBackendData()
    return ImGui.GetCurrentContext() and ImGui.GetIO().BackendPlatformUserData or nil
end

--- @param window Panel
local function ImGui_ImplGMOD_Init(window)
    --- If lower, the window title cross or arrow will look bad
    RunConsoleCommand("mat_antialias", "8")

    local io = ImGui.GetIO()

    local bd = ImGui_ImplGMOD_Data()
    bd.Window = window
    io.BackendPlatformUserData = bd

    -- local main_viewport = ImGui.GetMainViewport()
    -- main_viewport.PlatformHandle = window

    io.BackendFlags = bit.bor(io.BackendFlags, ImGuiBackendFlags.RendererHasTextures)
    io.BackendFlags = bit.bor(io.BackendFlags, ImGuiBackendFlags.RendererHasVtxOffset)
end

--- @param io           ImGuiIO
--- @param imgui_cursor ImGuiMouseCursor
local function ImGui_ImplGMOD_UpdateMouseCursor(io, imgui_cursor)
    if bit.band(io.ConfigFlags, ImGuiConfigFlags_NoMouseCursorChange) ~= 0 then
        return false
    end

    local bd = ImGui_ImplGMOD_GetBackendData()

    if imgui_cursor == ImGuiMouseCursor.None or io.MouseDrawCursor then
        bd.Window:SetCursor("blank")
    else
        local gmod_cursor = "arrow"

        if imgui_cursor == ImGuiMouseCursor.Arrow then
            gmod_cursor = "arrow"
        elseif imgui_cursor == ImGuiMouseCursor.TextInput then
            gmod_cursor = "beam"
        elseif imgui_cursor == ImGuiMouseCursor.ResizeAll then
            gmod_cursor = "sizeall"
        elseif imgui_cursor == ImGuiMouseCursor.ResizeEW then
            gmod_cursor = "sizewe"
        elseif imgui_cursor == ImGuiMouseCursor.ResizeNS then
            gmod_cursor = "sizens"
        elseif imgui_cursor == ImGuiMouseCursor.ResizeNESW then
            gmod_cursor = "sizenesw"
        elseif imgui_cursor == ImGuiMouseCursor.ResizeNWSE then
            gmod_cursor = "sizenwse"
        elseif imgui_cursor == ImGuiMouseCursor.Hand then
            gmod_cursor = "hand"
        elseif imgui_cursor == ImGuiMouseCursor.Wait then
            gmod_cursor = "hourglass"
        elseif imgui_cursor == ImGuiMouseCursor.Progress then
            gmod_cursor = "waitarrow"
        elseif imgui_cursor == ImGuiMouseCursor.NotAllowed then
            gmod_cursor = "no"
        end

        bd.Window:SetCursor(gmod_cursor)
    end

    return true
end

local function ImGui_ImplGMOD_Shutdown()
end

local function ImGui_ImplGMOD_NewFrame()
    local io = ImGui.GetIO()
    local bd = ImGui_ImplGMOD_GetBackendData()

    io.DisplaySize = ImVec2(ScrW(), ScrH()) -- TODO: is this correct?
    local main_viewport = ImGui.GetMainViewport()

    local current_time = SysTime()
    io.DeltaTime = current_time - bd.Time
    bd.Time = current_time

    ImGui_ImplGMOD_UpdateMouseCursor(io, ImGui.GetMouseCursor())
end

local clip_min = ImVec2()
local clip_max = ImVec2()
local clip_off = ImVec2()
local col0 = ImVec4()
local col1 = ImVec4()
local col2 = ImVec4()

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

                -- This uses screen-space coords
                local clip_min_x, clip_min_y = bd.Window:LocalToScreen(clip_min.x, clip_min.y)
                local clip_max_x, clip_max_y = bd.Window:LocalToScreen(clip_max.x, clip_max.y)
                render.SetScissorRect(clip_min_x, clip_min_y, clip_max_x, clip_max_y, true)

                mesh.Begin(MATERIAL_TRIANGLES, pcmd.ElemCount / 3)

                for i = 0, pcmd.ElemCount - 1, 3 do
                    local idx0 = draw_list.IdxBuffer.Data[pcmd.IdxOffset + 1 + i]
                    local idx1 = draw_list.IdxBuffer.Data[pcmd.IdxOffset + 2 + i]
                    local idx2 = draw_list.IdxBuffer.Data[pcmd.IdxOffset + 3 + i]

                    local vtx0 = draw_list.VtxBuffer.Data[pcmd.VtxOffset + idx0]
                    local vtx1 = draw_list.VtxBuffer.Data[pcmd.VtxOffset + idx1]
                    local vtx2 = draw_list.VtxBuffer.Data[pcmd.VtxOffset + idx2]

                    local tex_id = pcmd:GetTexID()

                    render.SetMaterial(bd.TextureRegistry[tex_id].Material)

                    mesh.Position(vtx0.pos.x, vtx0.pos.y, 0)
                    mesh.TexCoord(0, vtx0.uv.x, vtx0.uv.y)
                    ImGui.ColorConvertU32ToFloat4(vtx0.col, col0)
                    mesh.Color(col0.x * 255, col0.y * 255, col0.z * 255, col0.w * 255)
                    mesh.AdvanceVertex()

                    mesh.Position(vtx1.pos.x, vtx1.pos.y, 0)
                    mesh.TexCoord(0, vtx1.uv.x, vtx1.uv.y)
                    ImGui.ColorConvertU32ToFloat4(vtx1.col, col1)
                    mesh.Color(col1.x * 255, col1.y * 255, col1.z * 255, col1.w * 255)
                    mesh.AdvanceVertex()

                    mesh.Position(vtx2.pos.x, vtx2.pos.y, 0)
                    mesh.TexCoord(0, vtx2.uv.x, vtx2.uv.y)
                    ImGui.ColorConvertU32ToFloat4(vtx2.col, col2)
                    mesh.Color(col2.x * 255, col2.y * 255, col2.z * 255, col2.w * 255)
                    mesh.AdvanceVertex()
                end

                mesh.End()

                render.SetScissorRect(0, 0, 0, 0, false)
            end
        end
    end

    -- Display the atlas on my screen
    -- local atlas_tex = bd.TextureRegistry[draw_data.Textures.Data[draw_data.Textures.Size].TexID]
    -- if atlas_tex then
    --     render.DrawTextureToScreenRect(atlas_tex.Material:GetTexture("$basetexture"), 20, 20, atlas_tex.Width, atlas_tex.Height)
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

        backend_tex.Width  = tex.Width
        backend_tex.Height = tex.Height

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
    CreateMainViewport = ImGui_ImplGMOD_CreateMainViewport,

    Init           = ImGui_ImplGMOD_Init,
    Shutdown       = ImGui_ImplGMOD_Shutdown,
    NewFrame       = ImGui_ImplGMOD_NewFrame,
    RenderDrawData = ImGui_ImplGMOD_RenderDrawData
}