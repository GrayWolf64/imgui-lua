local ImGui_ImplGMOD = IMGUI_INCLUDE("imgui_impl_gmod.lua")

--- TEST HERE:
ImGui.CreateContext()

ImGui_ImplGMOD.Init()

local size = 30

--- TODO: can i actually switch different hooks dynamically to achieve our windows rendered under and above the game ui or derma?
hook.Add("PostRender", "ImGuiTest", function()
    cam.Start2D()

    ImGui_ImplGMOD.NewFrame()

    ImGui.NewFrame()

    if size == 200 then size = 30 end
    size = size + 1

    -- FIXME: bouncing text
    ImGui.PushFont(nil, size) -- math.max(20, math.abs(100 * math.sin(SysTime())))

    local window1_open = {true}
    ImGui.Begin("A", window1_open)
    ImGui.End()

    ImGui.PopFont()

    -- local window2_open = {true}
    -- ImGui.Begin("ImGui Demo", window2_open)
    -- ImGui.End()

    ImGui.EndFrame()

    ImGui.Render()

    ImGui_ImplGMOD.RenderDrawData(ImGui.GetDrawData())

    -- Temporary
    local g = ImGui.GetCurrentContext()
    draw.DrawText(
        string.format(
            "ActiveID: %s\nActiveIDWindow: %s\nActiveIDIsAlive: %s\nActiveIDPreviousFrame: %s\n\nMem: %dkb\nFramerate: %d",
            g.ActiveID,
            g.ActiveIDWindow and g.ActiveIDWindow.ID or nil,
            g.ActiveIDIsAlive,
            g.ActiveIDPreviousFrame,
            math.Round(collectgarbage("count")),
            g.IO.Framerate
        ), "CloseCaption_Bold", 800, 800, color_white
    )

    cam.End2D()
end)