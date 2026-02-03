--- ImGui for Garry's Mod written in pure Lua
--

--- Set to disable some functions, then you need to write your own
-- IMGUI_DISABLE_DEFAULT_FILE_FUNCTIONS = true // Don't implement ImFileOpen/ImFileClose/ImFileRead/ImFileWrite so you can implement them yourself
-- NOTE: you must implement ImFileOpen if you are not in GMod

--- @type ImGuiContext?
local GImGui = nil

ImGui = ImGui or {}

--[[
--- This executes Lua script at _filename and returns the result of the script.
--- @param _filename string
--- @return any
function IM_INCLUDE(_filename)
end
]]

--- [GMod] Platform specific include function
if gmod then
    IM_INCLUDE = include
end

IM_INCLUDE"imgui_h.lua"

IM_INCLUDE"imgui_internal.lua"

IM_INCLUDE"imgui_draw.lua"

IM_INCLUDE"imgui_widgets.lua"

local FONT_DEFAULT_SIZE_BASE = 20

local WINDOWS_RESIZE_FROM_EDGES_FEEDBACK_TIMER = 0.04

local TOOLTIP_DEFAULT_OFFSET_MOUSE = ImVec2(16, 10)   -- Multiplied by g.Style.MouseCursorScale
local TOOLTIP_DEFAULT_OFFSET_TOUCH = ImVec2(0, -20)   -- Multiplied by g.Style.MouseCursorScale
local TOOLTIP_DEFAULT_PIVOT_TOUCH  = ImVec2(0.5, 1.0) -- Multiplied by g.Style.MouseCursorScale

IMGUI_VIEWPORT_DEFAULT_ID = 0x11111111

local string = string
local ImFormatString = string.format

local math = math
local bit  = bit

---------------------------------------------------------------------------------------
-- [SECTION] MISC HELPERS/UTILITIES (File functions)
---------------------------------------------------------------------------------------

--- Store methods for File object
ImFile = {}

--[[
--- This closes the _file.
--- @param _file any # File object
function ImFile.close(_file)
end

--- This returns the size of _file in bytes.
--- @param _file any # File object
--- @return int
function ImFile.size(_file)
    return -1
end

--- This writes _str into _file.
--- @param _file any    # File object
--- @param _str  string
function ImFile.write(_file, _str)
end

--- This reads the specified _count of chars and returns them as a binary string.
--- @param _file any  # File object
--- @param _count int
--- @return string
function ImFile.read(_file, _count)
    return ""
end

--- This opens the file at _filename in _mode and returns the File object.
--- @param _filename string
--- @param _mode     string # e.g. "rb"
--- @return any
function ImFileOpen(_filename, _mode)
end
]]

--- [GMod] Platform specific
if gmod then
    ImFile.close = FindMetaTable("File").Close --- @type function
    ImFile.size  = FindMetaTable("File").Size  --- @type function
    ImFile.write = FindMetaTable("File").Write --- @type function
    ImFile.read  = FindMetaTable("File").Read  --- @type function
end

if not IMGUI_DISABLE_DEFAULT_FILE_FUNCTIONS then
    --- [GMod] Another Platform specific
    if gmod then
        function ImFileOpen(filename, mode) return file.Open(filename, mode, "GAME") end
    end

    function ImFileClose(f) ImFile.close(f) end
    function ImFileGetSize(f) return ImFile.size(f) end

    --- @param f     any   # File object
    --- @param data  table # 1-based table to store result data
    --- @param count int   # Amount of bytes to read from `f`
    function ImFileRead(f, data, count)
        local CHUNK_SIZE = 8000 -- We don't read byte by byte
        local offset = 0

        while offset < count do
            local read_size = math.min(CHUNK_SIZE, count - offset)
            local str = ImFile.read(f, read_size)

            local bytes = {string.byte(str, 1, read_size)}
            for i = 1, read_size do
                data[offset + i] = bytes[i]
            end

            offset = offset + read_size
        end
    end

    --- @param filename string
    --- @param mode     string
    --- @return ImSlice?, integer?
    function ImFileLoadToMemory(filename, mode)
        local f = ImFileOpen(filename, mode)
        if not f then return end

        local file_size = ImFileGetSize(f)
        if file_size <= 0 then
            ImFileClose(f)
            return
        end

        local file_data = IM_SLICE()
        ImFileRead(f, file_data.data, file_size)
        if #file_data.data == 0 then
            ImFileClose(f)
            return
        end

        ImFileClose(f)

        return file_data, file_size
    end
end

local MT = ImGui.GetMetatables()

local ImGuiResizeGripDef = {
    {CornerPosN = ImVec2(1, 1), InnerDir = ImVec2(-1, -1), AngleMin12 = 0, AngleMax12 = 3}, -- Bottom right grip
    {CornerPosN = ImVec2(0, 1), InnerDir = ImVec2( 1, -1), AngleMin12 = 3, AngleMax12 = 6}  -- Bottom left
}

--- [1] Left, [2] Right, [3] Up, [4] Down
local ImGuiResizeBorderDef = {
    {InnerDir = ImVec2( 1,  0), SegmentN1 = ImVec2( 0,  1), SegmentN2 = ImVec2( 0,  0), OuterAngle = IM_PI * 1.00},
    {InnerDir = ImVec2(-1,  0), SegmentN1 = ImVec2( 1,  0), SegmentN2 = ImVec2( 1,  1), OuterAngle = IM_PI * 0.00},
    {InnerDir = ImVec2( 0,  1), SegmentN1 = ImVec2( 0,  0), SegmentN2 = ImVec2( 1,  0), OuterAngle = IM_PI * 1.50},
    {InnerDir = ImVec2( 0, -1), SegmentN1 = ImVec2( 1,  1), SegmentN2 = ImVec2( 0,  1), OuterAngle = IM_PI * 0.50}
}

--- @param window       ImGuiWindow
--- @param border_n     int
--- @param perp_padding float
--- @param thickness    float
--- @return ImRect
--- @nodiscard
local function GetResizeBorderRect(window, border_n, perp_padding, thickness)
    local rect = window:Rect()
    if thickness == 0.0 then
        rect.Max = ImVec2(rect.Max.x - 1, rect.Max.y - 1)
    end
    if border_n == ImGuiDir.Left then
        return ImRect(rect.Min.x - thickness, rect.Min.y + perp_padding, rect.Min.x + thickness, rect.Max.y - perp_padding)
    end
    if border_n == ImGuiDir.Right then
        return ImRect(rect.Max.x - thickness, rect.Min.y + perp_padding, rect.Max.x + thickness, rect.Max.y - perp_padding)
    end
    if border_n == ImGuiDir.Up then
        return ImRect(rect.Min.x + perp_padding, rect.Min.y - thickness, rect.Max.x - perp_padding, rect.Min.y + thickness)
    end
    if border_n == ImGuiDir.Down then
        return ImRect(rect.Min.x + perp_padding, rect.Max.y - thickness, rect.Max.x - perp_padding, rect.Max.y + thickness)
    end
    IM_ASSERT(false)
    return ImRect()
end

--- @param data table|number
--- @param size int?
--- @param seed int?
--- @return int
function ImHashData(data, size, seed)
    seed = seed or 0

    local FNV_OFFSET_BASIS = 0x811C9DC5
    local FNV_PRIME = 0x01000193

    local hash = bit.bxor(FNV_OFFSET_BASIS, seed)

    if size == 1 then --- @cast data number
        hash = bit.bxor(hash, data)
        hash = bit.band(hash * FNV_PRIME, 0xFFFFFFFF)
    else
        size = size or #data
        local _data
        for i = 1, size do
            _data = data[i]
            hash = bit.bxor(hash, _data)
            hash = bit.band(hash * FNV_PRIME, 0xFFFFFFFF)
        end
    end

    assert(hash ~= 0, "ImHashData = 0!")

    return hash
end

-- Use FNV1a, as one ImGui FIXME suggested
--- @param str string
--- @param seed int?
--- @return int
function ImHashStr(str, seed)
    local len = #str
    local data = {string.byte(str, 1, len)}
    return ImHashData(data, len, seed)
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
    window.Pos = main_viewport.Pos + ImVec2(60, 60)
    window.SizeFull = ImVec2(0, 0)
    window.Size = ImVec2(0, 0)
    window.SetWindowPosAllowFlags = bit.bor(ImGuiCond.Always, ImGuiCond.Once, ImGuiCond.FirstUseEver, ImGuiCond.Appearing)
    window.SetWindowSizeAllowFlags = window.SetWindowPosAllowFlags
    window.SetWindowCollapsedAllowFlags = window.SetWindowPosAllowFlags

    if settings ~= nil then
        SetWindowConditionAllowFlags(window, ImGuiCond.FirstUseEver, false)
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

--- @param id ImGuiID
function ImGui.KeepAliveID(id)
    local g = GImGui

    if g.ActiveId == id then
        g.ActiveIdIsAlive = id
    end

    if g.DeactivatedItemData.ID == id then
        g.DeactivatedItemData.IsAlive = true
    end
end

--- @param r_min  ImVec2
--- @param r_max  ImVec2
--- @param clip?  bool
local function IsMouseHoveringRect(r_min, r_max, clip)
    if clip == nil then clip = true end

    local g = GImGui

    local rect_clipped = ImRect(r_min, r_max)
    if clip then
        rect_clipped:ClipWith(g.CurrentWindow.ClipRect)
    end

    if not rect_clipped:ContainsWithPad(g.IO.MousePos, g.Style.TouchExtraPadding) then
        return false
    end

    return true
end

--- @param bb           ImRect
--- @param id           ImGuiID
--- @param nav_bb_arg?  ImRect
--- @param extra_flags? ImGuiItemFlags
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

    g.NextItemData.HasFlags = ImGuiNextItemDataFlags.None
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

--- @param size             ImVec2
--- @param text_baseline_y? float
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
    if (window.DC.LayoutType == ImGuiLayoutType.Horizontal) then
        ImGui.SameLine()
    end
end

--- @param bb              ImRect
--- @param text_baseline_y float
function ImGui.ItemSizeR(bb, text_baseline_y)
    ImGui.ItemSize(bb:GetSize(), text_baseline_y)
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

--- @param indent_w float
function ImGui.Indent(indent_w)
    local g = GImGui
    local window = ImGui.GetCurrentWindow()

    if indent_w ~= 0.0 then
        window.DC.Indent.x = window.DC.Indent.x + indent_w
    else
        window.DC.Indent.x = window.DC.Indent.x + g.Style.IndentSpacing
    end

    window.DC.CursorPos.x = window.Pos.x + window.DC.Indent.x + window.DC.ColumnsOffset.x
end

--- @param indent_w float
function ImGui.Unindent(indent_w)
    local g = GImGui
    local window = ImGui.GetCurrentWindow()

    if indent_w ~= 0.0 then
        window.DC.Indent.x = window.DC.Indent.x - indent_w
    else
        window.DC.Indent.x = window.DC.Indent.x - g.Style.IndentSpacing
    end

    window.DC.CursorPos.x = window.Pos.x + window.DC.Indent.x + window.DC.ColumnsOffset.x
end

--- @return float
function ImGui.GetFrameHeight()
    local g = GImGui
    return g.FontSize + g.Style.FramePadding.y * 2.0
end

--- @return ImVec2
--- @nodiscard
function ImGui.GetContentRegionAvail()
    local g = GImGui
    local window = g.CurrentWindow

    local mx
    if window.DC.CurrentColumns or g.CurrentTable then
        mx = window.WorkRect.Max
    else
        mx = window.ContentRegionRect.Max
    end

    return ImVec2(mx.x - window.DC.CursorPos.x, mx.y - window.DC.CursorPos.y)
end

function ImGui.CalcItemWidth()
    local g = GImGui
    local window = g.CurrentWindow

    local w
    if bit.band(g.NextItemData.HasFlags, ImGuiNextItemDataFlags.HasWidth) ~= 0 then
        w = g.NextItemData.Width
    else
        w = window.DC.ItemWidth
    end

    if w < 0.0 then
        local region_avail_x = ImGui.GetContentRegionAvail().x
        w = ImMax(1.0, region_avail_x + w)
    end

    w = IM_TRUNC(w)
    return w
end

--- @param size      ImVec2
--- @param default_w float
--- @param default_h float
--- @return ImVec2
function ImGui.CalcItemSize(size, default_w, default_h)
    local avail
    if size.x < 0.0 or size.y < 0.0 then
        avail = ImGui.GetContentRegionAvail()
    end

    if size.x == 0.0 then
        size.x = default_w
    elseif size.x < 0.0 then
        size.x = ImMax(4.0, avail.x + size.x)  -- size.x is negative here so we are subtracting
    end

    if size.y == 0.0 then
        size.y = default_h
    elseif size.y < 0.0 then
        size.y = ImMax(4.0, avail.y + size.y)  -- size.y is negative here so we are subtracting
    end

    return size
end

function ImGui.GetTextLineHeight()
    local g = GImGui
    return g.FontSize
end

function ImGui.IsItemActive()
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
function ImGui.SetFocusID(id, window)
    local g = GImGui
    IM_ASSERT(id ~= 0)
    -- TODO:
end

function ImGui.StopMouseMovingWindow()
    GImGui.MovingWindow = nil
end

--- @param id      ImGuiID
--- @param window? ImGuiWindow
function ImGui.SetActiveID(id, window)
    local g = GImGui

    if g.ActiveId ~= 0 then
        g.DeactivatedItemData.ID = g.ActiveId
        if g.LastItemData.ID == g.ActiveId then
            g.DeactivatedItemData.ElapseFrame = g.FrameCount
        else
            g.DeactivatedItemData.ElapseFrame = g.FrameCount + 1
        end
        g.DeactivatedItemData.HasBeenEditedBefore = g.ActiveIdHasBeenEditedBefore
        g.DeactivatedItemData.IsAlive = (g.ActiveIdIsAlive == g.ActiveId)

        if g.MovingWindow and (g.ActiveId == g.MovingWindow.MoveId) then
            print("SetActiveID() cancel MovingWindow")
            ImGui.StopMouseMovingWindow()
        end
    end

    g.ActiveIdIsJustActivated = (g.ActiveId ~= id)
    if (g.ActiveIdIsJustActivated) then
        -- IMGUI_DEBUG_LOG_ACTIVEID("SetActiveID() old:0x%08X (window \"%s\") -> new:0x%08X (window \"%s\")\n", g.ActiveId, g.ActiveIdWindow ? g.ActiveIdWindow->Name : "", id, window ? window->Name : "")
        g.ActiveIdTimer = 0.0
        g.ActiveIdHasBeenPressedBefore = false
        g.ActiveIdHasBeenEditedBefore = false
        g.ActiveIdMouseButton = -1

        if id ~= 0 then
            g.LastActiveId = id
            g.LastActiveIdTimer = 0.0
        end
    end
    g.ActiveId = id
    g.ActiveIdAllowOverlap = false
    g.ActiveIdNoClearOnFocusLoss = false
    g.ActiveIdWindow = window
    g.ActiveIdHasBeenEditedThisFrame = false
    g.ActiveIdFromShortcut = false
    g.ActiveIdDisabledId = 0
    if id ~= 0 then
        g.ActiveIdIsAlive = id
        if g.NavActivateId == id or g.NavJustMovedToId == id then
            g.ActiveIdSource = g.NavInputSource
        else
            g.ActiveIdSource = ImGuiInputSource_Mouse
        end
        IM_ASSERT(g.ActiveIdSource ~= ImGuiInputSource_None)
    end

    g.ActiveIdUsingNavDirMask = 0x00
    g.ActiveIdUsingAllKeyboardKeys = false
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

--- @param id string|int
--- @return ImGuiID
function MT.ImGuiWindow:GetID(id)
    local seed = self.IDStack:back()
    local t = type(id)

    if t == "string" then
        return ImHashStr(id, seed)
    elseif t == "number" then
        return ImHashData(id, 1, seed)
    else
        error("GetID: expected string or number, got " .. t)
    end
end

--- @param id ImGuiID
function ImGui.SetHoveredID(id)
    local g = GImGui
    g.HoveredId = id
    g.HoveredIdAllowOverlap = false
    if id ~= 0 and g.HoveredIdPreviousFrame ~= id then
        g.HoveredIdTimer = 0.0
        g.HoveredIdNotActiveTimer = 0.0
    end
end

--- @param user_flags   ImGuiHoveredFlags
--- @param shared_flags ImGuiHoveredFlags
local function ApplyHoverFlagsForTooltip(user_flags, shared_flags)
    if bit.band(user_flags, bit.bor(ImGuiHoveredFlags_DelayNone, ImGuiHoveredFlags_DelayShort, ImGuiHoveredFlags_DelayNormal)) ~= 0 then
        shared_flags = bit.band(shared_flags, bit.bnot(bit.bor(ImGuiHoveredFlags_DelayNone, ImGuiHoveredFlags_DelayShort, ImGuiHoveredFlags_DelayNormal)))
    end
    return bit.bor(user_flags, shared_flags)
end

--- @param window ImGuiWindow
--- @param flags  ImGuiHoveredFlags
function ImGui.IsWindowContentHoverable(window, flags)
    -- An active popup disable hovering on other windows (apart from its own children)
    -- FIXME-OPT: This could be cached/stored within the window.
    local g = GImGui
    if g.NavWindow then
        local focused_root_window = g.NavWindow.RootWindow
        if focused_root_window.WasActive and focused_root_window ~= window.RootWindow then
            -- For the purpose of those flags we differentiate "standard popup" from "modal popup"
            -- NB: The 'else' is important because Modal windows are also Popups.
            local want_inhibit = false
            if bit.band(focused_root_window.Flags, ImGuiWindowFlags_Modal) ~= 0 then
                want_inhibit = true
            elseif (bit.band(focused_root_window.Flags, ImGuiWindowFlags_Popup) ~= 0) and (bit.band(flags, ImGuiHoveredFlags_AllowWhenBlockedByPopup) == 0) then
                want_inhibit = true
            end

            -- Inhibit hover unless the window is within the stack of our modal/popup
            if want_inhibit then
                if not ImGui.IsWindowWithinBeginStackOf(window.RootWindow, focused_root_window) then
                    return false
                end
            end
        end
    end
    return true
end

--- @param flags ImGuiHoveredFlags
function ImGui.IsItemHovered(flags) -- TODO: there are things not implmeneted here
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

--- @param bb         ImRect
--- @param id         ImGuiID
--- @param item_flags ImGuiItemFlags
function ImGui.ItemHoverable(id, bb, item_flags)
    local g = GImGui

    local window = g.CurrentWindow

    if g.HoveredWindow ~= window then
        return false
    end

    if not IsMouseHoveringRect(bb.Min, bb.Max) then
        return false
    end

    if g.HoveredId ~= 0 and g.HoveredId ~= id and not g.HoveredIdAllowOverlap then
        return false
    end

    if g.ActiveId ~= 0 and g.ActiveId ~= id and not g.ActiveIdAllowOverlap then
        if not g.ActiveIdFromShortcut then
            return false
        end
    end

    if (bit.band(item_flags, ImGuiItemFlags_NoWindowHoverableCheck) == 0) and not ImGui.IsWindowContentHoverable(window, ImGuiHoveredFlags_None) then
        g.HoveredIdIsDisabled = true
        return false
    end

    if id ~= 0 then
        if g.DragDropActive and g.DragDropPayload.SourceId == id and (bit.band(g.DragDropSourceFlags, ImGuiDragDropFlags_SourceNoDisableHover) == 0) then
            return false
        end

        ImGui.SetHoveredID(id)

        if bit.band(item_flags, ImGuiItemFlags_AllowOverlap) ~= 0 then
            g.HoveredIdAllowOverlap = true
            if g.HoveredIdPreviousFrame ~= id then
                return false
            end
        end

        if id == g.LastItemData.ID and (bit.band(g.LastItemData.StatusFlags, ImGuiItemStatusFlags_HasShortcut) ~= 0) and g.ActiveId ~= id then
            if ImGui.IsItemHovered(bit.bor(ImGuiHoveredFlags_ForTooltip, ImGuiHoveredFlags_DelayNormal)) then
                ImGui.SetTooltip("%s", ImGui.GetKeyChordName(g.LastItemData.Shortcut))
            end
        end
    end

    if bit.band(item_flags, ImGuiItemFlags_Disabled) ~= 0 then
        -- Release active id if turning disabled
        if g.ActiveId == id and id ~= 0 then
            ImGui.ClearActiveID()
        end
        g.HoveredIdIsDisabled = true
        return false
    end

    if g.NavHighlightItemUnderNav and (bit.band(item_flags, ImGuiItemFlags_NoNavDisableMouseHover) == 0) then
        return false
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
            goto CONTINUE
        end

        local key_data = g.IO.KeysData[key - ImGuiKey_NamedKey_BEGIN]
        key_data.Down = false
        key_data.DownDuration = -1.0
        key_data.DownDurationPrev = -1.0

        :: CONTINUE ::
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
        if type == ImGuiInputEventType.Key and e.Key.Key ~= arg then
            continue
        end
        if type == ImGuiInputEventType.MouseButton and e.MouseButton.Button ~= arg then
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

    local latest_event = self:FindLatestInputEvent(g, ImGuiInputEventType.Key, key)
    local key_data = ImGui.GetKeyData(g, key)
    local latest_key_down = latest_event and latest_event.Key.Down or key_data.Down
    local latest_key_analog = latest_event and latest_event.Key.AnalogValue or key_data.AnalogValue
    if latest_key_down == down and latest_key_analog == analog_value then
        return
    end

    local e = ImGuiInputEvent()
    e.Type = ImGuiInputEventType.Key
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

--- @param source ImGuiMouseSource
function MT.ImGuiIO:AddMouseSourceEvent(source)
    IM_ASSERT(self.Ctx ~= nil)
    local g = self.Ctx
    g.InputEventsNextMouseSource = source
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

    local latest_event = self:FindLatestInputEvent(g, ImGuiInputEventType.MousePos)
    local latest_pos = latest_event and ImVec2(latest_event.MousePos.PosX, latest_event.MousePos.PosY) or self.MousePos
    if latest_pos.x == x_val and latest_pos.y == y_val then
        return
    end

    local e = ImGuiInputEvent()
    e.Type = ImGuiInputEventType.MousePos
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

    local latest_event = self:FindLatestInputEvent(g, ImGuiInputEventType.MouseButton, mouse_button)
    local latest_button_down = latest_event and latest_event.MouseButton.Down or self.MouseDown[mouse_button]
    if latest_button_down == down then
        return
    end

    -- On MacOS X: Convert Ctrl(Super)+Left click into Right-click.
    -- - Note that this is actual physical Ctrl which is ImGuiMod_Super for us.
    -- - At this point we want from !down to down, so this is handling the initial press.
    if self.ConfigMacOSXBehaviors and mouse_button == 0 and down then
        local latest_super_event = self:FindLatestInputEvent(g, ImGuiInputEventType.Key, ImGuiMod_Super)
        if latest_super_event and latest_super_event.Key.Down or self.KeySuper then
            -- IMGUI_DEBUG_LOG_IO("[io] Super+Left Click aliased into Right Click\n")
            self.MouseCtrlLeftAsRightClick = true
            self:AddMouseButtonEvent(1, true) -- This is just quicker to write that passing through, as we need to filter duplicate again.
            return
        end
    end

    local e = ImGuiInputEvent()
    e.Type = ImGuiInputEventType.MouseButton
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
    e.Type = ImGuiInputEventType.MouseWheel
    e.Source = ImGuiInputSource_Mouse
    e.EventId = g.InputEventsNextEventId
    g.InputEventsNextEventId = g.InputEventsNextEventId + 1
    e.MouseWheel = ImGuiInputEventMouseWheel()
    e.MouseWheel.WheelX = wheel_x
    e.MouseWheel.WheelY = wheel_y
    e.MouseWheel.MouseSource = g.InputEventsNextMouseSource
    g.InputEventsQueue:push_back(e)
end

--- @param ctx? ImGuiContext
--- @param key  ImGuiKey
--- @return ImGuiKeyData
function ImGui.GetKeyData(ctx, key)
    if ctx == nil then ctx = GImGui end

    if bit.band(key, ImGuiMod_Mask_) ~= 0 then
        key = ImGui.ConvertSingleModFlagToKey(key)
    end

    IM_ASSERT(ImGui.IsNamedKey(key), "Support for user key indices was dropped in favor of ImGuiKey. Please update backend & user code.")
    return ctx.IO.KeysData[key - ImGuiKey_NamedKey_BEGIN]
end

--- @param key      ImGuiKey
--- @param owner_id ImGuiID
--- @param flags?   ImGuiInputFlags
function ImGui.SetKeyOwner(key, owner_id, flags)
    if flags == nil then flags = 0 end

    local g = GImGui --- @cast g ImGuiContext
    IM_ASSERT(ImGui.IsNamedKeyOrMod(key) and (owner_id ~= ImGuiKeyOwner_Any or (bit.band(flags, bit.bor(ImGuiInputFlags_LockThisFrame, ImGuiInputFlags_LockUntilRelease)) ~= 0)), "Can only use _Any with _LockXXX flags (to eat a key away without an ID to retrieve it)")
    IM_ASSERT(bit.band(flags, bit.bnot(ImGuiInputFlags_SupportedBySetKeyOwner)) == 0, "Passing flags not supported by this function!")

    local owner_data = ImGui.GetKeyOwnerData(g, key)
    owner_data.OwnerCurr = owner_id
    owner_data.OwnerNext = owner_id

    owner_data.LockUntilRelease = (bit.band(flags, ImGuiInputFlags_LockUntilRelease) ~= 0)
    owner_data.LockThisFrame = (bit.band(flags, ImGuiInputFlags_LockThisFrame) ~= 0) or owner_data.LockUntilRelease
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

--- @param key       ImGuiKey
--- @param owner_id? ImGuiID
function ImGui.IsKeyDown(key, owner_id)
    if owner_id == nil then owner_id = ImGuiKeyOwner_Any end

    local key_data = ImGui.GetKeyData(nil, key)
    if not key_data.Down then
        return false
    end
    if not ImGui.TestKeyOwner(key, owner_id) then
        return false
    end
    return true
end

-- TODO:
function ImGui.GetKeyChordName(key_chord)
    error("NOT IMPLEMENTED", 2)
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

--- @param mouse_pos? ImVec2
function ImGui.IsMousePosValid(mouse_pos)
    local MOUSE_INVALID = -256000.0
    local p
    if mouse_pos then p = mouse_pos else p = GImGui.IO.MousePos end
    return p.x >= MOUSE_INVALID and p.y >= MOUSE_INVALID
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

--- @param trickle_fast_inputs bool
function ImGui.UpdateInputEvents(trickle_fast_inputs)
    local g = GImGui
    local io = g.IO

    local trickle_interleaved_nonchar_keys_and_text = trickle_fast_inputs and g.WantTextInputNextFrame == 1

    local mouse_moved          = false
    local mouse_wheeled        = false
    local key_changed          = false
    local key_changed_nonchar  = false
    local text_inputted        = false
    local mouse_button_changed = 0x00

    local event_n = 1
    while event_n <= g.InputEventsQueue.Size do
        local e = g.InputEventsQueue.Data[event_n]
        if e.Type == ImGuiInputEventType.MousePos then
            if g.IO.WantSetMousePos then
                continue
            end
            if trickle_fast_inputs and (mouse_button_changed ~= 0 or mouse_wheeled or key_changed or text_inputted) then
                break
            end
            local event_pos = ImVec2(e.MousePos.PosX, e.MousePos.PosY)
            io.MousePos =  event_pos
            io.MouseSource = e.MousePos.MouseSource
            mouse_moved = true
        elseif e.Type == ImGuiInputEventType.MouseButton then
            local button = e.MouseButton.Button
            IM_ASSERT(button >= 0 and button < ImGuiMouseButton_COUNT)
            if trickle_fast_inputs and ((bit.band(mouse_button_changed, bit.lshift(1, button)) ~= 0) or mouse_wheeled) then
                break
            end
            if trickle_fast_inputs and e.MouseButton.MouseSource == ImGuiMouseSource_TouchScreen and mouse_moved then
                break
            end

            io.MouseDown[button] = e.MouseButton.Down
            io.MouseSource = e.MouseButton.MouseSource
            mouse_button_changed = bit.bor(mouse_button_changed, bit.lshift(1, button))
        end

        event_n = event_n + 1
    end

    if event_n == g.InputEventsQueue.Size + 1 then
        g.InputEventsQueue:resize(0)
    else
        for i = 1, event_n - 1 do
            g.InputEventsQueue:erase(1)
        end
    end
end

--- @param window ImGuiWindow
--- @return bool
local function IsWindowActiveAndVisible(window)
    return window.Active and not window.Hidden
end

--- @param window ImGuiWindow
--- @nodiscard
local function CalcWindowMinSize(window)
    local g = GImGui

    local size_min = ImVec2()

    if (bit.band(window.Flags, ImGuiWindowFlags_ChildWindow) ~= 0) and (bit.band(window.Flags, ImGuiWindowFlags_Popup) == 0) then
        if bit.band(window.ChildFlags, ImGuiChildFlags_ResizeX) ~= 0 then
            size_min.x = g.Style.WindowMinSize.x
        else
            size_min.x = IMGUI_WINDOW_HARD_MIN_SIZE
        end

        if bit.band(window.ChildFlags, ImGuiChildFlags_ResizeY) ~= 0 then
            size_min.y = g.Style.WindowMinSize.y
        else
            size_min.y = IMGUI_WINDOW_HARD_MIN_SIZE
        end
    else
        if bit.band(window.Flags, ImGuiWindowFlags_AlwaysAutoResize) == 0 then
            size_min.x = g.Style.WindowMinSize.x
        else
            size_min.x = IMGUI_WINDOW_HARD_MIN_SIZE
        end

        if bit.band(window.Flags, ImGuiWindowFlags_AlwaysAutoResize) == 0 then
            size_min.y = g.Style.WindowMinSize.y
        else
            size_min.y = IMGUI_WINDOW_HARD_MIN_SIZE
        end
    end

    local window_for_height = window
    size_min.y = ImMax(size_min.y, window_for_height.TitleBarHeight + window_for_height.MenuBarHeight + ImMax(0, g.Style.WindowRounding - 1))

    return size_min
end

--- @param window       ImGuiWindow
--- @param size_desired ImVec2
--- @return ImVec2
--- @nodiscard
local function CalcWindowSizeAfterConstraint(window, size_desired)
    local g = GImGui
    local new_size = size_desired:copy()
    if bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasSizeConstraint) ~= 0 then
        local cr = g.NextWindowData.SizeConstraintRect:copy()
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
    return ImMaxVec2(new_size, size_min)
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
        return ImMinVec2(size_desired, size_max)
    else
        local size_min = CalcWindowMinSize(window)
        local size_auto_fit = ImClampV2(size_desired, ImMinVec2(size_min, size_max), size_max)

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

--- @param window ImGuiWindow
--- @return ImGuiCol
local function GetWindowBgColorIdx(window)
    if bit.band(window.Flags, bit.bor(ImGuiWindowFlags_Tooltip, ImGuiWindowFlags_Popup)) ~= 0 then
        return ImGuiCol.PopupBg
    elseif bit.band(window.Flags, ImGuiWindowFlags_ChildWindow) ~= 0 then
        return ImGuiCol.ChildBg
    else
        return ImGuiCol.WindowBg
    end
end

--- @param window            ImGuiWindow
--- @param corner_target_arg ImVec2
--- @param corner_norm       ImVec2
--- @return ImVec2, ImVec2
--- @nodiscard
local function CalcResizePosSizeFromAnyCorner(window, corner_target_arg, corner_norm)
    local corner_target = corner_target_arg:copy()
    if bit.band(window.Flags, ImGuiWindowFlags_ChildWindow) ~= 0 then
        local parent_window = window.ParentWindow
        local parent_flags = parent_window.Flags
        local limit_rect = parent_window.InnerRect
        limit_rect:ExpandV2(ImVec2(-ImMax(parent_window.WindowPadding.x, parent_window.WindowBorderSize), -ImMax(parent_window.WindowPadding.y, parent_window.WindowBorderSize)))

        if (bit.band(parent_flags, bit.bor(ImGuiWindowFlags_HorizontalScrollbar, ImGuiWindowFlags_AlwaysHorizontalScrollbar)) == 0) or (bit.band(parent_flags, ImGuiWindowFlags_NoScrollbar) ~= 0) then
            corner_target.x = ImClamp(corner_target.x, limit_rect.Min.x, limit_rect.Max.x)
        end
        if bit.band(parent_flags, ImGuiWindowFlags_NoScrollbar) ~= 0 then
            corner_target.y = ImClamp(corner_target.y, limit_rect.Min.y, limit_rect.Max.y)
        end
    end
    local pos_min = ImLerpV2V2V2(corner_target, window.Pos, corner_norm)
    local pos_max = ImLerpV2V2V2(window.Pos + window.Size, corner_target, corner_norm)
    local size_expected = pos_max - pos_min
    local size_constrained = CalcWindowSizeAfterConstraint(window, size_expected)

    local out_pos = pos_min
    if corner_norm.x == 0.0 then
        out_pos.x = out_pos.x - (size_constrained.x - size_expected.x)
    end
    if corner_norm.y == 0.0 then
        out_pos.y = out_pos.y - (size_constrained.y - size_expected.y)
    end

    return out_pos, size_constrained
end

--- @param window            ImGuiWindow
--- @param resize_grip_count int
--- @param resize_grip_col   table
--- @param visibility_rect   ImRect
--- @return int, int, int
local function UpdateWindowManualResize(window, resize_grip_count, resize_grip_col, visibility_rect)
    local g = GImGui
    local flags = window.Flags

    if (bit.band(flags, ImGuiWindowFlags_NoResize) ~= 0 or window.AutoFitFramesX > 0 or window.AutoFitFramesY > 0) then
        return 0, -1, -1
    end
    if (bit.band(flags, ImGuiWindowFlags_AlwaysAutoResize) ~= 0 and bit.band(window.ChildFlags, bit.bor(ImGuiChildFlags_ResizeX, ImGuiChildFlags_ResizeY)) == 0) then
        return 0, -1, -1
    end
    if window.WasActive == false then
        return 0, -1, -1
    end

    local border_hovered = -1
    local border_held = -1

    local ret_auto_fit_mask = 0x00
    local grip_draw_size = IM_TRUNC(ImMax(g.FontSize * 1.35, g.Style.WindowRounding + 1.0 + g.FontSize * 0.2))
    local grip_hover_inner_size = (resize_grip_count > 0) and IM_TRUNC(grip_draw_size * 0.75) or 0.0
    local grip_hover_outer_size = g.WindowsBorderHoverPadding + 1

    ImGui.PushID("#RESIZE")

    local pos_target = ImVec2(FLT_MAX, FLT_MAX)
    local size_target = ImVec2(FLT_MAX, FLT_MAX)

    local clamp_rect = visibility_rect:copy()
    local window_move_from_title_bar = (bit.band(window.BgClickFlags, ImGuiWindowBgClickFlags.Move) == 0) and (bit.band(window.Flags, ImGuiWindowFlags_NoTitleBar) == 0)
    if window_move_from_title_bar then
        clamp_rect.Min.y = clamp_rect.Min.y - window.TitleBarHeight
    end

    for resize_grip_n = 0, resize_grip_count - 1 do
        local def = ImGuiResizeGripDef[resize_grip_n + 1]
        local corner_pos = def.CornerPosN
        local inner_dir = def.InnerDir

        local corner = ImVec2(window.Pos.x + corner_pos.x * window.Size.x, window.Pos.y + corner_pos.y * window.Size.y)

        local resize_rect = ImRect(corner - inner_dir * grip_hover_outer_size, corner + inner_dir * grip_hover_inner_size)

        if resize_rect.Min.x > resize_rect.Max.x then resize_rect.Min.x, resize_rect.Max.x = resize_rect.Max.x, resize_rect.Min.x end
        if resize_rect.Min.y > resize_rect.Max.y then resize_rect.Min.y, resize_rect.Max.y = resize_rect.Max.y, resize_rect.Min.y end

        local resize_grip_id = window:GetID(resize_grip_n)

        ImGui.ItemAdd(resize_rect, resize_grip_id, nil, ImGuiItemFlags_NoNav)
        local _, hovered, held = ImGui.ButtonBehavior(resize_rect, resize_grip_id, bit.bor(ImGuiButtonFlags_FlattenChildren, ImGuiButtonFlags_NoNavFocus))

        if hovered or held then
            if bit.band(resize_grip_n, 1) ~= 0 then
                ImGui.SetMouseCursor(ImGuiMouseCursor.ResizeNESW)
            else
                ImGui.SetMouseCursor(ImGuiMouseCursor.ResizeNWSE)
            end
        end

        if held and g.IO.MouseDoubleClicked[0] then
            local size_auto_fit = CalcWindowAutoFitSize(window, window.ContentSizeIdeal, -1)
            size_target = CalcWindowSizeAfterConstraint(window, size_auto_fit)
            ret_auto_fit_mask = 0x03
            ImGui.ClearActiveID()
        elseif held then
            local clamp_min = ImVec2((corner_pos.x == 1.0) and clamp_rect.Min.x or -FLT_MAX, (corner_pos.y == 1.0) and clamp_rect.Min.y or -FLT_MAX)
            local clamp_max = ImVec2((corner_pos.x == 0.0) and clamp_rect.Max.x or FLT_MAX, (corner_pos.y == 0.0) and clamp_rect.Max.y or FLT_MAX)
            local corner_target = g.IO.MousePos - g.ActiveIdClickOffset + ImLerpV2V2V2(def.InnerDir * grip_hover_outer_size, def.InnerDir * -grip_hover_inner_size, def.CornerPosN)

            corner_target = ImClampV2(corner_target, clamp_min, clamp_max)

            pos_target, size_target = CalcResizePosSizeFromAnyCorner(window, corner_target, corner_pos)
        end

        local resize_grip_visible = held or hovered or (resize_grip_n == 0 and bit.band(window.Flags, ImGuiWindowFlags_ChildWindow) == 0)
        if resize_grip_visible then
            local color
            if held then
                color = ImGui.GetColorU32(ImGuiCol.ResizeGripActive)
            else
                if hovered then
                    color = ImGui.GetColorU32(ImGuiCol.ResizeGripHovered)
                else
                    color = ImGui.GetColorU32(ImGuiCol.ResizeGrip)
                end
            end
            resize_grip_col[resize_grip_n + 1] = color
        end
    end

    local resize_border_mask = 0x00
    if bit.band(window.Flags, ImGuiWindowFlags_ChildWindow) ~= 0 then
        local mask_x = (bit.band(window.ChildFlags, ImGuiChildFlags_ResizeX) ~= 0) and 0x02 or 0
        local mask_y = (bit.band(window.ChildFlags, ImGuiChildFlags_ResizeY) ~= 0) and 0x08 or 0
        resize_border_mask = bit.bor(mask_x, mask_y)
    else
        resize_border_mask = g.IO.ConfigWindowsResizeFromEdges and 0x0F or 0x00
    end
    for border_n = 0, 3 do
        if bit.band(resize_border_mask, bit.lshift(1, border_n)) == 0 then
            continue
        end
        local def = ImGuiResizeBorderDef[border_n + 1]
        local axis
        if border_n == ImGuiDir.Left or border_n == ImGuiDir.Right then
            axis = ImGuiAxis.X
        else
            axis = ImGuiAxis.Y
        end

        local border_rect = GetResizeBorderRect(window, border_n, grip_hover_inner_size, g.WindowsBorderHoverPadding)
        local border_id = window:GetID(border_n + 4)
        ImGui.ItemAdd(border_rect, border_id, nil, ImGuiItemFlags_NoNav)
        local _, hovered, held = ImGui.ButtonBehavior(border_rect, border_id, bit.bor(ImGuiButtonFlags_FlattenChildren, ImGuiButtonFlags_NoNavFocus))

        if hovered and g.HoveredIdTimer <= WINDOWS_RESIZE_FROM_EDGES_FEEDBACK_TIMER then
            hovered = false
        end
        if hovered or held then
            if axis == ImGuiAxis.X then
                ImGui.SetMouseCursor(ImGuiMouseCursor.ResizeEW)
            else
                ImGui.SetMouseCursor(ImGuiMouseCursor.ResizeNS)
            end
        end
        if held and g.IO.MouseDoubleClicked[0] then
            -- Double-clicking bottom or right border auto-fit on this axis
            -- FIXME: Support top and right borders: rework CalcResizePosSizeFromAnyCorner() to be reusable in both cases.
            if border_n == 1 or border_n == 3 then  -- Right and bottom border
                local size_auto_fit = CalcWindowAutoFitSize(window, window.ContentSizeIdeal, bit.lshift(1, axis))
                if axis == 0 then
                    size_target.x = CalcWindowSizeAfterConstraint(window, size_auto_fit).x
                elseif axis == 1 then
                    size_target.y = CalcWindowSizeAfterConstraint(window, size_auto_fit).y
                end

                ret_auto_fit_mask = bit.bor(ret_auto_fit_mask, bit.lshift(1, axis))
                hovered = false
                held = false  -- So border doesn't show highlighted at new position
            end
            ImGui.ClearActiveID()
        elseif held then
            local just_scrolled_manually_while_resizing = (g.WheelingWindow ~= nil and g.WheelingWindowScrolledFrame == g.FrameCount and ImGui.IsWindowChildOf(window, g.WheelingWindow, false))
            if g.ActiveIdIsJustActivated or just_scrolled_manually_while_resizing then
                g.WindowResizeBorderExpectedRect = border_rect
                g.WindowResizeRelativeMode = false
            end

            if (bit.band(window.Flags, ImGuiWindowFlags_ChildWindow) ~= 0) and g.WindowResizeBorderExpectedRect ~= border_rect then
                g.WindowResizeRelativeMode = true
            end

            local border_curr = window.Pos + ImMinVec2(def.SegmentN1, def.SegmentN2) * window.Size
            local border_target_rel_mode_for_axis
            local border_target_abs_mode_for_axis
            if axis == 0 then
                border_target_rel_mode_for_axis = border_curr.x + g.IO.MouseDelta.x
                border_target_abs_mode_for_axis = g.IO.MousePos.x - g.ActiveIdClickOffset.x + g.WindowsBorderHoverPadding
            elseif axis == 1 then
                border_target_rel_mode_for_axis = border_curr.y + g.IO.MouseDelta.y
                border_target_abs_mode_for_axis = g.IO.MousePos.y - g.ActiveIdClickOffset.y + g.WindowsBorderHoverPadding
            end

            -- Use absolute mode position
            local border_target = window.Pos:copy()
            if axis == 0 then
                border_target.x = border_target_abs_mode_for_axis
            elseif axis == 1 then
                border_target.y = border_target_abs_mode_for_axis
            end

            -- Use relative mode target for child window, ignore resize when moving back toward the ideal absolute position.
            local ignore_resize = false
            if g.WindowResizeRelativeMode then
                if axis == 0 then
                    border_target.x = border_target_rel_mode_for_axis
                    if g.IO.MouseDelta.x == 0.0 or ((g.IO.MouseDelta.x > 0.0) == (border_target_rel_mode_for_axis > border_target_abs_mode_for_axis)) then
                        ignore_resize = true
                    end
                elseif axis == 1 then
                    border_target.y = border_target_rel_mode_for_axis
                    if g.IO.MouseDelta.y == 0.0 or ((g.IO.MouseDelta.y > 0.0) == (border_target_rel_mode_for_axis > border_target_abs_mode_for_axis)) then
                        ignore_resize = true
                    end
                end
            end

            local clamp_min = ImVec2((border_n == ImGuiDir.Right) and clamp_rect.Min.x or -FLT_MAX, (border_n == ImGuiDir.Down or (border_n == ImGuiDir.Up and window_move_from_title_bar)) and clamp_rect.Min.y or -FLT_MAX)
            local clamp_max = ImVec2((border_n == ImGuiDir.Left) and clamp_rect.Max.x or FLT_MAX, (border_n == ImGuiDir.Up) and clamp_rect.Max.y or FLT_MAX)
            border_target = ImClampV2(border_target, clamp_min, clamp_max)

            if not ignore_resize then
                pos_target, size_target = CalcResizePosSizeFromAnyCorner(window, border_target, ImMinVec2(def.SegmentN1, def.SegmentN2))
            end
        end
        if hovered then
            border_hovered = border_n
        end
        if held then
            border_held = border_n
        end
    end
    ImGui.PopID()

    window.DC.NavLayerCurrent = ImGuiNavLayer.Main

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

    if border_held ~= -1 then
        g.WindowResizeBorderExpectedRect = GetResizeBorderRect(window, border_held, grip_hover_inner_size, g.WindowsBorderHoverPadding)
    end

    return ret_auto_fit_mask, border_hovered, border_held
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
        window.DrawList:AddText(g.Font, g.FontSize, pos, ImGui.GetColorU32(ImGuiCol.Text), text, 1, text_display_end, 0.0)
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

    if text ~= "" then
        window.DrawList:AddText(g.Font, g.FontSize, pos, ImGui.GetColorU32(ImGuiCol.Text), text, 1, text_end, wrap_width)
    end
end

--- @param draw_list           ImDrawList
--- @param pos_min             ImVec2
--- @param pos_max             ImVec2
--- @param text                string
--- @param text_begin          int
--- @param text_display_end    int
--- @param text_size_if_known? ImVec2
--- @param align?              ImVec2
--- @param clip_rect?          ImRect
function ImGui.RenderTextClippedEx(draw_list, pos_min, pos_max, text, text_begin, text_display_end, text_size_if_known, align, clip_rect)
    if not align then align = ImVec2(0, 0) end

    local pos = pos_min:copy()
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
    if (need_clipping) then
        local fine_clip_rect = ImVec4(clip_min.x, clip_min.y, clip_max.x, clip_max.y)
        draw_list:AddText(nil, 0.0, pos, ImGui.GetColorU32(ImGuiCol.Text), text, text_begin, text_display_end, 0.0, fine_clip_rect)
    else
        draw_list:AddText(nil, 0.0, pos, ImGui.GetColorU32(ImGuiCol.Text), text, text_begin, text_display_end, 0.0, nil)
    end
end

--- @param pos_min             ImVec2
--- @param pos_max             ImVec2
--- @param text                string
--- @param text_end?           int
--- @param text_size_if_known? ImVec2
--- @param align?              ImVec2
--- @param clip_rect?          ImRect
function ImGui.RenderTextClipped(pos_min, pos_max, text, text_begin, text_end, text_size_if_known, align, clip_rect)
    if text_begin == nil then text_begin = 1            end
    if not align         then align      = ImVec2(0, 0) end

    local text_display_end = ImGui.FindRenderedTextEnd(text, text_end)
    local text_len = text_display_end - text_begin

    if text_len == 0 then
        return
    end

    local g = GImGui
    local window = g.CurrentWindow
    ImGui.RenderTextClippedEx(window.DrawList, pos_min, pos_max, text, text_begin, text_display_end, text_size_if_known, align, clip_rect)
    -- if (g.LogEnabled)
    --     LogRenderedText(&pos_min, text, text_display_end);
end

--- ImGui::RenderMouseCursor

--- Another overly complex function until we reorganize everything into a nice all-in-one helper.
--- This is made more complex because we have dissociated the layout rectangle (pos_min..pos_max) from 'ellipsis_max_x' which may be beyond it.
--- This is because in the context of tabs we selectively hide part of the text when the Close Button appears, but we don't want the ellipsis to move.
--- @param draw_list           ImDrawList
--- @param pos_min             ImVec2
--- @param pos_max             ImVec2
--- @param ellipsis_max_x      float
--- @param text                string
--- @param text_end_full?      int
--- @param text_size_if_known? ImVec2
function ImGui.RenderTextEllipsis(draw_list, pos_min, pos_max, ellipsis_max_x, text, text_end_full, text_size_if_known)
    local g = GImGui

    if text_end_full == nil then
        text_end_full = ImGui.FindRenderedTextEnd(text)
    end

    local text_size
    if text_size_if_known then
        text_size = text_size_if_known:copy()
    else
        text_size = ImGui.CalcTextSize(text, text_end_full, false, 0.0)
    end

    -- draw_list:AddLine(ImVec2(pos_max.x, pos_min.y - 4), ImVec2(pos_max.x, pos_max.y + 6), IM_COL32(0, 0, 255, 255))
    -- draw_list:AddLine(ImVec2(ellipsis_max_x, pos_min.y - 2), ImVec2(ellipsis_max_x, pos_max.y + 3), IM_COL32(0, 255, 0, 255))

    -- FIXME: We could technically remove (last_glyph->AdvanceX - last_glyph->X1) from text_size.x here and save a few pixels.
    if text_size.x > pos_max.x - pos_min.x then
        -- Hello wo...
        -- |       |   |
        -- min   max   ellipsis_max
        --          <-> this is generally some padding value

        local font = draw_list._Data.Font
        local font_size = draw_list._Data.FontSize
        local font_scale = draw_list._Data.FontScale
        local text_end_ellipsis = nil
        local baked = font:GetFontBaked(font_size)
        local ellipsis_width = baked:GetCharAdvance(font.EllipsisChar) * font_scale

        -- We can now claim the space between pos_max.x and ellipsis_max.x
        local text_avail_width = ImMax((ImMax(pos_max.x, ellipsis_max_x) - ellipsis_width) - pos_min.x, 1.0)
        local text_size_clipped
        text_size_clipped, text_end_ellipsis = font:CalcTextSizeA(font_size, text_avail_width, 0.0, text, 1, text_end_full)
        local text_size_clipped_x = text_size_clipped.x

        while text_end_ellipsis > 1 and ImCharIsBlankA(string.byte(text, text_end_ellipsis - 1)) do
            -- Trim trailing space before ellipsis (FIXME: Supporting non-ascii blanks would be nice, for this we need a function to backtrack in UTF-8 text)
            text_end_ellipsis = text_end_ellipsis - 1
            text_size_clipped_x = text_size_clipped_x - font:CalcTextSizeA(font_size, FLT_MAX, 0.0, text, text_end_ellipsis, text_end_ellipsis + 1).x -- Ascii blanks are always 1 byte
        end

        -- Render text, render ellipsis
        ImGui.RenderTextClippedEx(draw_list, pos_min, pos_max, text, 1, text_end_ellipsis, text_size, ImVec2(0.0, 0.0))
        local cpu_fine_clip_rect = ImVec4(pos_min.x, pos_min.y, pos_max.x, pos_max.y)
        local ellipsis_pos = ImTruncV2(ImVec2(pos_min.x + text_size_clipped_x, pos_min.y))
        font:RenderChar(draw_list, font_size, ellipsis_pos, ImGui.GetColorU32(ImGuiCol.Text), font.EllipsisChar, cpu_fine_clip_rect)
    else
        ImGui.RenderTextClippedEx(draw_list, pos_min, pos_max, text, 1, text_end_full, text_size, ImVec2(0.0, 0.0))
    end

    if g.LogEnabled then
        ImGui.LogRenderedText(pos_min, text, text_end_full)
    end
end

--- @param p_min    ImVec2
--- @param p_max    ImVec2
--- @param fill_col ImU32
--- @param borders  bool
--- @param rounding float
function ImGui.RenderFrame(p_min, p_max, fill_col, borders, rounding)
    if borders  == nil then borders  = true end
    if rounding == nil then rounding = 0.0 end

    local g = GImGui
    local window = g.CurrentWindow

    window.DrawList:AddRectFilled(p_min, p_max, fill_col, rounding)

    local border_size = g.Style.FrameBorderSize
    if borders and border_size > 0 then
        window.DrawList:AddRect(p_min + ImVec2(1, 1), p_max + ImVec2(1, 1), ImGui.GetColorU32(ImGuiCol.BorderShadow), rounding, 0, border_size)
        window.DrawList:AddRect(p_min, p_max, ImGui.GetColorU32(ImGuiCol.Border), rounding, 0, border_size)
    end
end

--- @param window      ImGuiWindow
--- @param border_n    int
--- @param border_col  ImU32
--- @param border_size float
local function RenderWindowOuterSingleBorder(window, border_n, border_col, border_size)
    local def = ImGuiResizeBorderDef[border_n + 1]
    local rounding = window.WindowRounding
    local border_r = GetResizeBorderRect(window, border_n, rounding, 0.0)
    window.DrawList:PathArcTo(ImLerpV2V2V2(border_r.Min, border_r.Max, def.SegmentN1) + ImVec2(0.5, 0.5) + def.InnerDir * rounding, rounding, def.OuterAngle - IM_PI * 0.25, def.OuterAngle)
    window.DrawList:PathArcTo(ImLerpV2V2V2(border_r.Min, border_r.Max, def.SegmentN2) + ImVec2(0.5, 0.5) + def.InnerDir * rounding, rounding, def.OuterAngle, def.OuterAngle + IM_PI * 0.25)
    window.DrawList:PathStroke(border_col, ImDrawFlags_None, border_size)
end

local function RenderWindowOuterBorders(window)
    local g = GImGui
    local border_size = window.WindowBorderSize
    local border_col = ImGui.GetColorU32(ImGuiCol.Border)
    if border_size > 0.0 and (bit.band(window.Flags, ImGuiWindowFlags_NoBackground) == 0) then
        window.DrawList:AddRect(window.Pos, window.Pos + window.Size, border_col, window.WindowRounding, 0, window.WindowBorderSize)
    elseif border_size > 0.0 then
        if bit.band(window.ChildFlags, ImGuiChildFlags_ResizeX) ~= 0 then
            RenderWindowOuterSingleBorder(window, 1, border_col, border_size)
        end
        if bit.band(window.ChildFlags, ImGuiChildFlags_ResizeY) ~= 0 then
            RenderWindowOuterSingleBorder(window, 3, border_col, border_size)
        end
    end

    if window.ResizeBorderHovered ~= -1 or window.ResizeBorderHeld ~= -1 then
        local border_n = (window.ResizeBorderHeld ~= -1) and window.ResizeBorderHeld or window.ResizeBorderHovered
        local border_col_resizing = ImGui.GetColorU32((window.ResizeBorderHeld ~= -1) and ImGuiCol.SeparatorActive or ImGuiCol.SeparatorHovered)
        RenderWindowOuterSingleBorder(window, border_n, border_col_resizing, ImMax(2.0, window.WindowBorderSize))
    end

    if g.Style.FrameBorderSize > 0 and (bit.band(window.Flags, ImGuiWindowFlags_NoTitleBar) == 0) then
        local y = window.Pos.y + window.TitleBarHeight - 1
        window.DrawList:AddLine(ImVec2(window.Pos.x + border_size * 0.5, y), ImVec2(window.Pos.x + window.Size.x - border_size * 0.5, y), border_col, g.Style.FrameBorderSize)
    end
end

--- @param window                          ImGuiWindow
--- @param title_bar_rect                  ImRect
--- @param titlebar_is_highlight           bool
--- @param handle_borders_and_resize_grips bool
--- @param resize_grip_col                 ImU32[]
--- @param resize_grip_draw_size           float
local function RenderWindowDecorations(window, title_bar_rect, titlebar_is_highlight, handle_borders_and_resize_grips, resize_grip_col, resize_grip_draw_size)
    local g = GImGui
    local style = g.Style
    local flags = window.Flags

    local title_color
    if titlebar_is_highlight then
        title_color = ImGui.GetColorU32(ImGuiCol.TitleBgActive)
    else
        title_color = ImGui.GetColorU32(ImGuiCol.TitleBg)
    end

    local border_width = g.Style.FrameBorderSize
    local window_rounding = window.WindowRounding
    local window_border_size = window.WindowBorderSize

    if window.Collapsed then
        local backup_border_size = style.FrameBorderSize
        g.Style.FrameBorderSize = window.WindowBorderSize

        local title_bar_col
        if titlebar_is_highlight and g.NavCursorVisible then
            title_bar_col = ImGui.GetColorU32(ImGuiCol.TitleBgActive)
        else
            title_bar_col = ImGui.GetColorU32(ImGuiCol.TitleBgCollapsed)
        end
        ImGui.RenderFrame(title_bar_rect.Min, title_bar_rect.Max, title_bar_col, true, window_rounding)
        g.Style.FrameBorderSize = backup_border_size
    else
        -- Window background
        if bit.band(flags, ImGuiWindowFlags_NoBackground) == 0 then
            local bg_col = ImGui.GetColorU32(GetWindowBgColorIdx(window))
            local override_alpha = false
            local alpha = 1.0

            if bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasBgAlpha) ~= 0 then
                alpha = g.NextWindowData.BgAlphaVal
                override_alpha = true
            end

            if override_alpha then
                bg_col = bit.band(bg_col, bit.bnot(IM_COL32_A_MASK)) or bit.lshift(IM_F32_TO_INT8_SAT(alpha), IM_COL32_A_SHIFT)
            end

            if bit.band(bg_col, IM_COL32_A_MASK) ~= 0 then
                local bg_rect = ImRect(window.Pos + ImVec2(0, window.TitleBarHeight), window.Pos + window.Size)
                local bg_rounding_flags = (bit.band(flags, ImGuiWindowFlags_NoTitleBar) ~= 0) and 0 or ImDrawFlags_RoundCornersBottom
                local bg_draw_list = window.DrawList
                bg_draw_list:AddRectFilled(bg_rect.Min, bg_rect.Max, bg_col, window_rounding, bg_rounding_flags)
            end
        end

        -- Title bar
        if bit.band(flags, ImGuiWindowFlags_NoTitleBar) == 0 then
            local title_bar_col
            if titlebar_is_highlight then
                title_bar_col = ImGui.GetColorU32(ImGuiCol.TitleBgActive)
            else
                title_bar_col = ImGui.GetColorU32(ImGuiCol.TitleBg)
            end

            window.DrawList:AddRectFilled(title_bar_rect.Min, title_bar_rect.Max, title_bar_col, window_rounding, ImDrawFlags_RoundCornersTop)
        end

        -- TODO: Menu bar

        -- TODO: Scrollbars

        -- Resize grip(s)
        if handle_borders_and_resize_grips and (bit.band(flags, ImGuiWindowFlags_NoResize) == 0) then
            for i = 1, #ImGuiResizeGripDef do
                local col = resize_grip_col[i]
                if bit.band(col, IM_COL32_A_MASK) == 0 then continue end

                local inner_dir = ImGuiResizeGripDef[i].InnerDir
                local corner = window.Pos + ImGuiResizeGripDef[i].CornerPosN * window.Size
                local border_inner = IM_ROUND(window_border_size * 0.5)
                window.DrawList:PathLineTo(corner + inner_dir * ((i % 2 == 0) and ImVec2(border_inner, resize_grip_draw_size) or ImVec2(resize_grip_draw_size, border_inner)))
                window.DrawList:PathLineTo(corner + inner_dir * ((i % 2 == 0) and ImVec2(resize_grip_draw_size, border_inner) or ImVec2(border_inner, resize_grip_draw_size)))
                window.DrawList:PathArcToFast(ImVec2(corner.x + inner_dir.x * (window_rounding + border_inner), corner.y + inner_dir.y * (window_rounding + border_inner)), window_rounding, ImGuiResizeGripDef[i].AngleMin12, ImGuiResizeGripDef[i].AngleMax12)
                window.DrawList:PathFillConvex(col)
            end
        end

        if handle_borders_and_resize_grips then
            RenderWindowOuterBorders(window)
        end
    end

    window.DC.NavLayerCurrent = ImGuiNavLayer.Main
end

--- @param window         ImGuiWindow
--- @param title_bar_rect ImRect
--- @param name           string
--- @param open           bool?
--- @return bool?
local function RenderWindowTitleBarContents(window, title_bar_rect, name, open)
    local g = GImGui
    local style = g.Style
    local flags = window.Flags

    local has_close_button = (open ~= nil)
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
            open = false
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

    return open
end

--- @param window         ImGuiWindow
--- @param flags          ImGuiWindowFlags
--- @param parent_window? ImGuiWindow
function ImGui.UpdateWindowParentAndRootLinks(window, flags, parent_window)
    window.ParentWindow                   = parent_window
    window.RootWindow                     = window
    window.RootWindowPopupTree            = window
    window.RootWindowForTitleBarHighlight = window
    window.RootWindowForNav               = window

    if parent_window and (bit.band(flags, ImGuiWindowFlags_ChildWindow) ~= 0) and (bit.band(flags, ImGuiWindowFlags_Tooltip) == 0) then
        window.RootWindow = parent_window.RootWindow
    end
    if parent_window and (bit.band(flags, ImGuiWindowFlags_Popup) ~= 0) then
        window.RootWindowPopupTree = parent_window.RootWindowPopupTree
    end
    if parent_window and (bit.band(flags, ImGuiWindowFlags_Modal) == 0) and (bit.band(flags, bit.bor(ImGuiWindowFlags_ChildWindow, ImGuiWindowFlags_Popup, ImGuiWindowFlags_Tooltip)) ~= 0) then
        window.RootWindowForTitleBarHighlight = parent_window.RootWindowForTitleBarHighlight
    end

    while bit.band(window.RootWindowForNav.ChildFlags, ImGuiChildFlags_NavFlattened) ~= 0 do
        IM_ASSERT(window.RootWindowForNav.ParentWindow ~= nil)
        window.RootWindowForNav = window.RootWindowForNav.ParentWindow
    end
end

-- [EXPERIMENTAL] Called by Begin(). NextWindowData is valid at this point.
-- This is designed as a toy/test-bed for
--- @param window ImGuiWindow
function ImGui.UpdateWindowSkipRefresh(window)
    local g = GImGui
    window.SkipRefresh = false

    if bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasRefreshPolicy) == 0 then
        return
    end

    if bit.band(g.NextWindowData.RefreshFlagsVal, ImGuiWindowRefreshFlags.TryToAvoidRefresh) ~= 0 then
        -- FIXME-IDLE: Tests for e.g. mouse clicks or keyboard while focused.
        if window.Appearing then  -- If currently appearing
            return
        end
        if window.Hidden then  -- If was hidden (previous frame)
            return
        end
        if bit.band(g.NextWindowData.RefreshFlagsVal, ImGuiWindowRefreshFlags.RefreshOnHover) ~= 0 and g.HoveredWindow then
            if window.RootWindow == g.HoveredWindow.RootWindow or ImGui.IsWindowWithinBeginStackOf(g.HoveredWindow.RootWindow, window) then
                return
            end
        end
        if bit.band(g.NextWindowData.RefreshFlagsVal, ImGuiWindowRefreshFlags.RefreshOnFocus) ~= 0 and g.NavWindow then
            if window.RootWindow == g.NavWindow.RootWindow or ImGui.IsWindowWithinBeginStackOf(g.NavWindow.RootWindow, window) then
                return
            end
        end
        window.DrawList = nil
        window.SkipRefresh = true
    end
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
    window.SetWindowPosAllowFlags = bit.band(window.SetWindowPosAllowFlags, bit.bnot(bit.bor(ImGuiCond.Once, ImGuiCond.FirstUseEver, ImGuiCond.Appearing)))
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
    window.SetWindowSizeAllowFlags = bit.band(window.SetWindowSizeAllowFlags, bit.bnot(bit.bor(ImGuiCond.Once, ImGuiCond.FirstUseEver, ImGuiCond.Appearing)))

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

--- @param window ImGuiWindow
function ImGui.SetWindowHiddenAndSkipItemsForCurrentFrame(window)
    window.Hidden = true
    window.SkipItems = true
    window.HiddenFramesCanSkipItems = 1
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
    g.NextWindowData.PosCond     = (cond ~= 0) and cond or ImGuiCond.Always
end

--- @param size  ImVec2
--- @param cond? ImGuiCond
function ImGui.SetNextWindowSize(size, cond)
    if cond == nil then cond = 0 end

    local g = GImGui
    IM_ASSERT(cond == 0 or ImIsPowerOfTwo(cond))

    g.NextWindowData.HasFlags = bit.bor(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasSize)
    g.NextWindowData.SizeVal  = size:copy()
    g.NextWindowData.SizeCond = (cond ~= 0) and cond or ImGuiCond.Always
end

--- @param alpha float
function ImGui.SetNextWindowBgAlpha(alpha)
    local g = GImGui
    g.NextWindowData.HasFlags = bit.bor(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasBgAlpha)
    g.NextWindowData.BgAlphaVal = alpha
end

-- This is a shortcut for not taking ownership of 100+ keys, frequently used by drag operations.
-- FIXME: It might be undesirable that this will likely disable KeyOwner-aware shortcuts systems. Consider a more fine-tuned version if needed?
function ImGui.SetActiveIdUsingAllKeyboardKeys()
    local g = GImGui
    IM_ASSERT(g.ActiveId ~= 0)
    g.ActiveIdUsingNavDirMask = (bit.lshift(1, ImGuiDir.COUNT) - 1)
    g.ActiveIdUsingAllKeyboardKeys = true
    ImGui.NavMoveRequestCancel()
end

--- @param window ImGuiWindow
local function StartMouseMovingWindow(window)
    local g = GImGui
    ImGui.FocusWindow(window)
    ImGui.SetActiveID(window.MoveId, window)
    if (g.IO.ConfigNavCursorVisibleAuto) then
        g.NavCursorVisible = false
    end
    g.ActiveIdClickOffset = g.IO.MouseClickedPos[0] - window.RootWindow.Pos
    g.ActiveIdNoClearOnFocusLoss = true
    ImGui.SetActiveIdUsingAllKeyboardKeys()

    local can_move_window = true
    if bit.band(window.Flags, ImGuiWindowFlags_NoMove) ~= 0 or bit.band(window.RootWindow.Flags, ImGuiWindowFlags_NoMove) ~= 0 then
        can_move_window = false
    end
    if can_move_window then
        g.MovingWindow = window
    end
end

function ImGui.UpdateMouseMovingWindowNewFrame()
    local g = GImGui

    if g.MovingWindow then
        ImGui.KeepAliveID(g.ActiveId)
        IM_ASSERT(g.MovingWindow and g.MovingWindow.RootWindow)

        local moving_window = g.MovingWindow.RootWindow
        if g.IO.MouseDown[0] and ImGui.IsMousePosValid(g.IO.MousePos) then
            ImGui.SetWindowPos(moving_window, g.IO.MousePos - g.ActiveIdClickOffset, ImGuiCond.Always)
            ImGui.FocusWindow(g.MovingWindow)
        else
            ImGui.StopMouseMovingWindow()
            ImGui.ClearActiveID()
        end
    else
        if (g.ActiveIdWindow and g.ActiveIdWindow.MoveId == g.ActiveId) then
            ImGui.KeepAliveID(g.ActiveId)

            if not g.IO.MouseDown[0] then
                ImGui.ClearActiveID()
            end
        end
    end
end

function ImGui.GetDrawListSharedData()
    return GImGui.DrawListSharedData
end

--- @param id          ImGuiID
--- @param popup_flags ImGuiPopupFlags
function ImGui.IsPopupOpen(id, popup_flags)
    local g = GImGui

    if bit.band(popup_flags, ImGuiPopupFlags_AnyPopupId) ~= 0 then
        -- Return true if any popup is open at the current BeginPopup() level of the popup stack
        -- This may be used to e.g. test for another popups already opened to handle popups priorities at the same level.
        IM_ASSERT(id == 0)
        if bit.band(popup_flags, ImGuiPopupFlags_AnyPopupLevel) ~= 0 then
            return g.OpenPopupStack.Size > 0
        else
            return g.OpenPopupStack.Size > g.BeginPopupStack.Size
        end
    else
        if bit.band(popup_flags, ImGuiPopupFlags_AnyPopupLevel) ~= 0 then
            -- Return true if the popup is open anywhere in the popup stack
            for n = 1, g.OpenPopupStack.Size do
                if g.OpenPopupStack.Data[n].PopupId == id then
                    return true
                end
            end
            return false
        else
            -- Return true if the popup is open at the current BeginPopup() level of the popup stack (this is the most-common query)
            return g.OpenPopupStack.Size > g.BeginPopupStack.Size and g.OpenPopupStack.Data[g.BeginPopupStack.Size + 1].PopupId == id
        end
    end
end

function ImGui.UpdateMouseMovingWindowEndFrame()
    local g = GImGui

    if g.ActiveId ~= 0 or (g.HoveredId ~= 0 and not g.HoveredIdIsDisabled) then
        return
    end

    if g.NavWindow and g.NavWindow.Appearing then
        return
    end

    local hovered_window = g.HoveredWindow

    if g.IO.MouseClicked[0] then
        local hovered_root
        if hovered_window then
            hovered_root = hovered_window.RootWindow
        else
            hovered_root = nil
        end
        local is_closed_popup = hovered_root and (bit.band(hovered_root.Flags, ImGuiWindowFlags_Popup) ~= 0) and not ImGui.IsPopupOpen(hovered_root.PopupId, ImGuiPopupFlags_AnyPopupLevel)

        if hovered_window ~= nil and not is_closed_popup then
            StartMouseMovingWindow(hovered_window)

            -- Cancel moving if clicked outside of title bar
            if bit.band(hovered_window.BgClickFlags, ImGuiWindowBgClickFlags.Move) == 0 then  -- set by io.ConfigWindowsMoveFromTitleBarOnly
                if bit.band(hovered_root.Flags, ImGuiWindowFlags_NoTitleBar) == 0 then
                    if not hovered_root:TitleBarRect():Contains(g.IO.MouseClickedPos[0]) then
                        g.MovingWindow = nil
                    end
                end
            end

            -- Cancel moving if clicked over an item which was disabled or inhibited by popups
            -- (when g.HoveredIdIsDisabled == true && g.HoveredId == 0 we are inhibited by popups, when g.HoveredIdIsDisabled == true && g.HoveredId != 0 we are over a disabled item)
            if g.HoveredIdIsDisabled then
                g.MovingWindow = nil
                g.ActiveIdDisabledId = g.HoveredId
            end
        elseif hovered_window == nil and g.NavWindow ~= nil then
            ImGui.FocusWindow(nil, ImGuiFocusRequestFlags.UnlessBelowModal)
        end
    end

    -- TODO: Right mouse button close popup
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

--- Push a new Dear ImGui window to add widgets to.
--- - Passing a non-nil `open` displays a close button on the upper-right corner of the window
--- @param name     string
--- @param open?    bool
--- @param flags?   ImGuiWindowFlags
--- @return bool is_open      # The updated `open` passed in
--- @return bool is_collapsed # You always need to call `ImGui.End()` even if false is returned
function ImGui.Begin(name, open, flags)
    if flags == nil then flags = 0     end

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
        SetWindowConditionAllowFlags(window, ImGuiCond.Appearing, true)
    end

    -- Update Flags, LastFrameActive, BeginOrderXXX fields
    if first_begin_of_the_frame then
        -- UpdateWindowInFocusOrderList(window, window_just_created, flags)
        window.Flags = flags
        window.ChildFlags = (bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasChildFlags) ~= 0) and g.NextWindowData.ChildFlags or 0
        window.LastFrameActive = current_frame
        window.LastTimeActive = g.Time
        window.BeginOrderWithinParent = 0
        window.BeginOrderWithinContext = g.WindowsActiveCount
        g.WindowsActiveCount = g.WindowsActiveCount + 1
    else
        flags = window.Flags
    end

    local parent_window_in_stack
    if g.CurrentWindowStack:empty() then
        parent_window_in_stack = nil
    else
        parent_window_in_stack = g.CurrentWindowStack:back().Window
    end
    local parent_window
    if first_begin_of_the_frame then
        if (bit.band(flags, bit.bor(ImGuiWindowFlags_ChildWindow, ImGuiWindowFlags_Popup, ImGuiWindowFlags_Tooltip)) ~= 0) then
            parent_window = parent_window_in_stack
        else
            parent_window = nil
        end
    else
        parent_window = window.ParentWindow
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

    if first_begin_of_the_frame then
        ImGui.UpdateWindowParentAndRootLinks(window, flags, parent_window)
        window.ParentWindowInBeginStack = parent_window_in_stack

        if bit.band(flags, ImGuiWindowFlags_ChildWindow) ~= 0 then
            window.ParentWindowForFocusRoute = parent_window_in_stack
        else
            window.ParentWindowForFocusRoute = nil
        end

        if parent_window then
            window.FontWindowScaleParents = parent_window.FontWindowScaleParents * parent_window.FontWindowScale
        else
            window.FontWindowScaleParents = 1.0
        end
    end

    local window_pos_set_by_api = false
    local window_size_x_set_by_api = false
    local window_size_y_set_by_api = false
    if bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasPos) ~= 0 then
        window_pos_set_by_api = (bit.band(window.SetWindowPosAllowFlags, g.NextWindowData.PosCond) ~= 0)
        if window_pos_set_by_api and ImLengthSqr(g.NextWindowData.PosPivotVal) > 1e-5 then
            -- FIXME: Look into removing the branch so everything can go through this same code path for consistency.
            window.SetWindowPosVal = g.NextWindowData.PosVal:copy()
            window.SetWindowPosPivot = g.NextWindowData.PosPivotVal:copy()
            window.SetWindowPosAllowFlags = bit.band(window.SetWindowPosAllowFlags, bit.bnot(bit.bor(ImGuiCond.Once, ImGuiCond.FirstUseEver, ImGuiCond.Appearing)))
        else
            ImGui.SetWindowPos(window, g.NextWindowData.PosVal, g.NextWindowData.PosCond)
        end
    end
    if bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasSize) ~= 0 then
        window_size_x_set_by_api = (bit.band(window.SetWindowSizeAllowFlags, g.NextWindowData.SizeCond) ~= 0) and (g.NextWindowData.SizeVal.x > 0.0)
        window_size_y_set_by_api = (bit.band(window.SetWindowSizeAllowFlags, g.NextWindowData.SizeCond) ~= 0) and (g.NextWindowData.SizeVal.y > 0.0)
        if (bit.band(window.ChildFlags, ImGuiChildFlags_ResizeX) ~= 0 and bit.band(window.SetWindowSizeAllowFlags, ImGuiCond.FirstUseEver) == 0) then
            g.NextWindowData.SizeVal.x = window.SizeFull.x
        end
        if (bit.band(window.ChildFlags, ImGuiChildFlags_ResizeY) ~= 0 and bit.band(window.SetWindowSizeAllowFlags, ImGuiCond.FirstUseEver) == 0) then
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
    if bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasContentSize) ~= 0 then
        window.ContentSizeExplicit = g.NextWindowData.ContentSizeVal:copy()
    elseif first_begin_of_the_frame then
        window.ContentSizeExplicit = ImVec2(0.0, 0.0)
    end

    -- [EXPERIMENTAL] Skip Refresh mode
    ImGui.UpdateWindowSkipRefresh(window)

    if window_stack_data.DisabledOverrideReenable and window.RootWindow == window then
        ImGui.BeginDisabledOverrideReenable()
    end

    g.CurrentWindow = nil

    if first_begin_of_the_frame and not window.SkipRefresh then
        local window_is_child_tooltip = (bit.band(flags, ImGuiWindowFlags_ChildWindow) ~= 0 and bit.band(flags, ImGuiWindowFlags_Tooltip) ~= 0)

        window.Active = true
        window.HasCloseButton = (open ~= nil)
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
        if (bit.band(flags, ImGuiWindowFlags_ChildWindow) ~= 0) and (bit.band(flags, ImGuiWindowFlags_Popup) == 0) and (bit.band(window.ChildFlags, ImGuiChildFlags_AlwaysUseWindowPadding) == 0) and window.WindowBorderSize == 0.0 then
            if bit.band(flags, ImGuiWindowFlags_MenuBar) ~= 0 then
                window.WindowPadding = ImVec2(0.0, style.WindowPadding.y)
            else
                window.WindowPadding = ImVec2(0.0, 0.0)
            end
        end

        -- Lock menu offset so size calculation can use it as menu-bar windows need a minimum size.
        window.DC.MenuBarOffset.x = ImMax(ImMax(window.WindowPadding.x, style.ItemSpacing.x), g.NextWindowData.MenuBarOffsetMinVal.x)
        window.DC.MenuBarOffset.y = g.NextWindowData.MenuBarOffsetMinVal.y

        if bit.band(flags, ImGuiWindowFlags_NoTitleBar) ~= 0 then
            window.TitleBarHeight = 0.0
        else
            window.TitleBarHeight = g.FontSize + g.Style.FramePadding.y * 2.0
        end

        if bit.band(flags, ImGuiWindowFlags_MenuBar) ~= 0 then
            window.MenuBarHeight = window.DC.MenuBarOffset.y + g.FontSize + g.Style.FramePadding.y * 2.0
        else
            window.MenuBarHeight = 0.0
        end

        window.FontRefSize = g.FontSize  -- Lock this to discourage calling window:CalcFontSize() outside of current window.

        window.TitleBarHeight = (bit.band(flags, ImGuiWindowFlags_NoTitleBar) ~= 0) and 0 or g.FontSize + g.Style.FramePadding.y * 2

        local scrollbar_sizes_from_last_frame = window.ScrollbarSizes:copy() -- Updated several lines later
        window.DecoOuterSizeX1 = 0.0
        window.DecoOuterSizeX2 = 0.0
        window.DecoOuterSizeY1 = window.TitleBarHeight + window.MenuBarHeight
        window.DecoOuterSizeY2 = 0.0
        window.ScrollbarSizes = ImVec2(0.0, 0.0)

        -- Calculate auto-fit size, handle automatic resize
        -- - Using SetNextWindowSize() overrides ImGuiWindowFlags_AlwaysAutoResize, so it can be used on tooltips/popups, etc.
        -- - We still process initial auto-fit on collapsed windows to get a window width, but otherwise don't honor ImGuiWindowFlags_AlwaysAutoResize when collapsed.
        -- - Auto-fit may only grow window during the first few frames.
        do
            local size_auto_fit_x_always = not window_size_x_set_by_api and (bit.band(flags, ImGuiWindowFlags_AlwaysAutoResize) ~= 0) and not window.Collapsed
            local size_auto_fit_y_always = not window_size_y_set_by_api and (bit.band(flags, ImGuiWindowFlags_AlwaysAutoResize) ~= 0) and not window.Collapsed
            local size_auto_fit_x_current = not window_size_x_set_by_api and (window.AutoFitFramesX > 0)
            local size_auto_fit_y_current = not window_size_y_set_by_api and (window.AutoFitFramesY > 0)

            local size_auto_fit_mask = 0
            if size_auto_fit_x_always or size_auto_fit_x_current then
                size_auto_fit_mask = bit.bor(size_auto_fit_mask, bit.lshift(1, ImGuiAxis.X))
            end
            if size_auto_fit_y_always or size_auto_fit_y_current then
                size_auto_fit_mask = bit.bor(size_auto_fit_mask, bit.lshift(1, ImGuiAxis.Y))
            end

            local size_auto_fit = CalcWindowAutoFitSize(window, window.ContentSizeIdeal, size_auto_fit_mask)
            local old_size = ImVec2(window.SizeFull.x, window.SizeFull.y)

            if size_auto_fit_x_always or size_auto_fit_x_current then
                if size_auto_fit_x_always then
                    window.SizeFull.x = size_auto_fit.x
                else
                    if window.AutoFitOnlyGrows then
                        window.SizeFull.x = ImMax(window.SizeFull.x, size_auto_fit.x)
                    else
                        window.SizeFull.x = size_auto_fit.x
                    end
                end
                use_current_size_for_scrollbar_x = true
            end
            if size_auto_fit_y_always or size_auto_fit_y_current then
                if size_auto_fit_y_always then
                    window.SizeFull.y = size_auto_fit.y
                else
                    if window.AutoFitOnlyGrows then
                        window.SizeFull.y = ImMax(window.SizeFull.y, size_auto_fit.y)
                    else
                        window.SizeFull.y = size_auto_fit.y
                    end
                end
                use_current_size_for_scrollbar_y = true
            end

            if old_size.x ~= window.SizeFull.x or old_size.y ~= window.SizeFull.y then
                -- ImGui.MarkIniSettingsDirty(window)
            end
        end

        window.SizeFull = CalcWindowSizeAfterConstraint(window, window.SizeFull)
        window.Size = (window.Collapsed and bit.band(flags, ImGuiWindowFlags_ChildWindow) == 0) and window:TitleBarRect():GetSize() or window.SizeFull

        if bit.band(flags, ImGuiWindowFlags_ChildWindow) ~= 0 then
            IM_ASSERT(parent_window and parent_window.Active)
            window.BeginOrderWithinParent = parent_window.DC.ChildWindows.Size
            parent_window.DC.ChildWindows:push_back(window)
            if (bit.band(flags, ImGuiWindowFlags_Popup) == 0) and not window_pos_set_by_api and not window_is_child_tooltip then
                window.Pos = parent_window.DC.CursorPos
            end
        end

        local window_pos_with_pivot = (window.SetWindowPosVal.x ~= FLT_MAX and window.HiddenFramesCannotSkipItems == 0)
        if window_pos_with_pivot then
            ImGui.SetWindowPos(window, window.SetWindowPosVal - window.Size * window.SetWindowPosPivot, 0)  -- Position given a pivot (e.g. for centering)
        elseif (bit.band(flags, ImGuiWindowFlags_ChildMenu) ~= 0) then
            window.Pos = ImGui.FindBestWindowPosForPopup(window)
        elseif (bit.band(flags, ImGuiWindowFlags_Popup) ~= 0) and not window_pos_set_by_api and window_just_appearing_after_hidden_for_resize then
            window.Pos = ImGui.FindBestWindowPosForPopup(window)
        elseif (bit.band(flags, ImGuiWindowFlags_Tooltip) ~= 0) and not window_pos_set_by_api and not window_is_child_tooltip then
            window.Pos = ImGui.FindBestWindowPosForPopup(window)
        end

        local viewport_rect = viewport:GetMainRect()
        local viewport_work_rect = viewport:GetWorkRect()
        local visibility_padding = ImMaxVec2(style.DisplayWindowPadding, style.DisplaySafeAreaPadding)
        local visibility_rect = ImRect(viewport_work_rect.Min + visibility_padding, viewport_work_rect.Max - visibility_padding)

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

        local border_hovered, border_held = -1, -1
        local resize_grip_col = {0, 0, 0, 0}

        local resize_grip_count
        if (bit.band(flags, ImGuiWindowFlags_ChildWindow) ~= 0) and (bit.band(flags, ImGuiWindowFlags_Popup) == 0) then
            if (bit.band(window.ChildFlags, ImGuiChildFlags_ResizeX) ~= 0) and (bit.band(window.ChildFlags, ImGuiChildFlags_ResizeY) ~= 0) then
                resize_grip_count = 1
            else
                resize_grip_count = 0
            end
        else
            resize_grip_count = g.IO.ConfigWindowsResizeFromEdges and 2 or 1  -- Allow resize from lower-left if we have the mouse cursor feedback for it.
        end

        local resize_grip_draw_size = ImTrunc(ImMax(g.FontSize * 1.10, g.Style.WindowRounding + 1.0 + g.FontSize * 0.2))
        if handle_borders_and_resize_grips and not window.Collapsed then
            local auto_fit_mask
            auto_fit_mask, border_hovered, border_held = UpdateWindowManualResize(window, resize_grip_count, resize_grip_col, visibility_rect)
            if auto_fit_mask ~= 0 then
                if bit.band(auto_fit_mask, bit.lshift(1, ImGuiAxis.X)) ~= 0 then
                    use_current_size_for_scrollbar_x = true
                end
                if bit.band(auto_fit_mask, bit.lshift(1, ImGuiAxis.Y)) ~= 0 then
                    use_current_size_for_scrollbar_y = true
                end
            end
        end
        window.ResizeBorderHovered = border_hovered
        window.ResizeBorderHeld = border_held

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
            local render_decorations_in_parent = false
            if (bit.band(flags, ImGuiWindowFlags_ChildWindow) ~= 0) and (bit.band(flags, ImGuiWindowFlags_Popup) == 0) and not window_is_child_tooltip then
                -- - We test overlap with the previous child window only (testing all would end up being O(log N) not a good investment here)
                -- - We disable this when the parent window has zero vertices, which is a common pattern leading to laying out multiple overlapping childs
                local previous_child
                if parent_window.DC.ChildWindows.Size >= 2 then
                    previous_child = parent_window.DC.ChildWindows.Data[parent_window.DC.ChildWindows.Size - 1]
                else
                    previous_child = nil
                end
                local previous_child_overlapping
                if previous_child ~= nil then
                    previous_child_overlapping = previous_child:Rect():Overlaps(window:Rect())
                else
                    previous_child_overlapping = false
                end
                local parent_is_empty = (parent_window.DrawList.VtxBuffer.Size == 0)
                if (window.DrawList.CmdBuffer:back().ElemCount == 0 and not parent_is_empty and not previous_child_overlapping) then
                    render_decorations_in_parent = true
                end
            end

            if render_decorations_in_parent then
                window.DrawList = parent_window.DrawList
            end

            local title_bar_is_highlight = (g.NavWindow == window) -- TODO: proper cond, just simple highlight now

            RenderWindowDecorations(window, title_bar_rect, title_bar_is_highlight, handle_borders_and_resize_grips, resize_grip_col, resize_grip_draw_size)

            if render_decorations_in_parent then
                window.DrawList = window.DrawListInst
            end
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
        window.DC.CursorPos = window.DC.CursorStartPos:copy()
        window.DC.CursorPosPrevLine = window.DC.CursorPos:copy()
        window.DC.CursorMaxPos = window.DC.CursorStartPos:copy()
        window.DC.IdealMaxPos = window.DC.CursorStartPos:copy()
        window.DC.CurrLineSize = ImVec2(0.0, 0.0)
        window.DC.PrevLineSize = ImVec2(0.0, 0.0)
        window.DC.CurrLineTextBaseOffset = 0.0
        window.DC.PrevLineTextBaseOffset = 0.0
        window.DC.IsSameLine = false
        window.DC.IsSetPos = false

        window.DC.ChildWindows:resize(0)
        window.DC.LayoutType = ImGuiLayoutType.Vertical
        window.DC.ParentLayoutType = (parent_window ~= nil) and parent_window.DC.LayoutType or ImGuiLayoutType.Vertical

        local is_resizable_window = (window.Size.x > 0.0) and (bit.band(flags, ImGuiWindowFlags_Tooltip) == 0) and (bit.band(flags, ImGuiWindowFlags_AlwaysAutoResize) == 0)
        if (is_resizable_window) then
            window.DC.ItemWidthDefault = ImTrunc(window.Size.x * 0.65)
        else
            window.DC.ItemWidthDefault = ImTrunc(g.FontSize * 16.0)
        end
        window.DC.ItemWidth = window.DC.ItemWidthDefault
        window.DC.TextWrapPos = -1.0
        window.DC.TextWrapPosStack:resize(0)

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

        if bit.band(flags, ImGuiWindowFlags_NoTitleBar) == 0 then
            open = RenderWindowTitleBarContents(window, title_bar_rect, name, open)
        end

        if bit.band(flags, ImGuiWindowFlags_Tooltip) ~= 0 then
            g.TooltipPreviousWindow = window
        end

        if bit.band(flags, ImGuiWindowFlags_ChildWindow) ~= 0 then
            window.BgClickFlags = parent_window.BgClickFlags
        else
            window.BgClickFlags = g.IO.ConfigWindowsMoveFromTitleBarOnly and ImGuiWindowBgClickFlags.None or ImGuiWindowBgClickFlags.Move
        end

        window.DC.WindowItemStatusFlags = ImGuiItemStatusFlags_None

        if IsMouseHoveringRect(title_bar_rect.Min, title_bar_rect.Max, false) then
            window.DC.WindowItemStatusFlags = bit.bor(window.DC.WindowItemStatusFlags, ImGuiItemStatusFlags_HoveredRect)
        end
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

    if first_begin_of_the_frame and not window.SkipRefresh then
        if (bit.band(flags, ImGuiWindowFlags_ChildWindow) ~= 0) and (bit.band(flags, ImGuiWindowFlags_ChildMenu) == 0) then
            -- Child window can be out of sight and have "negative" clip windows.
            -- Mark them as collapsed so commands are skipped earlier (we can't manually collapse them because they have no title bar).
            IM_ASSERT((bit.band(flags, ImGuiWindowFlags_NoTitleBar) ~= 0))

            local nav_request = (bit.band(window.ChildFlags, ImGuiChildFlags_NavFlattened) ~= 0) and (g.NavAnyRequest and g.NavWindow and g.NavWindow.RootWindowForNav == window.RootWindowForNav)

            if not g.LogEnabled and not nav_request then
                if window.OuterRectClipped.Min.x >= window.OuterRectClipped.Max.x or window.OuterRectClipped.Min.y >= window.OuterRectClipped.Max.y then
                    if window.AutoFitFramesX > 0 or window.AutoFitFramesY > 0 then
                        window.HiddenFramesCannotSkipItems = 1
                    else
                        window.HiddenFramesCanSkipItems = 1
                    end
                end
            end

            -- Hide along with parent or if parent is collapsed
            if parent_window and (parent_window.Collapsed or parent_window.HiddenFramesCanSkipItems > 0) then
                window.HiddenFramesCanSkipItems = 1
            end
            if parent_window and parent_window.HiddenFramesCannotSkipItems > 0 then
                window.HiddenFramesCannotSkipItems = 1
            end
        end

        if style.Alpha <= 0.0 then
            window.HiddenFramesCanSkipItems = 1
        end

        local hidden_regular = (window.HiddenFramesCanSkipItems > 0) or (window.HiddenFramesCannotSkipItems > 0)
        window.Hidden = hidden_regular or (window.HiddenFramesForRenderOnly > 0)

        -- Disable inputs for requested number of frames
        if window.DisableInputsFrames > 0 then
            window.DisableInputsFrames = window.DisableInputsFrames - 1
            window.Flags = bit.bor(window.Flags, ImGuiWindowFlags_NoInputs)
        end

        -- Update the SkipItems flag, used to early out of all items functions (no layout required)
        local skip_items = false
        if window.Collapsed or not window.Active or hidden_regular then
            if window.AutoFitFramesX <= 0 and window.AutoFitFramesY <= 0 and window.HiddenFramesCannotSkipItems <= 0 then
                skip_items = true
            end
        end
        window.SkipItems = skip_items
    elseif first_begin_of_the_frame then
        window.SkipItems = true
    end

    if     open then open = true  end
    if not open then open = false end

    return open, not window.SkipItems
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

function ImGui.BeginDisabledOverrideReenable()
    local g = GImGui
    IM_ASSERT(bit.band(g.CurrentItemFlags, ImGuiItemFlags_Disabled) ~= 0)

    g.CurrentWindowStack.Data[g.CurrentWindowStack.Size].DisabledOverrideReenableAlphaBackup = g.Style.Alpha
    g.Style.Alpha = g.DisabledAlphaBackup
    g.CurrentItemFlags = bit.band(g.CurrentItemFlags, bit.bnot(ImGuiItemFlags_Disabled))
    g.ItemFlagsStack:push_back(g.CurrentItemFlags)
    g.DisabledStackSize = g.DisabledStackSize + 1
end

--- @param pos                            ImVec2
--- @param find_first_and_in_any_viewport bool
--- @return ImGuiWindow, ImGuiWindow?
local function FindHoveredWindowEx(pos, find_first_and_in_any_viewport)
    local g = GImGui
    local hovered_window = nil
    local hovered_window_under_moving_window = nil

    if not find_first_and_in_any_viewport and g.MovingWindow and bit.band(g.MovingWindow.Flags, ImGuiWindowFlags_NoMouseInputs) == 0 then
        hovered_window = g.MovingWindow
    end

    local padding_regular = g.Style.TouchExtraPadding
    local padding_for_resize = ImVec2()
    padding_for_resize.x = ImMax(g.Style.TouchExtraPadding.x, g.Style.WindowBorderHoverPadding)
    padding_for_resize.y = ImMax(g.Style.TouchExtraPadding.y, g.Style.WindowBorderHoverPadding)
    local window
    for i = g.Windows.Size, 1, -1 do
        window = g.Windows.Data[i]
        if not window.WasActive or window.Hidden then
            continue
        end
        if bit.band(window.Flags, ImGuiWindowFlags_NoMouseInputs) ~= 0 then
            continue
        end
        local hit_padding
        if bit.band(window.Flags, bit.bor(ImGuiWindowFlags_NoResize, ImGuiWindowFlags_AlwaysAutoResize)) ~= 0 then
            hit_padding = padding_regular
        else
            hit_padding = padding_for_resize
        end
        if not window.OuterRectClipped:ContainsWithPad(pos, hit_padding) then
            continue
        end

        if window.HitTestHoleSize.x ~= 0 then
            -- TODO: hit test hole
        end

        if find_first_and_in_any_viewport then
            hovered_window = window
            break
        else
            if hovered_window == nil then
                hovered_window = window
            end

            if hovered_window_under_moving_window == nil and (not g.MovingWindow or window.RootWindow ~= g.MovingWindow.RootWindow) then
                hovered_window_under_moving_window = window
            end

            if hovered_window and hovered_window_under_moving_window then
                break
            end
        end
    end

    return hovered_window, hovered_window_under_moving_window
end

-- TODO:
function ImGui.UpdateHoveredWindowAndCaptureFlags(mouse_pos)
    local g = GImGui
    local io = g.IO

    g.WindowsBorderHoverPadding = ImMax(ImMax(g.Style.TouchExtraPadding.x, g.Style.TouchExtraPadding.y), g.Style.WindowBorderHoverPadding)

    g.HoveredWindow, g.HoveredWindowUnderMovingWindow = FindHoveredWindowEx(mouse_pos, false)

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

--- @param key          ImGuiKey
--- @param v            bool
--- @param analog_value float
function ImGui.UpdateAliasKey(key, v, analog_value)
    IM_ASSERT(ImGui.IsAliasKey(key))
    local key_data = ImGui.GetKeyData(nil, key)
    key_data.Down = v
    key_data.AnalogValue = analog_value
end

function ImGui.GetMergedModsFromKeys()
    local mods = 0

    if ImGui.IsKeyDown(ImGuiMod_Ctrl) then mods  = bit.bor(mods, ImGuiMod_Ctrl) end
    if ImGui.IsKeyDown(ImGuiMod_Shift) then mods = bit.bor(mods, ImGuiMod_Shift) end
    if ImGui.IsKeyDown(ImGuiMod_Alt) then mods   = bit.bor(mods, ImGuiMod_Alt) end
    if ImGui.IsKeyDown(ImGuiMod_Super) then mods = bit.bor(mods, ImGuiMod_Super) end

    return mods
end

function ImGui.UpdateKeyboardInputs()
    local g = GImGui
    local io = g.IO

    if bit.band(io.ConfigFlags, ImGuiConfigFlags_NoKeyboard) ~= 0 then
        io:ClearInputKeys()
    end

    for n = 0, 2 do -- TODO: ImGuiMouseButton_COUNT - 1
        ImGui.UpdateAliasKey(ImGui.MouseButtonToKey(n), io.MouseDown[n], io.MouseDown[n] and 1.0 or 0.0)
    end
    ImGui.UpdateAliasKey(ImGuiKey_MouseWheelX, io.MouseWheelH ~= 0.0, io.MouseWheelH)
    ImGui.UpdateAliasKey(ImGuiKey_MouseWheelY, io.MouseWheel ~= 0.0, io.MouseWheel)

    -- Synchronize io.KeyMods and io.KeyCtrl/io.KeyShift/etc. values
    local prev_key_mods = io.KeyMods
    io.KeyMods = ImGui.GetMergedModsFromKeys()
    io.KeyCtrl = bit.band(io.KeyMods, ImGuiMod_Ctrl) ~= 0
    io.KeyShift = bit.band(io.KeyMods, ImGuiMod_Shift) ~= 0
    io.KeyAlt = bit.band(io.KeyMods, ImGuiMod_Alt) ~= 0
    io.KeySuper = bit.band(io.KeyMods, ImGuiMod_Super) ~= 0
    if prev_key_mods ~= io.KeyMods then
        g.LastKeyModsChangeTime = g.Time
    end
    if prev_key_mods ~= io.KeyMods and prev_key_mods == 0 then
        g.LastKeyModsChangeFromNoneTime = g.Time
    end

    -- Clear gamepad data if disabled
    if bit.band(io.BackendFlags, ImGuiBackendFlags.HasGamepad) == 0 then
        for key = ImGuiKey_Gamepad_BEGIN, ImGuiKey_Gamepad_END - 1 do
            io.KeysData[key - ImGuiKey_NamedKey_BEGIN].Down = false
            io.KeysData[key - ImGuiKey_NamedKey_BEGIN].AnalogValue = 0.0
        end
    end

    -- Update keys
    for key = ImGuiKey_NamedKey_BEGIN, ImGuiKey_NamedKey_END - 1 do
        local key_data = io.KeysData[key - ImGuiKey_NamedKey_BEGIN]
        key_data.DownDurationPrev = key_data.DownDuration
        if key_data.Down then
            if key_data.DownDuration < 0.0 then
                key_data.DownDuration = 0.0
            else
                key_data.DownDuration = key_data.DownDuration + io.DeltaTime
            end
        else
            key_data.DownDuration = -1.0
        end
        if key_data.DownDuration == 0.0 then
            if ImGui.IsKeyboardKey(key) then
                g.LastKeyboardKeyPressTime = g.Time
            elseif key == ImGuiKey_ReservedForModCtrl or key == ImGuiKey_ReservedForModShift or key == ImGuiKey_ReservedForModAlt or key == ImGuiKey_ReservedForModSuper then
                g.LastKeyboardKeyPressTime = g.Time
            end
        end
    end

    -- Update keys/input owner (named keys only): one entry per key
    for key = ImGuiKey_NamedKey_BEGIN, ImGuiKey_NamedKey_END - 1 do
        local key_data = io.KeysData[key - ImGuiKey_NamedKey_BEGIN]
        local owner_data = g.KeysOwnerData[key - ImGuiKey_NamedKey_BEGIN]
        owner_data.OwnerCurr = owner_data.OwnerNext
        if not key_data.Down then -- Important: ownership is released on the frame after a release. Ensure a 'MouseDown -> CloseWindow -> MouseUp' chain doesn't lead to someone else seeing the MouseUp.
            owner_data.OwnerNext = ImGuiKeyOwner_NoOwner
        end
        owner_data.LockThisFrame = owner_data.LockUntilRelease and key_data.Down
        owner_data.LockUntilRelease = owner_data.LockUntilRelease and key_data.Down  -- Clear LockUntilRelease when key is not Down anymore
    end

    -- TODO: UpdateKeyRoutingTable(g.KeysRoutingTable)
end

function ImGui.UpdateMouseInputs()
    local g = GImGui
    local io = g.IO

    io.MouseWheelRequestAxisSwap = io.KeyShift and not io.ConfigMacOSXBehaviors

    -- Round mouse position to avoid spreading non-rounded position (e.g. UpdateManualResize doesn't support them well)
    if (ImGui.IsMousePosValid(io.MousePos)) then
        local x_val = ImFloor(io.MousePos.x)
        local y_val = ImFloor(io.MousePos.y)

        io.MousePos = ImVec2(x_val, y_val)
        g.MouseLastValidPos = ImVec2(x_val, y_val)
    end

    -- If mouse just appeared or disappeared (usually denoted by -FLT_MAX components) we cancel out movement in MouseDelta
    if (ImGui.IsMousePosValid(io.MousePos) and ImGui.IsMousePosValid(io.MousePosPrev)) then
        io.MouseDelta = io.MousePos - io.MousePosPrev
    else
        io.MouseDelta = ImVec2(0.0, 0.0)
    end

    for i = 0, 2 do -- IM_COUNTOF(io.MouseDown)
        io.MouseClicked[i] = io.MouseDown[i] and (io.MouseDownDuration[i] < 0)
        io.MouseClickedCount[i] = 0
        io.MouseReleased[i] = not io.MouseDown[i] and (io.MouseDownDuration[i] >= 0)
        if (io.MouseReleased[i]) then
            io.MouseReleasedTime[i] = g.Time
        end
        io.MouseDownDurationPrev[i] = io.MouseDownDuration[i]
        if io.MouseDown[i] then
            if io.MouseDownDuration[i] < 0 then
                io.MouseDownDuration[i] = 0
            else
                io.MouseDownDuration[i] = io.MouseDownDuration[i] + 1
            end
        else
            io.MouseDownDuration[i] = -1.0
        end

        if io.MouseClicked[i] then
            local is_repeated_click = false
            if (g.Time - io.MouseClickedTime[i]) < io.MouseDoubleClickTime then
                local delta_from_click_pos
                if ImGui.IsMousePosValid(io.MousePos) then
                    delta_from_click_pos = io.MousePos - io.MouseClickedPos[i]
                else
                    delta_from_click_pos = ImVec2(0.0, 0.0)
                end

                if ImLengthSqr(delta_from_click_pos) < io.MouseDoubleClickMaxDist * io.MouseDoubleClickMaxDist then
                    is_repeated_click = true
                end
            end

            if is_repeated_click then
                io.MouseClickedLastCount[i] = io.MouseClickedLastCount[i] + 1
            else
                io.MouseClickedLastCount[i] = 1
            end

            io.MouseClickedTime[i] = g.Time
            io.MouseClickedPos[i] = io.MousePos
            io.MouseClickedCount[i] = io.MouseClickedLastCount[i]
        end

        io.MouseDoubleClicked[i] = (io.MouseClickedCount[i] == 2)

        if (io.MouseClicked[i]) then
            g.NavHighlightItemUnderNav = false
        end
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

--- @param viewport ImGuiViewportP
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
function ImGui.GetCurrentWindowRead()
    local g = GImGui
    return g.CurrentWindow
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
    -- TODO: splitter
    ImGui.AddDrawListToDrawDataEx(viewport.DrawDataP, viewport.DrawDataBuilder.Layers[layer], window.DrawList)
    for _, child in window.DC.ChildWindows:iter() do
        if (IsWindowActiveAndVisible(child)) then -- Clipped children may have been marked not active
            AddWindowToDrawData(child, layer)
        end
    end
end

--- @param window ImGuiWindow
local function GetWindowDisplayLayer(window)
    return (bit.band(window.Flags, ImGuiWindowFlags_Tooltip) ~= 0) and 2 or 1
end

--- static inline void AddRootWindowToDrawData(ImGuiWindow* window)
local function AddRootWindowToDrawData(window)
    AddWindowToDrawData(window, GetWindowDisplayLayer(window))
end

--- @param builder ImDrawDataBuilder
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
            goto CONTINUE
        end

        for i = 1, layer.Size do
            builder.Layers[1].Data[n + i] = layer.Data[i]
        end

        n = n + layer.Size

        layer:resize(0)

        :: CONTINUE ::
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
    g.TooltipOverrideCount = 0

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

    ImGui.UpdateInputEvents(g.IO.ConfigInputTrickleEventQueue)

    ImGui.UpdateViewportsNewFrame()

    ImGui.UpdateTexturesNewFrame()

    SetupDrawListSharedData()
    ImGui.UpdateFontsNewFrame()

    g.WithinFrameScope = true

    for _, viewport in g.Viewports:iter() do
        viewport.DrawDataP.Valid = false
    end

    -- Update HoveredId data
    if not g.HoveredIdPreviousFrame then
        g.HoveredIdTimer = 0.0
    end
    if not g.HoveredIdPreviousFrame or (g.HoveredId and g.ActiveId == g.HoveredId) then
        g.HoveredIdNotActiveTimer = 0.0
    end
    if g.HoveredId then
        g.HoveredIdTimer = g.HoveredIdTimer + g.IO.DeltaTime
    end
    if g.HoveredId and g.ActiveId ~= g.HoveredId then
        g.HoveredIdNotActiveTimer = g.HoveredIdNotActiveTimer + g.IO.DeltaTime
    end
    g.HoveredIdPreviousFrame = g.HoveredId
    g.HoveredIdPreviousFrameItemCount = 0
    g.HoveredId = 0
    g.HoveredIdAllowOverlap = false
    g.HoveredIdIsDisabled = false

    if (g.ActiveId ~= 0 and g.ActiveIdIsAlive ~= g.ActiveId and g.ActiveIdPreviousFrame == g.ActiveId) then
        print("NewFrame(): ClearActiveID() because it isn't marked alive anymore!")

        ImGui.ClearActiveID()
    end

    -- Update ActiveId data (clear reference to active widget if the widget isn't alive anymore)
    if g.ActiveId then
        g.ActiveIdTimer = g.ActiveIdTimer + g.IO.DeltaTime
    end
    g.LastActiveIdTimer = g.LastActiveIdTimer + g.IO.DeltaTime
    g.ActiveIdPreviousFrame = g.ActiveId
    g.ActiveIdIsAlive = 0
    g.ActiveIdHasBeenEditedThisFrame = false
    g.ActiveIdIsJustActivated = false
    if g.TempInputId ~= 0 and g.ActiveId ~= g.TempInputId then
        g.TempInputId = 0
    end
    if g.ActiveId == 0 then
        g.ActiveIdUsingNavDirMask = 0x00
        g.ActiveIdUsingAllKeyboardKeys = false
    end
    if g.DeactivatedItemData.ElapseFrame < g.FrameCount then
        g.DeactivatedItemData.ID = 0
    end
    g.DeactivatedItemData.IsAlive = false

    -- Record when we have been stationary as this state is preserved while over same item.
    -- FIXME: The way this is expressed means user cannot alter HoverStationaryDelay during the frame to use varying values.
    -- To allow this we should store HoverItemMaxStationaryTime+ID and perform the >= check in IsItemHovered() function.
    -- if g.HoverItemDelayId ~= 0 and g.MouseStationaryTimer >= g.Style.HoverStationaryDelay then
    --     g.HoverItemUnlockedStationaryId = g.HoverItemDelayId
    -- elseif g.HoverItemDelayId == 0 then
    --     g.HoverItemUnlockedStationaryId = 0
    -- end

    -- if g.HoveredWindow ~= nil and g.MouseStationaryTimer >= g.Style.HoverStationaryDelay then
    --     g.HoverWindowUnlockedStationaryId = g.HoveredWindow.ID
    -- elseif g.HoveredWindow == nil then
    --     g.HoverWindowUnlockedStationaryId = 0
    -- end

    -- -- Update hover delay for IsItemHovered() with delays and tooltips
    -- g.HoverItemDelayIdPreviousFrame = g.HoverItemDelayId
    -- if g.HoverItemDelayId ~= 0 then
    --     g.HoverItemDelayTimer = g.HoverItemDelayTimer + g.IO.DeltaTime
    --     g.HoverItemDelayClearTimer = 0.0
    --     g.HoverItemDelayId = 0
    -- elseif g.HoverItemDelayTimer > 0.0 then
    --     -- This gives a little bit of leeway before clearing the hover timer, allowing mouse to cross gaps
    --     -- We could expose 0.25f as style.HoverClearDelay but I am not sure of the logic yet, this is particularly subtle.
    --     g.HoverItemDelayClearTimer = g.HoverItemDelayClearTimer + g.IO.DeltaTime
    --     if g.HoverItemDelayClearTimer >= math.max(0.25, g.IO.DeltaTime * 2.0) then  -- ~7 frames at 30 Hz + allow for low framerate
    --         g.HoverItemDelayTimer = 0.0
    --         g.HoverItemDelayClearTimer = 0.0  -- May want a decaying timer, in which case need to clamp at max first, based on max of caller last requested timer.
    --     end
    -- end

    ImGui.UpdateKeyboardInputs()

    g.TooltipPreviousWindow = nil

    ImGui.UpdateMouseInputs()

    -- TODO: GC

    for _, window in g.Windows:iter() do
        window.WasActive = window.Active
        window.Active = false
        window.WriteAccessed = false
        window.BeginCountPreviousFrame = window.BeginCount
        window.BeginCount = 0
    end

    ImGui.UpdateHoveredWindowAndCaptureFlags(g.IO.MousePos)

    ImGui.UpdateMouseMovingWindowNewFrame()

    g.MouseCursor = ImGuiMouseCursor.Arrow
    g.WantCaptureMouseNextFrame = -1
    g.WantCaptureKeyboardNextFrame = -1
    g.WantTextInputNextFrame = -1

    g.CurrentWindowStack:resize(0)

    g.WithinFrameScopeWithImplicitWindow = true
    ImGui.SetNextWindowSize(ImVec2(400, 400), ImGuiCond.FirstUseEver)
    ImGui.Begin("Debug##Default")
    IM_ASSERT(g.CurrentWindow.IsFallbackWindow == true)
end

function ImGui.EndFrame()
    local g = GImGui
    IM_ASSERT(g.Initialized)

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

    -- Drag and Drop: Fallback for missing source tooltip. This is not ideal but better than nothing.
    -- If you want to handle source item disappearing: instead of submitting your description tooltip
    -- in the BeginDragDropSource() block of the dragged item, you can submit them from a safe single spot
    -- (e.g. end of your item loop, or before EndFrame) by reading payload data.
    -- In the typical case, the contents of drag tooltip should be possible to infer solely from payload data.
    if g.DragDropActive and g.DragDropSourceFrameCount + 1 < g.FrameCount and (bit.band(g.DragDropSourceFlags, ImGuiDragDropFlags_SourceNoPreviewTooltip) == 0) then
        g.DragDropWithinSource = true
        ImGui.SetTooltip("...")
        g.DragDropWithinSource = false
    end

    g.WithinFrameScope = false
    g.FrameCountEnded = g.FrameCount
    ImGui.UpdateFontsEndFrame()

    ImGui.UpdateMouseMovingWindowEndFrame()

    ImGui.UpdateTexturesEndFrame()

    for _, atlas in g.FontAtlases:iter() do
        atlas.Locked = false
    end

    g.IO.MousePosPrev = g.IO.MousePos
    g.IO.AppFocusLost = false
    g.IO.MouseWheel = 0.0
    g.IO.MouseWheelH = 0.0
    g.IO.InputQueueCharacters:resize(0)
end

-- TODO:
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

    -- TODO: RenderDimmedBackgrounds()

    local windows_to_render_top_most = {nil, nil}
    windows_to_render_top_most[1] = (g.NavWindowingTarget and (bit.band(g.NavWindowingTarget.Flags, ImGuiWindowFlags_NoBringToFrontOnFocus) == 0)) and g.NavWindowingTarget.RootWindow or nil
    windows_to_render_top_most[2] = g.NavWindowingTarget and g.NavWindowingListWindow or nil
    for _, window in g.Windows:iter() do
        if IsWindowActiveAndVisible(window) and (bit.band(window.Flags, ImGuiWindowFlags_ChildWindow) == 0) and window ~= windows_to_render_top_most[1] and window ~= windows_to_render_top_most[2] then
            AddRootWindowToDrawData(window)
        end
    end
    for n = 1, 2 do
        if windows_to_render_top_most[n] and IsWindowActiveAndVisible(windows_to_render_top_most[n]) then  -- NavWindowingTarget is always temporarily displayed as the top-most window
            AddRootWindowToDrawData(windows_to_render_top_most[n])
        end
    end

    -- TODO: RenderMouseCursor

    g.IO.MetricsRenderVertices = 0
    g.IO.MetricsRenderIndices = 0
    for _, viewport in g.Viewports:iter() do
        FlattenDrawDataIntoSingleLayer(viewport.DrawDataBuilder)

        if viewport.BgFgDrawLists[2] ~= nil then
            ImGui.AddDrawListToDrawDataEx(viewport.DrawDataP, viewport.DrawDataBuilder.Layers[1], ImGui.GetForegroundDrawList(viewport))
        end

        local draw_data = viewport.DrawDataP
        IM_ASSERT(draw_data.CmdLists.Size == draw_data.CmdListsCount)
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

function ImGui.GetTime()
    return GImGui.Time
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

--- @param cursor_type ImGuiMouseCursor
function ImGui.SetMouseCursor(cursor_type)
    local g = GImGui
    g.MouseCursor = cursor_type
end

--- @param in_col  ImU32
--- @param out_col ImVec4?
--- @return ImVec4
function ImGui.ColorConvertU32ToFloat4(in_col, out_col)
    local s = 1.0 / 255.0
    local r = bit.band(bit.rshift(in_col, IM_COL32_R_SHIFT), 0xFF) * s
    local g = bit.band(bit.rshift(in_col, IM_COL32_G_SHIFT), 0xFF) * s
    local b = bit.band(bit.rshift(in_col, IM_COL32_B_SHIFT), 0xFF) * s
    local a = bit.band(bit.rshift(in_col, IM_COL32_A_SHIFT), 0xFF) * s

    if out_col then
        out_col.x = r
        out_col.y = g
        out_col.z = b
        out_col.w = a
        return out_col
    else
        return ImVec4(r, g, b, a)
    end
end

--- @param in_col ImVec4
--- @return ImU32
function ImGui.ColorConvertFloat4ToU32(in_col)
    local out_col = 0
    out_col = bit.bor(out_col, bit.lshift(IM_F32_TO_INT8_SAT(in_col.x), IM_COL32_R_SHIFT))
    out_col = bit.bor(out_col, bit.lshift(IM_F32_TO_INT8_SAT(in_col.y), IM_COL32_G_SHIFT))
    out_col = bit.bor(out_col, bit.lshift(IM_F32_TO_INT8_SAT(in_col.z), IM_COL32_B_SHIFT))
    out_col = bit.bor(out_col, bit.lshift(IM_F32_TO_INT8_SAT(in_col.w), IM_COL32_A_SHIFT))
    return out_col
end

--- @param idx        ImGuiCol
--- @param alpha_mul? float
--- @return ImU32
function ImGui.GetColorU32(idx, alpha_mul)
    if alpha_mul == nil then alpha_mul = 1.0 end

    local g = GImGui
    local c = g.Style.Colors[idx]
    c.w = c.w * g.Style.Alpha * alpha_mul
    return ImGui.ColorConvertFloat4ToU32(c)
end

--- @param idx ImGuiCol
--- @param col ImVec4
function ImGui.PushStyleColor(idx, col)
    local g = GImGui
    local backup = ImGuiColorMod(idx, g.Style.Colors[idx])
    g.ColorStack:push_back(backup)
    if g.DebugFlashStyleColorIdx ~= idx then
        g.Style.Colors[idx] = col
    end
end

--- @param count? int
function ImGui.PopStyleColor(count)
    if count == nil then count = 1 end

    local g = GImGui
    if g.ColorStack.Size < count then
        IM_ASSERT_USER_ERROR(false, "Calling PopStyleColor() too many times!")
        count = g.ColorStack.Size
    end

    while count > 0 do
        local backup = g.ColorStack:back()
        g.Style.Colors[backup.Col] = backup.BackupValue
        g.ColorStack:pop_back()
        count = count - 1
    end
end

--- @param wrap_local_pos_x float
function ImGui.PushTextWrapPos(wrap_local_pos_x) -- ATTENTION: THIS IS IN LEGACY LOCAL SPACE.
    local g = GImGui
    local window = g.CurrentWindow
    window.DC.TextWrapPosStack:push_back(window.DC.TextWrapPos)
    window.DC.TextWrapPos = wrap_local_pos_x
end

function ImGui.PopTextWrapPos()
    local g = GImGui
    local window = g.CurrentWindow
    IM_ASSERT_USER_ERROR_RET(window.DC.TextWrapPosStack.Size > 0, "Calling PopTextWrapPos() too many times!")
    window.DC.TextWrapPos = window.DC.TextWrapPosStack:back()
    window.DC.TextWrapPosStack:pop_back()
end

--- @param window          ImGuiWindow
--- @param popup_hierarchy bool
local function GetCombinedRootWindow(window, popup_hierarchy)
    local last_window = nil
    while last_window ~= window do
        last_window = window
        window = window.RootWindow
        if popup_hierarchy then
            window = window.RootWindowPopupTree
        end
    end
    return window
end

--- @param window           ImGuiWindow
--- @param potential_parent ImGuiWindow
--- @param popup_hierarchy  bool
function ImGui.IsWindowChildOf(window, potential_parent, popup_hierarchy)
    local window_root = GetCombinedRootWindow(window, popup_hierarchy)
    if window_root == potential_parent then
        return true
    end

    while window ~= nil do
        if window == potential_parent then
            return true
        end
        if window == window_root then -- end of chain
            return false
        end
        window = window.ParentWindow
    end

    return false
end

--- @param window ImGuiWindow
function ImGui.IsWindowInBeginStack(window)
    local g = GImGui
    for n = g.CurrentWindowStack.Size, 1, -1 do
        if g.CurrentWindowStack.Data[n].Window == window then
            return true
        end
    end
    return false
end

--- @param window           ImGuiWindow
--- @param potential_parent ImGuiWindow
function ImGui.IsWindowWithinBeginStackOf(window, potential_parent)
    if window.RootWindow == potential_parent then
        return true
    end

    while window ~= nil do
        if window == potential_parent then
            return true
        end
        window = window.ParentWindowInBeginStack
    end

    return false
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

---------------------------------------------------------------------------------------
-- [SECTION] TOOLTIPS
---------------------------------------------------------------------------------------

--- @param tooltip_flags      ImGuiTooltipFlags
--- @param extra_window_flags ImGuiWindowFlags
function ImGui.BeginTooltipEx(tooltip_flags, extra_window_flags)
    local g = GImGui

    local is_dragdrop_tooltip = g.DragDropWithinSource or g.DragDropWithinTarget
    if is_dragdrop_tooltip then
        local is_touchscreen = (g.IO.MouseSource == ImGuiMouseSource_TouchScreen)

        if bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasPos) == 0 then
            local tooltip_pos
            if is_touchscreen then
                tooltip_pos = g.IO.MousePos + TOOLTIP_DEFAULT_OFFSET_TOUCH * g.Style.MouseCursorScale
            else
                tooltip_pos = g.IO.MousePos + TOOLTIP_DEFAULT_OFFSET_MOUSE * g.Style.MouseCursorScale
            end

            local tooltip_pivot = is_touchscreen and TOOLTIP_DEFAULT_PIVOT_TOUCH or ImVec2(0.0, 0.0)
            ImGui.SetNextWindowPos(tooltip_pos, ImGuiCond.None, tooltip_pivot)
        end

        local bg_alpha = g.Style.Colors[ImGuiCol.PopupBg].w * 0.60
        ImGui.SetNextWindowBgAlpha(bg_alpha)

        tooltip_flags = bit.bor(tooltip_flags, ImGuiTooltipFlags.OverridePrevious)
    end

    if (bit.band(tooltip_flags, ImGuiTooltipFlags.OverridePrevious) ~= 0) and g.TooltipPreviousWindow ~= nil and g.TooltipPreviousWindow.Active and not ImGui.IsWindowInBeginStack(g.TooltipPreviousWindow) then
        -- IMGUI_DEBUG_LOG("[tooltip] '%s' already active, using +1 for this frame\n", window_name)
        ImGui.SetWindowHiddenAndSkipItemsForCurrentFrame(g.TooltipPreviousWindow)
        g.TooltipOverrideCount = g.TooltipOverrideCount + 1
    end

    local window_name_template = is_dragdrop_tooltip and "##Tooltip_DragDrop_%02d" or "##Tooltip_%02d"
    local window_name = ImFormatString(window_name_template, g.TooltipOverrideCount)

    local flags = bit.bor(ImGuiWindowFlags_Tooltip, ImGuiWindowFlags_NoInputs, ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoMove, ImGuiWindowFlags_NoResize, ImGuiWindowFlags_NoSavedSettings, ImGuiWindowFlags_AlwaysAutoResize)

    ImGui.Begin(window_name, nil, bit.bor(flags, extra_window_flags))

    return true
end

function ImGui.BeginTooltip()
    return ImGui.BeginTooltipEx(ImGuiTooltipFlags.None, ImGuiWindowFlags_None)
end

function ImGui.BeginItemTooltip()
    if not ImGui.IsItemHovered(ImGuiHoveredFlags_ForTooltip) then
        return false
    end
    return ImGui.BeginTooltipEx(ImGuiTooltipFlags.None, ImGuiWindowFlags_None)
end

function ImGui.EndTooltip()
    IM_ASSERT(bit.band(ImGui.GetCurrentWindowRead().Flags, ImGuiWindowFlags_Tooltip) ~= 0) -- Mismatched BeginTooltip()/EndTooltip() calls
    ImGui.End()
end

--- @param fmt string
--- @param ... any
function ImGui.SetTooltip(fmt, ...)
    if not ImGui.BeginTooltipEx(ImGuiTooltipFlags.OverridePrevious, ImGuiWindowFlags_None) then
        return
    end
    ImGui.TextV(fmt, ...)
    ImGui.EndTooltip()
end

--- @param fmt string
--- @param ... any
function ImGui.SetItemTooltip(fmt, ...)
    if ImGui.IsItemHovered(ImGuiHoveredFlags_ForTooltip) then
        ImGui.SetTooltip(fmt, ...)
    end
end

---------------------------------------------------------------------------------------
-- [SECTION] POPUPS
---------------------------------------------------------------------------------------

--- @param ref_pos  ImVec2
--- @param size     ImVec2
--- @param last_dir ImGuiDir
--- @param r_outer  ImRect
--- @param r_avoid  ImRect
--- @param policy   ImGuiPopupPositionPolicy
--- @return ImVec2
--- @nodiscard
function ImGui.FindBestWindowPosForPopupEx(ref_pos, size, last_dir, r_outer, r_avoid, policy)
    local base_pos_clamped = ImClampV2(ref_pos, r_outer.Min, r_outer.Max - size)

    -- Combo Box policy (we want a connecting edge)
    if policy == ImGuiPopupPositionPolicy.ComboBox then
        local dir_preferred_order = {ImGuiDir.Down, ImGuiDir.Right, ImGuiDir.Left, ImGuiDir.Up}

        for n = (last_dir ~= ImGuiDir.None) and 0 or 1, ImGuiDir.COUNT do
            local dir
            if n == 0 then
                dir = last_dir
            else
                dir = dir_preferred_order[n]
            end

            if n ~= 0 and dir == last_dir then  -- Already tried this direction?
                continue
            end

            local pos
            if dir == ImGuiDir.Down then
                pos = ImVec2(r_avoid.Min.x, r_avoid.Max.y)           -- Below, Toward Right (default)
            elseif dir == ImGuiDir.Right then
                pos = ImVec2(r_avoid.Min.x, r_avoid.Min.y - size.y)  -- Above, Toward Right
            elseif dir == ImGuiDir.Left then
                pos = ImVec2(r_avoid.Max.x - size.x, r_avoid.Max.y)  -- Below, Toward Left
            elseif dir == ImGuiDir.Up then
                pos = ImVec2(r_avoid.Max.x - size.x, r_avoid.Min.y - size.y)  -- Above, Toward Left
            end

            if not r_outer:Contains(ImRect(pos, pos + size)) then
                continue
            end

            last_dir = dir
            return pos
        end
    end

    -- Tooltip and Default popup policy
    -- (Always first try the direction we used on the last frame, if any)
    if policy == ImGuiPopupPositionPolicy.Tooltip or policy == ImGuiPopupPositionPolicy.Default then
        local dir_preferred_order = {ImGuiDir.Right, ImGuiDir.Down, ImGuiDir.Up, ImGuiDir.Left}

        for n = (last_dir ~= ImGuiDir.None) and 0 or 1, ImGuiDir.COUNT do
            local dir
            if n == 0 then
                dir = last_dir
            else
                dir = dir_preferred_order[n]
            end

            if n ~= 0 and dir == last_dir then  -- Already tried this direction?
                continue
            end

            local avail_w, avail_h

            if dir == ImGuiDir.Left then
                avail_w = r_avoid.Min.x - r_outer.Min.x
            elseif dir == ImGuiDir.Right then
                avail_w = r_outer.Max.x - r_avoid.Max.x
            else
                avail_w = r_outer.Max.x - r_outer.Min.x
            end

            if dir == ImGuiDir.Up then
                avail_h = r_avoid.Min.y - r_outer.Min.y
            elseif dir == ImGuiDir.Down then
                avail_h = r_outer.Max.y - r_avoid.Max.y
            else
                avail_h = r_outer.Max.y - r_outer.Min.y
            end

            -- If there's not enough room on one axis, there's no point in positioning on a side on this axis (e.g. when not enough width, use a top/bottom position to maximize available width)
            if avail_w < size.x and (dir == ImGuiDir.Left or dir == ImGuiDir.Right) then
                continue
            end
            if avail_h < size.y and (dir == ImGuiDir.Up or dir == ImGuiDir.Down) then
                continue
            end

            local pos = ImVec2()
            if dir == ImGuiDir.Left then
                pos.x = r_avoid.Min.x - size.x
            elseif dir == ImGuiDir.Right then
                pos.x = r_avoid.Max.x
            else
                pos.x = base_pos_clamped.x
            end

            if dir == ImGuiDir.Up then
                pos.y = r_avoid.Min.y - size.y
            elseif dir == ImGuiDir.Down then
                pos.y = r_avoid.Max.y
            else
                pos.y = base_pos_clamped.y
            end

            -- Clamp top-left corner of popup
            pos.x = ImMax(pos.x, r_outer.Min.x)
            pos.y = ImMax(pos.y, r_outer.Min.y)

            last_dir = dir
            return pos
        end
    end

    -- Fallback when not enough room:
    last_dir = ImGuiDir.None

    -- For tooltip we prefer avoiding the cursor at all cost even if it means that part of the tooltip won't be visible.
    if policy == ImGuiPopupPositionPolicy.Tooltip then
        return ref_pos + ImVec2(2, 2)
    end

    -- Otherwise try to keep within display
    local pos = ImVec2(ref_pos.x, ref_pos.y)
    pos.x = ImMax(ImMin(pos.x + size.x, r_outer.Max.x) - size.x, r_outer.Min.x)
    pos.y = ImMax(ImMin(pos.y + size.y, r_outer.Max.y) - size.y, r_outer.Min.y)
    return pos
end

--- @param window ImGuiWindow
--- @return ImRect
--- @nodiscard
function ImGui.GetPopupAllowedExtentRect(window)
    local g = GImGui
    -- IM_UNUSED(window)
    local r_screen = ImGui.GetMainViewport():GetMainRect()
    local padding = g.Style.DisplaySafeAreaPadding
    local expand_x = (r_screen:GetWidth() > padding.x * 2) and -padding.x or 0.0
    local expand_y = (r_screen:GetHeight() > padding.y * 2) and -padding.y or 0.0
    r_screen:ExpandV2(ImVec2(expand_x, expand_y))
    return r_screen
end

--- @param window ImGuiWindow
--- @return ImVec2
--- @nodiscard
function ImGui.FindBestWindowPosForPopup(window)
    local g = GImGui

    local r_outer = ImGui.GetPopupAllowedExtentRect(window)

    if bit.band(window.Flags, ImGuiWindowFlags_ChildMenu) ~= 0 then
        -- Child menus typically request _any_ position within the parent menu item, and then we move the new menu outside the parent bounds.
        -- This is how we end up with child menus appearing (most-commonly) on the right of the parent menu.
        IM_ASSERT(g.CurrentWindow == window)
        local parent_window = g.CurrentWindowStack.Data[g.CurrentWindowStack.Size - 1].Window
        local horizontal_overlap = g.Style.ItemInnerSpacing.x  -- We want some overlap to convey the relative depth of each menu (currently the amount of overlap is hard-coded to style.ItemSpacing.x).

        local r_avoid
        if parent_window.DC.MenuBarAppending then
            r_avoid = ImRect(-FLT_MAX, parent_window.ClipRect.Min.y, FLT_MAX, parent_window.ClipRect.Max.y)  -- Avoid parent menu-bar. If we wanted multi-line menu-bar, we may instead want to have the calling window setup e.g. a NextWindowData.PosConstraintAvoidRect field
        else
            r_avoid = ImRect(parent_window.Pos.x + horizontal_overlap, -FLT_MAX, parent_window.Pos.x + parent_window.Size.x - horizontal_overlap - parent_window.ScrollbarSizes.x, FLT_MAX)
        end

        return ImGui.FindBestWindowPosForPopupEx(window.Pos, window.Size, window.AutoPosLastDirection, r_outer, r_avoid, ImGuiPopupPositionPolicy.Default)
    end

    if bit.band(window.Flags, ImGuiWindowFlags_Popup) ~= 0 then
        return ImGui.FindBestWindowPosForPopupEx(window.Pos, window.Size, window.AutoPosLastDirection, r_outer, ImRect(window.Pos, window.Pos), ImGuiPopupPositionPolicy.Default)  -- Ideally we'd disable r_avoid here
    end

    if bit.band(window.Flags, ImGuiWindowFlags_Tooltip) ~= 0 then
        -- Position tooltip (always follows mouse + clamp within outer boundaries)
        -- FIXME:
        -- - Too many paths. One problem is that FindBestWindowPosForPopupEx() doesn't allow passing a suggested position (so touch screen path doesn't use it by default).
        -- - Drag and drop tooltips are not using this path either: BeginTooltipEx() manually sets their position.
        -- - Require some tidying up. In theory we could handle both cases in same location, but requires a bit of shuffling
        --   as drag and drop tooltips are calling SetNextWindowPos() leading to 'window_pos_set_by_api' being set in Begin().
        IM_ASSERT(g.CurrentWindow == window)
        local scale = g.Style.MouseCursorScale
        local ref_pos = ImGui.NavCalcPreferredRefPos(ImGuiWindowFlags_Tooltip)

        if g.IO.MouseSource == ImGuiMouseSource_TouchScreen and ImGui.NavCalcPreferredRefPosSource(ImGuiWindowFlags_Tooltip) == ImGuiInputSource_Mouse then
            local tooltip_pos = ref_pos + TOOLTIP_DEFAULT_OFFSET_TOUCH * scale - (TOOLTIP_DEFAULT_PIVOT_TOUCH * window.Size)
            if r_outer:Contains(ImRect(tooltip_pos, tooltip_pos + window.Size)) then
                return tooltip_pos
            end
        end

        local tooltip_pos = ref_pos + TOOLTIP_DEFAULT_OFFSET_MOUSE * scale
        local r_avoid
        if g.NavCursorVisible and g.NavHighlightItemUnderNav and not g.IO.ConfigNavMoveSetMousePos then
            r_avoid = ImRect(ref_pos.x - 16, ref_pos.y - 8, ref_pos.x + 16, ref_pos.y + 8)
        else
            r_avoid = ImRect(ref_pos.x - 16, ref_pos.y - 8, ref_pos.x + 24 * scale, ref_pos.y + 24 * scale)  -- FIXME: Hard-coded based on mouse cursor shape expectation. Exact dimension not very important.
        end

        return ImGui.FindBestWindowPosForPopupEx(tooltip_pos, window.Size, window.AutoPosLastDirection, r_outer, r_avoid, ImGuiPopupPositionPolicy.Tooltip)
    end

    IM_ASSERT(false)

    return window.Pos
end

---------------------------------------------------------------------------------------
-- [SECTION] NAVIGATION
---------------------------------------------------------------------------------------

--- @param window_type ImGuiWindowFlags
--- @return ImGuiInputSource
function ImGui.NavCalcPreferredRefPosSource(window_type)
    local g = GImGui
    local window = g.NavWindow

    local activated_shortcut = g.ActiveId ~= 0 and g.ActiveIdFromShortcut and g.ActiveId == g.LastItemData.ID
    if (bit.band(window_type, ImGuiWindowFlags_Popup) ~= 0) and activated_shortcut then
        return ImGuiInputSource_Keyboard
    end

    if not g.NavCursorVisible or not g.NavHighlightItemUnderNav or not window then
        return ImGuiInputSource_Mouse
    else
        return ImGuiInputSource_Keyboard  -- or Nav in general
    end
end

--- @param window_type ImGuiWindowFlags
--- @return ImVec2
--- @nodiscard
function ImGui.NavCalcPreferredRefPos(window_type)
    local g = GImGui
    local window = g.NavWindow
    local source = ImGui.NavCalcPreferredRefPosSource(window_type)

    if source == ImGuiInputSource_Mouse then
        -- Mouse (we need a fallback in case the mouse becomes invalid after being used)
        -- The +1.0f offset when stored by OpenPopupEx() allows reopening this or another popup (same or another mouse button) while not moving the mouse, it is pretty standard.
        -- In theory we could move that +1.0f offset in OpenPopupEx()
        local p = ImGui.IsMousePosValid(g.IO.MousePos) and g.IO.MousePos or g.MouseLastValidPos
        return ImVec2(p.x + 1.0, p.y)
    else
        -- When navigation is active and mouse is disabled, pick a position around the bottom left of the currently navigated item
        local activated_shortcut = g.ActiveId ~= 0 and g.ActiveIdFromShortcut and g.ActiveId == g.LastItemData.ID
        local ref_rect

        if activated_shortcut and (bit.band(window_type, ImGuiWindowFlags_Popup) ~= 0) then
            ref_rect = g.LastItemData.NavRect
        elseif window ~= nil then
            if g.NavLayer == 0 then
                ref_rect = ImGui.WindowRectRelToAbs(window, window.NavRectRel.x)
            elseif g.NavLayer == 1 then
                ref_rect = ImGui.WindowRectRelToAbs(window, window.NavRectRel.y)
            end
        end

        -- Take account of upcoming scrolling (maybe set mouse pos should be done in EndFrame?)
        if window ~= nil and window.LastFrameActive ~= g.FrameCount and (window.ScrollTarget.x ~= FLT_MAX or window.ScrollTarget.y ~= FLT_MAX) then
            local next_scroll = CalcNextScrollFromScrollTargetAndClamp(window)
            ref_rect:Translate(window.Scroll - next_scroll)
        end

        local pos = ImVec2(ref_rect.Min.x + ImMin(g.Style.FramePadding.x * 4, ref_rect:GetWidth()), ref_rect.Max.y - ImMin(g.Style.FramePadding.y, ref_rect:GetHeight()))

        local viewport = ImGui.GetMainViewport()
        return ImTruncV2(ImClampV2(pos, viewport.Pos, viewport.Pos + viewport.Size))  -- ImTrunc() is important because non-integer mouse position application in backend might be lossy and result in undesirable non-zero delta.
    end
end

function ImGui.NavMoveRequestCancel()
    -- TODO:
end