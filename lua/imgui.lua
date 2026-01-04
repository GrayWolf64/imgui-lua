--- ImGui for Garry's Mod written in pure Lua
--
local GImGui = nil

IMGUI_DEFINE(IMGUI_VIEWPORT_DEFAULT_ID, 0x11111111)

ImGui = ImGui or {}

local ImFile = {}

local Metatables = {}

IMGUI_INCLUDE("imgui_h.lua")

----------------------------------------------------
-- [SECTION] MISC HELPERS/UTILITIES (File functions)
----------------------------------------------------
local FILE = {
    close = FindMetaTable("File").Close,
    size  = FindMetaTable("File").Size,
    read  = FindMetaTable("File").Read,
    write = FindMetaTable("File").Write
}

function ImFile.Open(filename, mode) return file.Open(filename, mode, "GAME") end
function ImFile.Close(f) FILE.close(f) end
function ImFile.GetSize(f) return FILE.size(f) end
function ImFile.Read(f, num_chars) return FILE.read(f, num_chars) end

function ImFile.LoadToMemory(filename, mode)
    local f = ImFile.Open(filename, mode)
    if not f then return end

    local file_size = ImFile.GetSize(f)
    if file_size <= 0 then
        ImFile.Close(f)
        return
    end

    local file_data = ImFile.Read(f)
    if not file_data or file_data == "" then
        ImFile.Close(f)
        return
    end

    ImFile.Close(f)

    return file_data, file_size
end

IMGUI_INCLUDE("imgui_internal.lua")

local ImResizeGripDef = {
    {CornerPos = ImVec2(1, 1), InnerDir = ImVec2(-1, -1), AngleMin12 = 0, AngleMax12 = 3}, -- Bottom right grip
    {CornerPos = ImVec2(0, 1), InnerDir = ImVec2( 1, -1), AngleMin12 = 3, AngleMax12 = 6} -- Bottom left
}

--- Use FNV1a, as one ImGui FIXME suggested
local function ImHashStr(str)
    local FNV_OFFSET_BASIS = 0x811C9DC5
    local FNV_PRIME = 0x01000193

    local hash = FNV_OFFSET_BASIS

    local byte
    for i = 1, #str do
        byte = string.byte(str, i)
        hash = bit.bxor(hash, byte)
        hash = bit.band(hash * FNV_PRIME, 0xFFFFFFFF)
    end

    assert(hash ~= 0, "ImHash = 0!")

    return hash
end

IMGUI_INCLUDE("imgui_draw.lua")

--- void ImGui::UpdateCurrentFontSize
function ImGui.UpdateCurrentFontSize(restore_font_size_after_scaling)
    local g = GImGui

    local final_size
    if restore_font_size_after_scaling > 0 then
        final_size = restore_font_size_after_scaling
    else
        final_size = 0
    end

    if final_size == 0 then
        final_size = g.FontSizeBase

        final_size = final_size * g.Style.FontScaleMain
    end

    -- Again, due to gmod font system limitation
    final_size = ImRound(final_size)
    final_size = ImClamp(final_size, 4, IMGUI_FONT_SIZE_MAX)

    g.FontSize = final_size

    --local font_data_new = FontCopy(ImFontAtlas.Fonts[g.Font])

    --font_data_new.size = final_size

    --local font_new = ImFontAtlas:AddFont(font_data_new)
    g.Font = font_new
end

--- void ImGui::SetCurrentFont
local function SetCurrentFont(font_name, font_size_before_scaling, font_size_after_scaling)
    local g = GImGui

    g.Font = font_name
    g.FontSizeBase = font_size_before_scaling
    ImGui.UpdateCurrentFontSize(font_size_after_scaling) -- TODO: investigate
end

function ImGui.PushFont(font, font_size_base) -- FIXME: checks not implemented?
    local g = GImGui

    if not font or font == "" then
        font = g.Font
    end
    -- IM_ASSERT(font != NULL)
    -- IM_ASSERT(font_size_base >= 0.0f)

    g.FontStack:push_back({
        Font = font,
        FontSizeBeforeScaling = g.FontSizeBase,
        FontSizeAfterScaling = g.FontSize
    }) -- TODO: ImFontStackData

    if font_size_base == 0 then
        font_size_base = g.FontSizeBase
    end

    SetCurrentFont(font, font_size_base, 0)
end

function ImGui.PopFont()
    local g = GImGui

    if g.FontStack:empty() then return end

    local font_stack_data = g.FontStack:back()
    SetCurrentFont(font_stack_data.Font, font_stack_data.FontSizeBeforeScaling, font_stack_data.FontSizeAfterScaling)

    g.FontStack:pop_back()
end

function ImGui.GetDefaultFont() -- FIXME: fix impl
    local g = GImGui
    local atlas = g.IO.Fonts
    if (atlas.Builder == nil or atlas.Fonts.Size == 0) then
        ImFontAtlasBuildMain(atlas)
    end
    return g.IO.FontDefault and g.IO.FontDefault or atlas.Fonts:at(1)
end

--- void ImGui::UpdateFontsNewFrame
function ImGui.UpdateFontsNewFrame() -- TODO: investigate
    local g = GImGui

    g.Font = ImGui.GetDefaultFont()

    local font_stack_data  = {
        Font = g.Font,
        FontSizeBeforeScaling = g.Style.FontSizeBase,
        FontSizeAfterScaling = g.Style.FontSizeBase
    }

    SetCurrentFont(font_stack_data.Font, font_stack_data.FontSizeBeforeScaling, 0)

    g.FontStack:push_back(font_stack_data)
end

--- void ImGui::UpdateFontsEndFrame
function ImGui.UpdateFontsEndFrame()
    ImGui.PopFont()
end

local DefaultConfig = {
    WindowSize = {w = 500, h = 480},
    WindowPos = {x = 60, y = 60}
}

--- Index starts from 1
local MouseButtonMap = { -- TODO: enums instead
    [1] = MOUSE_LEFT,
    [2] = MOUSE_RIGHT
}

--- void ImGui::Initialize()
local function Initialize()
    local g = GImGui

    local viewport = ImGuiViewportP()
    viewport.ID = IMGUI_VIEWPORT_DEFAULT_ID
    g.Viewports:push_back(viewport)
end

function ImGui.CreateContext()
    GImGui = ImGuiContext()

    ImGui.StyleColorsDark(GImGui.Style)
    GImGui.Config = DefaultConfig

    for i = 0, 59 do GImGui.FramerateSecPerFrame[i] = 0 end

    Initialize()

    return GImGui
end



--- void ImGui::DestroyContext
-- local function DestroyContext()

-- end

local function CreateNewWindow(name)
    local g = GImGui

    if not g then return end

    local window_id = ImHashStr(name)

    local window = ImGuiWindow(g, name)

    window.ID = window_id
    window.Pos = ImVec2(g.Config.WindowPos.x, g.Config.WindowPos.y)
    window.Size = ImVec2(g.Config.WindowSize.w, g.Config.WindowSize.h) -- TODO: Don't use this Config thing
    window.SizeFull = ImVec2(g.Config.WindowSize.w, g.Config.WindowSize.h)

    g.WindowsByID[window_id] = window

    g.Windows:push_back(window)

    return window
end

--- TODO: fix drawlist
--- void ImGui::PushClipRect

--- void ImGui::PopClipRect

--- void ImGui::KeepAliveID(ImGuiID id)
local function KeepAliveID(id)
    local g = GImGui

    if g.ActiveID == id then
        g.ActiveIDIsAlive = id
    end

    if g.DeactivatedItemData.ID == id then
        g.DeactivatedItemData.IsAlive = true
    end
end

--- bool ImGui::ItemAdd
local function ItemAdd(bb, id, nav_bb_arg, extra_flags)
    local g = GImGui
    local window = g.CurrentWindow

    g.LastItemData.ID = id
    g.LastItemData.Rect = bb

    if nav_bb_arg then
        g.LastItemData.NavRect = nav_bb_arg
    else
        g.LastItemData.NavRect = bb
    end

    -- g.LastItemData.ItemFlags = g.CurrentItemFlags | g.NextItemData.ItemFlags | extra_flags;
    -- g.LastItemData.StatusFlags = ImGuiItemStatusFlags_None;

    if id ~= 0 then
        KeepAliveID(id)
    end

    -- g.NextItemData.HasFlags = ImGuiNextItemDataFlagsNone;
    -- g.NextItemData.ItemFlags = ImGuiItemFlags_None;

    -- local is_rect_visible = Overlaps(bb, window.ClipRect)
end

local function ItemSize(size, text_baseline_y)
    local g = GImGui
    local window = g.CurrentWindow

    if window.SkipItems then return end

    local offset_to_match_baseline_y
    if text_baseline_y >= 0 then
        offset_to_match_baseline_y = ImMax(0, window.DC.CurrLineTextBaseOffset - text_baseline_y)
    else
        offset_to_match_baseline_y = 0
    end

    local line_y1
    if window.DC.IsSameLine then
        line_y1 = window.DC.CursorPosPrevLine.y
    else
        line_y1 = window.DC.CursorPos.y
    end

    local line_height = ImMax(window.DC.CurrLineSize.y, window.DC.CursorPos.y - line_y1 + size.y + offset_to_match_baseline_y)

    window.DC.CursorPosPrevLine.x = window.DC.CursorPos.x + size.x
    window.DC.CursorPosPrevLine.y = line_y1
    window.DC.CursorPos.x = ImTrunc(window.Pos.x + window.DC.Indent.x + window.DC.ColumnsOffset.x)
    window.DC.CursorPos.y = ImTrunc(line_y1 + line_height + g.Style.ItemSpacing.y)
    window.DC.CursorMaxPos.x = ImMax(window.DC.CursorMaxPos.x, window.DC.CursorPosPrevLine.x)
    window.DC.CursorMaxPos.y = ImMax(window.DC.CursorMaxPos.y, window.DC.CursorPos.y - g.Style.ItemSpacing.y)

    window.DC.PrevLineSize.y = line_height
    window.DC.CurrLineSize.y = 0
    window.DC.PrevLineTextBaseOffset = ImMax(window.DC.CurrLineTextBaseOffset, text_baseline_y)
    window.DC.CurrLineTextBaseOffset = 0
    window.DC.IsSetPos = false
    window.DC.IsSameLine = false

    --- Horizontal layout mode
    -- if (window->DC.LayoutType == ImGuiLayoutType_Horizontal)
    -- SameLine();
end

--- bool ImGui::IsItemActive()
local function IsItemActive()
    local g = GImGui

    if g.ActiveID ~= 0 then
        return g.ActiveID == g.LastItemData.ID
    end

    return false
end

--- void ImGuiStyle::ScaleAllSizes
-- local function ScaleAllSizes(scale_factor)

-- end

--- void ImGui::BringWindowToDisplayFront(ImGuiWindow* window)
local function BringWindowToDisplayFront(window)
    local g = GImGui

    local current_front_window = g.Windows:back()

    if current_front_window == window then return end

    for i, this_window in g.Windows:iter() do
        if this_window == window then
            g.Windows:erase(i)
            break
        end
    end

    g.Windows:push_back(window)
end

--- void ImGui::SetNavWindow
local function SetNavWindow(window)
    if GImGui.NavWindow ~= window then
        GImGui.NavWindow = window
    end
end

--- void ImGui::FocusWindow
local function FocusWindow(window)
    if GImGui.NavWindow ~= window then
        SetNavWindow(window)
    end

    if not window then return end

    BringWindowToDisplayFront(window)
end

--- void ImGui::SetFocusID

--- void ImGui::StopMouseMovingWindow()
local function StopMouseMovingWindow()
    GImGui.MovingWindow = nil
end

--- void ImGui::SetActiveID
function ImGui.SetActiveID(id, window)
    local g = GImGui

    if g.ActiveID ~= 0 then
        g.DeactivatedItemData.ID = g.ActiveID
        -- g.DeactivatedItemData.ElapseFrame =
        -- g.DeactivatedItemData.HasBeenEditedBefore =
        g.DeactivatedItemData.IsAlive = (g.ActiveIDIsAlive == g.ActiveID)

        if g.MovingWindow and (g.ActiveID == g.MovingWindow.MoveID) then
            print("SetActiveID() cancel MovingWindow")
            StopMouseMovingWindow()
        end
    end

    g.ActiveIDIsJustActivated = (g.ActiveID ~= id)

    g.ActiveID = id
    g.ActiveIDWindow = window

    if id ~= 0 then
        g.ActiveIDIsAlive = id
    end
end

function ImGui.ClearActiveID()
    ImGui.SetActiveID(0, nil)
end

local function PushID(str_id)
    local window = GImGui.CurrentWindow
    if not window then return end

    window.IDStack:push_back(str_id)
end

local function PopID()
    local window = GImGui.CurrentWindow
    if not window then return end

    window.IDStack:pop_back()
end

local table_concat = table.concat
local function GetID(str_id)
    local window = GImGui.CurrentWindow
    if not window then return end

    local full_string = table_concat(window.IDStack.Data, "#") .. "#" .. (str_id or "") -- FIXME: no Data

    return ImHashStr(full_string)
end

local function IsMouseHoveringRect(r_min, r_max)
    local rect_clipped = ImRect(r_min, r_max)

    return rect_clipped:contains_point(GImGui.IO.MousePos)
end

--- void ImGui::SetHoveredID
local function SetHoveredID(id)
    local g = GImGui

    g.HoveredID = id
end

--- bool ImGui::ItemHoverable
function ImGui.ItemHoverable(id, bb)
    local g = GImGui

    local window = g.CurrentWindow

    if g.HoveredWindow ~= window then
        return false
    end

    if not IsMouseHoveringRect(bb.Min, bb.Max) then
        return false
    end

    if g.HoveredID ~= 0 and g.HoveredID ~= id then
        return false
    end

    if id ~= 0 then
        SetHoveredID(id)
    end

    return true
end

--- bool ImGui::IsMouseDown
function ImGui.IsMouseDown(button)
    local g = GImGui

    return g.IO.MouseDown[button]
end

--- bool ImGui::IsMouseClicked
function ImGui.IsMouseClicked(button)
    local g = GImGui

    if not g.IO.MouseDown[button] then
        return false
    end

    local t = g.IO.MouseDownDuration[button]
    if t < 0 then
        return false
    end

    local pressed = (t == 0)
    if not pressed then
        return false
    end

    return true
end

IMGUI_INCLUDE("imgui_widgets.lua")

--- static bool IsWindowActiveAndVisible
local function IsWindowActiveAndVisible(window)
    return window.Active and not window.Hidden
end

--- static inline ImVec2 CalcWindowMinSize
local function CalcWindowMinSize(window)
    local g = GImGui

    local size_min = ImVec2()

    size_min.x = ImMax(g.Style.WindowMinSize.x, IMGUI_WINDOW_HARD_MIN_SIZE)
    size_min.y = ImMax(g.Style.WindowMinSize.y, IMGUI_WINDOW_HARD_MIN_SIZE)

    local window_for_height = window
    size_min.y = ImMax(size_min.y, window_for_height.TitleBarHeight + ImMax(0, g.Style.WindowRounding - 1))

    return size_min
end

--- static ImVec2 CalcWindowSizeAfterConstraint
local function CalcWindowSizeAfterConstraint(window, size_desired)
    local size_min = CalcWindowMinSize(window)

    return ImVec2(
        ImMax(size_desired.x, size_min.x),
        ImMax(size_desired.y, size_min.y)
    )
end

--- static void CalcResizePosSizeFromAnyCorner
local function CalcResizePosSizeFromAnyCorner(window, corner_target, corner_pos)
    local pos_min = ImVec2(
        ImLerp(corner_target.x, window.Pos.x, corner_pos.x),
        ImLerp(corner_target.y, window.Pos.y, corner_pos.y)
    )
    local pos_max = ImVec2(
        ImLerp(window.Pos.x + window.Size.x, corner_target.x, corner_pos.x),
        ImLerp(window.Pos.y + window.Size.y, corner_target.y, corner_pos.y)
    )
    local size_expected = pos_max - pos_min

    local size_constrained = CalcWindowSizeAfterConstraint(window, size_expected)

    local out_pos = ImVec2(pos_min.x, pos_min.y)

    if corner_pos.x == 0 then
        out_pos.x = out_pos.x - (size_constrained.x - size_expected.x)
    end
    if corner_pos.y == 0 then
        out_pos.y = out_pos.y - (size_constrained.y - size_expected.y)
    end

    return out_pos, size_constrained
end

--- static int ImGui::UpdateWindowManualResize
local function UpdateWindowManualResize(window, resize_grip_col)
    local g = GImGui

    if window.WasActive == false then return end

    local grip_draw_size = ImTrunc(ImMax(g.FontSize * 1.35, g.Style.WindowRounding + 1.0 + g.FontSize * 0.2))
    local grip_hover_inner_size = ImTrunc(grip_draw_size * 0.75)
    local grip_hover_outer_size = g.WindowsBorderHoverPadding + 1

    PushID("#RESIZE")

    local pos_target = ImVec2(FLT_MAX, FLT_MAX)
    local size_target = ImVec2(FLT_MAX, FLT_MAX)

    local min_size = g.Style.WindowMinSize
    local max_size = {x = FLT_MAX, y = FLT_MAX}

    local clamp_rect = ImRect(window.Pos + min_size, window.Pos + max_size) -- visibility rect?

    for i = 1, #ImResizeGripDef do
        local corner_pos = ImResizeGripDef[i].CornerPos
        local inner_dir = ImResizeGripDef[i].InnerDir

        local corner = ImVec2(window.Pos.x + corner_pos.x * window.Size.x, window.Pos.y + corner_pos.y * window.Size.y)

        local resize_rect = ImRect(corner - inner_dir * grip_hover_outer_size, corner + inner_dir * grip_hover_inner_size)

        if resize_rect.Min.x > resize_rect.Max.x then resize_rect.Min.x, resize_rect.Max.x = resize_rect.Max.x, resize_rect.Min.x end
        if resize_rect.Min.y > resize_rect.Max.y then resize_rect.Min.y, resize_rect.Max.y = resize_rect.Max.y, resize_rect.Min.y end

        local resize_grip_id = GetID(i)

        ItemAdd(resize_rect, resize_grip_id)
        local pressed, hovered, held = ButtonBehavior(resize_grip_id, resize_rect)

        if hovered or held then
            if i == 1 then
                ImGui.SetMouseCursor("sizenwse")
            elseif i == 2 then
                ImGui.SetMouseCursor("sizenesw")
            end
        end

        if held then
            local clamp_min = ImVec2((corner_pos.x == 1.0) and clamp_rect.Min.x or -FLT_MAX, (corner_pos.y == 1.0) and clamp_rect.Min.y or -FLT_MAX)
            local clamp_max = ImVec2((corner_pos.x == 0.0) and clamp_rect.Max.x or FLT_MAX, (corner_pos.y == 0.0) and clamp_rect.Max.y or FLT_MAX)

            local corner_target = ImVec2(
                g.IO.MousePos.x - g.ActiveIDClickOffset.x + ImLerp(inner_dir.x * grip_hover_outer_size, inner_dir.x * -grip_hover_inner_size, corner_pos.x),
                g.IO.MousePos.y - g.ActiveIDClickOffset.y + ImLerp(inner_dir.y * grip_hover_outer_size, inner_dir.y * -grip_hover_inner_size, corner_pos.y)
            )

            corner_target.x = ImClamp(corner_target.x, clamp_min.x, clamp_max.x)
            corner_target.y = ImClamp(corner_target.y, clamp_min.y, clamp_max.y)

            pos_target, size_target = CalcResizePosSizeFromAnyCorner(window, corner_target, corner_pos)
        end

        local resize_grip_visible = held or hovered or (i == 1 and bit.band(window.Flags, ImGuiWindowFlags_ChildWindow) == 0)
        if resize_grip_visible then
            if held then
                resize_grip_col[i] = g.Style.Colors.ResizeGripActive
            else
                if hovered then
                    resize_grip_col[i] = g.Style.Colors.ResizeGripHovered
                else
                    resize_grip_col[i] = g.Style.Colors.ResizeGrip
                end
            end
        end
    end

    if size_target.x ~= FLT_MAX and (window.Size.x ~= size_target.x or window.SizeFull.x ~= size_target.x) then
        window.Size.x = size_target.x
        window.SizeFull.x = size_target.x
    end

    if size_target.y ~= FLT_MAX and (window.Size.y ~= size_target.y or window.SizeFull.y ~= size_target.y) then
        window.Size.y = size_target.y
        window.SizeFull.y = size_target.y
    end

    if pos_target.x ~= FLT_MAX and window.Pos.x ~= ImFloor(pos_target.x) then
        window.Pos.x = ImFloor(pos_target.x)
    end

    if pos_target.y ~= FLT_MAX and window.Pos.y ~= ImFloor(pos_target.y) then
        window.Pos.y = ImFloor(pos_target.y)
    end

    PopID()
end

--- TODO: AutoFit -> ScrollBar() -> Text()
--- float ImGui::CalcWrapWidthForPos
local function CalcWrapWidthForPos(pos, wrap_pos_x)
    if wrap_pos_x < 0 then return 0 end

    local g = GImGui
    local window = g.CurrentWindow

    -- if wrap_pos_x == 0 then
    --     wrap_pos_x = 
    -- end
end

local function Text(str_text)
    local g = GImGui
    local window = g.CurrentWindow

    if window.SkipItems then return end

    local strlen = #str_text
    local text_pos = ImVec2(window.DC.CursorPos.x, window.DC.CursorPos.y + window.DC.CurrLineTextBaseOffset)

    local wrap_pos_x = window.DC.TextWrapPos
    local wrap_enabled = wrap_pos_x >= 0

    -- if strlen <= 2e11 or wrap_enabled then

    -- end
end

--- ImGui::RenderMouseCursor

--- ImGui::RenderFrame
local function RenderFrame(p_min, p_max, fill_col, borders, rounding) -- TODO: implement rounding
    local g = GImGui
    local window = g.CurrentWindow

    window.DrawList:AddRectFilled(p_min, p_max, fill_col, rounding, 0)

    local border_size = g.Style.FrameBorderSize
    if borders and border_size > 0 then
        window.DrawList:AddRect(p_min + ImVec2(1, 1), p_max + ImVec2(1, 1), g.Style.Colors.BorderShadow, rounding, 0, border_size)
        window.DrawList:AddRect(p_min, p_max, g.Style.Colors.Border, rounding, 0, border_size)
    end
end

--- ImGui::RenderWindowDecorations
local function RenderWindowDecorations(window, title_bar_rect, titlebar_is_highlight, resize_grip_col, resize_grip_draw_size)
    local g = GImGui

    local title_color
    if titlebar_is_highlight then
        title_color = g.Style.Colors.TitleBgActive
    else
        title_color = g.Style.Colors.TitleBg
    end

    local border_width = g.Style.FrameBorderSize
    local window_rounding = window.WindowRounding
    local window_border_size = window.WindowBorderSize

    if window.Collapsed then
        RenderFrame(title_bar_rect.Min, title_bar_rect.Max, g.Style.Colors.TitleBgCollapsed, true, 0)
    else
        -- Title bar
        window.DrawList:AddRectFilled(title_bar_rect.Min, title_bar_rect.Max, title_color, 0, 0) -- TODO: rounding
        -- Window background
        window.DrawList:AddRectFilled(window.Pos + ImVec2(0, window.TitleBarHeight), window.Pos + window.Size, g.Style.Colors.WindowBg, 0, 0) -- TODO: rounding

        -- Resize grip(s)
        for i = 1, #ImResizeGripDef do
            local col = resize_grip_col[i]
            if not col then continue end -- TODO: use IM_COL32_A_MASK

            local inner_dir = ImResizeGripDef[i].InnerDir
            local corner = window.Pos + ImResizeGripDef[i].CornerPos * window.Size
            local border_inner = ImRound(window_border_size * 0.5)
            window.DrawList:PathLineTo(corner + inner_dir * ((i % 2 == 1) and ImVec2(border_inner, resize_grip_draw_size) or ImVec2(resize_grip_draw_size, border_inner)))
            window.DrawList:PathLineTo(corner + inner_dir * ((i % 2 == 1) and ImVec2(resize_grip_draw_size, border_inner) or ImVec2(border_inner, resize_grip_draw_size)))
            window.DrawList:PathArcToFast(ImVec2(corner.x + inner_dir.x * (window_rounding + border_inner), corner.y + inner_dir.y * (window_rounding + border_inner)), window_rounding, ImResizeGripDef[i].AngleMin12, ImResizeGripDef[i].AngleMax12)
            window.DrawList:PathFillConvex(col)
        end

        -- RenderWindowOuterBorders?
        window.DrawList:AddRect(window.Pos, window.Pos + window.Size, g.Style.Colors.Border, 0, 0, border_width)
    end
end

--- ImGui::RenderWindowTitleBarContents
local function RenderWindowTitleBarContents(window, p_open)
    local g = GImGui

    local pad_l = g.Style.FramePadding.x
    local pad_r = g.Style.FramePadding.x
    local button_size = g.FontSize

    local collapse_button_size = button_size -- TODO: impl has_close_button and etc. based
    local collapse_button_pos = ImVec2(window.Pos.x + pad_l, window.Pos.y + g.Style.FramePadding.y)

    local close_button_size = button_size
    local close_button_pos = ImVec2(window.Pos.x + window.Size.x - button_size - pad_r, window.Pos.y + g.Style.FramePadding.y)

    if CollapseButton(GetID("#COLLAPSE"), collapse_button_pos) then
        window.Collapsed = not window.Collapsed
    end

    if CloseButton(GetID("#CLOSE"), close_button_pos) then
        p_open[1] = false
        window.Hidden = true -- TODO: temporary hidden set
    end

    -- FIXME:
    -- Title text
    -- surface.SetFont(g.Font) -- TODO: layouting
    -- local _, text_h = surface.GetTextSize(window.Name)
    -- local text_clip_width = window.Size.x - window.TitleBarHeight - close_button_size - collapse_button_size
    -- window.DrawList:RenderTextClipped(window.Name, g.Font,
    --     ImVec2(window.Pos.x + window.TitleBarHeight, window.Pos.y + (window.TitleBarHeight - text_h) / 1.3),
    --     g.Style.Colors.Text,
    --     text_clip_width, window.Size.y)
end

--- static void SetCurrentWindow
local function SetCurrentWindow(window)
    local g = GImGui
    g.CurrentWindow = window

    if window then
        local backup_skip_items = window.SkipItems
        window.SkipItems = false

        ImGui.UpdateCurrentFontSize(0)

        window.SkipItems = backup_skip_items
    end
end

--- void ImGui::SetWindowPos
local function SetWindowPos(window, pos)
    local old_pos = window.Pos:copy()

    window.Pos.x = ImTrunc(pos.x)
    window.Pos.y = ImTrunc(pos.y)

    local offset = window.Pos - old_pos

    if offset.x == 0 and offset.y == 0 then return end

    window.DC.CursorPos = window.DC.CursorPos + offset
    window.DC.CursorMaxPos = window.DC.CursorMaxPos + offset
    window.DC.IdealMaxPos = window.DC.IdealMaxPos + offset
    window.DC.CursorStartPos = window.DC.CursorStartPos + offset
end

--- void ImGui::StartMouseMovingWindow
local function StartMouseMovingWindow(window)
    local g = GImGui

    FocusWindow(window)
    ImGui.SetActiveID(window.MoveID, window)

    g.ActiveIDClickOffset = g.IO.MouseClickedPos[1] - window.Pos

    g.MovingWindow = window
end

--- void ImGui::UpdateMouseMovingWindowNewFrame
function ImGui.UpdateMouseMovingWindowNewFrame()
    local g = GImGui
    local window = g.MovingWindow

    if window then
        KeepAliveID(g.ActiveID)

        if g.IO.MouseDown[1] then
            SetWindowPos(window, g.IO.MousePos - g.ActiveIDClickOffset)

            FocusWindow(g.MovingWindow)
        else
            StopMouseMovingWindow()
            ImGui.ClearActiveID()
        end
    else
        if (g.ActiveIDWindow and g.ActiveIDWindow.MoveID == g.ActiveID) then
            KeepAliveID(g.ActiveID)

            if g.IO.MouseDown[1] then
                ImGui.ClearActiveID()
            end
        end
    end
end

--- ImDrawListSharedData* ImGui::GetDrawListSharedData()
function ImGui.GetDrawListSharedData()
    return GImGui.DrawListSharedData
end

--- void ImGui::UpdateMouseMovingWindowEndFrame()
function ImGui.UpdateMouseMovingWindowEndFrame()
    local g = GImGui

    if g.ActiveID ~= 0 or g.HoveredID ~= 0 then return end

    local hovered_window = g.HoveredWindow

    if g.IO.MouseClicked[1] then
        if hovered_window then
            StartMouseMovingWindow(hovered_window)
        else -- TODO: investigate elseif (hovered_window == nil and g.NavWindow == nil) 
            FocusWindow(nil)
            g.ActiveIDWindow = nil
        end
    end
end

--- ImGui::FindWindowByID
local function FindWindowByID(id)
    local g = GImGui

    if not g then return end

    return g.WindowsByID[id]
end

--- ImGui::FindWindowByName
local function FindWindowByName(name)
    local id = ImHashStr(name)
    return FindWindowByID(id)
end

function ImGui.GetMainViewport()
    local g = GImGui

    return g.Viewports:at(1)
end

--- void ImGui::SetWindowViewport(ImGuiWindow* window, ImGuiViewportP* viewport)
local function SetWindowViewport(window, viewport)
    window.Viewport = viewport
end

-- `p_open` will be set to false when the close button is pressed.
function ImGui.Begin(name, p_open, flags)
    local g = GImGui

    if name == nil or name == "" then return false end
    -- IM_ASSERT(g.FrameCountEnded != g.FrameCount)

    local window = FindWindowByName(name)
    local window_just_created = (window == nil)
    if window_just_created then
        window = CreateNewWindow(name)
    end

    local current_frame = g.FrameCount
    local first_begin_of_the_frame = (window.LastFrameActive ~= current_frame)
    local window_just_activated_by_user = (window.LastFrameActive < (current_frame - 1))

    if first_begin_of_the_frame then
        window.LastFrameActive = current_frame
    else
        flags = window.Flags
    end

    g.CurrentWindow = nil

    if first_begin_of_the_frame and not window.SkipRefresh then
        window.Active = true
        window.HasCloseButton = (p_open[1] ~= nil)
        window.ClipRect = ImVec4(-FLT_MAX, -FLT_MAX, FLT_MAX, FLT_MAX)

        window.DrawList:_ResetForNewFrame()

        local viewport = ImGui.GetMainViewport()
        SetWindowViewport(window, viewport)
        SetCurrentWindow(window)

        -- TODO: if (flags & ImGuiWindowFlagsChildWindow)
        --     window->WindowBorderSize = style.ChildBorderSize;
        -- else
        --     window->WindowBorderSize = ((flags & (ImGuiWindowFlagsPopup | ImGuiWindowFlagsTooltip)) && !(flags & ImGuiWindowFlagsModal)) ? style.PopupBorderSize : style.WindowBorderSize;
    end

    local window_id = window.ID

    window.IDStack:clear_delete()

    PushID(window_id)
    window.MoveID = GetID("#MOVE") -- TODO: investigate

    g.CurrentWindowStack:push_back(window)

    window.TitleBarHeight = g.FontSize + g.Style.FramePadding.y * 2

    if window.Collapsed then
        window.Size.y = window.TitleBarHeight
    else
        window.Size.y = window.SizeFull.y
    end

    local resize_grip_col = {} -- TODO: change this
    if not window.Collapsed then
        UpdateWindowManualResize(window, resize_grip_col)
    end
    local resize_grip_draw_size = ImTrunc(ImMax(g.FontSize * 1.10, g.Style.WindowRounding + 1.0 + g.FontSize * 0.2));

    local title_bar_rect = window:TitleBarRect()

    local title_bar_is_highlight = (g.NavWindow == window) -- TODO: proper cond, just simple highlight now

    RenderWindowDecorations(window, title_bar_rect, title_bar_is_highlight, resize_grip_col, resize_grip_draw_size)

    RenderWindowTitleBarContents(window, p_open)

    return not window.Collapsed
end

function ImGui.End()
    local g = GImGui

    local window = g.CurrentWindow
    if not window then return end

    PopID()
    g.CurrentWindowStack:pop_back()

    SetCurrentWindow(g.CurrentWindowStack:back())
end

local function FindHoveredWindowEx()
    local g = GImGui

    g.HoveredWindow = nil

    for i = g.Windows.Size, 1, -1 do
        local window = g.Windows:at(i)

        if not window or ((not window.WasActive) or window.Hidden) then continue end

        local hit = IsMouseHoveringRect(window.Pos, window.Pos + window.Size)

        if hit and g.HoveredWindow == nil then
            g.HoveredWindow = window

            break
        end
    end
end

--- void ImGui::UpdateHoveredWindowAndCaptureFlags
function ImGui.UpdateHoveredWindowAndCaptureFlags()
    local g = GImGui
    local io = g.IO

    FindHoveredWindowEx()

    local mouse_earliest_down = -1
    local mouse_any_down = false

    for i = 1, #MouseButtonMap do
        if io.MouseClicked[i] then
            io.MouseDownOwned[i] = (g.HoveredWindow ~= nil)
        end

        mouse_any_down = mouse_any_down or io.MouseDown[i]
        if (io.MouseDown[i] or io.MouseReleased[i]) then
            if (mouse_earliest_down == -1 or (io.MouseClickedTime[i] < io.MouseClickedTime[mouse_earliest_down])) then
                mouse_earliest_down = i
            end
        end
    end

    local mouse_avail = (mouse_earliest_down == -1) or io.MouseDownOwned[mouse_earliest_down]

    if (g.WantCaptureMouseNextFrame ~= -1) then
        io.WantCaptureMouse = (g.WantCaptureMouseNextFrame ~= 0)
    else
        io.WantCaptureMouse = (mouse_avail and (g.HoveredWindow ~= nil or mouse_any_down)) -- or has_open_popup
    end
end

--- ImGui::UpdateMouseInputs()
function ImGui.UpdateMouseInputs()
    local g = GImGui
    local io = g.IO

    io.MousePos.x = GetMouseX()
    io.MousePos.y = GetMouseY()

    for i = 1, #MouseButtonMap do
        local button_down = io.IsMouseDown(MouseButtonMap[i])

        io.MouseClicked[i] = button_down and (io.MouseDownDuration[i] < 0)
        io.MouseReleased[i] = not button_down and (io.MouseDownDuration[i] >= 0)

        if io.MouseClicked[i] then
            io.MouseClickedTime[i] = g.Time
            io.MouseClickedPos[i] = ImVec2(io.MousePos.x, io.MousePos.y)
        end

        if io.MouseReleased[i] then
            io.MouseReleasedTime[i] = g.Time
        end

        if button_down then
            if io.MouseDownDuration[i] < 0 then
                io.MouseDownDuration[i] = 0
            else
                io.MouseDownDuration[i] = io.MouseDownDuration[i] + 1
            end
        else
            io.MouseDownDuration[i] = -1.0
        end

        io.MouseDownDurationPrev[i] = io.MouseDownDuration[i]

        io.MouseDown[i] = button_down
    end
end

--- static void SetupDrawListSharedData()
local function SetupDrawListSharedData()
    local g = GImGui

    g.DrawListSharedData:SetCircleTessellationMaxError(g.Style.CircleTessellationMaxError)
end
-- TODO: Have to be careful that e.g. every drawlist can have a pointer to shareddata(the same) of the context

local function InitViewportDrawData(viewport)
    local g = GImGui
    local draw_data = viewport.DrawDataP

    viewport.DrawDataBuilder.Layers[1] = draw_data.CmdLists
    viewport.DrawDataBuilder.Layers[2] = viewport.DrawDataBuilder.LayerData1
    viewport.DrawDataBuilder.Layers[1]:resize(0)
    viewport.DrawDataBuilder.Layers[2]:resize(0)

    draw_data.Valid = true
    draw_data.CmdListsCount = 0
    draw_data.TotalVtxCount = 0
    draw_data.TotalIdxCount = 0
    draw_data.DisplayPos = viewport.Pos
    draw_data.DisplaySize = viewport.Size
end

local function GetViewportBgFgDrawList(viewport, drawlist_no, drawlist_name)
    local g = GImGui

    local draw_list = viewport.BgFgDrawLists[drawlist_no]
    if draw_list == nil then
        draw_list = ImDrawList(g.DrawListSharedData)
        draw_list._OwnerName = drawlist_name
        viewport.BgFgDrawLists[drawlist_no] = draw_list
    end

    if viewport.BgFgDrawListsLastFrame[drawlist_no] ~= g.FrameCount then
        draw_list:_ResetForNewFrame()
        draw_list:PushClipRect(viewport.Pos, viewport.Pos + viewport.Size, false)
        viewport.BgFgDrawListsLastFrame[drawlist_no] = g.FrameCount
    end

    return draw_list
end

local function GetBackgroundDrawList(viewport)
    local g = GImGui

    if viewport ~= nil then
        return GetViewportBgFgDrawList(viewport, 1, "##Background")
    end

    return GetViewportBgFgDrawList(g.Viewports:at(1), 1, "##Background")
end

local function GetForegroundDrawList(viewport)
    local g = GImGui

    if viewport ~= nil then
        return GetViewportBgFgDrawList(viewport, 2, "##Foreground")
    end

    return GetViewportBgFgDrawList(g.Viewports:at(1), 2, "##Foreground")
end

--- static void AddWindowToDrawData(ImGuiWindow* window, int layer)
local function AddWindowToDrawData(window, layer)
    local g = GImGui
    local viewport = g.Viewports:at(1)
    g.IO.MetricsRenderWindows = g.IO.MetricsRenderWindows + 1
    -- splitter
    ImGui.AddDrawListToDrawDataEx(viewport.DrawDataP, viewport.DrawDataBuilder.Layers[layer], window.DrawList)
    -- child windows
end

--- static inline int GetWindowDisplayLayer(ImGuiWindow* window)
local function GetWindowDisplayLayer(window)
    return (bit.band(window.Flags, ImGuiWindowFlags_Tooltip) ~= 0) and 2 or 1
end

--- static inline void AddRootWindowToDrawData(ImGuiWindow* window)
local function AddRootWindowToDrawData(window)
    AddWindowToDrawData(window, GetWindowDisplayLayer(window))
end

local function FlattenDrawDataIntoSingleLayer(builder)
    local n = builder.Layers[1].Size
    local full_size = n

    for i = 2, #builder.Layers do
        full_size = full_size + builder.Layers[i].Size
    end

    builder.Layers[1]:resize(full_size)

    for layer_n = 2, #builder.Layers do
        local layer = builder.Layers[layer_n]
        if layer:empty() then
            continue
        end

        for i = 1, #layer do
            builder.Layers[1][n + i] = layer[i]
        end

        n = n + layer.Size

        layer:resize(0)
    end
end

--- static void ImGui::UpdateViewportsNewFrame()
function ImGui.UpdateViewportsNewFrame()
    local g = GImGui
    IM_ASSERT(g.Viewports.Size == 1)

    local main_viewport = g.Viewports:at(1)
    main_viewport.Pos = ImVec2(0, 0)
    main_viewport.Size = g.IO.DisplaySize

    for _, viewport in g.Viewports:iter() do
        viewport.WorkInsetMin = viewport.BuildWorkInsetMin
        viewport.WorkInsetMax = viewport.BuildWorkInsetMax
        viewport.BuildWorkInsetMax = ImVec2(0.0, 0.0)
        viewport.BuildWorkInsetMin = ImVec2(0.0, 0.0)
        viewport:UpdateWorkRect()
    end
end

function ImGui.NewFrame()
    local g = GImGui

    g.Time = g.Time + g.IO.DeltaTime

    if not g or not g.Initialized then return end

    g.FrameCount = g.FrameCount + 1

    -- FIXME: are lines below correct and necessary
    g.FramerateSecPerFrameAccum = g.FramerateSecPerFrameAccum + (g.IO.DeltaTime - g.FramerateSecPerFrame[g.FramerateSecPerFrameIdx])
    g.FramerateSecPerFrame[g.FramerateSecPerFrameIdx] = g.IO.DeltaTime
    g.FramerateSecPerFrameIdx = (g.FramerateSecPerFrameIdx + 1) % 60
    g.FramerateSecPerFrameCount = ImMin(g.FramerateSecPerFrameCount + 1, 60)
    if g.FramerateSecPerFrameAccum > 0 then
        g.IO.Framerate = (1.0 / (g.FramerateSecPerFrameAccum / g.FramerateSecPerFrameCount))
    else
        g.IO.Framerate = FLT_MAX
    end

    g.CurrentWindowStack:clear_delete()

    g.CurrentWindow = nil

    ImGui.UpdateViewportsNewFrame()

    SetupDrawListSharedData()
    ImGui.UpdateFontsNewFrame()

    for _, viewport in g.Viewports:iter() do
        viewport.DrawDataP.Valid = false
    end

    g.HoveredID = 0
    g.HoveredWindow = nil

    if (g.ActiveID ~= 0 and g.ActiveIDIsAlive ~= g.ActiveID and g.ActiveIDPreviousFrame == g.ActiveID) then
        print("NewFrame(): ClearActiveID() because it isn't marked alive anymore!")

        ImGui.ClearActiveID()
    end

    g.ActiveIDPreviousFrame = g.ActiveID
    g.ActiveIDIsAlive = 0
    g.ActiveIDIsJustActivated = false

    ImGui.UpdateMouseInputs()

    for _, window in g.Windows:iter() do
        window.WasActive = window.Active
        window.Active = false
    end

    ImGui.UpdateHoveredWindowAndCaptureFlags()

    ImGui.UpdateMouseMovingWindowNewFrame()

    g.MouseCursor = "arrow"

    g.CurrentWindowStack:resize(0)
end

function ImGui.EndFrame()
    local g = GImGui

    if g.FrameCountEnded == g.FrameCount then return end

    g.FrameCountEnded = g.FrameCount
    ImGui.UpdateFontsEndFrame()

    ImGui.UpdateMouseMovingWindowEndFrame()
end

function ImGui.Render()
    local g = GImGui
    IM_ASSERT(g.Initialized)

    if g.FrameCountEnded ~= g.FrameCount then
        EndFrame()
    end
    if g.FrameCountRendered == g.FrameCount then return end
    g.FrameCountRendered = g.FrameCount

    g.IO.MetricsRenderWindows = 0

    for _, viewport in g.Viewports:iter() do
        InitViewportDrawData(viewport)
        if viewport.BgFgDrawLists[1] ~= nil then
            ImGui.AddDrawListToDrawDataEx(viewport.DrawDataP, viewport.DrawDataBuilder.Layers[1], GetBackgroundDrawList(viewport))
        end
    end

    -- RenderDimmedBackgrounds()

    for _, window in g.Windows:iter() do
        if IsWindowActiveAndVisible(window) then
            AddRootWindowToDrawData(window)
        end
    end

    g.IO.MetricsRenderVertices = 0
    g.IO.MetricsRenderIndices = 0
    for _, viewport in g.Viewports:iter() do
        FlattenDrawDataIntoSingleLayer(viewport.DrawDataBuilder)

        if viewport.BgFgDrawLists[2] ~= nil then
            ImGui.AddDrawListToDrawDataEx(viewport.DrawDataP, viewport.DrawDataBuilder.Layers[1], GetForegroundDrawList(viewport))
        end

        local draw_data = viewport.DrawDataP
        -- IM_ASSERT(draw_data.CmdLists.Size == draw_data.CmdListsCount)
        for _, draw_list in draw_data.CmdLists:iter() do
            draw_list:_PopUnusedDrawCmd()
        end

        g.IO.MetricsRenderVertices = g.IO.MetricsRenderVertices + draw_data.TotalVtxCount
        g.IO.MetricsRenderIndices = g.IO.MetricsRenderIndices + draw_data.TotalIdxCount
    end
end

function ImGui.GetDrawData()
    local g = GImGui
    local viewport = g.Viewports:at(1)
    return viewport.DrawDataP.Valid and viewport.DrawDataP or nil
end

--- void ImGui::Shutdown()

--- Exposure
--
function ImGui.GetIO() return GImGui.IO end

function ImGui.GetStyle()
    IM_ASSERT(GImGui ~= nil, "No current context. Did you call ImGui::CreateContext() and ImGui::SetCurrentContext() ?")
    return GImGui.Style
end

function ImGui.GetMouseCursor()
    local g = GImGui
    return g.MouseCursor
end

function ImGui.SetMouseCursor(cursor_type)
    local g = GImGui
    g.MouseCursor = cursor_type
end

--- static void ScaleWindow(ImGuiWindow* window, float scale)
local function ScaleWindow(window, scale)
    local origin = window.Viewport.Pos
    window.Pos.x = ImFloor((window.Pos.x - origin.x) * scale + origin.x) -- TODO: those for vecs
    window.Pos.y = ImFloor((window.Pos.y - origin.y) * scale + origin.y)
    window.Size.x = ImTrunc(window.Size.x * scale)
    window.Size.y = ImTrunc(window.Size.y * scale)
    window.SizeFull.x = ImTrunc(window.SizeFull.x * scale)
    window.SizeFull.y = ImTrunc(window.SizeFull.y * scale)
    window.ContentSize.x = ImTrunc(window.ContentSize.x * scale)
    window.ContentSize.y = ImTrunc(window.ContentSize.y * scale)
end

--- void ImGui::ScaleWindowsInViewport(ImGuiViewportP* viewport, float scale)
local function ScaleWindowsInViewport(viewport, scale)
    local g = GImGui

    for _, window in g.Windows:iter() do
        if window.Viewport == viewport then
            ScaleWindow(window, scale)
        end
    end
end