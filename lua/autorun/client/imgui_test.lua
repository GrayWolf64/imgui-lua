--- Temporary testing:
-- won't let users write these complicated stuff in production version

include"imgui.lua"

local ImGui_ImplGMOD = include("backends/imgui_impl_gmod.lua")

local function CreateMainViewport()
    local derma_window = vgui.Create("DFrame")

    derma_window:SetSizable(true)
    derma_window:SetSize(ScrW() / 2, ScrH() / 2)
    derma_window:MakePopup()
    derma_window:SetDraggable(true)
    derma_window:Center()
    derma_window:SetTitle("ImGui Example")
    derma_window:SetIcon("icon16/application.png")
    derma_window:SetDeleteOnClose(true)

    local clear_color = ImVec4(0.45, 0.55, 0.60, 1.00) * 255
    local old_Paint = derma_window.Paint
    derma_window.Paint = function(self, w, h)
        old_Paint(self, w, h)
        surface.SetDrawColor(clear_color.x, clear_color.y, clear_color.z, clear_color.w)
        surface.DrawRect(0, 0, w, h)
    end

    return derma_window
end

local window1_open = true
local window2_open = true

concommand.Add("imgui_test", function()
    local animate = true
    local values = {} for i = 1, 90 do values[i] = 0 end
    local values_offset = 0
    local refresh_time = 0
    local phase = 0

    local style_names = {"Dark", "Classic", "Light"}
    local current_style = style_names[1]

    local radio_v = 0

    local function sin(_, i) return math.sin(i * 0.1) end

    local viewport = CreateMainViewport()
    ImGui_ImplGMOD.SetupPanelHooks(viewport, true)

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
            ImGui.SetNextWindowPos(ImVec2(70, 200), ImGuiCond.FirstUseEver)
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
                    ImGui.PlotLines("Lines", values, nil, 90, values_offset, overlay, -1.0, 1.0, ImVec2(0, 80.0))
                    ImGui.PlotHistogram("Sine Saws", sin, nil, 90, nil, nil, -1.0, 1.0, ImVec2(0, 80.0))
                end

                if ImGui.BeginCombo("Colors##Selector", current_style) then
                    for style_idx, style_name in ipairs(style_names) do
                        local pressed, _ = ImGui.Selectable(style_name, style_name == current_style)
                        if pressed then
                            if style_idx == 1 then
                                ImGui.StyleColorsDark()
                            elseif style_idx == 2 then
                                ImGui.StyleColorsClassic()
                            elseif style_idx == 3 then
                                ImGui.StyleColorsLight()
                            end

                            current_style = style_name
                        end
                    end
                    ImGui.EndCombo()
                end

                _, radio_v = ImGui.RadioButton("radio a", radio_v, 0) ImGui.SameLine()
                _, radio_v = ImGui.RadioButton("radio b", radio_v, 1) ImGui.SameLine()
                _, radio_v = ImGui.RadioButton("radio c", radio_v, 2)

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