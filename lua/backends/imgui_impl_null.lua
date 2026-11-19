-- imgui sincerely: Null Platform+Renderer Backends
-- A blind imgui context with no input and no output

local ImGui_ImplNullPlatform_Init
local ImGui_ImplNullPlatform_Shutdown
local ImGui_ImplNullPlatform_NewFrame
local ImGui_ImplNullRender_Init
local ImGui_ImplNullRender_Shutdown
local ImGui_ImplNullRender_NewFrame

local function ImGui_ImplNull_Init()
    ImGui_ImplNullPlatform_Init()
    ImGui_ImplNullRender_Init()
    return true
end

local function ImGui_ImplNull_Shutdown()
    ImGui_ImplNullRender_Shutdown()
    ImGui_ImplNullPlatform_Shutdown()
end

local function ImGui_ImplNull_NewFrame()
    ImGui_ImplNullPlatform_NewFrame()
    ImGui_ImplNullRender_NewFrame()
end

function ImGui_ImplNullPlatform_Init()
    local io = ImGui.GetIO()
    io.BackendFlags = bit.bor(io.BackendFlags, ImGuiBackendFlags.HasMouseCursors)
    return true
end

function ImGui_ImplNullPlatform_Shutdown()
    local io = ImGui.GetIO()
    io.BackendFlags = bit.band(io.BackendFlags, bit.bnot(ImGuiBackendFlags.HasMouseCursors))
end

function ImGui_ImplNullPlatform_NewFrame()
    local io = ImGui.GetIO()
    ImVec2_CopyV(io.DisplaySize, 1920, 1080)
    io.DeltaTime = 1.0 / 60.0
end

function ImGui_ImplNullRender_Init()
    local io = ImGui.GetIO()
    io.BackendFlags = bit.bor(io.BackendFlags, ImGuiBackendFlags.RendererHasVtxOffset)
    io.BackendFlags = bit.bor(io.BackendFlags, ImGuiBackendFlags.RendererHasTextures)
    return true
end

function ImGui_ImplNullRender_Shutdown()
    local io = ImGui.GetIO()
    io.BackendFlags = bit.band(io.BackendFlags, bit.bnot(ImGuiBackendFlags.RendererHasVtxOffset))
    io.BackendFlags = bit.band(io.BackendFlags, bit.bnot(ImGuiBackendFlags.RendererHasTextures))
end

function ImGui_ImplNullRender_NewFrame()
end

--- @param tex ImTextureData
local function ImGui_ImplNullRender_UpdateTexture(tex)
    -- NOTE: WantUpdates is ignored and WantDestroy becomes OK before destruction check!
    if tex.Status == ImTextureStatus.WantCreate or tex.Status == ImTextureStatus.WantDestroy then
        tex:SetStatus(ImTextureStatus.OK)
    end
    if tex.Status == ImTextureStatus.WantDestroy then
        tex:SetTexID(ImTextureID_Invalid)
        tex:SetStatus(ImTextureStatus.Destroyed)
    end
end

--- @param draw_data ImDrawData
local function ImGui_ImplNullRender_RenderDrawData(draw_data)
    if draw_data.Textures ~= nil then
        for _, tex in draw_data.Textures:iter() do
            if tex.Status ~= ImTextureStatus.OK then
                ImGui_ImplNullRender_UpdateTexture(tex)
            end
        end
    end
end

return {
    Init     = ImGui_ImplNull_Init,
    Shutdown = ImGui_ImplNull_Shutdown,
    NewFrame = ImGui_ImplNull_NewFrame,

    Platform_Init     = ImGui_ImplNullPlatform_Init,
    Platform_Shutdown = ImGui_ImplNullPlatform_Shutdown,
    Platform_NewFrame = ImGui_ImplNullPlatform_NewFrame,

    Render_Init     = ImGui_ImplNullRender_Init,
    Render_Shutdown = ImGui_ImplNullRender_Shutdown,
    Render_NewFrame = ImGui_ImplNullRender_NewFrame,
    RenderDrawData  = ImGui_ImplNullRender_RenderDrawData,
}
