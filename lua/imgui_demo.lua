--- ImGui Sincerely WIP
-- (Demo Code)

local IM_MIN = math.min
local IM_MAX = math.max
local function IM_CLAMP(V, MN, MX) return (V < MN) and MN or (V > MX) and MX or V end

--- @class ExampleImageViewerData

--- @return ExampleImageViewerData
--- @nodiscard
local function ExampleImageViewerData()
    return {
        ImageBgColor = IM_COL32(100, 100, 100, 255),
        GridColor    = IM_COL32(255, 255, 255, 100),
        GridEnabled  = true,
        ViewReset    = true,
        ViewOffset   = ImVec2(0, 0),
        Zoom         = 10.0,
        ZoomMin      = 1.0,
        ZoomMax      = 10000.0
    }
end

--- @param data ExampleImageViewerData
local function ExampleImageViewer_DrawOptions(data)
    ImGui.SetNextItemShortcut(ImGuiKey.G, ImGuiInputFlags.Tooltip)
    _, data.GridEnabled = ImGui.Checkbox("Grid", data.GridEnabled)
    ImGui.SameLine()
    ImGui.SetNextItemWidth(ImGui.GetFontSize() * 10.0)
    local zoom_100 = data.Zoom * 100.0
    local changed
    zoom_100, changed = ImGui.DragFloat("##Zoom", zoom_100, 5.0, data.ZoomMin * 100.0, data.ZoomMax * 100.0, "%.0f%%", ImGuiSliderFlags.AlwaysClamp)
    if changed then
        data.Zoom = zoom_100 / 100.0
    end
end

--- @param data          ExampleImageViewerData
--- @param canvas_size   ImVec2
--- @param image_tex_ref ImTextureRef
--- @param image_w       int
--- @param image_h       int
local function ExampleImageViewer_DrawCanvas(data, canvas_size, image_tex_ref, image_w, image_h)
    local io = ImGui.GetIO()
    local platform_io = ImGui.GetPlatformIO()
    local draw_list = ImGui.GetWindowDrawList()
    IM_ASSERT(canvas_size.x >= 0.0 and canvas_size.y >= 0.0)

    ImGui.InvisibleButton("##Canvas", canvas_size)
    local canvas_min = ImGui.GetItemRectMin()
    local canvas_max = ImGui.GetItemRectMax()

    if data.ViewReset then
        data.ViewOffset = ImVec2((canvas_size.x * 0.5 / data.Zoom) - 0.5, (canvas_size.y * 0.5 / data.Zoom) - 0.5)
    end
    data.ViewReset = false

    if ImGui.SetItemKeyOwner(ImGuiKey.MouseWheelY) then
        if io.MouseWheel ~= 0.0 then
            data.Zoom = IM_CLAMP(data.Zoom * (1.0 + io.MouseWheel * 0.10), data.ZoomMin, data.ZoomMax)
        end
    end
    local zoom = data.Zoom
    if ImGui.IsItemActive() and ImGui.IsMouseDragging(0) then
        data.ViewOffset.x = data.ViewOffset.x - io.MouseDelta.x / zoom
        data.ViewOffset.y = data.ViewOffset.y - io.MouseDelta.y / zoom
    end

    local image_min = ImVec2(); local image_max = ImVec2()
    image_min.x = math.floor((canvas_min.x - (data.ViewOffset.x * zoom)) + (canvas_size.x * 0.5))
    image_min.y = math.floor((canvas_min.y - (data.ViewOffset.y * zoom)) + (canvas_size.y * 0.5))
    image_max.x = image_min.x + image_w * zoom
    image_max.y = image_min.y + image_h * zoom

    draw_list:AddRect(ImVec2(canvas_min.x - 1.0, canvas_min.y - 1.0), ImVec2(canvas_max.x + 1.0, canvas_max.y + 1.0), IM_COL32(255, 255, 255, 255))
    draw_list:PushClipRect(canvas_min, canvas_max, true)
    draw_list:AddRectFilled(image_min, image_max, data.ImageBgColor)
    if platform_io.DrawCallback_SetSamplerNearest ~= nil then
        draw_list:AddCallback(platform_io.DrawCallback_SetSamplerNearest)
    end
    draw_list:AddImage(image_tex_ref, image_min, image_max)
    if platform_io.DrawCallback_SetSamplerLinear ~= nil then
        draw_list:AddCallback(ImGui.GetPlatformIO().DrawCallback_SetSamplerLinear)
    end

    if data.GridEnabled and zoom > 6.0 then
        local step = zoom
        for px = math.floor((canvas_min.x - image_min.x) / step), math.floor((canvas_max.x - image_min.x) / step) do
            draw_list:AddLineV(image_min.x + px * step, canvas_min.y, canvas_max.y, data.GridColor, 1.0)
        end
        for py = math.floor((canvas_min.y - image_min.y) / step), math.floor((canvas_max.y - image_min.y) / step) do
            draw_list:AddLineH(canvas_min.x, canvas_max.x, image_min.y + py * step, data.GridColor, 1.0)
        end
    end
    draw_list:PopClipRect()
end

local function ShowExampleMenuFile()
    ImGui.MenuItem("(demo menu)", nil, false, false)
    if ImGui.MenuItem("New") then end
    if ImGui.MenuItem("Open", "Ctrl+O") then end
    if ImGui.BeginMenu("Open Recent") then
        ImGui.MenuItem("fish_hat.c")
        ImGui.MenuItem("fish_hat.inl")
        ImGui.MenuItem("fish_hat.h")
        if ImGui.BeginMenu("More..") then
            ImGui.MenuItem("Hello")
            ImGui.MenuItem("Sailor")
            if ImGui.BeginMenu("Recurse..") then
                ShowExampleMenuFile()
                ImGui.EndMenu()
            end
            ImGui.EndMenu()
        end
        ImGui.EndMenu()
    end
    if ImGui.MenuItem("Save", "Ctrl+S") then end
    if ImGui.MenuItem("Save As..") then end
end

local function DemoWindowMenuBar()
    if ImGui.BeginMenuBar() then
        if ImGui.BeginMenu("Menu") then
            ShowExampleMenuFile()
            ImGui.EndMenu()
        end
        if ImGui.BeginMenu("Examples") then
            ImGui.EndMenu()
        end

        ImGui.EndMenuBar()
    end
end

local DemoWindowWidgetsBasic
do

local clicked = 0
local checked = true
local radio_v = 0

local col0 = ImVec4(0, 0, 0, 1)
local col1 = ImVec4(0, 0, 0, 1)
local col2 = ImVec4(0, 0, 0, 1)

local counter = 0

local str0 = {string.byte("Hello, World!", 1, 13)}
table.insert(str0, 0)

local str1 = {}
str1[1] = 0

local hint0 = {string.byte("enter text here", 1, 15)}
table.insert(hint0, 0)

local i0 = 233

function DemoWindowWidgetsBasic()
    if ImGui.TreeNode("Basic") then
        ImGui.SeparatorText("General")

        if ImGui.Button("Button") then
            clicked = clicked + 1
        end

        if clicked % 2 ~= 0 then
            ImGui.SameLine()
            ImGui.Text("Thanks for clicking me!")
        end

        _, check = ImGui.Checkbox("checkbox", check)

        _, radio_v = ImGui.RadioButton("radio a", radio_v, 0) ImGui.SameLine()
        _, radio_v = ImGui.RadioButton("radio b", radio_v, 1) ImGui.SameLine()
        _, radio_v = ImGui.RadioButton("radio c", radio_v, 2)

        ImGui.AlignTextToFramePadding()
        ImGui.TextLinkOpenURL("Hyperlink", "https://github.com/GrayWolf64/imgui-lua")

        for i = 1, 7 do
            if i > 1 then
                ImGui.SameLine()
            end
            ImGui.PushID(i)

            col0.x, col0.y, col0.z = ImGui.ColorConvertHSVtoRGB(i / 7.0, 0.6, 0.6)
            col1.x, col1.y, col1.z = ImGui.ColorConvertHSVtoRGB(i / 7.0, 0.7, 0.7)
            col2.x, col2.y, col2.z = ImGui.ColorConvertHSVtoRGB(i / 7.0, 0.8, 0.8)
            ImGui.PushStyleColor(ImGuiCol.Button, col0)
            ImGui.PushStyleColor(ImGuiCol.ButtonHovered, col1)
            ImGui.PushStyleColor(ImGuiCol.ButtonActive, col2)

            ImGui.Button("Click")

            ImGui.PopStyleColor(3)
            ImGui.PopID()
        end

        -- Use AlignTextToFramePadding() to align text baseline to the baseline of framed widgets elements
        -- (otherwise a Text+SameLine+Button sequence will have the text a little too high by default!)
        -- See 'Demo->Layout->Text Baseline Alignment' for details.
        ImGui.AlignTextToFramePadding()
        ImGui.Text("Hold to repeat:")
        ImGui.SameLine()

        -- Arrow buttons with Repeater
        local spacing = ImGui.GetStyle().ItemInnerSpacing.x
        ImGui.PushItemFlag(ImGuiItemFlags.ButtonRepeat, true)
        if ImGui.ArrowButton("##left", ImGuiDir.Left) then counter = counter - 1 end
        ImGui.SameLine(0.0, spacing)
        if ImGui.ArrowButton("##right", ImGuiDir.Right) then counter = counter + 1 end
        ImGui.PopItemFlag()
        ImGui.SameLine()
        ImGui.Text("%d", counter)

        ImGui.Button("Tooltip")
        ImGui.SetItemTooltip("I am a tooltip")

        ImGui.LabelText("label", "Value")

        ImGui.SeparatorText("Inputs")

        do
            ImGui.InputText("input text", str0, 128)

            ImGui.InputTextWithHint("input text (w/ hint)", hint0, str1, 128)

            i0 = ImGui.InputInt("input int", i0)
            -- TODO:
        end

        ImGui.TreePop()
    end
end

end

local function DemoWindowWidgetsBullets()
    if ImGui.TreeNode("Bullets") then
        ImGui.BulletText("Bullet point 1")
        ImGui.BulletText("Bullet point 2\nOn multiple lines")
        if ImGui.TreeNode("Tree node") then
            ImGui.BulletText("Another bullet point")
            ImGui.TreePop()
        end
        ImGui.Bullet() ImGui.Text("Bullet point 3 (two calls)")
        ImGui.Bullet() ImGui.SmallButton("Button")
        ImGui.TreePop()
    end
end

local DemoWindowWidgetsColorAndPickers
do

local color = {114.0 / 255.0, 144.0 / 255.0, 154.0 / 255.0, 200.0 / 255.0}
local base_flags = ImGuiColorEditFlags.None

local ref_color = false
local ref_color_v = {1.0, 0.0, 1.0, 0.5}
local picker_mode = 0
local display_mode = 0
local color_picker_flags = ImGuiColorEditFlags.AlphaBar
local picker_mode_names = {"Auto/Current", "ImGuiColorEditFlags.PickerHueBar", "ImGuiColorEditFlags.PickerHueWheel"}
local display_mode_names = {"Auto/Current", "ImGuiColorEditFlags.NoInputs", "ImGuiColorEditFlags.DisplayRGB", "ImGuiColorEditFlags.DisplayHSV", "ImGuiColorEditFlags.DisplayHex"}

function DemoWindowWidgetsColorAndPickers()
    if ImGui.TreeNode("Color/Picker Widgets") then
        ImGui.SeparatorText("Options")

        _, base_flags = ImGui.CheckboxFlags("ImGuiColorEditFlags.NoAlpha", base_flags, ImGuiColorEditFlags.NoAlpha)
        _, base_flags = ImGui.CheckboxFlags("ImGuiColorEditFlags.AlphaOpaque", base_flags, ImGuiColorEditFlags.AlphaOpaque)
        _, base_flags = ImGui.CheckboxFlags("ImGuiColorEditFlags.AlphaNoBg", base_flags, ImGuiColorEditFlags.AlphaNoBg)
        _, base_flags = ImGui.CheckboxFlags("ImGuiColorEditFlags.AlphaPreviewHalf", base_flags, ImGuiColorEditFlags.AlphaPreviewHalf)
        _, base_flags = ImGui.CheckboxFlags("ImGuiColorEditFlags.NoOptions", base_flags, ImGuiColorEditFlags.NoOptions)
        _, base_flags = ImGui.CheckboxFlags("ImGuiColorEditFlags.NoDragDrop", base_flags, ImGuiColorEditFlags.NoDragDrop)
        _, base_flags = ImGui.CheckboxFlags("ImGuiColorEditFlags.NoColorMarkers", base_flags, ImGuiColorEditFlags.NoColorMarkers)
        _, base_flags = ImGui.CheckboxFlags("ImGuiColorEditFlags.HDR", base_flags, ImGuiColorEditFlags.HDR)

        ImGui.SeparatorText("Color picker")

        ImGui.PushID("Color picker")
        _, color_picker_flags = ImGui.CheckboxFlags("ImGuiColorEditFlags.NoAlpha", color_picker_flags, ImGuiColorEditFlags.NoAlpha)
        _, color_picker_flags = ImGui.CheckboxFlags("ImGuiColorEditFlags.AlphaBar", color_picker_flags, ImGuiColorEditFlags.AlphaBar)
        _, color_picker_flags = ImGui.CheckboxFlags("ImGuiColorEditFlags.NoSidePreview", color_picker_flags, ImGuiColorEditFlags.NoSidePreview)

        if bit.band(color_picker_flags, ImGuiColorEditFlags.NoSidePreview) ~= 0 then
            ImGui.SameLine()
            _, ref_color = ImGui.Checkbox("With Ref Color", ref_color)
            if ref_color then
                ImGui.SameLine()
                ImGui.ColorEdit4("##RefColor", ref_color_v, bit.bor(ImGuiColorEditFlags.NoInputs, base_flags))
            end
        end

        if ImGui.BeginCombo("Picker Mode", picker_mode_names[picker_mode + 1], ImGuiComboFlags.None) then
            for mode_idx, mode_name in ipairs(picker_mode_names) do
                local pressed = ImGui.Selectable(mode_name, mode_idx == picker_mode + 1)
                if pressed then
                    picker_mode = mode_idx - 1
                end
            end
            ImGui.EndCombo()
        end

        if ImGui.BeginCombo("Display Mode", display_mode_names[display_mode + 1], ImGuiComboFlags.None) then
            for mode_idx, mode_name in ipairs(display_mode_names) do
                local pressed = ImGui.Selectable(mode_name, mode_idx == display_mode + 1)
                if pressed then
                    display_mode = mode_idx - 1
                end
            end
            ImGui.EndCombo()
        end

        local flags = bit.bor(base_flags, color_picker_flags)
        if picker_mode == 1 then flags = bit.bor(flags, ImGuiColorEditFlags.PickerHueBar) end
        if picker_mode == 2 then flags = bit.bor(flags, ImGuiColorEditFlags.PickerHueWheel) end
        if display_mode == 1 then flags = bit.bor(flags, ImGuiColorEditFlags.NoInputs) end   -- Disable all RGB/HSV/Hex displays
        if display_mode == 2 then flags = bit.bor(flags, ImGuiColorEditFlags.DisplayRGB) end -- Override display mode
        if display_mode == 3 then flags = bit.bor(flags, ImGuiColorEditFlags.DisplayHSV) end
        if display_mode == 4 then flags = bit.bor(flags, ImGuiColorEditFlags.DisplayHex) end

        ImGui.ColorPicker4("MyColor##4", color, flags, ref_color and ref_color_v or nil)

        ImGui.TreePop()
    end
end

end

local DemoWindowWidgetsImages do

local pressed_count = 0

local image_viewer = ExampleImageViewerData()

function DemoWindowWidgetsImages()
    if ImGui.TreeNode("Images") then
        ImGui.TextWrapped(
            "Below we are displaying the font texture (which is the only texture we have access to in this demo). " ..
            "Use the 'ImTextureID' type as storage to pass pointers or identifier to your own texture data. " ..
            "Hover the texture for a zoomed view!"
        )

        -- Grab the current texture identifier used by the font atlas
        local io = ImGui.GetIO()

        local atlas = io.Fonts
        local my_tex_id = atlas.TexRef
        local my_tex_w = atlas.TexData.Width
        local my_tex_h = atlas.TexData.Height
        ImGui.Text("%.0fx%.0f", my_tex_w, my_tex_h)

        ImGui.SeparatorText("Image()/ImageWithBg() function")
        local uv_min = ImVec2(0.0, 0.0)
        local uv_max = ImVec2(1.0, 1.0)
        ImGui.PushStyleVar(ImGuiStyleVar.ImageBorderSize, IM_MAX(1.0, ImGui.GetStyle().ImageBorderSize))
        ImGui.ImageWithBg(my_tex_id, ImVec2(my_tex_w, my_tex_h), uv_min, uv_max, ImVec4(0.0, 0.0, 0.0, 1.0))
        ImGui.PopStyleVar()

        -- Fancy widget
        ImGui.SeparatorText("Interactive Image Viewer")

        local canvas_size = ImVec2(ImGui.GetContentRegionAvail().x, my_tex_h * 2.0)
        ExampleImageViewer_DrawOptions(image_viewer)
        ExampleImageViewer_DrawCanvas(image_viewer, canvas_size, my_tex_id, my_tex_w, my_tex_h)

        ImGui.SeparatorText("Textured Buttons")

        ImGui.TextWrapped("And now some textured buttons..")
        for i = 1, 8 do
            -- UV coordinates are often (0.0f, 0.0f) and (1.0f, 1.0f) to display an entire textures.
            -- Here are trying to display only a 32x32 pixels area of the texture, hence the UV computation.
            ImGui.PushID(i)
            if i > 1 then
                ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, ImVec2(i, i))
            end

            local size = ImVec2(32.0, 32.0) -- Size of the image we want to make visible
            local uv0 = ImVec2(0.0, 0.0) -- UV coordinates for lower-left
            local uv1 = ImVec2(32.0 / my_tex_w, 32.0 / my_tex_h) -- UV coordinates for (32,32) in our texture
            local bg_col = ImVec4(0.0, 0.0, 0.0, 1.0) -- Black background
            local tint_col = ImVec4(1.0, 1.0, 1.0, 1.0) -- No tint

            if ImGui.ImageButton("", my_tex_id, size, uv0, uv1, bg_col, tint_col) then
                pressed_count = pressed_count + 1
            end

            if i > 1 then
                ImGui.PopStyleVar()
            end

            ImGui.PopID()
            ImGui.SameLine()
        end

        ImGui.NewLine()
        ImGui.Text("Pressed %d times.", pressed_count)

        ImGui.TreePop()
    end
end

end

local DemoWindowWidgetsPlotting
do

local animate = true
local arr = { 0.6, 0.1, 1.0, 0.5, 0.92, 0.1, 0.2 }

local values_sz = 90
local values = {} for i = 1, values_sz do values[i] = 0 end
local values_offset = 0
local refresh_time = 0.0
local phase = 0.0

function DemoWindowWidgetsPlotting()
    if ImGui.TreeNode("Plotting") then
        _, animate = ImGui.Checkbox("Animate", animate)

        -- Plot as lines and plot as histogram
        ImGui.PlotLines("Frame Times", arr, nil, #arr)
        ImGui.PlotHistogram("Histogram", arr, nil, #arr, 0, nil, 0.0, 1.0, ImVec2(0, 80.0))

        if not animate or refresh_time == 0.0 then
            refresh_time = ImGui.GetTime()
        end
        while refresh_time < ImGui.GetTime() do -- Create data at fixed 60 Hz rate for the demo
            values[values_offset + 1] = math.cos(phase)
            values_offset = (values_offset + 1) % values_sz
            phase = phase + 0.10 * values_offset
            refresh_time = refresh_time + 1.0 / 60.0
        end

        -- Plots can display overlay texts
        -- (in this example, we will display an average value)
        do
            local average = 0.0
            for i = 1, values_sz do
                average = average + values[i]
            end
            average = average / values_sz
            local overlay = string.format("avg %f", average)
            ImGui.PlotLines("Lines", values, nil, values_sz, values_offset, overlay, -1.0, 1.0, ImVec2(0, 80.0))
        end

        ImGui.TreePop()
    end
end

end

local DemoWindowWidgetsProgressBars do

local progress_accum = 0.0
local progress_dir = 1.0

function DemoWindowWidgetsProgressBars()
    if ImGui.TreeNode("Progress Bars") then
        -- Animate a simple progress bar
        progress_accum = progress_accum + progress_dir * 0.4 * ImGui.GetIO().DeltaTime
        if progress_accum >= 1.1 then
            progress_accum = 1.1
            progress_dir = progress_dir * -1.0
        end

        if progress_accum <= -0.1 then
            progress_accum = -0.1
            progress_dir = progress_dir * -1.0
        end

        local progress = IM_CLAMP(progress_accum, 0.0, 1.0)

        -- Typically we would use ImVec2(-1.0,0.0) or ImVec2(-math.huge,0.0) to use all available width,
        -- or ImVec2(width,0.0) for a specified width. ImVec2(0.0,0.0) uses ItemWidth
        ImGui.ProgressBar(progress, ImVec2(0.0, 0.0))
        ImGui.SameLine(0.0, ImGui.GetStyle().ItemInnerSpacing.x)
        ImGui.Text("Progress Bar")

        local buf = string.format("%d/%d", math.floor(progress * 1753), 1753)
        ImGui.ProgressBar(progress, ImVec2(0.0, 0.0), buf)

        -- Pass an animated negative value, e.g. -1.0 * ImGui.GetTime() is the recommended value
        -- Adjust the factor if you want to adjust the animation speed
        ImGui.ProgressBar(-1.0 * ImGui.GetTime(), ImVec2(0.0, 0.0), "Searching..")
        ImGui.SameLine(0.0, ImGui.GetStyle().ItemInnerSpacing.x)
        ImGui.Text("Indeterminate")

        ImGui.TreePop()
    end
end

end

local no_menu = false

local function DemoWindowWidgets()
    if not ImGui.CollapsingHeader("Widgets") then
        return
    end

    DemoWindowWidgetsBasic()
    DemoWindowWidgetsBullets()
    DemoWindowWidgetsColorAndPickers()
    DemoWindowWidgetsImages()
    DemoWindowWidgetsPlotting()
    DemoWindowWidgetsProgressBars()
end

local function DemoWindowLayout()
    if not ImGui.CollapsingHeader("Layout & Scrolling") then
        return
    end

end

local function DemoWindowPopups()
    if not ImGui.CollapsingHeader("Popups & Modal windows") then
        return
    end

end

local function DemoWindowTables()
    if not ImGui.CollapsingHeader("Tables & Columns") then
        return
    end

end

local function DemoWindowInputs()
    if not ImGui.CollapsingHeader("Inputs & Focus") then
        return
    end

end

local function ShowExampleAppImageViewer()
    -- TODO:
end

function ImGui.ShowDemoWindow(open)
    local window_flags = 0

    if not no_menu then window_flags = bit.bor(window_flags, ImGuiWindowFlags.MenuBar) end

    open = ImGui.Begin("ImGui Sincerely Demo", open, window_flags)
    if not open then
        ImGui.End()
        return open
    end

    local label_width_base = ImGui.GetFontSize() * 12
    local label_width_max = ImGui.GetContentRegionAvail().x * 0.40
    local label_width = IM_MIN(label_width_base, label_width_max)
    ImGui.PushItemWidth(-label_width)

    DemoWindowMenuBar()

    if ImGui.CollapsingHeader("Help") then
        ImGui.SeparatorText("ABOUT THIS DEMO:")
    end

    if ImGui.CollapsingHeader("Configuration") then
        
    end

    if ImGui.CollapsingHeader("Window Options") then
        
    end

    DemoWindowWidgets()
    DemoWindowLayout()
    DemoWindowPopups()
    DemoWindowTables()
    DemoWindowInputs()

    ImGui.End()

    return open
end
