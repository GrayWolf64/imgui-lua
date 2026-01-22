local ImGui_ImplGMOD = IMGUI_INCLUDE("imgui_impl_gmod.lua")

--- TEST HERE:
ImGui.CreateContext()

ImGui_ImplGMOD.Init()

--- TODO: can i actually switch different hooks dynamically to achieve our windows rendered under and above the game ui or derma?
hook.Add("PostRender", "ImGuiTest", function()
    cam.Start2D()

    ImGui_ImplGMOD.NewFrame()

    ImGui.NewFrame()

    ImGui.PushFont(nil, 40) -- math.max(20, math.abs(100 * math.sin(SysTime())))

    local window1_open = {true}
    ImGui.Begin("Hello World!", window1_open)
    ImGui.Text("WTF")
    ImGui.Text("A Quick Brown Fox Jumps Over a Lazy Bear!")
    ImGui.End()

    ImGui.PopFont()

    local window2_open = {true}
    ImGui.Begin("ImGui Demo", window2_open)
    ImGui.End()

    ImGui.EndFrame()

    ImGui.Render()

    ImGui_ImplGMOD.RenderDrawData(ImGui.GetDrawData())

    -- Temporary
    local g = ImGui.GetCurrentContext()
    draw.DrawText(
        string.format(
            "Mem: %dkb\nFramerate: %d",
            math.Round(collectgarbage("count")),
            g.IO.Framerate
        ), "CloseCaption_Bold", 800, 800, color_white
    )

    cam.End2D()
end)