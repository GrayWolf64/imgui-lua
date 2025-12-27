local function ButtonBehavior(button_id, bb)
    local g = GImGui

    local io = g.IO
    local hovered = ItemHoverable(button_id, bb)

    local pressed = false
    if hovered then
        if IsMouseClicked(1) then
            pressed = true

            SetActiveID(button_id, g.CurrentWindow) -- FIXME: is this correct?
        end
    end

    local held = false
    if g.ActiveID == button_id then
        if g.ActiveIDIsJustActivated then
            g.ActiveIDClickOffset = io.MousePos - bb.Min
        end

        if IsMouseDown(1) then
            held = true
        else
            ClearActiveID()
        end
    end

    return pressed, hovered, held
end

local function CloseButton(id, pos)
    local g = GImGui
    local window = g.CurrentWindow

    local bb = ImRect(pos, pos + ImVec2(g.FontSize, g.FontSize))

    local is_clipped = not ItemAdd(bb, id)

    local pressed, hovered = ButtonBehavior(id, bb)

    if hovered then
        window.DrawList:AddRectFilled(bb.Min, bb.Max, g.Style.Colors.ButtonHovered, 0, 0) -- TODO: 0 rounding
    end

    --- DrawLine draws lines of different thickness, why? Antialiasing
    -- AddText(window.DrawList, "X", "ImCloseButtonCross", x + w * 0.25, y, g.Style.Colors.Text)
    local cross_center = bb:GetCenter() - ImVec2(0.5, 0.5)
    local cross_extent = g.FontSize * 0.5 * 0.7071 - 1

    window.DrawList:AddLine(cross_center + ImVec2(cross_extent, cross_extent), cross_center + ImVec2(-cross_extent, -cross_extent), g.Style.Colors.Text, 1)
    window.DrawList:AddLine(cross_center + ImVec2(cross_extent, -cross_extent), cross_center + ImVec2(-cross_extent, cross_extent), g.Style.Colors.Text, 1)

    return pressed
end

local function CollapseButton(id, pos)
    local g = GImGui
    local window = g.CurrentWindow

    local bb = ImRect(pos, pos + ImVec2(g.FontSize, g.FontSize))

    local is_clipped = not ItemAdd(bb, id)

    local pressed, hovered = ButtonBehavior(id, bb)

    if hovered then
        window.DrawList:AddRectFilled(bb.Min, bb.Max, g.Style.Colors.ButtonHovered, 0, 0) -- TODO: 0 rounding
    end

    if window.Collapsed then
        RenderArrow(window.DrawList, bb.Min, g.Style.Colors.Text, ImDir.Right, 1)
    else
        RenderArrow(window.DrawList, bb.Min, g.Style.Colors.Text, ImDir.Down, 1)
    end

    return pressed
end