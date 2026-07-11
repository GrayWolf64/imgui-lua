--- Temporary testing:
-- won't let users write these complicated stuff in production version

if SERVER then
    AddCSLuaFile"imstd_minstdio.lua"
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
    resource.AddFile"resource/fonts/ProggyForever.ttf"
else
    include"imgui.lua"

    --- @module "backends.imgui_impl_gmod"
    local ImGui_ImplGMOD = include("backends/imgui_impl_gmod.lua")

    include("imgui_demo.lua")

    local main_scale = 2.0
    local window
    concommand.Add("imgui_test", function()
        if IsValid(window) then
            return
        end

        window = vgui.Create("DFrame")
        window:SetSizable(true)
        window:SetDraggable(true)
        window:SetSize(ScrW() / 2, ScrH() / 2)
        window:MakePopup()
        window:Center()
        window:SetTitle(string.format("ImGui Sincerely GMod(DXLevel=%d) Example", render.GetDXLevel()))
        window:SetIcon("icon16/application.png")
        window:SetDeleteOnClose(true)

        local clear_color = ImVec4(0.45, 0.55, 0.60, 1.00)

        local left, top, right, bottom = window:GetDockPadding()
        local old_Paint = window.Paint
        window.Paint = function(self, w, h)
            old_Paint(self, w, h)
            draw.RoundedBoxEx(4, left, top, w - (left + right), h - (top + bottom), Color(clear_color.x * 255, clear_color.y * 255, clear_color.z * 255, clear_color.w * 255), false, false, true, true)
        end

        ImGui_ImplGMOD.SetupPanelHooks(window, true)

        ImGui.CreateContext()

        local io = ImGui.GetIO()
        io.ConfigFlags = bit.bor(io.ConfigFlags, ImGuiConfigFlags.ViewportsEnable)

        local style = ImGui.GetStyle()
        style:ScaleAllSizes(main_scale)
        style.FontScaleDpi = main_scale

        ImGui_ImplGMOD.Init(window, true)

        local show_demo_window = true
        local show_another_window = false

        local f = 0.0
        local counter = 0

        -- update
        local function main_logic()
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

                f = ImGui.SliderFloat("float", f, 0.0, 1.0)
                ImGui.ColorEdit3("clear color", clear_color)

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
        end

        -- render!
        local function main_render()
            ImGui_ImplGMOD.RenderDrawData(ImGui.GetDrawData())

            if bit.band(io.ConfigFlags, ImGuiConfigFlags.ViewportsEnable) ~= 0 then
                ImGui.UpdatePlatformWindows()
                ImGui.RenderPlatformWindowsDefault()
            end
        end

        local function on_removal()
            ImGui_ImplGMOD.Shutdown()
            ImGui.DestroyContext()
        end

        ImGui_ImplGMOD.VGUI_Hook(window, "Think", main_logic)
        ImGui_ImplGMOD.VGUI_Hook(window, "PaintOver", main_render)
        ImGui_ImplGMOD.VGUI_Hook(window, "OnRemove", on_removal)
    end)
end
