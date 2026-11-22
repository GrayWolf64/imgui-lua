--- ImGui Sincerely WIP
-- (Demo Code)

-- NOTE: Make sure to use fields with different names inside `static`!

local IM_MIN = math.min
local IM_MAX = math.max
local function IM_CLAMP(V, MN, MX) return (V < MN) and MN or (V > MX) and MX or V end

--- @param desc string
local function HelpMarker(desc)
    ImGui.TextDisabled("(?)")
    if ImGui.BeginItemTooltip() then
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 35.0)
        ImGui.TextUnformatted(desc)
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
end
-- TODO: ImColor helpers?

--- @class ImGuiDemoWindowData

--- @return ImGuiDemoWindowData
--- @nodiscard
local function ImGuiDemoWindowData()
    return {
        ShowAppCustomRendering = false,
        ShowAppImageViewer = false,
        ShowAppFullscreen = false,
        ShowAppLongText = false,

        ShowMetrics = false,
        ShowStyleEditor = false,
    }
end

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
    image_max.x = math.floor(image_min.x + image_w * zoom)
    image_max.y = math.floor(image_min.y + image_h * zoom)

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

local function DemoWindowMenuBar(demo_data)
    if ImGui.BeginMenuBar() then
        if ImGui.BeginMenu("Menu") then
            ShowExampleMenuFile()
            ImGui.EndMenu()
        end
        if ImGui.BeginMenu("Examples") then
            ImGui.SeparatorText("Concepts")
            _, demo_data.ShowAppCustomRendering = ImGui.MenuItem("Custom rendering", nil, demo_data.ShowAppCustomRendering)
            _, demo_data.ShowAppImageViewer = ImGui.MenuItem("Image viewer", nil, demo_data.ShowAppImageViewer)
            _, demo_data.ShowAppFullscreen = ImGui.MenuItem("Fullscreen window", nil, demo_data.ShowAppFullscreen)
            _, demo_data.ShowAppLongText = ImGui.MenuItem("Long text display", nil, demo_data.ShowAppLongText)

            ImGui.EndMenu()
        end
        if ImGui.BeginMenu("Tools") then

local has_debug_tools = false
if not IMGUI_DISABLE_DEBUG_TOOLS then
    has_debug_tools = true
end

            _, demo_data.ShowMetrics = ImGui.MenuItem("Metrics/Debugger", nil, demo_data.ShowMetrics, has_debug_tools)
            _, demo_data.ShowStyleEditor = ImGui.MenuItem("Style Editor", nil, demo_data.ShowStyleEditor)

            ImGui.EndMenu()
        end

        ImGui.EndMenuBar()
    end
end

local DemoWindowWidgetsBasic
do

local static = {}

local clicked = 0
local checked = true
local radio_v = 0

local col0 = ImVec4(0, 0, 0, 1)
local col1 = ImVec4(0, 0, 0, 1)
local col2 = ImVec4(0, 0, 0, 1)
local col3 = ImVec4(1, 1, 1, 1)

local counter = 0

local str0 = {string.byte("Hello, World!", 1, 13)}
table.insert(str0, 0)

local str1 = {}
str1[1] = 0

local hint0 = {string.byte("enter text here", 1, 15)}
table.insert(hint0, 0)

local vec4a = { 0.10, 0.20, 0.30, 0.44 }

local Element = { Fire = 1, Earth = 2, Air = 3, Water = 4, COUNT = 5 }
local elems_names = { "Fire", "Earth", "Air", "Water" }

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
            ImGui.PushStyleColor(ImGuiCol.Text, col3)

            ImGui.Button("Click")

            ImGui.PopStyleColor(4)
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

            if not static.i0 then static.i0 = 233 end
            static.i0 = ImGui.InputInt("input int", static.i0)

            if not static.f0 then static.f0 = 0.001 end
            static.f0 = ImGui.InputFloat("input float", static.f0, 0.01, 1.0)

            if not static.d0 then static.d0 = 999999.00000001 end
            static.d0 = ImGui.InputDouble("input double", static.d0, 0.01, 1.0, "%.8f")
            -- TODO:

            ImGui.InputFloat3("input float3", vec4a)
        end

        ImGui.SeparatorText("Drags")

        do
            if not static.i1 then static.i1 = 50  end
            if not static.i2 then static.i2 = 42  end
            if not static.i3 then static.i3 = 128 end
            static.i1 = ImGui.DragInt("drag int", static.i1, 1)
            static.i2 = ImGui.DragInt("drag int 0..100", static.i2, 1, 0, 100, "%d%%", ImGuiSliderFlags.AlwaysClamp)
            static.i3 = ImGui.DragInt("drag int wrap 100..200", static.i3, 1, 100, 200, "%d", ImGuiSliderFlags.WrapAround)

            if not static.f1 then static.f1 = 1.00   end
            if not static.f2 then static.f2 = 0.0067 end
            static.f1 = ImGui.DragFloat("drag float", static.f1, 0.005)
            static.f2 = ImGui.DragFloat("drag small float", static.f2, 0.0001, 0.0, 0.0, "%.06f ns")
        end

        ImGui.SeparatorText("Sliders")

        do
            if not static.f01 then static.f01 = 0.123 end
            if not static.f02 then static.f02 = 0.0   end
            static.f01 = ImGui.SliderFloat("slider float", static.f01, 0.0, 1.0, "ratio = %.3f")
            static.f02 = ImGui.SliderFloat("slider float (log)", static.f02, -10.0, 10.0, "%.4f", ImGuiSliderFlags.Logarithmic)

            if not static.angle then static.angle = 0.0 end
            static.angle = ImGui.SliderAngle("slider angle", static.angle)

            if not static.elem then static.elem = Element.Fire end
            local elem_name = (static.elem >= 1 and static.elem < Element.COUNT) and elems_names[static.elem] or "Unknown"
            static.elem = ImGui.SliderInt("slider enum", static.elem, 1, Element.COUNT - 1, elem_name)
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

        ImGui.SeparatorText("Inline color editor")
        ImGui.Text("Color widget:")
        ImGui.ColorEdit3("MyColor##1", color, base_flags)

        ImGui.Text("Color widget HSV with Alpha:")
        ImGui.ColorEdit4("MyColor##2", color, bit.bor(ImGuiColorEditFlags.DisplayHSV, base_flags))

        ImGui.Text("Color widget with Float Display:")
        ImGui.ColorEdit4("MyColor##2f", color, bit.bor(ImGuiColorEditFlags.Float, base_flags))

        ImGui.Text("Color button with Picker:")
        ImGui.ColorEdit4("MyColor##3", color, bit.bor(ImGuiColorEditFlags.NoInputs, ImGuiColorEditFlags.NoLabel, base_flags))

        -- TODO:

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
        _, color_picker_flags = ImGui.CheckboxFlags("ImGuiColorEditFlags.PickerNoRotate", color_picker_flags, ImGuiColorEditFlags.PickerNoRotate)

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

local function DemoWindowWidgetsLiveEdit()
    -- TODO:
end

local DemoWindowWidgetsMixedValues do

local use_liveedit = false
local items = { 12.0, 0.0, 0.0 }

function DemoWindowWidgetsMixedValues()
    if ImGui.TreeNode("Mixed Values") then
        local item_ref = 1
        local is_mixed = items[item_ref] ~= items[2] or items[item_ref] ~= items[3]
        _, use_liveedit = ImGui.Checkbox("ImGuiItemFlags.LiveEditOnInput", use_liveedit)

        ImGui.SeparatorText("Scalar/Text Widgets")
        ImGui.PushItemFlag(ImGuiItemFlags.LiveEditOnInput, use_liveedit)
        ImGui.PushItemFlag(ImGuiItemFlags.MixedValue, is_mixed)
        local edited, changed
        items[item_ref], changed = ImGui.DragFloat("DragFloat", items[item_ref])
        edited = changed
        items[item_ref], changed = ImGui.SliderFloat("SliderFloat", items[item_ref], 0.0, 100.0)
        edited = edited or changed
        items[item_ref], changed = ImGui.InputFloat("InputFloat", items[item_ref], 1.0)
        edited = edited or changed
        if edited then
            for i = 1, 3 do
                if i ~= item_ref then
                    items[i] = items[item_ref]
                end
            end
        end
        ImGui.PopItemFlag()

        ImGui.Text("Underlying data:")
        items[1] = ImGui.InputFloat("item 0 (ref)", items[1])
        items[2] = ImGui.InputFloat("item 1", items[2])
        items[3] = ImGui.InputFloat("item 2", items[3])
        ImGui.PopItemFlag()

        ImGui.SeparatorText("Others Widgets")
        ImGui.Text("(note: edits are not applied in this demo)")
        local b_on, b_off = true, false
        _, b_on = ImGui.Checkbox("Checkbox On", b_on)
        _, b_off = ImGui.Checkbox("Checkbox Off", b_off)
        ImGui.PushItemFlag(ImGuiItemFlags.MixedValue, true)
        _, b_off = ImGui.Checkbox("Checkbox Mixed", b_off)
        ImGui.RadioButtonEx("RadioButton Mixed", true)
        ImGui.SameLine()
        ImGui.RadioButtonEx("RadioButton Mixed##2", true)
        local color = { 0.5, 0.5, 0.5, 0.5 }
        ImGui.ColorEdit4("ColorEdit4", color)
        ImGui.PopItemFlag()

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

        local plot_sz = ImVec2(0.0, ImGui.GetFrameHeight() * 4.0)

        -- Plot as lines and plot as histogram
        ImGui.PlotLines("Frame Times", arr, nil, #arr)
        ImGui.PlotHistogram("Histogram", arr, nil, #arr, 0, nil, 0.0, 1.0, plot_sz)

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
            ImGui.PlotLines("Lines", values, nil, values_sz, values_offset, overlay, -1.0, 1.0, plot_sz)
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

local DemoWindowWidgetsTabs
do

local function EditTabBarFittingPolicyFlags(flags)
    if bit.band(flags, ImGuiTabBarFlags.FittingPolicyMask_) == 0 then
        flags = bit.bor(flags, ImGuiTabBarFlags.FittingPolicyDefault_)
    end
    local changed
    changed, flags = ImGui.CheckboxFlags("ImGuiTabBarFlags.FittingPolicyMixed", flags, ImGuiTabBarFlags.FittingPolicyMixed)
    if changed then
        flags = bit.band(flags, bit.bnot(bit.bxor(ImGuiTabBarFlags.FittingPolicyMask_, ImGuiTabBarFlags.FittingPolicyMixed)))
    end
    changed, flags = ImGui.CheckboxFlags("ImGuiTabBarFlags.FittingPolicyShrink", flags, ImGuiTabBarFlags.FittingPolicyShrink)
    if changed then
        flags = bit.band(flags, bit.bnot(bit.bxor(ImGuiTabBarFlags.FittingPolicyMask_, ImGuiTabBarFlags.FittingPolicyShrink)))
    end
    changed, flags = ImGui.CheckboxFlags("ImGuiTabBarFlags.FittingPolicyScroll", flags, ImGuiTabBarFlags.FittingPolicyScroll)
    if changed then
        flags = bit.band(flags, bit.bnot(bit.bxor(ImGuiTabBarFlags.FittingPolicyMask_, ImGuiTabBarFlags.FittingPolicyScroll)))
    end
    return flags
end

local tab_bar_flags_advanced = ImGuiTabBarFlags.Reorderable
local names = { "Artichoke", "Beetroot", "Celery", "Daikon" }
local opened = { true, true, true, true }
local active_tabs = ImVector()
local next_tab_id = 0
local show_leading_button = true
local show_trailing_button = true
local show_leading_trailing_tabs = false
local tab_bar_flags_buttons = bit.bor(ImGuiTabBarFlags.AutoSelectNewTabs, ImGuiTabBarFlags.Reorderable, ImGuiTabBarFlags.FittingPolicyMixed)

function DemoWindowWidgetsTabs()
    if ImGui.TreeNode("Tabs") then
        if ImGui.TreeNode("Basic") then
            local tab_bar_flags = ImGuiTabBarFlags.None
            if ImGui.BeginTabBar("MyTabBar", tab_bar_flags) then
                local contents_visible
                _, contents_visible = ImGui.BeginTabItem("Avocado")
                if contents_visible then
                    ImGui.Text("This is the Avocado tab!\nblah blah blah blah blah")
                    ImGui.EndTabItem()
                end
                _, contents_visible = ImGui.BeginTabItem("Broccoli")
                if contents_visible then
                    ImGui.Text("This is the Broccoli tab!\nblah blah blah blah blah")
                    ImGui.EndTabItem()
                end
                _, contents_visible = ImGui.BeginTabItem("Cucumber")
                if contents_visible then
                    ImGui.Text("This is the Cucumber tab!\nblah blah blah blah blah")
                    ImGui.EndTabItem()
                end
                ImGui.EndTabBar()
            end
            ImGui.Separator()
            ImGui.TreePop()
        end

        if ImGui.TreeNode("Advanced & Close Button") then
            _, tab_bar_flags_advanced = ImGui.CheckboxFlags("ImGuiTabBarFlags.Reorderable", tab_bar_flags_advanced, ImGuiTabBarFlags.Reorderable)
            _, tab_bar_flags_advanced = ImGui.CheckboxFlags("ImGuiTabBarFlags.AutoSelectNewTabs", tab_bar_flags_advanced, ImGuiTabBarFlags.AutoSelectNewTabs)
            _, tab_bar_flags_advanced = ImGui.CheckboxFlags("ImGuiTabBarFlags.TabListPopupButton", tab_bar_flags_advanced, ImGuiTabBarFlags.TabListPopupButton)
            _, tab_bar_flags_advanced = ImGui.CheckboxFlags("ImGuiTabBarFlags.NoCloseWithMiddleMouseButton", tab_bar_flags_advanced, ImGuiTabBarFlags.NoCloseWithMiddleMouseButton)
            _, tab_bar_flags_advanced = ImGui.CheckboxFlags("ImGuiTabBarFlags.DrawSelectedOverline", tab_bar_flags_advanced, ImGuiTabBarFlags.DrawSelectedOverline)
            tab_bar_flags_advanced = EditTabBarFittingPolicyFlags(tab_bar_flags_advanced)

            ImGui.AlignTextToFramePadding()
            ImGui.Text("Opened:")
            for n = 1, #opened do
                ImGui.SameLine()
                _, opened[n] = ImGui.Checkbox(names[n], opened[n])
            end

            if ImGui.BeginTabBar("MyTabBar", tab_bar_flags_advanced) then
                for n = 1, #opened do
                    if opened[n] then
                        local contents_visible
                        opened[n], contents_visible = ImGui.BeginTabItem(names[n], opened[n], ImGuiTabItemFlags.None)
                        if contents_visible then
                            ImGui.Text("This is the %s tab!", names[n])
                            if bit.band(n - 1, 1) ~= 0 then
                                ImGui.Text("I am an odd tab.")
                            end
                            ImGui.EndTabItem()
                        end
                    end
                end
                ImGui.EndTabBar()
            end
            ImGui.Separator()
            ImGui.TreePop()
        end

        if ImGui.TreeNode("TabItemButton & Leading/Trailing flags") then
            if next_tab_id == 0 then
                for i = 0, 2 do
                    active_tabs:push_back(next_tab_id)
                    next_tab_id = next_tab_id + 1
                end
            end

            _, show_leading_button = ImGui.Checkbox("Show Leading TabItemButton()", show_leading_button)
            _, show_trailing_button = ImGui.Checkbox("Show Trailing TabItemButton()", show_trailing_button)
            _, show_leading_trailing_tabs = ImGui.Checkbox("Show Leading+Trailing TabItem()", show_leading_trailing_tabs)
            tab_bar_flags_buttons = EditTabBarFittingPolicyFlags(tab_bar_flags_buttons)

            if ImGui.BeginTabBar("MyTabBar", tab_bar_flags_buttons) then
                if show_leading_button then
                    if ImGui.TabItemButton("?", bit.bor(ImGuiTabItemFlags.Leading, ImGuiTabItemFlags.NoTooltip)) then
                        ImGui.OpenPopup("MyHelpMenu")
                    end
                end
                if ImGui.BeginPopup("MyHelpMenu") then
                    ImGui.Selectable("Hello!")
                    ImGui.EndPopup()
                end

                if show_leading_trailing_tabs then
                    local contents_visible
                    _, contents_visible = ImGui.BeginTabItem("Leading", nil, ImGuiTabItemFlags.Leading)
                    if contents_visible then ImGui.EndTabItem() end
                    _, contents_visible = ImGui.BeginTabItem("Trailing", nil, ImGuiTabItemFlags.Trailing)
                    if contents_visible then ImGui.EndTabItem() end
                end

                if show_trailing_button then
                    if ImGui.TabItemButton("+", bit.bor(ImGuiTabItemFlags.Trailing, ImGuiTabItemFlags.NoTooltip)) then
                        active_tabs:push_back(next_tab_id)
                        next_tab_id = next_tab_id + 1
                    end
                end

                local n = 1
                while n <= active_tabs.Size do
                    local open = true
                    local name = string.format("%04d", active_tabs.Data[n])
                    local contents_visible
                    open, contents_visible = ImGui.BeginTabItem(name, open, ImGuiTabItemFlags.None)
                    if contents_visible then
                        ImGui.Text("This is the %s tab!", name)
                        ImGui.EndTabItem()
                    end
                    if not open then
                        active_tabs:erase(n)
                    else
                        n = n + 1
                    end
                end
                ImGui.EndTabBar()
            end
            ImGui.Separator()
            ImGui.TreePop()
        end
        ImGui.TreePop()
    end
end

end

local DemoWindowWidgetsVerticalSliders do

local int_value = 0
local values = { 0.0, 0.60, 0.35, 0.9, 0.70, 0.20, 0.0 }
local values2 = { 0.20, 0.80, 0.40, 0.25 }

local col0 = ImVec4(0, 0, 0, 1)
local col1 = ImVec4(0, 0, 0, 1)
local col2 = ImVec4(0, 0, 0, 1)
local col3 = ImVec4(0, 0, 0, 1)
local col4 = ImVec4(0, 0, 0, 1)

function DemoWindowWidgetsVerticalSliders()
    if ImGui.TreeNode("Vertical Sliders") then
        local style = ImGui.GetStyle()
        local slider_sz = ImVec2(ImGui.GetFrameHeight(), ImGui.GetFrameHeight() * 9)

        ImGui.PushStyleVarX(ImGuiStyleVar.ItemSpacing, math.floor(style.ItemSpacing.x * 0.5))
        ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, math.floor(slider_sz.x * 0.25))
        ImGui.PushStyleVar(ImGuiStyleVar.GrabRounding, math.floor(slider_sz.x * 0.25))
        local spacing = style.ItemSpacing.x

        int_value = ImGui.VSliderInt("##int", slider_sz, int_value, 0, 5)
        ImGui.SameLine()

        ImGui.PushID("set1")
        for i = 1, 7 do
            if i > 1 then ImGui.SameLine() end
            ImGui.PushID(i)
            local hue = (i - 1) / 7.0
            col0.x, col0.y, col0.z = ImGui.ColorConvertHSVtoRGB(hue, 0.5, 0.5)
            col1.x, col1.y, col1.z = ImGui.ColorConvertHSVtoRGB(hue, 0.6, 0.5)
            col2.x, col2.y, col2.z = ImGui.ColorConvertHSVtoRGB(hue, 0.7, 0.5)
            col3.x, col3.y, col3.z = ImGui.ColorConvertHSVtoRGB(hue, 0.8, 0.7)
            col4.x, col4.y, col4.z = ImGui.ColorConvertHSVtoRGB(hue, 0.9, 0.9)
            ImGui.PushStyleColor(ImGuiCol.FrameBg, col0)
            ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, col1)
            ImGui.PushStyleColor(ImGuiCol.FrameBgActive, col2)
            ImGui.PushStyleColor(ImGuiCol.SliderGrab, col3)
            ImGui.PushStyleColor(ImGuiCol.SliderGrabActive, col4)
            values[i] = ImGui.VSliderFloat("##v", slider_sz, values[i], 0.0, 1.0, "")
            if ImGui.IsItemActive() or ImGui.IsItemHovered() then
                ImGui.SetTooltip("%.3f", values[i])
            end
            ImGui.PopStyleColor(5)
            ImGui.PopID()
        end
        ImGui.PopID()

        ImGui.SameLine()
        ImGui.PushID("set2")
        local rows = 3
        local slider_size_small = ImVec2(slider_sz.x, math.floor((slider_sz.y - (rows - 1) * spacing) / rows))
        for nx = 1, 4 do
            if nx > 1 then ImGui.SameLine() end
            ImGui.BeginGroup()
            for ny = 1, rows do
                ImGui.PushID((nx - 1) * rows + ny)
                values2[nx] = ImGui.VSliderFloat("##v", slider_size_small, values2[nx], 0.0, 1.0, "")
                if ImGui.IsItemActive() or ImGui.IsItemHovered() then
                    ImGui.SetTooltip("%.3f", values2[nx])
                end
                ImGui.PopID()
            end
            ImGui.EndGroup()
        end
        ImGui.PopID()

        ImGui.SameLine()
        ImGui.PushID("set3")
        for i = 1, 4 do
            if i > 1 then ImGui.SameLine() end
            ImGui.PushID(i)
            ImGui.PushStyleVar(ImGuiStyleVar.GrabMinSize, slider_sz.y * 0.25)
            values[i] = ImGui.VSliderFloat("##v", ImVec2(slider_sz.x * 2.0, slider_sz.y), values[i], 0.0, 1.0, "%.2f\nsec")
            ImGui.PopStyleVar()
            ImGui.PopID()
        end
        ImGui.PopID()

        ImGui.PopStyleVar(3)

        ImGui.TreePop()
    end
end

end

local function DemoWindowWidgets()
    if not ImGui.CollapsingHeader("Widgets") then
        return
    end

    DemoWindowWidgetsBasic()
    DemoWindowWidgetsBullets()
    DemoWindowWidgetsColorAndPickers()
    DemoWindowWidgetsImages()
    DemoWindowWidgetsLiveEdit()
    DemoWindowWidgetsMixedValues()
    DemoWindowWidgetsPlotting()
    DemoWindowWidgetsProgressBars()
    DemoWindowWidgetsTabs()
    DemoWindowWidgetsVerticalSliders()
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

do

local static = {}

local style_idx = -1
local style_names = { "Dark", "Light", "Classic" }

--- @param label string
function ImGui.ShowStyleSelector(label)
    local ret = false
    if ImGui.BeginCombo(label, (style_idx >= 1 and style_idx <= #style_names) and style_names[style_idx] or "") then
        for n = 1, #style_names do
            if ImGui.Selectable(style_names[n], style_idx == n, ImGuiSelectableFlags.SelectOnNav) then
                style_idx = n
                ret = true

                if style_idx == 1 then ImGui.StyleColorsDark() end
                if style_idx == 2 then ImGui.StyleColorsLight() end
                if style_idx == 3 then ImGui.StyleColorsClassic() end

            elseif style_idx == n then
                ImGui.SetItemDefaultFocus()
            end
        end
        ImGui.EndCombo()
    end
    return ret
end

--- @param label string
function ImGui.ShowFontSelector(label)
    local io = ImGui.GetIO()
    local font_current = ImGui.GetFont()
    if ImGui.BeginCombo(label, font_current:GetDebugName()) then
        for _, font in io.Fonts.Fonts:iter() do
            ImGui.PushID(tostring(font):match("0x%x+")) -- (void*)font
            if ImGui.Selectable(font:GetDebugName(), font == font_current, ImGuiSelectableFlags.SelectOnNav) then
                io.FontDefault = font
            end
            if font == font_current then
                ImGui.SetItemDefaultFocus()
            end
            ImGui.PopID()
        end
        ImGui.EndCombo()
    end
end

--- @param ref ImGuiStyle?
function ImGui.ShowStyleEditor(ref)
    local style = ImGui.GetStyle()

    local default_border_size = ImTrunc(style._MainScale)
    local max_border_size = ImMax(default_border_size, 2.0)

    ImGui.PushItemWidth(ImGui.GetWindowWidth() * 0.50)

    ImGui.SeparatorText("General")
    do
        if ImGui.ShowStyleSelector("Colors##Selector") then
            -- TODO:
        end
        ImGui.ShowFontSelector("Fonts##Selector")

        local ret0
        style.FontSizeBase, ret0 = ImGui.DragFloat("FontSizeBase", style.FontSizeBase, 0.20, 5.0, 100.0, "%.0f")
        if ret0 then
            style._NextFrameFontSizeBase = style.FontSizeBase -- FIXME: Temporary hack until we finish remaining work.
        end
        ImGui.SameLine(0.0, 0.0); ImGui.Text(" (out %.2f)", ImGui.GetFontSize())

        style.FontScaleMain = ImGui.DragFloat("FontScaleMain", style.FontScaleMain, 0.02, 0.5, 4.0)

        ImGui.BeginDisabled(ImGui.GetIO().ConfigDpiScaleFonts)
            style.FontScaleDpi = ImGui.DragFloat("FontScaleDpi", style.FontScaleDpi, 0.02, 0.5, 4.0)
            ImGui.SetItemTooltip("When io.ConfigDpiScaleFonts is set, this value is automatically overwritten.")
        ImGui.EndDisabled()

        local ret1
        style.FrameRounding, ret1 = ImGui.SliderFloat("FrameRounding", style.FrameRounding, 0.0, 12.0, "%.0f")
        if ret1 then
            style.GrabRounding = style.FrameRounding -- Make GrabRounding always the same value as FrameRounding
        end

        do
            local border = (style.WindowBorderSize > 0.0)
            local pressed
            pressed, border = ImGui.Checkbox("WindowBorder", border)
            if pressed then style.WindowBorderSize = (border and default_border_size or 0.0) end
        end
        ImGui.SameLine()
        do
            local border = (style.FrameBorderSize > 0.0)
            local pressed
            pressed, border = ImGui.Checkbox("FrameBorder", border)
            if pressed then style.FrameBorderSize = (border and default_border_size or 0.0) end
        end
        ImGui.SameLine()
        do
            local border = (style.PopupBorderSize > 0.0)
            local pressed
            pressed, border = ImGui.Checkbox("PopupBorder", border)
            if pressed then style.PopupBorderSize = (border and default_border_size or 0.0) end
        end
    end

    ImGui.SeparatorText("Details")
    -- TODO:

    ImGui.PopItemWidth()
end

end

local ShowExampleAppImageViewer do

local image_viewer = ExampleImageViewerData()

function ShowExampleAppImageViewer(open)
    local atlas = ImGui.GetIO().Fonts
    local tex_ref = atlas.TexRef
    local tex_w = atlas.TexData.Width
    local tex_h = atlas.TexData.Height
    local visible
    open, visible = ImGui.Begin("Example: Image Viewer", open)
    if visible then
        ExampleImageViewer_DrawOptions(image_viewer)
        local canvas_size = ImGui.GetContentRegionAvail()
        local canvas_min_size = ImGui.IsWindowAppearing() and ImVec2(3.0 * tex_w, 4.0 * tex_h) or ImVec2(1.0, 1.0)
        canvas_size = ImVec2(IM_MAX(canvas_size.x, canvas_min_size.x), IM_MAX(canvas_size.y, canvas_min_size.y))
        ExampleImageViewer_DrawCanvas(image_viewer, canvas_size, tex_ref, tex_w, tex_h)
    end
    ImGui.End()

    return open
end

end

local ShowExampleAppCustomRendering do

local sz = 42.0
local base_rounding = 8.0
local base_thickness = 3.0
local animate_rounding = false
local animate_thickness = false
local ngon_segments = 6
local circle_segments_override = false
local circle_segments_override_v = 12
local curve_segments_override = false
local curve_segments_override_v = 8
local colf_stroke = ImVec4(1.000, 0.384, 0.169, 1.000)
local colf_fill = ImVec4(0.416, 0.378, 0.420, 1.000)
local prim_stroke_flags = ImDrawFlags.None
local prim_other_flags = ImDrawFlags.AALineEnds
local scope_flags
local concave_shape = { ImVec2(0.0, 0.0), ImVec2(0.3, 0.0), ImVec2(0.3, 0.7), ImVec2(0.7, 0.7), ImVec2(0.7, 0.0), ImVec2(1.0, 0.0), ImVec2(1.0, 1.0), ImVec2(0.0, 1.0) }
local zigzag_shape = { ImVec2(0.0, 0.0), ImVec2(0.9, 0.0), ImVec2(1.0, 0.1), ImVec2(1.0, 0.9), ImVec2(0.9, 1.0), ImVec2(0.3, 1.0), ImVec2(0.3, 0.4), ImVec2(0.9, 0.4) }
local points = ImVector()
local scrolling = ImVec2(0.0, 0.0)
local opt_enable_grid = true
local opt_enable_context_menu = true
local adding_line = false
local draw_bg = true
local draw_fg = true

function ShowExampleAppCustomRendering(open)
    local _, visible
    open, visible = ImGui.Begin("Example: Custom rendering", open)
    if not visible then
        ImGui.End()
        return open
    end

    if ImGui.BeginTabBar("##TabBar") then
        _, visible = ImGui.BeginTabItem("Primitives")
        if visible then
            ImGui.PushItemWidth(-ImGui.GetFontSize() * 15)
            ImGui.PushItemFlag(ImGuiItemFlags.LiveEditOnInput, true)
            local draw_list = ImGui.GetWindowDrawList()

            ImGui.Text("Gradients")
            local gradient_size = ImVec2(ImGui.CalcItemWidth(), ImGui.GetFrameHeight())
            do
                ImGui.InvisibleButton("##gradient1", gradient_size)
                local col_a = ImGui.GetColorU32(IM_COL32(0, 0, 0, 255), nil, true)
                local col_b = ImGui.GetColorU32(IM_COL32(255, 255, 255, 255), nil, true)
                draw_list:AddRectFilledMultiColor(ImGui.GetItemRectMin(), ImGui.GetItemRectMax(), col_a, col_b, col_b, col_a)
            end
            do
                ImGui.InvisibleButton("##gradient2", gradient_size)
                local col_a = ImGui.GetColorU32(IM_COL32(0, 255, 0, 255), nil, true)
                local col_b = ImGui.GetColorU32(IM_COL32(255, 0, 0, 255), nil, true)
                draw_list:AddRectFilledMultiColor(ImGui.GetItemRectMin(), ImGui.GetItemRectMax(), col_a, col_b, col_b, col_a)
            end

            ImGui.Text("All primitives")
            sz = ImGui.DragFloat("Size", sz, 0.2, 0.2, 100.0, "%.0f")

            local rounding_anim_period = 3.0
            local rounding_wave = 1.0 - math.abs(math.fmod(ImGui.GetTime(), rounding_anim_period) * (2.0 / rounding_anim_period) - 1.0)
            local rounding = animate_rounding and ImTrunc(rounding_wave * base_rounding * 10.0) / 10.0 or base_rounding
            base_rounding = ImGui.DragFloat("Rounding", base_rounding, 0.02, 0.0, 32.0, "%.1f"); ImGui.SameLine()
            _, animate_rounding = ImGui.Checkbox("Animate##rounding", animate_rounding); ImGui.SameLine()
            ImGui.Text("%.2f", rounding)

            local thickness_anim_period = 5.0
            local thickness_wave = 1.0 - math.abs(math.fmod(ImGui.GetTime(), thickness_anim_period) * (2.0 / thickness_anim_period) - 1.0)
            local thickness = animate_thickness and thickness_wave * base_thickness or base_thickness
            base_thickness = ImGui.DragFloat("Thickness", base_thickness, 0.02, 0.0, 32.0, "%.02f"); ImGui.SameLine()
            _, animate_thickness = ImGui.Checkbox("Animate##thickness", animate_thickness); ImGui.SameLine()
            ImGui.Text("%.2f", thickness)

            ngon_segments = ImGui.SliderInt("N-gon sides", ngon_segments, 3, 12)
            _, circle_segments_override = ImGui.Checkbox("##CircleSegmentOverride", circle_segments_override)
            ImGui.SameLine(0.0, ImGui.GetStyle().ItemInnerSpacing.x)
            local changed
            circle_segments_override_v, changed = ImGui.SliderInt("Circle segments override", circle_segments_override_v, 3, 30)
            circle_segments_override = circle_segments_override or changed
            _, curve_segments_override = ImGui.Checkbox("##CurvesSegmentOverride", curve_segments_override)
            ImGui.SameLine(0.0, ImGui.GetStyle().ItemInnerSpacing.x)
            curve_segments_override_v, changed = ImGui.SliderInt("Curves segments override", curve_segments_override_v, 3, 30)
            curve_segments_override = curve_segments_override or changed
            ImGui.ColorEdit4("Stroke Color", colf_stroke)
            ImGui.ColorEdit4("Fill Color", colf_fill)

            ImGui.SeparatorText("Per primitive flags (AddXXX functions)")
            _, prim_stroke_flags = ImGui.RadioButton("Default", prim_stroke_flags, ImDrawFlags.None); ImGui.SameLine()
            _, prim_stroke_flags = ImGui.RadioButton("Inside", prim_stroke_flags, ImDrawFlags.StrokeInside); ImGui.SameLine()
            _, prim_stroke_flags = ImGui.RadioButton("Center", prim_stroke_flags, ImDrawFlags.StrokeCenter); ImGui.SameLine()
            _, prim_stroke_flags = ImGui.RadioButton("CenterBiased", prim_stroke_flags, ImDrawFlags.StrokeCenterBiased); ImGui.SameLine()
            _, prim_stroke_flags = ImGui.RadioButton("Outside", prim_stroke_flags, ImDrawFlags.StrokeOutside); ImGui.SameLine()
            _, prim_stroke_flags = ImGui.RadioButton("Legacy", prim_stroke_flags, ImDrawFlags.StrokeLegacy)
            _, prim_other_flags = ImGui.CheckboxFlags("AAFill", prim_other_flags, ImDrawFlags.AAFill); ImGui.SameLine()
            _, prim_other_flags = ImGui.CheckboxFlags("AALines", prim_other_flags, ImDrawFlags.AALines); ImGui.SameLine()
            _, prim_other_flags = ImGui.CheckboxFlags("AALineEnds", prim_other_flags, ImDrawFlags.AALineEnds); ImGui.SameLine()
            _, prim_other_flags = ImGui.CheckboxFlags("JoinMiter", prim_other_flags, ImDrawFlags.JoinMiter); ImGui.SameLine()
            _, prim_other_flags = ImGui.CheckboxFlags("CapSquare", prim_other_flags, ImDrawFlags.CapSquare)

            if scope_flags == nil then scope_flags = bit.band(draw_list.Flags, ImDrawFlags.AllowInPushScope_) end
            ImGui.SeparatorText("Current ImDrawList flags (e.g. PushDrawFlag function)")
            ImGui.PushID("ScopeFlags")
            _, scope_flags = ImGui.CheckboxFlags("AAFill", scope_flags, ImDrawFlags.AAFill); ImGui.SameLine()
            _, scope_flags = ImGui.CheckboxFlags("AALines", scope_flags, ImDrawFlags.AALines); ImGui.SameLine()
            _, scope_flags = ImGui.CheckboxFlags("AALineEnds", scope_flags, ImDrawFlags.AALineEnds); ImGui.SameLine()
            _, scope_flags = ImGui.CheckboxFlags("StrokeLegacy", scope_flags, ImDrawFlags.StrokeLegacy)
            ImGui.PopID()
            ImGui.Spacing()

            draw_list:PushDrawFlag(ImDrawFlags.AllowInPushScope_, false)
            draw_list:PushDrawFlag(scope_flags, true)
            local flags = bit.bor(prim_stroke_flags, prim_other_flags)

            local start_pos = ImGui.GetCursorScreenPos()
            local pi = 3.141592
            local step = sz + 10.0
            local corners_tl_br = bit.bor(ImDrawFlags.RoundTopLeft, ImDrawFlags.RoundBottomRight)
            local half_sz = sz * 0.5
            local circle_segments = circle_segments_override and circle_segments_override_v or 0
            local curve_segments = curve_segments_override and curve_segments_override_v or 0
            local cp3 = { ImVec2(0.0, sz * 0.6), ImVec2(sz * 0.5, -sz * 0.4), ImVec2(sz, sz) }
            local cp4 = { ImVec2(0.0, 0.0), ImVec2(sz * 1.3, sz * 0.3), ImVec2(sz - sz * 1.3, sz - sz * 0.3), ImVec2(sz, sz) }
            local rotating_square = {}
            for side = 0, 3 do
                local t = ImGui.GetTime() * 0.1 + side * pi * 0.5
                rotating_square[side + 1] = ImVec2(math.cos(t) * half_sz, math.sin(t) * half_sz)
            end

            local x = start_pos.x
            local y = start_pos.y
            for row = 0, 3 do
                x = start_pos.x
                local draw_fill = row == 2 or row == 3
                local draw_strokes = row == 0 or row == 1 or row == 3
                if draw_fill then
                    local col = ImGui.ColorConvertFloat4ToU32(colf_fill)
                    draw_list:AddNgonFilled(ImVec2(x + half_sz, y + half_sz), half_sz, col, ngon_segments); x = x + step
                    draw_list:AddCircleFilled(ImVec2(x + half_sz, y + half_sz), half_sz, col, circle_segments); x = x + step
                    draw_list:AddEllipseFilled(ImVec2(x + half_sz, y + half_sz), ImVec2(half_sz, sz * 0.3), col, -0.3, circle_segments); x = x + step
                    draw_list:AddRectFilled(ImVec2(x, y), ImVec2(x + sz, y + sz), col, 0.0, flags); x = x + step
                    draw_list:AddRectFilled(ImVec2(x, y), ImVec2(x + sz, y + sz), col, rounding, flags); x = x + step
                    draw_list:AddRectFilled(ImVec2(x, y), ImVec2(x + sz, y + sz), col, rounding, bit.bor(flags, corners_tl_br)); x = x + step
                    draw_list:AddTriangleFilled(ImVec2(x + sz * 0.5, y), ImVec2(x + sz, y + sz), ImVec2(x, y + sz), col); x = x + step
                    draw_list:AddTriangleFilled(ImVec2(x + sz * 0.2, y), ImVec2(x + sz * 0.4, y + sz), ImVec2(x, y + sz), col); x = x + step - ImTrunc(sz * 0.6)

                    for _, p in ipairs(concave_shape) do draw_list:PathLineTo(ImVec2(x + ImTrunc(sz * p.x), y + ImTrunc(sz * p.y))) end
                    draw_list:PathFillConcave(col)
                    x = x + step
                    for _, p in ipairs(zigzag_shape) do draw_list:PathLineTo(ImVec2(x + ImTrunc(sz * p.x), y + ImTrunc(sz * p.y))) end
                    draw_list:PathFillConcave(col)
                    x = x + step

                    draw_list:AddRectFilled(ImVec2(x, y), ImVec2(x + sz, y + thickness), col); x = x + step
                    draw_list:AddRectFilled(ImVec2(x, y), ImVec2(x + thickness, y + sz), col); x = x + step - ImTrunc(half_sz)
                    if not (draw_fill and draw_strokes) then
                        local block_sz, off = 1, 0
                        while block_sz < 16 and off + block_sz <= sz do
                            draw_list:AddRectFilled(ImVec2(x, y + off), ImVec2(x + block_sz, y + off + block_sz), col)
                            off = off + block_sz + 1
                            block_sz = block_sz + 1
                        end
                    end
                    x = x + step - ImTrunc(half_sz)

                    for n = 1, 4 do draw_list:PathLineTo(ImVec2(x + half_sz + rotating_square[n].x, y + half_sz + rotating_square[n].y)) end
                    draw_list:PathFillConvex(col, flags)
                    x = x + step
                    draw_list:PathArcTo(ImVec2(x + half_sz, y + half_sz), half_sz, pi * -0.5, pi * 1.1)
                    draw_list:PathFillConvex(col)
                    x = x + step
                    draw_list:PathLineTo(ImVec2(x + cp3[1].x, y + cp3[1].y))
                    draw_list:PathBezierQuadraticCurveTo(ImVec2(x + cp3[2].x, y + cp3[2].y), ImVec2(x + cp3[3].x, y + cp3[3].y), curve_segments)
                    draw_list:PathFillConvex(col)
                    x = x + step
                    if not (draw_fill and draw_strokes) then
                        draw_list:AddRectFilledMultiColor(ImVec2(x, y), ImVec2(x + sz, y + sz), IM_COL32(0, 0, 0, 255), IM_COL32(255, 0, 0, 255), IM_COL32(255, 255, 0, 255), IM_COL32(0, 255, 0, 255))
                        x = x + step
                    end
                end
                if draw_fill and draw_strokes then x = start_pos.x end
                if draw_strokes then
                    local col = ImGui.ColorConvertFloat4ToU32(colf_stroke)
                    local th = row == 0 and 1.0 or thickness
                    draw_list:AddNgon(ImVec2(x + half_sz, y + half_sz), half_sz, col, ngon_segments, th, flags); x = x + step
                    draw_list:AddCircle(ImVec2(x + half_sz, y + half_sz), half_sz, col, circle_segments, th, flags); x = x + step
                    draw_list:AddEllipse(ImVec2(x + half_sz, y + half_sz), ImVec2(half_sz, sz * 0.3), col, -0.3, circle_segments, th, flags); x = x + step
                    draw_list:AddRect(ImVec2(x, y), ImVec2(x + sz, y + sz), col, 0.0, th, flags); x = x + step
                    draw_list:AddRect(ImVec2(x, y), ImVec2(x + sz, y + sz), col, rounding, th, flags); x = x + step
                    draw_list:AddRect(ImVec2(x, y), ImVec2(x + sz, y + sz), col, rounding, th, bit.bor(flags, corners_tl_br)); x = x + step
                    draw_list:AddTriangle(ImVec2(x + sz * 0.5, y), ImVec2(x + sz, y + sz), ImVec2(x, y + sz), col, th, flags); x = x + step
                    draw_list:AddTriangle(ImVec2(x + sz * 0.2, y), ImVec2(x + sz * 0.4, y + sz), ImVec2(x, y + sz), col, th, flags); x = x + step - ImTrunc(sz * 0.6)

                    for _, p in ipairs(concave_shape) do draw_list:PathLineTo(ImVec2(x + ImTrunc(sz * p.x), y + ImTrunc(sz * p.y))) end
                    draw_list:PathStroke(col, th, bit.bor(flags, ImDrawFlags.Closed))
                    x = x + step
                    for _, p in ipairs(zigzag_shape) do draw_list:PathLineTo(ImVec2(x + ImTrunc(sz * p.x), y + ImTrunc(sz * p.y))) end
                    draw_list:PathStroke(col, th, bit.bor(flags, ImDrawFlags.Closed))
                    x = x + step

                    local off = ImTrunc(sz * 0.4)
                    draw_list:AddLineH(x, x + sz, y, col, th, flags)
                    draw_list:AddLine(ImVec2(x, y + off), ImVec2(x + sz, y + off), col, th, flags)
                    x = x + step
                    draw_list:AddLineV(x, y, y + sz, col, th, flags)
                    draw_list:AddLine(ImVec2(x + off, y + sz), ImVec2(x + off, y), col, th, flags)
                    x = x + step - ImTrunc(half_sz)
                    if not (draw_fill and draw_strokes) then
                        draw_list:AddLine(ImVec2(x, y), ImVec2(x + half_sz, y + sz), col, th, flags)
                        draw_list:AddLine(ImVec2(x, y + sz), ImVec2(x + half_sz, y), col, th, flags)
                    end
                    x = x + step - ImTrunc(half_sz)
                    for n = 1, 4 do draw_list:PathLineTo(ImVec2(x + half_sz + rotating_square[n].x, y + half_sz + rotating_square[n].y)) end
                    draw_list:PathStroke(col, th, bit.bor(flags, ImDrawFlags.Closed))
                    x = x + step
                    draw_list:PathArcTo(ImVec2(x + half_sz, y + half_sz), half_sz, pi * -0.5, pi * 1.1)
                    draw_list:PathStroke(col, th, flags)
                    x = x + step
                    draw_list:AddBezierQuadratic(ImVec2(x + cp3[1].x, y + cp3[1].y), ImVec2(x + cp3[2].x, y + cp3[2].y), ImVec2(x + cp3[3].x, y + cp3[3].y), col, th, curve_segments, flags)
                    x = x + step
                    if not (draw_fill and draw_strokes) then
                        draw_list:AddBezierCubic(ImVec2(x + cp4[1].x, y + cp4[1].y), ImVec2(x + cp4[2].x, y + cp4[2].y), ImVec2(x + cp4[3].x, y + cp4[3].y), ImVec2(x + cp4[4].x, y + cp4[4].y), col, th, curve_segments, flags)
                        x = x + step
                    end
                end
                y = y + step
            end

            ImGui.Dummy(ImVec2(step * 15.5, step * 4.0))
            draw_list:PopDrawFlag()
            draw_list:PopDrawFlag()
            ImGui.Text("ImDrawList Vector Rendering Reference:")
            ImGui.TextLinkOpenURL("https://github.com/ocornut/imgui/wiki/Draw-List")
            ImGui.PopItemFlag()
            ImGui.PopItemWidth()
            ImGui.EndTabItem()
        end

        _, visible = ImGui.BeginTabItem("Canvas")
        if visible then
            _, opt_enable_grid = ImGui.Checkbox("Enable grid", opt_enable_grid)
            _, opt_enable_context_menu = ImGui.Checkbox("Enable context menu", opt_enable_context_menu)
            ImGui.Text("Mouse Left: drag to add lines,\nMouse Right: drag to scroll, click for context menu.")

            local canvas_p0 = ImGui.GetCursorScreenPos()
            local canvas_sz = ImGui.GetContentRegionAvail()
            if canvas_sz.x < 50.0 then canvas_sz.x = 50.0 end
            if canvas_sz.y < 50.0 then canvas_sz.y = 50.0 end
            local canvas_p1 = ImVec2(canvas_p0.x + canvas_sz.x, canvas_p0.y + canvas_sz.y)
            local io = ImGui.GetIO()
            local draw_list = ImGui.GetWindowDrawList()
            draw_list:AddRectFilled(canvas_p0, canvas_p1, IM_COL32(50, 50, 50, 255))
            draw_list:AddRect(canvas_p0, canvas_p1, IM_COL32(255, 255, 255, 255))

            ImGui.InvisibleButton("canvas", canvas_sz, bit.bor(ImGuiButtonFlags.MouseButtonLeft, ImGuiButtonFlags.MouseButtonRight))
            local is_hovered = ImGui.IsItemHovered()
            local is_active = ImGui.IsItemActive()
            local origin = ImVec2(canvas_p0.x + scrolling.x, canvas_p0.y + scrolling.y)
            local mouse_pos_in_canvas = ImVec2(io.MousePos.x - origin.x, io.MousePos.y - origin.y)

            if is_hovered and not adding_line and ImGui.IsMouseClicked(ImGuiMouseButton.Left) then
                points:push_back(ImVec2(mouse_pos_in_canvas.x, mouse_pos_in_canvas.y))
                points:push_back(ImVec2(mouse_pos_in_canvas.x, mouse_pos_in_canvas.y))
                adding_line = true
            end
            if adding_line then
                ImVec2_Copy(points:back(), mouse_pos_in_canvas)
                if not ImGui.IsMouseDown(ImGuiMouseButton.Left) then adding_line = false end
            end

            local mouse_threshold_for_pan = opt_enable_context_menu and -1.0 or 0.0
            if is_active and ImGui.IsMouseDragging(ImGuiMouseButton.Right, mouse_threshold_for_pan) then
                scrolling.x = scrolling.x + io.MouseDelta.x
                scrolling.y = scrolling.y + io.MouseDelta.y
            end

            local drag_delta = ImGui.GetMouseDragDelta(ImGuiMouseButton.Right)
            if opt_enable_context_menu and drag_delta.x == 0.0 and drag_delta.y == 0.0 then
                ImGui.OpenPopupOnItemClick("context", ImGuiPopupFlags.MouseButtonRight)
            end
            if ImGui.BeginPopup("context") then
                if adding_line then points:resize(points.Size - 2) end
                adding_line = false
                if ImGui.MenuItem("Remove one", nil, false, points.Size > 0) then points:resize(points.Size - 2) end
                if ImGui.MenuItem("Remove all", nil, false, points.Size > 0) then points:clear() end
                ImGui.EndPopup()
            end

            draw_list:PushClipRect(canvas_p0, canvas_p1, true)
            if opt_enable_grid then
                local GRID_STEP = 64.0
                local x = math.fmod(scrolling.x, GRID_STEP)
                while x < canvas_sz.x do
                    draw_list:AddLineV(canvas_p0.x + x, canvas_p0.y, canvas_p1.y, IM_COL32(200, 200, 200, 40))
                    x = x + GRID_STEP
                end
                local y = math.fmod(scrolling.y, GRID_STEP)
                while y < canvas_sz.y do
                    draw_list:AddLineH(canvas_p0.x, canvas_p1.x, canvas_p0.y + y, IM_COL32(200, 200, 200, 40))
                    y = y + GRID_STEP
                end
            end
            for n = 1, points.Size, 2 do
                draw_list:AddLine(ImVec2(origin.x + points[n].x, origin.y + points[n].y), ImVec2(origin.x + points[n + 1].x, origin.y + points[n + 1].y), IM_COL32(255, 255, 0, 255), 2.0)
            end
            draw_list:PopClipRect()
            ImGui.EndTabItem()
        end

        _, visible = ImGui.BeginTabItem("BG/FG draw lists")
        if visible then
            _, draw_bg = ImGui.Checkbox("Draw in Background draw list", draw_bg)
            ImGui.SameLine(); HelpMarker("The Background draw list will be rendered below every Dear ImGui windows.")
            _, draw_fg = ImGui.Checkbox("Draw in Foreground draw list", draw_fg)
            ImGui.SameLine(); HelpMarker("The Foreground draw list will be rendered over every Dear ImGui windows.")
            local window_pos = ImGui.GetWindowPos()
            local window_size = ImGui.GetWindowSize()
            local window_center = ImVec2(window_pos.x + window_size.x * 0.5, window_pos.y + window_size.y * 0.5)
            if draw_bg then ImGui.GetBackgroundDrawList():AddCircle(window_center, window_size.x * 0.6, IM_COL32(255, 0, 0, 200), 0, 10 + 4) end
            if draw_fg then ImGui.GetForegroundDrawList():AddCircle(window_center, window_size.y * 0.6, IM_COL32(0, 255, 0, 200), 0, 10) end
            ImGui.EndTabItem()
        end

        _, visible = ImGui.BeginTabItem("Draw Channels")
        if visible then
            local draw_list = ImGui.GetWindowDrawList()
            do
                ImGui.Text("Blue shape is drawn first: appears in back")
                ImGui.Text("Red shape is drawn after: appears in front")
                local p0 = ImGui.GetCursorScreenPos()
                draw_list:AddRectFilled(ImVec2(p0.x, p0.y), ImVec2(p0.x + 50, p0.y + 50), IM_COL32(0, 0, 255, 255))
                draw_list:AddRectFilled(ImVec2(p0.x + 25, p0.y + 25), ImVec2(p0.x + 75, p0.y + 75), IM_COL32(255, 0, 0, 255))
                ImGui.Dummy(ImVec2(75, 75))
            end
            ImGui.Separator()
            do
                ImGui.Text("Blue shape is drawn first, into channel 1: appears in front")
                ImGui.Text("Red shape is drawn after, into channel 0: appears in back")
                local p1 = ImGui.GetCursorScreenPos()
                draw_list:ChannelsSplit(2)
                draw_list:ChannelsSetCurrent(1)
                draw_list:AddRectFilled(ImVec2(p1.x, p1.y), ImVec2(p1.x + 50, p1.y + 50), IM_COL32(0, 0, 255, 255))
                draw_list:ChannelsSetCurrent(0)
                draw_list:AddRectFilled(ImVec2(p1.x + 25, p1.y + 25), ImVec2(p1.x + 75, p1.y + 75), IM_COL32(255, 0, 0, 255))
                draw_list:ChannelsMerge()
                ImGui.Dummy(ImVec2(75, 75))
                ImGui.Text("After reordering, contents of channel 0 appears below channel 1.")
            end
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
    ImGui.End()
    return open
end

end

local ShowExampleAppLongText do

local test_type = 1
local log = ImGuiTextBuffer()
local lines = 0

function ShowExampleAppLongText(open)
    ImGui.SetNextWindowSize(ImVec2(520, 600), ImGuiCond.FirstUseEver)
    local ret
    open, ret = ImGui.Begin("Example: Long text display", open)
    if not ret then
        ImGui.End()
        return open
    end

    ImGui.Text("Printing unusually long amount of text.")
    test_type = ImGui.Combo("Test type", test_type,
        "Single call to TextUnformatted()\0" ..
        "Multiple calls to Text(), clipped\0" ..
        "Multiple calls to Text(), not clipped (slow)\0")
    ImGui.Text("Buffer contents: %d lines, %d bytes", lines, log:size())
    if ImGui.Button("Clear") then
        log:clear()
        lines = 0
    end
    ImGui.SameLine()
    if ImGui.Button("Add 1000 lines") then
        for i = 0, 999 do
            log:appendf("%i The quick brown fox jumps over the lazy dog\n", lines + i)
        end
        lines = lines + 1000
    end

    ImGui.BeginChild("Log")
    if test_type == 1 then
        local text = log:c_str()
        ImGui.TextUnformatted(text, log:end_())
    elseif test_type == 2 then
        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0))
        local clipper = ImGuiListClipper()
        clipper:Begin(lines)
        while clipper:Step() do
            for i = clipper.DisplayStart, clipper.DisplayEnd - 1 do
                ImGui.Text("%i The quick brown fox jumps over the lazy dog", i - 1)
            end
        end
        ImGui.PopStyleVar()
    elseif test_type == 3 then
        ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(0, 0))
        for i = 0, lines - 1 do
            ImGui.Text("%i The quick brown fox jumps over the lazy dog", i)
        end
        ImGui.PopStyleVar()
    end
    ImGui.EndChild()
    ImGui.End()
    return open
end

end

local ShowExampleAppFullscreen do

local use_work_area = true
local flags = bit.bor(ImGuiWindowFlags.NoDecoration, ImGuiWindowFlags.NoMove, ImGuiWindowFlags.NoSavedSettings)

function ShowExampleAppFullscreen(open)
    local viewport = ImGui.GetMainViewport()
    ImGui.SetNextWindowPos(use_work_area and viewport.WorkPos or viewport.Pos)
    ImGui.SetNextWindowSize(use_work_area and viewport.WorkSize or viewport.Size)

    local ret
    open, ret = ImGui.Begin("Example: Fullscreen window", open, flags)
    if ret then
        _, use_work_area = ImGui.Checkbox("Use work area instead of main area", use_work_area)
        ImGui.SameLine()

        _, flags = ImGui.CheckboxFlags("ImGuiWindowFlags.NoBackground", flags, ImGuiWindowFlags.NoBackground)
        _, flags = ImGui.CheckboxFlags("ImGuiWindowFlags.NoDecoration", flags, ImGuiWindowFlags.NoDecoration)
        ImGui.Indent()
        _, flags = ImGui.CheckboxFlags("ImGuiWindowFlags.NoTitleBar", flags, ImGuiWindowFlags.NoTitleBar)
        _, flags = ImGui.CheckboxFlags("ImGuiWindowFlags.NoCollapse", flags, ImGuiWindowFlags.NoCollapse)
        _, flags = ImGui.CheckboxFlags("ImGuiWindowFlags.NoScrollbar", flags, ImGuiWindowFlags.NoScrollbar)
        ImGui.Unindent()

        if open and ImGui.Button("Close this window") then
            open = false
        end
    end
    ImGui.End()

    return open
end

end

do

local demo_data = ImGuiDemoWindowData()

local no_titlebar       = false
local no_scrollbar      = false
local no_menu           = false
local no_move           = false
local no_resize         = false
local no_collapse       = false
local no_close          = false
local no_nav            = false
local no_background     = false
local no_bring_to_front = false
local no_docking        = false
local unsaved_document  = false

function ImGui.ShowDemoWindow(open)
    if demo_data.ShowAppCustomRendering then demo_data.ShowAppCustomRendering = ShowExampleAppCustomRendering(demo_data.ShowAppCustomRendering) end
    if demo_data.ShowAppImageViewer then demo_data.ShowAppImageViewer = ShowExampleAppImageViewer(demo_data.ShowAppImageViewer) end
    if demo_data.ShowAppFullscreen then demo_data.ShowAppFullscreen = ShowExampleAppFullscreen(demo_data.ShowAppFullscreen) end
    if demo_data.ShowAppLongText then demo_data.ShowAppLongText = ShowExampleAppLongText(demo_data.ShowAppLongText) end

    if demo_data.ShowMetrics then
        demo_data.ShowMetrics = ImGui.ShowMetricsWindow(demo_data.ShowMetrics)
    end
    if demo_data.ShowStyleEditor then
        demo_data.ShowStyleEditor = ImGui.Begin("ImGui Sincerely Style Editor", demo_data.ShowStyleEditor)
        ImGui.ShowStyleEditor()
        ImGui.End()
    end

    local window_flags = 0
    if no_titlebar       then window_flags = bit.bor(window_flags, ImGuiWindowFlags.NoTitleBar) end
    if no_scrollbar      then window_flags = bit.bor(window_flags, ImGuiWindowFlags.NoScrollbar) end
    if not no_menu       then window_flags = bit.bor(window_flags, ImGuiWindowFlags.MenuBar) end
    if no_move           then window_flags = bit.bor(window_flags, ImGuiWindowFlags.NoMove) end
    if no_resize         then window_flags = bit.bor(window_flags, ImGuiWindowFlags.NoResize) end
    if no_collapse       then window_flags = bit.bor(window_flags, ImGuiWindowFlags.NoCollapse) end
    if no_nav            then window_flags = bit.bor(window_flags, ImGuiWindowFlags.NoNav) end
    if no_background     then window_flags = bit.bor(window_flags, ImGuiWindowFlags.NoBackground) end
    if no_bring_to_front then window_flags = bit.bor(window_flags, ImGuiWindowFlags.NoBringToFrontOnFocus) end
    if no_docking        then window_flags = bit.bor(window_flags, ImGuiWindowFlags.NoDocking) end
    if unsaved_document  then window_flags = bit.bor(window_flags, ImGuiWindowFlags.UnsavedDocument) end
    if no_close          then open = nil end

    if not no_menu then window_flags = bit.bor(window_flags, ImGuiWindowFlags.MenuBar) end

    local ret -- is_visible
    open, ret = ImGui.Begin("ImGui Sincerely Demo", open, window_flags)
    if not ret then
        ImGui.End()
        return open
    end

    local label_width_base = ImGui.GetFontSize() * 12
    local label_width_max = ImGui.GetContentRegionAvail().x * 0.40
    local label_width = IM_MIN(label_width_base, label_width_max)
    ImGui.PushItemWidth(-label_width)

    DemoWindowMenuBar(demo_data)

    if ImGui.CollapsingHeader("Help") then
        ImGui.SeparatorText("ABOUT THIS DEMO:")
    end

    if ImGui.CollapsingHeader("Configuration") then
        
    end

    if ImGui.CollapsingHeader("Window Options") then
        if ImGui.BeginTable("split", 3) then
            ImGui.TableNextColumn() _, no_titlebar       = ImGui.Checkbox("No titlebar", no_titlebar)
            ImGui.TableNextColumn() _, no_scrollbar      = ImGui.Checkbox("No scrollbar", no_scrollbar)
            ImGui.TableNextColumn() _, no_menu           = ImGui.Checkbox("No menu", no_menu)
            ImGui.TableNextColumn() _, no_move           = ImGui.Checkbox("No move", no_move)
            ImGui.TableNextColumn() _, no_resize         = ImGui.Checkbox("No resize", no_resize)
            ImGui.TableNextColumn() _, no_collapse       = ImGui.Checkbox("No collapse", no_collapse)
            ImGui.TableNextColumn() _, no_close          = ImGui.Checkbox("No close", no_close)
            ImGui.TableNextColumn() _, no_nav            = ImGui.Checkbox("No nav", no_nav)
            ImGui.TableNextColumn() _, no_background     = ImGui.Checkbox("No background", no_background)
            ImGui.TableNextColumn() _, no_bring_to_front = ImGui.Checkbox("No bring to front", no_bring_to_front)
            ImGui.TableNextColumn() _, no_docking        = ImGui.Checkbox("No docking", no_docking)
            ImGui.TableNextColumn() _, unsaved_document  = ImGui.Checkbox("Unsaved document", unsaved_document)
            ImGui.EndTable()
        end
    end

    DemoWindowWidgets()
    DemoWindowLayout()
    DemoWindowPopups()
    DemoWindowTables()
    DemoWindowInputs()

    ImGui.End()

    return open
end

end
