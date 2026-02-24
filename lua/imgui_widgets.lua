--- ImGui Sincerely WIP
-- (Widgets Code)

local DRAG_MOUSE_THRESHOLD_FACTOR = 0.50 -- Multiplier for the default value of io.MouseDragThreshold to make DragFloat/DragInt react faster to mouse drags

local IM_S8_MIN = -128
local IM_S8_MAX = 127
local IM_U8_MIN = 0
local IM_U8_MAX = 0xFF
local IM_S16_MIN = -32768
local IM_S16_MAX = 32767
local IM_U16_MIN = 0
local IM_U16_MAX = 0xFFFF
local IM_S32_MIN = INT_MIN
local IM_S32_MAX = INT_MAX
local IM_U32_MIN = 0
local IM_U32_MAX = UINT_MAX
local IM_S64_MIN = LLONG_MIN
local IM_S64_MAX = LLONG_MAX

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

    local text = ImFormatString(fmt, ...)
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
-- [SECTION] MAIN: BUTTONS, SCROLLBARS, ...
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
    local hovered = ImGui.ItemHoverable(bb, id, item_flags)
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

    local pos = ImVec2() -- Don't modify the cursor!
    ImVec2_Copy(pos, window.DC.CursorPos)
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

    ImGui.RenderNavCursor(bb, id)
    ImGui.RenderFrame(bb.Min, bb.Max, col, true, style.FrameRounding)

    -- if (g.LogEnabled)
    --     LogSetNextTextDecoration("[", "]");
    ImGui.RenderTextClipped(bb.Min + style.FramePadding, bb.Max - style.FramePadding, label, nil, label_size, style.ButtonTextAlign, bb)

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

--- @param str_id   string
--- @param size_arg ImVec2
--- @param flags?   ImGuiButtonFlags
function ImGui.InvisibleButton(str_id, size_arg, flags)
    if flags == nil then flags = 0 end

    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return false
    end

    -- Ensure zero-size fits to contents
    local size = ImGui.CalcItemSize(ImVec2(size_arg.x ~= 0.0 and size_arg.x or -FLT_MIN, size_arg.y ~= 0.0 and size_arg.y or -FLT_MIN), 0.0, 0.0)

    local id = window:GetID(str_id)
    local bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + size)
    ImGui.ItemSize(size)

    local item_flags = (bit.band(flags, ImGuiButtonFlags_EnableNav) ~= 0) and ImGuiItemFlags_None or ImGuiItemFlags_NoNav
    if not ImGui.ItemAdd(bb, id, nil, item_flags) then
        return false
    end

    local pressed, hovered, held = ImGui.ButtonBehavior(bb, id, flags)
    ImGui.RenderNavCursor(bb, id)

    -- IMGUI_TEST_ENGINE_ITEM_INFO(id, str_id, g.LastItemData.StatusFlags)
    return pressed
end

--- @param id  ImGuiID
--- @param pos ImVec2
--- @return bool
function ImGui.CloseButton(id, pos)
    local g = ImGui.GetCurrentContext()

    local window = g.CurrentWindow

    local bb = ImRect(pos, pos + ImVec2(g.FontSize, g.FontSize))
    local bb_interact = ImRect()
    ImRect_Copy(bb_interact, bb)

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
    local scrollbar_size = window.ScrollbarSizes[axis == ImGuiAxis.X and ImGuiAxis.Y or ImGuiAxis.X]
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

    local bb = ImRect()
    ImRect_Copy(bb, bb_frame)

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
    local grab_h_minsize = ImMin(bb:GetSize()[axis], style.GrabMinSize)
    local grab_h_pixels = ImClamp(scrollbar_size_v * (size_visible_v / win_size_v), grab_h_minsize, scrollbar_size_v)
    local grab_h_norm = grab_h_pixels / scrollbar_size_v

    ImGui.ItemAdd(bb_frame, id, nil, ImGuiItemFlags_NoNav)
    local pressed, hovered, held = ImGui.ButtonBehavior(bb, id, ImGuiButtonFlags_NoNavFocus)

    local scroll_max = ImMax(1, size_contents_v - size_visible_v)
    local scroll_ratio = ImSaturate(p_scroll_v / scroll_max)
    local grab_v_norm = scroll_ratio * (scrollbar_size_v - grab_h_pixels) / scrollbar_size_v
    if held and allow_interaction and grab_h_norm < 1.0 then
        local scrollbar_pos_v = bb.Min[axis]
        local mouse_pos_v = g.IO.MousePos[axis]
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
    local rounding_corners = ImGui.CalcRoundingFlagsForRectInRect(bb, window:Rect(), g.Style.WindowBorderSize)
    local size_visible = window.InnerRect.Max[axis] - window.InnerRect.Min[axis]
    local size_contents = window.ContentSize[axis] + window.WindowPadding[axis] * 2.0
    local scroll = window.Scroll[axis]
    local held
    held, scroll = ImGui.ScrollbarEx(bb, id, axis, scroll, size_visible, size_contents, rounding_corners)
    window.Scroll[axis] = scroll
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
    local pos = ImVec2()
    ImVec2_Copy(pos, window.DC.CursorPos)

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

--- @param label       string
--- @param flags       int
--- @param flags_value int
--- @return bool is_pressed
--- @return int  flags_new  # Updated `flags`
function ImGui.CheckboxFlags(label, flags, flags_value)
    local all_on = bit.band(flags, flags_value) == flags_value
    local any_on = bit.band(flags, flags_value) ~= 0
    local pressed
    if not all_on and any_on then
        local g = ImGui.GetCurrentContext()
        g.NextItemData.ItemFlags = bit.bor(g.NextItemData.ItemFlags, ImGuiItemFlags_MixedValue)
        pressed, all_on = ImGui.Checkbox(label, all_on)
    else
        pressed, all_on = ImGui.Checkbox(label, all_on)
    end
    if pressed then
        if all_on then
            flags = bit.bor(flags, flags_value)
        else
            flags = bit.band(flags, bit.bnot(flags_value))
        end
    end

    return pressed, flags
end

--- @param label  string
--- @param active bool
--- @return bool is_pressed
function ImGui.RadioButtonEx(label, active)
    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return false
    end

    local g = ImGui.GetCurrentContext()
    local style = g.Style
    local id = window:GetID(label)
    local label_size = ImGui.CalcTextSize(label, nil, true)

    local square_sz = ImGui.GetFrameHeight()
    local pos = ImVec2()
    ImVec2_Copy(pos, window.DC.CursorPos)
    local check_bb = ImRect(pos, pos + ImVec2(square_sz, square_sz))
    local total_bb = ImRect(pos, pos + ImVec2(square_sz + (label_size.x > 0.0 and style.ItemInnerSpacing.x + label_size.x or 0.0), label_size.y + style.FramePadding.y * 2.0))
    ImGui.ItemSizeR(total_bb, style.FramePadding.y)
    if not ImGui.ItemAdd(total_bb, id) then
        return false
    end

    local center = check_bb:GetCenter()
    center.x = IM_ROUND(center.x)
    center.y = IM_ROUND(center.y)
    local radius = (square_sz - 1.0) * 0.5

    local pressed, hovered, held = ImGui.ButtonBehavior(total_bb, id)
    if (pressed) then
        ImGui.MarkItemEdited(id)
    end

    -- ImGui.RenderNavCursor(total_bb, id)
    local num_segment = window.DrawList:_CalcCircleAutoSegmentCount(radius)
    local col
    if held and hovered then
        col = ImGui.GetColorU32(ImGuiCol.FrameBgActive)
    else
        if hovered then
            col = ImGui.GetColorU32(ImGuiCol.FrameBgHovered)
        else
            col = ImGui.GetColorU32(ImGuiCol.FrameBg)
        end
    end
    window.DrawList:AddCircleFilled(center, radius, col, num_segment)
    if active then
        local pad = ImMax(1.0, IM_TRUNC(square_sz / 6.0))
        window.DrawList:AddCircleFilled(center, radius - pad, ImGui.GetColorU32(ImGuiCol.CheckMark))
    end
    if style.FrameBorderSize > 0.0 then
        window.DrawList:AddCircle(center + ImVec2(1, 1), radius, ImGui.GetColorU32(ImGuiCol.BorderShadow), num_segment, style.FrameBorderSize)
        window.DrawList:AddCircle(center, radius, ImGui.GetColorU32(ImGuiCol.Border), num_segment, style.FrameBorderSize)
    end
    local label_pos = ImVec2(check_bb.Max.x + style.ItemInnerSpacing.x, check_bb.Min.y + style.FramePadding.y)
    if g.LogEnabled then
        -- ImGui.LogRenderedText(label_pos, active and "(x)" or "( )")
    end
    if label_size.x > 0.0 then
        ImGui.RenderText(label_pos, label)
    end

    return pressed
end

-- `rawequal` is used here to check if v == v_button
--- @param label    string
--- @param v        any
--- @param v_button any
--- @return bool is_pressed
--- @return any  v          # Updated v
function ImGui.RadioButton(label, v, v_button)
    local pressed = ImGui.RadioButtonEx(label, rawequal(v, v_button))
    if pressed then
        v = v_button
    end
    return pressed, v
end

-- size_arg (for each axis) < 0.0f: align to end, 0.0f: auto, > 0.0f: specified size
--- @param fraction  float
--- @param size_arg? ImVec2
--- @param overlay?  string
function ImGui.ProgressBar(fraction, size_arg, overlay)
    if size_arg == nil then size_arg = ImVec2(-FLT_MIN, 0) end

    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return
    end

    local g = ImGui.GetCurrentContext()
    local style = g.Style

    local pos = ImVec2()
    ImVec2_Copy(pos, window.DC.CursorPos)
    local size = ImGui.CalcItemSize(size_arg, ImGui.CalcItemWidth(), g.FontSize + style.FramePadding.y * 2.0)
    local bb = ImRect(pos, pos + size)
    ImGui.ItemSize(size, style.FramePadding.y)
    if not ImGui.ItemAdd(bb, 0) then
        return
    end

    -- Fraction < 0.0 will display an indeterminate progress bar animation
    -- The value must be animated along with time, so e.g. passing '-1.0 * ImGui.GetTime()' as fraction works
    local is_indeterminate = (fraction < 0.0)
    if not is_indeterminate then
        fraction = ImSaturate(fraction)
    end

    -- Out of courtesy we accept a NaN fraction without crashing
    local fill_n0 = 0.0
    local fill_n1 = (fraction == fraction) and fraction or 0.0

    if is_indeterminate then
        local fill_width_n = 0.2
        fill_n0 = ImFmod(-fraction, 1.0) * (1.0 + fill_width_n) - fill_width_n
        fill_n1 = ImSaturate(fill_n0 + fill_width_n)
        fill_n0 = ImSaturate(fill_n0)
    end

    -- Render
    ImGui.RenderFrame(bb.Min, bb.Max, ImGui.GetColorU32(ImGuiCol.FrameBg), true, style.FrameRounding)
    bb:ExpandV2(ImVec2(-style.FrameBorderSize, -style.FrameBorderSize))

    local fill_x0 = ImLerp(bb.Min.x, bb.Max.x, fill_n0)
    local fill_x1 = ImLerp(bb.Min.x, bb.Max.x, fill_n1)
    if fill_x0 < fill_x1 then
        ImGui.RenderRectFilledInRangeH(window.DrawList, bb, ImGui.GetColorU32(ImGuiCol.PlotHistogram), fill_x0, fill_x1, style.FrameRounding)
    end

    -- Default displaying the fraction as percentage string, but user can override it
    -- Don't display text for indeterminate bars by default
    if not is_indeterminate or overlay ~= nil then
        if overlay == nil then
            overlay = ImFormatString("%.0f%%", fraction * 100 + 0.01)
        end

        local overlay_size = ImGui.CalcTextSize(overlay, nil)
        if overlay_size.x > 0.0 then
            local text_x = is_indeterminate and ((bb.Min.x + bb.Max.x - overlay_size.x) * 0.5) or (fill_x1 + style.ItemSpacing.x)
            ImGui.RenderTextClipped(ImVec2(ImClamp(text_x, bb.Min.x, bb.Max.x - overlay_size.x - style.ItemInnerSpacing.x), bb.Min.y), bb.Max, overlay, nil, overlay_size, ImVec2(0.0, 0.5), bb)
        end
    end
end

--- @param label string
function ImGui.TextLink(label)
    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return false
    end

    local g = ImGui.GetCurrentContext()
    local id = window:GetID(label)
    local label_end = ImGui.FindRenderedTextEnd(label)

    local pos = ImVec2(window.DC.CursorPos.x, window.DC.CursorPos.y + window.DC.CurrLineTextBaseOffset)
    local size = ImGui.CalcTextSize(label, label_end, true)
    local bb = ImRect(pos, pos + size)
    ImGui.ItemSize(size, 0.0)
    if not ImGui.ItemAdd(bb, id) then
        return false
    end

    local pressed, hovered, held = ImGui.ButtonBehavior(bb, id)
    ImGui.RenderNavCursor(bb, id)

    if hovered then
        ImGui.SetMouseCursor(ImGuiMouseCursor.Hand)
    end

    local text_colf = ImVec4()
    ImVec4_Copy(text_colf, g.Style.Colors[ImGuiCol.TextLink])
    local line_colf = ImVec4()
    ImVec4_Copy(line_colf, text_colf)
    do
        -- FIXME-STYLE: Read comments above. This widget is NOT written in the same style as some earlier widgets,
        -- as we are currently experimenting/planning a different styling system.
        local h, s, v = ImGui.ColorConvertRGBtoHSV(text_colf.x, text_colf.y, text_colf.z)
        if held or hovered then
            v = ImSaturate(v + (held and 0.4 or 0.3))
            h = ImFmod(h + 0.02, 1.0)
        end
        text_colf.x, text_colf.y, text_colf.z = ImGui.ColorConvertHSVtoRGB(h, s, v)
        v = ImSaturate(v - 0.20)
        line_colf.x, line_colf.y, line_colf.z = ImGui.ColorConvertHSVtoRGB(h, s, v)
    end

    local line_y = bb.Max.y + ImFloor(g.FontBaked.Descent * g.FontBakedScale * 0.20)
    window.DrawList:AddLine(ImVec2(bb.Min.x, line_y), ImVec2(bb.Max.x, line_y), ImGui.GetColorU32(line_colf)) -- FIXME-TEXT: Underline mode -- FIXME-DPI

    ImGui.PushStyleColor(ImGuiCol.Text, ImGui.GetColorU32(text_colf))
    ImGui.RenderText(bb.Min, label, label_end)
    ImGui.PopStyleColor()

    -- IMGUI_TEST_ENGINE_ITEM_INFO(id, label, g.LastItemData.StatusFlags)
    return pressed
end

--- @param label string
--- @param url   string
function ImGui.TextLinkOpenURL(label, url)
    local g = ImGui.GetCurrentContext()
    if url == nil then
        url = label
    end
    local pressed = ImGui.TextLink(label)
    if pressed and g.PlatformIO.Platform_OpenInShellFn ~= nil then
        g.PlatformIO.Platform_OpenInShellFn(g, url)
    end

    ImGui.SetItemTooltip(ImGui.LocalizeGetMsg(ImGuiLocKey.OpenLink_s), url) -- It is more reassuring for user to _always_ display URL when we same as label

    -- TODO:
    -- if ImGui.BeginPopupContextItem() then
    --     if ImGui.MenuItem(ImGui.LocalizeGetMsg(ImGuiLocKey.CopyLink)) then
    --         ImGui.SetClipboardText(url)
    --     end
    --     ImGui.EndPopup()
    -- end

    return pressed
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
        ImGui.RenderTextClipped(bb.Min + style.FramePadding, ImVec2(value_x2, bb.Max.y), preview_value, nil, nil)
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

    if window.SkipItems or not (bit.band(g.LastItemData.StatusFlags, ImGuiItemStatusFlags.Visible) ~= 0) then
        return false
    end

    IM_ASSERT(g.LastItemData.Rect.Min.x == preview_data.PreviewRect.Min.x and g.LastItemData.Rect.Min.y == preview_data.PreviewRect.Min.y) -- Didn't call after BeginCombo/EndCombo block or forgot to pass ImGuiComboFlags_CustomPreview flag?

    if not window.ClipRect:Overlaps(preview_data.PreviewRect) then -- Narrower test (optional)
        return false
    end

    -- FIXME: This could be contained in a PushWorkRect() api
    ImVec2_Copy(preview_data.BackupCursorPos, window.DC.CursorPos)
    ImVec2_Copy(preview_data.BackupCursorMaxPos, window.DC.CursorMaxPos)
    ImVec2_Copy(preview_data.BackupCursorPosPrevLine, window.DC.CursorPosPrevLine)
    preview_data.BackupPrevLineTextBaseOffset = window.DC.PrevLineTextBaseOffset
    preview_data.BackupLayout = window.DC.LayoutType

    ImVec2_Copy(window.DC.CursorPos, preview_data.PreviewRect.Min + g.Style.FramePadding)
    ImVec2_Copy(window.DC.CursorMaxPos, window.DC.CursorPos)
    window.DC.LayoutType = ImGuiLayoutType.Horizontal
    window.DC.IsSameLine = false

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
            ImVec4_Copy(draw_list.CmdBuffer.Data[draw_list.CmdBuffer.Size].ClipRect, draw_list.CmdBuffer.Data[draw_list.CmdBuffer.Size - 1].ClipRect)
            ImVec4_Copy(draw_list._CmdHeader.ClipRect, draw_list.CmdBuffer.Data[draw_list.CmdBuffer.Size].ClipRect)
            draw_list:_TryMergeDrawCmds()
        end
    end

    ImGui.PopClipRect()

    ImVec2_Copy(window.DC.CursorPos, preview_data.BackupCursorPos)
    ImVec2_Copy(window.DC.CursorMaxPos, ImMaxVec2(window.DC.CursorMaxPos, preview_data.BackupCursorMaxPos))
    ImVec2_Copy(window.DC.CursorPosPrevLine, preview_data.BackupCursorPosPrevLine)
    window.DC.PrevLineTextBaseOffset = preview_data.BackupPrevLineTextBaseOffset
    window.DC.LayoutType = preview_data.BackupLayout
    window.DC.IsSameLine = false

    preview_data.PreviewRect = ImRect()
end

----------------------------------------------------------------
-- [SECTION] DATA TYPE & DATA FORMATTING [Internal]
----------------------------------------------------------------

local GDefaultRgbaColorMarkers = {
    IM_COL32(240, 20, 20, 255), IM_COL32(20, 240, 20, 255), IM_COL32(20, 20, 240, 255), IM_COL32(140, 140, 140, 255)
}

--- @param name      string
--- @param print_fmt string
--- @return ImGuiDataTypeInfo
--- @nodiscard
--- @package
local function ImGuiDataTypeInfo(name, print_fmt)
    return { Name = name, PrintFmt = print_fmt }
end

local GDataTypeInfo = {
    ImGuiDataTypeInfo("S8",     "%d"),
    ImGuiDataTypeInfo("U8",     "%u"),
    ImGuiDataTypeInfo("S16",    "%d"),
    ImGuiDataTypeInfo("U16",    "%u"),
    ImGuiDataTypeInfo("S32",    "%d"),
    ImGuiDataTypeInfo("U32",    "%u"),
    ImGuiDataTypeInfo("S64",    "%lld"),
    ImGuiDataTypeInfo("float",  "%.3f"),
    ImGuiDataTypeInfo("double", "%f"),
    ImGuiDataTypeInfo("bool",   "%d"),
    ImGuiDataTypeInfo("string", "%s")
}

--- @param data_type ImGuiDataType
function ImGui.DataTypeGetInfo(data_type)
    IM_ASSERT(data_type >= 1 and data_type <= ImGuiDataType.COUNT)
    return GDataTypeInfo[data_type]
end

local GetMinimumStepAtDecimalPrecision do

local min_steps = { 1.0, 0.1, 0.01, 0.001, 0.0001, 0.00001, 0.000001, 0.0000001, 0.00000001, 0.000000001 }

--- @param decimal_precision int
--- @return float
function GetMinimumStepAtDecimalPrecision(decimal_precision)
    if decimal_precision < 0 then
        return FLT_MIN
    end
    if decimal_precision < #min_steps then
        return min_steps[decimal_precision + 1]
    else
        return ImPow(10.0, -decimal_precision)
    end
end

end

local ImParseFormatFindStart

--- @param format    string
--- @param data_type ImGuiDataType
--- @param v         number
function ImGui.RoundScalarWithFormatT(format, data_type, v)
    -- IM_UNUSED(data_type)
    IM_ASSERT(data_type == ImGuiDataType.Float or data_type == ImGuiDataType.Double)
    local fmt_start = ImParseFormatFindStart(format)
    if string.byte(format, fmt_start) ~= 37 or string.byte(format, fmt_start + 1) == 37 then
        return v -- Don't apply if the value is not visible in the format string
    end

    -- Sanitize format
    -- Currently does nothing to sanitize

    local str = ImFormatString(format, v)
    v = tonumber(str) --[[@as number]]
    return v
end

----------------------------------------------------------------
-- [SECTION] DRAGXXX
----------------------------------------------------------------

--- @param fmt string
function ImParseFormatFindStart(fmt)
    local len = #fmt
    local i = 1
    local c
    while i < len do
        c = string.byte(fmt, i)
        if c == 37 and string.byte(fmt, i + 1) ~= 37 then -- '%'
            return i
        elseif c == 37 then
            i = i + 1
        end
        i = i + 1
    end
    return nil
end

--- @param fmt string
--- @param pos int
local function ImParseFormatFindEnd(fmt, pos)
    -- Printf/scanf types modifiers: I/L/h/j/l/t/w/z. Other uppercase letters qualify as types aka end of the format
    if string.byte(fmt, pos) ~= 37 then -- '%'
        return pos
    end
    local ignored_uppercase_mask = bit.bor(bit.lshift(1, 73 - 65), bit.lshift(1, 76 - 65))
    local ignored_lowercase_mask = bit.bor(bit.lshift(1, 104 - 97), bit.lshift(1, 106 - 97), bit.lshift(1, 108 - 97), bit.lshift(1, 116 - 97), bit.lshift(1, 119 - 97), bit.lshift(1, 122 - 97))
    local len = #fmt
    local c
    for i = pos, len do
        c = string.byte(fmt, i)
        if c >= 65 and c <= 90 and (bit.band(bit.lshift(1, c - 65), ignored_uppercase_mask) == 0) then
            return i + 1
        end
        if c >= 97 and c <= 122 and (bit.band(bit.lshift(1, c - 97), ignored_lowercase_mask) == 0) then
            return i + 1
        end
    end
    return len + 1
end

--- @param str string
--- @param pos int
local function ImAtoi(str, pos)
    local negative = false
    if string.byte(str, pos) == 45 then -- '-'
        negative = true
        pos = pos + 1
    end
    if string.byte(str, pos) == 43 then -- '+'
        pos = pos + 1
    end
    local len = #str
    local v = 0
    local c = string.byte(str, pos)
    while c >= 48 and c <= 57 do
        v = v * 10 + c - 48
        pos = pos + 1
        c = string.byte(str, pos)
        if pos > len then break end
    end
    return negative and -v or v, pos
end

--- @param fmt               string
--- @param default_precision int
local function ImParseFormatPrecision(fmt, default_precision)
    local pos = ImParseFormatFindStart(fmt)
    if not pos then
        return default_precision
    end
    pos = pos + 1
    local len = #fmt
    local c = string.byte(fmt, pos)
    while c >= 48 and c <= 57 do
        pos = pos + 1
        c = string.byte(fmt, pos)
        if pos > len then break end
    end
    local precision = INT_MAX
    if c == 46 then -- '.'
        precision, pos = ImAtoi(fmt, pos + 1)
        if precision < 0 or precision > 99 then
            precision = default_precision
        end
    end
    c = string.byte(fmt, pos)
    if c == 101 or c == 69 then -- Maximum precision with scientific notation
        precision = -1
    end
    if (c == 103 or c == 71) and precision == INT_MAX then
        precision = -1
    end
    return (precision == INT_MAX) and default_precision or precision
end

-- This is called by DragBehavior() when the widget is active (held by mouse or being manipulated with Nav controls)
--- @param data_type ImGuiDataType
--- @param v         number
--- @param v_speed   float
--- @param v_min     number
--- @param v_max     number
--- @param format    string
--- @param flags     ImGuiSliderFlags
--- @return number new_v   # Updated `v`
--- @return bool   changed
function ImGui.DragBehaviorT(data_type, v, v_speed, v_min, v_max, format, flags)
    local g = ImGui.GetCurrentContext()
    local axis = (bit.band(flags, ImGuiSliderFlags.Vertical) ~= 0) and ImGuiAxis.Y or ImGuiAxis.X
    local is_bounded = (v_min < v_max) or ((v_min == v_max) and (v_min ~= 0.0 or (bit.band(flags, ImGuiSliderFlags.ClampZeroRange) ~= 0)))
    local is_wrapped = is_bounded and (bit.band(flags, ImGuiSliderFlags.WrapAround) ~= 0)
    local is_logarithmic = bit.band(flags, ImGuiSliderFlags.Logarithmic) ~= 0
    local is_floating_point = (data_type == ImGuiDataType.Float) or (data_type == ImGuiDataType.Double)

    -- Default tweak speed
    if v_speed == 0.0 and is_bounded and (v_max - v_min < math.huge) then
        v_speed = (v_max - v_min) * g.DragSpeedDefaultRatio
    end

    -- Inputs accumulates into g.DragCurrentAccum, which is flushed into the current value as soon as it makes a difference with our precision settings
    local adjust_delta = 0.0
    if g.ActiveIdSource == ImGuiInputSource.Mouse and ImGui.IsMousePosValid() and ImGui.IsMouseDragPastThreshold(0, g.IO.MouseDragThreshold * DRAG_MOUSE_THRESHOLD_FACTOR) then
        adjust_delta = g.IO.MouseDelta[axis]
        if g.IO.KeyAlt and bit.band(flags, ImGuiSliderFlags.NoSpeedTweaks) == 0 then
            adjust_delta = adjust_delta / 100.0
        end
        if g.IO.KeyShift and bit.band(flags, ImGuiSliderFlags.NoSpeedTweaks) == 0 then
            adjust_delta = adjust_delta * 10.0
        end
    elseif g.ActiveIdSource == ImGuiInputSource.Keyboard or g.ActiveIdSource == ImGuiInputSource.Gamepad then
        local decimal_precision
        if is_floating_point then
            decimal_precision = ImParseFormatPrecision(format, 3)
        else
            decimal_precision = 0
        end
        local slow_key = (g.NavInputSource == ImGuiInputSource.Gamepad) and ImGuiKey.NavGamepadTweakSlow or ImGuiKey.NavKeyboardTweakSlow
        local fast_key = (g.NavInputSource == ImGuiInputSource.Gamepad) and ImGuiKey.NavGamepadTweakFast or ImGuiKey.NavKeyboardTweakFast

        local tweak_factor
        if bit.band(flags, ImGuiSliderFlags.NoSpeedTweaks) ~= 0 then
            tweak_factor = 1.0
        elseif ImGui.IsKeyDown(slow_key) then
            tweak_factor = 1.0 / 10.0
        elseif ImGui.IsKeyDown(fast_key) then
            tweak_factor = 10.0
        else
            tweak_factor = 1.0
        end

        adjust_delta = ImGui.GetNavTweakPressedAmount(axis) * tweak_factor
        v_speed = ImMax(v_speed, GetMinimumStepAtDecimalPrecision(decimal_precision))
    end
    adjust_delta = adjust_delta * v_speed

    -- For vertical drag we currently assume that Up=higher value (like we do with vertical sliders). This may become a parameter
    if axis == ImGuiAxis.Y then
        adjust_delta = -adjust_delta
    end

    -- For logarithmic use our range is effectively 0..1 so scale the delta into that range
    if is_logarithmic and (v_max - v_min < FLT_MAX) and (v_max - v_min > 0.000001) then  -- Epsilon to avoid /0
        adjust_delta = adjust_delta / (v_max - v_min)
    end

    -- Clear current value on activation
    -- Avoid altering values and clamping when we are _already_ past the limits and heading in the same direction, so e.g. if range is 0..255, current value is 300 and we are pushing to the right side, keep the 300.
    local is_just_activated = g.ActiveIdIsJustActivated
    local is_already_past_limits_and_pushing_outward = is_bounded and not is_wrapped and ((v >= v_max and adjust_delta > 0.0) or (v <= v_min and adjust_delta < 0.0))
    if is_just_activated or is_already_past_limits_and_pushing_outward then
        g.DragCurrentAccum = 0.0
        g.DragCurrentAccumDirty = false
    elseif adjust_delta ~= 0.0 then
        g.DragCurrentAccum = g.DragCurrentAccum + adjust_delta
        g.DragCurrentAccumDirty = true
    end

    if not g.DragCurrentAccumDirty then
        return v, false
    end

    local v_cur = v
    local v_old_ref_for_accum_remainder = 0.0

    local logarithmic_zero_epsilon = 0.0 -- Only valid when is_logarithmic is true
    local zero_deadzone_halfsize = 0.0 -- Drag widgets have no deadzone (as it doesn't make sense)
    if is_logarithmic then
        -- When using logarithmic sliders, we need to clamp to avoid hitting zero, but our choice of clamp value greatly affects slider precision. We attempt to use the specified precision to estimate a good lower bound.
        local decimal_precision
        if is_floating_point then
            decimal_precision = ImParseFormatPrecision(format, 3)
        else
            decimal_precision = 1
        end
        logarithmic_zero_epsilon = ImPow(0.1, decimal_precision)

        -- Convert to parametric space, apply delta, convert back
        local v_old_parametric = ImGui.ScaleRatioFromValueT(data_type, v_cur, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize)
        local v_new_parametric = v_old_parametric + g.DragCurrentAccum
        v_cur = ImGui.ScaleValueFromRatioT(data_type, v_new_parametric, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize)
        v_old_ref_for_accum_remainder = v_old_parametric
    else
        v_cur = v_cur + g.DragCurrentAccum
    end

    -- Round to user desired precision based on format string
    if is_floating_point and bit.band(flags, ImGuiSliderFlags.NoRoundToFormat) == 0 then
        v_cur = ImGui.RoundScalarWithFormatT(format, data_type, v_cur)
    end

    -- Preserve remainder after rounding has been applied. This also allow slow tweaking of values
    g.DragCurrentAccumDirty = false
    if is_logarithmic then
        -- Convert to parametric space, apply delta, convert back
        local v_new_parametric = ImGui.ScaleRatioFromValueT(data_type, v_cur, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize)
        g.DragCurrentAccum = v_new_parametric - v_old_ref_for_accum_remainder
    else
        g.DragCurrentAccum = v_cur - v
    end

    if v ~= v_cur and is_bounded then
        if is_wrapped then
            -- Wrap values
            if v_cur < v_min then
                v_cur = v_cur + (v_max - v_min) + (is_floating_point and 0 or 1)
            end
            if v_cur > v_max then
                v_cur = v_cur - (v_max - v_min) - (is_floating_point and 0 or 1)
            end
        else
            -- Clamp values + handle overflow/wrap-around for integer types
            if v_cur < v_min or (v_cur > v and adjust_delta < 0.0 and not is_floating_point) then
                v_cur = v_min
            end
            if v_cur > v_max or (v_cur < v and adjust_delta > 0.0 and not is_floating_point) then
                v_cur = v_max
            end
        end
    end

    -- Apply result
    if v == v_cur then
        return v, false
    end
    v = v_cur
    return v, true
end

--- @param id        ImGuiID
--- @param data_type ImGuiDataType
--- @param v         number
--- @param v_speed   float
--- @param min       number
--- @param max       number
--- @param format    string
--- @param flags     ImGuiSliderFlags
function ImGui.DragBehavior(id, data_type, v, v_speed, min, max, format, flags)
    IM_ASSERT((flags == 1 or bit.band(flags, ImGuiSliderFlags.InvalidMask_) == 0), "Invalid ImGuiSliderFlags flags! Has the legacy 'float power' argument been mistakenly cast to flags? Call function with ImGuiSliderFlags_Logarithmic flags instead.")

    local g = ImGui.GetCurrentContext()
    if g.ActiveId == id then
        if g.ActiveIdSource == ImGuiInputSource.Mouse and not g.IO.MouseDown[0] then
            ImGui.ClearActiveID()
        elseif (g.ActiveIdSource == ImGuiInputSource.Keyboard or g.ActiveIdSource == ImGuiInputSource.Gamepad) and g.NavActivatePressedId == id and not g.ActiveIdIsJustActivated then
            ImGui.ClearActiveID()
        end
    end
    if g.ActiveId ~= id then
        return v, false
    end
    if bit.band(g.LastItemData.ItemFlags, ImGuiItemFlags_ReadOnly) ~= 0 or bit.band(flags, ImGuiSliderFlags.ReadOnly) ~= 0 then
        return v, false
    end

    if data_type == ImGuiDataType.S8 then
        return ImGui.DragBehaviorT(ImGuiDataType.S32, v, v_speed, min and min or IM_S8_MIN, max and max or IM_S8_MAX, format, flags)
    elseif data_type == ImGuiDataType.U8 then
        return ImGui.DragBehaviorT(ImGuiDataType.U32, v, v_speed, min and min or IM_U8_MIN, max and max or IM_U8_MAX, format, flags)
    elseif data_type == ImGuiDataType.S16 then
        return ImGui.DragBehaviorT(ImGuiDataType.S32, v, v_speed, min and min or IM_S16_MIN, max and max or IM_S16_MAX, format, flags)
    elseif data_type == ImGuiDataType.U16 then
        return ImGui.DragBehaviorT(ImGuiDataType.U32, v, v_speed, min and min or IM_U16_MIN, max and max or IM_U16_MAX, format, flags)
    elseif data_type == ImGuiDataType.S32 then
        return ImGui.DragBehaviorT(data_type, v, v_speed, min and min or IM_S32_MIN, max and max or IM_S32_MAX, format, flags)
    elseif data_type == ImGuiDataType.U32 then
        return ImGui.DragBehaviorT(data_type, v, v_speed, min and min or IM_U32_MIN, max and max or IM_U32_MAX, format, flags)
    elseif data_type == ImGuiDataType.S64 then
        return ImGui.DragBehaviorT(data_type, v, v_speed, min and min or IM_S64_MIN, max and max or IM_S64_MAX, format, flags)
    elseif data_type == ImGuiDataType.Float then
        return ImGui.DragBehaviorT(data_type, v, v_speed, min and min or -FLT_MAX, max and max or FLT_MAX, format, flags)
    elseif data_type == ImGuiDataType.Double then
        return ImGui.DragBehaviorT(data_type, v, v_speed, min and min or -DBL_MAX, max and max or DBL_MAX, format, flags)
    end

    IM_ASSERT(false)
    return v, false
end

function ImGui.DragScalar(label, data_type, data, v_speed, min, max, format, flags)
    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return data, false
    end

    local g = ImGui.GetCurrentContext()
    local style = g.Style
    local id = window:GetID(label)
    local w = ImGui.CalcItemWidth()
    local color_marker = (bit.band(g.NextItemData.HasFlags, ImGuiNextItemDataFlags.HasColorMarker) ~= 0) and g.NextItemData.ColorMarker or 0

    local label_size = ImGui.CalcTextSize(label, nil, true)
    local frame_bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + ImVec2(w, label_size.y + style.FramePadding.y * 2.0))
    local total_bb = ImRect(frame_bb.Min, frame_bb.Max + ImVec2((label_size.x > 0.0) and (style.ItemInnerSpacing.x + label_size.x) or 0.0, 0.0))

    local temp_input_allowed = (bit.band(flags, ImGuiSliderFlags.NoInput) == 0)
    ImGui.ItemSizeR(total_bb, style.FramePadding.y)
    if not ImGui.ItemAdd(total_bb, id, frame_bb, temp_input_allowed and ImGuiItemFlags_Inputable or 0) then
        return data, false
    end

    -- Default format string when passing NULL
    if format == nil then
        format = ImGui.DataTypeGetInfo(data_type).PrintFmt
    end

    local hovered = ImGui.ItemHoverable(frame_bb, id, g.LastItemData.ItemFlags)
    local temp_input_is_active = temp_input_allowed and ImGui.TempInputIsActive(id)
    if not temp_input_is_active then
        local clicked = hovered and ImGui.IsMouseClicked(0, nil, ImGuiInputFlags_None, id)
        local double_clicked = (hovered and g.IO.MouseClickedCount[0] == 2 and ImGui.TestKeyOwner(ImGuiKey.MouseLeft, id))
        local make_active = (clicked or double_clicked or g.NavActivateId == id)
        if make_active and (clicked or double_clicked) then
            ImGui.SetKeyOwner(ImGuiKey.MouseLeft, id)
        end
        if make_active and temp_input_allowed then
            if (clicked and g.IO.KeyCtrl) or double_clicked or (g.NavActivateId == id and bit.band(g.NavActivateFlags, ImGuiActivateFlags.PreferInput) ~= 0) then
                temp_input_is_active = true
            end
        end

        -- (Optional) simple click (without moving) turns Drag into an InputText
        if g.IO.ConfigDragClickToInputText and temp_input_allowed and not temp_input_is_active then
            if g.ActiveId == id and hovered and g.IO.MouseReleased[0] and not ImGui.IsMouseDragPastThreshold(0, g.IO.MouseDragThreshold * DRAG_MOUSE_THRESHOLD_FACTOR) then
                g.NavActivateId = id
                g.NavActivateFlags = ImGuiActivateFlags.PreferInput
                temp_input_is_active = true
            end
        end

        -- Store initial value (not used by main lib but available as a convenience but some mods e.g. to revert)
        if make_active then

        end

        if make_active and not temp_input_is_active then
            ImGui.SetActiveID(id, window)
            ImGui.SetFocusID(id, window)
            ImGui.FocusWindow(window)
            g.ActiveIdUsingNavDirMask = bit.bor(bit.lshift(1, ImGuiDir.Left), bit.lshift(1, ImGuiDir.Right))
        end
    end

    if temp_input_is_active then
        -- TODO:
    end

    -- Draw frame
    local frame_col = ImGui.GetColorU32(g.ActiveId == id and ImGuiCol.FrameBgActive or hovered and ImGuiCol.FrameBgHovered or ImGuiCol.FrameBg)
    ImGui.RenderNavCursor(frame_bb, id)
    ImGui.RenderFrame(frame_bb.Min, frame_bb.Max, frame_col, false, style.FrameRounding)

    if color_marker ~= 0 and style.ColorMarkerSize > 0.0 then
        ImGui.RenderColorComponentMarker(frame_bb, ImGui.GetColorU32_U32(color_marker), style.FrameRounding)
    end

    ImGui.RenderFrameBorder(frame_bb.Min, frame_bb.Max, g.Style.FrameRounding)

    -- Drag behavior
    local value_changed
    data, value_changed = ImGui.DragBehavior(id, data_type, data, v_speed, min, max, format, flags)
    if value_changed then
        ImGui.MarkItemEdited(id)
    end

    -- Display value using user-provided display format so user can add prefix/suffix/decorations to the value
    ImGui.RenderTextClipped(frame_bb.Min, frame_bb.Max, ImFormatString(format, data), nil, nil, ImVec2(0.5, 0.5))

    if label_size.x > 0.0 then
        ImGui.RenderText(ImVec2(frame_bb.Max.x + style.ItemInnerSpacing.x, frame_bb.Min.y + style.FramePadding.y), label)
    end

    return data, value_changed
end

function ImGui.DragFloat(label, v, v_speed, v_min, v_max, format, flags)
    return ImGui.DragScalar(label, ImGuiDataType.Float, v, v_speed, v_min, v_max, format, flags)
end

function ImGui.DragInt(label, v, v_speed, v_min, v_max, format, flags)
    return ImGui.DragScalar(label, ImGuiDataType.S32, v, v_speed, v_min, v_max, format, flags)
end

----------------------------------------------------------------
-- [SECTION] SLIDERXXX
----------------------------------------------------------------

-- Convert a value v in the output space of a slider into a parametric position on the slider itself (the logical opposite of ScaleValueFromRatioT)
--- @param data_type                ImGuiDataType
--- @param v                        number
--- @param v_min                    number
--- @param v_max                    number
--- @param is_logarithmic           bool
--- @param logarithmic_zero_epsilon float
--- @param zero_deadzone_halfsize   float
function ImGui.ScaleRatioFromValueT(data_type, v, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize)
    if v_min == v_max then
        return 0.0
    end
    -- IM_UNUSED(data_type)

    local v_clamped
    if v_min < v_max then
        v_clamped = ImClamp(v, v_min, v_max)
    else
        v_clamped = ImClamp(v, v_max, v_min)
    end
    if is_logarithmic then
        local flipped = v_max < v_min
        if flipped then -- Handle the case where the range is backwards
            v_min, v_max = v_max, v_min
        end

        -- Fudge min/max to avoid getting close to log(0)
        local v_min_fudged
        if ImAbs(v_min) < logarithmic_zero_epsilon then
            v_min_fudged = (v_min < 0.0) and -logarithmic_zero_epsilon or logarithmic_zero_epsilon
        else
            v_min_fudged = v_min
        end
        local v_max_fudged
        if ImAbs(v_max) < logarithmic_zero_epsilon then
            v_max_fudged = (v_max < 0.0) and -logarithmic_zero_epsilon or logarithmic_zero_epsilon
        else
            v_max_fudged = v_max
        end

        -- Awkward special cases - we need ranges of the form (-100 .. 0) to convert to (-100 .. -epsilon), not (-100 .. epsilon)
        if v_min == 0.0 and v_max < 0.0 then
            v_min_fudged = -logarithmic_zero_epsilon
        elseif v_max == 0.0 and v_min < 0.0 then
            v_max_fudged = -logarithmic_zero_epsilon
        end

        local result
        if v_clamped <= v_min_fudged then
            result = 0.0 -- Workaround for values that are in-range but below our fudge
        elseif v_clamped >= v_max_fudged then
            result = 1.0 -- Workaround for values that are in-range but above our fudge
        elseif v_min * v_max < 0.0 then -- Range crosses zero, so split into two portions
            local zero_point_center = (-v_min) / (v_max - v_min) -- The zero point in parametric space.  There's an argument we should take the logarithmic nature into account when calculating this, but for now this should do (and the most common case of a symmetrical range works fine)
            local zero_point_snap_L = zero_point_center - zero_deadzone_halfsize
            local zero_point_snap_R = zero_point_center + zero_deadzone_halfsize
            if v == 0.0 then
                result = zero_point_center -- Special case for exactly zero
            elseif v < 0.0 then
                result = (1.0 - (ImLog(-v_clamped / logarithmic_zero_epsilon) / ImLog(-v_min_fudged / logarithmic_zero_epsilon))) * zero_point_snap_L
            else
                result = zero_point_snap_R + ((ImLog(v_clamped / logarithmic_zero_epsilon) / ImLog(v_max_fudged / logarithmic_zero_epsilon)) * (1.0 - zero_point_snap_R))
            end
        elseif v_min < 0.0 or v_max < 0.0 then -- Entirely negative slider
            result = 1.0 - (ImLog(-v_clamped / -v_max_fudged) / ImLog(-v_min_fudged / -v_max_fudged))
        else
            result = ImLog(v_clamped / v_min_fudged) / ImLog(v_max_fudged / v_min_fudged)
        end

        return flipped and (1.0 - result) or result
    else
        -- Linear slider
        return (v_clamped - v_min) / (v_max - v_min)
    end
end

-- Convert a parametric position on a slider into a value v in the output space (the logical opposite of ScaleRatioFromValueT)
--- @param data_type                ImGuiDataType
--- @param t                        float
--- @param v_min                    number
--- @param v_max                    number
--- @param is_logarithmic           bool
--- @param logarithmic_zero_epsilon float
--- @param zero_deadzone_halfsize   float
function ImGui.ScaleValueFromRatioT(data_type, t, v_min, v_max, is_logarithmic, logarithmic_zero_epsilon, zero_deadzone_halfsize)
    -- We special-case the extents because otherwise our logarithmic fudging can lead to "mathematically correct"
    -- but non-intuitive behaviors like a fully-left slider not actually reaching the minimum value. Also generally simpler.
    if t <= 0.0 or v_min == v_max then
        return v_min
    end
    if t >= 1.0 then
        return v_max
    end

    local result = 0
    if is_logarithmic then
        -- Fudge min/max to avoid getting silly results close to zero
        local v_min_fudged
        if ImAbs(v_min) < logarithmic_zero_epsilon then
            v_min_fudged = (v_min < 0.0) and -logarithmic_zero_epsilon or logarithmic_zero_epsilon
        else
            v_min_fudged = v_min
        end
        local v_max_fudged
        if ImAbs(v_max) < logarithmic_zero_epsilon then
            v_max_fudged = (v_max < 0.0) and -logarithmic_zero_epsilon or logarithmic_zero_epsilon
        else
            v_max_fudged = v_max
        end

        local flipped = v_max < v_min -- Check if range is "backwards"
        if flipped then
            v_min_fudged, v_max_fudged = v_max_fudged, v_min_fudged
        end

        -- Awkward special case - we need ranges of the form (-100 .. 0) to convert to (-100 .. -epsilon), not (-100 .. epsilon)
        if v_max == 0.0 and v_min < 0.0 then
            v_max_fudged = -logarithmic_zero_epsilon
        end

        local t_with_flip = flipped and (1.0 - t) or t -- t, but flipped if necessary to account for us flipping the range

        if v_min * v_max < 0.0 then -- Range crosses zero, so we have to do this in two parts
            local zero_point_center = (-ImMin(v_min, v_max)) / ImAbs(v_max - v_min) -- The zero point in parametric space
            local zero_point_snap_L = zero_point_center - zero_deadzone_halfsize
            local zero_point_snap_R = zero_point_center + zero_deadzone_halfsize

            if t_with_flip >= zero_point_snap_L and t_with_flip <= zero_point_snap_R then
                result = 0.0 -- Special case to make getting exactly zero possible (the epsilon prevents it otherwise)
            elseif t_with_flip < zero_point_center then
                result = -(logarithmic_zero_epsilon * ImPow(-v_min_fudged / logarithmic_zero_epsilon, 1.0 - (t_with_flip / zero_point_snap_L)))
            else
                result = logarithmic_zero_epsilon * ImPow(v_max_fudged / logarithmic_zero_epsilon, (t_with_flip - zero_point_snap_R) / (1.0 - zero_point_snap_R))
            end
        elseif v_min < 0.0 or v_max < 0.0 then  -- Entirely negative slider
            result = -(-v_max_fudged * ImPow(-v_min_fudged / -v_max_fudged, 1.0 - t_with_flip))
        else
            result = v_min_fudged * ImPow(v_max_fudged / v_min_fudged, t_with_flip)
        end
    else
        -- Linear slider
        local is_floating_point = (data_type == ImGuiDataType.Float) or (data_type == ImGuiDataType.Double)
        if is_floating_point then
            result = ImLerp(v_min, v_max, t)
        elseif t < 1.0 then
            -- - For integer values we want the clicking position to match the grab box so we round above
            --   This code is carefully tuned to work with large values (e.g. high ranges of U64) while preserving this property..
            -- - Not doing a *1.0 multiply at the end of a range as it tends to be lossy. While absolute aiming at a large s64/u64
            --   range is going to be imprecise anyway, with this check we at least make the edge values matches expected limits.
            local v_new_off_f = (v_max - v_min) * t
            local offset = (v_min > v_max) and -0.5 or 0.5
            result = v_min + v_new_off_f + offset
        end
    end

    return result
end

----------------------------------------------------------------
-- [SECTION] INPUT TEXT
----------------------------------------------------------------

ImStb = {}

ImStb.TEXTEDIT_K_LEFT      = 0x200000 -- keyboard input to move cursor left
ImStb.TEXTEDIT_K_RIGHT     = 0x200001 -- keyboard input to move cursor right
ImStb.TEXTEDIT_K_UP        = 0x200002 -- keyboard input to move cursor up
ImStb.TEXTEDIT_K_DOWN      = 0x200003 -- keyboard input to move cursor down
ImStb.TEXTEDIT_K_LINESTART = 0x200004 -- keyboard input to move cursor to start of line
ImStb.TEXTEDIT_K_LINEEND   = 0x200005 -- keyboard input to move cursor to end of line
ImStb.TEXTEDIT_K_TEXTSTART = 0x200006 -- keyboard input to move cursor to start of text
ImStb.TEXTEDIT_K_TEXTEND   = 0x200007 -- keyboard input to move cursor to end of text
ImStb.TEXTEDIT_K_DELETE    = 0x200008 -- keyboard input to delete selection or character under cursor
ImStb.TEXTEDIT_K_BACKSPACE = 0x200009 -- keyboard input to delete selection or character left of cursor
ImStb.TEXTEDIT_K_UNDO      = 0x20000A -- keyboard input to perform undo
ImStb.TEXTEDIT_K_REDO      = 0x20000B -- keyboard input to perform redo
ImStb.TEXTEDIT_K_WORDLEFT  = 0x20000C -- keyboard input to move cursor left one word
ImStb.TEXTEDIT_K_WORDRIGHT = 0x20000D -- keyboard input to move cursor right one word
ImStb.TEXTEDIT_K_PGUP      = 0x20000E -- keyboard input to move cursor up a page
ImStb.TEXTEDIT_K_PGDOWN    = 0x20000F -- keyboard input to move cursor down a page
ImStb.TEXTEDIT_K_SHIFT     = 0x400000

ImStb.TEXTEDIT_NEWLINE = 10 -- '\n'

IM_INCLUDE"imstb_textedit.lua"

--- @param ctx  ImGuiContext
--- @param text             ImString
--- @param text_begin       int
--- @param text_end_display int
--- @param text_end         int
--- @param out_offset?      ImVec2
--- @param flags?           ImDrawTextFlags
local function InputTextCalcTextSize(ctx, text, text_begin, text_end_display, text_end, out_offset, flags)
    if flags == nil then flags = 0 end

    local g = ctx
    local obj = g.InputTextState
    IM_ASSERT(text_end_display >= text_begin and text_end_display <= text_end)
    return ImFontCalcTextSizeEx(g.Font, g.FontSize, FLT_MAX, obj.WrapWidth, text, text_begin, text_end_display, text_end, out_offset, flags)
end

--- @param obj ImGuiInputTextState
--- @return int
function ImStb.TEXTEDIT_STRINGLEN(obj) return obj.TextLen end

--- @param obj ImGuiInputTextState
--- @param idx int                 # 1-based
function ImStb.TEXTEDIT_GETCHAR(obj, idx) IM_ASSERT(idx >= 1 and idx <= obj.TextLen + 1); return obj.TextSrc[idx] end

--- @param obj            ImGuiInputTextState
--- @param line_start_idx int                 # 1-based
--- @param char_idx       int                 # 1-based
--- @return float
function ImStb.TEXTEDIT_GETWIDTH(obj, line_start_idx, char_idx) local _, c = ImText.CharFromUtf8(obj.TextSrc, line_start_idx + char_idx - 1, obj.TextLen + 1); if c == 10 then return IMSTB_TEXTEDIT_GETWIDTH_NEWLINE end; local g = obj.Ctx; return g.FontBaked:GetCharAdvance(c) * g.FontBakedScale end

--- @param r              StbTexteditRow
--- @param obj            ImGuiInputTextState
--- @param line_start_idx int                 # 1-based
function ImStb.TEXTEDIT_LAYOUTROW(r, obj, line_start_idx)
    local text = obj.TextSrc
    local size, text_remaining = InputTextCalcTextSize(obj.Ctx, text, line_start_idx, obj.TextLen + 1, obj.TextLen + 1, nil, bit.bor(ImDrawTextFlags.StopOnNewLine, ImDrawTextFlags.WrapKeepBlanks))
    r.x0 = 0.0
    r.x1 = size.x
    r.baseline_y_delta = size.y
    r.ymin = 0.0
    r.ymax = size.y
    r.num_chars = text_remaining - line_start_idx
end

--- @param obj ImGuiInputTextState
--- @param idx int
function ImStb.TEXTEDIT_GETNEXTCHARINDEX_IMPL(obj, idx)
    if idx >= obj.TextLen then
        return obj.TextLen + 1
    end
    return idx + ImText.CharFromUtf8(obj.TextSrc, idx, obj.TextLen + 1)
end

--- @param obj ImGuiInputTextState
--- @param idx int
function ImStb.TEXTEDIT_GETPREVCHARINDEX_IMPL(obj, idx)
    if idx <= 1 then
        return -1
    end
    local p = ImText.FindPreviousUtf8Codepoint(obj.TextSrc, 1, idx)
    return p
end

-- Edit a string of text
--- @param label              string
--- @param hint               string
--- @param buf                ImStringBuffer
--- @param size_arg           ImVec2
--- @param flags              ImGuiInputTextFlags
--- @param callback?          ImGuiInputTextCallback
--- @param callback_user_data any
function ImGui.InputTextEx(label, hint, buf, size_arg, flags, callback, callback_user_data)
    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return false
    end

    IM_ASSERT(buf ~= nil)
    IM_ASSERT(not (bit.band(flags, ImGuiInputTextFlags.CallbackHistory) ~= 0 and bit.band(flags, ImGuiInputTextFlags.Multiline) ~= 0))        -- Can't use both together (they both use up/down keys)
    IM_ASSERT(not (bit.band(flags, ImGuiInputTextFlags.CallbackCompletion) ~= 0 and bit.band(flags, ImGuiInputTextFlags.AllowTabInput) ~= 0)) -- Can't use both together (they both use tab key)
    IM_ASSERT(not (bit.band(flags, ImGuiInputTextFlags.ElideLeft) ~= 0 and bit.band(flags, ImGuiInputTextFlags.Multiline) ~= 0))              -- Multiline does not not work with left-trimming
    IM_ASSERT(bit.band(flags, ImGuiInputTextFlags.WordWrap) == 0 or bit.band(flags, ImGuiInputTextFlags.Password) == 0)  -- WordWrap does not work with Password mode
    IM_ASSERT(bit.band(flags, ImGuiInputTextFlags.WordWrap) == 0 or bit.band(flags, ImGuiInputTextFlags.Multiline) ~= 0) -- WordWrap does not work in single-line mode

    local g = ImGui.GetCurrentContext()
    local io = g.IO
    local style = g.Style

    local RENDER_SELECTION_WHEN_INACTIVE = false
    local is_multiline = bit.band(flags, ImGuiInputTextFlags.Multiline) ~= 0

    -- TODO:
end

----------------------------------------------------------------
-- [SECTION] COLOR EDIT / PICKER
----------------------------------------------------------------

--- @param col float[]
--- @param H   float
--- @return float
local function ColorEditRestoreH(col, H)
    local g = ImGui.GetCurrentContext()
    IM_ASSERT(g.ColorEditCurrentID ~= 0)
    if g.ColorEditSavedID ~= g.ColorEditCurrentID or g.ColorEditSavedColor ~= ImGui.ColorConvertFloat4ToU32(ImVec4(col[1], col[2], col[3], 0)) then
        return H
    end
    H = g.ColorEditSavedHue
    return H
end

--- @param col float[]
--- @param H float
--- @param S float
--- @param V float
--- @return float, float, float
local function ColorEditRestoreHS(col, H, S, V)
    local g = ImGui.GetCurrentContext()
    IM_ASSERT(g.ColorEditCurrentID ~= 0)

    if g.ColorEditSavedID ~= g.ColorEditCurrentID or g.ColorEditSavedColor ~= ImGui.ColorConvertFloat4ToU32(ImVec4(col[1], col[2], col[3], 0)) then
        return H, S, V
    end

    -- When S == 0, H is undefined.
    -- When H == 1 it wraps around to 0.
    if S == 0.0 or (H == 0.0 and g.ColorEditSavedHue == 1) then
        H = g.ColorEditSavedHue
    end

    -- When V == 0, S is undefined.
    if V == 0.0 then
        S = g.ColorEditSavedSat
    end

    return H, S, V
end

do --[[ColorEdit4]]

local ids = { "##X", "##Y", "##Z", "##W" }
local fmt_table_int = {
    {   "%3d",   "%3d",   "%3d",   "%3d" }, -- Short display
    { "R:%3d", "G:%3d", "B:%3d", "A:%3d" }, -- Long display for RGBA
    { "H:%3d", "S:%3d", "V:%3d", "A:%3d" }  -- Long display for HSVA
}
local fmt_table_float = {
    {   "%0.3f",   "%0.3f",   "%0.3f",   "%0.3f" }, -- Short display
    { "R:%0.3f", "G:%0.3f", "B:%0.3f", "A:%0.3f" }, -- Long display for RGBA
    { "H:%0.3f", "S:%0.3f", "V:%0.3f", "A:%0.3f" }  -- Long display for HSVA
}

--- @param label string
--- @param col   float[]
--- @param flags ImGuiColorEditFlags
function ImGui.ColorEdit4(label, col, flags)
    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return false
    end

    local g = ImGui.GetCurrentContext()
    local style = g.Style
    local square_sz = ImGui.GetFrameHeight()
    local label_display_end = ImGui.FindRenderedTextEnd(label)
    local w_full = ImGui.CalcItemWidth()
    g.NextItemData:ClearFlags()

    ImGui.BeginGroup()
    ImGui.PushID(label)
    local set_current_color_edit_id = (g.ColorEditCurrentID == 0)
    if set_current_color_edit_id then
        g.ColorEditCurrentID = window.IDStack:back()
    end

    -- If we're not showing any slider there's no point in doing any HSV conversions
    local flags_untouched = flags
    if bit.band(flags, ImGuiColorEditFlags.NoInputs) ~= 0 then
        flags = bit.bor(bit.band(flags, bit.bnot(ImGuiColorEditFlags.DisplayMask_)), ImGuiColorEditFlags.DisplayRGB, ImGuiColorEditFlags.NoOptions)
    end

    -- Context menu: display and modify options (before defaults are applied)
    if bit.band(flags, ImGuiColorEditFlags.NoOptions) == 0 then
        ImGui.ColorEditOptionsPopup(col, flags)
    end

    -- Read stored options
    if bit.band(flags, ImGuiColorEditFlags.DisplayMask_) == 0 then
        flags = bit.bor(flags, bit.band(g.ColorEditOptions, ImGuiColorEditFlags.DisplayMask_))
    end
    if bit.band(flags, ImGuiColorEditFlags.DataTypeMask_) == 0 then
        flags = bit.bor(flags, bit.band(g.ColorEditOptions, ImGuiColorEditFlags.DataTypeMask_))
    end
    if bit.band(flags, ImGuiColorEditFlags.PickerMask_) == 0 then
        flags = bit.bor(flags, bit.band(g.ColorEditOptions, ImGuiColorEditFlags.PickerMask_))
    end
    if bit.band(flags, ImGuiColorEditFlags.InputMask_) == 0 then
        flags = bit.bor(flags, bit.band(g.ColorEditOptions, ImGuiColorEditFlags.InputMask_))
    end
    flags = bit.bor(flags, bit.band(g.ColorEditOptions, bit.bnot(bit.bor(ImGuiColorEditFlags.DisplayMask_, ImGuiColorEditFlags.DataTypeMask_, ImGuiColorEditFlags.PickerMask_, ImGuiColorEditFlags.InputMask_))))
    IM_ASSERT(ImIsPowerOfTwo(bit.band(flags, ImGuiColorEditFlags.DisplayMask_))) -- Check that only 1 is selected
    IM_ASSERT(ImIsPowerOfTwo(bit.band(flags, ImGuiColorEditFlags.InputMask_)))   -- Check that only 1 is selected

    local alpha = bit.band(flags, ImGuiColorEditFlags.NoAlpha) == 0
    local hdr = bit.band(flags, ImGuiColorEditFlags.HDR) ~= 0
    local components = alpha and 4 or 3
    local w_button = (bit.band(flags, ImGuiColorEditFlags.NoSmallPreview) ~= 0) and 0.0 or (square_sz + style.ItemInnerSpacing.x)
    local w_inputs = ImMax(w_full - w_button, 1.0)
    w_full = w_inputs + w_button

    -- Convert to the formats we need
    local f = { col[1], col[2], col[3], alpha and col[4] or 1.0 }
    if bit.band(flags, ImGuiColorEditFlags.InputHSV) ~= 0 and bit.band(flags, ImGuiColorEditFlags.DisplayRGB) ~= 0 then
        f[1], f[2], f[3] = ImGui.ColorConvertHSVtoRGB(f[1], f[2], f[3])
    elseif bit.band(flags, ImGuiColorEditFlags.InputRGB) ~= 0 and bit.band(flags, ImGuiColorEditFlags.DisplayHSV) ~= 0 then
        -- Hue is lost when converting from grayscale rgb (saturation=0). Restore it.
        f[1], f[2], f[3] = ImGui.ColorConvertRGBtoHSV(f[1], f[2], f[3])
        f[1], f[2], f[3] = ColorEditRestoreHS(col, f[1], f[2], f[3])
    end
    local i = { IM_F32_TO_INT8_UNBOUND(f[1]), IM_F32_TO_INT8_UNBOUND(f[2]), IM_F32_TO_INT8_UNBOUND(f[3]), IM_F32_TO_INT8_UNBOUND(f[4]) }

    local value_changed = false
    local value_changed_as_float = false

    local pos = ImVec2()
    ImVec2_Copy(pos, window.DC.CursorPos)
    local inputs_offset_x = (style.ColorButtonPosition == ImGuiDir.Left) and w_button or 0.0
    window.DC.CursorPos.x = pos.x + inputs_offset_x

    if bit.band(flags, bit.bor(ImGuiColorEditFlags.DisplayRGB, ImGuiColorEditFlags.DisplayHSV)) ~= 0 and bit.band(flags, ImGuiColorEditFlags.NoInputs) == 0 then
        local w_items = w_inputs - style.ItemInnerSpacing.x * (components - 1)
        local w_per_component = IM_TRUNC(w_items / components)
        local draw_color_marker = bit.band(flags, bit.bor(ImGuiColorEditFlags.DisplayHSV, ImGuiColorEditFlags.NoColorMarkers)) == 0
        local hide_prefix = draw_color_marker or (w_per_component <= ImGui.CalcTextSize((bit.band(flags, ImGuiColorEditFlags.Float) ~= 0) and "M:0.000" or "M:000").x)

        local fmt_idx
        if hide_prefix then
            fmt_idx = 1
        elseif bit.band(flags, ImGuiColorEditFlags.DisplayHSV) ~= 0 then
            fmt_idx = 3
        else
            fmt_idx = 2
        end
        local drag_flags = draw_color_marker and ImGuiSliderFlags.ColorMarkers or ImGuiSliderFlags.None

        local prev_split = 0.0
        for n = 1, components do
            if n > 1 then
                ImGui.SameLine(0, style.ItemInnerSpacing.x)
            end
            local next_split = IM_TRUNC(w_items * n / components)
            ImGui.SetNextItemWidth(ImMax(next_split - prev_split, 1.0))
            prev_split = next_split
            if draw_color_marker then
                ImGui.SetNextItemColorMarker(GDefaultRgbaColorMarkers[n])
            end

            -- FIXME: When ImGuiColorEditFlags_HDR flag is passed HS values snap in weird ways when SV values go below 0
            if bit.band(flags, ImGuiColorEditFlags.Float) ~= 0 then
                local changed
                f[n], changed = ImGui.DragFloat(ids[n], f[n], 1.0 / 255.0, 0.0, hdr and 0.0 or 1.0, fmt_table_float[fmt_idx][n], drag_flags)
                value_changed = value_changed or changed
                value_changed_as_float = value_changed_as_float or value_changed
            else
                local changed
                i[n], changed = ImGui.DragInt(ids[n], i[n], 1.0, 0, hdr and 0 or 255, fmt_table_int[fmt_idx][n], drag_flags)
                value_changed = value_changed or changed
            end

            if bit.band(flags, ImGuiColorEditFlags.NoOptions) == 0 then
                ImGui.OpenPopupOnItemClick("context", ImGuiPopupFlags_MouseButtonRight)
            end
        end
    elseif bit.band(flags, ImGuiColorEditFlags.DisplayHex) ~= 0 and bit.band(flags, ImGuiColorEditFlags.NoInputs) == 0 then
        -- RGB Hexadecimal Input
        -- TODO:

        ImGui.SetNextItemWidth(w_inputs)

        if bit.band(flags, ImGuiColorEditFlags.NoOptions) == 0 then
            ImGui.OpenPopupOnItemClick("context", ImGuiPopupFlags_MouseButtonRight)
        end
    end

    local picker_active_window = nil
    if bit.band(flags, ImGuiColorEditFlags.NoSmallPreview) == 0 then
        local button_offset_x = (bit.band(flags, ImGuiColorEditFlags.NoInputs) ~= 0 or style.ColorButtonPosition == ImGuiDir.Left) and 0.0 or (w_inputs + style.ItemInnerSpacing.x)
        ImVec2_Copy(window.DC.CursorPos, ImVec2(pos.x + button_offset_x, pos.y))

        local col_v4 = ImVec4(col[1], col[2], col[3], alpha and col[4] or 1.0)
        if ImGui.ColorButton("##ColorButton", col_v4, flags) then
            if bit.band(flags, ImGuiColorEditFlags.NoPicker) == 0 then
                -- Store current color and open a picker
                ImVec4_Copy(g.ColorPickerRef, col_v4)
                ImGui.OpenPopup("picker")
                ImGui.SetNextWindowPos(g.LastItemData.Rect:GetBL() + ImVec2(0.0, style.ItemSpacing.y))
            end
        end
        if bit.band(flags, ImGuiColorEditFlags.NoOptions) == 0 then
            ImGui.OpenPopupOnItemClick("context", ImGuiPopupFlags_MouseButtonRight)
        end

        if ImGui.BeginPopup("picker") then
            if g.CurrentWindow.BeginCount == 1 then
                picker_active_window = g.CurrentWindow
                if label ~= "" and label_display_end > 1 then
                    ImGui.TextEx(label, label_display_end)
                    ImGui.Spacing()
                end
                local picker_flags_to_forward = bit.bor(ImGuiColorEditFlags.DataTypeMask_, ImGuiColorEditFlags.PickerMask_, ImGuiColorEditFlags.InputMask_, ImGuiColorEditFlags.HDR, ImGuiColorEditFlags.NoAlpha, ImGuiColorEditFlags.AlphaBar)
                local picker_flags = bit.bor(bit.band(flags_untouched, picker_flags_to_forward), ImGuiColorEditFlags.DisplayMask_, ImGuiColorEditFlags.NoLabel, ImGuiColorEditFlags.AlphaPreviewHalf)
                ImGui.SetNextItemWidth(square_sz * 12.0) -- Use 256 + bar sizes?
                value_changed = value_changed or ImGui.ColorPicker4("##picker", col, picker_flags, g.ColorPickerRef)
            end
            ImGui.EndPopup()
        end
    end

    if label ~= "" and label_display_end > 1 and bit.band(flags, ImGuiColorEditFlags.NoLabel) == 0 then
        -- Position not necessarily next to last submitted button (e.g. if style.ColorButtonPosition == ImGuiDir_Left),
        -- but we need to use SameLine() to setup baseline correctly. Might want to refactor SameLine() to simplify this
        ImGui.SameLine(0.0, style.ItemInnerSpacing.x)
        window.DC.CursorPos.x = pos.x + ((bit.band(flags, ImGuiColorEditFlags.NoInputs) ~= 0) and w_button or (w_full + style.ItemInnerSpacing.x))
        ImGui.TextEx(label, label_display_end)
    end

    -- Convert back
    if value_changed and picker_active_window == nil then
        if not value_changed_as_float then
            for n = 1, 4 do
                f[n] = i[n] / 255.0
            end
        end
        if bit.band(flags, ImGuiColorEditFlags.DisplayHSV) ~= 0 and bit.band(flags, ImGuiColorEditFlags.InputRGB) ~= 0 then
            g.ColorEditSavedHue = f[1]
            g.ColorEditSavedSat = f[2]
            f[1], f[2], f[3] = ImGui.ColorConvertHSVtoRGB(f[1], f[2], f[3])
            g.ColorEditSavedID = g.ColorEditCurrentID
            g.ColorEditSavedColor = ImGui.ColorConvertFloat4ToU32(ImVec4(f[1], f[2], f[3], 0))
        end
        if bit.band(flags, ImGuiColorEditFlags.DisplayRGB) ~= 0 and bit.band(flags, ImGuiColorEditFlags.InputHSV) ~= 0 then
            f[1], f[2], f[3] = ImGui.ColorConvertRGBtoHSV(f[1], f[2], f[3])
        end

        col[1] = f[1]
        col[2] = f[2]
        col[3] = f[3]
        if alpha then
            col[4] = f[4]
        end
    end

    if set_current_color_edit_id then
        g.ColorEditCurrentID = 0
    end
    ImGui.PopID()
    ImGui.EndGroup()

    -- Drag and Drop Target

    -- When picker is being actively used, use its active id so IsItemActive() will function on ColorEdit4()
    if picker_active_window and g.ActiveId ~= 0 and g.ActiveIdWindow == picker_active_window then
        g.LastItemData.ID = g.ActiveId
    end

    if value_changed and g.LastItemData.ID ~= 0 then -- In case of ID collision, the second EndGroup() won't catch g.ActiveId
        ImGui.MarkItemEdited(g.LastItemData.ID)
    end

    return value_changed
end

end

-- Helper for ColorPicker4()
--- @param draw_list ImDrawList
--- @param pos       ImVec2
--- @param half_sz   ImVec2
--- @param bar_w     float
--- @param alpha     float
local function RenderArrowsForVerticalBar(draw_list, pos, half_sz, bar_w, alpha)
    local alpha8 = IM_F32_TO_INT8_SAT(alpha)
    ImGui.RenderArrowPointingAt(draw_list, ImVec2(pos.x + half_sz.x + 1,         pos.y), ImVec2(half_sz.x + 2, half_sz.y + 1), ImGuiDir.Right, IM_COL32(0, 0, 0, alpha8))
    ImGui.RenderArrowPointingAt(draw_list, ImVec2(pos.x + half_sz.x,             pos.y), half_sz,                              ImGuiDir.Right, IM_COL32(255, 255, 255, alpha8))
    ImGui.RenderArrowPointingAt(draw_list, ImVec2(pos.x + bar_w - half_sz.x - 1, pos.y), ImVec2(half_sz.x + 2, half_sz.y + 1), ImGuiDir.Left,  IM_COL32(0, 0, 0, alpha8))
    ImGui.RenderArrowPointingAt(draw_list, ImVec2(pos.x + bar_w - half_sz.x,     pos.y), half_sz,                              ImGuiDir.Left,  IM_COL32(255, 255, 255, alpha8))
end

do --[[ColorPicker4]]

local backup_initial_col = {0, 0, 0, 0}

--- @param label    string
--- @param col      float[]
--- @param flags    ImGuiColorEditFlags
--- @param ref_col? float[]
function ImGui.ColorPicker4(label, col, flags, ref_col)
    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return false
    end

    local draw_list = window.DrawList
    local g = ImGui.GetCurrentContext()
    local style = g.Style
    local io = g.IO

    local width = ImGui.CalcItemWidth()
    local is_readonly = bit.band(bit.bor(g.NextItemData.ItemFlags, g.CurrentItemFlags), ImGuiItemFlags_ReadOnly) ~= 0
    g.NextItemData:ClearFlags()

    ImGui.PushID(label)
    local set_current_color_edit_id = (g.ColorEditCurrentID == 0)
    if set_current_color_edit_id then
        g.ColorEditCurrentID = window.IDStack:back()
    end
    ImGui.BeginGroup()

    if bit.band(flags, ImGuiColorEditFlags.NoSidePreview) == 0 then
        flags = bit.bor(flags, ImGuiColorEditFlags.NoSmallPreview)
    end

    -- Context menu: display and store options.
    if bit.band(flags, ImGuiColorEditFlags.NoOptions) == 0 then
        ImGui.ColorPickerOptionsPopup(col, flags)
    end

    -- Read stored options
    if bit.band(flags, ImGuiColorEditFlags.PickerMask_) == 0 then
        local picker_flags = bit.band(g.ColorEditOptions, ImGuiColorEditFlags.PickerMask_)
        if picker_flags ~= 0 then
            flags = bit.bor(flags, picker_flags)
        else
            flags = bit.bor(flags, bit.band(ImGuiColorEditFlags.DefaultOptions_, ImGuiColorEditFlags.PickerMask_))
        end
    end
    if bit.band(flags, ImGuiColorEditFlags.InputMask_) == 0 then
        local input_flags = bit.band(g.ColorEditOptions, ImGuiColorEditFlags.InputMask_)
        if input_flags ~= 0 then
            flags = bit.bor(flags, input_flags)
        else
            flags = bit.bor(flags, bit.band(ImGuiColorEditFlags.DefaultOptions_, ImGuiColorEditFlags.InputMask_))
        end
    end
    IM_ASSERT(ImIsPowerOfTwo(bit.band(flags, ImGuiColorEditFlags.PickerMask_))) -- Check that only 1 is selected
    IM_ASSERT(ImIsPowerOfTwo(bit.band(flags, ImGuiColorEditFlags.InputMask_)))  -- Check that only 1 is selected
    if bit.band(flags, ImGuiColorEditFlags.NoOptions) == 0 then
        flags = bit.bor(flags, bit.band(g.ColorEditOptions, ImGuiColorEditFlags.AlphaBar))
    end

    -- Setup
    local components = (bit.band(flags, ImGuiColorEditFlags.NoAlpha) ~= 0) and 3 or 4
    local alpha_bar = (bit.band(flags, ImGuiColorEditFlags.AlphaBar) ~= 0) and (bit.band(flags, ImGuiColorEditFlags.NoAlpha) == 0)
    local picker_pos = ImVec2()
    ImVec2_Copy(picker_pos, window.DC.CursorPos)
    local square_sz = ImGui.GetFrameHeight()
    local bars_width = square_sz  -- Arbitrary smallish width of Hue/Alpha picking bars
    local sv_picker_size = ImMax(bars_width * 1, width - (alpha_bar and 2 or 1) * (bars_width + style.ItemInnerSpacing.x))  -- Saturation/Value picking box
    local bar0_pos_x = picker_pos.x + sv_picker_size + style.ItemInnerSpacing.x
    local bar1_pos_x = bar0_pos_x + bars_width + style.ItemInnerSpacing.x
    local bars_triangles_half_sz = IM_TRUNC(bars_width * 0.20)

    backup_initial_col[1], backup_initial_col[2], backup_initial_col[3], backup_initial_col[4] = col[1], col[2], col[3], col[4]

    local wheel_thickness = sv_picker_size * 0.08
    local wheel_r_outer = sv_picker_size * 0.50
    local wheel_r_inner = wheel_r_outer - wheel_thickness
    local wheel_center = ImVec2(picker_pos.x + (sv_picker_size + bars_width) * 0.5, picker_pos.y + sv_picker_size * 0.5)

    -- Note: the triangle is displayed rotated with triangle_pa pointing to Hue, but most coordinates stays unrotated for logic.
    local triangle_r = wheel_r_inner - math.floor(sv_picker_size * 0.027)
    local triangle_pa = ImVec2(triangle_r, 0.0)  -- Hue point.
    local triangle_pb = ImVec2(triangle_r * -0.5, triangle_r * -0.866025) -- Black point
    local triangle_pc = ImVec2(triangle_r * -0.5, triangle_r *  0.866025) -- White point

    local H = col[1]; local S = col[2]; local V = col[3]
    local R = col[1]; local G = col[2]; local B = col[3]
    if bit.band(flags, ImGuiColorEditFlags.InputRGB) ~= 0 then
        -- Hue is lost when converting from grayscale rgb (saturation=0). Restore it.
        H, S, V = ImGui.ColorConvertRGBtoHSV(R, G, B)
        H, S, V = ColorEditRestoreHS(col, H, S, V)
    elseif bit.band(flags, ImGuiColorEditFlags.InputHSV) ~= 0 then
        R, G, B = ImGui.ColorConvertHSVtoRGB(H, S, V)
    end

    local value_changed = false; local value_changed_h = false; local value_changed_sv = false

    ImGui.PushItemFlag(ImGuiItemFlags_NoNav, true)
    if bit.band(flags, ImGuiColorEditFlags.PickerHueWheel) ~= 0 then
        -- Hue wheel + SV triangle logic
        ImGui.InvisibleButton("hsv", ImVec2(sv_picker_size + style.ItemInnerSpacing.x + bars_width, sv_picker_size))
        if ImGui.IsItemActive() and not is_readonly then
            local initial_off = g.IO.MouseClickedPos[0] - wheel_center
            local current_off = g.IO.MousePos - wheel_center
            local initial_dist2 = ImLengthSqr(initial_off)

            if initial_dist2 >= (wheel_r_inner - 1) * (wheel_r_inner - 1) and initial_dist2 <= (wheel_r_outer + 1) * (wheel_r_outer + 1) then
                -- Interactive with Hue wheel
                H = ImAtan2(current_off.y, current_off.x) / IM_PI * 0.5
                if H < 0.0 then
                    H = H + 1.0
                end
                value_changed = true
                value_changed_h = true
            end

            local cos_hue_angle = ImCos(-H * 2.0 * IM_PI)
            local sin_hue_angle = ImSin(-H * 2.0 * IM_PI)
            if ImTriangleContainsPoint(triangle_pa, triangle_pb, triangle_pc, ImRotate(initial_off, cos_hue_angle, sin_hue_angle)) then
                -- Interacting with SV triangle
                local current_off_unrotated = ImRotate(current_off, cos_hue_angle, sin_hue_angle)
                if not ImTriangleContainsPoint(triangle_pa, triangle_pb, triangle_pc, current_off_unrotated) then
                    current_off_unrotated = ImTriangleClosestPoint(triangle_pa, triangle_pb, triangle_pc, current_off_unrotated)
                end
                local uu, vv, ww
                uu, vv, ww = ImTriangleBarycentricCoords(triangle_pa, triangle_pb, triangle_pc, current_off_unrotated)
                V = ImClamp(1.0 - vv, 0.0001, 1.0)
                S = ImClamp(uu / V, 0.0001, 1.0)
                value_changed = true
                value_changed_sv = true
            end
        end

        if bit.band(flags, ImGuiColorEditFlags.NoOptions) == 0 then
            ImGui.OpenPopupOnItemClick("context", ImGuiPopupFlags_MouseButtonRight)
        end
    elseif bit.band(flags, ImGuiColorEditFlags.PickerHueBar) ~= 0 then
        -- SV rectangle logic
        ImGui.InvisibleButton("sv", ImVec2(sv_picker_size, sv_picker_size))
        if ImGui.IsItemActive() and not is_readonly then
            S = ImSaturate((io.MousePos.x - picker_pos.x) / ImMax(sv_picker_size - 1, 0.0001))
            V = 1.0 - ImSaturate((io.MousePos.y - picker_pos.y) / ImMax(sv_picker_size - 1, 0.0001))
            H = ColorEditRestoreH(col, H)  -- Greatly reduces hue jitter and reset to 0 when hue == 255 and color is rapidly modified using SV square.
            value_changed = true
            value_changed_sv = true
        end

        if bit.band(flags, ImGuiColorEditFlags.NoOptions) == 0 then
            ImGui.OpenPopupOnItemClick("context", ImGuiPopupFlags_MouseButtonRight)
        end

        -- Hue bar logic
        ImGui.SetCursorScreenPos(ImVec2(bar0_pos_x, picker_pos.y))
        ImGui.InvisibleButton("hue", ImVec2(bars_width, sv_picker_size))
        if ImGui.IsItemActive() and not is_readonly then
            H = ImSaturate((io.MousePos.y - picker_pos.y) / ImMax(sv_picker_size - 1, 0.0001))
            value_changed = true
            value_changed_h = true
        end
    end

    -- Alpha bar logic
    if alpha_bar then
        ImGui.SetCursorScreenPos(ImVec2(bar1_pos_x, picker_pos.y))
        ImGui.InvisibleButton("alpha", ImVec2(bars_width, sv_picker_size))
        if ImGui.IsItemActive() then
            col[4] = 1.0 - ImSaturate((io.MousePos.y - picker_pos.y) / ImMax(sv_picker_size - 1, 0.0001))
            value_changed = true
        end
    end
    ImGui.PopItemFlag()

    if bit.band(flags, ImGuiColorEditFlags.NoSidePreview) == 0 then
        ImGui.SameLine(0, style.ItemInnerSpacing.x)
        ImGui.BeginGroup()
    end

    if bit.band(flags, ImGuiColorEditFlags.NoLabel) == 0 then
        local label_display_end = ImGui.FindRenderedTextEnd(label)
        if label ~= "" and label_display_end > 1 then
            if bit.band(flags, ImGuiColorEditFlags.NoSidePreview) ~= 0 then
                ImGui.SameLine(0, style.ItemInnerSpacing.x)
            end
            ImGui.TextEx(label, label_display_end)
        end
    end

    if bit.band(flags, ImGuiColorEditFlags.NoSidePreview) == 0 then
        ImGui.PushItemFlag(ImGuiItemFlags_NoNavDefaultFocus, true)
        local col_v4 = ImVec4(col[1], col[2], col[3], (bit.band(flags, ImGuiColorEditFlags.NoAlpha) ~= 0) and 1.0 or col[4])

        if bit.band(flags, ImGuiColorEditFlags.NoLabel) ~= 0 then
            ImGui.Text("Current")
        end

        local sub_flags_to_forward = bit.bor(ImGuiColorEditFlags.InputMask_, ImGuiColorEditFlags.HDR, ImGuiColorEditFlags.AlphaMask_, ImGuiColorEditFlags.NoTooltip)

        ImGui.ColorButton("##current", col_v4, bit.band(flags, sub_flags_to_forward), ImVec2(square_sz * 3, square_sz * 2))

        if ref_col ~= nil then
            ImGui.Text("Original")
            local ref_col_v4 = ImVec4(ref_col[1], ref_col[2], ref_col[3], (bit.band(flags, ImGuiColorEditFlags.NoAlpha) ~= 0) and 1.0 or ref_col[4])
            if ImGui.ColorButton("##original", ref_col_v4, bit.band(flags, sub_flags_to_forward), ImVec2(square_sz * 3, square_sz * 2)) then
                for i = 1, components do
                    col[i] = ref_col[i]
                end
                value_changed = true
            end
        end

        ImGui.PopItemFlag()
        ImGui.EndGroup()
    end

    -- Convert back color to RGB
    if value_changed_h or value_changed_sv then
        if bit.band(flags, ImGuiColorEditFlags.InputRGB) ~= 0 then
            col[1], col[2], col[3] = ImGui.ColorConvertHSVtoRGB(H, S, V)  -- Lua 1-based indexing
            g.ColorEditSavedHue = H
            g.ColorEditSavedSat = S
            g.ColorEditSavedID = g.ColorEditCurrentID
            g.ColorEditSavedColor = ImGui.ColorConvertFloat4ToU32(ImVec4(col[1], col[2], col[3], 0))
        elseif bit.band(flags, ImGuiColorEditFlags.InputHSV) ~= 0 then
            col[1] = H
            col[2] = S
            col[3] = V
        end
    end

    -- R,G,B and H,S,V slider color editor
    local value_changed_fix_hue_wrap = false
    if bit.band(flags, ImGuiColorEditFlags.NoInputs) == 0 then
        ImGui.PushItemWidth((alpha_bar and bar1_pos_x or bar0_pos_x) + bars_width - picker_pos.x)

        local sub_flags_to_forward = bit.bor(ImGuiColorEditFlags.DataTypeMask_, ImGuiColorEditFlags.InputMask_, ImGuiColorEditFlags.HDR, ImGuiColorEditFlags.AlphaMask_, ImGuiColorEditFlags.NoOptions, ImGuiColorEditFlags.NoTooltip, ImGuiColorEditFlags.NoSmallPreview)
        local sub_flags = bit.bor(bit.band(flags, sub_flags_to_forward), ImGuiColorEditFlags.NoPicker)

        if bit.band(flags, ImGuiColorEditFlags.DisplayRGB) ~= 0 or bit.band(flags, ImGuiColorEditFlags.DisplayMask_) == 0 then
            if ImGui.ColorEdit4("##rgb", col, bit.bor(sub_flags, ImGuiColorEditFlags.DisplayRGB)) then
                -- FIXME: Hackily differentiating using the DragInt (ActiveId != 0 && !ActiveIdAllowOverlap) vs. using the InputText or DropTarget.
                -- For the later we don't want to run the hue-wrap canceling code. If you are well versed in HSV picker please provide your input! (See #2050)
                value_changed_fix_hue_wrap = (g.ActiveId ~= 0 and not g.ActiveIdAllowOverlap)
                value_changed = true
            end
        end

        if bit.band(flags, ImGuiColorEditFlags.DisplayHSV) ~= 0 or bit.band(flags, ImGuiColorEditFlags.DisplayMask_) == 0 then
            if ImGui.ColorEdit4("##hsv", col, bit.bor(sub_flags, ImGuiColorEditFlags.DisplayHSV)) then
                value_changed = true
            end
        end

        if bit.band(flags, ImGuiColorEditFlags.DisplayHex) ~= 0 or bit.band(flags, ImGuiColorEditFlags.DisplayMask_) == 0 then
            if ImGui.ColorEdit4("##hex", col, bit.bor(sub_flags, ImGuiColorEditFlags.DisplayHex)) then
                value_changed = true
            end
        end

        ImGui.PopItemWidth()
    end

    -- Try to cancel hue wrap (after ColorEdit4 call), if any
    if value_changed_fix_hue_wrap and bit.band(flags, ImGuiColorEditFlags.InputRGB) ~= 0 then
        local new_H, new_S, new_V = ImGui.ColorConvertRGBtoHSV(col[1], col[2], col[3])  -- Lua 1-based indexing

        if new_H <= 0 and H > 0 then
            if new_V <= 0 and V ~= new_V then
                col[1], col[2], col[3] = ImGui.ColorConvertHSVtoRGB(H, S, (new_V <= 0) and (V * 0.5) or new_V)
            elseif new_S <= 0 then
                col[1], col[2], col[3] = ImGui.ColorConvertHSVtoRGB(H, (new_S <= 0) and (S * 0.5) or new_S, new_V)
            end
        end
    end

    if value_changed then
        if bit.band(flags, ImGuiColorEditFlags.InputRGB) ~= 0 then
            R = col[1]
            G = col[2]
            B = col[3]
            H, S, V = ImGui.ColorConvertRGBtoHSV(R, G, B)
            H, S, V = ColorEditRestoreHS(col, H, S, V) -- Fix local Hue as display below will use it immediately.
        elseif bit.band(flags, ImGuiColorEditFlags.InputHSV) ~= 0 then
            H = col[1]
            S = col[2]
            V = col[3]
            R, G, B = ImGui.ColorConvertHSVtoRGB(H, S, V)
        end
    end

    local style_alpha8 = IM_F32_TO_INT8_SAT(style.Alpha)
    local col_black = IM_COL32(0, 0, 0, style_alpha8)
    local col_white = IM_COL32(255, 255, 255, style_alpha8)
    local col_midgrey = IM_COL32(128, 128, 128, style_alpha8)
    local col_hues = { IM_COL32(255, 0, 0, style_alpha8), IM_COL32(255, 255, 0, style_alpha8), IM_COL32(0, 255, 0, style_alpha8), IM_COL32(0, 255, 255, style_alpha8), IM_COL32(0, 0, 255, style_alpha8), IM_COL32(255, 0, 255, style_alpha8), IM_COL32(255, 0, 0, style_alpha8) }

    local hue_color_f = ImVec4(1, 1, 1, style.Alpha)
    hue_color_f.x, hue_color_f.y, hue_color_f.z = ImGui.ColorConvertHSVtoRGB(H, 1, 1)
    local hue_color32 = ImGui.ColorConvertFloat4ToU32(hue_color_f)
    local user_col32_striped_of_alpha = ImGui.ColorConvertFloat4ToU32(ImVec4(R, G, B, style.Alpha)) -- Important: this is still including the main rendering/style alpha!!

    local sv_cursor_pos = ImVec2()

    if bit.band(flags, ImGuiColorEditFlags.PickerHueWheel) ~= 0 then
        -- Render Hue Wheel
        local aeps = 0.5 / wheel_r_outer -- Half a pixel arc length in radians (2pi cancels out).
        local segment_per_arc =ImMax(4, math.floor(wheel_r_outer / 12))

        for n = 1, 6 do
            local a0 = (n - 1) / 6.0 * 2.0 * IM_PI - aeps
            local a1 = n / 6.0 * 2.0 * IM_PI + aeps
            local vert_start_idx = draw_list.VtxBuffer.Size + 1

            draw_list:PathArcTo(wheel_center, (wheel_r_inner + wheel_r_outer) * 0.5, a0, a1, segment_per_arc)
            draw_list:PathStroke(col_white, 0, wheel_thickness)

            local vert_end_idx = draw_list.VtxBuffer.Size + 1

            -- Paint colors over existing vertices
            local gradient_p0 = ImVec2(wheel_center.x + ImCos(a0) * wheel_r_inner, wheel_center.y + ImSin(a0) * wheel_r_inner)
            local gradient_p1 = ImVec2(wheel_center.x + ImCos(a1) * wheel_r_inner, wheel_center.y + ImSin(a1) * wheel_r_inner)
            ImGui.ShadeVertsLinearColorGradientKeepAlpha(draw_list, vert_start_idx, vert_end_idx, gradient_p0, gradient_p1, col_hues[n], col_hues[n + 1])
        end

        -- Render Cursor + preview on Hue Wheel
        local cos_hue_angle = ImCos(H * 2.0 * IM_PI)
        local sin_hue_angle = ImSin(H * 2.0 * IM_PI)

        local hue_cursor_pos = ImVec2(wheel_center.x + cos_hue_angle * (wheel_r_inner + wheel_r_outer) * 0.5, wheel_center.y + sin_hue_angle * (wheel_r_inner + wheel_r_outer) * 0.5)

        local hue_cursor_rad = value_changed_h and (wheel_thickness * 0.65) or (wheel_thickness * 0.55)
        local hue_cursor_segments = draw_list:_CalcCircleAutoSegmentCount(hue_cursor_rad) -- Lock segment count so the +1 one matches others.

        draw_list:AddCircleFilled(hue_cursor_pos, hue_cursor_rad, hue_color32, hue_cursor_segments)
        draw_list:AddCircle(hue_cursor_pos, hue_cursor_rad + 1, col_midgrey, hue_cursor_segments)
        draw_list:AddCircle(hue_cursor_pos, hue_cursor_rad, col_white, hue_cursor_segments)

        -- Render SV triangle (rotated according to hue)
        local tra = wheel_center + ImRotate(triangle_pa, cos_hue_angle, sin_hue_angle)
        local trb = wheel_center + ImRotate(triangle_pb, cos_hue_angle, sin_hue_angle)
        local trc = wheel_center + ImRotate(triangle_pc, cos_hue_angle, sin_hue_angle)

        local uv_white = ImGui.GetFontTexUvWhitePixel()
        draw_list:PrimReserve(3, 3)
        draw_list:PrimVtx(tra, uv_white, hue_color32)
        draw_list:PrimVtx(trb, uv_white, col_black)
        draw_list:PrimVtx(trc, uv_white, col_white)
        draw_list:AddTriangle(tra, trb, trc, col_midgrey, 1.5)

        sv_cursor_pos = ImLerpV2V2(ImLerpV2V2(trc, tra, ImSaturate(S)), trb, ImSaturate(1 - V))
    elseif bit.band(flags, ImGuiColorEditFlags.PickerHueBar) ~= 0 then
        -- Render SV Square
        draw_list:AddRectFilledMultiColor(picker_pos, picker_pos + ImVec2(sv_picker_size, sv_picker_size), col_white, hue_color32, hue_color32, col_white)
        draw_list:AddRectFilledMultiColor(picker_pos, picker_pos + ImVec2(sv_picker_size, sv_picker_size), 0, 0, col_black, col_black)
        ImGui.RenderFrameBorder(picker_pos, picker_pos + ImVec2(sv_picker_size, sv_picker_size), 0.0)

        -- Sneakily prevent the circle to stick out too much
        sv_cursor_pos.x = ImClamp(IM_ROUND(picker_pos.x + ImSaturate(S) * sv_picker_size), picker_pos.x + 2, picker_pos.x + sv_picker_size - 2)
        sv_cursor_pos.y = ImClamp(IM_ROUND(picker_pos.y + ImSaturate(1 - V) * sv_picker_size), picker_pos.y + 2, picker_pos.y + sv_picker_size - 2)

        -- Render Hue Bar
        for i = 1, 6 do
            draw_list:AddRectFilledMultiColor(ImVec2(bar0_pos_x, picker_pos.y + (i - 1) * (sv_picker_size / 6)), ImVec2(bar0_pos_x + bars_width, picker_pos.y + i * (sv_picker_size / 6)), col_hues[i], col_hues[i], col_hues[i + 1], col_hues[i + 1])
        end

        local bar0_line_y = IM_ROUND(picker_pos.y + H * sv_picker_size)
        ImGui.RenderFrameBorder(ImVec2(bar0_pos_x, picker_pos.y), ImVec2(bar0_pos_x + bars_width, picker_pos.y + sv_picker_size), 0.0)
        RenderArrowsForVerticalBar(draw_list, ImVec2(bar0_pos_x - 1, bar0_line_y), ImVec2(bars_triangles_half_sz + 1, bars_triangles_half_sz), bars_width + 2.0, style.Alpha)
    end

    -- Render cursor/preview circle (clamp S/V within 0..1 range because floating points colors may lead HSV values to be out of range)
    local sv_cursor_rad = value_changed_sv and (wheel_thickness * 0.55) or (wheel_thickness * 0.40)
    local sv_cursor_segments = draw_list:_CalcCircleAutoSegmentCount(sv_cursor_rad)  -- Lock segment count so the +1 one matches others.
    draw_list:AddCircleFilled(sv_cursor_pos, sv_cursor_rad, user_col32_striped_of_alpha, sv_cursor_segments)
    draw_list:AddCircle(sv_cursor_pos, sv_cursor_rad + 1, col_midgrey, sv_cursor_segments)
    draw_list:AddCircle(sv_cursor_pos, sv_cursor_rad, col_white, sv_cursor_segments)

    -- Render alpha bar
    if alpha_bar then
        local alpha = ImSaturate(col[4])
        local bar1_bb = ImRect(bar1_pos_x, picker_pos.y, bar1_pos_x + bars_width, picker_pos.y + sv_picker_size)
        ImGui.RenderColorRectWithAlphaCheckerboard(draw_list, bar1_bb.Min, bar1_bb.Max, 0, bar1_bb:GetWidth() / 2.0, ImVec2(0.0, 0.0))
        draw_list:AddRectFilledMultiColor(bar1_bb.Min, bar1_bb.Max, user_col32_striped_of_alpha, user_col32_striped_of_alpha, bit.band(user_col32_striped_of_alpha, bit.bnot(IM_COL32_A_MASK)), bit.band(user_col32_striped_of_alpha, bit.bnot(IM_COL32_A_MASK)))

        local bar1_line_y = IM_ROUND(picker_pos.y + (1.0 - alpha) * sv_picker_size)
        ImGui.RenderFrameBorder(bar1_bb.Min, bar1_bb.Max, 0.0)
        RenderArrowsForVerticalBar(draw_list, ImVec2(bar1_pos_x - 1, bar1_line_y), ImVec2(bars_triangles_half_sz + 1, bars_triangles_half_sz), bars_width + 2.0, style.Alpha)
    end

    ImGui.EndGroup()

    if value_changed then
        for i = 1, components do
            if backup_initial_col[i] ~= col[i] then
                break
            end
            if i == components then
                value_changed = false
            end
        end
    end

    if value_changed and g.LastItemData.ID ~= 0 then -- In case of ID collision, the second EndGroup() won't catch g.ActiveId
        ImGui.MarkItemEdited(g.LastItemData.ID)
    end

    if set_current_color_edit_id then
        g.ColorEditCurrentID = 0
    end

    ImGui.PopID()

    return value_changed
end

end

--- @param desc_id   string
--- @param col       ImVec4
--- @param flags?    ImGuiColorEditFlags
--- @param size_arg? ImVec2
function ImGui.ColorButton(desc_id, col, flags, size_arg)
    if flags    == nil then flags    = 0            end
    if size_arg == nil then size_arg = ImVec2(0, 0) end

    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return false
    end

    local g = ImGui.GetCurrentContext()
    local id = window:GetID(desc_id)
    local default_size = ImGui.GetFrameHeight()
    local size = ImVec2(size_arg.x == 0.0 and default_size or size_arg.x, size_arg.y == 0.0 and default_size or size_arg.y)
    local bb = ImRect(window.DC.CursorPos, window.DC.CursorPos + size)
    ImGui.ItemSizeR(bb, (size.y >= default_size) and g.Style.FramePadding.y or 0.0)
    if not ImGui.ItemAdd(bb, id) then
        return false
    end

    local pressed, hovered, held = ImGui.ButtonBehavior(bb, id)

    if bit.band(flags, bit.bor(ImGuiColorEditFlags.NoAlpha, ImGuiColorEditFlags.AlphaOpaque)) ~= 0 then
        flags = bit.band(flags, bit.bnot(bit.bor(ImGuiColorEditFlags.AlphaNoBg, ImGuiColorEditFlags.AlphaPreviewHalf)))
    end

    local col_rgb = ImVec4(col.x, col.y, col.z, col.w)
    if bit.band(flags, ImGuiColorEditFlags.InputHSV) ~= 0 then
        col_rgb.x, col_rgb.y, col_rgb.z = ImGui.ColorConvertHSVtoRGB(col_rgb.x, col_rgb.y, col_rgb.z)
    end

    local col_rgb_without_alpha = ImVec4(col_rgb.x, col_rgb.y, col_rgb.z, 1.0)
    local grid_step = ImMin(size.x, size.y) / 2.99
    local rounding = ImMin(g.Style.FrameRounding, grid_step * 0.5)
    local bb_inner = ImRect()
    ImRect_Copy(bb_inner, bb)
    local off = 0.0
    if bit.band(flags, ImGuiColorEditFlags.NoBorder) == 0 then
        off = -0.75
        bb_inner:Expand(off)
    end
    if bit.band(flags, ImGuiColorEditFlags.AlphaPreviewHalf) ~= 0 and col_rgb.w < 1.0 then
        local mid_x = IM_ROUND((bb_inner.Min.x + bb_inner.Max.x) * 0.5)
        if bit.band(flags, ImGuiColorEditFlags.AlphaNoBg) == 0 then
            ImGui.RenderColorRectWithAlphaCheckerboard(window.DrawList, ImVec2(bb_inner.Min.x + grid_step, bb_inner.Min.y), bb_inner.Max, ImGui.GetColorU32(col_rgb), grid_step, ImVec2(-grid_step + off, off), rounding, ImDrawFlags_RoundCornersRight)
        else
            window.DrawList:AddRectFilled(ImVec2(bb_inner.Min.x + grid_step, bb_inner.Min.y), bb_inner.Max, ImGui.GetColorU32(col_rgb), rounding, ImDrawFlags_RoundCornersRight)
        end
        window.DrawList:AddRectFilled(bb_inner.Min, ImVec2(mid_x, bb_inner.Max.y), ImGui.GetColorU32(col_rgb_without_alpha), rounding, ImDrawFlags_RoundCornersLeft)
    else
        local col_source = (bit.band(flags, ImGuiColorEditFlags.AlphaOpaque) ~= 0) and col_rgb_without_alpha or col_rgb
        if col_source.w < 1.0 and bit.band(flags, ImGuiColorEditFlags.AlphaNoBg) == 0 then
            ImGui.RenderColorRectWithAlphaCheckerboard(window.DrawList, bb_inner.Min, bb_inner.Max, ImGui.GetColorU32(col_source), grid_step, ImVec2(off, off), rounding)
        else
            window.DrawList:AddRectFilled(bb_inner.Min, bb_inner.Max, ImGui.GetColorU32(col_source), rounding)
        end
    end
    ImGui.RenderNavCursor(bb, id)
    if bit.band(flags, ImGuiColorEditFlags.NoBorder) == 0 then
        if g.Style.FrameBorderSize > 0.0 then
            ImGui.RenderFrameBorder(bb.Min, bb.Max, rounding)
        else
            window.DrawList:AddRect(bb.Min, bb.Max, ImGui.GetColorU32(ImGuiCol.FrameBg), rounding)
        end
    end

    -- Drag and Drop Source
    -- NB: The ActiveId test is merely an optional micro-optimization, BeginDragDropSource() does the same test.
    -- if g.ActiveId == id and bit.band(flags, ImGuiColorEditFlags.NoDragDrop) == 0 and ImGui.BeginDragDropSource() then
    --     if bit.band(flags, ImGuiColorEditFlags.NoAlpha) ~= 0 then
    --         ImGui.SetDragDropPayload(IMGUI_PAYLOAD_TYPE_COLOR_3F, col_rgb, ImGuiCond.Once)
    --     else
    --         ImGui.SetDragDropPayload(IMGUI_PAYLOAD_TYPE_COLOR_4F, col_rgb, ImGuiCond.Once)
    --     end
    --     ImGui.ColorButton(desc_id, col, flags)
    --     ImGui.SameLine()
    --     ImGui.TextEx("Color")
    --     ImGui.EndDragDropSource()
    -- end

    -- Tooltip
    if bit.band(flags, ImGuiColorEditFlags.NoTooltip) == 0 and hovered and ImGui.IsItemHovered(ImGuiHoveredFlags_ForTooltip) then
        ImGui.ColorTooltip(desc_id, col, bit.band(flags, bit.bor(ImGuiColorEditFlags.InputMask_, ImGuiColorEditFlags.AlphaMask_)))
    end
end

--- @param text? string
--- @param col   ImVec4
--- @param flags ImGuiColorEditFlags
function ImGui.ColorTooltip(text, col, flags)
    local g = ImGui.GetCurrentContext()

    if not ImGui.BeginTooltipEx(ImGuiTooltipFlags.OverridePrevious, ImGuiWindowFlags_None) then
        return
    end

    local text_end = text and ImGui.FindRenderedTextEnd(text, nil) or 1
    if text_end > 1 then
        --- @cast text string
        ImGui.TextEx(text, text_end)
        ImGui.Separator()
    end

    local sz = ImVec2(g.FontSize * 3 + g.Style.FramePadding.y * 2, g.FontSize * 3 + g.Style.FramePadding.y * 2)
    local cf = ImVec4(col.x, col.y, col.z, (bit.band(flags, ImGuiColorEditFlags.NoAlpha) ~= 0) and 1.0 or col.w)
    local cr = IM_F32_TO_INT8_SAT(col.x)
    local cg = IM_F32_TO_INT8_SAT(col.y)
    local cb = IM_F32_TO_INT8_SAT(col.z)
    local ca = (bit.band(flags, ImGuiColorEditFlags.NoAlpha) ~= 0) and 255 or IM_F32_TO_INT8_SAT(col.w)

    local flags_to_forward = bit.bor(ImGuiColorEditFlags.InputMask_, ImGuiColorEditFlags.AlphaMask_)
    ImGui.ColorButton("##preview", cf, bit.bor(bit.band(flags, flags_to_forward), ImGuiColorEditFlags.NoTooltip), sz)
    ImGui.SameLine()

    if bit.band(flags, ImGuiColorEditFlags.InputRGB) ~= 0 or bit.band(flags, ImGuiColorEditFlags.InputMask_) == 0 then
        if bit.band(flags, ImGuiColorEditFlags.NoAlpha) ~= 0 then
            ImGui.Text("#%02X%02X%02X\nR: %d, G: %d, B: %d\n(%.3f, %.3f, %.3f)", cr, cg, cb, cr, cg, cb, col.x, col.y, col.z)
        else
            ImGui.Text("#%02X%02X%02X%02X\nR:%d, G:%d, B:%d, A:%d\n(%.3f, %.3f, %.3f, %.3f)", cr, cg, cb, ca, cr, cg, cb, ca, col.x, col.y, col.z, col.w)
        end
    elseif bit.band(flags, ImGuiColorEditFlags.InputHSV) ~= 0 then
        if bit.band(flags, ImGuiColorEditFlags.NoAlpha) ~= 0 then
            ImGui.Text("H: %.3f, S: %.3f, V: %.3f", col.x, col.y, col.z)
        else
            ImGui.Text("H: %.3f, S: %.3f, V: %.3f, A: %.3f", col.x, col.y, col.z, col.w)
        end
    end

    ImGui.EndTooltip()
end

--- @param col   float[]
--- @param flags ImGuiColorEditFlags
function ImGui.ColorEditOptionsPopup(col, flags)
    local allow_opt_inputs = bit.band(flags, ImGuiColorEditFlags.DisplayMask_) == 0
    local allow_opt_datatype = bit.band(flags, ImGuiColorEditFlags.DataTypeMask_) == 0

    if (not allow_opt_inputs and not allow_opt_datatype) or not ImGui.BeginPopup("context") then
        return
    end

    local g = ImGui.GetCurrentContext()
    ImGui.PushItemFlag(ImGuiItemFlags_NoMarkEdited, true)
    local opts = g.ColorEditOptions
    if allow_opt_inputs then
        if ImGui.RadioButton("RGB", bit.band(opts, ImGuiColorEditFlags.DisplayRGB) ~= 0) then
            opts = bit.bor(bit.band(opts, bit.bnot(ImGuiColorEditFlags.DisplayMask_)), ImGuiColorEditFlags.DisplayRGB)
        end
        if ImGui.RadioButton("HSV", bit.band(opts, ImGuiColorEditFlags.DisplayHSV) ~= 0) then
            opts = bit.bor(bit.band(opts, bit.bnot(ImGuiColorEditFlags.DisplayMask_)), ImGuiColorEditFlags.DisplayHSV)
        end
        if ImGui.RadioButton("Hex", bit.band(opts, ImGuiColorEditFlags.DisplayHex) ~= 0) then
            opts = bit.bor(bit.band(opts, bit.bnot(ImGuiColorEditFlags.DisplayMask_)), ImGuiColorEditFlags.DisplayHex)
        end
    end
    if allow_opt_datatype then
        if allow_opt_inputs then ImGui.Separator() end
        if ImGui.RadioButton("0..255", bit.band(opts, ImGuiColorEditFlags.Uint8) ~= 0) then
            opts = bit.bor(bit.band(opts, bit.bnot(ImGuiColorEditFlags.DataTypeMask_)), ImGuiColorEditFlags.Uint8)
        end
        if ImGui.RadioButton("0.00..1.00", bit.band(opts, ImGuiColorEditFlags.Float) ~= 0) then
            opts = bit.bor(bit.band(opts, bit.bnot(ImGuiColorEditFlags.DataTypeMask_)), ImGuiColorEditFlags.Float)
        end
    end

    if allow_opt_inputs or allow_opt_datatype then
        ImGui.Separator()
    end
    if ImGui.Button("Copy as..", ImVec2(-1, 0)) then
        ImGui.OpenPopup("Copy")
    end
    if ImGui.BeginPopup("Copy") then
        local cr = IM_F32_TO_INT8_SAT(col[1])
        local cg = IM_F32_TO_INT8_SAT(col[2])
        local cb = IM_F32_TO_INT8_SAT(col[3])
        local ca = (bit.band(flags, ImGuiColorEditFlags.NoAlpha) ~= 0) and 255 or IM_F32_TO_INT8_SAT(col[4])

        local buf1 = ImFormatString("(%.3ff, %.3ff, %.3ff, %.3ff)", col[1], col[2], col[3], (bit.band(flags, ImGuiColorEditFlags.NoAlpha) ~= 0) and 1.0 or col[4])
        if ImGui.Selectable(buf1) then
            ImGui.SetClipboardText(buf1)
        end

        local buf2 = ImFormatString("(%d,%d,%d,%d)", cr, cg, cb, ca)
        if ImGui.Selectable(buf2) then
            ImGui.SetClipboardText(buf2)
        end

        local buf3 = ImFormatString("#%02X%02X%02X", cr, cg, cb)
        if ImGui.Selectable(buf3) then
            ImGui.SetClipboardText(buf3)
        end

        if bit.band(flags, ImGuiColorEditFlags.NoAlpha) == 0 then
            local buf4 = ImFormatString("#%02X%02X%02X%02X", cr, cg, cb, ca)
            if ImGui.Selectable(buf4) then
                ImGui.SetClipboardText(buf4)
            end
        end

        ImGui.EndPopup()
    end

    g.ColorEditOptions = opts
    ImGui.PopItemFlag()
    ImGui.EndPopup()
end

--- @param ref_col float[]
--- @param flags   ImGuiColorEditFlags
function ImGui.ColorPickerOptionsPopup(ref_col, flags)
    local allow_opt_picker = bit.band(flags, ImGuiColorEditFlags.PickerMask_) == 0
    local allow_opt_alpha_bar = (bit.band(flags, ImGuiColorEditFlags.NoAlpha) == 0) and (bit.band(flags, ImGuiColorEditFlags.AlphaBar) == 0)

    if (not allow_opt_picker and not allow_opt_alpha_bar) or not ImGui.BeginPopup("context") then
        return
    end

    local g = ImGui.GetCurrentContext()
    ImGui.PushItemFlag(ImGuiItemFlags_NoMarkEdited, true)
    if allow_opt_picker then
        local picker_size = ImVec2(g.FontSize * 8, ImMax(g.FontSize * 8 - (ImGui.GetFrameHeight() + g.Style.ItemInnerSpacing.x), 1.0)) -- FIXME: Picker size copied from main picker function
        ImGui.PushItemWidth(picker_size.x)
        for picker_type = 0, 1 do
            if picker_type > 0 then
                ImGui.Separator()
            end
            ImGui.PushID(picker_type)
            local picker_flags = bit.bor(ImGuiColorEditFlags.NoInputs, ImGuiColorEditFlags.NoOptions, ImGuiColorEditFlags.NoLabel, ImGuiColorEditFlags.NoSidePreview, bit.band(flags, ImGuiColorEditFlags.NoAlpha))
            if picker_type == 0 then
                picker_flags = bit.bor(picker_flags, ImGuiColorEditFlags.PickerHueBar)
            end
            if picker_type == 1 then
                picker_flags = bit.bor(picker_flags, ImGuiColorEditFlags.PickerHueWheel)
            end
            local backup_pos = ImGui.GetCursorScreenPos()
            -- By default, Selectable() is closing popup
            if ImGui.Selectable("##selectable", false, 0, picker_size) then
                g.ColorEditOptions = bit.bor(bit.band(g.ColorEditOptions, bit.bnot(ImGuiColorEditFlags.PickerMask_)), bit.band(picker_flags, ImGuiColorEditFlags.PickerMask_))
            end
            ImGui.SetCursorScreenPos(backup_pos)
            local previewing_ref_col = ImVec4()
            for i = 1, (bit.band(picker_flags, ImGuiColorEditFlags.NoAlpha) ~= 0 and 3 or 4) do
                previewing_ref_col[i] = ref_col[i]
            end
            ImGui.ColorPicker4("##previewing_picker", previewing_ref_col, picker_flags)
            ImGui.PopID()
        end
        ImGui.PopItemWidth()
    end
    if allow_opt_alpha_bar then
        if allow_opt_picker then
            ImGui.Separator()
        end
        _, g.ColorEditOptions = ImGui.CheckboxFlags("Alpha Bar", g.ColorEditOptions, ImGuiColorEditFlags.AlphaBar)
    end
    ImGui.PopItemFlag()
    ImGui.EndPopup()
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
--- @param selected? bool
--- @param flags?    ImGuiSelectableFlags
--- @param size_arg? any
--- @return bool is_pressed
--- @return bool is_selected # Updated `selected`
function ImGui.Selectable(label, selected, flags, size_arg)
    if selected == nil then selected = false        end
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

    local pos = ImVec2()
    ImVec2_Copy(pos, window.DC.CursorPos)
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

        g.LastItemData.StatusFlags = bit.bor(g.LastItemData.StatusFlags, ImGuiItemStatusFlags.HasClipRect)
        ImRect_Copy(g.LastItemData.ClipRect, window.ClipRect)
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
        g.LastItemData.StatusFlags = bit.bor(g.LastItemData.StatusFlags, ImGuiItemStatusFlags.ToggledSelection)
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
        ImGui.RenderTextClipped(pos, ImVec2(ImMin(pos.x + size.x, window.WorkRect.Max.x), pos.y + size.y), label, nil, label_size, style.SelectableTextAlign, bb)
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
    local window = ImGui.GetCurrentWindow()
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
            local v = values_getter(data, i) -- NaN isn't checked here

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

----------------------------------------------------------------
-- [SECTION] MENU RELATED
----------------------------------------------------------------

-- FIXME: Provided a rectangle perhaps e.g. a BeginMenuBarEx() could be used anywhere..
-- Currently the main responsibility of this function being to setup clip-rect + horizontal layout + menu navigation layer.
-- Ideally we also want this to be responsible for claiming space out of the main window scrolling rectangle, in which case ImGuiWindowFlags_MenuBar will become unnecessary.
-- Then later the same system could be used for multiple menu-bars, scrollbars, side-bars.
function ImGui.BeginMenuBar()
    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return false
    end
    if bit.band(window.Flags, ImGuiWindowFlags_MenuBar) == 0 then
        return false
    end

    IM_ASSERT(not window.DC.MenuBarAppending)
    ImGui.BeginGroup() -- FIXME: Misleading to use a group for that backup/restore
    ImGui.PushID("##MenuBar")

    -- We don't clip with current window clipping rectangle as it is already set to the area below. However we clip with window full rect.
    -- We remove 1 worth of rounding to Max.x to that text in long menus and small windows don't tend to display over the lower-right rounded area, which looks particularly glitchy.
    local border_top = ImMax(IM_ROUND(window.WindowBorderSize * 0.5 - window.TitleBarHeight), 0.0)
    local border_half = IM_ROUND(window.WindowBorderSize * 0.5)
    local bar_rect = window:MenuBarRect()
    local clip_rect = ImRect(ImFloor(bar_rect.Min.x + border_half), ImFloor(bar_rect.Min.y + border_top), ImFloor(ImMax(bar_rect.Min.x, bar_rect.Max.x - ImMax(window.WindowRounding, border_half))), ImFloor(bar_rect.Max.y))
    clip_rect:ClipWith(window.OuterRectClipped)
    ImGui.PushClipRect(clip_rect.Min, clip_rect.Max, false)

    -- We overwrite CursorMaxPos because BeginGroup sets it to CursorPos (essentially the .EmitItem hack in EndMenuBar() would need something analogous here, maybe a BeginGroupEx() with flags)
    ImVec2_Copy(window.DC.CursorPos, ImVec2(bar_rect.Min.x + window.DC.MenuBarOffset.x, bar_rect.Min.y + window.DC.MenuBarOffset.y))
    ImVec2_Copy(window.DC.CursorMaxPos, window.DC.CursorPos)
    window.DC.LayoutType = ImGuiLayoutType.Horizontal
    window.DC.IsSameLine = false
    window.DC.NavLayerCurrent = ImGuiNavLayer.Menu
    window.DC.MenuBarAppending = true
    ImGui.AlignTextToFramePadding()

    return true
end

function ImGui.EndMenuBar()
    local window = ImGui.GetCurrentWindow()
    if window.SkipItems then
        return false
    end
    local g = ImGui.GetCurrentContext()

    IM_ASSERT(bit.band(window.Flags, ImGuiWindowFlags_MenuBar) ~= 0)
    IM_ASSERT(window.DC.MenuBarAppending)

    -- Nav: When a move request within one of our child menu failed, capture the request to navigate among our siblings
    if ImGui.NavMoveRequestButNoResultYet() and (g.NavMoveDir == ImGuiDir.Left or g.NavMoveDir == ImGuiDir.Right) and bit.band(g.NavWindow.Flags, ImGuiWindowFlags_ChildMenu) ~= 0 then
        -- TODO:
    else

    end

    ImGui.PopClipRect()
    ImGui.PopID()
    window.DC.MenuBarOffset.x = window.DC.CursorPos.x - window.Pos.x -- Save horizontal position so next append can reuse it. This is kinda equivalent to a per-layer CursorPos

    -- FIXME: Extremely confusing, cleanup by (a) working on WorkRect stack system (b) not using a Group confusingly here
    local group_data = g.GroupStack:back()
    group_data.EmitItem = false
    local restore_cursor_max_pos = ImVec2()
    ImVec2_Copy(restore_cursor_max_pos, group_data.BackupCursorMaxPos)
    window.DC.IdealMaxPos.x = ImMax(window.DC.IdealMaxPos.x, window.DC.CursorMaxPos.x - window.Scroll.x) -- Convert ideal extents for scrolling layer equivalent
    ImGui.EndGroup() -- Restore position on layer 0 // FIXME: Misleading to use a group for that backup/restore
    window.DC.LayoutType = ImGuiLayoutType.Vertical
    window.DC.IsSameLine = false
    window.DC.NavLayerCurrent = ImGuiNavLayer.Main
    window.DC.MenuBarAppending = false
    ImVec2_Copy(window.DC.CursorMaxPos, restore_cursor_max_pos)
end