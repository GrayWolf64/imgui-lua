--- All the things strongly related to GMod go here

-- `input.GetCursorPos()` has issues in MacOS:
-- https://github.com/Facepunch/garrysmod-issues/issues/4964

local cam     = cam
local render  = render
local surface = surface
local mesh    = mesh

--- @type function
local ImGui_ImplGMOD_DestroyTexture

--- @type function
local ImGui_ImplGMOD_UpdateTexture

--- @type function
local ImGui_ImplGMOD_RenderDrawData

--- @type function
local ImGui_ImplGMOD_ProcessEvent

--- @type function
local ImGui_ImplGMOD_Shutdown

local function ImGui_ImplGMOD_GetBackendData()
    return ImGui.GetCurrentContext() and ImGui.GetIO().BackendPlatformUserData or nil
end

local function ImGui_ImplGMOD_FindViewportByPlatformHandle(platform_io, derma_window)
    for _, viewport in platform_io.Viewports:iter() do
        if (viewport.PlatformHandle == derma_window) then
            return viewport
        end
    end

    return nil
end

--- @param panel Panel
local function ImGui_ImplGMOD_SetupPanelHooks(panel, is_main_viewport)
    local old_OnCursorMoved = panel.OnCursorMoved
    panel.OnCursorMoved = function(self, x, y)
        if old_OnCursorMoved then old_OnCursorMoved(self, x, y) end
        x, y = input.GetCursorPos()
        ImGui_ImplGMOD_ProcessEvent(nil, nil, x, y)
    end

    local old_OnMousePressed = panel.OnMousePressed
    panel.OnMousePressed = function(self, key_code)
        if old_OnMousePressed then old_OnMousePressed(self, key_code) end
        self:MouseCapture(true)
        ImGui_ImplGMOD_ProcessEvent(key_code, true, nil, nil)
    end

    local old_OnMouseReleased = panel.OnMouseReleased
    panel.OnMouseReleased = function(self, key_code)
        if old_OnMouseReleased then old_OnMouseReleased(self, key_code) end
        self:MouseCapture(false)
        ImGui_ImplGMOD_ProcessEvent(key_code, false, nil, nil)
    end

    local old_OnMouseWheeled = panel.OnMouseWheeled
    panel.OnMouseWheeled = function(self, scroll_delta)
        if old_OnMouseWheeled then old_OnMouseWheeled(self, scroll_delta) end
        ImGui_ImplGMOD_ProcessEvent(nil, nil, nil, nil, nil, scroll_delta)
    end

    local old_OnScreenSizeChanged = panel.OnScreenSizeChanged
    panel.OnScreenSizeChanged = function(self, old_w, old_h, new_w, new_h)
        if old_OnScreenSizeChanged then old_OnScreenSizeChanged(self, old_w, old_h, new_w, new_h) end
        ImGui_ImplGMOD_ProcessEvent(nil, nil, nil, nil, true)
    end

    if is_main_viewport then
        local old_OnRemove = panel.OnRemove
        panel.OnRemove = function()
            if old_OnRemove then old_OnRemove() end
            ImGui_ImplGMOD_Shutdown()
        end
    end
end

function ImGui_ImplGMOD_UpdateMouseData(io)
    local hovered_panel = vgui.GetHoveredPanel() -- This lags behind panel Paint(), but should be fine in this use case
    local vp = ImGui_ImplGMOD_FindViewportByPlatformHandle(ImGui.GetPlatformIO(), hovered_panel)
    if vp then
        io:AddMouseViewportEvent(vp.ID)
    end
end

--- - Single-viewport mode: mouse position in GMod Derma window coordinates
--- - Multi-viewport mode: mouse position in GMod screen absolute coordinates
function ImGui_ImplGMOD_ProcessEvent(key_code, is_down, x, y, is_display_changed, scroll_delta)
    local bd = ImGui_ImplGMOD_GetBackendData()
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
    elseif x and y then -- cursor position update
        io:AddMouseSourceEvent(ImGuiMouseSource_Mouse)
        io:AddMousePosEvent(x, y)
    elseif is_display_changed then
        bd.WantUpdateMonitors = true
    elseif scroll_delta then
        io:AddMouseWheelEvent(0.0, scroll_delta / 120) -- TODO: validate
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

--- @class ImGui_ImplGMOD_ViewportData
--- @field DermaWindow        Panel
--- @field DermaWindowParent? Panel
--- @field DermaWindowOwned   bool

--- @return ImGui_ImplGMOD_ViewportData
--- @nodiscard
local function ImGui_ImplGMOD_ViewportData()
    return {
        DermaWindow       = nil,
        DermaWindowParent = nil,
        DermaWindowOwned  = false
    }
end

--- @param viewport ImGuiViewport
--- @return Panel?
local function ImGui_ImplGMOD_GetDermaWindowFromViewport(viewport)
    if viewport ~= nil then
        return viewport.PlatformHandle
    end
    return nil
end

local function ImGui_ImplGMOD_CreateWindow(viewport)
    local vd = ImGui_ImplGMOD_ViewportData()
    viewport.PlatformUserData = vd

    -- VGUI treats child windows as "inside" the parent
    -- vd.DermaWindowParent = ImGui_ImplGMOD_GetDermaWindowFromViewport(viewport.ParentViewport)
    vd.DermaWindow = vgui.Create("EditablePanel", nil, "ImGui Platform")

    vd.DermaWindow:SetPos(viewport.Pos.x, viewport.Pos.y)
    vd.DermaWindow:SetSize(viewport.Size.x, viewport.Size.y)
    vd.DermaWindowOwned = true

    ImGui_ImplGMOD_SetupPanelHooks(vd.DermaWindow)

    vd.DermaWindow.Paint = function(self, w, h)
        ImGui_ImplGMOD_RenderDrawData(viewport.DrawData)
    end

    viewport.PlatformRequestResize = false

    viewport.PlatformHandle    = vd.DermaWindow
    viewport.PlatformHandleRaw = vd.DermaWindow
end

local function ImGui_ImplGMOD_DestroyWindow(viewport)
    local vd = viewport.PlatformUserData
    if vd then
        if IsValid(vd.DermaWindow) and vd.DermaWindowOwned then
            vd.DermaWindow:Remove()
        end
        vd.DermaWindow = nil
    end
    viewport.PlatformUserData = nil

    vd = viewport.RendererUserData
    if vd then

    end
    viewport.RendererUserData = nil
end

local function ImGui_ImplGMOD_ShowWindow(viewport)
    local vd = viewport.PlatformUserData
    IM_ASSERT(IsValid(vd.DermaWindow))
    vd.DermaWindow:MakePopup()
end

local function ImGui_ImplGMOD_SetWindowPos(viewport, pos)
    local vd = viewport.PlatformUserData
    IM_ASSERT(IsValid(vd.DermaWindow))
    vd.DermaWindow:SetPos(pos.x, pos.y)
end

--- @param viewport ImGuiViewport
--- @return ImVec2
--- @nodiscard
local function ImGui_ImplGMOD_GetWindowPos(viewport)
    local vd = viewport.PlatformUserData
    IM_ASSERT(IsValid(vd.DermaWindow))

    return ImVec2(vd.DermaWindow:GetPos())
end

local function ImGui_ImplGMOD_SetWindowSize(viewport, size)
    local vd = viewport.PlatformUserData
    IM_ASSERT(IsValid(vd.DermaWindow))
    vd.DermaWindow:SetSize(size.x, size.y)
end

local function ImGui_ImplGMOD_SetWindowFocus(viewport)
    local vd = viewport.PlatformUserData
    IM_ASSERT(IsValid(vd.DermaWindow))
    vd:MakePopup()
end

local function ImGui_ImplGMOD_SetWindowTitle(viewport, title)
    local vd = viewport.PlatformUserData
    IM_ASSERT(IsValid(vd.DermaWindow))
    vd.DermaWindow:SetName(title)
end

local function ImGui_ImplGMOD_RenderWindow(viewport)
    local vd = viewport.PlatformUserData
    -- TODO: validate
end

local function ImGui_ImplGMOD_SwapBuffers()
    return
end

--- @param platform_has_own_dc bool
local function ImGui_ImplGMOD_InitMultiViewportSupport(platform_has_own_dc)
    local platform_io = ImGui.GetPlatformIO()
    platform_io.Platform_CreateWindow = ImGui_ImplGMOD_CreateWindow
    platform_io.Platform_DestroyWindow = ImGui_ImplGMOD_DestroyWindow
    platform_io.Platform_ShowWindow = ImGui_ImplGMOD_ShowWindow
    platform_io.Platform_SetWindowPos = ImGui_ImplGMOD_SetWindowPos
    platform_io.Platform_SetWindowSize = ImGui_ImplGMOD_SetWindowSize
    platform_io.Platform_SetWindowFocus = ImGui_ImplGMOD_SetWindowFocus
    platform_io.Platform_SetWindowTitle = ImGui_ImplGMOD_SetWindowTitle

    platform_io.Platform_GetWindowPos = ImGui_ImplGMOD_GetWindowPos

    platform_io.Renderer_RenderWindow = ImGui_ImplGMOD_RenderWindow
    platform_io.Renderer_SwapBuffers = ImGui_ImplGMOD_SwapBuffers

    local main_viewport = ImGui.GetMainViewport()
    local bd = ImGui_ImplGMOD_GetBackendData()
    local vd = ImGui_ImplGMOD_ViewportData()
    vd.DermaWindow = bd.Window
    vd.DermaWindowOwned = false
    main_viewport.PlatformUserData = vd
end

local function ImGui_ImplGMOD_ShutdownMultiViewportSupport()
    ImGui.DestroyPlatformWindows()
end

local function ImGui_ImplGMOD_UpdateMonitors()
    local bd = ImGui_ImplGMOD_GetBackendData()
    local io = ImGui.GetPlatformIO()
    io.Monitors:resize(0)

    local imgui_monitor = ImGuiPlatformMonitor()
    imgui_monitor.MainSize = ImVec2(ScrW(), ScrH())
    imgui_monitor.WorkSize = ImVec2(ScrW(), ScrH())

    io.Monitors:push_back(imgui_monitor)

    bd.WantUpdateMonitors = false
end

--- @param window Panel
local function ImGui_ImplGMOD_Init(window, platform_has_own_dc)
    --- If lower, the window title cross or arrow will look bad
    RunConsoleCommand("mat_antialias", "8")

    local io = ImGui.GetIO()

    local bd = ImGui_ImplGMOD_Data()
    bd.Window = window
    io.BackendPlatformUserData = bd

    io.BackendFlags = bit.bor(io.BackendFlags, ImGuiBackendFlags.PlatformHasViewports)
    io.BackendFlags = bit.bor(io.BackendFlags, ImGuiBackendFlags.HasMouseHoveredViewport)
    -- io.BackendFlags = bit.bor(io.BackendFlags, ImGuiBackendFlags.HasParentViewport)

    io.BackendFlags = bit.bor(io.BackendFlags, ImGuiBackendFlags.RendererHasTextures)
    io.BackendFlags = bit.bor(io.BackendFlags, ImGuiBackendFlags.RendererHasVtxOffset)
    io.BackendFlags = bit.bor(io.BackendFlags, ImGuiBackendFlags.RendererHasViewports)

    ImGui_ImplGMOD_UpdateMonitors()

    local main_viewport = ImGui.GetMainViewport()
    main_viewport.PlatformHandle = bd.Window
    main_viewport.PlatformHandleRaw = bd.Window
    ImGui_ImplGMOD_InitMultiViewportSupport(platform_has_own_dc)
end

-- We don't have a game-level cursor setter in GMod, so just set cursor for the hovered panel that happens to be our viewport
local function ImGui_ImplGMOD_DermaSetCursor(cursor_type)
    local io = ImGui.GetPlatformIO()
    local hovered_panel = vgui.GetHoveredPanel() -- This lags behind panel Paint(), but should be fine in this use case
    if ImGui_ImplGMOD_FindViewportByPlatformHandle(io, hovered_panel) then
        hovered_panel:SetCursor(cursor_type)
    end
end

--- @param io           ImGuiIO
--- @param imgui_cursor ImGuiMouseCursor
local function ImGui_ImplGMOD_UpdateMouseCursor(io, imgui_cursor)
    if bit.band(io.ConfigFlags, ImGuiConfigFlags_NoMouseCursorChange) ~= 0 then
        return false
    end

    local bd = ImGui_ImplGMOD_GetBackendData()

    if imgui_cursor == ImGuiMouseCursor.None or io.MouseDrawCursor then
        ImGui_ImplGMOD_DermaSetCursor("blank")
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

        ImGui_ImplGMOD_DermaSetCursor(gmod_cursor)
    end

    return true
end

function ImGui_ImplGMOD_Shutdown()
    local bd = ImGui_ImplGMOD_GetBackendData()
    IM_ASSERT(bd ~= nil, "No platform backend to shutdown, or already shutdown?")

    local io = ImGui.GetIO()
    local platform_io = ImGui.GetPlatformIO()

    ImGui_ImplGMOD_ShutdownMultiViewportSupport()

    io.BackendPlatformName = nil
    io.BackendPlatformUserData = nil
    io.BackendFlags = bit.band(io.BackendFlags, bit.bnot(bit.bor(ImGuiBackendFlags.HasMouseCursors, ImGuiBackendFlags.HasSetMousePos, ImGuiBackendFlags.HasGamepad, ImGuiBackendFlags.PlatformHasViewports, ImGuiBackendFlags.HasMouseHoveredViewport, ImGuiBackendFlags.HasParentViewport)))
    platform_io:ClearPlatformHandlers()
end

local function ImGui_ImplGMOD_NewFrame()
    local io = ImGui.GetIO()
    local bd = ImGui_ImplGMOD_GetBackendData()

    io.DisplaySize = ImVec2(bd.Window:GetSize())
    if bd.WantUpdateMonitors then
        ImGui_ImplGMOD_UpdateMonitors()
    end

    local current_time = SysTime()
    io.DeltaTime = current_time - bd.Time
    bd.Time = current_time

    ImGui_ImplGMOD_UpdateMouseData(io)
    ImGui_ImplGMOD_UpdateMouseCursor(io, ImGui.GetMouseCursor())
end

local function ImGui_ImplGMOD_SetupRenderState()
    render.SetViewPort(0, 0, ScrW(), ScrH())

    render.CullMode(MATERIAL_CULLMODE_NONE)
    render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE_MINUS_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ONE_MINUS_SRC_ALPHA, BLENDFUNC_ADD)
    render.FogMode(MATERIAL_FOG_NONE)
    render.SetStencilEnable(false)
    render.EnableClipping(true)
    render.SuppressEngineLighting(true)
    render.PushFilterMin(TEXFILTER.LINEAR)
    render.PushFilterMag(TEXFILTER.LINEAR)
end

local function ImGui_ImplGMOD_RestoreRenderState()
    render.OverrideBlend(false)
    render.EnableClipping(false)
    render.SuppressEngineLighting(false)
    render.PopFilterMin()
    render.PopFilterMag()
end

local col0 = ImVec4()
local col1 = ImVec4()
local col2 = ImVec4()

function ImGui_ImplGMOD_RenderDrawData(draw_data)
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

    ImGui_ImplGMOD_SetupRenderState()

    for _, draw_list in draw_data.CmdLists:iter() do
        for _, pcmd in draw_list.CmdBuffer:iter() do
            if pcmd.ElemCount > 0 then
                if pcmd.ClipRect.z <= pcmd.ClipRect.x or pcmd.ClipRect.w <= pcmd.ClipRect.y then
                    continue
                end

                -- GMod SetScissorRect expects screen-space coords
                render.SetScissorRect(pcmd.ClipRect.x, pcmd.ClipRect.y, pcmd.ClipRect.z, pcmd.ClipRect.w, true)

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

    ImGui_ImplGMOD_RestoreRenderState()

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
            ["$ignorez"] = 1,
            ["$linearwrite"] = 1,         -- Disable broken engine gamma correction for colors
            ["$linearread_texture1"] = 1, -- Disable broken engine gamma correction for textures
            ["$linearread_texture2"] = 1,
            ["$linearread_texture3"] = 1
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
    SetupPanelHooks = ImGui_ImplGMOD_SetupPanelHooks,

    Init           = ImGui_ImplGMOD_Init,
    Shutdown       = ImGui_ImplGMOD_Shutdown,
    NewFrame       = ImGui_ImplGMOD_NewFrame,
    RenderDrawData = ImGui_ImplGMOD_RenderDrawData
}