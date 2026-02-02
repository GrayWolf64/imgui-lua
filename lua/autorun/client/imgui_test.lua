--- Temporary testing:
-- won't let users write these complicated stuff in production version

include"imgui.lua"

local ImGui_ImplGMOD = include("imgui_impl_gmod.lua")

local window1_open = true
local window2_open = true

concommand.Add("imgui_test", function()
    local animate = true
    local values = {} for i = 1, 90 do values[i] = 0 end
    local values_offset = 0
    local refresh_time = 0
    local phase = 0

    local viewport = ImGui_ImplGMOD.CreateMainViewport()

    ImGui.CreateContext()
    local g = ImGui.GetCurrentContext()

    local io = ImGui.GetIO()
    io.ConfigFlags = bit.bor(io.ConfigFlags, ImGuiConfigFlags_ViewportsEnable)

    ImGui_ImplGMOD.Init(viewport, true)

    function viewport.PaintOver(self, w, h)

        ImGui_ImplGMOD.NewFrame()

        ImGui.NewFrame()

        if window1_open then
            ImGui.PushFont(nil, 40)

            ImGui.SetNextWindowSize(ImVec2(550, 400), ImGuiCond.FirstUseEver)

            window1_open = ImGui.Begin("Hello, World!", window1_open)
                ImGui.Text("Lua Memory Usage: %dKb", math.Round(collectgarbage("count")))
                ImGui.Text("FPS: %d", g.IO.Framerate)
                local pressed
                pressed, window2_open = ImGui.Checkbox("Show Demo Window", window2_open)
            ImGui.End()

            ImGui.PopFont()
        end

        if window2_open then
            ImGui.SetNextWindowPos(ImVec2(30, 100), ImGuiCond.FirstUseEver)
            ImGui.SetNextWindowSize(ImVec2(300, 300), ImGuiCond.FirstUseEver)

            window2_open = ImGui.Begin("ImGui Demo", window2_open)
                ImGui.PushFont(nil, 30)

                ImGui.TextColored(ImVec4(0, 1, 0, 1), "Dear ImGui says %s!", "Hello")
                ImGui.TextColored(ImVec4(1, 0, 1, 1), "ImGui Sincerely")
                ImGui.TextDisabled("I am Disabled Text!")
                ImGui.TextUnformatted("Unformatted Text I am!", 12)
                ImGui.TextWrapped("A Quick Brown Fox Jumps Over A Lazy Bear When The Text Is Wrapped!")
                ImGui.Button("Click Me!")
                ImGui.SmallButton("Small")

                ImGui.SeparatorText("Basic PlotLines")

                if not animate or refresh_time == 0 then
                    refresh_time = ImGui.GetTime()
                end
                while refresh_time < ImGui.GetTime() do
                    values[values_offset + 1] = math.cos(phase)
                    values_offset = (values_offset + 1) % 90
                    phase = phase + 0.1 * values_offset
                    refresh_time = refresh_time + 1 / 60
                end

                do
                    local average = 0.0
                    for n = 1, 90 do
                        average = average + values[n]
                    end
                    average = average / 90

                    local overlay = string.format("avg %.6f", average)
                    ImGui.PlotLines("Lines", values, 90, values_offset, overlay, -1.0, 1.0, ImVec2(0, 90.0))
                end

                ImGui.PopFont()
            ImGui.End()
        end

        ImGui.EndFrame()

        ImGui.Render()

        ImGui_ImplGMOD.RenderDrawData(ImGui.GetDrawData())

        if bit.band(io.ConfigFlags, ImGuiConfigFlags_ViewportsEnable) ~= 0 then
            ImGui.UpdatePlatformWindows()
            ImGui.RenderPlatformWindowsDefault()
        end
    end
end)