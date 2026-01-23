--- ImGui for Garry's Mod written in pure Lua
--

--- @type ImGuiContext?
local GImGui = nil

ImGui = ImGui or {}

local FONT_DEFAULT_SIZE_BASE = 20

IMGUI_VIEWPORT_DEFAULT_ID = 0x11111111

local math = math
local bit  = bit

----------------------------------------------------------------
-- [SECTION] MISC HELPERS/UTILITIES (File functions)
----------------------------------------------------------------

local FILE = {
    close     = FindMetaTable("File").Close,
    size      = FindMetaTable("File").Size,
    write     = FindMetaTable("File").Write,
    read_byte = FindMetaTable("File").ReadByte
}

function ImFileOpen(filename, mode) return file.Open(filename, mode, "GAME") end
function ImFileClose(f) FILE.close(f) end
function ImFileGetSize(f) return FILE.size(f) end
function ImFileRead(f, data, count)
    for i = 1, count do
        data[i] = FILE.read_byte(f)
    end
end

--- @param filename string
--- @param mode string
--- @return ImSlice?, integer?
function ImFileLoadToMemory(filename, mode)
    local f = ImFileOpen(filename, mode)
    if not f then return end

    local file_size = ImFileGetSize(f)
    if file_size <= 0 then
        ImFileClose(f)
        return
    end

    local file_data = IM_SLICE() -- XXX: ptr-like op support
    ImFileRead(f, file_data.data, file_size)
    if #file_data.data == 0 then
        ImFileClose(f)
        return
    end

    ImFileClose(f)

    return file_data, file_size
end

local MT = include"imgui_h.lua"

#IMGUI_INCLUDE "imgui_internal.lua"

local ImResizeGripDef = {
    {CornerPos = ImVec2(1, 1), InnerDir = ImVec2(-1, -1), AngleMin12 = 0, AngleMax12 = 3}, -- Bottom right grip
    {CornerPos = ImVec2(0, 1), InnerDir = ImVec2( 1, -1), AngleMin12 = 3, AngleMax12 = 6} -- Bottom left
}

--- @param data table
--- @param seed int?
--- @return int
function ImHashData(data, seed)
    seed = seed or 0

    local FNV_OFFSET_BASIS = 0x811C9DC5
    local FNV_PRIME = 0x01000193

    local hash = bit.bxor(FNV_OFFSET_BASIS, seed)

    local _data
    for i = 1, #data do
        _data = data[i]
        hash = bit.bxor(hash, _data)
        hash = bit.band(hash * FNV_PRIME, 0xFFFFFFFF)
    end

    assert(hash ~= 0, "ImHashData = 0!")

    return hash
end

-- Use FNV1a, as one ImGui FIXME suggested
--- @param str string
--- @param seed int?
--- @return int
function ImHashStr(str, seed)
    seed = seed or 0

    local FNV_OFFSET_BASIS = 0x811C9DC5
    local FNV_PRIME = 0x01000193

    local hash = bit.bxor(FNV_OFFSET_BASIS, seed)

    local byte
    for i = 1, #str do
        byte = string.byte(str, i)
        hash = bit.bxor(hash, byte)
        hash = bit.band(hash * FNV_PRIME, 0xFFFFFFFF)
    end

    assert(hash ~= 0, "ImHashStr = 0!")

    return hash
end

--- @param in_text     string
--- @param pos         int
--- @param in_text_end int
--- @return int, int
function ImTextCharFromUtf8(in_text, pos, in_text_end)
    local lengths = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 3, 3, 4, 0}
    local masks   = {0x00, 0x7f, 0x1f, 0x0f, 0x07}
    local mins    = {0x400000, 0, 0x80, 0x800, 0x10000}
    local shiftc  = {0, 18, 12, 6, 0}
    local shifte  = {0, 6, 4, 2, 0}

    local len = lengths[bit.rshift(string.byte(in_text, pos), 3) + 1]
    local wanted = len > 0 and len or 1

    if in_text_end == nil then
        in_text_end = pos + wanted
    end

    local s = {0, 0, 0, 0}
    s[1] = (pos     < in_text_end) and string.byte(in_text, pos)     or 0
    s[2] = (pos + 1 < in_text_end) and string.byte(in_text, pos + 1) or 0
    s[3] = (pos + 2 < in_text_end) and string.byte(in_text, pos + 2) or 0
    s[4] = (pos + 3 < in_text_end) and string.byte(in_text, pos + 3) or 0

    local out_char
    out_char = bit.lshift(bit.band(s[1], masks[len + 1]), 18)
    out_char = bit.bor(out_char, bit.lshift(bit.band(s[2], 0x3f), 12))
    out_char = bit.bor(out_char, bit.lshift(bit.band(s[3], 0x3f),  6))
    out_char = bit.bor(out_char, bit.lshift(bit.band(s[4], 0x3f),  0))
    out_char = bit.rshift(out_char, shiftc[len + 1])

    local e = 0
    e = bit.lshift((out_char < mins[len + 1]) and 1 or 0, 6)
    e = bit.bor(e, bit.lshift((bit.rshift(out_char, 11) == 0x1b) and 1 or 0, 7))
    e = bit.bor(e, bit.lshift((out_char > IM_UNICODE_CODEPOINT_MAX) and 1 or 0, 8))
    e = bit.bor(e, bit.rshift(bit.band(s[2], 0xc0), 2))
    e = bit.bor(e, bit.rshift(bit.band(s[3], 0xc0), 4))
    e = bit.bor(e, bit.rshift(s[4]                , 6))
    e = bit.bxor(e, 0x2a)
    e = bit.rshift(e, shifte[len + 1])

    if e ~= 0 then
        wanted = ImMin(wanted, (s[1] ~= 0 and 1 or 0) + (s[2] ~= 0 and 1 or 0) + (s[3] ~= 0 and 1 or 0) + (s[4] ~= 0 and 1 or 0))
        out_char = IM_UNICODE_CODEPOINT_INVALID
    end

    return wanted, out_char
end

--- @param in_text     string
--- @param pos         int
--- @param in_text_end int
--- @return int
function ImTextCountUtf8BytesFromChar(in_text, pos, in_text_end)
    local bytes, unused = ImTextCharFromUtf8(in_text, pos, in_text_end)
    return bytes
end

#IMGUI_INCLUDE "imgui_draw.lua"

--- void ImGui::UpdateCurrentFontSize
function ImGui.UpdateCurrentFontSize(restore_font_size_after_scaling)
    local g = GImGui
    local window = g.CurrentWindow

    g.Style.FontSizeBase = g.FontSizeBase

    -- if (window ~= nil and window.SkipItems) then
    --     local table = g.CurrentTable
    --     if (table == nil or (table.CurrentColumn ~= -1 and table.Columns[table.CurrentColumn].IsSkipItems == false)) then
    --         return
    --     end
    -- end

    local final_size = (restore_font_size_after_scaling > 0.0) and restore_font_size_after_scaling or 0.0
    if final_size == 0.0 then
        final_size = g.FontSizeBase

        final_size = final_size * g.Style.FontScaleMain
        final_size = final_size * g.Style.FontScaleDpi
        if window ~= nil then
            final_size = final_size * window.FontWindowScale
        end
    end

    final_size = ImGui.GetRoundedFontSize(final_size)
    final_size = ImClamp(final_size, 4.0, IMGUI_FONT_SIZE_MAX)
    if (g.Font ~= nil and bit.band(g.IO.BackendFlags, ImGuiBackendFlags.RendererHasTextures) ~= 0) then
        g.Font.CurrentRasterizerDensity = g.FontRasterizerDensity
    end
    g.FontSize = final_size
    g.FontBaked = (g.Font ~= nil and window ~= nil) and g.Font:GetFontBaked(final_size) or nil
    g.FontBakedScale = (g.Font ~= nil and window ~= nil) and (g.FontSize / g.FontBaked.Size) or 0.0
    g.DrawListSharedData.FontSize = g.FontSize
    g.DrawListSharedData.FontScale = g.FontBakedScale
end

--- void ImGui::SetCurrentFont
function ImGui.SetCurrentFont(font, font_size_before_scaling, font_size_after_scaling)
    local g = GImGui

    g.Font = font
    g.FontSizeBase = font_size_before_scaling
    ImGui.UpdateCurrentFontSize(font_size_after_scaling)

    if font ~= nil then
        IM_ASSERT(font and font:IsLoaded())
        local atlas = font.OwnerAtlas
        g.DrawListSharedData.FontAtlas = atlas
        g.DrawListSharedData.Font = font
        ImFontAtlasUpdateDrawListsSharedData(atlas)
        if (g.CurrentWindow ~= nil) then
            g.CurrentWindow.DrawList:_SetTexture(atlas.TexRef)
        end
    end
end

function ImGui.PushFont(font, font_size_base)
    local g = GImGui

    if font == nil then
        font = g.Font
    end

    IM_ASSERT(font ~= nil)
    IM_ASSERT(font_size_base >= 0.0)

    g.FontStack:push_back({
        Font = font,
        FontSizeBeforeScaling = g.FontSizeBase,
        FontSizeAfterScaling = g.FontSize
    }) -- TODO: ImFontStackData

    if font_size_base == 0.0 then
        font_size_base = g.FontSizeBase
    end

    ImGui.SetCurrentFont(font, font_size_base, 0.0)
end

function ImGui.PopFont()
    local g = GImGui

    if (g.FontStack.Size <= 0) then
        IM_ASSERT_USER_ERROR(0, "Calling PopFont() too many times!")

        return
    end

    local font_stack_data = g.FontStack:back()
    ImGui.SetCurrentFont(font_stack_data.Font, font_stack_data.FontSizeBeforeScaling, font_stack_data.FontSizeAfterScaling)

    g.FontStack:pop_back()
end

function ImGui.UpdateTexturesNewFrame()
    local g = GImGui
    local has_textures = bit.band(g.IO.BackendFlags, ImGuiBackendFlags.RendererHasTextures) ~= 0
    for _, atlas in g.FontAtlases:iter() do
        if (atlas.OwnerContext == g) then
            ImFontAtlasUpdateNewFrame(atlas, g.FrameCount, has_textures)
        else
            IM_ASSERT(atlas.Builder ~= nil and atlas.Builder.FrameCount ~= -1)
            IM_ASSERT(atlas.RendererHasTextures == has_textures)
        end
    end
end

function ImGui.UpdateTexturesEndFrame()
    local g = GImGui
    g.PlatformIO.Textures:resize(0)
    for _, atlas in g.FontAtlases:iter() do
        for _, tex in atlas.TexList:iter() do
            tex.RefCount = atlas.RefCount
            g.PlatformIO.Textures:push_back(tex)
        end
    end
    for _, tex in g.UserTextures:iter() do
        g.PlatformIO.Textures:push_back(tex)
    end
end

function ImGui.UpdateFontsNewFrame()
    local g = GImGui
    if (bit.band(g.IO.BackendFlags, ImGuiBackendFlags.RendererHasTextures) == 0) then
        for _, atlas in g.FontAtlases:iter() do
            atlas.Locked = true
        end
    end

    if (g.Style._NextFrameFontSizeBase ~= 0.0) then
        g.Style.FontSizeBase = g.Style._NextFrameFontSizeBase
        g.Style._NextFrameFontSizeBase = 0.0
    end

    local font = ImGui.GetDefaultFont()
    if g.Style.FontSizeBase <= 0.0 then
        g.Style.FontSizeBase = ((font.LegacySize > 0.0) and font.LegacySize or FONT_DEFAULT_SIZE_BASE)
    end

    g.Font = font
    g.FontSizeBase = g.Style.FontSizeBase
    g.FontSize = 0.0
    local font_stack_data = ImFontStackData(font, g.Style.FontSizeBase, g.Style.FontSizeBase)
    ImGui.SetCurrentFont(font_stack_data.Font, font_stack_data.FontSizeBeforeScaling, 0.0)
    g.FontStack:push_back(font_stack_data)
    IM_ASSERT(g.Font:IsLoaded())
end

--- void ImGui::UpdateFontsEndFrame
function ImGui.UpdateFontsEndFrame()
    ImGui.PopFont()
end

--- @return ImFont
function ImGui.GetDefaultFont()
    local g = GImGui
    local atlas = g.IO.Fonts
    if (atlas.Builder == nil or atlas.Fonts.Size == 0) then
        ImFontAtlasBuildMain(atlas)
    end
    return g.IO.FontDefault and g.IO.FontDefault or atlas.Fonts:at(1)
end

--- @param atlas ImFontAtlas
function ImGui.RegisterFontAtlas(atlas)
    local g = GImGui
    if (g.FontAtlases.Size == 0) then
        IM_ASSERT(atlas == g.IO.Fonts)
    end
    atlas.RefCount = atlas.RefCount + 1
    g.FontAtlases:push_back(atlas)
    ImFontAtlasAddDrawListSharedData(atlas, g.DrawListSharedData)
    for _, tex in atlas.TexList:iter() do
        tex.RefCount = atlas.RefCount
    end
end

function ImGui.GetCurrentContext()
    return GImGui
end

--- @param ctx ImGuiContext?
function ImGui.SetCurrentContext(ctx)
    GImGui = ctx
end

--- void ImGui::Initialize()
function ImGui.Initialize()
    local g = GImGui
    IM_ASSERT(not g.Initialized and not g.SettingsLoaded)

    local viewport = ImGuiViewportP()
    viewport.ID = IMGUI_VIEWPORT_DEFAULT_ID
    g.Viewports:push_back(viewport)

    local atlas = g.IO.Fonts
    g.DrawListSharedData.Context = g
    ImGui.RegisterFontAtlas(atlas)

    g.Initialized = true
end

--- @param shared_font_atlas? ImFontAtlas
function ImGui.CreateContext(shared_font_atlas)
    GImGui = ImGuiContext(shared_font_atlas)

    for i = 0, 59 do GImGui.FramerateSecPerFrame[i] = 0 end

    ImGui.Initialize()

    return GImGui
end

--- void ImGui::DestroyContext
-- local function DestroyContext()

-- end

--- @param window ImGuiWindow
--- @return any
function ImGui.FindWindowSettingsByWindow(window)
    local g = GImGui
    if window.SettingsOffset ~= -1 then
        return g.SettingsWindows:ptr_from_offset(window.SettingsOffset)
    end
    return ImGui.FindWindowSettingsByID(window.ID)
end

--- @param id ImGuiID
--- @return any
function ImGui.FindWindowSettingsByID(id)
    local g = GImGui
    for _, settings in g.SettingsWindows:iter() do
        if settings.ID == id and not settings.WantDelete then
            return settings
        end
    end
    return nil
end

--- @param window ImGuiWindow
--- @param cond ImGuiCond
--- @param allow bool
local function SetWindowConditionAllowFlags(window, cond, allow)
    if allow then
        window.SetWindowPosAllowFlags = bit.bor(window.SetWindowPosAllowFlags, cond)
        window.SetWindowSizeAllowFlags = bit.bor(window.SetWindowSizeAllowFlags, cond)
        window.SetWindowCollapsedAllowFlags = bit.bor(window.SetWindowCollapsedAllowFlags, cond)
    else
        window.SetWindowPosAllowFlags = bit.band(window.SetWindowPosAllowFlags, bit.bnot(cond))
        window.SetWindowSizeAllowFlags = bit.band(window.SetWindowSizeAllowFlags, bit.bnot(cond))
        window.SetWindowCollapsedAllowFlags = bit.band(window.SetWindowCollapsedAllowFlags, bit.bnot(cond))
    end
end

--- @param window ImGuiWindow
--- @param settings ImGuiWindowSettings
local function ApplyWindowSettings(window, settings)
    window.Pos = ImVec2(ImTrunc(settings.Pos.x), ImTrunc(settings.Pos.y))
    if settings.Size.x > 0 and settings.Size.y > 0 then
        local size = ImVec2(ImTrunc(settings.Size.x), ImTrunc(settings.Size.y))
        window.Size = size
        window.SizeFull = size
    end
    window.Collapsed = settings.Collapsed
end

--- @param window ImGuiWindow
--- @param settings ImGuiWindowSettings
local function InitOrLoadWindowSettings(window, settings)
    -- Initial window state with e.g. default/arbitrary window position
    -- Use SetNextWindowPos() with the appropriate condition flag to change the initial position of a window.
    local main_viewport = ImGui.GetMainViewport()
    window.Pos = ImVec2(main_viewport.Pos.x + 60, main_viewport.Pos.y + 60)
    window.SizeFull = ImVec2(0, 0)
    window.Size = window.SizeFull
    window.SetWindowPosAllowFlags = bit.bor(ImGuiCond_Always, ImGuiCond_Once, ImGuiCond_FirstUseEver, ImGuiCond_Appearing)
    window.SetWindowSizeAllowFlags = window.SetWindowPosAllowFlags
    window.SetWindowCollapsedAllowFlags = window.SetWindowPosAllowFlags

    if settings ~= nil then
        SetWindowConditionAllowFlags(window, ImGuiCond_FirstUseEver, false)
        ApplyWindowSettings(window, settings)
    end
    window.DC.CursorStartPos = ImVec2(window.Pos.x, window.Pos.y) -- So first call to CalcWindowContentSizes() doesn't return crazy values
    window.DC.CursorMaxPos = window.DC.CursorStartPos
    window.DC.IdealMaxPos = window.DC.CursorStartPos

    if bit.band(window.Flags, ImGuiWindowFlags_AlwaysAutoResize) ~= 0 then
        window.AutoFitFramesX = 2
        window.AutoFitFramesY = 2
        window.AutoFitOnlyGrows = false
    else
        if window.Size.x <= 0.0 then
            window.AutoFitFramesX = 2
        end
        if window.Size.y <= 0.0 then
            window.AutoFitFramesY = 2
        end
        window.AutoFitOnlyGrows = (window.AutoFitFramesX > 0) or (window.AutoFitFramesY > 0)
    end
end

--- @param name string
--- @param flags ImGuiWindowFlags
--- @return ImGuiWindow
local function CreateNewWindow(name, flags)
    local g = GImGui

    local window_id = ImHashStr(name)

    local window = ImGuiWindow(g, name)

    window.ID = window_id
    window.Flags = flags

    g.WindowsById[window_id] = window

    local settings = nil
    if bit.band(window.Flags, ImGuiWindowFlags_NoSavedSettings) == 0 then
        settings = ImGui.FindWindowSettingsByWindow(window)
        if settings ~= nil then
            window.SettingsOffset = g.SettingsWindows:index_from_ptr(settings)
        end
    end

    InitOrLoadWindowSettings(window, settings)

    g.Windows:push_back(window)

    return window
end

--- void ImGui::KeepAliveID(ImGuiID id)
function ImGui.KeepAliveID(id)
    local g = GImGui

    if g.ActiveId == id then
        g.ActiveIdIsAlive = id
    end

    if g.DeactivatedItemData.ID == id then
        g.DeactivatedItemData.IsAlive = true
    end
end

local function IsMouseHoveringRect(r_min, r_max)
    local rect_clipped = ImRect(r_min, r_max)

    return rect_clipped:contains_point(GImGui.IO.MousePos)
end

function ImGui.ItemAdd(bb, id, nav_bb_arg, extra_flags)
    if extra_flags == nil then extra_flags = 0 end

    local g = GImGui
    local window = g.CurrentWindow

    g.LastItemData.ID = id
    g.LastItemData.Rect = bb
    g.LastItemData.NavRect = nav_bb_arg and nav_bb_arg or bb
    g.LastItemData.ItemFlags = bit.bor(g.CurrentItemFlags, g.NextItemData.ItemFlags, extra_flags)
    g.LastItemData.StatusFlags = ImGuiItemStatusFlags_None

    if id ~= 0 then
        ImGui.KeepAliveID(id)

        -- if bit.band(g.LastItemData.ItemFlags, ImGuiItemFlags_NoNav) == 0 then
        --     window.DC.NavLayersActiveMaskNext = bit.bor(window.DC.NavLayersActiveMaskNext, bit.lshift(1, window.DC.NavLayerCurrent))

        --     if g.NavId == id or g.NavAnyRequest then
        --         if g.NavWindow.RootWindowForNav == window.RootWindowForNav then
        --             if window == g.NavWindow or bit.band(bit.bor(window.ChildFlags, g.NavWindow.ChildFlags), ImGuiChildFlags.NavFlattened) ~= 0 then
        --                 TODO: NavProcessItem()
        --             end
        --         end
        --     end
        -- end

        -- if bit.band(g.NextItemData.HasFlags, ImGuiNextItemDataFlags.HasShortcut) ~= 0 then
        --     TODO: ItemHandleShortcut(id)
        -- end
    end

    g.NextItemData.HasFlags = ImGuiNextItemDataFlags_None
    g.NextItemData.ItemFlags = ImGuiItemFlags_None

    local is_rect_visible = bb:Overlaps(window.ClipRect)
    if not is_rect_visible then
        if id == 0 or not (id == g.ActiveId or id == g.ActiveIdPreviousFrame or id == g.NavId or id == g.NavActivateId or g.ItemUnclipByLog) then
            return false
        end
    end

    if id ~= 0 and g.DeactivatedItemData.ID == id then
        g.DeactivatedItemData.ElapseFrame = g.FrameCount
    end

    if is_rect_visible then
        g.LastItemData.StatusFlags = bit.bor(g.LastItemData.StatusFlags, ImGuiItemStatusFlags_Visible)
    end

    if IsMouseHoveringRect(bb.Min, bb.Max) then
        g.LastItemData.StatusFlags = bit.bor(g.LastItemData.StatusFlags, ImGuiItemStatusFlags_HoveredRect)
    end

    return true
end

function ImGui.ItemSize(size, text_baseline_y)
    if text_baseline_y == nil then text_baseline_y = -1.0 end

    local g = GImGui
    local window = g.CurrentWindow

    if window.SkipItems then
        return
    end

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
    window.DC.CursorPos.x = IM_TRUNC(window.Pos.x + window.DC.Indent.x + window.DC.ColumnsOffset.x)
    window.DC.CursorPos.y = IM_TRUNC(line_y1 + line_height + g.Style.ItemSpacing.y)
    window.DC.CursorMaxPos.x = ImMax(window.DC.CursorMaxPos.x, window.DC.CursorPosPrevLine.x)
    window.DC.CursorMaxPos.y = ImMax(window.DC.CursorMaxPos.y, window.DC.CursorPos.y - g.Style.ItemSpacing.y)

    window.DC.PrevLineSize.y = line_height
    window.DC.CurrLineSize.y = 0
    window.DC.PrevLineTextBaseOffset = ImMax(window.DC.CurrLineTextBaseOffset, text_baseline_y)
    window.DC.CurrLineTextBaseOffset = 0
    window.DC.IsSetPos = false
    window.DC.IsSameLine = false

    --- Horizontal layout mode
    if (window.DC.LayoutType == ImGuiLayoutType_Horizontal) then
        ImGui.SameLine()
    end
end

--- @param offset_from_start_x float?
--- @param spacing_w           float?
function ImGui.SameLine(offset_from_start_x, spacing_w)
    if offset_from_start_x == nil then offset_from_start_x =  0.0 end
    if spacing_w           == nil then spacing_w           = -1.0 end

    local g = GImGui
    local window = g.CurrentWindow

    if window.SkipItems then
        return
    end

    if offset_from_start_x ~= 0.0 then
        if spacing_w < 0.0 then spacing_w = 0.0 end
        window.DC.CursorPos.x = window.Pos.x - window.Scroll.x + offset_from_start_x + spacing_w + window.DC.GroupOffset.x + window.DC.ColumnsOffset.x
        window.DC.CursorPos.y = window.DC.CursorPosPrevLine.y
    else
        if spacing_w < 0.0 then spacing_w = g.Style.ItemSpacing.x end
        window.DC.CursorPos.x = window.DC.CursorPosPrevLine.x + spacing_w
        window.DC.CursorPos.y = window.DC.CursorPosPrevLine.y
    end
    window.DC.CurrLineSize = window.DC.PrevLineSize
    window.DC.CurrLineTextBaseOffset = window.DC.PrevLineTextBaseOffset
    window.DC.IsSameLine = true
end

function ImGui.GetTextLineHeight()
    local g = GImGui
    return g.FontSize
end

--- bool ImGui::IsItemActive()
local function IsItemActive()
    local g = GImGui

    if g.ActiveId ~= 0 then
        return g.ActiveId == g.LastItemData.ID
    end

    return false
end

--- void ImGuiStyle::ScaleAllSizes
-- local function ScaleAllSizes(scale_factor)

-- end

--- void ImGui::BringWindowToDisplayFront(ImGuiWindow* window)
function ImGui.BringWindowToDisplayFront(window)
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
function ImGui.FocusWindow(window, flags) -- TODO:
    local g = GImGui

    if g.NavWindow ~= window then
        SetNavWindow(window)
    end

    if not window then return end

    ImGui.BringWindowToDisplayFront(window)
end

--- void ImGui::SetFocusID

--- void ImGui::StopMouseMovingWindow()
local function StopMouseMovingWindow()
    GImGui.MovingWindow = nil
end

--- void ImGui::SetActiveID
function ImGui.SetActiveID(id, window)
    local g = GImGui

    if g.ActiveId ~= 0 then
        g.DeactivatedItemData.ID = g.ActiveId
        -- g.DeactivatedItemData.ElapseFrame =
        -- g.DeactivatedItemData.HasBeenEditedBefore =
        g.DeactivatedItemData.IsAlive = (g.ActiveIdIsAlive == g.ActiveId)

        if g.MovingWindow and (g.ActiveId == g.MovingWindow.MoveID) then
            print("SetActiveID() cancel MovingWindow")
            StopMouseMovingWindow()
        end
    end

    g.ActiveIdIsJustActivated = (g.ActiveId ~= id)

    g.ActiveId = id
    g.ActiveIDWindow = window

    if id ~= 0 then
        g.ActiveIdIsAlive = id
    end
end

function ImGui.ClearActiveID()
    ImGui.SetActiveID(0, nil)
end

--- @param str_id string
function ImGui.PushID(str_id)
    local g = GImGui
    local window = g.CurrentWindow
    local id = window:GetID(str_id)
    window.IDStack:push_back(id)
end

function ImGui.PopID()
    local window = GImGui.CurrentWindow
    IM_ASSERT_USER_ERROR_RET(window.IDStack.Size > 1, "Calling PopID() too many times!")
    window.IDStack:pop_back()
end

--- @param str string
--- @return ImGuiID
function MT.ImGuiWindow:GetID(str)
    local seed = self.IDStack:back()
    local id = ImHashStr(str, seed)

    return id
end

--- @param id ImGuiID
function ImGui.SetHoveredID(id)
    local g = GImGui

    g.HoveredId = id
end

--- @param user_flags   ImGuiHoveredFlags
--- @param shared_flags ImGuiHoveredFlags
local function ApplyHoverFlagsForTooltip(user_flags, shared_flags)
    if bit.band(user_flags, bit.bor(ImGuiHoveredFlags_DelayNone, ImGuiHoveredFlags_DelayShort, ImGuiHoveredFlags_DelayNormal)) ~= 0 then
        shared_flags = bit.band(shared_flags, bit.bnot(bit.bor(ImGuiHoveredFlags_DelayNone, ImGuiHoveredFlags_DelayShort, ImGuiHoveredFlags_DelayNormal)))
    end
    return bit.bor(user_flags, shared_flags)
end

--- @param flags ImGuiHoveredFlags
function ImGui.IsItemHovered(flags)
    if flags == nil then flags = 0 end

    local g = GImGui
    local window = g.CurrentWindow
    IM_ASSERT_USER_ERROR(bit.band(flags, bit.bnot(ImGuiHoveredFlags_AllowedMaskForIsItemHovered)) == 0, "Invalid flags for IsItemHovered()!")

    if g.NavHighlightItemUnderNav and g.NavCursorVisible and bit.band(flags, ImGuiHoveredFlags_NoNavOverride) == 0 then
        if not ImGui.IsItemFocused() then
            return false
        end
        if bit.band(g.LastItemData.ItemFlags, ImGuiItemFlags_Disabled) ~= 0 and bit.band(flags, ImGuiHoveredFlags_AllowWhenDisabled) == 0 then
            return false
        end

        if bit.band(flags, ImGuiHoveredFlags_ForTooltip) ~= 0 then
            flags = ApplyHoverFlagsForTooltip(flags, g.Style.HoverFlagsForTooltipNav)
        end
    else
        local status_flags = g.LastItemData.StatusFlags
        if bit.band(status_flags, ImGuiItemStatusFlags_HoveredRect) == 0 then
            return false
        end

        if bit.band(flags, ImGuiHoveredFlags_ForTooltip) ~= 0 then
            flags = ApplyHoverFlagsForTooltip(flags, g.Style.HoverFlagsForTooltipMouse)
        end

        if g.HoveredWindow ~= window and bit.band(status_flags, ImGuiItemStatusFlags_HoveredWindow) == 0 then
            if bit.band(flags, ImGuiHoveredFlags_AllowWhenOverlappedByWindow) == 0 then
                return false
            end
        end

        local id = g.LastItemData.ID
        if bit.band(flags, ImGuiHoveredFlags_AllowWhenBlockedByActiveItem) == 0 then
            if g.ActiveId ~= 0 and g.ActiveId ~= id and not g.ActiveIdAllowOverlap and not g.ActiveIdFromShortcut then
                local cancel_is_hovered = true
                if g.ActiveId == window.MoveId and (id == 0 or g.ActiveIdDisabledId == id) then
                    cancel_is_hovered = false
                end
                if cancel_is_hovered then
                    return false
                end
            end
        end

        if not ImGui.IsWindowContentHoverable(window, flags) and bit.band(g.LastItemData.ItemFlags, ImGuiItemFlags_NoWindowHoverableCheck) == 0 then
            return false
        end

        if bit.band(g.LastItemData.ItemFlags, ImGuiItemFlags_Disabled) ~= 0 and bit.band(flags, ImGuiHoveredFlags_AllowWhenDisabled) == 0 then
            return false
        end

        if id == window.MoveId and window.WriteAccessed then
            return false
        end

        if bit.band(g.LastItemData.ItemFlags, ImGuiItemFlags_AllowOverlap) ~= 0 and id ~= 0 then
            if bit.band(flags, ImGuiHoveredFlags_AllowWhenOverlappedByItem) == 0 then
                if g.HoveredIdPreviousFrame ~= g.LastItemData.ID then
                    return false
                end
            end
        end
    end

    local delay = ImGui.CalcDelayFromHoveredFlags(flags)
    if delay > 0.0 or bit.band(flags, ImGuiHoveredFlags_Stationary) ~= 0 then
        local hover_delay_id
        if g.LastItemData.ID ~= 0 then
            hover_delay_id = g.LastItemData.ID
        else
            hover_delay_id = window:GetIDFromPos(g.LastItemData.Rect.Min)
        end
        if bit.band(flags, ImGuiHoveredFlags_NoSharedDelay) ~= 0 and g.HoverItemDelayIdPreviousFrame ~= hover_delay_id then
            g.HoverItemDelayTimer = 0.0
        end
        g.HoverItemDelayId = hover_delay_id

        if bit.band(flags, ImGuiHoveredFlags_Stationary) ~= 0 and g.HoverItemUnlockedStationaryId ~= hover_delay_id then
            return false
        end

        if g.HoverItemDelayTimer < delay then
            return false
        end
    end

    return true
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

    if g.HoveredId ~= 0 and g.HoveredId ~= id then
        return false
    end

    if id ~= 0 then
        ImGui.SetHoveredID(id)
    end

    return true
end

--- @param bb ImRect
--- @param id ImGuiID
--- @return bool
function ImGui.IsClippedEx(bb, id)
    local g = GImGui
    local window = g.CurrentWindow
    if not bb:Overlaps(window.ClipRect) then
        if id == 0 or (id ~= g.ActiveId and id ~= g.ActiveIdPreviousFrame and id ~= g.NavId and id ~= g.NavActivateId) then
            if not g.ItemUnclipByLog then
                return true
            end
        end
    end
    return false
end

function MT.ImGuiIO:ClearEventsQueue()
    IM_ASSERT(self.Ctx ~= nil)
    local g = GImGui
    g.InputEventsQueue:clear()
end

function MT.ImGuiIO:ClearInputKeys()
    local g = self.Ctx
    for key = ImGuiKey_NamedKey_BEGIN, ImGuiKey_NamedKey_END - 1 do
        if ImGui.IsMouseKey(key) then
            continue
        end

        local key_data = g.IO.KeysData[key - ImGuiKey_NamedKey_BEGIN]
        key_data.Down = false
        key_data.DownDuration = -1.0
        key_data.DownDurationPrev = -1.0
    end
    self.KeyCtrl  = false
    self.KeyShift = false
    self.KeyAlt   = false
    self.KeySuper = false
    self.KeyMods  = ImGuiMod_None
    self.InputQueueCharacters:resize(0)
end

function MT.ImGuiIO:ClearInputMouse()
    for key = ImGuiKey_Mouse_BEGIN, ImGuiKey_Mouse_END - 1 do
        local key_data = self.KeysData[key - ImGuiKey_NamedKey_BEGIN]
        if key_data then
            key_data.Down = false
            key_data.DownDuration = -1.0
            key_data.DownDurationPrev = -1.0
        end
    end

    self.MousePos = ImVec2(-FLT_MAX, -FLT_MAX)

    for n = 0, 2 do -- IM_COUNTOF(MouseDown)
        self.MouseDown[n] = false
        self.MouseDownDuration[n] = -1.0
        self.MouseDownDurationPrev[n] = -1.0
    end

    self.MouseWheel = 0
    self.MouseWheelH = 0
end

--- @param ctx  ImGuiContext
--- @param type ImGuiInputEventType
--- @param arg? int
--- @return ImGuiInputEvent?
function MT.ImGuiIO:FindLatestInputEvent(ctx, type, arg)
    if arg == nil then arg = -1 end

    local g = ctx
    for n = g.InputEventsQueue.Size, 1, -1 do
        local e = g.InputEventsQueue.Data[n]

        if e.Type ~= type then
            continue
        end
        if type == ImGuiInputEventType_Key and e.Key.Key ~= arg then
            continue
        end
        if type == ImGuiInputEventType_MouseButton and e.MouseButton.Button ~= arg then
            continue
        end

        return e
    end

    return nil
end

--- @param key          ImGuiKey
--- @param down         bool
--- @param analog_value float
function MT.ImGuiIO:AddKeyAnalogEvent(key, down, analog_value)
    IM_ASSERT(self.Ctx ~= nil)
    if key == ImGuiKey_None or not self.AppAcceptingEvents then
        return
    end

    local g = self.Ctx
    IM_ASSERT(ImGui.IsNamedKeyOrMod(key))
    IM_ASSERT(ImGui.IsAliasKey(key) == false)

    -- MacOS: swap Cmd(Super) and Ctrl
    if (g.IO.ConfigMacOSXBehaviors) then
        if (key == ImGuiMod_Super)          then key = ImGuiMod_Ctrl
        elseif (key == ImGuiMod_Ctrl)       then key = ImGuiMod_Super
        elseif (key == ImGuiKey_LeftSuper)  then key = ImGuiKey_LeftCtrl
        elseif (key == ImGuiKey_RightSuper) then key = ImGuiKey_RightCtrl
        elseif (key == ImGuiKey_LeftCtrl)   then key = ImGuiKey_LeftSuper
        elseif (key == ImGuiKey_RightCtrl)  then key = ImGuiKey_RightSuper
        end
    end

    local latest_event = self:FindLatestInputEvent(g, ImGuiInputEventType_Key, key)
    local key_data = ImGui.GetKeyData(g, key)
    local latest_key_down = latest_event and latest_event.Key.Down or key_data.Down
    local latest_key_analog = latest_event and latest_event.Key.AnalogValue or key_data.AnalogValue
    if latest_key_down == down and latest_key_analog == analog_value then
        return
    end

    local e = ImGuiInputEvent()
    e.Type = ImGuiInputEventType_Key
    e.Source = ImGui.IsGamepadKey(key) and ImGuiInputSource_Gamepad or ImGuiInputSource_Keyboard
    e.EventId = g.InputEventsNextEventId
    g.InputEventsNextEventId = g.InputEventsNextEventId + 1
    e.Key.Key = key
    e.Key.Down = down
    e.Key.AnalogValue = analog_value
    g.InputEventsQueue:push_back(e)
end

--- @param key  ImGuiKey
--- @param down bool
function MT.ImGuiIO:AddKeyEvent(key, down)
    if not self.AppAcceptingEvents then
        return
    end
    self:AddKeyAnalogEvent(key, down, (down and 1.0 or 0.0))
end

--- @param accepting_events bool
function MT.ImGuiIO:SetAppAcceptingEvents(accepting_events)
    self.AppAcceptingEvents = accepting_events
end

--- @param x float
--- @param y float
function MT.ImGuiIO:AddMousePosEvent(x, y)
    IM_ASSERT(self.Ctx ~= nil)
    if not self.AppAcceptingEvents then
        return
    end

    local g = self.Ctx

    local x_val = x
    if x > -FLT_MAX then
        x_val = ImFloor(x)
    end
    local y_val = y
    if y > -FLT_MAX then
        y_val = ImFloor(y)
    end

    local latest_event = self:FindLatestInputEvent(g, ImGuiInputEventType_MousePos)
    local latest_pos = latest_event and ImVec2(latest_event.MousePos.PosX, latest_event.MousePos.PosY) or self.MousePos
    if latest_pos.x == x_val and latest_pos.y == y_val then
        return
    end

    local e = ImGuiInputEvent()
    e.Type = ImGuiInputEventType_MousePos
    e.Source = ImGuiInputSource_Mouse
    e.EventId = g.InputEventsNextEventId
    g.InputEventsNextEventId = g.InputEventsNextEventId + 1
    e.MousePos = ImGuiInputEventMousePos()
    e.MousePos.PosX = x_val
    e.MousePos.PosY = y_val
    e.MousePos.MouseSource = g.InputEventsNextMouseSource
    g.InputEventsQueue:push_back(e)
end

--- @param mouse_button ImGuiMouseButton
--- @param down         bool
function MT.ImGuiIO:AddMouseButtonEvent(mouse_button, down)
    IM_ASSERT(self.Ctx ~= nil)
    local g = self.Ctx
    IM_ASSERT(mouse_button >= 0 and mouse_button < ImGuiMouseButton_COUNT)
    if not self.AppAcceptingEvents then
        return
    end

    -- On MacOS X: Convert Ctrl(Super)+Left click into Right-click: handle held button.
    if self.ConfigMacOSXBehaviors and mouse_button == 0 and g.IO.MouseCtrlLeftAsRightClick then
        -- Order of both statements matters: this event will still release mouse button 1
        mouse_button = 1
        if not down then
            self.MouseCtrlLeftAsRightClick = false
        end
    end

    local latest_event = self:FindLatestInputEvent(g, ImGuiInputEventType_MouseButton, mouse_button)
    local latest_button_down = latest_event and latest_event.MouseButton.Down or self.MouseDown[mouse_button]
    if latest_button_down == down then
        return
    end

    -- On MacOS X: Convert Ctrl(Super)+Left click into Right-click.
    -- - Note that this is actual physical Ctrl which is ImGuiMod_Super for us.
    -- - At this point we want from !down to down, so this is handling the initial press.
    if self.ConfigMacOSXBehaviors and mouse_button == 0 and down then
        local latest_super_event = self:FindLatestInputEvent(g, ImGuiInputEventType_Key, ImGuiMod_Super)
        if latest_super_event and latest_super_event.Key.Down or self.KeySuper then
            -- IMGUI_DEBUG_LOG_IO("[io] Super+Left Click aliased into Right Click\n")
            self.MouseCtrlLeftAsRightClick = true
            self:AddMouseButtonEvent(1, true) -- This is just quicker to write that passing through, as we need to filter duplicate again.
            return
        end
    end

    local e = ImGuiInputEvent()
    e.Type = ImGuiInputEventType_MouseButton
    e.Source = ImGuiInputSource_Mouse
    e.EventId = g.InputEventsNextEventId
    g.InputEventsNextEventId = g.InputEventsNextEventId + 1
    e.MouseButton = ImGuiInputEventMouseButton()
    e.MouseButton.Button = mouse_button
    e.MouseButton.Down = down
    e.MouseButton.MouseSource = g.InputEventsNextMouseSource
    g.InputEventsQueue:push_back(e)
end

--- @param wheel_x float
--- @param wheel_y float
function MT.ImGuiIO:AddMouseWheelEvent(wheel_x, wheel_y)
    IM_ASSERT(self.Ctx ~= nil)
    local g = self.Ctx
    if not self.AppAcceptingEvents or (wheel_x == 0 and wheel_y == 0) then
        return
    end

    local e = ImGuiInputEvent()
    e.Type = ImGuiInputEventType_MouseWheel
    e.Source = ImGuiInputSource_Mouse
    e.EventId = g.InputEventsNextEventId
    g.InputEventsNextEventId = g.InputEventsNextEventId + 1
    e.MouseWheel = ImGuiInputEventMouseWheel()
    e.MouseWheel.WheelX = wheel_x
    e.MouseWheel.WheelY = wheel_y
    e.MouseWheel.MouseSource = g.InputEventsNextMouseSource
    g.InputEventsQueue:push_back(e)
end

--- @param ctx ImGuiContext
--- @param key ImGuiKey
--- @return ImGuiKeyData
function ImGui.GetKeyData(ctx, key)
    if bit.band(key, ImGuiMod_Mask_) ~= 0 then
        key = ImGui.ConvertSingleModFlagToKey(key)
    end

    IM_ASSERT(ImGui.IsNamedKey(key), "Support for user key indices was dropped in favor of ImGuiKey. Please update backend & user code.")
    return g.IO.KeysData[key - ImGuiKey_NamedKey_BEGIN]
end

--- @param key      ImGuiKey
--- @param owner_id ImGuiID
function ImGui.TestKeyOwner(key, owner_id)
    if not ImGui.IsNamedKeyOrMod(key) then
        return true
    end

    local g = GImGui --- @cast g ImGuiContext
    if g.ActiveIdUsingAllKeyboardKeys and owner_id ~= g.ActiveId and owner_id ~= ImGuiKeyOwner_Any then
        if key >= ImGuiKey_Keyboard_BEGIN and key < ImGuiKey_Keyboard_END then
            return false
        end
    end

    local owner_data = ImGui.GetKeyOwnerData(g, key)
    if owner_id == ImGuiKeyOwner_Any then
        return not owner_data.LockThisFrame
    end

    if owner_data.OwnerCurr ~= owner_id then
        if owner_data.LockThisFrame then
            return false
        end
        if owner_data.OwnerCurr ~= ImGuiKeyOwner_NoOwner then
            return false
        end
    end

    return true
end

--- @param t0           float
--- @param t1           float
--- @param repeat_delay float
--- @param repeat_rate  float
function ImGui.CalcTypematicRepeatAmount(t0, t1, repeat_delay, repeat_rate)
    if t1 == 0.0 then return 1 end
    if t0 >= t1 then return 0 end
    if repeat_rate <= 0.0 then
        if t0 < repeat_delay and t1 >= repeat_delay then
            return 1
        else
            return 0
        end
    end

    local count_t0
    if t0 < repeat_delay then
        count_t0 = -1
    else
        count_t0 = math.floor((t0 - repeat_delay) / repeat_rate)
    end

    local count_t1
    if t1 < repeat_delay then
        count_t1 = -1
    else
        count_t1 = math.floor((t1 - repeat_delay) / repeat_rate)
    end

    return count_t1 - count_t0
end

--- bool ImGui::IsMouseDown
function ImGui.IsMouseDown(button, owner_id)
    if owner_id == nil then owner_id = ImGuiKeyOwner_Any end

    local g = GImGui
    IM_ASSERT(button >= 0 and button < 3) -- IM_COUNTOF(g.IO.MouseDown)
    return g.IO.MouseDown[button] and ImGui.TestKeyOwner(ImGui.MouseButtonToKey(button), owner_id)
end

--- @param button     ImGuiMouseButton
--- @param is_repeat? bool
--- @param flags?     ImGuiInputFlags
--- @param owner_id?  ImGuiID
function ImGui.IsMouseClicked(button, is_repeat, flags, owner_id)
    if is_repeat == true then flags = ImGuiInputFlags_Repeat else flags = ImGuiInputFlags_None end
    if owner_id  == nil  then owner_id = ImGuiKeyOwner_Any end

    local g = GImGui
    IM_ASSERT(button >= 0 and button < 3) -- IM_COUNTOF(g.IO.MouseDown)

    if not g.IO.MouseDown[button] then
        return false
    end
    local t = g.IO.MouseDownDuration[button]
    if t < 0.0 then
        return false
    end
    IM_ASSERT(bit.band(flags, bit.bnot(ImGuiInputFlags_SupportedByIsMouseClicked)) == 0)

    local repeat_flag = (bit.band(flags, ImGuiInputFlags_Repeat) ~= 0)
    local pressed = (t == 0.0) or (repeat_flag and t > g.IO.KeyRepeatDelay and ImGui.CalcTypematicRepeatAmount(t - g.IO.DeltaTime, t, g.IO.KeyRepeatDelay, g.IO.KeyRepeatRate) > 0)

    if not pressed then
        return false
    end

    if not ImGui.TestKeyOwner(ImGui.MouseButtonToKey(button), owner_id) then
        return false
    end

    return true
end

--- @param button   ImGuiMouseButton
--- @param owner_id ImGuiID
function ImGui.IsMouseReleased(button, owner_id)
    if owner_id == nil then owner_id = ImGuiKeyOwner_Any end

    local g = GImGui
    IM_ASSERT(button >= 0 and button < 3) -- IM_COUNTOF(g.IO.MouseDown)
    return g.IO.MouseReleased[button] and ImGui.TestKeyOwner(ImGui.MouseButtonToKey(button), owner_id)
end

#IMGUI_INCLUDE "imgui_widgets.lua"

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

--- @param window       ImGuiWindow  # The window to calculate size for
--- @param size_desired ImVec2       # The desired size before constraints
--- @return ImVec2                   # The size after applying constraints
local function CalcWindowSizeAfterConstraint(window, size_desired)
    local g = GImGui
    local new_size = ImVec2(size_desired.x, size_desired.y)
    if g.NextWindowData.HasFlags and bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasSizeConstraint) ~= 0 then
        local cr = g.NextWindowData.SizeConstraintRect
        new_size.x = (cr.Min.x >= 0 and cr.Max.x >= 0) and ImClamp(new_size.x, cr.Min.x, cr.Max.x) or window.SizeFull.x
        new_size.y = (cr.Min.y >= 0 and cr.Max.y >= 0) and ImClamp(new_size.y, cr.Min.y, cr.Max.y) or window.SizeFull.y
        if g.NextWindowData.SizeCallback then
            local data = {} -- TODO: ImGuiSizeCallbackData
            data.UserData = g.NextWindowData.SizeCallbackUserData
            data.Pos = ImVec2(window.Pos.x, window.Pos.y)
            data.CurrentSize = ImVec2(window.SizeFull.x, window.SizeFull.y)
            data.DesiredSize = ImVec2(new_size.x, new_size.y)
            g.NextWindowData.SizeCallback(data)
            new_size.x = data.DesiredSize.x
            new_size.y = data.DesiredSize.y
        end
        new_size.x = IM_TRUNC(new_size.x)
        new_size.y = IM_TRUNC(new_size.y)
    end

    local size_min = CalcWindowMinSize(window)
    return ImVec2(
        ImMax(new_size.x, size_min.x),
        ImMax(new_size.y, size_min.y)
    )
end

--- @param window        ImGuiWindow # The window to calculate auto-fit size for
--- @param size_contents ImVec2      # The content size
--- @param axis_mask     int         # The axis mask to determine which axes to auto-fit
--- @return ImVec2                   # The auto-fit size
local function CalcWindowAutoFitSize(window, size_contents, axis_mask)
    local g = GImGui
    local style = g.Style
    local decoration_w_without_scrollbars = window.DecoOuterSizeX1 + window.DecoOuterSizeX2 - window.ScrollbarSizes.x
    local decoration_h_without_scrollbars = window.DecoOuterSizeY1 + window.DecoOuterSizeY2 - window.ScrollbarSizes.y
    local size_pad = ImVec2(window.WindowPadding.x * 2, window.WindowPadding.y * 2)
    local size_desired = ImVec2()
    size_desired.x = (bit.band(axis_mask, 1) ~= 0) and (size_contents.x + size_pad.x + decoration_w_without_scrollbars) or window.Size.x
    size_desired.y = (bit.band(axis_mask, 2) ~= 0) and (size_contents.y + size_pad.y + decoration_h_without_scrollbars) or window.Size.y

    local size_max
    if (bit.band(window.Flags, ImGuiWindowFlags_ChildWindow) ~= 0) and (bit.band(window.Flags, ImGuiWindowFlags_Popup) == 0) then
        size_max = ImVec2(FLT_MAX, FLT_MAX)
    else
        local main_viewport = g.Viewports:at(1)
        size_max = ImVec2(main_viewport.WorkSize.x - style.DisplaySafeAreaPadding.x * 2, main_viewport.WorkSize.y - style.DisplaySafeAreaPadding.y * 2)
    end

    if bit.band(window.Flags, ImGuiWindowFlags_Tooltip) ~= 0 then
        return ImVec2(math.min(size_desired.x, size_max.x), math.min(size_desired.y, size_max.y))
    else
        local size_min = CalcWindowMinSize(window)
        local size_auto_fit = ImVec2(
            ImClamp(size_desired.x, math.min(size_min.x, size_max.x), size_max.x),
            ImClamp(size_desired.y, math.min(size_min.y, size_max.y), size_max.y)
        )

        local size_auto_fit_after_constraint = CalcWindowSizeAfterConstraint(window, size_auto_fit)
        local will_have_scrollbar_x = ((size_auto_fit_after_constraint.x - size_pad.x - decoration_w_without_scrollbars) < size_contents.x and (bit.band(window.Flags, ImGuiWindowFlags_NoScrollbar) == 0) and (bit.band(window.Flags, ImGuiWindowFlags_HorizontalScrollbar) ~= 0)) or (bit.band(window.Flags, ImGuiWindowFlags_AlwaysHorizontalScrollbar) ~= 0)
        local will_have_scrollbar_y = ((size_auto_fit_after_constraint.y - size_pad.y - decoration_h_without_scrollbars) < size_contents.y and (bit.band(window.Flags, ImGuiWindowFlags_NoScrollbar) == 0)) or (bit.band(window.Flags, ImGuiWindowFlags_AlwaysVerticalScrollbar) ~= 0)
        if will_have_scrollbar_x then
            size_auto_fit.y = size_auto_fit.y + style.ScrollbarSize
        end
        if will_have_scrollbar_y then
            size_auto_fit.x = size_auto_fit.x + style.ScrollbarSize
        end
        return size_auto_fit
    end
end

--- @param window               ImGuiWindow
--- @param content_size_current ImVec2
--- @param content_size_ideal   ImVec2
local function CalcWindowContentSizes(window, content_size_current, content_size_ideal)
    local preserve_old_content_sizes = false
    if window.Collapsed and window.AutoFitFramesX <= 0 and window.AutoFitFramesY <= 0 then
        preserve_old_content_sizes = true
    elseif window.Hidden and window.HiddenFramesCannotSkipItems == 0 and window.HiddenFramesCanSkipItems > 0 then
        preserve_old_content_sizes = true
    end
    if preserve_old_content_sizes then
        content_size_current.x = window.ContentSize.x
        content_size_current.y = window.ContentSize.y
        content_size_ideal.x = window.ContentSizeIdeal.x
        content_size_ideal.y = window.ContentSizeIdeal.y
        return
    end

    content_size_current.x = (window.ContentSizeExplicit.x ~= 0.0) and window.ContentSizeExplicit.x or ImTrunc64(window.DC.CursorMaxPos.x - window.DC.CursorStartPos.x)
    content_size_current.y = (window.ContentSizeExplicit.y ~= 0.0) and window.ContentSizeExplicit.y or ImTrunc64(window.DC.CursorMaxPos.y - window.DC.CursorStartPos.y)
    content_size_ideal.x = (window.ContentSizeExplicit.x ~= 0.0) and window.ContentSizeExplicit.x or ImTrunc64(ImMax(window.DC.CursorMaxPos.x, window.DC.IdealMaxPos.x) - window.DC.CursorStartPos.x)
    content_size_ideal.y = (window.ContentSizeExplicit.y ~= 0.0) and window.ContentSizeExplicit.y or ImTrunc64(ImMax(window.DC.CursorMaxPos.y, window.DC.IdealMaxPos.y) - window.DC.CursorStartPos.y)
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

--- @param window          ImGuiWindow
--- @param resize_grip_col table
local function UpdateWindowManualResize(window, resize_grip_col)
    local g = GImGui
    local flags = window.Flags

    if (bit.band(flags, ImGuiWindowFlags_NoResize) ~= 0 or window.AutoFitFramesX > 0 or window.AutoFitFramesY > 0) then
        return false
    end
    if (bit.band(flags, ImGuiWindowFlags_AlwaysAutoResize) ~= 0 and bit.band(window.ChildFlags, bit.bor(ImGuiChildFlags_ResizeX, ImGuiChildFlags_ResizeY)) == 0) then
        return false
    end
    if window.WasActive == false then
        return
    end

    local grip_draw_size = IM_TRUNC(ImMax(g.FontSize * 1.35, g.Style.WindowRounding + 1.0 + g.FontSize * 0.2))
    local grip_hover_inner_size = IM_TRUNC(grip_draw_size * 0.75)
    local grip_hover_outer_size = g.WindowsBorderHoverPadding + 1

    ImGui.PushID("#RESIZE")

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

        local resize_grip_id = window:GetID(tostring(i))

        ImGui.ItemAdd(resize_rect, resize_grip_id)
        local pressed, hovered, held = ImGui.ButtonBehavior(resize_rect, resize_grip_id)

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

    ImGui.PopID()
end

--- TODO: AutoFit -> ScrollBar() -> Text()

--- @param pos        ImVec2
--- @param wrap_pos_x float
--- @return float
function ImGui.CalcWrapWidthForPos(pos, wrap_pos_x)
    if wrap_pos_x < 0.0 then
        return 0.0
    end

    local g = GImGui
    local window = g.CurrentWindow
    if wrap_pos_x == 0.0 then
        wrap_pos_x = window.WorkRect.Max.x
    elseif wrap_pos_x > 0.0 then
        wrap_pos_x = wrap_pos_x + window.Pos.x - window.Scroll.x
    end

    return ImMax(wrap_pos_x - pos.x, 1.0)
end

--- @param text string
--- @param text_end int?
function ImGui.FindRenderedTextEnd(text, text_end)
    local text_display_end = 1
    if not text_end then
        text_end = #text + 1
    end
    while (text_display_end < text_end and text_display_end <= #text and (string.sub(text, text_display_end, text_display_end) ~= "#" or string.sub(text, text_display_end + 1, text_display_end + 1) ~= "#")) do
        text_display_end = text_display_end + 1
    end

    return text_display_end
end

--- void ImGui::RenderText
--- @param pos ImVec2
--- @param text string
--- @param text_end int?
--- @param hide_text_after_hash bool?
function ImGui.RenderText(pos, text, text_end, hide_text_after_hash)
    local g = GImGui
    local window = g.CurrentWindow

    -- Hide anything after a '##' string
    local text_display_end
    if hide_text_after_hash then
        text_display_end = ImGui.FindRenderedTextEnd(text, text_end)
    else
        if text_end == nil then
            text_end = #text + 1
        end
        text_display_end = text_end
    end

    if text ~= "" and text_display_end > 1 then
        window.DrawList:AddText(g.Font, g.FontSize, pos, g.Style.Colors.Text, text, 1, text_display_end, 0.0)
        if g.LogEnabled then
            -- LogRenderedText(&pos, text, text_display_end);
        end
    end
end

--- @param pos        ImVec2
--- @param text       string
--- @param text_end   int?
--- @param wrap_width float
function ImGui.RenderTextWrapped(pos, text, text_end, wrap_width)
    local g = GImGui
    local window = g.CurrentWindow

    if text_end == nil then
        text_end = #text + 1
    end

    if text ~= "" then -- TODO: GetColorU32(ImGuiCol_Text)
        window.DrawList:AddText(g.Font, g.FontSize, pos, g.Style.Colors.Text, text, 1, text_end, wrap_width)
    end
end

--- @param draw_list           ImDrawList
--- @param pos_min             ImVec2
--- @param pos_max             ImVec2
--- @param text                string
--- @param text_display_end    int
--- @param text_size_if_known? ImVec2
--- @param align?              ImVec2
--- @param clip_rect?          ImRect
local function RenderTextClippedEx(draw_list, pos_min, pos_max, text, text_begin, text_display_end, text_size_if_known, align, clip_rect)
    if not align then align = ImVec2(0, 0) end

    local pos = pos_min
    local text_size = text_size_if_known or ImGui.CalcTextSize(text, text_display_end, false, 0.0)

    local clip_min = clip_rect and clip_rect.Min or pos_min
    local clip_max = clip_rect and clip_rect.Max or pos_max
    local need_clipping = (pos.x + text_size.x >= clip_max.x) or (pos.y + text_size.y >= clip_max.y)
    if (clip_rect) then
        need_clipping = need_clipping or ((pos.x < clip_min.x) or (pos.y < clip_min.y))
    end

    if (align.x > 0.0) then pos.x = ImMax(pos.x, pos.x + (pos_max.x - pos.x - text_size.x) * align.x) end
    if (align.y > 0.0) then pos.y = ImMax(pos.y, pos.y + (pos_max.y - pos.y - text_size.y) * align.y) end

    local g = GImGui
    if (need_clipping) then -- TODO: GetColorU32(ImGuiCol_Text)
        local fine_clip_rect = ImVec4(clip_min.x, clip_min.y, clip_max.x, clip_max.y)
        draw_list:AddText(nil, 0.0, pos, g.Style.Colors.Text, text, text_begin, text_display_end, 0.0, fine_clip_rect)
    else
        draw_list:AddText(nil, 0.0, pos, g.Style.Colors.Text, text, text_begin, text_display_end, 0.0, nil)
    end
end

--- @param pos_min            ImVec2
--- @param pos_max            ImVec2
--- @param text               string
--- @param text_end?          int
--- @param text_size_if_known ImVec2
--- @param align?             ImVec2
--- @param clip_rect?         ImRect
function ImGui.RenderTextClipped(pos_min, pos_max, text, text_begin, text_end, text_size_if_known, align, clip_rect)
    if not align then align = ImVec2(0, 0) end

    local text_display_end = ImGui.FindRenderedTextEnd(text, text_end)
    local text_len = text_display_end - text_begin

    if text_len == 0 then
        return
    end

    local g = GImGui
    local window = g.CurrentWindow
    RenderTextClippedEx(window.DrawList, pos_min, pos_max, text, text_begin, text_display_end, text_size_if_known, align, clip_rect)
    -- if (g.LogEnabled)
    --     LogRenderedText(&pos_min, text, text_display_end);
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
        -- TODO: 
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
            local border_inner = IM_ROUND(window_border_size * 0.5)
            window.DrawList:PathLineTo(corner + inner_dir * ((i % 2 == 0) and ImVec2(border_inner, resize_grip_draw_size) or ImVec2(resize_grip_draw_size, border_inner)))
            window.DrawList:PathLineTo(corner + inner_dir * ((i % 2 == 0) and ImVec2(resize_grip_draw_size, border_inner) or ImVec2(border_inner, resize_grip_draw_size)))
            window.DrawList:PathArcToFast(ImVec2(corner.x + inner_dir.x * (window_rounding + border_inner), corner.y + inner_dir.y * (window_rounding + border_inner)), window_rounding, ImResizeGripDef[i].AngleMin12, ImResizeGripDef[i].AngleMax12)
            window.DrawList:PathFillConvex(col)
        end

        -- RenderWindowOuterBorders?
        window.DrawList:AddRect(window.Pos, window.Pos + window.Size, g.Style.Colors.Border, 0, 0, border_width)
    end
end

--- ImGui::RenderWindowTitleBarContents
local function RenderWindowTitleBarContents(window, title_bar_rect, name, p_open)
    local g = GImGui
    local style = g.Style
    local flags = window.Flags

    local has_close_button = ((p_open ~= nil) and (p_open[1] ~= nil) or true)
    local has_collapse_button = bit.band(flags, ImGuiWindowFlags_NoCollapse) == 0 and (style.WindowMenuButtonPosition ~= ImGuiDir.None)

    local item_flags_backup = g.CurrentItemFlags
    g.CurrentItemFlags = bit.bor(g.CurrentItemFlags, ImGuiItemFlags_NoNavDefaultFocus)
    window.DC.NavLayerCurrent = ImGuiNavLayer.Menu

    local pad_l = g.Style.FramePadding.x
    local pad_r = g.Style.FramePadding.x
    local button_sz = g.FontSize
    local close_button_pos
    local collapse_button_pos
    if has_close_button then
        close_button_pos = ImVec2(title_bar_rect.Max.x - pad_r - button_sz, title_bar_rect.Min.y + style.FramePadding.y)
        pad_r = pad_r + button_sz + style.ItemInnerSpacing.x
    end
    if has_collapse_button and style.WindowMenuButtonPosition == ImGuiDir.Right then
        collapse_button_pos = ImVec2(title_bar_rect.Max.x - pad_r - button_sz, title_bar_rect.Min.y + style.FramePadding.y)
        pad_r = pad_r + button_sz + style.ItemInnerSpacing.x
    end
    if has_collapse_button and style.WindowMenuButtonPosition == ImGuiDir.Left then
        collapse_button_pos = ImVec2(title_bar_rect.Min.x + pad_l, title_bar_rect.Min.y + style.FramePadding.y)
        pad_l = pad_l + button_sz + style.ItemInnerSpacing.x
    end

    if has_collapse_button then
        if ImGui.CollapseButton(window:GetID("#COLLAPSE"), collapse_button_pos) then
            window.Collapsed = not window.Collapsed
        end
    end

    if has_close_button then
        local backup_item_flags = g.CurrentItemFlags
        g.CurrentItemFlags = bit.bor(g.CurrentItemFlags, ImGuiItemFlags_NoFocus)
        if ImGui.CloseButton(window:GetID("#CLOSE"), close_button_pos) then
            p_open[1] = false
            window.Hidden = true -- TODO: temporary hidden set
        end
        g.CurrentItemFlags = backup_item_flags
    end

    window.DC.NavLayerCurrent = ImGuiNavLayer.Main
    g.CurrentItemFlags = item_flags_backup

    local marker_size_x = (bit.band(flags, ImGuiWindowFlags_UnsavedDocument) ~= 0) and (button_sz * 0.80) or 0.0
    local text_size = ImGui.CalcTextSize(name, nil, true) + ImVec2(marker_size_x, 0.0)

    if (pad_l > style.FramePadding.x) then
        pad_l = pad_l + g.Style.ItemInnerSpacing.x
    end
    if (pad_r > style.FramePadding.x) then
        pad_r = pad_r + g.Style.ItemInnerSpacing.x
    end
    if (style.WindowTitleAlign.x > 0.0 and style.WindowTitleAlign.x < 1.0) then
        local centerness = ImSaturate(1.0 - ImFabs(style.WindowTitleAlign.x - 0.5) * 2.0)
        local pad_extend = ImMin(ImMax(pad_l, pad_r), title_bar_rect:GetWidth() - pad_l - pad_r - text_size.x)
        pad_l = ImMax(pad_l, pad_extend * centerness)
        pad_r = ImMax(pad_r, pad_extend * centerness)
    end

    local layout_r = ImRect(title_bar_rect.Min.x + pad_l, title_bar_rect.Min.y, title_bar_rect.Max.x - pad_r, title_bar_rect.Max.y)
    local clip_r = ImRect(layout_r.Min.x, layout_r.Min.y, ImMin(layout_r.Max.x + g.Style.ItemInnerSpacing.x, title_bar_rect.Max.x), layout_r.Max.y)

    -- if bit.band(flags, ImGuiWindowFlags_UnsavedDocument) ~= 0 then
    -- TODO: 
    -- end

    ImGui.RenderTextClipped(layout_r.Min, layout_r.Max, name, 1, nil, text_size, style.WindowTitleAlign, clip_r)
end

--- static void SetCurrentWindow
local function SetCurrentWindow(window)
    local g = GImGui
    g.CurrentWindow = window

    g.CurrentDpiScale = 1.0

    if window then
        local backup_skip_items = window.SkipItems
        window.SkipItems = false

        if bit.band(g.IO.BackendFlags, ImGuiBackendFlags.RendererHasTextures) ~= 0 then
            local viewport = window.Viewport
            g.FontRasterizerDensity = (viewport.FramebufferScale.x ~= 0.0) and viewport.FramebufferScale.x or g.IO.DisplayFramebufferScale.x
        end

        ImGui.UpdateCurrentFontSize(0.0)

        window.SkipItems = backup_skip_items
    end
end

--- @param window ImGuiWindow
--- @param pos    ImVec2
--- @param cond?  ImGuiCond
function ImGui.SetWindowPos(window, pos, cond)
    if cond == nil then cond = 0 end

    if (cond ~= 0) and (bit.band(window.SetWindowPosAllowFlags, cond) == 0) then
        return
    end

    IM_ASSERT(cond == 0 or ImIsPowerOfTwo(cond))
    window.SetWindowPosAllowFlags = bit.band(window.SetWindowPosAllowFlags, bit.bnot(bit.bor(ImGuiCond_Once, ImGuiCond_FirstUseEver, ImGuiCond_Appearing)))
    window.SetWindowPosVal = ImVec2(FLT_MAX, FLT_MAX)

    local old_pos = window.Pos:copy()

    window.Pos.x = ImTrunc(pos.x)
    window.Pos.y = ImTrunc(pos.y)

    local offset = window.Pos - old_pos

    if offset.x == 0 and offset.y == 0 then
        return
    end

    window.DC.CursorPos = window.DC.CursorPos + offset
    window.DC.CursorMaxPos = window.DC.CursorMaxPos + offset
    window.DC.IdealMaxPos = window.DC.IdealMaxPos + offset
    window.DC.CursorStartPos = window.DC.CursorStartPos + offset
end

--- @param window ImGuiWindow
--- @param size   ImVec2
--- @param cond?  ImGuiCond
function ImGui.SetWindowSize(window, size, cond)
    if cond == nil then cond = 0 end

    if ((cond ~= 0) and bit.band(window.SetWindowSizeAllowFlags, cond) == 0) then
        return
    end

    IM_ASSERT(cond == 0 or ImIsPowerOfTwo(cond))
    window.SetWindowSizeAllowFlags = bit.band(window.SetWindowSizeAllowFlags, bit.bnot(bit.bor(ImGuiCond_Once, ImGuiCond_FirstUseEver, ImGuiCond_Appearing)))

    if bit.band(window.Flags, ImGuiWindowFlags_ChildWindow) == 0 or window.Appearing or bit.band(window.ChildFlags, ImGuiChildFlags_AlwaysAutoResize) ~= 0 then
        window.AutoFitFramesX = (size.x <= 0.0) and 2 or 0
    end
    if bit.band(window.Flags, ImGuiWindowFlags_ChildWindow) == 0 or window.Appearing or bit.band(window.ChildFlags, ImGuiChildFlags_AlwaysAutoResize) ~= 0 then
        window.AutoFitFramesY = (size.y <= 0.0) and 2 or 0
    end

    local old_size = window.SizeFull:copy()
    if size.x <= 0.0 then
        window.AutoFitOnlyGrows = false
    else
        window.SizeFull.x = IM_TRUNC(size.x)
    end
    if size.y <= 0.0 then
        window.AutoFitOnlyGrows = false
    else
        window.SizeFull.y = IM_TRUNC(size.y)
    end
    -- if old_size.x ~= window.SizeFull.x or old_size.y ~= window.SizeFull.y then
    --     TODO: MarkIniSettingsDirty(window)
    -- end
end

--- @param pos    ImVec2
--- @param cond?  ImGuiCond
--- @param pivot? ImVec2
function ImGui.SetNextWindowPos(pos, cond, pivot)
    if cond  == nil then cond  = 0            end
    if pivot == nil then pivot = ImVec2(0, 0) end

    local g = GImGui
    IM_ASSERT(cond == 0 or ImIsPowerOfTwo(cond))

    g.NextWindowData.HasFlags    = bit.bor(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasPos)
    g.NextWindowData.PosVal      = pos:copy()
    g.NextWindowData.PosPivotVal = pivot:copy()
    g.NextWindowData.PosCond     = (cond ~= 0) and cond or ImGuiCond_Always
end

--- @param size  ImVec2
--- @param cond? ImGuiCond
function ImGui.SetNextWindowSize(size, cond)
    if cond == nil then cond = 0 end

    local g = GImGui
    IM_ASSERT(cond == 0 or ImIsPowerOfTwo(cond))

    g.NextWindowData.HasFlags = bit.bor(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasSize)
    g.NextWindowData.SizeVal  = size:copy()
    g.NextWindowData.SizeCond = (cond ~= 0) and cond or ImGuiCond_Always
end

--- void ImGui::StartMouseMovingWindow
local function StartMouseMovingWindow(window)
    local g = GImGui

    ImGui.FocusWindow(window)
    ImGui.SetActiveID(window.MoveID, window)

    g.ActiveIDClickOffset = g.IO.MouseClickedPos[1] - window.Pos

    g.MovingWindow = window
end

--- void ImGui::UpdateMouseMovingWindowNewFrame
function ImGui.UpdateMouseMovingWindowNewFrame()
    local g = GImGui
    local window = g.MovingWindow

    if window then
        ImGui.KeepAliveID(g.ActiveId)

        if g.IO.MouseDown[1] then
            ImGui.SetWindowPos(window, g.IO.MousePos - g.ActiveIDClickOffset)

            ImGui.FocusWindow(g.MovingWindow)
        else
            StopMouseMovingWindow()
            ImGui.ClearActiveID()
        end
    else
        if (g.ActiveIDWindow and g.ActiveIDWindow.MoveID == g.ActiveId) then
            ImGui.KeepAliveID(g.ActiveId)

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

    if g.ActiveId ~= 0 or g.HoveredId ~= 0 then return end

    local hovered_window = g.HoveredWindow

    if g.IO.MouseClicked[1] then
        if hovered_window then
            StartMouseMovingWindow(hovered_window)
        else -- TODO: investigate elseif (hovered_window == nil and g.NavWindow == nil) 
            ImGui.FocusWindow(nil)
            g.ActiveIDWindow = nil
        end
    end
end

--- ImGui::FindWindowByID
function ImGui.FindWindowByID(id)
    local g = GImGui

    if not g then return end

    return g.WindowsById[id]
end

--- ImGui::FindWindowByName
function ImGui.FindWindowByName(name)
    local id = ImHashStr(name)
    return ImGui.FindWindowByID(id)
end

function ImGui.GetMainViewport()
    local g = GImGui

    return g.Viewports:at(1)
end

--- void ImGui::SetWindowViewport(ImGuiWindow* window, ImGuiViewportP* viewport)
function ImGui.SetWindowViewport(window, viewport)
    window.Viewport = viewport
end

-- `p_open` will be set to false when the close button is pressed.
--- @param name     string
--- @param p_open?  bool_ptr
--- @param flags?   ImGuiWindowFlags
--- @return bool
function ImGui.Begin(name, p_open, flags)
    if not flags  then flags = 0 end

    local g = GImGui
    local style = g.Style

    IM_ASSERT(name ~= nil and name ~= "")
    IM_ASSERT(g.WithinFrameScope)
    IM_ASSERT(g.FrameCountEnded ~= g.FrameCount)

    local window = ImGui.FindWindowByName(name)
    local window_just_created = (window == nil)
    if window_just_created then
        window = CreateNewWindow(name, flags) --- @cast window ImGuiWindow
    end

    local current_frame = g.FrameCount
    local first_begin_of_the_frame = (window.LastFrameActive ~= current_frame)
    window.IsFallbackWindow = (g.CurrentWindowStack.Size == 0 and g.WithinFrameScopeWithImplicitWindow)

    local window_just_activated_by_user = (window.LastFrameActive < (current_frame - 1))

    window.Appearing = window_just_activated_by_user
    if (window.Appearing) then
        SetWindowConditionAllowFlags(window, ImGuiCond_Appearing, true)
    end

    -- Update Flags, LastFrameActive, BeginOrderXXX fields
    if first_begin_of_the_frame then
        window.Flags = flags
        window.ChildFlags = (bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasChildFlags) ~= 0) and g.NextWindowData.ChildFlags or 0
        window.LastFrameActive = current_frame
        window.LastTimeActive = g.Time
    else
        flags = window.Flags
    end

    if window.IDStack.Size == 0 then
        window.IDStack:push_back(window.ID)
    end

    -- Add to stack
    g.CurrentWindow = window
    g.CurrentWindowStack:resize(g.CurrentWindowStack.Size + 1)
    g.CurrentWindowStack.Data[g.CurrentWindowStack.Size] = ImGuiWindowStackData()
    local window_stack_data = g.CurrentWindowStack.Data[g.CurrentWindowStack.Size]
    window_stack_data.Window = window
    window_stack_data.ParentLastItemDataBackup = g.LastItemData
    window_stack_data.DisabledOverrideReenable = (bit.band(flags, ImGuiWindowFlags_Tooltip) ~= 0) and (bit.band(g.CurrentItemFlags, ImGuiItemFlags_Disabled) ~= 0)
    window_stack_data.DisabledOverrideReenableAlphaBackup = 0.0

    local window_pos_set_by_api = false
    local window_size_x_set_by_api = false
    local window_size_y_set_by_api = false
    if bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasPos) ~= 0 then
        window_pos_set_by_api = (bit.band(window.SetWindowPosAllowFlags, g.NextWindowData.PosCond) ~= 0)
        if window_pos_set_by_api and ImLengthSqr(g.NextWindowData.PosPivotVal) > 1e-5 then
            -- FIXME: Look into removing the branch so everything can go through this same code path for consistency.
            window.SetWindowPosVal = g.NextWindowData.PosVal:copy()
            window.SetWindowPosPivot = g.NextWindowData.PosPivotVal:copy()
            window.SetWindowPosAllowFlags = bit.band(window.SetWindowPosAllowFlags, bit.bnot(bit.bor(ImGuiCond_Once, ImGuiCond_FirstUseEver, ImGuiCond_Appearing)))
        else
            ImGui.SetWindowPos(window, g.NextWindowData.PosVal, g.NextWindowData.PosCond)
        end
    end
    if bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasSize) ~= 0 then
        window_size_x_set_by_api = (bit.band(window.SetWindowSizeAllowFlags, g.NextWindowData.SizeCond) ~= 0) and (g.NextWindowData.SizeVal.x > 0.0)
        window_size_y_set_by_api = (bit.band(window.SetWindowSizeAllowFlags, g.NextWindowData.SizeCond) ~= 0) and (g.NextWindowData.SizeVal.y > 0.0)
        if (bit.band(window.ChildFlags, ImGuiChildFlags_ResizeX) ~= 0 and bit.band(window.SetWindowSizeAllowFlags, ImGuiCond_FirstUseEver) == 0) then
            g.NextWindowData.SizeVal.x = window.SizeFull.x
        end
        if (bit.band(window.ChildFlags, ImGuiChildFlags_ResizeY) ~= 0 and bit.band(window.SetWindowSizeAllowFlags, ImGuiCond_FirstUseEver) == 0) then
            g.NextWindowData.SizeVal.y = window.SizeFull.y
        end
        ImGui.SetWindowSize(window, g.NextWindowData.SizeVal, g.NextWindowData.SizeCond);
    end
    if bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasScroll) ~= 0 then
        if g.NextWindowData.ScrollVal.x >= 0.0 then
            window.ScrollTarget.x = g.NextWindowData.ScrollVal.x
            window.ScrollTargetCenterRatio.x = 0.0
        end
        if g.NextWindowData.ScrollVal.y >= 0.0 then
            window.ScrollTarget.y = g.NextWindowData.ScrollVal.y
            window.ScrollTargetCenterRatio.y = 0.0
        end
    end

    g.CurrentWindow = nil

    if first_begin_of_the_frame and not window.SkipRefresh then
        local window_is_child_tooltip = (bit.band(flags, ImGuiWindowFlags_ChildWindow) ~= 0 and bit.band(flags, ImGuiWindowFlags_Tooltip) ~= 0)

        window.Active = true
        window.HasCloseButton = ((p_open ~= nil) and (p_open[1] ~= nil) or true)
        window.ClipRect = ImVec4(-FLT_MAX, -FLT_MAX, FLT_MAX, FLT_MAX)

        window.IDStack:resize(1)

        window.DrawList:_ResetForNewFrame()

        -- UPDATE CONTENTS SIZE, UPDATE HIDDEN STATUS
        -- Update contents size from last frame for auto-fitting (or use explicit size)
        CalcWindowContentSizes(window, window.ContentSize, window.ContentSizeIdeal)
        if window.HiddenFramesCanSkipItems > 0 then
            window.HiddenFramesCanSkipItems = window.HiddenFramesCanSkipItems - 1
        end
        if window.HiddenFramesCannotSkipItems > 0 then
            window.HiddenFramesCannotSkipItems = window.HiddenFramesCannotSkipItems - 1
        end
        if window.HiddenFramesForRenderOnly > 0 then
            window.HiddenFramesForRenderOnly = window.HiddenFramesForRenderOnly - 1
        end

        -- Hide new windows for one frame until they calculate their size
        if window_just_created then
            window.HiddenFramesCannotSkipItems = 1
        end

        -- Hide popup/tooltip window when re-opening while we measure size (because we recycle the windows)
        -- We reset Size/ContentSize for reappearing popups/tooltips early in this function, so further code won't be tempted to use the old size.
        if window_just_activated_by_user and bit.band(flags, bit.bor(ImGuiWindowFlags_Popup, ImGuiWindowFlags_Tooltip)) ~= 0 then
            window.HiddenFramesCannotSkipItems = 1
            if bit.band(flags, ImGuiWindowFlags_AlwaysAutoResize) ~= 0 then
                if not window_size_x_set_by_api then
                    window.SizeFull.x = 0.0
                    window.Size.x = 0.0
                end
                if not window_size_y_set_by_api then
                    window.SizeFull.y = 0.0
                    window.Size.y = 0.0
                end
                window.ContentSize = ImVec2(0.0, 0.0)
                window.ContentSizeIdeal = ImVec2(0.0, 0.0)
            end
        end

        local viewport = ImGui.GetMainViewport()
        ImGui.SetWindowViewport(window, viewport)
        SetCurrentWindow(window)

        if bit.band(flags, ImGuiWindowFlags_ChildWindow) ~= 0 then
            window.WindowBorderSize = style.ChildBorderSize
        else
            window.WindowBorderSize = (bit.band(flags, bit.bor(ImGuiWindowFlags_Popup, ImGuiWindowFlags_Tooltip)) ~= 0 and bit.band(flags, ImGuiWindowFlags_Modal) == 0) and style.PopupBorderSize or style.WindowBorderSize
        end
        window.WindowPadding = style.WindowPadding
        -- if ((flags & ImGuiWindowFlags_ChildWindow) && !(flags & ImGuiWindowFlags_Popup) && !(window->ChildFlags & ImGuiChildFlags_AlwaysUseWindowPadding) && window->WindowBorderSize == 0.0f)
        -- window->WindowPadding = ImVec2(0.0f, (flags & ImGuiWindowFlags_MenuBar) ? style.WindowPadding.y : 0.0f);

        window.TitleBarHeight = (bit.band(flags, ImGuiWindowFlags_NoTitleBar) ~= 0) and 0 or g.FontSize + g.Style.FramePadding.y * 2

        -- const ImVec2 scrollbar_sizes_from_last_frame = window->ScrollbarSizes;
        window.DecoOuterSizeX1 = 0.0
        window.DecoOuterSizeX2 = 0.0
        window.DecoOuterSizeY1 = window.TitleBarHeight + window.MenuBarHeight
        window.DecoOuterSizeY2 = 0.0
        -- window->ScrollbarSizes = ImVec2(0.0f, 0.0f);

        window.SizeFull = CalcWindowSizeAfterConstraint(window, window.SizeFull)
        window.Size = (window.Collapsed and bit.band(flags, ImGuiWindowFlags_ChildWindow) == 0) and window:TitleBarRect():GetSize() or window.SizeFull

        local viewport_rect = viewport:GetMainRect()
        local viewport_work_rect = viewport:GetWorkRect()

        window.Pos.x = ImTrunc(window.Pos.x) window.Pos.y = ImTrunc(window.Pos.y)

        local want_focus = false
        if (window_just_activated_by_user and bit.band(flags, ImGuiWindowFlags_NoFocusOnAppearing) == 0) then
            if bit.band(flags, ImGuiWindowFlags_Popup) ~= 0 then
                want_focus = true
            elseif (bit.band(flags, bit.bor(ImGuiWindowFlags_ChildWindow, ImGuiWindowFlags_Tooltip)) == 0)then
                want_focus = true
            end
        end

        if bit.band(flags, ImGuiWindowFlags_ChildWindow) ~= 0 then
            window.WindowRounding = style.ChildRounding
        else
            if (bit.band(flags, ImGuiWindowFlags_Popup) ~= 0 and bit.band(flags, ImGuiWindowFlags_Modal) == 0) then
                window.WindowRounding = style.PopupRounding
            else
                window.WindowRounding = style.WindowRounding
            end
        end

        local handle_borders_and_resize_grips = true
        if bit.band(flags, ImGuiWindowFlags_ChildWindow) ~= 0 and window.ParentWindow.SkipItems then
            handle_borders_and_resize_grips = false
        end

        local resize_grip_col = {}
        local resize_grip_draw_size = ImTrunc(ImMax(g.FontSize * 1.10, g.Style.WindowRounding + 1.0 + g.FontSize * 0.2))
        if handle_borders_and_resize_grips and not window.Collapsed then
            UpdateWindowManualResize(window, resize_grip_col)
        end

        local host_rect = (bit.band(flags, ImGuiWindowFlags_ChildWindow) ~= 0 and bit.band(flags, ImGuiWindowFlags_Popup) == 0 and not window_is_child_tooltip) and parent_window.ClipRect or viewport_rect
        local outer_rect = window:Rect()
        local title_bar_rect = window:TitleBarRect()
        window.OuterRectClipped = outer_rect
        window.OuterRectClipped:ClipWith(host_rect)

        window.InnerRect.Min.x = window.Pos.x + window.DecoOuterSizeX1
        window.InnerRect.Min.y = window.Pos.y + window.DecoOuterSizeY1
        window.InnerRect.Max.x = window.Pos.x + window.Size.x - window.DecoOuterSizeX2
        window.InnerRect.Max.y = window.Pos.y + window.Size.y - window.DecoOuterSizeY2

        local top_border_size = ((bit.band(flags, ImGuiWindowFlags_MenuBar) ~= 0 or bit.band(flags, ImGuiWindowFlags_NoTitleBar) == 0) and style.FrameBorderSize or window.WindowBorderSize)

        window.InnerClipRect.Min.x = ImFloor(0.5 + window.InnerRect.Min.x + window.WindowBorderSize * 0.5)
        window.InnerClipRect.Min.y = ImFloor(0.5 + window.InnerRect.Min.y + top_border_size * 0.5)
        window.InnerClipRect.Max.x = ImFloor(window.InnerRect.Max.x - window.WindowBorderSize * 0.5)
        window.InnerClipRect.Max.y = ImFloor(window.InnerRect.Max.y - window.WindowBorderSize * 0.5)
        window.InnerClipRect:ClipWithFull(host_rect)

        IM_ASSERT(window.DrawList.CmdBuffer.Size == 1 and window.DrawList.CmdBuffer.Data[1].ElemCount == 0)
        window.DrawList:PushTexture(g.Font.OwnerAtlas.TexRef)
        ImGui.PushClipRect(host_rect.Min, host_rect.Max, false)

        do
            local render_decorations_in_parent = false -- TODO: 

            local title_bar_is_highlight = (g.NavWindow == window) -- TODO: proper cond, just simple highlight now

            RenderWindowDecorations(window, title_bar_rect, title_bar_is_highlight, resize_grip_col, resize_grip_draw_size)
        end

        local allow_scrollbar_x = (bit.band(flags, ImGuiWindowFlags_NoScrollbar) == 0) and (bit.band(flags, ImGuiWindowFlags_HorizontalScrollbar) ~= 0)
        local allow_scrollbar_y = (bit.band(flags, ImGuiWindowFlags_NoScrollbar) == 0)

        local work_rect_size_x
        if window.ContentSizeExplicit.x ~= 0.0 then
            work_rect_size_x = window.ContentSizeExplicit.x
        else
            local content_size_x = allow_scrollbar_x and (window.ContentSize and window.ContentSize.x or 0.0) or 0.0
            local window_size_x = window.Size.x - window.WindowPadding.x * 2.0 - (window.DecoOuterSizeX1 + window.DecoOuterSizeX2)
            work_rect_size_x = ImMax(content_size_x, window_size_x)
        end

        local work_rect_size_y
        if window.ContentSizeExplicit.y ~= 0.0 then
            work_rect_size_y = window.ContentSizeExplicit.y
        else
            local content_size_y = allow_scrollbar_y and (window.ContentSize and window.ContentSize.y or 0.0) or 0.0
            local window_size_y = window.Size.y - window.WindowPadding.y * 2.0 - (window.DecoOuterSizeY1 + window.DecoOuterSizeY2)
            work_rect_size_y = ImMax(content_size_y, window_size_y)
        end

        window.WorkRect.Min.x = ImTrunc(window.InnerRect.Min.x - window.Scroll.x + ImMax(window.WindowPadding.x, window.WindowBorderSize))
        window.WorkRect.Min.y = ImTrunc(window.InnerRect.Min.y - window.Scroll.y + ImMax(window.WindowPadding.y, window.WindowBorderSize))
        window.WorkRect.Max.x = window.WorkRect.Min.x + work_rect_size_x
        window.WorkRect.Max.y = window.WorkRect.Min.y + work_rect_size_y
        window.ParentWorkRect = window.WorkRect

        -- [LEGACY] Content Region
        -- FIXME-OBSOLETE: window->ContentRegionRect.Max is currently very misleading / partly faulty, but some BeginChild() patterns relies on it.
        -- Unless explicit content size is specified by user, this currently represent the region leading to no scrolling.
        -- Used by:
        -- - Mouse wheel scrolling + many other things
        window.ContentRegionRect.Min.x = window.Pos.x - window.Scroll.x + window.WindowPadding.x + window.DecoOuterSizeX1
        window.ContentRegionRect.Min.y = window.Pos.y - window.Scroll.y + window.WindowPadding.y + window.DecoOuterSizeY1
        window.ContentRegionRect.Max.x = window.ContentRegionRect.Min.x + (window.ContentSizeExplicit.x ~= 0.0 and window.ContentSizeExplicit.x or (window.Size.x - window.WindowPadding.x * 2.0 - (window.DecoOuterSizeX1 + window.DecoOuterSizeX2)))
        window.ContentRegionRect.Max.y = window.ContentRegionRect.Min.y + (window.ContentSizeExplicit.y ~= 0.0 and window.ContentSizeExplicit.y or (window.Size.y - window.WindowPadding.y * 2.0 - (window.DecoOuterSizeY1 + window.DecoOuterSizeY2)))

        -- Setup drawing context
        -- (NB: That term "drawing context / DC" lost its meaning a long time ago. Initially was meant to hold transient data only. Nowadays difference between window-> and window->DC-> is dubious.)
        window.DC.Indent.x = window.DecoOuterSizeX1 + window.WindowPadding.x - window.Scroll.x
        window.DC.GroupOffset.x = 0.0
        window.DC.ColumnsOffset.x = 0.0

        -- Record the loss of precision of CursorStartPos which can happen due to really large scrolling amount.
        -- This is used by clipper to compensate and fix the most common use case of large scroll area. Easy and cheap, next best thing compared to switching everything to double or ImU64.
        local start_pos_highp_x = window.Pos.x + window.WindowPadding.x - window.Scroll.x + window.DecoOuterSizeX1 + window.DC.ColumnsOffset.x
        local start_pos_highp_y = window.Pos.y + window.WindowPadding.y - window.Scroll.y + window.DecoOuterSizeY1
        window.DC.CursorStartPos = ImVec2(start_pos_highp_x, start_pos_highp_y)
        window.DC.CursorStartPosLossyness = ImVec2(start_pos_highp_x - window.DC.CursorStartPos.x, start_pos_highp_y - window.DC.CursorStartPos.y)
        window.DC.CursorPos = window.DC.CursorStartPos
        window.DC.CursorPosPrevLine = window.DC.CursorPos
        window.DC.CursorMaxPos = window.DC.CursorStartPos
        window.DC.IdealMaxPos = window.DC.CursorStartPos
        window.DC.CurrLineSize = ImVec2(0.0, 0.0)
        window.DC.PrevLineSize = ImVec2(0.0, 0.0)
        window.DC.CurrLineTextBaseOffset = 0.0
        window.DC.PrevLineTextBaseOffset = 0.0
        window.DC.IsSameLine = false
        window.DC.IsSetPos = false

        window.DC.LayoutType = ImGuiLayoutType_Vertical
        window.DC.ParentLayoutType = (parent_window ~= nil) and parent_window.DC.LayoutType or ImGuiLayoutType_Vertical

        if (window.Size.x > 0.0 and bit.band(flags, ImGuiWindowFlags_Tooltip) == 0 and bit.band(flags, ImGuiWindowFlags_AlwaysAutoResize) == 0) then
            window.ItemWidthDefault = ImTrunc(window.Size.x * 0.65)
        else
            window.ItemWidthDefault = ImTrunc(g.FontSize * 16.0)
        end
        window.DC.ItemWidth = window.ItemWidthDefault
        window.DC.TextWrapPos = -1.0

        if window.AutoFitFramesX > 0 then
            window.AutoFitFramesX = window.AutoFitFramesX - 1
        end
        if window.AutoFitFramesY > 0 then
            window.AutoFitFramesY = window.AutoFitFramesY - 1
        end

        if want_focus then
            ImGui.FocusWindow(window)
        end

        -- TODO: SCROLL

        RenderWindowTitleBarContents(window, title_bar_rect, name, p_open)
    else
        -- if (window->SkipRefresh)
        --     SetWindowActiveForSkipRefresh(window);

        SetCurrentWindow(window)
        -- SetLastItemDataForWindow(window, window->TitleBarRect());
    end

    if (not window.SkipRefresh) then
        ImGui.PushClipRect(window.InnerClipRect.Min, window.InnerClipRect.Max, true)
    end

    window.WriteAccessed = false
    window.BeginCount = window.BeginCount + 1
    g.NextWindowData:ClearFlags()

    -- TODO: parent_window

    return not window.Collapsed
end

function ImGui.End()
    local g = GImGui
    local window = g.CurrentWindow

    if (g.CurrentWindowStack.Size <= 1 and g.WithinFrameScopeWithImplicitWindow) then
        IM_ASSERT_USER_ERROR(g.CurrentWindowStack.Size > 1, "Calling End() too many times!")

        return
    end

    if not window.SkipRefresh then
        ImGui.PopClipRect()
    end

    if (window.SkipRefresh) then
        IM_ASSERT(window.DrawList == nil)
        window.DrawList = window.DrawListInst
    end

    g.CurrentWindowStack:pop_back()

    -- GLUA: No "Ternary Operator", since lua (... and (1) or (2)) will eval (1) and (2) no matter what
    -- so something like `SetCurrentWindow((g.CurrentWindowStack.Size == 0) and nil or g.CurrentWindowStack:back().Window)` will error
    if (g.CurrentWindowStack.Size == 0) then
        SetCurrentWindow(nil)
    else
        SetCurrentWindow(g.CurrentWindowStack:back().Window)
    end
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

    for i = 0, 2 do -- IM_COUNTOF(io.MouseDown)
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

--- TODO: 
function ImGui.UpdateMouseInputs()
    local g = GImGui
    local io = g.IO

    io.MousePos.x = GetMouseX()
    io.MousePos.y = GetMouseY()

    for i = 0, 2 do -- IM_COUNTOF(io.MouseDown)
        io.MouseClicked[i] = io.MouseDown[i] and (io.MouseDownDuration[i] < 0)
        io.MouseClickedCount[i] = 0
        io.MouseReleased[i] = not io.MouseDown[i] and (io.MouseDownDuration[i] >= 0)

        if io.MouseClicked[i] then
            io.MouseClickedTime[i] = g.Time
            io.MouseClickedPos[i] = ImVec2(io.MousePos.x, io.MousePos.y)
        end

        if io.MouseReleased[i] then
            io.MouseReleasedTime[i] = g.Time
        end

        if io.MouseDown[i] then
            if io.MouseDownDuration[i] < 0 then
                io.MouseDownDuration[i] = 0
            else
                io.MouseDownDuration[i] = io.MouseDownDuration[i] + 1
            end
        else
            io.MouseDownDuration[i] = -1.0
        end

        io.MouseDownDurationPrev[i] = io.MouseDownDuration[i]
    end
end

local function SetupDrawListSharedData()
    local g = GImGui
    local virtual_space = ImRect(FLT_MAX, FLT_MAX, -FLT_MAX, -FLT_MAX)
    for _, viewport in g.Viewports:iter() do
        virtual_space:Add(viewport:GetMainRect())
    end
    g.DrawListSharedData.ClipRectFullscreen = virtual_space:ToVec4()
    g.DrawListSharedData.CurveTessellationTol = g.Style.CurveTessellationTol
    g.DrawListSharedData:SetCircleTessellationMaxError(g.Style.CircleTessellationMaxError)
    g.DrawListSharedData.InitialFlags = ImDrawListFlags_None
    if g.Style.AntiAliasedLines then
        g.DrawListSharedData.InitialFlags = bit.bor(g.DrawListSharedData.InitialFlags, ImDrawListFlags_AntiAliasedLines)
    end
    if g.Style.AntiAliasedLinesUseTex and not bit.band(g.IO.Fonts.Flags, ImFontAtlasFlags.NoBakedLines) then
        g.DrawListSharedData.InitialFlags = bit.bor(g.DrawListSharedData.InitialFlags, ImDrawListFlags_AntiAliasedLinesUseTex)
    end
    if g.Style.AntiAliasedFill then
        g.DrawListSharedData.InitialFlags = bit.bor(g.DrawListSharedData.InitialFlags, ImDrawListFlags_AntiAliasedFill)
    end
    if bit.band(g.IO.BackendFlags, ImGuiBackendFlags.RendererHasVtxOffset) then
        g.DrawListSharedData.InitialFlags = bit.bor(g.DrawListSharedData.InitialFlags, ImDrawListFlags_AllowVtxOffset)
    end
    g.DrawListSharedData.InitialFringeScale = 1.0
end

local function InitViewportDrawData(viewport)
    local io = ImGui.GetIO()
    local draw_data = viewport.DrawDataP

    viewport.DrawDataBuilder.Layers[1] = draw_data.CmdLists
    viewport.DrawDataBuilder.Layers[2] = viewport.DrawDataBuilder.LayerData1
    viewport.DrawDataBuilder.Layers[1]:resize(0)
    viewport.DrawDataBuilder.Layers[2]:resize(0)

    draw_data.Valid            = true
    draw_data.CmdListsCount    = 0
    draw_data.TotalVtxCount    = 0
    draw_data.TotalIdxCount    = 0
    draw_data.DisplayPos       = viewport.Pos
    draw_data.DisplaySize      = viewport.Size
    draw_data.FramebufferScale = io.DisplayFramebufferScale
    draw_data.OwnerViewport    = viewport
    draw_data.Textures         = ImGui.GetPlatformIO().Textures
end

--- @return ImGuiWindow
function ImGui.GetCurrentWindow()
    local g = GImGui
    g.CurrentWindow.WriteAccessed = true
    return g.CurrentWindow
end

--- @param clip_rect_min                     ImVec2
--- @param clip_rect_max                     ImVec2
--- @param intersect_with_current_clip_rect? bool
function ImGui.PushClipRect(clip_rect_min, clip_rect_max, intersect_with_current_clip_rect)
    local window = ImGui.GetCurrentWindow()
    window.DrawList:PushClipRect(clip_rect_min, clip_rect_max, intersect_with_current_clip_rect)
    window.ClipRect = window.DrawList._ClipRectStack:back()
end

function ImGui.PopClipRect()
    local window = ImGui.GetCurrentWindow()
    window.DrawList:PopClipRect()
    window.ClipRect = window.DrawList._ClipRectStack:back()
end

--- @param viewport      ImGuiViewportP
--- @param drawlist_no   size_t         # background(1), foreground(2)
--- @param drawlist_name string
local function GetViewportBgFgDrawList(viewport, drawlist_no, drawlist_name)
    local g = GImGui
    IM_ASSERT(drawlist_no <= 2) -- IM_COUNTOF(viewport->BgFgDrawLists)
    local draw_list = viewport.BgFgDrawLists[drawlist_no]
    if draw_list == nil then
        draw_list = ImDrawList(g.DrawListSharedData)
        draw_list._OwnerName = drawlist_name
        viewport.BgFgDrawLists[drawlist_no] = draw_list
    end

    if viewport.BgFgDrawListsLastFrame[drawlist_no] ~= g.FrameCount then
        draw_list:_ResetForNewFrame()
        draw_list:PushTexture(g.IO.Fonts.TexRef)
        draw_list:PushClipRect(viewport.Pos, viewport.Pos + viewport.Size, false)
        viewport.BgFgDrawListsLastFrame[drawlist_no] = g.FrameCount
    end

    return draw_list
end

function ImGui.GetBackgroundDrawList(viewport)
    local g = GImGui

    if viewport ~= nil then
        return GetViewportBgFgDrawList(viewport, 1, "##Background")
    end

    return GetViewportBgFgDrawList(g.Viewports:at(1), 1, "##Background")
end

function ImGui.GetForegroundDrawList(viewport)
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
    main_viewport.Flags = bit.bor(ImGuiViewportFlags_IsPlatformWindow, ImGuiViewportFlags_OwnedByApp)
    main_viewport.Pos = ImVec2(0, 0)
    main_viewport.Size = g.IO.DisplaySize
    main_viewport.FramebufferScale = g.IO.DisplayFramebufferScale
    IM_ASSERT(main_viewport.FramebufferScale.x > 0.0 and main_viewport.FramebufferScale.y > 0.0)

    for _, viewport in g.Viewports:iter() do
        viewport.WorkInsetMin = viewport.BuildWorkInsetMin
        viewport.WorkInsetMax = viewport.BuildWorkInsetMax
        viewport.BuildWorkInsetMax = ImVec2(0.0, 0.0)
        viewport.BuildWorkInsetMin = ImVec2(0.0, 0.0)
        viewport:UpdateWorkRect()
    end
end

function ImGui.NewFrame()
    IM_ASSERT(GImGui ~= nil, "No current context. Did you call ImGui::CreateContext() and ImGui::SetCurrentContext() ?")
    local g = GImGui

    g.Time = g.Time + g.IO.DeltaTime

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

    ImGui.UpdateViewportsNewFrame()

    ImGui.UpdateTexturesNewFrame()

    SetupDrawListSharedData()
    ImGui.UpdateFontsNewFrame()

    g.WithinFrameScope = true

    for _, viewport in g.Viewports:iter() do
        viewport.DrawDataP.Valid = false
    end

    g.HoveredId = 0
    g.HoveredWindow = nil -- TODO: is this correct?

    if (g.ActiveId ~= 0 and g.ActiveIdIsAlive ~= g.ActiveId and g.ActiveIdPreviousFrame == g.ActiveId) then
        print("NewFrame(): ClearActiveID() because it isn't marked alive anymore!")

        ImGui.ClearActiveID()
    end

    g.ActiveIdPreviousFrame = g.ActiveId
    g.ActiveIdIsAlive = 0
    g.ActiveIdIsJustActivated = false

    ImGui.UpdateMouseInputs()

    -- TODO: GC

    for _, window in g.Windows:iter() do
        window.WasActive = window.Active
        window.Active = false
        window.WriteAccessed = false
        window.BeginCountPreviousFrame = window.BeginCount
        window.BeginCount = 0
    end

    ImGui.UpdateHoveredWindowAndCaptureFlags()

    ImGui.UpdateMouseMovingWindowNewFrame()

    g.MouseCursor = "arrow" -- TODO:
    g.WantCaptureMouseNextFrame = -1
    g.WantCaptureKeyboardNextFrame = -1
    g.WantTextInputNextFrame = -1

    g.CurrentWindowStack:resize(0)

    g.WithinFrameScopeWithImplicitWindow = true
    ImGui.SetNextWindowSize(ImVec2(400, 400), ImGuiCond_FirstUseEver)
    ImGui.Begin("Debug##Default")
    IM_ASSERT(g.CurrentWindow.IsFallbackWindow == true)
end

function ImGui.EndFrame()
    local g = GImGui

    if g.FrameCountEnded == g.FrameCount then
        return
    end
    if not g.WithinFrameScope then
        IM_ASSERT_USER_ERROR(g.WithinFrameScope, "Forgot to call ImGui::NewFrame()?")

        return
    end

    g.WithinFrameScopeWithImplicitWindow = false
    if (g.CurrentWindow and not g.CurrentWindow.WriteAccessed) then
        g.CurrentWindow.Active = false
    end
    ImGui.End()

    g.WithinFrameScope = false
    g.FrameCountEnded = g.FrameCount
    ImGui.UpdateFontsEndFrame()

    ImGui.UpdateMouseMovingWindowEndFrame()

    ImGui.UpdateTexturesEndFrame()

    for _, atlas in g.FontAtlases:iter() do
        atlas.Locked = false
    end
end

function ImGui.Render()
    local g = GImGui
    IM_ASSERT(g.Initialized)

    if g.FrameCountEnded ~= g.FrameCount then
        ImGui.EndFrame()
    end
    if g.FrameCountRendered == g.FrameCount then return end
    g.FrameCountRendered = g.FrameCount

    g.IO.MetricsRenderWindows = 0

    for _, viewport in g.Viewports:iter() do
        InitViewportDrawData(viewport)
        if viewport.BgFgDrawLists[1] ~= nil then
            ImGui.AddDrawListToDrawDataEx(viewport.DrawDataP, viewport.DrawDataBuilder.Layers[1], ImGui.GetBackgroundDrawList(viewport))
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
            ImGui.AddDrawListToDrawDataEx(viewport.DrawDataP, viewport.DrawDataBuilder.Layers[1], ImGui.GetForegroundDrawList(viewport))
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

--- @param text                         string
--- @param text_end?                    int    # Exclusive upper bound
--- @param hide_text_after_double_hash? bool
--- @param wrap_width?                  float
--- @return ImVec2
function ImGui.CalcTextSize(text, text_end, hide_text_after_double_hash, wrap_width)
    if hide_text_after_double_hash == nil then hide_text_after_double_hash = false end
    if wrap_width                  == nil then wrap_width                  = -1.0  end

    local g = GImGui

    local text_display_end
    if hide_text_after_double_hash then
        text_display_end = ImGui.FindRenderedTextEnd(text, text_end)
    else
        text_display_end = text_end
    end

    local font = g.Font
    local font_size = g.FontSize
    if text == "" or (text_end and text_end <= 1) then
        return ImVec2(0.0, font_size)
    end
    local text_size = font:CalcTextSizeA(font_size, FLT_MAX, wrap_width, text, 1, text_display_end, nil)

    text_size.x = IM_TRUNC(text_size.x + 0.99999)

    return text_size
end

function ImGui.GetDrawData()
    local g = GImGui
    local viewport = g.Viewports:at(1)
    return viewport.DrawDataP.Valid and viewport.DrawDataP or nil
end

--- void ImGui::Shutdown()

function ImGui.GetIO() return GImGui.IO end

function ImGui.GetPlatformIO() return GImGui.PlatformIO end

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
function ImGui.ScaleWindowsInViewport(viewport, scale)
    local g = GImGui

    for _, window in g.Windows:iter() do
        if window.Viewport == viewport then
            ScaleWindow(window, scale)
        end
    end
end