local ImGui_ImplGMOD = IMGUI_INCLUDE("imgui_impl_gmod.lua")

--- TEST HERE:
ImGui.CreateContext()

ImGui_ImplGMOD.Init()

--- TODO: can i actually switch different hooks dynamically to achieve our windows rendered under and above the game ui or derma?
hook.Add("PostRender", "ImGuiTest", function()
    cam.Start2D()

    ImGui_ImplGMOD.NewFrame()

    ImGui.NewFrame()

    -- Temporary test, cool timed scaling
    ImGui.PushFont(nil, math.max(15, math.abs(90 * math.sin(SysTime()))))

    local window1_open = {true}
    ImGui.Begin("Hello World!", window1_open)
    ImGui.End()

    ImGui.PopFont()

    -- local window2_open = {true}
    -- ImGui.Begin("ImGui Demo", window2_open)
    -- ImGui.End()

    -- local drawlist = ImDrawList()
    -- drawlist:AddRectFilled(ImVec2(60, 60), ImVec2(120, 120), color_white, 0.01)
    -- TODO: Finish this rendering!

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