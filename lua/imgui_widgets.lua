
--- @param bb     ImRect
--- @param id     ImGuiID
--- @param flags? ImGuiButtonFlags
function ImGui.ButtonBehavior(bb, id, flags)
    if flags == nil then flags = 0 end

    local g = ImGui.GetCurrentContext()

    local window = ImGui.GetCurrentWindow()

    local item_flags = (g.LastItemData.ID == id) and g.LastItemData.ItemFlags or g.CurrentItemFlags
    if bit.band(flags, ImGuiButtonFlags_AllowOverlap) ~= 0 then
        item_flags = bit.bor(item_flags, ImGuiItemFlags_AllowOverlap)
    end
    if bit.band(item_flags, ImGuiItemFlags_NoFocus) ~= 0 then
        flags = bit.bor(flags, ImGuiButtonFlags_NoFocus, ImGuiButtonFlags_NoNavFocus)
    end

    -- Default only reacts to left mouse button
    if bit.band(flags, ImGuiButtonFlags_MouseButtonMask_) == 0 then
        flags = bit.bor(flags, ImGuiButtonFlags_MouseButtonLeft)
    end

    -- Default behavior requires click + release inside bounding box
    if bit.band(flags, ImGuiButtonFlags_PressedOnMask_) == 0 then
        flags = bit.bor(flags, (bit.band(item_flags, ImGuiItemFlags_ButtonRepeat) ~= 0) and ImGuiButtonFlags_PressedOnClick or ImGuiButtonFlags_PressedOnDefault_)
    end

    local backup_hovered_window = g.HoveredWindow
    local flatten_hovered_children = (bit.band(flags, ImGuiButtonFlags_FlattenChildren) ~= 0) and g.HoveredWindow and g.HoveredWindow.RootWindow == window.RootWindow
    if flatten_hovered_children then
        g.HoveredWindow = window
    end

    local pressed = false
    local hovered = ImGui.ItemHoverable(id, bb)
    if g.DragDropActive then
        if (bit.band(flags, ImGuiButtonFlags_PressedOnDragDropHold) ~= 0) and (bit.band(g.DragDropSourceFlags, ImGuiDragDropFlags_SourceNoHoldToOpenOthers) == 0) and ImGui.IsItemHovered(ImGuiHoveredFlags_AllowWhenBlockedByActiveItem) then
            hovered = true
            ImGui.SetHoveredID(id)

            if (g.HoveredIdTimer - g.IO.DeltaTime <= DRAGDROP_HOLD_TO_OPEN_TIMER) and (g.HoveredIdTimer >= DRAGDROP_HOLD_TO_OPEN_TIMER) then
                pressed = true
                g.DragDropHoldJustPressedId = id
                ImGui.FocusWindow(window)
            end
        end

        if (g.DragDropAcceptIdPrev == id) and (bit.band(g.DragDropAcceptFlagsPrev, ImGuiDragDropFlags_AcceptDrawAsHovered) ~= 0) then
            hovered = true
        end
    end

    if (flatten_hovered_children) then
        g.HoveredWindow = backup_hovered_window
    end

    local test_owner_id = (bit.band(flags, ImGuiButtonFlags_NoTestKeyOwner) ~= 0) and ImGuiKeyOwner_Any or id
    if hovered then
        IM_ASSERT(id ~= 0)

        local mouse_button_clicked = -1
        local mouse_button_released = -1
        for button = 0, 2 do
            if bit.band(flags, bit.lshift(ImGuiButtonFlags_MouseButtonLeft, button)) ~= 0 then -- Handle ImGuiButtonFlags_MouseButtonRight and ImGuiButtonFlags_MouseButtonMiddle here.
                if (ImGui.IsMouseClicked(button, nil, ImGuiInputFlags_None, test_owner_id) and mouse_button_clicked == -1) then mouse_button_clicked = button end
                if (ImGui.IsMouseReleased(button, test_owner_id) and mouse_button_released == -1) then mouse_button_released = button end
            end
        end

        local mods_ok = (bit.band(flags, ImGuiButtonFlags_NoKeyModsAllowed) == 0) or (not g.IO.KeyCtrl and not g.IO.KeyShift and not g.IO.KeyAlt)
        if mods_ok then
            if mouse_button_clicked ~= -1 and g.ActiveId ~= id then
                if bit.band(flags, ImGuiButtonFlags_NoSetKeyOwner) == 0 then
                    ImGui.SetKeyOwner(ImGui.MouseButtonToKey(mouse_button_clicked), id)
                end

                if bit.band(flags, bit.bor(ImGuiButtonFlags_PressedOnClickRelease, ImGuiButtonFlags_PressedOnClickReleaseAnywhere)) ~= 0 then
                    ImGui.SetActiveID(id, window)
                    g.ActiveIdMouseButton = mouse_button_clicked

                    if bit.band(flags, ImGuiButtonFlags_NoNavFocus) == 0 then
                        ImGui.SetFocusID(id, window)
                        ImGui.FocusWindow(window)
                    elseif bit.band(flags, ImGuiButtonFlags_NoFocus) == 0 then
                        ImGui.FocusWindow(window, ImGuiFocusRequestFlags.RestoreFocusedChild)
                    end
                end

                if (bit.band(flags, ImGuiButtonFlags_PressedOnClick) ~= 0) or ((bit.band(flags, ImGuiButtonFlags_PressedOnDoubleClick) ~= 0) and g.IO.MouseClickedCount[mouse_button_clicked] == 2) then
                    pressed = true

                    if bit.band(flags, ImGuiButtonFlags_NoHoldingActiveId) ~= 0 then
                        ImGui.ClearActiveID()
                    else
                        ImGui.SetActiveID(id, window)
                    end

                    g.ActiveIdMouseButton = mouse_button_clicked

                    if bit.band(flags, ImGuiButtonFlags_NoNavFocus) == 0 then
                        ImGui.SetFocusID(id, window)
                        ImGui.FocusWindow(window)
                    elseif bit.band(flags, ImGuiButtonFlags_NoFocus) == 0 then
                        ImGui.FocusWindow(window, ImGuiFocusRequestFlags.RestoreFocusedChild)
                    end
                end
            end

            if bit.band(flags, ImGuiButtonFlags_PressedOnRelease) ~= 0 then
                if mouse_button_released ~= -1 then
                    local has_repeated_at_least_once = (bit.band(item_flags, ImGuiItemFlags_ButtonRepeat) ~= 0) and g.IO.MouseDownDurationPrev[mouse_button_released] >= g.IO.KeyRepeatDelay

                    if not has_repeated_at_least_once then
                        pressed = true
                    end

                    if bit.band(flags, ImGuiButtonFlags_NoNavFocus) == 0 then
                        ImGui.SetFocusID(id, window)  -- FIXME: Lack of FocusWindow() call here is inconsistent with other paths. Research why.
                    end

                    ImGui.ClearActiveID()
                end
            end

            if g.ActiveId == id and (bit.band(item_flags, ImGuiItemFlags_ButtonRepeat) ~= 0) then
                if g.IO.MouseDownDuration[g.ActiveIdMouseButton] > 0.0 and ImGui.IsMouseClicked(g.ActiveIdMouseButton, nil, ImGuiInputFlags_Repeat, test_owner_id) then
                    pressed = true
                end
            end
        end

        if pressed and g.IO.ConfigNavCursorVisibleAuto then
            g.NavCursorVisible = false
        end
    end

    -- TODO: Keyboard/Gamepad navigation handling

    local held = false
    if g.ActiveId == id then
        if g.ActiveIdSource == ImGuiInputSource_Mouse then
            if g.ActiveIdIsJustActivated then
                g.ActiveIdClickOffset = g.IO.MousePos - bb.Min
            end

            local mouse_button = g.ActiveIdMouseButton
            if mouse_button == -1 then
                -- Fallback for the rare situation were g.ActiveId was set programmatically or from another widget (e.g. #6304).
                ImGui.ClearActiveID()
            elseif ImGui.IsMouseDown(mouse_button, test_owner_id) then
                held = true
            else
                local release_in = hovered and (bit.band(flags, ImGuiButtonFlags_PressedOnClickRelease) ~= 0)
                local release_anywhere = (bit.band(flags, ImGuiButtonFlags_PressedOnClickReleaseAnywhere) ~= 0)

                if (release_in or release_anywhere) and not g.DragDropActive then
                    -- Report as pressed when releasing the mouse (this is the most common path)
                    local is_double_click_release = (bit.band(flags, ImGuiButtonFlags_PressedOnDoubleClick) ~= 0) and g.IO.MouseReleased[mouse_button] and g.IO.MouseClickedLastCount[mouse_button] == 2

                    local is_repeating_already = (bit.band(item_flags, ImGuiItemFlags_ButtonRepeat) ~= 0) and g.IO.MouseDownDurationPrev[mouse_button] >= g.IO.KeyRepeatDelay

                    local is_button_avail_or_owned = ImGui.TestKeyOwner(ImGui.MouseButtonToKey(mouse_button), test_owner_id)

                    if not is_double_click_release and not is_repeating_already and is_button_avail_or_owned then
                        pressed = true
                    end
                end

                ImGui.ClearActiveID()
            end

            if bit.band(flags, ImGuiButtonFlags_NoNavFocus) == 0 and g.IO.ConfigNavCursorVisibleAuto then
                g.NavCursorVisible = false
            end
        elseif g.ActiveIdSource == ImGuiInputSource_Keyboard or g.ActiveIdSource == ImGuiInputSource_Gamepad then
            -- When activated using Nav, we hold on the ActiveID until activation button is released
            if g.NavActivateDownId == id then
                held = true  -- hovered == true not true as we are already likely hovered on direct activation.
            else
                ImGui.ClearActiveID()
            end
        end

        if pressed then
            g.ActiveIdHasBeenPressedBefore = true
        end
    end

    if g.NavHighlightActivatedId == id and (bit.band(item_flags, ImGuiItemFlags_Disabled) == 0) then
        hovered = true
    end

    return pressed, hovered, held
end

--- @return boolean
function ImGui.CloseButton(id, pos)
    local g = ImGui.GetCurrentContext()

    local window = g.CurrentWindow

    local bb = ImRect(pos, pos + ImVec2(g.FontSize, g.FontSize))

    local is_clipped = not ImGui.ItemAdd(bb, id)

    local pressed, hovered = ImGui.ButtonBehavior(bb, id)
    if is_clipped then
        return pressed
    end

    if hovered then
        window.DrawList:AddRectFilled(bb.Min, bb.Max, ImGui.GetColorU32(ImGuiCol.ButtonHovered))
    end

    --- DrawLine draws lines of different thickness, why? Antialiasing
    -- AddText(window.DrawList, "X", "ImCloseButtonCross", x + w * 0.25, y, ImGui.GetColorU32(ImGuiCol.Text))
    local cross_center = bb:GetCenter() - ImVec2(0.5, 0.5)
    local cross_extent = g.FontSize * 0.5 * 0.7071 - 1

    window.DrawList:AddLine(cross_center + ImVec2(cross_extent, cross_extent), cross_center + ImVec2(-cross_extent, -cross_extent), ImGui.GetColorU32(ImGuiCol.Text), 1)
    window.DrawList:AddLine(cross_center + ImVec2(cross_extent, -cross_extent), cross_center + ImVec2(-cross_extent, cross_extent), ImGui.GetColorU32(ImGuiCol.Text), 1)

    return pressed
end

--- @return boolean
function ImGui.CollapseButton(id, pos)
    local g = ImGui.GetCurrentContext()

    local window = g.CurrentWindow

    local bb = ImRect(pos, pos + ImVec2(g.FontSize, g.FontSize))

    local is_clipped = not ImGui.ItemAdd(bb, id)

    local pressed, hovered = ImGui.ButtonBehavior(bb, id)

    if hovered then
        window.DrawList:AddRectFilled(bb.Min, bb.Max, ImGui.GetColorU32(ImGuiCol.ButtonHovered))
    end

    if window.Collapsed then
        ImGui.RenderArrow(window.DrawList, bb.Min, ImGui.GetColorU32(ImGuiCol.Text), ImGuiDir.Right, 1)
    else
        ImGui.RenderArrow(window.DrawList, bb.Min, ImGui.GetColorU32(ImGuiCol.Text), ImGuiDir.Down, 1)
    end

    return pressed
end

--- @param text      string
--- @param text_end? int
--- @param flags?    ImGuiTextFlags
function ImGui.TextEx(text, text_end, flags)
    if not flags then flags = 0 end

    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return
    end

    local g = ImGui.GetCurrentContext()

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
                ImGui.RenderText(pos, line_text, nil, false)
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
    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return
    end

    local text = string.format(fmt, ...)
    ImGui.TextEx(text, nil, ImGuiTextFlags.NoWidthForLargeClippedText)
end

--- @param col ImVec4
--- @param fmt string
--- @param ... any
function ImGui.TextColored(col, fmt, ...)
    ImGui.PushStyleColor(ImGuiCol.Text, col)
    ImGui.TextV(fmt, ...)
    ImGui.PopStyleColor()
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