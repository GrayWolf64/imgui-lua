--- ImGui Sincerely WIP
-- (Widgets Code)

----------------------------------------------------------------
-- [SECTION] TEXT
----------------------------------------------------------------

--- @param text      string
--- @param text_end? int
--- @param flags?    ImGuiTextFlags
function ImGui.TextEx(text, text_end, flags)
    if not flags then flags = 0 end

    local g = ImGui.GetCurrentContext()
    local window = g.CurrentWindow
    if window.SkipItems then
        return
    end

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

--- @param text      string
--- @param text_end? int
function ImGui.TextUnformatted(text, text_end)
    ImGui.TextEx(text, text_end, ImGuiTextFlags.NoWidthForLargeClippedText)
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

--- @param fmt string
--- @param ... any
function ImGui.Text(fmt, ...)
    if select('#', ...) > 0 then
        ImGui.TextV(fmt, ...)
    else
        ImGui.TextEx(fmt)
    end
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
function ImGui.TextDisabled(fmt, ...)
    local g = ImGui.GetCurrentContext()
    ImGui.PushStyleColor(ImGuiCol.Text, g.Style.Colors[ImGuiCol.TextDisabled])
    ImGui.TextV(fmt, ...)
    ImGui.PopStyleColor()
end

--- @param fmt string
--- @param ... any
function ImGui.TextWrapped(fmt, ...)
    local g = ImGui.GetCurrentContext()
    local need_backup = (g.CurrentWindow.DC.TextWrapPos < 0.0)
    if need_backup then
        ImGui.PushTextWrapPos(0.0)
    end
    ImGui.TextV(fmt, ...)
    if need_backup then
        ImGui.PopTextWrapPos()
    end
end

----------------------------------------------------------------
-- [SECTION] BUTTONS, SCROLLBARS
----------------------------------------------------------------

--- @param bb     ImRect
--- @param id     ImGuiID
--- @param flags? ImGuiButtonFlags
function ImGui.ButtonBehavior(bb, id, flags)
    if flags == nil then flags = 0 end

    local g = ImGui.GetCurrentContext()

    local window = g.CurrentWindow

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
    local hovered = ImGui.ItemHoverable(id, bb, item_flags)
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
                --- @cast mouse_button_clicked ImGuiMouseButton

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
        if g.ActiveIdSource == ImGuiInputSource.Mouse then
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
        elseif g.ActiveIdSource == ImGuiInputSource.Keyboard or g.ActiveIdSource == ImGuiInputSource.Gamepad then
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

--- @param label     string
--- @param size_arg? ImVec2
--- @param flags?    ImGuiButtonFlags
--- @return bool
function ImGui.ButtonEx(label, size_arg, flags)
    if size_arg == nil then size_arg = ImVec2(0, 0) end
    if flags    == nil then flags    = 0            end

    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return false
    end

    local g = ImGui.GetCurrentContext()
    local style = g.Style
    local id = window:GetID(label)
    local label_size = ImGui.CalcTextSize(label, nil, true)

    local pos = window.DC.CursorPos:copy() -- Don't modify the cursor!
    if bit.band(flags, ImGuiButtonFlags_AlignTextBaseLine) ~= 0 and style.FramePadding.y < window.DC.CurrLineTextBaseOffset then
        pos.y = pos.y + window.DC.CurrLineTextBaseOffset - style.FramePadding.y
    end
    local size = ImGui.CalcItemSize(size_arg, label_size.x + style.FramePadding.x * 2.0, label_size.y + style.FramePadding.y * 2.0)

    local bb = ImRect(pos, pos + size)
    ImGui.ItemSize(size, style.FramePadding.y)
    if not ImGui.ItemAdd(bb, id) then
        return false
    end

    local pressed, hovered, held = ImGui.ButtonBehavior(bb, id, flags)

    local col
    if held and hovered then
        col = ImGui.GetColorU32(ImGuiCol.ButtonActive)
    elseif hovered then
        col = ImGui.GetColorU32(ImGuiCol.ButtonHovered)
    else
        col = ImGui.GetColorU32(ImGuiCol.Button)
    end

    -- TODO: RenderNavCursor(bb, id);
    ImGui.RenderFrame(bb.Min, bb.Max, col, true, style.FrameRounding)

    -- if (g.LogEnabled)
    --     LogSetNextTextDecoration("[", "]");
    ImGui.RenderTextClipped(bb.Min + style.FramePadding, bb.Max - style.FramePadding, label, 1, nil, label_size, style.ButtonTextAlign, bb)

    -- Automatically close popups
    --if (pressed && !(flags & ImGuiButtonFlags_DontClosePopups) && (window->Flags & ImGuiWindowFlags_Popup))
    --    CloseCurrentPopup();

    -- IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags);
    return pressed
end

--- @param label     string
--- @param size_arg? ImVec2
--- @return bool
function ImGui.Button(label, size_arg)
    return ImGui.ButtonEx(label, size_arg, ImGuiButtonFlags_None)
end

--- @param label string
--- @return bool
function ImGui.SmallButton(label)
    local g = ImGui.GetCurrentContext()
    local backup_padding_y = g.Style.FramePadding.y
    g.Style.FramePadding.y = 0.0
    local pressed = ImGui.ButtonEx(label, ImVec2(0, 0), ImGuiButtonFlags_AlignTextBaseLine)
    g.Style.FramePadding.y = backup_padding_y
    return pressed
end

--- @param id  ImGuiID
--- @param pos ImVec2
--- @return bool
function ImGui.CloseButton(id, pos)
    local g = ImGui.GetCurrentContext()

    local window = g.CurrentWindow

    local bb = ImRect(pos, pos + ImVec2(g.FontSize, g.FontSize))
    local bb_interact = bb:copy()
    local area_to_visible_ratio = window.OuterRectClipped:GetArea() / bb:GetArea()
    if area_to_visible_ratio < 1.5 then
        bb_interact:ExpandV2(ImTruncV2(bb_interact:GetSize() * -0.25))
    end

    local is_clipped = not ImGui.ItemAdd(bb_interact, id)

    local pressed, hovered, held = ImGui.ButtonBehavior(bb, id)
    if is_clipped then
        return pressed
    end

    local bg_col
    if held then
        bg_col = ImGui.GetColorU32(ImGuiCol.ButtonActive)
    else
        bg_col = ImGui.GetColorU32(ImGuiCol.ButtonHovered)
    end

    if hovered then
        window.DrawList:AddRectFilled(bb.Min, bb.Max, bg_col)
    end

    --- DrawLine draws lines of different thickness, why? Antialiasing
    -- AddText(window.DrawList, "X", "ImCloseButtonCross", x + w * 0.25, y, ImGui.GetColorU32(ImGuiCol.Text))
    local cross_center = bb:GetCenter() - ImVec2(0.5, 0.5)
    local cross_extent = g.FontSize * 0.5 * 0.7071 - 1
    local cross_col = ImGui.GetColorU32(ImGuiCol.Text)
    local cross_thickness = 1.0 -- FIXME-DPI
    window.DrawList:AddLine(cross_center + ImVec2(cross_extent, cross_extent), cross_center + ImVec2(-cross_extent, -cross_extent), cross_col, cross_thickness)
    window.DrawList:AddLine(cross_center + ImVec2(cross_extent, -cross_extent), cross_center + ImVec2(-cross_extent, cross_extent), cross_col, cross_thickness)

    return pressed
end

--- @return bool
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

--- @param window ImGuiWindow
--- @param axis   ImGuiAxis
--- @return ImGuiID
function ImGui.GetWindowScrollbarID(window, axis)
    if axis == ImGuiAxis.X then
        return window:GetID("#SCROLLX")
    else
        return window:GetID("#SCROLLY")
    end
end

--- @param window ImGuiWindow
--- @param axis   ImGuiAxis
--- @return ImRect
--- @nodiscard
function ImGui.GetWindowScrollbarRect(window, axis)
    local g = GImGui
    local outer_rect = window:Rect()
    local inner_rect = window.InnerRect

    -- (ScrollbarSizes.x = width of Y scrollbar; ScrollbarSizes.y = height of X scrollbar)
    local scrollbar_size = window.ScrollbarSizes[ImAxisToStr[axis == ImGuiAxis.X and ImGuiAxis.Y or ImGuiAxis.X]]
    IM_ASSERT(scrollbar_size >= 0.0)

    local border_size = IM_ROUND(window.WindowBorderSize * 0.5)
    local border_top = (bit.band(window.Flags, ImGuiWindowFlags_MenuBar) ~= 0) and IM_ROUND(g.Style.FrameBorderSize * 0.5) or 0.0

    if axis == ImGuiAxis.X then
        return ImRect(inner_rect.Min.x + border_size, ImMax(outer_rect.Min.y + border_size, outer_rect.Max.y - border_size - scrollbar_size), inner_rect.Max.x - border_size, outer_rect.Max.y - border_size)
    else
        return ImRect(ImMax(outer_rect.Min.x, outer_rect.Max.x - border_size - scrollbar_size), inner_rect.Min.y + border_top, outer_rect.Max.x - border_size, inner_rect.Max.y - border_size)
    end
end

--- @param bb_frame            ImRect
--- @param id                  ImGuiID
--- @param axis                ImGuiAxis
--- @param p_scroll_v          ImS64
--- @param size_visible_v      ImS64
--- @param size_contents_v     ImS64
--- @param draw_rounding_flags ImDrawFlags
--- @return bool  is_held
--- @return ImS64 scroll_v # Updated p_scroll_v
function ImGui.ScrollbarEx(bb_frame, id, axis, p_scroll_v, size_visible_v, size_contents_v, draw_rounding_flags)
    local g = ImGui.GetCurrentContext()
    local window = g.CurrentWindow
    if window.SkipItems then
        return false, p_scroll_v
    end

    local bb_frame_width = bb_frame:GetWidth()
    local bb_frame_height = bb_frame:GetHeight()
    if bb_frame_width <= 0.0 or bb_frame_height <= 0.0 then
        return false, p_scroll_v
    end

    local alpha = 1.0
    if axis == ImGuiAxis.Y and bb_frame_height < bb_frame_width then
        alpha = ImSaturate(bb_frame_height / ImMax(bb_frame_width * 2.0, 1.0))
    end
    if alpha <= 0.0 then
        return false, p_scroll_v
    end

    local style = g.Style
    local allow_interaction = (alpha >= 1.0)

    local bb = bb_frame:copy()
    local padding = IM_TRUNC(ImMin(style.ScrollbarPadding, ImMin(bb_frame_width, bb_frame_height) * 0.5))
    bb:Expand(-padding)

    -- V denote the main, longer axis of the scrollbar (= height for a vertical scrollbar)
    local scrollbar_size_v
    if axis == ImGuiAxis.X then
        scrollbar_size_v = bb:GetWidth()
    else
        scrollbar_size_v = bb:GetHeight()
    end

    if scrollbar_size_v < 1.0 then
        return false, p_scroll_v
    end

    IM_ASSERT(ImMax(size_contents_v, size_visible_v) > 0.0)
    local win_size_v = ImMax(ImMax(size_contents_v, size_visible_v), 1)
    local grab_h_minsize = ImMin(bb:GetSize()[ImAxisToStr[axis]], style.GrabMinSize)
    local grab_h_pixels = ImClamp(scrollbar_size_v * (size_visible_v / win_size_v), grab_h_minsize, scrollbar_size_v)
    local grab_h_norm = grab_h_pixels / scrollbar_size_v

    ImGui.ItemAdd(bb_frame, id, nil, ImGuiItemFlags_NoNav)
    local pressed, hovered, held = ImGui.ButtonBehavior(bb, id, ImGuiButtonFlags_NoNavFocus)

    local scroll_max = ImMax(1, size_contents_v - size_visible_v)
    local scroll_ratio = ImSaturate(p_scroll_v / scroll_max)
    local grab_v_norm = scroll_ratio * (scrollbar_size_v - grab_h_pixels) / scrollbar_size_v
    if held and allow_interaction and grab_h_norm < 1.0 then
        local scrollbar_pos_v = bb.Min[ImAxisToStr[axis]]
        local mouse_pos_v = g.IO.MousePos[ImAxisToStr[axis]]
        local clicked_v_norm = ImSaturate((mouse_pos_v - scrollbar_pos_v) / scrollbar_size_v)

        local held_dir
        if clicked_v_norm < grab_v_norm then
            held_dir = -1
        elseif clicked_v_norm > grab_v_norm + grab_h_norm then
            held_dir = 1
        else
            held_dir = 0
        end
        if g.ActiveIdIsJustActivated then
            local scroll_to_clicked_location = (g.IO.ConfigScrollbarScrollByPage == false) or g.IO.KeyShift or held_dir == 0

            if scroll_to_clicked_location then
                g.ScrollbarSeekMode = 0
            else
                g.ScrollbarSeekMode = held_dir
            end

            if held_dir == 0 and not g.IO.KeyShift then
                g.ScrollbarClickDeltaToGrabCenter = clicked_v_norm - grab_v_norm - grab_h_norm * 0.5
            else
                g.ScrollbarClickDeltaToGrabCenter = 0.0
            end
        end

        if g.ScrollbarSeekMode == 0 then
            scroll_v_norm = ImSaturate((clicked_v_norm - g.ScrollbarClickDeltaToGrabCenter - grab_h_norm * 0.5) / (1.0 - grab_h_norm))
            p_scroll_v = scroll_v_norm * scroll_max
        else
            if ImGui.IsMouseClicked(ImGuiMouseButton.Left, nil, ImGuiInputFlags_Repeat) and held_dir == g.ScrollbarSeekMode then
                local page_dir
                if g.ScrollbarSeekMode > 0.0 then
                    page_dir = 1.0
                else
                    page_dir = -1.0
                end
                p_scroll_v = ImClamp(p_scroll_v + page_dir * size_visible_v, 0, scroll_max)
            end
        end

        scroll_ratio = ImSaturate(p_scroll_v / scroll_max)
        grab_v_norm = scroll_ratio * (scrollbar_size_v - grab_h_pixels) / scrollbar_size_v
    end

    local bg_col = ImGui.GetColorU32(ImGuiCol.ScrollbarBg)
    local grab_col
    if held then
        grab_col = ImGui.GetColorU32(ImGuiCol.ScrollbarGrabActive, alpha)
    elseif hovered then
        grab_col = ImGui.GetColorU32(ImGuiCol.ScrollbarGrabHovered, alpha)
    else
        grab_col = ImGui.GetColorU32(ImGuiCol.ScrollbarGrab, alpha)
    end
    window.DrawList:AddRectFilled(bb_frame.Min, bb_frame.Max, bg_col, window.WindowRounding, draw_rounding_flags)
    local grab_rect
    if axis == ImGuiAxis_X then
        local x1 = ImLerp(bb.Min.x, bb.Max.x, grab_v_norm)
        grab_rect = ImRect(x1, bb.Min.y, x1 + grab_h_pixels, bb.Max.y)
    else
        local y1 = ImLerp(bb.Min.y, bb.Max.y, grab_v_norm)
        grab_rect = ImRect(bb.Min.x, y1, bb.Max.x, y1 + grab_h_pixels)
    end

    window.DrawList:AddRectFilled(grab_rect.Min, grab_rect.Max, grab_col, style.ScrollbarRounding)

    return held, p_scroll_v
end

--- @param axis ImGuiAxis
function ImGui.Scrollbar(axis)
    local g = ImGui.GetCurrentContext()
    local window = g.CurrentWindow
    local id = ImGui.GetWindowScrollbarID(window, axis)

    -- Calculate scrollbar bounding box
    local bb = ImGui.GetWindowScrollbarRect(window, axis)
    local axis_str = ImAxisToStr[axis]
    local rounding_corners = ImGui.CalcRoundingFlagsForRectInRect(bb, window:Rect(), g.Style.WindowBorderSize)
    local size_visible = window.InnerRect.Max[axis_str] - window.InnerRect.Min[axis_str]
    local size_contents = window.ContentSize[axis_str] + window.WindowPadding[axis_str] * 2.0
    local scroll = window.Scroll[axis_str]
    local held
    held, scroll = ImGui.ScrollbarEx(bb, id, axis, scroll, size_visible, size_contents, rounding_corners)
    window.Scroll[axis_str] = scroll
end

--- @param label string
--- @param v     bool
--- @return bool is_pressed
--- @return bool is_checked # The updated `v` passed in
function ImGui.Checkbox(label, v)
    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return false, v
    end

    local g = ImGui.GetCurrentContext()
    local style = g.Style
    local id = window:GetID(label)
    local label_size = ImGui.CalcTextSize(label, nil, true)

    local square_sz = ImGui.GetFrameHeight()
    local pos = window.DC.CursorPos:copy()
    local total_width
    if label_size.x > 0.0 then
        total_width = square_sz + style.ItemInnerSpacing.x + label_size.x
    else
        total_width = square_sz
    end
    local total_bb = ImRect(pos, pos + ImVec2(total_width, label_size.y + style.FramePadding.y * 2.0))
    ImGui.ItemSizeR(total_bb, style.FramePadding.y)
    local is_visible = ImGui.ItemAdd(total_bb, id)
    local is_multi_select = (bit.band(g.LastItemData.ItemFlags, ImGuiItemFlags_IsMultiSelect) ~= 0)
    if not is_visible then
        if not is_multi_select or not g.BoxSelectState.UnclipMode or not g.BoxSelectState.UnclipRect:Overlaps(total_bb) then  -- Extra layer of "no logic clip" for box-select support
            -- IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags | ImGuiItemStatusFlags_Checkable | (*v ? ImGuiItemStatusFlags_Checked : 0))
            return false, v
        end
    end

    local checked = v
    if is_multi_select then
        -- TODO: MultiSelectItemHeader(id, &checked, NULL)
    end

    local pressed, hovered, held = ImGui.ButtonBehavior(total_bb, id)

    if is_multi_select then
        -- MultiSelectItemFooter(id, &checked, &pressed);
    elseif pressed then
        checked = not checked
    end

    if v ~= checked then
        v = checked
        pressed = true
        -- MarkItemEdited(id);
    end

    local check_bb = ImRect(pos, pos + ImVec2(square_sz, square_sz))
    local mixed_value = (bit.band(g.LastItemData.ItemFlags, ImGuiItemFlags_MixedValue) ~= 0)
    if is_visible then
        -- ImGui.RenderNavCursor(total_bb, id)

        local frame_col
        if held and hovered then
            frame_col = ImGui.GetColorU32(ImGuiCol.FrameBgActive)
        elseif hovered then
            frame_col = ImGui.GetColorU32(ImGuiCol.FrameBgHovered)
        else
            frame_col = ImGui.GetColorU32(ImGuiCol.FrameBg)
        end

        ImGui.RenderFrame(check_bb.Min, check_bb.Max, frame_col, true, style.FrameRounding)

        local check_col = ImGui.GetColorU32(ImGuiCol.CheckMark)

        if mixed_value then
            -- Undocumented tristate/mixed/indeterminate checkbox (#2644)
            -- This may seem awkwardly designed because the aim is to make ImGuiItemFlags_MixedValue supported by all widgets (not just checkbox)
            local pad_val = ImMax(1.0, IM_TRUNC(square_sz / 3.6))
            local pad = ImVec2(pad_val, pad_val)
            window.DrawList:AddRectFilled(check_bb.Min + pad, check_bb.Max - pad, check_col, style.FrameRounding)
        elseif v then
            local pad = ImMax(1.0, IM_TRUNC(square_sz / 6.0))
            ImGui.RenderCheckMark(window.DrawList, check_bb.Min + ImVec2(pad, pad), check_col, square_sz - pad * 2.0)
        end
    end

    local label_pos = ImVec2(check_bb.Max.x + style.ItemInnerSpacing.x, check_bb.Min.y + style.FramePadding.y)
    if g.LogEnabled then
        -- local log_text
        -- if mixed_value then
        --     log_text = "[~]"
        -- elseif v then
        --     log_text = "[x]"
        -- else
        --     log_text = "[ ]"
        -- end
        -- ImGui.LogRenderedText(label_pos, log_text)
    end

    if is_visible and label_size.x > 0.0 then
        ImGui.RenderText(label_pos, label)
    end

    -- IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags | ImGuiItemStatusFlags_Checkable | (*v ? ImGuiItemStatusFlags_Checked : 0))
    return pressed, v
end

----------------------------------------------------------------
-- [SECTION] Low-level Layout helpers
----------------------------------------------------------------

function ImGui.Spacing()
    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return
    end
    ImGui.ItemSize(ImVec2(0, 0))
end

--- @param size ImVec2
function ImGui.Dummy(size)
    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return
    end

    local bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + size)
    ImGui.ItemSize(size)
    ImGui.ItemAdd(bb, 0)
end

function ImGui.NewLine()
    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return
    end

    local g = ImGui.GetCurrentContext()
    local backup_layout_type = window.DC.LayoutType
    window.DC.LayoutType = ImGuiLayoutType.Vertical
    window.DC.IsSameLine = false

    if window.DC.CurrLineSize.y > 0.0 then
        -- In the event that we are on a line with items that is smaller that FontSize high, we will preserve its height.
        ImGui.ItemSize(ImVec2(0, 0))
    else
        ImGui.ItemSize(ImVec2(0.0, g.FontSize))
    end

    window.DC.LayoutType = backup_layout_type
end

function ImGui.AlignTextToFramePadding()
    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return
    end

    local g = ImGui.GetCurrentContext()
    window.DC.CurrLineSize.y = ImMax(window.DC.CurrLineSize.y, g.FontSize + g.Style.FramePadding.y * 2)
    window.DC.CurrLineTextBaseOffset = ImMax(window.DC.CurrLineTextBaseOffset, g.Style.FramePadding.y)
end

--- @param flags     ImGuiSeparatorFlags
--- @param thickness float
function ImGui.SeparatorEx(flags, thickness)
    if thickness == nil then thickness = 1.0 end

    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return
    end

    local g = ImGui.GetCurrentContext()
    IM_ASSERT(ImIsPowerOfTwo(bit.band(flags, bit.bor(ImGuiSeparatorFlags.Horizontal, ImGuiSeparatorFlags.Vertical)))) -- Check that only 1 option is selected
    IM_ASSERT(thickness > 0.0)

    if bit.band(flags, ImGuiSeparatorFlags.Vertical) ~= 0 then
        -- Vertical separator, for menu bars (use current line height).
        local y1 = window.DC.CursorPos.y
        local y2 = window.DC.CursorPos.y + window.DC.CurrLineSize.y
        local bb = ImRect(ImVec2(window.DC.CursorPos.x, y1), ImVec2(window.DC.CursorPos.x + thickness, y2))
        ImGui.ItemSize(ImVec2(thickness, 0.0))
        if not ImGui.ItemAdd(bb, 0) then
            return
        end

        -- Draw
        window.DrawList:AddRectFilled(bb.Min, bb.Max, ImGui.GetColorU32(ImGuiCol.Separator))
        if g.LogEnabled then
            ImGui.LogText(" |")
        end
    elseif bit.band(flags, ImGuiSeparatorFlags.Horizontal) ~= 0 then
        -- Horizontal Separator
        local x1 = window.DC.CursorPos.x
        local x2 = window.WorkRect.Max.x

        -- Preserve legacy behavior inside Columns()
        -- Before Tables API happened, we relied on Separator() to span all columns of a Columns() set.
        -- We currently don't need to provide the same feature for tables because tables naturally have border features.
        local columns = (bit.band(flags, ImGuiSeparatorFlags.SpanAllColumns) ~= 0) and window.DC.CurrentColumns or nil
        if columns then
            x1 = window.Pos.x + window.DC.Indent.x  -- Used to be Pos.x before 2023/10/03
            x2 = window.Pos.x + window.Size.x
            ImGui.PushColumnsBackground()
        end

        -- We don't provide our width to the layout so that it doesn't get feed back into AutoFit
        -- FIXME: This prevents ->CursorMaxPos based bounding box evaluation from working (e.g. TableEndCell)
        local thickness_for_layout = (thickness == 1.0) and 0.0 or thickness  -- FIXME: See 1.70/1.71 Separator() change: makes legacy 1-px separator not affect layout yet. Should change.
        local bb = ImRect(ImVec2(x1, window.DC.CursorPos.y), ImVec2(x2, window.DC.CursorPos.y + thickness))
        ImGui.ItemSize(ImVec2(0.0, thickness_for_layout))

        if ImGui.ItemAdd(bb, 0) then
            -- Draw
            window.DrawList:AddRectFilled(bb.Min, bb.Max, ImGui.GetColorU32(ImGuiCol.Separator))
            if g.LogEnabled then
                ImGui.LogRenderedText(bb.Min, "--------------------------------\n")
            end
        end

        if columns then
            ImGui.PopColumnsBackground()
            columns.LineMinY = window.DC.CursorPos.y
        end
    end
end

function ImGui.Separator()
    local g = ImGui.GetCurrentContext()
    local window = g.CurrentWindow
    if window.SkipItems then
        return
    end

    -- Those flags should eventually be configurable by the user
    -- FIXME: We cannot g.Style.SeparatorTextBorderSize for thickness as it relates to SeparatorText() which is a decorated separator, not defaulting to 1.0f.
    local flags
    if window.DC.LayoutType == ImGuiLayoutType.Horizontal then
        flags = ImGuiSeparatorFlags.Vertical
    else
        flags = ImGuiSeparatorFlags.Horizontal
    end

    -- Only applies to legacy Columns() api as they relied on Separator() a lot.
    if window.DC.CurrentColumns then
        flags = bit.bor(flags, ImGuiSeparatorFlags.SpanAllColumns)
    end

    ImGui.SeparatorEx(flags, 1.0)
end

--- @param id         ImGuiID
--- @param label      string
--- @param label_end? int
--- @param extra_w    float
function ImGui.SeparatorTextEx(id, label, label_end, extra_w)
    local g = ImGui.GetCurrentContext()
    local window = g.CurrentWindow
    local style = g.Style

    local label_size = ImGui.CalcTextSize(label, label_end, false)
    local pos = ImVec2(window.DC.CursorPos.x, window.DC.CursorPos.y)
    local padding = style.SeparatorTextPadding

    local separator_thickness = style.SeparatorTextBorderSize
    local min_size = ImVec2(label_size.x + extra_w + padding.x * 2.0, ImMax(label_size.y + padding.y * 2.0, separator_thickness))

    local bb = ImRect(pos, ImVec2(window.WorkRect.Max.x, pos.y + min_size.y))
    local text_baseline_y = ImTrunc((bb:GetHeight() - label_size.y) * style.SeparatorTextAlign.y + 0.99999)  -- ImMax(padding.y, ImTrunc((style.SeparatorTextSize - label_size.y) * 0.5f))

    ImGui.ItemSize(min_size, text_baseline_y)
    if not ImGui.ItemAdd(bb, id) then
        return
    end

    local sep1_x1 = pos.x
    local sep2_x2 = bb.Max.x
    local seps_y = ImTrunc((bb.Min.y + bb.Max.y) * 0.5 + 0.99999)

    local label_avail_w = ImMax(0.0, sep2_x2 - sep1_x1 - padding.x * 2.0)
    local label_pos = ImVec2(pos.x + padding.x + ImMax(0.0, (label_avail_w - label_size.x - extra_w) * style.SeparatorTextAlign.x), pos.y + text_baseline_y)  -- FIXME-ALIGN

    -- This allows using SameLine() to position something in the 'extra_w'
    window.DC.CursorPosPrevLine.x = label_pos.x + label_size.x

    local separator_col = ImGui.GetColorU32(ImGuiCol.Separator)

    if label_size.x > 0.0 then
        local sep1_x2 = label_pos.x - style.ItemSpacing.x
        local sep2_x1 = label_pos.x + label_size.x + extra_w + style.ItemSpacing.x

        if sep1_x2 > sep1_x1 and separator_thickness > 0.0 then
            window.DrawList:AddLine(ImVec2(sep1_x1, seps_y), ImVec2(sep1_x2, seps_y), separator_col, separator_thickness)
        end

        if sep2_x2 > sep2_x1 and separator_thickness > 0.0 then
            window.DrawList:AddLine(ImVec2(sep2_x1, seps_y), ImVec2(sep2_x2, seps_y), separator_col, separator_thickness)
        end

        if g.LogEnabled then
            ImGui.LogSetNextTextDecoration("---", nil)
        end

        ImGui.RenderTextEllipsis(window.DrawList, label_pos, ImVec2(bb.Max.x, bb.Max.y + style.ItemSpacing.y), bb.Max.x, label, label_end, label_size)
    else
        if g.LogEnabled then
            ImGui.LogText("---")
        end

        if separator_thickness > 0.0 then
            window.DrawList:AddLine(ImVec2(sep1_x1, seps_y), ImVec2(sep2_x2, seps_y), separator_col, separator_thickness)
        end
    end
end

--- @param label string
function ImGui.SeparatorText(label)
    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return
    end

    ImGui.SeparatorTextEx(0, label, ImGui.FindRenderedTextEnd(label), 0.0)
end

----------------------------------------------------------------
-- [SECTION] COMBO BOX
----------------------------------------------------------------

--- @param items_count float
--- @return float
local function CalcMaxPopupHeightFromItemCount(items_count)
    local g = ImGui.GetCurrentContext()
    if items_count <= 0 then
        return FLT_MAX
    end
    return (g.FontSize + g.Style.ItemSpacing.y) * items_count - g.Style.ItemSpacing.y + (g.Style.WindowPadding.y * 2)
end

--- @param label          string
--- @param preview_value? string
--- @param flags?         ImGuiComboFlags
function ImGui.BeginCombo(label, preview_value, flags)
    if flags == nil then flags = 0 end

    local g = ImGui.GetCurrentContext()
    local window = ImGui.GetCurrentWindow()

    local backup_next_window_data_flags = g.NextWindowData.HasFlags
    g.NextWindowData:ClearFlags()
    if window.SkipItems then
        return false
    end

    local style = g.Style
    local id = window:GetID(label)
    IM_ASSERT(bit.band(flags, bit.bor(ImGuiComboFlags_NoArrowButton, ImGuiComboFlags_NoPreview)) ~= bit.bor(ImGuiComboFlags_NoArrowButton, ImGuiComboFlags_NoPreview)) -- Can't use both flags together
    if bit.band(flags, ImGuiComboFlags_WidthFitPreview) ~= 0 then
        IM_ASSERT(bit.band(flags, bit.bor(ImGuiComboFlags_NoPreview, ImGuiComboFlags_CustomPreview)) == 0)
    end

    local arrow_size
    if (bit.band(flags, ImGuiComboFlags_NoArrowButton) ~= 0) then
        arrow_size = 0.0
    else
        arrow_size = ImGui.GetFrameHeight()
    end

    local label_size = ImGui.CalcTextSize(label, nil, true)

    local preview_width
    if ((bit.band(flags, ImGuiComboFlags_WidthFitPreview) ~= 0) and (preview_value ~= nil)) then
        preview_width = ImGui.CalcTextSize(preview_value, nil, true).x
    else
        preview_width = 0.0
    end

    local w
    if bit.band(flags, ImGuiComboFlags_NoPreview) ~= 0 then
        w = arrow_size
    elseif bit.band(flags, ImGuiComboFlags_WidthFitPreview) ~= 0 then
        w = arrow_size + preview_width + style.FramePadding.x * 2.0
    else
        w = ImGui.CalcItemWidth()
    end

    local bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + ImVec2(w, label_size.y + style.FramePadding.y * 2.0))
    local label_offset = (label_size.x > 0.0) and (style.ItemInnerSpacing.x + label_size.x) or 0.0
    local total_bb = ImRect(bb.Min, bb.Max + ImVec2(label_offset, 0.0))

    ImGui.ItemSizeR(total_bb, style.FramePadding.y)
    if not ImGui.ItemAdd(total_bb, id, bb) then
        return false
    end

    local pressed, hovered, held = ImGui.ButtonBehavior(bb, id)
    local popup_id = ImHashStr("##ComboPopup", id)
    local popup_open = ImGui.IsPopupOpen(popup_id, ImGuiPopupFlags_None)
    if pressed and not popup_open then
        ImGui.OpenPopupEx(popup_id, ImGuiPopupFlags_None)
        popup_open = true
    end

    -- Render shape
    local frame_col = ImGui.GetColorU32(hovered and ImGuiCol.FrameBgHovered or ImGuiCol.FrameBg)
    local value_x2 = ImMax(bb.Min.x, bb.Max.x - arrow_size)

    ImGui.RenderNavCursor(bb, id)

    if bit.band(flags, ImGuiComboFlags_NoPreview) == 0 then
        window.DrawList:AddRectFilled(bb.Min, ImVec2(value_x2, bb.Max.y), frame_col, style.FrameRounding, (bit.band(flags, ImGuiComboFlags_NoArrowButton) ~= 0) and ImDrawFlags_RoundCornersAll or ImDrawFlags_RoundCornersLeft)
    end

    if bit.band(flags, ImGuiComboFlags_NoArrowButton) == 0 then
        local bg_col = ImGui.GetColorU32((popup_open or hovered) and ImGuiCol.ButtonHovered or ImGuiCol.Button)
        local text_col = ImGui.GetColorU32(ImGuiCol.Text)

        window.DrawList:AddRectFilled(ImVec2(value_x2, bb.Min.y), bb.Max, bg_col, style.FrameRounding, (w <= arrow_size) and ImDrawFlags_RoundCornersAll or ImDrawFlags_RoundCornersRight)

        if value_x2 + arrow_size - style.FramePadding.x <= bb.Max.x then
            ImGui.RenderArrow(window.DrawList, ImVec2(value_x2 + style.FramePadding.y, bb.Min.y + style.FramePadding.y), text_col, ImGuiDir.Down, 1.0)
        end
    end

    ImGui.RenderFrameBorder(bb.Min, bb.Max, style.FrameRounding)

    -- Custom preview
    if bit.band(flags, ImGuiComboFlags_CustomPreview) ~= 0 then
        g.ComboPreviewData.PreviewRect = ImRect(bb.Min.x, bb.Min.y, value_x2, bb.Max.y)
        IM_ASSERT(preview_value == nil or preview_value == "")
        preview_value = nil
    end

    -- Render preview and label
    if preview_value ~= nil and bit.band(flags, ImGuiComboFlags_NoPreview) == 0 then
        if g.LogEnabled then
            ImGui.LogSetNextTextDecoration("{", "}")
        end
        ImGui.RenderTextClipped(bb.Min + style.FramePadding, ImVec2(value_x2, bb.Max.y), preview_value, 1, nil, nil)
    end

    if label_size.x > 0 then
        ImGui.RenderText(ImVec2(bb.Max.x + style.ItemInnerSpacing.x, bb.Min.y + style.FramePadding.y), label)
    end

    if not popup_open then
        return false
    end

    g.NextWindowData.HasFlags = backup_next_window_data_flags
    return ImGui.BeginComboPopup(popup_id, bb, flags)
end

--- @param popup_id ImGuiID
--- @param bb       ImRect
--- @param flags    ImGuiComboFlags
function ImGui.BeginComboPopup(popup_id, bb, flags)
    local g = ImGui.GetCurrentContext()
    if not ImGui.IsPopupOpen(popup_id, ImGuiPopupFlags_None) then
        g.NextWindowData:ClearFlags()
        return false
    end

    local w = bb:GetWidth()
    if bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasSizeConstraint) ~= 0 then
        g.NextWindowData.SizeConstraintRect.Min.x = ImMax(g.NextWindowData.SizeConstraintRect.Min.x, w)
    else
        if bit.band(flags, ImGuiComboFlags_HeightMask_) == 0 then
            flags = bit.bor(flags, ImGuiComboFlags_HeightRegular)
        end
        IM_ASSERT(ImIsPowerOfTwo(bit.band(flags, ImGuiComboFlags_HeightMask_)))
        local popup_max_height_in_items = -1
        if bit.band(flags, ImGuiComboFlags_HeightRegular) ~= 0 then
            popup_max_height_in_items = 8
        elseif bit.band(flags, ImGuiComboFlags_HeightSmall) ~= 0 then
            popup_max_height_in_items = 4
        elseif bit.band(flags, ImGuiComboFlags_HeightLarge) ~= 0 then
            popup_max_height_in_items = 20
        end
        local constraint_min = ImVec2(0.0, 0.0)
        local constraint_max = ImVec2(FLT_MAX, FLT_MAX)
        if bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasSize) == 0 or g.NextWindowData.SizeVal.x <= 0.0 then
            constraint_min.x = w
        end
        if bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasSize) == 0 or g.NextWindowData.SizeVal.y <= 0.0 then
            constraint_max.y = CalcMaxPopupHeightFromItemCount(popup_max_height_in_items)
        end
        ImGui.SetNextWindowSizeConstraints(constraint_min, constraint_max)
    end

    -- This is essentially a specialized version of BeginPopupEx()
    local name = ImFormatString("##Combo_%02d", g.BeginComboDepth)

    -- Set position given a custom constraint (peak into expected window size so we can position it)
    -- FIXME: This might be easier to express with an hypothetical SetNextWindowPosConstraints() function?
    -- FIXME: This might be moved to Begin() or at least around the same spot where Tooltips and other Popups are calling FindBestWindowPosForPopupEx()?
    local popup_window = ImGui.FindWindowByName(name)
    if popup_window then
        if popup_window.WasActive then
            -- Always override 'AutoPosLastDirection' to not leave a chance for a past value to affect us.
            local size_expected = ImGui.CalcWindowNextAutoFitSize(popup_window)
            popup_window.AutoPosLastDirection = (bit.band(flags, ImGuiComboFlags_PopupAlignLeft) ~= 0) and ImGuiDir.Left or ImGuiDir.Down
            local r_outer = ImGui.GetPopupAllowedExtentRect(popup_window)
            local pos
            pos, popup_window.AutoPosLastDirection = ImGui.FindBestWindowPosForPopupEx(bb:GetBL(), size_expected, popup_window.AutoPosLastDirection, r_outer, bb, ImGuiPopupPositionPolicy.ComboBox)
            ImGui.SetNextWindowPos(pos)
        end
    end

    -- We don't use BeginPopupEx() solely because we have a custom name string, which we could make an argument to BeginPopupEx()
    local window_flags = bit.bor(ImGuiWindowFlags_AlwaysAutoResize, ImGuiWindowFlags_Popup, ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoResize, ImGuiWindowFlags_NoSavedSettings, ImGuiWindowFlags_NoMove)
    ImGui.PushStyleVarX(ImGuiStyleVar.WindowPadding, g.Style.FramePadding.x) -- Horizontally align ourselves with the framed text
    local _, ret = ImGui.Begin(name, nil, window_flags)
    ImGui.PopStyleVar()
    if not ret then
        ImGui.EndPopup()
        if not g.IO.ConfigDebugBeginReturnValueOnce and not g.IO.ConfigDebugBeginReturnValueLoop then
            -- Begin may only return false with those debug tools activated.
            IM_ASSERT(false) -- This should never happen as we tested for IsPopupOpen() above
        end
        return false
    end

    g.BeginComboDepth = g.BeginComboDepth + 1

    return true
end

function ImGui.EndCombo()
    local g = ImGui.GetCurrentContext()
    g.BeginComboDepth = g.BeginComboDepth - 1

    local name = ImFormatString("##Combo_%02d", g.BeginComboDepth) -- FIXME: Move those to helpers?

    if g.CurrentWindow.Name ~= name then
        IM_ASSERT_USER_ERROR_RET(false, "Calling EndCombo() in wrong window!")
    end

    ImGui.EndPopup()
end

-- Call directly after the BeginCombo/EndCombo block. The preview is designed to only host non-interactive elements
-- (Experimental, see GitHub issues: #1658, #4168)
function ImGui.BeginComboPreview()
    local g = ImGui.GetCurrentContext()
    local window = g.CurrentWindow
    local preview_data = g.ComboPreviewData

    if window.SkipItems or not (bit.band(g.LastItemData.StatusFlags, ImGuiItemStatusFlags_Visible) ~= 0) then
        return false
    end

    IM_ASSERT(g.LastItemData.Rect.Min.x == preview_data.PreviewRect.Min.x and g.LastItemData.Rect.Min.y == preview_data.PreviewRect.Min.y) -- Didn't call after BeginCombo/EndCombo block or forgot to pass ImGuiComboFlags_CustomPreview flag?

    if not window.ClipRect:Overlaps(preview_data.PreviewRect) then -- Narrower test (optional)
        return false
    end

    -- FIXME: This could be contained in a PushWorkRect() api
    preview_data.BackupCursorPos              = window.DC.CursorPos:copy()
    preview_data.BackupCursorMaxPos           = window.DC.CursorMaxPos:copy()
    preview_data.BackupCursorPosPrevLine      = window.DC.CursorPosPrevLine:copy()
    preview_data.BackupPrevLineTextBaseOffset = window.DC.PrevLineTextBaseOffset
    preview_data.BackupLayout                 = window.DC.LayoutType

    window.DC.CursorPos    = preview_data.PreviewRect.Min + g.Style.FramePadding
    window.DC.CursorMaxPos = window.DC.CursorPos:copy()
    window.DC.LayoutType   = ImGuiLayoutType.Horizontal
    window.DC.IsSameLine   = false

    ImGui.PushClipRect(preview_data.PreviewRect.Min, preview_data.PreviewRect.Max, true)

    return true
end

function ImGui.EndComboPreview()
    local g = ImGui.GetCurrentContext()
    local window = g.CurrentWindow
    local preview_data = g.ComboPreviewData

    local draw_list = window.DrawList
    if window.DC.CursorMaxPos.x < preview_data.PreviewRect.Max.x and window.DC.CursorMaxPos.y < preview_data.PreviewRect.Max.y then
        if draw_list.CmdBuffer.Size > 1 then -- Unlikely case that the PushClipRect() didn't create a command
            draw_list.CmdBuffer.Data[draw_list.CmdBuffer.Size].ClipRect = draw_list.CmdBuffer.Data[draw_list.CmdBuffer.Size - 1].ClipRect
            draw_list._CmdHeader.ClipRect = draw_list.CmdBuffer.Data[draw_list.CmdBuffer.Size].ClipRect
            draw_list:_TryMergeDrawCmds()
        end
    end

    ImGui.PopClipRect()

    window.DC.CursorPos              = preview_data.BackupCursorPos
    window.DC.CursorMaxPos           = ImMaxVec2(window.DC.CursorMaxPos, preview_data.BackupCursorMaxPos)
    window.DC.CursorPosPrevLine      = preview_data.BackupCursorPosPrevLine
    window.DC.PrevLineTextBaseOffset = preview_data.BackupPrevLineTextBaseOffset
    window.DC.LayoutType             = preview_data.BackupLayout
    window.DC.IsSameLine             = false

    preview_data.PreviewRect = ImRect()
end

----------------------------------------------------------------
-- [SECTION] SELECTABLE
----------------------------------------------------------------
-- - Selectable()
----------------------------------------------------------------

-- Tip: pass a non-visible label (e.g. "##hello") then you can use the space to draw other text or image.
-- But you need to make sure the ID is unique, e.g. enclose calls in PushID/PopID or use ##unique_id.
-- With this scheme, ImGuiSelectableFlags_SpanAllColumns and ImGuiSelectableFlags_AllowOverlap are also frequently used flags.
-- FIXME: Selectable() with (size.x == 0.0f) and (SelectableTextAlign.x > 0.0f) followed by SameLine() is currently not supported.
--- @param label     string
--- @param selected  bool
--- @param flags?    ImGuiSelectableFlags
--- @param size_arg? any
--- @return bool is_pressed
--- @return bool is_selected # Updated `selected`
function ImGui.Selectable(label, selected, flags, size_arg)
    if flags    == nil then flags    = 0            end
    if size_arg == nil then size_arg = ImVec2(0, 0) end

    local window = ImGui.GetCurrentWindow()
    if (window.SkipItems) then
        return false, selected
    end

    local g = ImGui.GetCurrentContext()
    local style = g.Style

    local id = window:GetID(label)
    local label_size = ImGui.CalcTextSize(label, nil, true)
    local size = ImVec2((size_arg.x ~= 0.0) and size_arg.x or label_size.x, (size_arg.y ~= 0.0) and size_arg.y or label_size.y)
    local pos = window.DC.CursorPos:copy()
    pos.y = pos.y + window.DC.CurrLineTextBaseOffset
    ImGui.ItemSize(size, 0.0)

    -- Fill horizontal space
    -- We don't support (size < 0.0) in Selectable() because the ItemSpacing extension would make explicitly right-aligned sizes not visibly match other widgets.
    local span_all_columns = bit.band(flags, ImGuiSelectableFlags.SpanAllColumns) ~= 0
    local min_x = span_all_columns and window.ParentWorkRect.Min.x or pos.x
    local max_x = span_all_columns and window.ParentWorkRect.Max.x or window.WorkRect.Max.x
    if size_arg.x == 0.0 or bit.band(flags, ImGuiSelectableFlags.SpanAvailWidth) ~= 0 then
        size.x = ImMax(label_size.x, max_x - min_x)
    end

    -- Selectables are meant to be tightly packed together with no click-gap, so we extend their box to cover spacing between selectable.
    -- FIXME: Not part of layout so not included in clipper calculation, but ItemSize currently doesn't allow offsetting CursorPos.
    local bb = ImRect(min_x, pos.y, min_x + size.x, pos.y + size.y)
    if bit.band(flags, ImGuiSelectableFlags.NoPadWithHalfSpacing) == 0 then
        local spacing_x = span_all_columns and 0.0 or style.ItemSpacing.x
        local spacing_y = style.ItemSpacing.y
        local spacing_L = IM_TRUNC(spacing_x * 0.50)
        local spacing_U = IM_TRUNC(spacing_y * 0.50)

        bb.Min.x = bb.Min.x - spacing_L
        bb.Min.y = bb.Min.y - spacing_U
        bb.Max.x = bb.Max.x + (spacing_x - spacing_L)
        bb.Max.y = bb.Max.y + (spacing_y - spacing_U)
    end

    local disabled_item = bit.band(flags, ImGuiSelectableFlags.Disabled) ~= 0
    local extra_item_flags = disabled_item and ImGuiItemFlags_Disabled or ImGuiItemFlags_None

    local is_visible
    if span_all_columns then
        -- Modify ClipRect for the ItemAdd(), faster than doing a PushColumnsBackground/PushTableBackgroundChannel for every Selectable..
        local backup_clip_rect_min_x = window.ClipRect.Min.x
        local backup_clip_rect_max_x = window.ClipRect.Max.x

        window.ClipRect.Min.x = window.ParentWorkRect.Min.x
        window.ClipRect.Max.x = window.ParentWorkRect.Max.x

        is_visible = ImGui.ItemAdd(bb, id, nil, extra_item_flags)

        window.ClipRect.Min.x = backup_clip_rect_min_x
        window.ClipRect.Max.x = backup_clip_rect_max_x
    else
        is_visible = ImGui.ItemAdd(bb, id, nil, extra_item_flags)
    end

    local is_multi_select = bit.band(g.LastItemData.ItemFlags, ImGuiItemFlags_IsMultiSelect) ~= 0

    if not is_visible then
        if not is_multi_select or not g.BoxSelectState.UnclipMode or not g.BoxSelectState.UnclipRect:Overlaps(bb) then
            -- Extra layer of "no logic clip" for box-select support (would be more overhead to add to ItemAdd)
            return false, selected
        end
    end

    local disabled_global = bit.band(g.CurrentItemFlags, ImGuiItemFlags_Disabled) ~= 0

    if disabled_item and not disabled_global then
        -- Only testing this as an optimization
        ImGui.BeginDisabled()
    end

    -- FIXME: We can standardize the behavior of those two, we could also keep the fast path of override ClipRect + full push on render only,
    -- which would be advantageous since most selectable are not selected.
    if span_all_columns then
        if g.CurrentTable then
            ImGui.TablePushBackgroundChannel()
        elseif window.DC.CurrentColumns then
            ImGui.PushColumnsBackground()
        end

        g.LastItemData.StatusFlags = bit.bor(g.LastItemData.StatusFlags, ImGuiItemStatusFlags_HasClipRect)
        g.LastItemData.ClipRect = window.ClipRect:copy()
    end

    -- We use NoHoldingActiveID on menus so user can click and _hold_ on a menu then drag to browse child entries
    local button_flags = 0
    if bit.band(flags, ImGuiSelectableFlags.NoHoldingActiveID) ~= 0 then button_flags = bit.bor(button_flags, ImGuiButtonFlags_NoHoldingActiveId) end
    if bit.band(flags, ImGuiSelectableFlags.NoSetKeyOwner)     ~= 0 then button_flags = bit.bor(button_flags, ImGuiButtonFlags_NoSetKeyOwner) end
    if bit.band(flags, ImGuiSelectableFlags.SelectOnClick)     ~= 0 then button_flags = bit.bor(button_flags, ImGuiButtonFlags_PressedOnClick) end
    if bit.band(flags, ImGuiSelectableFlags.SelectOnRelease)   ~= 0 then button_flags = bit.bor(button_flags, ImGuiButtonFlags_PressedOnRelease) end
    if bit.band(flags, ImGuiSelectableFlags.AllowDoubleClick)  ~= 0 then button_flags = bit.bor(button_flags, ImGuiButtonFlags_PressedOnClickRelease, ImGuiButtonFlags_PressedOnDoubleClick) end
    if bit.band(flags, ImGuiSelectableFlags.AllowOverlap) ~= 0 or bit.band(g.LastItemData.ItemFlags, ImGuiItemFlags_AllowOverlap) ~= 0 then button_flags = bit.bor(button_flags, ImGuiButtonFlags_AllowOverlap) end

    -- Multi-selection support (header)
    local was_selected = selected
    if is_multi_select then
        -- Handle multi-select + alter button flags for it
        selected, button_flags = ImGui.MultiSelectItemHeader(id, selected, button_flags)
    end

    local pressed, hovered, held = ImGui.ButtonBehavior(bb, id, button_flags)
    local auto_selected = false

    -- Multi-selection support (footer)
    if is_multi_select then
        selected, pressed = ImGui.MultiSelectItemFooter(id, selected, pressed)
    else
        -- Auto-select when moved into
        -- - This will be more fully fleshed in the range-select branch
        -- - This is not exposed as it won't nicely work with some user side handling of shift/control
        -- - We cannot do 'if (g.NavJustMovedToId != id) { selected = false; pressed = was_selected; }' for two reasons
        --   - (1) it would require focus scope to be set, need exposing PushFocusScope() or equivalent (e.g. BeginSelection() calling PushFocusScope())
        --   - (2) usage will fail with clipped items
        --   The multi-select API aim to fix those issues, e.g. may be replaced with a BeginSelection() API.
        if bit.band(flags, ImGuiSelectableFlags.SelectOnNav) ~= 0 and g.NavJustMovedToId ~= 0 and g.NavJustMovedToFocusScopeId == g.CurrentFocusScopeId then
            if g.NavJustMovedToId == id and bit.band(g.NavJustMovedToKeyMods, ImGuiMod_Ctrl) == 0 then
                selected = true
                pressed = true
                auto_selected = true
            end
        end
    end

    -- Update NavId when clicking or when Hovering (this doesn't happen on most widgets), so navigation can be resumed with keyboard/gamepad
    if pressed or (hovered and bit.band(flags, ImGuiSelectableFlags.SetNavIdOnHover) ~= 0) then
        if not g.NavHighlightItemUnderNav and g.NavWindow == window and g.NavLayer == window.DC.NavLayerCurrent then
            ImGui.SetNavID(id, window.DC.NavLayerCurrent, g.CurrentFocusScopeId, ImGui.WindowRectAbsToRel(window, bb))  -- (bb == NavRect)
            if g.IO.ConfigNavCursorVisibleAuto then
                g.NavCursorVisible = false
            end
        end
    end
    if pressed then
        ImGui.MarkItemEdited(id)
    end

    if selected ~= was_selected then
        g.LastItemData.StatusFlags = bit.bor(g.LastItemData.StatusFlags, ImGuiItemStatusFlags_ToggledSelection)
    end

    -- Render
    if is_visible then
        local highlighted = hovered or (bit.band(flags, ImGuiSelectableFlags.Highlight) ~= 0)

        if highlighted or selected then
            -- Between 1.91.0 and 1.91.4 we made selected Selectable use an arbitrary lerp between _Header and _HeaderHovered. Removed that now. (#8106)
            local col
            if held and highlighted then
                col = ImGui.GetColorU32(ImGuiCol.HeaderActive)
            elseif highlighted then
                col = ImGui.GetColorU32(ImGuiCol.HeaderHovered)
            else
                col = ImGui.GetColorU32(ImGuiCol.Header)
            end
            ImGui.RenderFrame(bb.Min, bb.Max, col, false, 0.0)
        end

        if g.NavId == id then
            local nav_render_cursor_flags = bit.bor(ImGuiNavRenderCursorFlags.Compact, ImGuiNavRenderCursorFlags.NoRounding)
            if is_multi_select then
                nav_render_cursor_flags = bit.bor(nav_render_cursor_flags, ImGuiNavRenderCursorFlags.AlwaysDraw) -- Always show the nav rectangle
            end
            ImGui.RenderNavCursor(bb, id, nav_render_cursor_flags)
        end
    end

    if span_all_columns then
        if g.CurrentTable then
            ImGui.TablePopBackgroundChannel()
        elseif window.DC.CurrentColumns then
            ImGui.PopColumnsBackground()
        end
    end

    -- Text stays at the submission position. Alignment/clipping extents ignore SpanAllColumns.
    if is_visible then
        ImGui.RenderTextClipped(pos, ImVec2(ImMin(pos.x + size.x, window.WorkRect.Max.x), pos.y + size.y), label, 1, nil, label_size, style.SelectableTextAlign, bb)
    end

    -- Automatically close popups
    if pressed and not auto_selected and bit.band(window.Flags, ImGuiWindowFlags_Popup) ~= 0 and bit.band(flags, ImGuiSelectableFlags.NoAutoClosePopups) == 0 and bit.band(g.LastItemData.ItemFlags, ImGuiItemFlags_AutoClosePopups) ~= 0 then
        ImGui.CloseCurrentPopup()
    end

    if disabled_item and not disabled_global then
        ImGui.EndDisabled()
    end

    -- Users of BeginMultiSelect()/EndMultiSelect() scope: you may call ImGui::IsItemToggledSelection() to retrieve
    -- selection toggle, only useful if you need that state updated (e.g. for rendering purpose) before reaching EndMultiSelect().
    return pressed, selected
end

----------------------------------------------------------------
-- [SECTION] BASIC PLOTTING
----------------------------------------------------------------

--- @param plot_type     ImGuiPlotType
--- @param label         string
--- @param values_getter fun(data?: table, idx: int): float
--- @param data?         table                              # 1-based table
--- @param values_count  int
--- @param values_offset int
--- @param overlay_text? string
--- @param scale_min     float
--- @param scale_max     float
--- @param size_arg      ImVec2
--- @return int
function ImGui.PlotEx(plot_type, label, values_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, size_arg)
    local g = ImGui.GetCurrentContext()
    local window = g.CurrentWindow
    if window.SkipItems then
        return -1
    end

    local style = g.Style
    local id = window:GetID(label)

    local label_size = ImGui.CalcTextSize(label, nil, true)
    local frame_size = ImGui.CalcItemSize(size_arg, ImGui.CalcItemWidth(), label_size.y + style.FramePadding.y * 2.0)

    local frame_bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + frame_size)
    local inner_bb = ImRect(frame_bb.Min + style.FramePadding, frame_bb.Max - style.FramePadding)
    local total_bb = ImRect(frame_bb.Min, frame_bb.Max + ImVec2(label_size.x > 0.0 and style.ItemInnerSpacing.x + label_size.x or 0.0, 0))
    ImGui.ItemSizeR(total_bb, style.FramePadding.y)
    if not ImGui.ItemAdd(total_bb, id, frame_bb, ImGuiItemFlags_NoNav) then
        return -1
    end

    local _, hovered, _ = ImGui.ButtonBehavior(frame_bb, id)

    if scale_min == FLT_MAX or scale_max == FLT_MAX then
        local v_min = FLT_MAX
        local v_max = -FLT_MAX
        for i = 1, values_count do
            local v = values_getter(data, i)

            v_min = ImMin(v_min, v)
            v_max = ImMax(v_max, v)
        end
        if scale_min == FLT_MAX then
            scale_min = v_min
        end
        if scale_max == FLT_MAX then
            scale_max = v_max
        end
    end

    ImGui.RenderFrame(frame_bb.Min, frame_bb.Max, ImGui.GetColorU32(ImGuiCol.FrameBg), true, style.FrameRounding)

    local values_count_min = (plot_type == ImGuiPlotType.Lines) and 2 or 1
    local idx_hovered = -1

    if values_count >= values_count_min then
        local res_w = ImMin(math.floor(frame_size.x), values_count) + ((plot_type == ImGuiPlotType.Lines) and -1 or 0)
        local item_count = values_count + ((plot_type == ImGuiPlotType.Lines) and -1 or 0)

        if hovered and inner_bb:ContainsV2(g.IO.MousePos) then
            local t = ImClamp((g.IO.MousePos.x - inner_bb.Min.x) / (inner_bb.Max.x - inner_bb.Min.x), 0.0, 0.9999)
            local v_idx = math.floor(t * item_count) + 1
            IM_ASSERT(v_idx >= 1 and v_idx <= values_count)

            local v0 = values_getter(data, (v_idx - 1 + values_offset) % values_count + 1)
            local v1 = values_getter(data, (v_idx - 1 + 1 + values_offset) % values_count + 1)
            if plot_type == ImGuiPlotType.Lines then
                ImGui.SetTooltip("%d: %8.4g\n%d: %8.4g", v_idx, v0, v_idx + 1, v1)
            elseif plot_type == ImGuiPlotType.Histogram then
                ImGui.SetTooltip("%d: %8.4g", v_idx, v0)
            end
            idx_hovered = v_idx
        end

        local t_step = 1.0 / res_w
        local inv_scale = (scale_min == scale_max) and 0.0 or (1.0 / (scale_max - scale_min))

        local v0 = values_getter(data, (0 + values_offset) % values_count + 1)
        local t0 = 0.0
        local tp0 = ImVec2(t0, 1.0 - ImSaturate((v0 - scale_min) * inv_scale))
        local histogram_zero_line_t = (scale_min * scale_max < 0.0) and (1 + scale_min * inv_scale) or (scale_min < 0.0 and 0.0 or 1.0)

        local col_base = ImGui.GetColorU32((plot_type == ImGuiPlotType.Lines) and ImGuiCol.PlotLines or ImGuiCol.PlotHistogram)
        local col_hovered = ImGui.GetColorU32((plot_type == ImGuiPlotType.Lines) and ImGuiCol.PlotLinesHovered or ImGuiCol.PlotHistogramHovered)

        for _ = 0, res_w - 1 do
            local t1 = t0 + t_step
            local v1_idx = math.floor(t0 * item_count + 0.5) + 1
            IM_ASSERT(v1_idx >= 1 and v1_idx <= values_count)
            local v1 = values_getter(data, (v1_idx - 1 + values_offset + 1) % values_count + 1)
            local tp1 = ImVec2(t1, 1.0 - ImSaturate((v1 - scale_min) * inv_scale))

            local pos0 = ImLerpV2V2V2(inner_bb.Min, inner_bb.Max, tp0)
            local pos1
            if plot_type == ImGuiPlotType.Lines then
                pos1 = ImLerpV2V2V2(inner_bb.Min, inner_bb.Max, tp1)
            else
                pos1 = ImLerpV2V2V2(inner_bb.Min, inner_bb.Max, ImVec2(tp1.x, histogram_zero_line_t))
            end

            if plot_type == ImGuiPlotType.Lines then
                window.DrawList:AddLine(pos0, pos1, idx_hovered == v1_idx and col_hovered or col_base)
            elseif plot_type == ImGuiPlotType.Histogram then
                if pos1.x >= pos0.x + 2.0 then
                    pos1.x = pos1.x - 1.0
                end
                window.DrawList:AddRectFilled(pos0, pos1, idx_hovered == v1_idx and col_hovered or col_base)
            end

            t0 = t1
            tp0 = tp1
        end
    end

    if overlay_text then
        ImGui.RenderTextClipped(ImVec2(frame_bb.Min.x, frame_bb.Min.y + style.FramePadding.y), frame_bb.Max, overlay_text, nil, nil, nil, ImVec2(0.5, 0.0))
    end

    if label_size.x > 0.0 then
        ImGui.RenderText(ImVec2(frame_bb.Max.x + style.ItemInnerSpacing.x, inner_bb.Min.y), label)
    end

    return idx_hovered
end

--- @class ImGuiPlotArrayGetterData
--- @field Values float[]
--- @field Stride int

--- @param values float[]
--- @param stride int
--- @return ImGuiPlotArrayGetterData
--- @nodiscard
function ImGuiPlotArrayGetterData(values, stride)
    return {
        Values = values,
        Stride = stride
    }
end

--- @param data ImGuiPlotArrayGetterData
--- @param idx int
--- @return float
--- @package
local function Plot_ArrayGetter(data, idx)
    return data.Values[idx * data.Stride]
end

--- @param label            string
--- @param values_or_getter table|fun(data:table, i:int)  # 1-based table or a function
--- @param data?            table                         # 1-based table
--- @param values_count     int
--- @param values_offset?   int                           # Defaults to 0
--- @param overlay_text?    string
--- @param scale_min?       float                         # Defaults to FLT_MAX
--- @param scale_max?       float                         # Defaults to FLT_MAX
--- @param graph_size?      ImVec2                        # Defaults to ImVec2(0, 0)
--- @param stride?          int                           # Defaults to 1
function ImGui.PlotLines(label, values_or_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size, stride)
    if values_offset == nil then values_offset = 0         end
    if scale_min     == nil then scale_min  = FLT_MAX      end
    if scale_max     == nil then scale_max  = FLT_MAX      end
    if graph_size    == nil then graph_size = ImVec2(0, 0) end
    if stride        == nil then stride     = 1            end

    if type(values_or_getter) == "function" then
        ImGui.PlotEx(ImGuiPlotType.Lines, label, values_or_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size)
    else
        data = ImGuiPlotArrayGetterData(values_or_getter, stride)
        ImGui.PlotEx(ImGuiPlotType.Lines, label, Plot_ArrayGetter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size)
    end
end

--- @param label            string
--- @param values_or_getter table|fun(data:table, i:int)  # 1-based table or a function
--- @param data?            table                         # 1-based table
--- @param values_count     int
--- @param values_offset?   int                           # Defaults to 0
--- @param overlay_text?    string
--- @param scale_min?       float                         # Defaults to FLT_MAX
--- @param scale_max?       float                         # Defaults to FLT_MAX
--- @param graph_size?      ImVec2                        # Defaults to ImVec2(0, 0)
--- @param stride?          int                           # Defaults to 1
function ImGui.PlotHistogram(label, values_or_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size, stride)
    if values_offset == nil then values_offset = 0         end
    if scale_min     == nil then scale_min  = FLT_MAX      end
    if scale_max     == nil then scale_max  = FLT_MAX      end
    if graph_size    == nil then graph_size = ImVec2(0, 0) end
    if stride        == nil then stride     = 1            end

    if type(values_or_getter) == "function" then
        ImGui.PlotEx(ImGuiPlotType.Histogram, label, values_or_getter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size)
    else
        data = ImGuiPlotArrayGetterData(values_or_getter, stride)
        ImGui.PlotEx(ImGuiPlotType.Histogram, label, Plot_ArrayGetter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size)
    end
end