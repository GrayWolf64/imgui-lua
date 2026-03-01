--- ImGui Sincerely WIP
-- (Demo Code)

local function IM_CLAMP(V, MN, MX) return (V < MN) and MN or (V > MX) and MX or V end

local DemoWindowWidgetsBasic
do

local clicked = 0
local checked = true
local radio_v = 0

local col0 = ImVec4(0, 0, 0, 1)
local col1 = ImVec4(0, 0, 0, 1)
local col2 = ImVec4(0, 0, 0, 1)

local counter = 0

function DemoWindowWidgetsBasic()
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
    ImGui.PushItemFlag(ImGuiItemFlags_ButtonRepeat, true)
    if ImGui.ArrowButton("##left", ImGuiDir.Left) then counter = counter - 1 end
    ImGui.SameLine(0.0, spacing)
    if ImGui.ArrowButton("##right", ImGuiDir.Right) then counter = counter + 1 end
    ImGui.PopItemFlag()
    ImGui.SameLine()
    ImGui.Text("%d", counter)

    ImGui.Button("Tooltip")
    ImGui.SetItemTooltip("I am a tooltip")

    ImGui.LabelText("label", "Value")
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

    if ImGui.BeginCombo("Picker Mode", picker_mode_names[picker_mode + 1], ImGuiComboFlags_None) then
        for mode_idx, mode_name in ipairs(picker_mode_names) do
            local pressed = ImGui.Selectable(mode_name, mode_idx == picker_mode + 1)
            if pressed then
                picker_mode = mode_idx - 1
            end
        end
        ImGui.EndCombo()
    end

    if ImGui.BeginCombo("Display Mode", display_mode_names[display_mode + 1], ImGuiComboFlags_None) then
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
    end
end

local DemoWindowWidgetsProgressBars do

local progress_accum = 0.0
local progress_dir = 1.0

function DemoWindowWidgetsProgressBars()
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
end

end

function ImGui.ShowDemoWindow(open)
    open = ImGui.Begin("ImGui Sincerely Demo", open)
    if not open then
        ImGui.End()
        return open
    end

    DemoWindowWidgetsBasic()
    DemoWindowWidgetsColorAndPickers()
    DemoWindowWidgetsPlotting()
    DemoWindowWidgetsProgressBars()

    ImGui.End()

    return open
end