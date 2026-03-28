--- Temporary testing:
-- won't let users write these complicated stuff in production version

if SERVER then
    AddCSLuaFile"imstb_truetype.lua"
    AddCSLuaFile"imstb_rectpack.lua"
    AddCSLuaFile"imstb_textedit.lua"
    AddCSLuaFile"imgui_h.lua"
    AddCSLuaFile"imgui_internal.lua"
    AddCSLuaFile"imgui_draw.lua"
    AddCSLuaFile"imgui_widgets.lua"
    AddCSLuaFile"imgui.lua"
    AddCSLuaFile"imgui_demo.lua"
    AddCSLuaFile"backends/imgui_impl_gmod.lua"
    resource.AddFile"resource/fonts/ProggyClean.ttf"
else
    include"imgui.lua"

    local ImGui_ImplGMOD = include("backends/imgui_impl_gmod.lua")

    include("imgui_demo.lua")

    local function CreateHostWindow()
        local derma_window = vgui.Create("DFrame")

        derma_window:SetSizable(true)
        derma_window:SetSize(ScrW() / 2, ScrH() / 2)
        derma_window:MakePopup()
        derma_window:SetDraggable(true)
        derma_window:Center()
        derma_window:SetTitle("ImGui Example")
        derma_window:SetIcon("icon16/application.png")
        derma_window:SetDeleteOnClose(true)

        local clear_color = Color(0.45 * 255, 0.55 * 255, 0.60 * 255, 1.00 * 255)
        local titlebar_h = 24
        local padding = 1
        local old_Paint = derma_window.Paint
        derma_window.Paint = function(self, w, h)
            old_Paint(self, w, h)
            draw.RoundedBoxEx(6, padding, padding + titlebar_h, w - 2 * padding, h - titlebar_h - 2 * padding, clear_color, false, false, true, true)
        end

        return derma_window
    end

    local viewport

    concommand.Add("imgui_test", function()
        if IsValid(viewport) then
            return
        end

        viewport = CreateHostWindow()
        ImGui_ImplGMOD.SetupPanelHooks(viewport, true)

        ImGui.CreateContext()
        local g = ImGui.GetCurrentContext()

        local io = ImGui.GetIO()
        io.ConfigFlags = bit.bor(io.ConfigFlags, ImGuiConfigFlags.ViewportsEnable)

        ImGui_ImplGMOD.Init(viewport, true)

        local show_demo_window = true
        local show_another_window = false

        local f = 0.0
        local counter = 0

        function viewport.PaintOver(self, w, h)
            ImGui_ImplGMOD.NewFrame()

            ImGui.NewFrame()

            if show_demo_window then
                show_demo_window = ImGui.ShowDemoWindow(show_demo_window)
            end

            -- Show a simple window that we create ourselves
            do
                ImGui.Begin("Hello, world!")

                ImGui.Text("This is some useful text.")
                _, show_demo_window = ImGui.Checkbox("Demo Window", show_demo_window)
                _, show_another_window = ImGui.Checkbox("Another Window", show_another_window)

                if ImGui.Button("Button") then
                    counter = counter + 1
                end
                ImGui.SameLine()
                ImGui.Text("counter = %d", counter)

                ImGui.Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / io.Framerate, io.Framerate)

                ImGui.End()
            end

            ImGui.EndFrame()

            ImGui.Render()

            ImGui_ImplGMOD.RenderDrawData(ImGui.GetDrawData())

            if bit.band(io.ConfigFlags, ImGuiConfigFlags.ViewportsEnable) ~= 0 then
                ImGui.UpdatePlatformWindows()
                ImGui.RenderPlatformWindowsDefault()
            end
        end
    end)
end
