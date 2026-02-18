--- ImGui Sincerely WIP
-- (Demo Code)

local DemoWindowWidgetsBasic
do

local clicked = 0
local checked = true
local radio_v = 0

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
        -- TODO: Styling
        ImGui.Button("Click")
        ImGui.PopID()
    end
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
            ImGui.ColorEdit4("##RefColor", ref_color_v.x, bit.bor(ImGuiColorEditFlags.NoInputs, base_flags))
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

    ImGui.ColorPicker4("MyColor##4", color, flags, ref_color and ref_color_v.x or nil)
end

end

local open = true

function ImGui.ShowDemoWindow()
    open = ImGui.Begin("ImGui Sincerely Demo", open)
    if not open then
        ImGui.End()
        return
    end

    DemoWindowWidgetsBasic()
    DemoWindowWidgetsColorAndPickers()

    ImGui.End()
end