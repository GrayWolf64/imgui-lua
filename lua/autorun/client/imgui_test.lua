local ImGui_ImplGMOD = IMGUI_INCLUDE("imgui_impl_gmod.lua")

--- TEST HERE:
ImGui.CreateContext()

ImGui_ImplGMOD.Init()

local g = ImGui.GetCurrentContext()

local window1_open = {true}
local window2_open = {true}

--- TODO: can i actually switch different hooks dynamically to achieve our windows rendered under and above the game ui or derma?
hook.Add("PostRender", "ImGuiTest", function()
    cam.Start2D()

    ImGui_ImplGMOD.NewFrame()

    ImGui.NewFrame()

    -- math.max(20, math.abs(100 * math.sin(SysTime())))
    ImGui.PushFont(nil, 30)

    ImGui.SetNextWindowSize(ImVec2(550, 400), ImGuiCond_FirstUseEver)

    ImGui.Begin("Hello, World!", window1_open)
        ImGui.Text("Lua Memory Usage: %dKb", math.Round(collectgarbage("count")))
        ImGui.Text("FPS: %d", g.IO.Framerate)
    ImGui.End()

    ImGui.PopFont()

    ImGui.SetNextWindowPos(ImVec2(30, 100), ImGuiCond_FirstUseEver)

    ImGui.Begin("ImGui Demo", window2_open)
    ImGui.End()

    ImGui.EndFrame()

    ImGui.Render()

    ImGui_ImplGMOD.RenderDrawData(ImGui.GetDrawData())

    cam.End2D()
end)