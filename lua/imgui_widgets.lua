function ImGui.ButtonBehavior(button_id, bb)
    local g = GImGui

    local io = g.IO
    local hovered = ImGui.ItemHoverable(button_id, bb)

    local pressed = false
    if hovered then
        if ImGui.IsMouseClicked(1) then
            pressed = true

            ImGui.SetActiveID(button_id, g.CurrentWindow) -- FIXME: is this correct?
        end
    end

    local held = false
    if g.ActiveId == button_id then
        if g.ActiveIdIsJustActivated then
            g.ActiveIDClickOffset = io.MousePos - bb.Min
        end

        if ImGui.IsMouseDown(1) then
            held = true
        else
            ImGui.ClearActiveID()
        end
    end

    return pressed, hovered, held
end

--- @return boolean
function ImGui.CloseButton(id, pos)
    local g = GImGui
    local window = g.CurrentWindow

    local bb = ImRect(pos, pos + ImVec2(g.FontSize, g.FontSize))

    local is_clipped = not ImGui.ItemAdd(bb, id)

    local pressed, hovered = ImGui.ButtonBehavior(id, bb)

    if hovered then
        window.DrawList:AddRectFilled(bb.Min, bb.Max, g.Style.Colors.ButtonHovered)
    end

    --- DrawLine draws lines of different thickness, why? Antialiasing
    -- AddText(window.DrawList, "X", "ImCloseButtonCross", x + w * 0.25, y, g.Style.Colors.Text)
    local cross_center = bb:GetCenter() - ImVec2(0.5, 0.5)
    local cross_extent = g.FontSize * 0.5 * 0.7071 - 1

    window.DrawList:AddLine(cross_center + ImVec2(cross_extent, cross_extent), cross_center + ImVec2(-cross_extent, -cross_extent), g.Style.Colors.Text, 1)
    window.DrawList:AddLine(cross_center + ImVec2(cross_extent, -cross_extent), cross_center + ImVec2(-cross_extent, cross_extent), g.Style.Colors.Text, 1)

    return pressed
end

--- @return boolean
function ImGui.CollapseButton(id, pos)
    local g = GImGui
    local window = g.CurrentWindow

    local bb = ImRect(pos, pos + ImVec2(g.FontSize, g.FontSize))

    local is_clipped = not ImGui.ItemAdd(bb, id)

    local pressed, hovered = ImGui.ButtonBehavior(id, bb)

    if hovered then
        window.DrawList:AddRectFilled(bb.Min, bb.Max, g.Style.Colors.ButtonHovered)
    end

    if window.Collapsed then
        ImGui.RenderArrow(window.DrawList, bb.Min, g.Style.Colors.Text, ImGuiDir.Right, 1)
    else
        ImGui.RenderArrow(window.DrawList, bb.Min, g.Style.Colors.Text, ImGuiDir.Down, 1)
    end

    return pressed
end

--- @param text      string
--- @param text_end? int
--- @param flags?    int
function ImGui.TextEx(text, text_end, flags)
    if not flags then flags = 0 end

    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then return end
    local g = GImGui

    if not text or text == "" then
        text = ""
        text_end = 1
    end

    if text_end == nil then
        text_end = #text + 1
    end

    local text_pos = ImVec2(window.DC.CursorPos.x, window.DC.CursorPos.y + window.DC.CurrLineTextBaseOffset)
    local wrap_pos_x = window.DC.TextWrapPos
    local wrap_enabled = (wrap_pos_x >= 0.0)
    if (text_end - 1 <= 2000) or wrap_enabled then
        local wrap_width = wrap_enabled and ImGui.CalcWrapWidthForPos(window.DC.CursorPos, wrap_pos_x) or 0.0
        local text_size = ImGui.CalcTextSize(text, text_end, false, wrap_width)

        local bb = ImRect(text_pos, text_pos + text_size)
        ImGui.ItemSize(text_size, 0.0)
        if not ImGui.ItemAdd(bb, 0) then
            return
        end

        ImGui.RenderTextWrapped(bb.Min, text, text_end, wrap_width)
    else
        local line = 1
        local line_height = ImGui.GetTextLineHeight()
        local text_size = ImVec2(0, 0)

        local pos = ImVec2(text_pos.x, text_pos.y)
        if not g.LogEnabled then
            local lines_skippable = ImFloor((window.ClipRect.Min.y - text_pos.y) / line_height)
            if lines_skippable > 0 then
                local lines_skipped = 0
                while line < text_end and lines_skipped < lines_skippable do
                    local line_end = ImMemchr(text, "\n", line)
                    if not line_end then
                        line_end = text_end
                    end
                    if bit.band(flags, ImGuiTextFlags.NoWidthForLargeClippedText) == 0 then
                        local line_text = string.sub(text, line, line_end - 1)
                        local line_size = ImGui.CalcTextSize(line_text)
                        text_size.x = ImMax(text_size.x, line_size.x)
                    end
                    line = line_end + 1
                    lines_skipped = lines_skipped + 1
                end
                pos.y = pos.y + lines_skipped * line_height
            end
        end

        if line < text_end then
            local line_rect = ImRect(pos, pos + ImVec2(FLT_MAX, line_height))
            while line < text_end do
                if ImGui.IsClippedEx(line_rect, 0) then
                    break
                end

                local line_end = ImMemchr(text, "\n", line)
                if not line_end then
                    line_end = text_end
                end
                local line_text = string.sub(text, line, line_end - 1)
                local line_size = ImGui.CalcTextSize(line_text)
                text_size.x = ImMax(text_size.x, line_size.x)
                ImGui.RenderText(pos, line_text)
                line = line_end + 1
                line_rect.Min.y = line_rect.Min.y + line_height
                line_rect.Max.y = line_rect.Max.y + line_height
                pos.y = pos.y + line_height
            end

            local lines_skipped = 0
            while line < text_end do
                local line_end = ImMemchr(text, "\n", line)
                if not line_end then
                    line_end = text_end
                end
                if bit.band(flags, ImGuiTextFlags.NoWidthForLargeClippedText) == 0 then
                    local line_text = string.sub(text, line, line_end - 1)
                    local line_size = ImGui.CalcTextSize(line_text)
                    text_size.x = ImMax(text_size.x, line_size.x)
                end
                line = line_end + 1
                lines_skipped = lines_skipped + 1
            end
            pos.y = pos.y + lines_skipped * line_height
        end
        text_size.y = pos.y - text_pos.y

        local bb = ImRect(text_pos, text_pos + text_size)
        ImGui.ItemSize(text_size, 0.0)
        ImGui.ItemAdd(bb, 0)
    end
end

--- @param fmt string
--- @param ... any
function ImGui.TextV(fmt, ...)
    local text = string.format(fmt, ...)
    ImGui.TextEx(text)
end

--- @param fmt string
--- @param ... any
function ImGui.Text(fmt, ...)
    if select('#', ...) > 0 then
        ImGui.TextV(fmt, ...)
    else
        ImGui.TextEx(fmt)
    end
end