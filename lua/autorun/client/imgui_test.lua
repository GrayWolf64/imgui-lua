--- Temporary testing:
-- won't let users write these complicated stuff in production version

include"imgui.lua"

local ImGui_ImplGMOD = include("imgui_impl_gmod.lua")

local window1_open = {true}
local window2_open = {true}

local g_ModelMatrix = Matrix()
local g_ScaleVector = Vector(1, 1, 1)

concommand.Add("imgui_test", function()
    local viewport = ImGui_ImplGMOD.CreateMainViewport()

    ImGui.CreateContext()
    local g = ImGui.GetCurrentContext()

    ImGui_ImplGMOD.Init(viewport)

    local old_Paint = viewport.Paint
    function viewport.Paint(self, w, h)
        old_Paint(self, w, h)

        local offset_x, offset_y = self:GetPos()
        local old_w, old_h = ScrW(), ScrH()

        -- This scales the things we draw, so later we restore it
        render.SetViewPort(offset_x, offset_y, w, h)

        g_ScaleVector.x = old_w / w
        g_ScaleVector.y = old_h / h
        g_ModelMatrix:Scale(g_ScaleVector)
        cam.PushModelMatrix(g_ModelMatrix)
        g_ModelMatrix:Identity()


        ImGui_ImplGMOD.NewFrame()

        ImGui.NewFrame()

        ImGui.PushFont(nil, 30)

        ImGui.SetNextWindowSize(ImVec2(550, 400), ImGuiCond_FirstUseEver)

        ImGui.Begin("Hello, World!", window1_open)
            ImGui.Text("Lua Memory Usage: %dKb", math.Round(collectgarbage("count")))
            ImGui.Text("FPS: %d", g.IO.Framerate)
        ImGui.End()

        ImGui.PopFont()

        ImGui.SetNextWindowPos(ImVec2(30, 100), ImGuiCond_FirstUseEver)

        ImGui.Begin("ImGui Demo", window2_open)
        ImGui.TextColored(ImVec4(0, 1, 0, 1), "Dear ImGui says %s!", "Hello")
        ImGui.TextColored(ImVec4(1, 0, 1, 1), "ImGui Sincerely")
        ImGui.End()

        ImGui.EndFrame()

        ImGui.Render()

        ImGui_ImplGMOD.RenderDrawData(ImGui.GetDrawData())


        render.SetViewPort(0, 0, old_w, old_h)

        cam.PopModelMatrix()
    end
end)
