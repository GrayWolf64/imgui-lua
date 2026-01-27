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
-- [SECTION] BUTTONS
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

--- @return bool
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

----------------------------------------------------------------
-- [SECTION] BASIC PLOTTING
----------------------------------------------------------------

--- @param plot_type     ImGuiPlotType
--- @param label         string
--- @param values_getter function(data: table, idx: int): float
--- @param data          table                                  # 1-based table
--- @param values_count  int
--- @param values_offset int
--- @param overlay_text  string
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
            if type(v) ~= "number" then -- Probably doesn't do proper NaN check
                continue
            end

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
        ImGui.RenderTextClipped(ImVec2(frame_bb.Min.x, frame_bb.Min.y + style.FramePadding.y), frame_bb.Max, overlay_text, nil, nil, ImVec2(0.5, 0.0))
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

--- @param label         string
--- @param values        table  # 1-based table
--- @param values_count  int
--- @param values_offset int
--- @param overlay_text  string
--- @param scale_min?    float
--- @param scale_max?    float
--- @param stride?       int    # Defaults to 1
function ImGui.PlotLines(label, values, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size, stride)
    if scale_min  == nil then scale_min  = FLT_MAX      end
    if scale_max  == nil then scale_max  = FLT_MAX      end
    if graph_size == nil then graph_size = ImVec2(0, 0) end
    if stride     == nil then stride     = 1            end

    local data = ImGuiPlotArrayGetterData(values, stride)
    ImGui.PlotEx(ImGuiPlotType.Lines, label, Plot_ArrayGetter, data, values_count, values_offset, overlay_text, scale_min, scale_max, graph_size)
end

-- FIXME: tooltips(popups) size