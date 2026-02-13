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
local WINDOWS_MOUSE_WHEEL_SCROLL_LOCK_TIMER    = 0.70

local TOOLTIP_DEFAULT_OFFSET_MOUSE = ImVec2(16, 10)   -- Multiplied by g.Style.MouseCursorScale
local TOOLTIP_DEFAULT_OFFSET_TOUCH = ImVec2(0, -20)   -- Multiplied by g.Style.MouseCursorScale
local TOOLTIP_DEFAULT_PIVOT_TOUCH  = ImVec2(0.5, 1.0) -- Multiplied by g.Style.MouseCursorScale

IMGUI_VIEWPORT_DEFAULT_ID = 0x11111111

local string = string
ImFormatString = string.format

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

--- Forward Declaration
local CalcNextScrollFromScrollTargetAndClamp

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
--- @param size int?         # size = -1 to indicate that `data` is a single number
--- @param seed int?
--- @return int
function ImHashData(data, size, seed)
    seed = seed or 0

    local FNV_OFFSET_BASIS = 0x811C9DC5
    local FNV_PRIME = 0x01000193

    local hash = bit.bxor(FNV_OFFSET_BASIS, seed)

    if size == -1 then --- @cast data number
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
--- @param str  string
--- @param seed int?
--- @param size int?
--- @return int
function ImHashStr(str, seed, size)
    if size == nil then size = #str end

    local data = {string.byte(str, 1, size)}
    return ImHashData(data, size, seed)
end

do --[[ImTextCharFromUtf8]]

local lengths = {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 2, 3, 3, 4, 0}
local masks   = {0x00, 0x7f, 0x1f, 0x0f, 0x07}
local mins    = {0x400000, 0, 0x80, 0x800, 0x10000}
local shiftc  = {0, 18, 12, 6, 0}
local shifte  = {0, 6, 4, 2, 0}

local s = {0, 0, 0, 0}

--- @param in_text     string
--- @param pos         int
--- @param in_text_end int
--- @return int, int
function ImTextCharFromUtf8(in_text, pos, in_text_end)
    local len = lengths[bit.rshift(string.byte(in_text, pos), 3) + 1]
    local wanted = len > 0 and len or 1

    if in_text_end == nil then
        in_text_end = pos + wanted
    end

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
    e = bit.bor(e, bit.rshift(s[4], 6))
    e = bit.bxor(e, 0x2a)
    e = bit.rshift(e, shifte[len + 1])

    if e ~= 0 then
        wanted = ImMin(wanted, (s[1] ~= 0 and 1 or 0) + (s[2] ~= 0 and 1 or 0) + (s[3] ~= 0 and 1 or 0) + (s[4] ~= 0 and 1 or 0))
        out_char = IM_UNICODE_CODEPOINT_INVALID
    end

    return wanted, out_char
end

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
    viewport.Idx = 1
    viewport.PlatformWindowCreated = true
    viewport.Flags = ImGuiViewportFlags_OwnedByApp
    g.Viewports:push_back(viewport)
    g.ViewportCreatedCount = g.ViewportCreatedCount + 1
    g.PlatformIO.Viewports:push_back(g.Viewports.Data[1])

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
    local main_viewport = ImGui.GetMainViewport()
    ImVec2_Copy(window.ViewportPos, main_viewport.Pos)
    if (settings.ViewportId ~= 0) then
        window.ViewportId = settings.ViewportId
        window.ViewportPos = ImVec2(settings.ViewportPos.x, settings.ViewportPos.y)
    end
    window.Pos = ImTruncV2(ImVec2(settings.Pos.x + window.ViewportPos.x, settings.Pos.y + window.ViewportPos.y))
    if settings.Size.x > 0 and settings.Size.y > 0 then
        local size = ImVec2(ImTrunc(settings.Size.x), ImTrunc(settings.Size.y))
        ImVec2_Copy(window.Size, size)
        ImVec2_Copy(window.SizeFull, size)
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
    window.Size = ImVec2(0, 0)
    window.SizeFull = ImVec2(0, 0)
    ImVec2_Copy(window.ViewportPos, main_viewport.Pos)
    window.SetWindowPosAllowFlags = bit.bor(ImGuiCond.Always, ImGuiCond.Once, ImGuiCond.FirstUseEver, ImGuiCond.Appearing)
    window.SetWindowSizeAllowFlags = window.SetWindowPosAllowFlags
    window.SetWindowCollapsedAllowFlags = window.SetWindowPosAllowFlags

    if settings ~= nil then
        SetWindowConditionAllowFlags(window, ImGuiCond.FirstUseEver, false)
        ApplyWindowSettings(window, settings)
    end
    window.DC.CursorStartPos = ImVec2(window.Pos.x, window.Pos.y) -- So first call to CalcWindowContentSizes() doesn't return crazy values
    ImVec2_Copy(window.DC.CursorMaxPos, window.DC.CursorStartPos)
    ImVec2_Copy(window.DC.IdealMaxPos, window.DC.CursorStartPos)

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

--- @param window ImGuiWindow
--- @return ImGuiWindow?
local function GetWindowForTitleDisplay(window)
    if window.DockNodeAsHost then
        return window.DockNodeAsHost.VisibleWindow
    else
        return window
    end
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
    if (not g.MouseViewport:GetMainRect():Overlaps(rect_clipped)) then
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
    ImRect_Copy(g.LastItemData.Rect, bb)
    g.LastItemData.NavRect = nav_bb_arg and nav_bb_arg or bb
    g.LastItemData.ItemFlags = bit.bor(g.CurrentItemFlags, g.NextItemData.ItemFlags, extra_flags)
    g.LastItemData.StatusFlags = ImGuiItemStatusFlags.None

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
        g.LastItemData.StatusFlags = bit.bor(g.LastItemData.StatusFlags, ImGuiItemStatusFlags.Visible)
    end

    if IsMouseHoveringRect(bb.Min, bb.Max) then
        g.LastItemData.StatusFlags = bit.bor(g.LastItemData.StatusFlags, ImGuiItemStatusFlags.HoveredRect)
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

-- Lock horizontal starting position + capture group bounding box into one "item" (so you can use IsItemHovered() or layout primitives such as SameLine() on whole group, etc.)
-- Groups are currently a mishmash of functionalities which should perhaps be clarified and separated.
-- FIXME-OPT: Could we safely early out on ->SkipItems?
function ImGui.BeginGroup()
    local g = GImGui
    local window = g.CurrentWindow

    local group_data = ImGuiGroupData()
    group_data.WindowID = window.ID
    ImVec2_Copy(group_data.BackupCursorPos, window.DC.CursorPos)
    ImVec2_Copy(group_data.BackupCursorPosPrevLine, window.DC.CursorPosPrevLine)
    ImVec2_Copy(group_data.BackupCursorMaxPos, window.DC.CursorMaxPos)
    ImVec1_Copy(group_data.BackupIndent, window.DC.Indent)
    ImVec1_Copy(group_data.BackupGroupOffset, window.DC.GroupOffset)
    ImVec2_Copy(group_data.BackupCurrLineSize, window.DC.CurrLineSize)
    group_data.BackupCurrLineTextBaseOffset = window.DC.CurrLineTextBaseOffset
    group_data.BackupActiveIdIsAlive = g.ActiveIdIsAlive
    group_data.BackupHoveredIdIsAlive = (g.HoveredId ~= 0)
    group_data.BackupIsSameLine = window.DC.IsSameLine
    group_data.BackupActiveIdHasBeenEditedThisFrame = g.ActiveIdHasBeenEditedThisFrame
    group_data.BackupDeactivatedIdIsAlive = g.DeactivatedItemData.IsAlive
    group_data.EmitItem = true

    g.GroupStack:push_back(group_data)

    window.DC.GroupOffset.x = window.DC.CursorPos.x - window.Pos.x - window.DC.ColumnsOffset.x
    ImVec1_Copy(window.DC.Indent, window.DC.GroupOffset)
    ImVec2_Copy(window.DC.CursorMaxPos, window.DC.CursorPos)
    ImVec2_Copy(window.DC.CurrLineSize, ImVec2(0.0, 0.0))
    if (g.LogEnabled) then
        g.LogLinePosY = -FLT_MAX
    end
end

function ImGui.EndGroup()
    local g = GImGui
    local window = g.CurrentWindow
    IM_ASSERT(g.GroupStack.Size > 0) -- Mismatched BeginGroup()/EndGroup() calls

    local group_data = g.GroupStack:back()
    IM_ASSERT(group_data.WindowID == window.ID) -- EndGroup() in wrong window?

    if (window.DC.IsSetPos) then
    -- TODO: ImGui.ErrorCheckUsingSetCursorPosToExtendParentBoundaries()
    end

    local group_bb = ImRect(group_data.BackupCursorPos, ImMaxVec2(ImMaxVec2(window.DC.CursorMaxPos, g.LastItemData.Rect.Max), group_data.BackupCursorPos))
    ImVec2_Copy(window.DC.CursorPos, group_data.BackupCursorPos)
    ImVec2_Copy(window.DC.CursorPosPrevLine, group_data.BackupCursorPosPrevLine)
    ImVec2_Copy(window.DC.CursorMaxPos, ImMaxVec2(group_data.BackupCursorMaxPos, group_bb.Max))
    ImVec1_Copy(window.DC.Indent, group_data.BackupIndent)
    ImVec1_Copy(window.DC.GroupOffset, group_data.BackupGroupOffset)
    ImVec2_Copy(window.DC.CurrLineSize, group_data.BackupCurrLineSize)
    window.DC.CurrLineTextBaseOffset = group_data.BackupCurrLineTextBaseOffset
    window.DC.IsSameLine = group_data.BackupIsSameLine
    if (g.LogEnabled) then
        g.LogLinePosY = -FLT_MAX -- To enforce a carriage return
    end

    if (not group_data.EmitItem) then
        g.GroupStack:pop_back()
        return
    end

    window.DC.CurrLineTextBaseOffset = ImMax(window.DC.PrevLineTextBaseOffset, group_data.BackupCurrLineTextBaseOffset) -- FIXME: Incorrect, we should grab the base offset from the *first line* of the group but it is hard to obtain now
    ImGui.ItemSize(group_bb:GetSize())
    ImGui.ItemAdd(group_bb, 0, nil, ImGuiItemFlags_NoTabStop)

    -- If the current ActiveId was declared within the boundary of our group, we copy it to LastItemId so IsItemActive(), IsItemDeactivated() etc. will be functional on the entire group.
    -- It would be neater if we replaced window.DC.LastItemId by e.g. 'bool LastItemIsActive', but would put a little more burden on individual widgets.
    -- Also if you grep for LastItemId you'll notice it is only used in that context.
    -- (The two tests not the same because ActiveIdIsAlive is an ID itself, in order to be able to handle ActiveId being overwritten during the frame.)
    local group_contains_curr_active_id = (group_data.BackupActiveIdIsAlive ~= g.ActiveId) and (g.ActiveIdIsAlive == g.ActiveId) and g.ActiveId
    local group_contains_deactivated_id = (group_data.BackupDeactivatedIdIsAlive == false) and (g.DeactivatedItemData.IsAlive == true)
    if group_contains_curr_active_id then
        g.LastItemData.ID = g.ActiveId
    elseif group_contains_deactivated_id then
        g.LastItemData.ID = g.DeactivatedItemData.ID
    end
    ImRect_Copy(g.LastItemData.Rect, group_bb)

    -- Forward Hovered flag
    local group_contains_curr_hovered_id = (group_data.BackupHoveredIdIsAlive == false) and g.HoveredId ~= 0
    if group_contains_curr_hovered_id then
        g.LastItemData.StatusFlags = bit.bor(g.LastItemData.StatusFlags, ImGuiItemStatusFlags.HoveredWindow)
    end

    -- Forward Edited flag
    if g.ActiveIdHasBeenEditedThisFrame and not group_data.BackupActiveIdHasBeenEditedThisFrame then
        g.LastItemData.StatusFlags = bit.bor(g.LastItemData.StatusFlags, ImGuiItemStatusFlags.Edited)
    end

    -- Forward Deactivated flag
    g.LastItemData.StatusFlags = bit.bor(g.LastItemData.StatusFlags, ImGuiItemStatusFlags.HasDeactivated)
    if group_contains_deactivated_id then
        g.LastItemData.StatusFlags = bit.bor(g.LastItemData.StatusFlags, ImGuiItemStatusFlags.Deactivated)
    end

    g.GroupStack:pop_back()
    if g.DebugShowGroupRects then
        window.DrawList:AddRect(group_bb.Min, group_bb.Max, IM_COL32(255, 0, 255, 255)) -- [Debug]
    end
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

---------------------------------------------------------------------------------------
-- [SECTION] WINDOW FOCUS
---------------------------------------------------------------------------------------

--- @param window? ImGuiWindow
--- @param flags?  ImGuiFocusRequestFlags
function ImGui.FocusWindow(window, flags)
    if flags == nil then flags = 0 end

    local g = GImGui
    -- TODO:
    if g.NavWindow ~= window then
        ImGui.SetNavWindow(window)

        -- Close popups if any
        ImGui.ClosePopupsOverWindow(window, false)
    end

    IM_ASSERT(window == nil or window.RootWindowDockTree ~= nil)
    local focus_front_window = window and window.RootWindow or nil
    local display_front_window = window and window.RootWindowDockTree or nil

    if not window then
        return
    end
    window.LastFrameJustFocused = g.FrameCount

    ImGui.BringWindowToFocusFront(focus_front_window)
    ImGui.BringWindowToDisplayFront(display_front_window)
end

--- @param window ImGuiWindow
--- @return int
function ImGui.FindWindowFocusIndex(window)
    local g = GImGui
    -- IM_UNUSED(g)
    local order = window.FocusOrder
    IM_ASSERT(window.RootWindow == window) -- No child window (not testing _ChildWindow because of docking)
    IM_ASSERT(g.WindowsFocusOrder.Data[order] == window)
    return order
end

function ImGui.UpdateWindowInFocusOrderList(window, just_created, new_flags)
    local g = GImGui

    local new_is_explicit_child = (bit.band(new_flags, ImGuiWindowFlags_ChildWindow) ~= 0) and ((bit.band(new_flags, ImGuiWindowFlags_Popup) == 0) or (bit.band(new_flags, ImGuiWindowFlags_ChildMenu) ~= 0))
    local child_flag_changed = (new_is_explicit_child ~= window.IsExplicitChild)

    if (just_created or child_flag_changed) and not new_is_explicit_child then
        IM_ASSERT(not g.WindowsFocusOrder:contains(window))
        g.WindowsFocusOrder:push_back(window)
        window.FocusOrder = g.WindowsFocusOrder.Size
    elseif not just_created and child_flag_changed and new_is_explicit_child then
        IM_ASSERT(g.WindowsFocusOrder.Data[window.FocusOrder] == window)

        for n = window.FocusOrder + 1, g.WindowsFocusOrder.Size do
            g.WindowsFocusOrder.Data[n].FocusOrder = g.WindowsFocusOrder.Data[n].FocusOrder - 1
        end

        g.WindowsFocusOrder:erase(window.FocusOrder)
        window.FocusOrder = -1
    end

    window.IsExplicitChild = new_is_explicit_child
end

--- @param window? ImGuiWindow
function ImGui.BringWindowToFocusFront(window)
    local g = GImGui
    IM_ASSERT(window == window.RootWindow)

    local cur_order = window.FocusOrder
    IM_ASSERT(g.WindowsFocusOrder.Data[cur_order] == window)

    if g.WindowsFocusOrder:back() == window then
        return
    end

    local new_order = g.WindowsFocusOrder.Size

    for n = cur_order, new_order - 1 do
        g.WindowsFocusOrder.Data[n] = g.WindowsFocusOrder.Data[n + 1]
        g.WindowsFocusOrder.Data[n].FocusOrder = g.WindowsFocusOrder.Data[n].FocusOrder - 1
        IM_ASSERT(g.WindowsFocusOrder.Data[n].FocusOrder == n)
    end

    g.WindowsFocusOrder.Data[new_order] = window
    window.FocusOrder = new_order
end

--- @param window? ImGuiWindow
function ImGui.BringWindowToDisplayFront(window)
    local g = GImGui

    local current_front_window = g.Windows:back()

    if current_front_window == window or current_front_window.RootWindowDockTree == window then
        return
    end

    for i, this_window in g.Windows:iter() do
        if this_window == window then
            g.Windows:erase(i)
            break
        end
    end

    g.Windows:push_back(window)
end

--- @param under_this_window? ImGuiWindow
--- @param ignore_window?     ImGuiWindow
--- @param filter_viewport?   ImGuiViewport
--- @param flags              ImGuiFocusRequestFlags
function ImGui.FocusTopMostWindowUnderOne(under_this_window, ignore_window, filter_viewport, flags)
    local g = GImGui
    local start_idx = g.WindowsFocusOrder.Size
    if under_this_window ~= nil then
        -- Aim at root window behind us, if we are in a child window that's our own root (see #4640)
        local offset = -1
        while bit.band(under_this_window.Flags, ImGuiWindowFlags_ChildWindow) ~= 0 do
            under_this_window = under_this_window.ParentWindow
            offset = 0
        end
        --- @cast under_this_window ImGuiWindow
        start_idx = ImGui.FindWindowFocusIndex(under_this_window) + offset
    end
    for i = start_idx, 1, -1 do
        local window = g.WindowsFocusOrder.Data[i]
        if window == ignore_window or not window.WasActive then
            goto CONTINUE
        end
        if filter_viewport ~= nil and window.Viewport ~= filter_viewport then
            goto CONTINUE
        end
        if bit.band(window.Flags, bit.bor(ImGuiWindowFlags_NoMouseInputs, ImGuiWindowFlags_NoNavInputs)) ~= bit.bor(ImGuiWindowFlags_NoMouseInputs, ImGuiWindowFlags_NoNavInputs) then
            ImGui.FocusWindow(window, flags)
            return
        end

        :: CONTINUE ::
    end
    ImGui.FocusWindow(nil, flags)
end

--- void ImGui::SetFocusID
function ImGui.SetFocusID(id, window)
    local g = GImGui
    IM_ASSERT(id ~= 0)

    if g.NavWindow ~= window then
        ImGui.SetNavWindow(window)
    end

    -- TODO:
end

function ImGui.StopMouseMovingWindow()
    local g = GImGui
    local window = g.MovingWindow

    if window and window.Viewport then
        if bit.band(g.ConfigFlagsCurrFrame, ImGuiConfigFlags_ViewportsEnable) ~= 0 then
            ImGui.UpdateTryMergeWindowIntoHostViewport(window.RootWindowDockTree, g.MouseViewport)
        end

        if (not ImGui.IsDragDropPayloadBeingAccepted()) then
            g.MouseViewport = window.Viewport
        end

        local window_can_use_inputs = bit.band(window.Flags, ImGuiWindowFlags_NoMouseInputs) == 0 or bit.band(window.Flags, ImGuiWindowFlags_NoNavInputs) == 0
        if window_can_use_inputs then
            window.Viewport.Flags = bit.band(window.Viewport.Flags, bit.bnot(ImGuiViewportFlags_NoInputs))
        end
    end

    g.MovingWindow = nil
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
            g.ActiveIdSource = ImGuiInputSource.Mouse
        end
        IM_ASSERT(g.ActiveIdSource ~= ImGuiInputSource.None)
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
        return ImHashData(id, -1, seed)
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

--- @param id ImGuiID
function ImGui.MarkItemEdited(id)
    -- This marking is to be able to provide info for IsItemDeactivatedAfterEdit().
    -- ActiveId might have been released by the time we call this (as in the typical press/release button behavior) but still need to fill the data.
    local g = GImGui
    if bit.band(g.LastItemData.ItemFlags, ImGuiItemFlags_NoMarkEdited) ~= 0 then
        return
    end

    if g.ActiveId == id or g.ActiveId == 0 then
        -- FIXME: Can't we fully rely on LastItemData yet?
        g.ActiveIdHasBeenEditedThisFrame = true
        g.ActiveIdHasBeenEditedBefore = true
        if g.DeactivatedItemData.ID == id then
            g.DeactivatedItemData.HasBeenEditedBefore = true
        end
    end

    -- We accept a MarkItemEdited() on drag and drop targets (see https://github.com/ocornut/imgui/issues/1875#issuecomment-978243343)
    -- We accept 'ActiveIdPreviousFrame == id' for InputText() returning an edit after it has been taken ActiveId away (#4714)
    -- FIXME: This assert is getting a bit meaningless over time. It helped detect some unusual use cases but eventually it is becoming an unnecessary restriction.
    IM_ASSERT(g.DragDropActive or g.ActiveId == id or g.ActiveId == 0 or g.ActiveIdPreviousFrame == id or g.NavJustMovedToId or (g.CurrentMultiSelect ~= nil and g.BoxSelectState.IsActive))

    -- IM_ASSERT(g.CurrentWindow.DC.LastItemId == id)
    g.LastItemData.StatusFlags = bit.bor(g.LastItemData.StatusFlags, ImGuiItemStatusFlags.Edited)
end

--- @param window ImGuiWindow
--- @param flags  ImGuiHoveredFlags
function ImGui.IsWindowContentHoverable(window, flags)
    -- An active popup disable hovering on other windows (apart from its own children)
    -- FIXME-OPT: This could be cached/stored within the window.
    local g = GImGui
    if g.NavWindow then
        local focused_root_window = g.NavWindow.RootWindowDockTree
        if focused_root_window.WasActive and focused_root_window ~= window.RootWindowDockTree then
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

    -- Filter by viewport
    if (window.Viewport ~= g.MouseViewport) then
        if (g.MovingWindow == nil or window.RootWindowDockTree ~= g.MovingWindow.RootWindowDockTree) then
            return false
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
        if bit.band(status_flags, ImGuiItemStatusFlags.HoveredRect) == 0 then
            return false
        end

        if bit.band(flags, ImGuiHoveredFlags_ForTooltip) ~= 0 then
            flags = ApplyHoverFlagsForTooltip(flags, g.Style.HoverFlagsForTooltipMouse)
        end

        if g.HoveredWindow ~= window and bit.band(status_flags, ImGuiItemStatusFlags.HoveredWindow) == 0 then
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

        if id == g.LastItemData.ID and (bit.band(g.LastItemData.StatusFlags, ImGuiItemStatusFlags.HasShortcut) ~= 0) and g.ActiveId ~= id then
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
    for key = ImGuiKey.NamedKey_BEGIN, ImGuiKey.NamedKey_END - 1 do
        if ImGui.IsMouseKey(key) then
            goto CONTINUE
        end

        local key_data = g.IO.KeysData[key - ImGuiKey.NamedKey_BEGIN]
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
        local key_data = self.KeysData[key - ImGuiKey.NamedKey_BEGIN]
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
    repeat
        local e = g.InputEventsQueue.Data[n]

        if e.Type ~= type then
            do break end --[[continue]]
        end
        if type == ImGuiInputEventType.Key and e.Key.Key ~= arg then
            do break end --[[continue]]
        end
        if type == ImGuiInputEventType.MouseButton and e.MouseButton.Button ~= arg then
            do break end --[[continue]]
        end

        return e
    until true
    end

    return nil
end

--- @param key          ImGuiKey
--- @param down         bool
--- @param analog_value float
function MT.ImGuiIO:AddKeyAnalogEvent(key, down, analog_value)
    IM_ASSERT(self.Ctx ~= nil)
    if key == ImGuiKey.None or not self.AppAcceptingEvents then
        return
    end

    local g = self.Ctx
    IM_ASSERT(ImGui.IsNamedKeyOrMod(key))
    IM_ASSERT(ImGui.IsAliasKey(key) == false)

    -- MacOS: swap Cmd(Super) and Ctrl
    if (g.IO.ConfigMacOSXBehaviors) then
        if (key == ImGuiMod_Super)          then key = ImGuiMod_Ctrl
        elseif (key == ImGuiMod_Ctrl)       then key = ImGuiMod_Super
        elseif (key == ImGuiKey.LeftSuper)  then key = ImGuiKey.LeftCtrl
        elseif (key == ImGuiKey.RightSuper) then key = ImGuiKey.RightCtrl
        elseif (key == ImGuiKey.LeftCtrl)   then key = ImGuiKey.LeftSuper
        elseif (key == ImGuiKey.RightCtrl)  then key = ImGuiKey.RightSuper
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
    e.Source = ImGui.IsGamepadKey(key) and ImGuiInputSource.Gamepad or ImGuiInputSource.Keyboard
    e.EventId = g.InputEventsNextEventId
    g.InputEventsNextEventId = g.InputEventsNextEventId + 1
    e.Key = ImGuiInputEventKey()
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

--- @param viewport_id ImGuiID
function MT.ImGuiIO:AddMouseViewportEvent(viewport_id)
    IM_ASSERT(self.Ctx ~= nil)
    local g = self.Ctx
    -- IM_ASSERT(g.IO.BackendFlags & ImGuiBackendFlags.HasMouseHoveredViewport);
    if (not self.AppAcceptingEvents) then
        return
    end

    -- Filter duplicate
    local latest_event = self:FindLatestInputEvent(g, ImGuiInputEventType.MouseViewport)
    local latest_viewport_id
    if latest_event then
        latest_viewport_id = latest_event.MouseViewport.HoveredViewportID
    else
        latest_viewport_id = g.IO.MouseHoveredViewport
    end
    if (latest_viewport_id == viewport_id) then
        return
    end

    local e = ImGuiInputEvent()
    e.Type = ImGuiInputEventType.MouseViewport
    e.Source = ImGuiInputSource.Mouse
    e.MouseViewport = ImGuiInputEventMouseViewport()
    e.MouseViewport.HoveredViewportID = viewport_id
    g.InputEventsQueue:push_back(e)
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
    e.Source = ImGuiInputSource.Mouse
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
    IM_ASSERT(mouse_button >= 0 and mouse_button < ImGuiMouseButton.COUNT)
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
    e.Source = ImGuiInputSource.Mouse
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
    e.Source = ImGuiInputSource.Mouse
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
    return ctx.IO.KeysData[key - ImGuiKey.NamedKey_BEGIN]
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

--- @return bool
function ImGui.IsAnyMouseDown()
    local g = GImGui
    for n = 0, 2 do -- IM_COUNTOF(g.IO.MouseDown) - 1
        if g.IO.MouseDown[n] then
            return true
        end
    end
    return false
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
                goto CONTINUE
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
            IM_ASSERT(button >= 0 and button < ImGuiMouseButton.COUNT)
            if trickle_fast_inputs and ((bit.band(mouse_button_changed, bit.lshift(1, button)) ~= 0) or mouse_wheeled) then
                break
            end
            if trickle_fast_inputs and e.MouseButton.MouseSource == ImGuiMouseSource.TouchScreen and mouse_moved then
                break
            end

            io.MouseDown[button] = e.MouseButton.Down
            io.MouseSource = e.MouseButton.MouseSource
            mouse_button_changed = bit.bor(mouse_button_changed, bit.lshift(1, button))
        elseif e.Type == ImGuiInputEventType.MouseWheel then
            if trickle_fast_inputs and (mouse_moved or mouse_button_changed ~= 0) then
                break
            end

            io.MouseWheelH = io.MouseWheelH + e.MouseWheel.WheelX
            io.MouseWheel = io.MouseWheel + e.MouseWheel.WheelY
            io.MouseSource = e.MouseWheel.MouseSource
            mouse_wheeled = true
        elseif e.Type == ImGuiInputEventType.MouseViewport then
            io.MouseHoveredViewport = e.MouseViewport.HoveredViewportID
        elseif e.Type == ImGuiInputEventType.Key then
            -- TODO:
        elseif e.Type == ImGuiInputEventType.Text then
            -- TODO:
        elseif e.Type == ImGuiInputEventType.Focus then
            -- TODO:
        else
            IM_ASSERT(false, "Unknown event!")
        end

        event_n = event_n + 1

        :: CONTINUE ::
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
function ImGui.IsWindowActiveAndVisible(window)
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

    local new_size = ImVec2()
    ImVec2_Copy(new_size, size_desired)

    if bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasSizeConstraint) ~= 0 then
        local cr = ImRect()
        ImRect_Copy(cr, g.NextWindowData.SizeConstraintRect)

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

--- @param window               ImGuiWindow
--- @param content_size_current ImVec2
--- @param content_size_ideal   ImVec2
local function CalcWindowContentSizes(window, content_size_current, content_size_ideal)
    local preserve_old_content_sizes = false
    if (window.Collapsed and window.AutoFitFramesX <= 0 and window.AutoFitFramesY <= 0) then
        preserve_old_content_sizes = true
    elseif (window.Hidden and window.HiddenFramesCannotSkipItems == 0 and window.HiddenFramesCanSkipItems > 0) then
        preserve_old_content_sizes = true
    end
    if preserve_old_content_sizes then
        content_size_current.x = window.ContentSize.x;      content_size_current.y = window.ContentSize.y
        content_size_current.x = window.ContentSizeIdeal.x; content_size_current.y = window.ContentSizeIdeal.y
    end

    if (window.ContentSizeExplicit.x ~= 0.0) then content_size_current.x = window.ContentSizeExplicit.x else content_size_current.x = ImTrunc64(window.DC.CursorMaxPos.x - window.DC.CursorStartPos.x) end
    if (window.ContentSizeExplicit.y ~= 0.0) then content_size_current.y = window.ContentSizeExplicit.y else content_size_current.y = ImTrunc64(window.DC.CursorMaxPos.y - window.DC.CursorStartPos.y) end
    if (window.ContentSizeExplicit.x ~= 0.0) then content_size_ideal.x = window.ContentSizeExplicit.x else content_size_ideal.x = ImTrunc64(ImMax(window.DC.CursorMaxPos.x, window.DC.IdealMaxPos.x) - window.DC.CursorStartPos.x) end
    if (window.ContentSizeExplicit.y ~= 0.0) then content_size_ideal.y = window.ContentSizeExplicit.y else content_size_ideal.y = ImTrunc64(ImMax(window.DC.CursorMaxPos.y, window.DC.IdealMaxPos.y) - window.DC.CursorStartPos.y) end
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

    local size_max = ImVec2(FLT_MAX, FLT_MAX)
    if bit.band(window.Flags, ImGuiWindowFlags_ChildWindow) == 0 or bit.band(window.Flags, ImGuiWindowFlags_Popup) ~= 0 then
        if not window.ViewportOwned then
            size_max = ImGui.GetMainViewport().WorkSize - style.DisplaySafeAreaPadding * 2.0
        end
        local monitor_idx = window.ViewportAllowPlatformMonitorExtend
        if monitor_idx >= 1 and monitor_idx <= g.PlatformIO.Monitors.Size then
            size_max = g.PlatformIO.Monitors.Data[monitor_idx].WorkSize - style.DisplaySafeAreaPadding * 2.0
        end
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

--- @param window ImGuiWindow
--- @return ImVec2
function ImGui.CalcWindowNextAutoFitSize(window)
    local size_contents_current = ImVec2()
    local size_contents_ideal = ImVec2()
    CalcWindowContentSizes(window, size_contents_current, size_contents_ideal)
    local size_auto_fit = CalcWindowAutoFitSize(window, size_contents_ideal, -1)
    local size_final = CalcWindowSizeAfterConstraint(window, size_auto_fit)
    return size_final
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
    local corner_target = ImVec2()
    ImVec2_Copy(corner_target, corner_target_arg)

    if bit.band(window.Flags, ImGuiWindowFlags_ChildWindow) ~= 0 then
        local parent_window = window.ParentWindow
        local parent_flags = parent_window.Flags

        local limit_rect = ImRect()
        ImRect_Copy(limit_rect, parent_window.InnerRect)
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

    -- Clip mouse interaction rectangles within the viewport rectangle (in practice the narrowing is going to happen most of the time).
    -- - Not narrowing would mostly benefit the situation where OS windows _without_ decoration have a threshold for hovering when outside their limits.
    --   This is however not the case with current backends under Win32, but a custom borderless window implementation would benefit from it.
    -- - When decoration are enabled we typically benefit from that distance, but then our resize elements would be conflicting with OS resize elements, so we also narrow.
    -- - Note that we are unable to tell if the platform setup allows hovering with a distance threshold (on Win32, decorated window have such threshold).
    -- We only clip interaction so we overwrite window->ClipRect, cannot call PushClipRect() yet as DrawList is not yet setup.
    local clip_with_viewport_rect = bit.band(g.IO.BackendFlags, ImGuiBackendFlags.HasMouseHoveredViewport) == 0 or g.IO.MouseHoveredViewport ~= window.ViewportId or bit.band(window.Viewport.Flags, ImGuiViewportFlags_NoDecoration) == 0
    if (clip_with_viewport_rect) then
        ImRect_Copy(window.ClipRect, window.Viewport:GetMainRect())
    end

    local clamp_rect = ImRect()
    ImRect_Copy(clamp_rect, visibility_rect)

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
            goto CONTINUE
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
            local border_target = ImVec2()
            ImVec2_Copy(border_target, window.Pos)
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

        :: CONTINUE ::
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
--- @return int # Exclusive upper bound
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

--- @param pos                  ImVec2
--- @param text                 string
--- @param text_end             int?
--- @param hide_text_after_hash bool?  # true by default
function ImGui.RenderText(pos, text, text_end, hide_text_after_hash)
    if hide_text_after_hash == nil then hide_text_after_hash = true end

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

    local pos = ImVec2()
    ImVec2_Copy(pos, pos_min)

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

function ImGui.RenderNavCursor(bb, id, flags)
    -- TODO:
end

do --[[ImGui.RenderMouseCursor]]

local offset = ImVec2()
local size   = ImVec2()
local uv_border = {ImVec2(), ImVec2()}
local uv_fill   = {ImVec2(), ImVec2()}

--- @param base_pos     ImVec2
--- @param base_scale   float
--- @param mouse_cursor ImGuiMouseCursor
--- @param col_fill     ImU32
--- @param col_border   ImU32
--- @param col_shadow   ImU32
function ImGui.RenderMouseCursor(base_pos, base_scale, mouse_cursor, col_fill, col_border, col_shadow)
    local g = GImGui
    if mouse_cursor <= ImGuiMouseCursor.None or mouse_cursor >= ImGuiMouseCursor.COUNT then -- We intentionally accept out of bound values
        mouse_cursor = ImGuiMouseCursor.Arrow
    end
    local font_atlas = g.DrawListSharedData.FontAtlas

    for _, viewport in g.Viewports:iter() do
        if not ImFontAtlasGetMouseCursorTexData(font_atlas, mouse_cursor, offset, size, uv_border, uv_fill) then
            goto CONTINUE
        end

        local pos = base_pos - offset
        local scale = base_scale * viewport.DpiScale
        if not viewport:GetMainRect():Overlaps(ImRect(pos, pos + ImVec2(size.x + 2, size.y + 2) * scale)) then
            goto CONTINUE
        end

        local draw_list = ImGui.GetForegroundDrawList(viewport)
        local tex_ref = font_atlas.TexRef
        draw_list:PushTexture(tex_ref);
        draw_list:AddImage(tex_ref, pos + ImVec2(1, 0) * scale, pos + (ImVec2(1, 0) + size) * scale, uv_fill[1], uv_fill[2], col_shadow)
        draw_list:AddImage(tex_ref, pos + ImVec2(2, 0) * scale, pos + (ImVec2(2, 0) + size) * scale, uv_fill[1], uv_fill[2], col_shadow)
        draw_list:AddImage(tex_ref, pos,                        pos + size * scale,                  uv_fill[1], uv_fill[2], col_border)
        draw_list:AddImage(tex_ref, pos,                        pos + size * scale,                  uv_border[1], uv_border[2], col_fill)
        if mouse_cursor == ImGuiMouseCursor.Wait or mouse_cursor == ImGuiMouseCursor.Progress then
            local a_min = ImFmod(g.Time * 5.0, 2.0 * IM_PI)
            local a_max = a_min + IM_PI * 1.65
            draw_list:PathArcTo(pos + ImVec2(14, -1) * scale, 6.0 * scale, a_min, a_max)
            draw_list:PathStroke(col_fill, ImDrawFlags_None, 3.0 * scale)
        end
        draw_list:PopTexture()

        :: CONTINUE ::
    end
end

end

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
        text_size = ImVec2()
        ImVec2_Copy(text_size, text_size_if_known)
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

--- @param p_min    ImVec2
--- @param p_max    ImVec2
--- @param rounding float
function ImGui.RenderFrameBorder(p_min, p_max, rounding)
    local g = GImGui
    local window = g.CurrentWindow
    local border_size = g.Style.FrameBorderSize
    if border_size > 0.0 then
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

        if window.ScrollbarX then
            ImGui.Scrollbar(ImGuiAxis.X)
        end
        if window.ScrollbarY then
            ImGui.Scrollbar(ImGuiAxis.Y)
        end

        -- Resize grip(s)
        if handle_borders_and_resize_grips and (bit.band(flags, ImGuiWindowFlags_NoResize) == 0) then
            for i = 1, #ImGuiResizeGripDef do
                local col = resize_grip_col[i]
                if bit.band(col, IM_COL32_A_MASK) == 0 then goto CONTINUE end

                local inner_dir = ImGuiResizeGripDef[i].InnerDir
                local corner = window.Pos + ImGuiResizeGripDef[i].CornerPosN * window.Size
                local border_inner = IM_ROUND(window_border_size * 0.5)
                window.DrawList:PathLineTo(corner + inner_dir * ((i % 2 == 0) and ImVec2(border_inner, resize_grip_draw_size) or ImVec2(resize_grip_draw_size, border_inner)))
                window.DrawList:PathLineTo(corner + inner_dir * ((i % 2 == 0) and ImVec2(resize_grip_draw_size, border_inner) or ImVec2(border_inner, resize_grip_draw_size)))
                window.DrawList:PathArcToFast(ImVec2(corner.x + inner_dir.x * (window_rounding + border_inner), corner.y + inner_dir.y * (window_rounding + border_inner)), window_rounding, ImGuiResizeGripDef[i].AngleMin12, ImGuiResizeGripDef[i].AngleMax12)
                window.DrawList:PathFillConvex(col)

                :: CONTINUE ::
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
    window.RootWindowDockTree             = window
    window.RootWindowForTitleBarHighlight = window
    window.RootWindowForNav               = window

    if parent_window and (bit.band(flags, ImGuiWindowFlags_ChildWindow) ~= 0) and (bit.band(flags, ImGuiWindowFlags_Tooltip) == 0) then
        window.RootWindowDockTree = parent_window.RootWindowDockTree
        if not window.DockIsActive and (bit.band(parent_window.Flags, ImGuiWindowFlags_DockNodeHost) == 0) then
            window.RootWindow = parent_window.RootWindow
        end
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

    local old_pos = ImVec2()
    ImVec2_Copy(old_pos, window.Pos)

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

    -- local old_size = ImVec2()
    -- ImVec2_Copy(old_size, window.SizeFull)

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

    g.NextWindowData.HasFlags = bit.bor(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasPos)
    ImVec2_Copy(g.NextWindowData.PosVal, pos)
    ImVec2_Copy(g.NextWindowData.PosPivotVal, pivot)
    g.NextWindowData.PosCond = (cond ~= 0) and cond or ImGuiCond.Always
end

--- @param size  ImVec2
--- @param cond? ImGuiCond
function ImGui.SetNextWindowSize(size, cond)
    if cond == nil then cond = 0 end

    local g = GImGui
    IM_ASSERT(cond == 0 or ImIsPowerOfTwo(cond))

    g.NextWindowData.HasFlags = bit.bor(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasSize)
    ImVec2_Copy(g.NextWindowData.SizeVal, size)
    g.NextWindowData.SizeCond = (cond ~= 0) and cond or ImGuiCond.Always
end

-- For each axis:
-- - Use 0.0f as min or FLT_MAX as max if you don't want limits, e.g. size_min = (500.0f, 0.0f), size_max = (FLT_MAX, FLT_MAX) sets a minimum width.
-- - Use -1 for both min and max of same axis to preserve current size which itself is a constraint.
-- - See "Demo->Examples->Constrained-resizing window" for examples.
--- @param size_min                   ImVec2
--- @param size_max                   ImVec2
--- @param custom_callback?           function
--- @param custom_callback_user_data? any
function ImGui.SetNextWindowSizeConstraints(size_min, size_max, custom_callback, custom_callback_user_data)
    local g = GImGui
    g.NextWindowData.HasFlags = bit.bor(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasSizeConstraint)
    g.NextWindowData.SizeConstraintRect = ImRect(size_min, size_max)
    g.NextWindowData.SizeCallback = custom_callback
    g.NextWindowData.SizeCallbackUserData = custom_callback_user_data
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
    g.ActiveIdClickOffset = g.IO.MouseClickedPos[0] - window.RootWindowDockTree.Pos
    g.ActiveIdNoClearOnFocusLoss = true
    ImGui.SetActiveIdUsingAllKeyboardKeys()

    local can_move_window = true
    if bit.band(window.Flags, ImGuiWindowFlags_NoMove) ~= 0 or bit.band(window.RootWindowDockTree.Flags, ImGuiWindowFlags_NoMove) ~= 0 then
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

        local window_disappeared = (not moving_window.WasActive and not moving_window.Active)
        if g.IO.MouseDown[0] and ImGui.IsMousePosValid(g.IO.MousePos) and not window_disappeared then
            local pos = g.IO.MousePos - g.ActiveIdClickOffset
            if moving_window.Pos.x ~= pos.x or moving_window.Pos.y ~= pos.y then
                ImGui.SetWindowPos(moving_window, pos, ImGuiCond.Always)
                if moving_window.Viewport and moving_window.ViewportOwned then -- Synchronize viewport immediately because some overlays may relies on clipping rectangle before we Begin() into the window.
                    ImVec2_Copy(moving_window.Viewport.Pos, pos)
                    moving_window.Viewport:UpdateWorkRect()
                end
            end
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

--- @return ImGuiWindow?
function ImGui.GetTopMostPopupModal()
    local g = GImGui
    for n = g.OpenPopupStack.Size, 1, -1 do
        local popup = g.OpenPopupStack.Data[n].Window
        if bit.band(popup.Flags, ImGuiWindowFlags_Modal) ~= 0 then
            return popup
        end
    end
    return nil
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

    -- With right mouse button we close popups without changing focus based on where the mouse is aimed
    -- Instead, focus will be restored to the window under the bottom-most closed popup.
    -- (The left mouse button path calls FocusWindow on the hovered window, which will lead NewFrame->ClosePopupsOverWindow to trigger)
    if g.IO.MouseClicked[1] and g.HoveredId == 0 then
        -- Find the top-most window between HoveredWindow and the top-most Modal Window.
        -- This is where we can trim the popup stack.
        local modal = ImGui.GetTopMostPopupModal()
        local hovered_window_above_modal = hovered_window and (modal == nil or ImGui.IsWindowAbove(hovered_window, modal))
        ImGui.ClosePopupsOverWindow(hovered_window_above_modal and hovered_window or modal, true)
    end
end

--- @param window ImGuiWindow
--- @param delta  ImVec2
function ImGui.TranslateWindow(window, delta)
    window.Pos = window.Pos + delta
    window.ClipRect:Translate(delta)
    window.OuterRectClipped:Translate(delta)
    window.InnerRect:Translate(delta)

    window.DC.CursorPos      = window.DC.CursorPos + delta
    window.DC.CursorStartPos = window.DC.CursorStartPos + delta
    window.DC.CursorMaxPos   = window.DC.CursorMaxPos + delta
    window.DC.IdealMaxPos    = window.DC.IdealMaxPos + delta
end

--- ImGui::FindWindowByID
function ImGui.FindWindowByID(id)
    local g = GImGui

    if not g then return end

    return g.WindowsById[id]
end

--- @param name string
--- @return ImGuiWindow?
function ImGui.FindWindowByName(name)
    local id = ImHashStr(name)
    return ImGui.FindWindowByID(id)
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
    if bit.band(flags, ImGuiWindowFlags_Popup) ~= 0 then
        local popup_ref = g.OpenPopupStack.Data[g.BeginPopupStack.Size + 1]
        window_just_activated_by_user = window_just_activated_by_user or (window.PopupId ~= popup_ref.PopupId) -- We recycle popups so treat window as activated if popup id changed
        window_just_activated_by_user = window_just_activated_by_user or (window ~= popup_ref.Window)
    end

    window.Appearing = window_just_activated_by_user
    if (window.Appearing) then
        SetWindowConditionAllowFlags(window, ImGuiCond.Appearing, true)
    end

    -- Update Flags, LastFrameActive, BeginOrderXXX fields
    local window_was_appearing = window.Appearing
    if first_begin_of_the_frame then
        ImGui.UpdateWindowInFocusOrderList(window, window_just_created, flags)
        window.Appearing = window_just_activated_by_user
        if (window.Appearing) then
            SetWindowConditionAllowFlags(window, ImGuiCond.Appearing, true)
        end
        window.FlagsPreviousFrame = window.Flags
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

    -- Add to popup stacks: update OpenPopupStack data, push to BeginPopupStack
    if bit.band(flags, ImGuiWindowFlags_Popup) ~= 0 then
        local popup_ref = g.OpenPopupStack.Data[g.BeginPopupStack.Size + 1]
        popup_ref.Window = window
        popup_ref.ParentNavLayer = parent_window_in_stack.DC.NavLayerCurrent
        g.BeginPopupStack:push_back(popup_ref)
        window.PopupId = popup_ref.PopupId
    end

    local window_pos_set_by_api = false
    local window_size_x_set_by_api = false
    local window_size_y_set_by_api = false
    if bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasPos) ~= 0 then
        window_pos_set_by_api = (bit.band(window.SetWindowPosAllowFlags, g.NextWindowData.PosCond) ~= 0)
        if window_pos_set_by_api and ImLengthSqr(g.NextWindowData.PosPivotVal) > 1e-5 then
            -- FIXME: Look into removing the branch so everything can go through this same code path for consistency.
            ImVec2_Copy(window.SetWindowPosVal, g.NextWindowData.PosVal)
            ImVec2_Copy(window.SetWindowPosPivot, g.NextWindowData.PosPivotVal)
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
        ImVec2_Copy(window.ContentSizeExplicit, g.NextWindowData.ContentSizeVal)
    elseif first_begin_of_the_frame then
        window.ContentSizeExplicit = ImVec2(0.0, 0.0)
    end
    if bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasWindowClass) ~= 0 then
        window.WindowClass = g.NextWindowData.WindowClass
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
        ImRect_CopyFromV4(window.ClipRect, ImVec4(-FLT_MAX, -FLT_MAX, FLT_MAX, FLT_MAX))

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

        -- SELECT VIEWPORT
        ImGui.WindowSelectViewport(window)
        ImGui.SetCurrentViewport(window, window.Viewport)
        SetCurrentWindow(window)
        flags = window.Flags

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

        local scrollbar_sizes_from_last_frame = ImVec2()
        ImVec2_Copy(scrollbar_sizes_from_last_frame, window.ScrollbarSizes)

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

        -- POSITION

        -- Popup latch its initial position, will position itself when it appears next frame
        if window_just_activated_by_user then
            window.AutoPosLastDirection = ImGuiDir.None
            if bit.band(flags, ImGuiWindowFlags_Popup) ~= 0 and bit.band(flags, ImGuiWindowFlags_Modal) == 0 and not window_pos_set_by_api then -- FIXME: BeginPopup() could use SetNextWindowPos()
                ImVec2_Copy(window.Pos, g.BeginPopupStack:back().OpenPopupPos)
            end
        end

        if bit.band(flags, ImGuiWindowFlags_ChildWindow) ~= 0 then
            IM_ASSERT(parent_window and parent_window.Active)
            window.BeginOrderWithinParent = parent_window.DC.ChildWindows.Size
            parent_window.DC.ChildWindows:push_back(window)
            if (bit.band(flags, ImGuiWindowFlags_Popup) == 0) and not window_pos_set_by_api and not window_is_child_tooltip then
                ImVec2_Copy(window.Pos, parent_window.DC.CursorPos)
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

        -- Late create viewport if we don't fit within our current host viewport.
        if window.ViewportAllowPlatformMonitorExtend >= 0 and not window.ViewportOwned and bit.band(window.Viewport.Flags, ImGuiViewportFlags_IsMinimized) == 0 then
            if not window.Viewport:GetMainRect():Contains(window:Rect()) then
                -- This is based on the assumption that the DPI will be known ahead (same as the DPI of the selection done in UpdateSelectWindowViewport)
                -- local old_viewport = window.Viewport
                window.Viewport = ImGui.AddUpdateViewport(window, window.ID, window.Pos, window.Size, ImGuiViewportFlags_NoFocusOnAppearing)

                -- FIXME-DPI
                -- IM_ASSERT(old_viewport.DpiScale == window.Viewport.DpiScale) -- FIXME-DPI: Something went wrong
                ImGui.SetCurrentViewport(window, window.Viewport)
                SetCurrentWindow(window)
            end
        end

        if window.ViewportOwned then
            ImGui.WindowSyncOwnedViewport(window, parent_window_in_stack)
        end

        local viewport_rect = window.Viewport:GetMainRect()
        local viewport_work_rect = window.Viewport:GetWorkRect()
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

        -- Synchronize window --> viewport again and one last time (clamping and manual resize may have affected either)
        if window.ViewportOwned then
            if not window.Viewport.PlatformRequestMove then
                ImVec2_Copy(window.Viewport.Pos, window.Pos)
            end
            if not window.Viewport.PlatformRequestResize then
                ImVec2_Copy(window.Viewport.Size, window.Size)
            end
            window.Viewport:UpdateWorkRect()
            viewport_rect = window.Viewport:GetMainRect()
        end

        -- Save last known viewport position within the window itself (so it can be saved in .ini file and restored)
        ImVec2_Copy(window.ViewportPos, window.Viewport.Pos)

        --- SCROLLBAR VISIBILITY
        -- Update scrollbar visibility (based on the Size that was effective during last frame or the auto-resized Size)
        if not window.Collapsed then
            -- When reading the current size we need to read it after size constraints have been applied.
            -- Intentionally use previous frame values for InnerRect and ScrollbarSizes.
            -- And when we use window.DecoOuterSizeY1 here it doesn't have ScrollbarSizes.y applied yet.
            local avail_size_from_current_frame = ImVec2(window.SizeFull.x, window.SizeFull.y - (window.DecoOuterSizeY1 + window.DecoOuterSizeY2))
            local avail_size_from_last_frame = window.InnerRect:GetSize() + scrollbar_sizes_from_last_frame
            local needed_size_from_last_frame = window_just_created and ImVec2(0, 0) or window.ContentSize + window.WindowPadding * 2.0

            local size_x_for_scrollbars = use_current_size_for_scrollbar_x and avail_size_from_current_frame.x or avail_size_from_last_frame.x
            local size_y_for_scrollbars = use_current_size_for_scrollbar_y and avail_size_from_current_frame.y or avail_size_from_last_frame.y

            local scrollbar_x_prev = window.ScrollbarX
            -- local scrollbar_y_from_last_frame = window.ScrollbarY -- FIXME: May want to use that in the ScrollbarX expression? How many pros vs cons?

            window.ScrollbarY = (bit.band(flags, ImGuiWindowFlags_AlwaysVerticalScrollbar) ~= 0) or ((needed_size_from_last_frame.y > size_y_for_scrollbars) and not (bit.band(flags, ImGuiWindowFlags_NoScrollbar) ~= 0))
            window.ScrollbarX = (bit.band(flags, ImGuiWindowFlags_AlwaysHorizontalScrollbar) ~= 0) or ((needed_size_from_last_frame.x > size_x_for_scrollbars - (window.ScrollbarY and style.ScrollbarSize or 0.0)) and not (bit.band(flags, ImGuiWindowFlags_NoScrollbar) ~= 0) and (bit.band(flags, ImGuiWindowFlags_HorizontalScrollbar) ~= 0))

            -- Track when ScrollbarX visibility keeps toggling, which is a sign of a feedback loop, and stabilize by enforcing visibility (#3285, #8488)
            -- (Feedback loops of this sort can manifest in various situations, but combining horizontal + vertical scrollbar + using a clipper with varying width items is one frequent cause.
            --  The better solution is to, either (1) enforce visibility by using ImGuiWindowFlags_AlwaysHorizontalScrollbar or (2) declare stable contents width with SetNextWindowContentSize(), if you can compute it)
            window.ScrollbarXStabilizeToggledHistory = bit.lshift(window.ScrollbarXStabilizeToggledHistory, 1)
            if scrollbar_x_prev ~= window.ScrollbarX then
                window.ScrollbarXStabilizeToggledHistory = bit.bor(window.ScrollbarXStabilizeToggledHistory, 0x01)
            end

            local scrollbar_x_stabilize = (window.ScrollbarXStabilizeToggledHistory ~= 0) and ImCountSetBits(window.ScrollbarXStabilizeToggledHistory) >= 4 -- 4 == half of bits in our U8 history.
            if scrollbar_x_stabilize then
                window.ScrollbarX = true
            end

            -- if scrollbar_x_stabilize and not window.ScrollbarXStabilizeEnabled then
            --     IMGUI_DEBUG_LOG("[scroll] Stabilize ScrollbarX for Window '%s'\n", window.Name)
            -- end
            window.ScrollbarXStabilizeEnabled = scrollbar_x_stabilize

            if window.ScrollbarX and not window.ScrollbarY then
                window.ScrollbarY = (needed_size_from_last_frame.y > size_y_for_scrollbars - style.ScrollbarSize) and not (bit.band(flags, ImGuiWindowFlags_NoScrollbar) ~= 0)
            end

            window.ScrollbarSizes = ImVec2(window.ScrollbarY and style.ScrollbarSize or 0.0, window.ScrollbarX and style.ScrollbarSize or 0.0)

            -- Amend the partially filled window.DecoOuterSizeX2 values.
            window.DecoOuterSizeX2 = window.DecoOuterSizeX2 + window.ScrollbarSizes.x
            window.DecoOuterSizeY2 = window.DecoOuterSizeY2 + window.ScrollbarSizes.y
        end

        local host_rect
        if (bit.band(flags, ImGuiWindowFlags_ChildWindow) ~= 0 and bit.band(flags, ImGuiWindowFlags_Popup) == 0 and not window_is_child_tooltip) then
            host_rect = parent_window.ClipRect
        else
            host_rect = viewport_rect
        end
        local outer_rect = window:Rect()
        local title_bar_rect = window:TitleBarRect()
        ImRect_Copy(window.OuterRectClipped, outer_rect)
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

        --- Scrolling
        -- Lock down maximum scrolling
        -- The value of ScrollMax are ahead from ScrollbarX/ScrollbarY which is intentionally using InnerRect from previous rect in order to accommodate
        -- for right/bottom aligned items without creating a scrollbar.
        window.ScrollMax.x = ImMax(0.0, window.ContentSize.x + window.WindowPadding.x * 2.0 - window.InnerRect:GetWidth())
        window.ScrollMax.y = ImMax(0.0, window.ContentSize.y + window.WindowPadding.y * 2.0 - window.InnerRect:GetHeight())

        -- Apply scrolling
        CalcNextScrollFromScrollTargetAndClamp(window)
        window.ScrollTarget = ImVec2(FLT_MAX, FLT_MAX)
        window.DecoInnerSizeX1 = 0.0; window.DecoInnerSizeY1 = 0.0

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
        ImVec2_Copy(window.DC.CursorPos, window.DC.CursorStartPos)
        ImVec2_Copy(window.DC.CursorPosPrevLine, window.DC.CursorPos)
        ImVec2_Copy(window.DC.CursorMaxPos, window.DC.CursorStartPos)
        ImVec2_Copy(window.DC.IdealMaxPos, window.DC.CursorStartPos)
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

        window.DC.WindowItemStatusFlags = ImGuiItemStatusFlags.None

        if IsMouseHoveringRect(title_bar_rect.Min, title_bar_rect.Max, false) then
            window.DC.WindowItemStatusFlags = bit.bor(window.DC.WindowItemStatusFlags, ImGuiItemStatusFlags.HoveredRect)
        end
    else
        -- if (window->SkipRefresh)
        --     SetWindowActiveForSkipRefresh(window);

        ImGui.SetCurrentViewport(window, window.Viewport)
        SetCurrentWindow(window)
        g.NextWindowData:ClearFlags()
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
    local window_stack_data = g.CurrentWindowStack:back()

    if not window.SkipRefresh then
        ImGui.PopClipRect()
    end

    if (window.SkipRefresh) then
        IM_ASSERT(window.DrawList == nil)
        window.DrawList = window.DrawListInst
    end

    -- Pop from window stack
    g.LastItemData = window_stack_data.ParentLastItemDataBackup
    if bit.band(window.Flags, ImGuiWindowFlags_ChildMenu) ~= 0 then
        g.BeginMenuDepth = g.BeginMenuDepth - 1
    end
    if bit.band(window.Flags, ImGuiWindowFlags_Popup) ~= 0 then
        g.BeginPopupStack:pop_back()
    end

    g.CurrentWindowStack:pop_back()

    -- LUA: No "Ternary Operator", since lua (... and (1) or (2)) will eval (1) and (2) no matter what
    -- so something like `SetCurrentWindow((g.CurrentWindowStack.Size == 0) and nil or g.CurrentWindowStack:back().Window)` will error
    if (g.CurrentWindowStack.Size == 0) then
        SetCurrentWindow(nil)
    else
        SetCurrentWindow(g.CurrentWindowStack:back().Window)
    end
    if g.CurrentWindow then
        ImGui.SetCurrentViewport(g.CurrentWindow, g.CurrentWindow.Viewport)
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

    -- Special handling for the window being moved: Ignore the mouse viewport check (because it may reset/lose its viewport during the undocking frame)
    hovered_window = g.MovingWindow
    local backup_moving_window_viewport = nil
    if (find_first_and_in_any_viewport == false and g.MovingWindow) then
        backup_moving_window_viewport = g.MovingWindow.Viewport
        g.MovingWindow.Viewport = g.MouseViewport
        if (bit.band(g.MovingWindow.Flags, ImGuiWindowFlags_NoMouseInputs) == 0) then
            hovered_window = g.MovingWindow
        end
    end

    local padding_regular = g.Style.TouchExtraPadding
    local padding_for_resize = ImVec2()
    padding_for_resize.x = ImMax(g.Style.TouchExtraPadding.x, g.Style.WindowBorderHoverPadding)
    padding_for_resize.y = ImMax(g.Style.TouchExtraPadding.y, g.Style.WindowBorderHoverPadding)
    local window
    for i = g.Windows.Size, 1, -1 do
        window = g.Windows.Data[i]
        if not window.WasActive or window.Hidden then
            goto CONTINUE
        end
        if bit.band(window.Flags, ImGuiWindowFlags_NoMouseInputs) ~= 0 then
            goto CONTINUE
        end

        IM_ASSERT(window.Viewport)
        if (window.Viewport ~= g.MouseViewport) then
            goto CONTINUE
        end
        local hit_padding
        if bit.band(window.Flags, bit.bor(ImGuiWindowFlags_NoResize, ImGuiWindowFlags_AlwaysAutoResize)) ~= 0 then
            hit_padding = padding_regular
        else
            hit_padding = padding_for_resize
        end
        if not window.OuterRectClipped:ContainsWithPad(pos, hit_padding) then
            goto CONTINUE
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

            if hovered_window_under_moving_window == nil and (not g.MovingWindow or window.RootWindowDockTree ~= g.MovingWindow.RootWindowDockTree) then
                hovered_window_under_moving_window = window
            end

            if hovered_window and hovered_window_under_moving_window then
                break
            end
        end

        :: CONTINUE ::
    end

    if (find_first_and_in_any_viewport == false and g.MovingWindow) then
        g.MovingWindow.Viewport = backup_moving_window_viewport
    end

    return hovered_window, hovered_window_under_moving_window
end

-- TODO:
function ImGui.UpdateHoveredWindowAndCaptureFlags(mouse_pos)
    local g = GImGui
    local io = g.IO

    g.WindowsBorderHoverPadding = ImMax(ImMax(g.Style.TouchExtraPadding.x, g.Style.TouchExtraPadding.y), g.Style.WindowBorderHoverPadding)

    g.HoveredWindow, g.HoveredWindowUnderMovingWindow = FindHoveredWindowEx(mouse_pos, false)
    IM_ASSERT(g.HoveredWindow == nil or g.HoveredWindow == g.MovingWindow or g.HoveredWindow.Viewport == g.MouseViewport)

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

    for n = 0, 2 do -- TODO: ImGuiMouseButton.COUNT - 1
        ImGui.UpdateAliasKey(ImGui.MouseButtonToKey(n), io.MouseDown[n], io.MouseDown[n] and 1.0 or 0.0)
    end
    ImGui.UpdateAliasKey(ImGuiKey.MouseWheelX, io.MouseWheelH ~= 0.0, io.MouseWheelH)
    ImGui.UpdateAliasKey(ImGuiKey.MouseWheelY, io.MouseWheel ~= 0.0, io.MouseWheel)

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
            io.KeysData[key - ImGuiKey.NamedKey_BEGIN].Down = false
            io.KeysData[key - ImGuiKey.NamedKey_BEGIN].AnalogValue = 0.0
        end
    end

    -- Update keys
    for key = ImGuiKey.NamedKey_BEGIN, ImGuiKey.NamedKey_END - 1 do
        local key_data = io.KeysData[key - ImGuiKey.NamedKey_BEGIN]
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
            elseif key == ImGuiKey.ReservedForModCtrl or key == ImGuiKey.ReservedForModShift or key == ImGuiKey.ReservedForModAlt or key == ImGuiKey.ReservedForModSuper then
                g.LastKeyboardKeyPressTime = g.Time
            end
        end
    end

    -- Update keys/input owner (named keys only): one entry per key
    for key = ImGuiKey.NamedKey_BEGIN, ImGuiKey.NamedKey_END - 1 do
        local key_data = io.KeysData[key - ImGuiKey.NamedKey_BEGIN]
        local owner_data = g.KeysOwnerData[key - ImGuiKey.NamedKey_BEGIN]
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

--- @param window?      ImGuiWindow
--- @param wheel_amount float
local function LockWheelingWindow(window, wheel_amount)
    local g = GImGui
    if window then
        g.WheelingWindowReleaseTimer = ImMin(g.WheelingWindowReleaseTimer + ImAbs(wheel_amount) * WINDOWS_MOUSE_WHEEL_SCROLL_LOCK_TIMER, WINDOWS_MOUSE_WHEEL_SCROLL_LOCK_TIMER)
    else
        g.WheelingWindowReleaseTimer = 0.0
    end
    if (g.WheelingWindow == window) then
        return
    end
    -- IMGUI_DEBUG_LOG_IO("[io] LockWheelingWindow() \"%s\"\n", window ? window->Name : "NULL")
    g.WheelingWindow = window
    ImVec2_Copy(g.WheelingWindowRefMousePos, g.IO.MousePos)
    if window == nil then
        g.WheelingWindowStartFrame = -1
        g.WheelingAxisAvg = ImVec2(0.0, 0.0)
    end
end

--- @param wheel ImVec2
--- @return ImGuiWindow?
local function FindBestWheelingWindow(wheel)
    local g = GImGui
    local windows = {nil, nil}
    for axis = 0, 1 do
        if wheel[ImAxisToStr[axis]] ~= 0.0 then
            windows[axis + 1] = g.HoveredWindow
            local window = g.HoveredWindow
            while bit.band(window.Flags, ImGuiWindowFlags_ChildWindow) ~= 0 do
                local has_scrolling = (window.ScrollMax[ImAxisToStr[axis]] ~= 0.0)
                local inputs_disabled = (bit.band(window.Flags, ImGuiWindowFlags_NoScrollWithMouse) ~= 0) and not (bit.band(window.Flags, ImGuiWindowFlags_NoMouseInputs) ~= 0)

                if has_scrolling and not inputs_disabled then
                    break -- select this window
                end

                windows[axis + 1] = window.ParentWindow
                window = window.ParentWindow
            end
        end
    end
    if windows[1] == nil and windows[2] == nil then
        return nil
    end

    if (windows[1] == windows[2] or windows[1] == nil or windows[2] == nil) then
        return windows[2] and windows[2] or windows[1]
    end

    if (g.WheelingWindowStartFrame == -1) then
        g.WheelingWindowStartFrame = g.FrameCount
    end
    if ((g.WheelingWindowStartFrame == g.FrameCount and wheel.x ~= 0.0 and wheel.y ~= 0.0) or (g.WheelingAxisAvg.x == g.WheelingAxisAvg.y)) then
        ImVec2_Copy(g.WheelingWindowWheelRemainder, wheel)

        return nil
    end
    return (g.WheelingAxisAvg.x > g.WheelingAxisAvg.y) and windows[1] or windows[2]
end

function ImGui.UpdateMouseWheel()
    local g = GImGui
    if g.WheelingWindow ~= nil then
        g.WheelingWindowReleaseTimer = g.WheelingWindowReleaseTimer - g.IO.DeltaTime
        if ImGui.IsMousePosValid() and ImLengthSqr(g.IO.MousePos - g.WheelingWindowRefMousePos) > g.IO.MouseDragThreshold * g.IO.MouseDragThreshold then
            g.WheelingWindowReleaseTimer = 0.0
        end

        if g.WheelingWindowReleaseTimer <= 0.0 then
            LockWheelingWindow(nil, 0.0)
        end
    end

    local wheel = ImVec2()
    wheel.x = ImGui.TestKeyOwner(ImGuiKey.MouseWheelX, ImGuiKeyOwner_NoOwner) and g.IO.MouseWheelH or 0.0
    wheel.y = ImGui.TestKeyOwner(ImGuiKey.MouseWheelY, ImGuiKeyOwner_NoOwner) and g.IO.MouseWheel or 0.0

    local mouse_window = g.WheelingWindow and g.WheelingWindow or g.HoveredWindow
    if not mouse_window or mouse_window.Collapsed then
        return
    end

    -- Zoom / Scale window
    -- FIXME-OBSOLETE: This is an old feature, it still works but pretty much nobody is using it and may be best redesigned
    if wheel.y ~= 0.0 and g.IO.KeyCtrl and g.IO.FontAllowUserScaling then
        LockWheelingWindow(mouse_window, wheel.y)
        local window = mouse_window
        local new_font_scale = ImClamp(window.FontWindowScale + g.IO.MouseWheel * 0.10, 0.50, 2.50)
        local scale = new_font_scale / window.FontWindowScale
        window.FontWindowScale = new_font_scale
        if window == window.RootWindow then
            local offset = window.Size * (1.0 - scale) * (g.IO.MousePos - window.Pos) / window.Size
            ImGui.SetWindowPos(window, window.Pos + offset, 0)
            -- MarkIniSettingsDirty(window)
        end
        return
    end
    if g.IO.KeyCtrl then
        return
    end

    -- Mouse wheel scrolling
    if (g.IO.MouseWheelRequestAxisSwap) then
        wheel = ImVec2(wheel.y, 0.0)
    end

    -- Maintain a rough average of moving magnitude on both axes
    -- FIXME: should by based on wall clock time rather than frame-counter
    g.WheelingAxisAvg.x = ImExponentialMovingAverage(g.WheelingAxisAvg.x, ImAbs(wheel.x), 30)
    g.WheelingAxisAvg.y = ImExponentialMovingAverage(g.WheelingAxisAvg.y, ImAbs(wheel.y), 30)

    -- In the rare situation where FindBestWheelingWindow() had to defer first frame of wheeling due to ambiguous main axis, reinject it now
    wheel = wheel + g.WheelingWindowWheelRemainder
    g.WheelingWindowWheelRemainder = ImVec2(0.0, 0.0)
    if (wheel.x == 0.0 and wheel.y == 0.0) then
        return
    end

    -- Mouse wheel scrolling: find target and apply
    -- - don't renew lock if axis doesn't apply on the window.
    -- - select a main axis when both axes are being moved.
    local window
    if g.WheelingWindow then
        window = g.WheelingWindow
    else
        window = FindBestWheelingWindow(wheel)
    end
    if window then
        if not (bit.band(window.Flags, ImGuiWindowFlags_NoScrollWithMouse) ~= 0) and not (bit.band(window.Flags, ImGuiWindowFlags_NoMouseInputs) ~= 0) then
            local do_scroll = { wheel.x ~= 0.0 and window.ScrollMax.x ~= 0.0, wheel.y ~= 0.0 and window.ScrollMax.y ~= 0.0 }

            if do_scroll[ImGuiAxis.X + 1] and do_scroll[ImGuiAxis.Y + 1] then
                if g.WheelingAxisAvg.x > g.WheelingAxisAvg.y then
                    do_scroll[ImGuiAxis.Y + 1] = false
                else
                    do_scroll[ImGuiAxis.X + 1] = false
                end
            end

            if do_scroll[ImGuiAxis.X + 1] then
                LockWheelingWindow(window, wheel.x)
                local max_step = window.InnerRect:GetWidth() * 0.67
                local scroll_step = ImTrunc(ImMin(2 * window.FontRefSize, max_step))
                ImGui.SetScrollX(window, window.Scroll.x - wheel.x * scroll_step)
                g.WheelingWindowScrolledFrame = g.FrameCount
            end

            if do_scroll[ImGuiAxis.Y + 1] then
                LockWheelingWindow(window, wheel.y)
                local max_step = window.InnerRect:GetHeight() * 0.67
                local scroll_step = ImTrunc(ImMin(5 * window.FontRefSize, max_step))
                ImGui.SetScrollY(window, window.Scroll.y - wheel.y * scroll_step)
                g.WheelingWindowScrolledFrame = g.FrameCount
            end
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
    g.DrawListSharedData.InitialFlags = ImDrawListFlags.None
    if g.Style.AntiAliasedLines then
        g.DrawListSharedData.InitialFlags = bit.bor(g.DrawListSharedData.InitialFlags, ImDrawListFlags.AntiAliasedLines)
    end
    if g.Style.AntiAliasedLinesUseTex and not bit.band(g.IO.Fonts.Flags, ImFontAtlasFlags.NoBakedLines) then
        g.DrawListSharedData.InitialFlags = bit.bor(g.DrawListSharedData.InitialFlags, ImDrawListFlags.AntiAliasedLinesUseTex)
    end
    if g.Style.AntiAliasedFill then
        g.DrawListSharedData.InitialFlags = bit.bor(g.DrawListSharedData.InitialFlags, ImDrawListFlags.AntiAliasedFill)
    end
    if bit.band(g.IO.BackendFlags, ImGuiBackendFlags.RendererHasVtxOffset) then
        g.DrawListSharedData.InitialFlags = bit.bor(g.DrawListSharedData.InitialFlags, ImDrawListFlags.AllowVtxOffset)
    end
    g.DrawListSharedData.InitialFringeScale = 1.0
end

--- @param viewport ImGuiViewportP
local function InitViewportDrawData(viewport)
    local io = ImGui.GetIO()
    local draw_data = viewport.DrawDataP

    viewport.DrawData = draw_data
    viewport.DrawDataBuilder.Layers[1] = draw_data.CmdLists
    viewport.DrawDataBuilder.Layers[2] = viewport.DrawDataBuilder.LayerData1
    viewport.DrawDataBuilder.Layers[1]:resize(0)
    viewport.DrawDataBuilder.Layers[2]:resize(0)

    -- When minimized, we report draw_data->DisplaySize as zero to be consistent with non-viewport mode,
    -- and to allow applications/backends to easily skip rendering.
    -- FIXME: Note that we however do NOT attempt to report "zero drawlist / vertices" into the ImDrawData structure.
    -- This is because the work has been done already, and its wasted! We should fix that and add optimizations for
    -- it earlier in the pipeline, rather than pretend to hide the data at the end of the pipeline.
    local is_minimized = bit.band(viewport.Flags, ImGuiViewportFlags_IsMinimized) ~= 0

    draw_data.Valid            = true
    draw_data.CmdListsCount    = 0
    draw_data.TotalVtxCount    = 0
    draw_data.TotalIdxCount    = 0
    draw_data.DisplayPos       = viewport.Pos
    if is_minimized then
        draw_data.DisplaySize = ImVec2(0.0, 0.0)
    else
        ImVec2_Copy(draw_data.DisplaySize, viewport.Size)
    end
    if viewport.FramebufferScale.x ~= 0.0 then
        draw_data.FramebufferScale = viewport.FramebufferScale
    else
        draw_data.FramebufferScale = io.DisplayFramebufferScale
    end

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
    ImRect_CopyFromV4(window.ClipRect, window.DrawList._ClipRectStack:back())
end

function ImGui.PopClipRect()
    local window = ImGui.GetCurrentWindow()
    window.DrawList:PopClipRect()
    ImRect_CopyFromV4(window.ClipRect, window.DrawList._ClipRectStack:back())
end

--- @param viewport      ImGuiViewportP
--- @param drawlist_no   size_t         # background(1), foreground(2)
--- @param drawlist_name string
--- @return ImDrawList
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

--- @param viewport? ImGuiViewport
function ImGui.GetBackgroundDrawList(viewport)
    local g = GImGui

    if (viewport == nil) then
        viewport = g.CurrentWindow.Viewport
    end

    --- @cast viewport ImGuiViewportP
    return GetViewportBgFgDrawList(viewport, 1, "##Background")
end

--- @param viewport? ImGuiViewport
function ImGui.GetForegroundDrawList(viewport)
    local g = GImGui

    if (viewport == nil) then
        viewport = g.CurrentWindow.Viewport
    end

    --- @cast viewport ImGuiViewportP
    return GetViewportBgFgDrawList(viewport, 2, "##Foreground")
end

local function AddWindowToDrawData(window, layer)
    local g = GImGui
    local viewport = window.Viewport
    g.IO.MetricsRenderWindows = g.IO.MetricsRenderWindows + 1
    -- TODO: splitter
    ImGui.AddDrawListToDrawDataEx(viewport.DrawDataP, viewport.DrawDataBuilder.Layers[layer], window.DrawList)
    for _, child in window.DC.ChildWindows:iter() do
        if (ImGui.IsWindowActiveAndVisible(child)) then -- Clipped children may have been marked not active
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

function ImGui.NewFrame()
    IM_ASSERT(GImGui ~= nil, "No current context. Did you call ImGui::CreateContext() and ImGui::SetCurrentContext() ?")
    local g = GImGui

    g.ConfigFlagsLastFrame = g.ConfigFlagsCurrFrame
    g.ConfigFlagsCurrFrame = g.IO.ConfigFlags

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

    -- Mark rendering data as invalid to prevent user who may have a handle on it to use it.
    for _, viewport in g.Viewports:iter() do
        viewport.DrawData = nil
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
    if g.HoverItemDelayId ~= 0 and g.MouseStationaryTimer >= g.Style.HoverStationaryDelay then
        g.HoverItemUnlockedStationaryId = g.HoverItemDelayId
    elseif g.HoverItemDelayId == 0 then
        g.HoverItemUnlockedStationaryId = 0
    end
    if g.HoveredWindow ~= nil and g.MouseStationaryTimer >= g.Style.HoverStationaryDelay then
        g.HoverWindowUnlockedStationaryId = g.HoveredWindow.ID
    elseif g.HoveredWindow == nil then
        g.HoverWindowUnlockedStationaryId = 0
    end

    -- Update hover delay for IsItemHovered() with delays and tooltips
    g.HoverItemDelayIdPreviousFrame = g.HoverItemDelayId
    if g.HoverItemDelayId ~= 0 then
        g.HoverItemDelayTimer = g.HoverItemDelayTimer + g.IO.DeltaTime
        g.HoverItemDelayClearTimer = 0.0
        g.HoverItemDelayId = 0
    elseif g.HoverItemDelayTimer > 0.0 then
        -- This gives a little bit of leeway before clearing the hover timer, allowing mouse to cross gaps
        -- We could expose 0.25f as style.HoverClearDelay but I am not sure of the logic yet, this is particularly subtle.
        g.HoverItemDelayClearTimer = g.HoverItemDelayClearTimer + g.IO.DeltaTime
        if g.HoverItemDelayClearTimer >= ImMax(0.25, g.IO.DeltaTime * 2.0) then  -- ~7 frames at 30 Hz + allow for low framerate
            g.HoverItemDelayTimer = 0.0
            g.HoverItemDelayClearTimer = 0.0  -- May want a decaying timer, in which case need to clamp at max first, based on max of caller last requested timer.
        end
    end

    ImGui.UpdateKeyboardInputs()

    g.TooltipPreviousWindow = nil

    ImGui.UpdateMouseInputs()

    -- TODO: GC
    IM_ASSERT(g.WindowsFocusOrder.Size <= g.Windows.Size)

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

    ImGui.UpdateMouseWheel()

    g.CurrentWindowStack:resize(0)
    g.BeginPopupStack:resize(0)
    g.ItemFlagsStack:resize(0)
    g.ItemFlagsStack:push_back(ImGuiItemFlags_AutoClosePopups)
    g.CurrentItemFlags = g.ItemFlagsStack:back()

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
    if (g.CurrentWindow and g.CurrentWindow.IsFallbackWindow and g.CurrentWindow.WriteAccessed == false) then
        g.CurrentWindow.Active = false
    end
    ImGui.End()

    ImGui.SetCurrentViewport(nil, nil)

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

    ImGui.UpdateViewportsEndFrame()

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
    windows_to_render_top_most[1] = (g.NavWindowingTarget and (bit.band(g.NavWindowingTarget.Flags, ImGuiWindowFlags_NoBringToFrontOnFocus) == 0)) and g.NavWindowingTarget.RootWindowDockTree or nil
    windows_to_render_top_most[2] = g.NavWindowingTarget and g.NavWindowingListWindow or nil
    for _, window in g.Windows:iter() do
        if ImGui.IsWindowActiveAndVisible(window) and (bit.band(window.Flags, ImGuiWindowFlags_ChildWindow) == 0) and window ~= windows_to_render_top_most[1] and window ~= windows_to_render_top_most[2] then
            AddRootWindowToDrawData(window)
        end
    end
    for n = 1, 2 do
        if windows_to_render_top_most[n] and ImGui.IsWindowActiveAndVisible(windows_to_render_top_most[n]) then  -- NavWindowingTarget is always temporarily displayed as the top-most window
            AddRootWindowToDrawData(windows_to_render_top_most[n])
        end
    end

    -- Draw software mouse cursor if requested by io.MouseDrawCursor flag
    if g.IO.MouseDrawCursor and g.MouseCursor ~= ImGuiMouseCursor.None then
        ImGui.RenderMouseCursor(g.IO.MousePos, g.Style.MouseCursorScale, g.MouseCursor, IM_COL32_WHITE, IM_COL32_BLACK, IM_COL32(0, 0, 0, 48))
    end

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

-- TODO: void ImGui::Shutdown()

function ImGui.GetIO() return GImGui.IO end

--- @return ImGuiPlatformIO
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

local GStyleVarsInfo = {
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "Alpha"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "DisabledAlpha"),
    ImGuiStyleVarInfo(2, ImGuiDataType.Float, "WindowPadding"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "WindowRounding"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "WindowBorderSize"),
    ImGuiStyleVarInfo(2, ImGuiDataType.Float, "WindowMinSize"),
    ImGuiStyleVarInfo(2, ImGuiDataType.Float, "WindowTitleAlign"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "ChildRounding"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "ChildBorderSize"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "PopupRounding"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "PopupBorderSize"),
    ImGuiStyleVarInfo(2, ImGuiDataType.Float, "FramePadding"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "FrameRounding"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "FrameBorderSize"),
    ImGuiStyleVarInfo(2, ImGuiDataType.Float, "ItemSpacing"),
    ImGuiStyleVarInfo(2, ImGuiDataType.Float, "ItemInnerSpacing"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "IndentSpacing"),
    ImGuiStyleVarInfo(2, ImGuiDataType.Float, "CellPadding"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "ScrollbarSize"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "ScrollbarRounding"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "ScrollbarPadding"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "GrabMinSize"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "GrabRounding"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "ImageRounding"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "ImageBorderSize"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "TabRounding"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "TabBorderSize"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "TabMinWidthBase"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "TabMinWidthShrink"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "TabBarBorderSize"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "TabBarOverlineSize"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "TableAngledHeadersAngle"),
    ImGuiStyleVarInfo(2, ImGuiDataType.Float, "TableAngledHeadersTextAlign"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "TreeLinesSize"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "TreeLinesRounding"),
    ImGuiStyleVarInfo(2, ImGuiDataType.Float, "ButtonTextAlign"),
    ImGuiStyleVarInfo(2, ImGuiDataType.Float, "SelectableTextAlign"),
    ImGuiStyleVarInfo(1, ImGuiDataType.Float, "SeparatorTextBorderSize"),
    ImGuiStyleVarInfo(2, ImGuiDataType.Float, "SeparatorTextAlign"),
    ImGuiStyleVarInfo(2, ImGuiDataType.Float, "SeparatorTextPadding")
}

--- @param idx ImGuiStyleVar
--- @return ImGuiStyleVarInfo
function ImGui.GetStyleVarInfo(idx)
    IM_ASSERT(idx >= 0 and idx < ImGuiStyleVar.COUNT)
    -- IM_STATIC_ASSERT(IM_COUNTOF(GStyleVarsInfo) == ImGuiStyleVar_COUNT)
    return GStyleVarsInfo[idx + 1]
end

--- @param idx ImGuiStyleVar
--- @param val float|ImVec2
function ImGui.PushStyleVar(idx, val)
    local g = GImGui
    local var_info = ImGui.GetStyleVarInfo(idx)
    if type(val) == "number" then
        IM_ASSERT_USER_ERROR_RET(var_info.DataType == ImGuiDataType.Float and var_info.Count == 1, "Calling PushStyleVar() with wrong type!")
    else -- ImVec2
        IM_ASSERT_USER_ERROR_RET(var_info.DataType == ImGuiDataType.Float and var_info.Count == 2, "Calling PushStyleVar() with wrong type!")
    end
    local var = g.Style[var_info.Key]
    g.StyleVarStack:push_back(ImGuiStyleMod(idx, var))
    g.Style[var_info.Key] = val
end

--- @param idx   ImGuiStyleVar
--- @param val_x float
function ImGui.PushStyleVarX(idx, val_x)
    local g = GImGui
    local var_info = ImGui.GetStyleVarInfo(idx)
    IM_ASSERT_USER_ERROR_RET(var_info.DataType == ImGuiDataType.Float and var_info.Count == 2, "Calling PushStyleVarX() with wrong type!")
    local pvar = g.Style[var_info.Key]
    g.StyleVarStack:push_back(ImGuiStyleMod(idx, pvar))
    pvar.x = val_x
end

--- @param idx   ImGuiStyleVar
--- @param val_y float
function ImGui.PushStyleVarY(idx, val_y)
    local g = GImGui
    local var_info = ImGui.GetStyleVarInfo(idx)
    IM_ASSERT_USER_ERROR_RET(var_info.DataType == ImGuiDataType.Float and var_info.Count == 2, "Calling PushStyleVarY() with wrong type!")
    local pvar = g.Style[var_info.Key]
    g.StyleVarStack:push_back(ImGuiStyleMod(idx, pvar))
    pvar.y = val_y
end

--- @param count? int
function ImGui.PopStyleVar(count)
    if count == nil then count = 1 end

    local g = GImGui
    if g.StyleVarStack.Size < count then
        IM_ASSERT_USER_ERROR(0, "Calling PopStyleVar() too many times!")
        count = g.StyleVarStack.Size
    end
    while count > 0 do
        local backup = g.StyleVarStack:back()
        local var_info = ImGui.GetStyleVarInfo(backup.VarIdx)
        local data = g.Style[var_info.Key]
        if (var_info.DataType == ImGuiDataType.Float and var_info.Count == 1) then
            g.Style[var_info.Key] = backup.BackupVal[1]
        elseif (var_info.DataType == ImGuiDataType.Float and var_info.Count == 2) then
            data.x = backup.BackupVal[1]; data.y = backup.BackupVal[2]
        end
        g.StyleVarStack:pop_back()
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

--- @param potential_above ImGuiWindow
--- @param potential_below ImGuiWindow
--- @return bool
function ImGui.IsWindowAbove(potential_above, potential_below)
    local g = GImGui

    -- It would be saner to ensure that display layer is always reflected in the g.Windows order, which would likely requires altering all manipulations of that array
    local display_layer_delta = GetWindowDisplayLayer(potential_above) - GetWindowDisplayLayer(potential_below)
    if display_layer_delta ~= 0 then
        return display_layer_delta > 0
    end

    for i = g.Windows.Size, 1, -1 do
        local candidate_window = g.Windows.Data[i]
        if candidate_window == potential_above then
            return true
        end
        if candidate_window == potential_below then
            return false
        end
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
-- [SECTION] SCROLLING
---------------------------------------------------------------------------------------

--- @param target         float
--- @param snap_min       float
--- @param snap_max       float
--- @param snap_threshold float
--- @param center_ratio   float
local function CalcScrollEdgeSnap(target, snap_min, snap_max, snap_threshold, center_ratio)
    if target <= snap_min + snap_threshold then
        return ImLerp(snap_min, target, center_ratio)
    end
    if target >= snap_max - snap_threshold then
        return ImLerp(target, snap_max, center_ratio)
    end
    return target
end

--- Updates window.Scroll
--- @param window ImGuiWindow
function CalcNextScrollFromScrollTargetAndClamp(window)
    local scroll = window.Scroll
    local decoration_size = ImVec2(window.DecoOuterSizeX1 + window.DecoInnerSizeX1 + window.DecoOuterSizeX2, window.DecoOuterSizeY1 + window.DecoInnerSizeY1 + window.DecoOuterSizeY2)

    local axis
    for i = 0, 1 do
        axis = ImAxisToStr[i]

        if window.ScrollTarget[axis] < FLT_MAX then
            local center_ratio = window.ScrollTargetCenterRatio[axis]
            local scroll_target = window.ScrollTarget[axis]

            if window.ScrollTargetEdgeSnapDist[axis] > 0.0 then
                local snap_min = 0.0
                local snap_max = window.ScrollMax[axis] + window.SizeFull[axis] - decoration_size[axis]
                scroll_target = CalcScrollEdgeSnap(scroll_target, snap_min, snap_max, window.ScrollTargetEdgeSnapDist[axis], center_ratio)
            end

            scroll[axis] = scroll_target - center_ratio * (window.SizeFull[axis] - decoration_size[axis])
        end
        scroll[axis] = ImRound(ImMax(scroll[axis], 0.0))
        if not window.Collapsed and not window.SkipItems then
            scroll[axis] = ImMin(scroll[axis], window.ScrollMax[axis])
        end
    end
end

--- @param window   ImGuiWindow
--- @param scroll_x float
function ImGui.SetScrollX(window, scroll_x)
    window.ScrollTarget.x = scroll_x
    window.ScrollTargetCenterRatio.x = 0.0
    window.ScrollTargetEdgeSnapDist.x = 0.0
end

--- @param window   ImGuiWindow
--- @param scroll_y float
function ImGui.SetScrollY(window, scroll_y)
    window.ScrollTarget.y = scroll_y
    window.ScrollTargetCenterRatio.y = 0.0
    window.ScrollTargetEdgeSnapDist.y = 0.0
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
        local is_touchscreen = (g.IO.MouseSource == ImGuiMouseSource.TouchScreen)

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

function ImGui.OpenPopupEx(id, popup_flags)
    local g = GImGui
    local parent_window = g.CurrentWindow
    local current_stack_size = g.BeginPopupStack.Size

    if bit.band(popup_flags, ImGuiPopupFlags_NoOpenOverExistingPopup) ~= 0 then
        if ImGui.IsPopupOpen(0, ImGuiPopupFlags_AnyPopupId) then
            return
        end
    end

    local popup_ref = ImGuiPopupData()
    popup_ref.PopupId = id
    popup_ref.Window = nil
    popup_ref.RestoreNavWindow = g.NavWindow -- When popup closes focus may be restored to NavWindow (depend on window type).
    popup_ref.OpenFrameCount = g.FrameCount
    popup_ref.OpenParentId = parent_window.IDStack:back()
    popup_ref.OpenPopupPos = ImGui.NavCalcPreferredRefPos(ImGuiWindowFlags_Popup)
    if ImGui.IsMousePosValid(g.IO.MousePos) then
        ImVec2_Copy(popup_ref.OpenMousePos, g.IO.MousePos)
    else
        ImVec2_Copy(popup_ref.OpenMousePos, popup_ref.OpenPopupPos)
    end

    -- IMGUI_DEBUG_LOG_POPUP("[popup] OpenPopupEx(0x%08X)", id)
    if g.OpenPopupStack.Size < current_stack_size + 1 then
        g.OpenPopupStack:push_back(popup_ref)
    else
        -- Gently handle the user mistakenly calling OpenPopup() every frames: it is likely a programming mistake!
        -- However, if we were to run the regular code path, the ui would become completely unusable because the popup will always be
        -- in hidden-while-calculating-size state _while_ claiming focus. Which is extremely confusing situation for the programmer.
        -- Instead, for successive frames calls to OpenPopup(), we silently avoid reopening even if ImGuiPopupFlags_NoReopen is not specified.

        local keep_existing = false
        if g.OpenPopupStack.Data[current_stack_size + 1].PopupId == id then
            if (g.OpenPopupStack.Data[current_stack_size + 1].OpenFrameCount == g.FrameCount - 1) or (bit.band(popup_flags, ImGuiPopupFlags_NoReopen) ~= 0) then
                keep_existing = true
            end
        end

        if keep_existing then
            -- No reopen
            g.OpenPopupStack.Data[current_stack_size + 1].OpenFrameCount = popup_ref.OpenFrameCount
        else
            -- Reopen: close child popups if any, then flag popup for open/reopen (set position, focus, init navigation)
            ImGui.ClosePopupToLevel(current_stack_size, true)
            g.OpenPopupStack:push_back(popup_ref)
        end

        -- When reopening a popup we first refocus its parent, otherwise if its parent is itself a popup it would get closed by ClosePopupsOverWindow().
        -- This is equivalent to what ClosePopupToLevel() does.
        -- if (g.OpenPopupStack[current_stack_size].PopupId == id)
        --     FocusWindow(parent_window);
    end
end

-- When popups are stacked, clicking on a lower level popups puts focus back to it and close popups above it.
-- This function closes any popups that are over 'ref_window'.
--- @param ref_window?                         ImGuiWindow
--- @param restore_focus_to_window_under_popup bool
function ImGui.ClosePopupsOverWindow(ref_window, restore_focus_to_window_under_popup)
    local g = GImGui
    if g.OpenPopupStack.Size == 0 then
        return
    end

    -- Don't close our own child popup windows.
    -- IMGUI_DEBUG_LOG_POPUP("[popup] ClosePopupsOverWindow(\"%s\") restore_under=%d", ref_window and ref_window.Name or "<NULL>", restore_focus_to_window_under_popup)
    local popup_count_to_keep = 1
    if ref_window then
        -- Find the highest popup which is a descendant of the reference window (generally reference window = NavWindow)
        while popup_count_to_keep <= g.OpenPopupStack.Size do
            local popup = g.OpenPopupStack.Data[popup_count_to_keep]

                if popup.Window then -- cpp code has `continue` here instead of this big if statement

                    IM_ASSERT(bit.band(popup.Window.Flags, ImGuiWindowFlags_Popup) ~= 0)

                    -- Trim the stack unless the popup is a direct parent of the reference window (the reference window is often the NavWindow)
                    -- - Clicking/Focusing Window2 won't close Popup1:
                    --     Window -> Popup1 -> Window2(Ref)
                    -- - Clicking/focusing Popup1 will close Popup2 and Popup3:
                    --     Window -> Popup1(Ref) -> Popup2 -> Popup3
                    -- - Each popups may contain child windows, which is why we compare ->RootWindow!
                    --     Window -> Popup1 -> Popup1_Child -> Popup2 -> Popup2_Child
                    -- We step through every popup from bottom to top to validate their position relative to reference window.
                    local ref_window_is_descendent_of_popup = false
                    for n = popup_count_to_keep, g.OpenPopupStack.Size do
                        local popup_window = g.OpenPopupStack.Data[n].Window
                        if popup_window and ImGui.IsWindowWithinBeginStackOf(ref_window, popup_window) then
                            ref_window_is_descendent_of_popup = true
                            break
                        end
                    end

                    if not ref_window_is_descendent_of_popup then
                        break
                    end

                end

            popup_count_to_keep = popup_count_to_keep + 1
        end
    end
    if popup_count_to_keep <= g.OpenPopupStack.Size then -- This test is not required but it allows to set a convenient breakpoint on the statement below
        -- IMGUI_DEBUG_LOG_POPUP("[popup] ClosePopupsOverWindow(\"%s\")", ref_window and ref_window.Name or "<NULL>")
        ImGui.ClosePopupToLevel(popup_count_to_keep, restore_focus_to_window_under_popup)
    end
end

function ImGui.ClosePopupToLevel(remaining, restore_focus_to_window_under_popup)
    local g = GImGui
    -- IMGUI_DEBUG_LOG_POPUP("[popup] ClosePopupToLevel(%d), restore_under=%d", remaining, restore_focus_to_window_under_popup)
    IM_ASSERT(remaining > 0 and remaining <= g.OpenPopupStack.Size)
    -- if bit.band(g.DebugLogFlags, ImGuiDebugLogFlags.EventPopup) ~= 0 then
    --     for n = remaining, g.OpenPopupStack.Size do
    --         local popup = g.OpenPopupStack.Data[n]
    --         IMGUI_DEBUG_LOG_POPUP("[popup] - Closing PopupID 0x%08X Window \"%s\"", popup.PopupId, popup.Window and popup.Window.Name or nil)
    --     end
    -- end

    -- Trim open popup stack
    local prev_popup = g.OpenPopupStack.Data[remaining]
    g.OpenPopupStack:resize(remaining - 1)

    -- Restore focus (unless popup window was not yet submitted, and didn't have a chance to take focus anyhow. See #7325 for an edge case)
    if restore_focus_to_window_under_popup and prev_popup.Window then
        local popup_window = prev_popup.Window
        local focus_window
        if bit.band(popup_window.Flags, ImGuiWindowFlags_ChildMenu) ~= 0 then
            focus_window = popup_window.ParentWindow
        else
            focus_window = prev_popup.RestoreNavWindow
        end

        if focus_window and not focus_window.WasActive then
            ImGui.FocusTopMostWindowUnderOne(popup_window, nil, nil, ImGuiFocusRequestFlags_RestoreFocusedChild) -- Fallback
        else
            local focus_flags = (g.NavLayer == ImGuiNavLayer_Main) and ImGuiFocusRequestFlags.RestoreFocusedChild or ImGuiFocusRequestFlags.None
            ImGui.FocusWindow(focus_window, focus_flags)
        end
    end
end

-- Close the popup we have Begin-ed into
function ImGui.CloseCurrentPopup()
    local g = GImGui
    local popup_idx = g.BeginPopupStack.Size
    if popup_idx < 1 or popup_idx > g.OpenPopupStack.Size or g.BeginPopupStack.Data[popup_idx].PopupId ~= g.OpenPopupStack.Data[popup_idx].PopupId then
        return
    end

    -- Closing a menu closes its top-most parent popup (unless a modal)
    while popup_idx > 1 do
        local popup_window = g.OpenPopupStack.Data[popup_idx].Window
        local parent_popup_window = g.OpenPopupStack.Data[popup_idx - 1].Window
        local close_parent = false
        if popup_window and bit.band(popup_window.Flags, ImGuiWindowFlags_ChildMenu) ~= 0 then
            if parent_popup_window and not (bit.band(parent_popup_window.Flags, ImGuiWindowFlags_MenuBar) ~= 0) then
                close_parent = true
            end
        end

        if not close_parent then
            break
        end

        popup_idx = popup_idx - 1
    end

    -- IMGUI_DEBUG_LOG_POPUP("[popup] CloseCurrentPopup %d -> %d\n", g.BeginPopupStack.Size, popup_idx)
    ImGui.ClosePopupToLevel(popup_idx, true)

    -- A common pattern is to close a popup when selecting a menu item/selectable that will open another window.
    -- To improve this usage pattern, we avoid nav highlight for a single frame in the parent window.
    -- Similarly, we could avoid mouse hover highlight in this window but it is less visually problematic.
    local window = g.NavWindow
    if window then
        window.DC.NavHideHighlightOneFrame = true
    end
end

function ImGui.EndPopup()
    local g = GImGui
    local window = g.CurrentWindow
    IM_ASSERT_USER_ERROR_RET((bit.band(window.Flags, ImGuiWindowFlags_Popup) ~= 0) and (g.BeginPopupStack.Size > 0), "Calling EndPopup() in wrong window!")

    -- Make all menus and popups wrap around for now, may need to expose that policy (e.g. focus scope could include wrap/loop policy flags used by new move requests)
    if g.NavWindow == window then
        -- TODO: ImGui.NavMoveRequestTryWrapping(window, ImGuiNavMoveFlags_LoopY)
    end

    -- Child-popups don't need to be laid out
    local backup_within_end_child_id = g.WithinEndChildID
    if bit.band(window.Flags, ImGuiWindowFlags_ChildWindow) ~= 0 then
        g.WithinEndChildID = window.ID
    end

    ImGui.End()
    g.WithinEndChildID = backup_within_end_child_id
end

--- @param ref_pos  ImVec2
--- @param size     ImVec2
--- @param last_dir ImGuiDir
--- @param r_outer  ImRect
--- @param r_avoid  ImRect
--- @param policy   ImGuiPopupPositionPolicy
--- @return ImVec2 # Best Window Pos For Popup
--- @return int    # Updated last_dir
--- @nodiscard
function ImGui.FindBestWindowPosForPopupEx(ref_pos, size, last_dir, r_outer, r_avoid, policy)
    local base_pos_clamped = ImClampV2(ref_pos, r_outer.Min, r_outer.Max - size)

    -- Combo Box policy (we want a connecting edge)
    if policy == ImGuiPopupPositionPolicy.ComboBox then
        local dir_preferred_order = {ImGuiDir.Down, ImGuiDir.Right, ImGuiDir.Left, ImGuiDir.Up}

        for n = (last_dir ~= ImGuiDir.None) and 0 or 1, ImGuiDir.COUNT do
        repeat
            local dir
            if n == 0 then
                dir = last_dir
            else
                dir = dir_preferred_order[n]
            end

            if n ~= 0 and dir == last_dir then  -- Already tried this direction?
                do break end --[[continue]]
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
                do break end --[[continue]]
            end

            last_dir = dir
            return pos, last_dir
        until true
        end
    end

    -- Tooltip and Default popup policy
    -- (Always first try the direction we used on the last frame, if any)
    if policy == ImGuiPopupPositionPolicy.Tooltip or policy == ImGuiPopupPositionPolicy.Default then
        local dir_preferred_order = {ImGuiDir.Right, ImGuiDir.Down, ImGuiDir.Up, ImGuiDir.Left}

        for n = (last_dir ~= ImGuiDir.None) and 0 or 1, ImGuiDir.COUNT do
        repeat
            local dir
            if n == 0 then
                dir = last_dir
            else
                dir = dir_preferred_order[n]
            end

            if n ~= 0 and dir == last_dir then  -- Already tried this direction?
                do break end --[[continue]]
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
                do break end --[[continue]]
            end
            if avail_h < size.y and (dir == ImGuiDir.Up or dir == ImGuiDir.Down) then
                do break end --[[continue]]
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
            return pos, last_dir
        until true
        end
    end

    -- Fallback when not enough room:
    last_dir = ImGuiDir.None

    -- For tooltip we prefer avoiding the cursor at all cost even if it means that part of the tooltip won't be visible.
    if policy == ImGuiPopupPositionPolicy.Tooltip then
        return ref_pos + ImVec2(2, 2), last_dir
    end

    -- Otherwise try to keep within display
    local pos = ImVec2(ref_pos.x, ref_pos.y)
    pos.x = ImMax(ImMin(pos.x + size.x, r_outer.Max.x) - size.x, r_outer.Min.x)
    pos.y = ImMax(ImMin(pos.y + size.y, r_outer.Max.y) - size.y, r_outer.Min.y)
    return pos, last_dir
end

--- @param window ImGuiWindow
--- @return ImRect
--- @nodiscard
function ImGui.GetPopupAllowedExtentRect(window)
    local g = GImGui
    local r_screen = ImRect()

    if window.ViewportAllowPlatformMonitorExtend >= 1 then
        -- Extent with be in the frame of reference of the given viewport (so Min is likely to be negative here)
        local monitor = g.PlatformIO.Monitors.Data[window.ViewportAllowPlatformMonitorExtend]
        ImVec2_Copy(r_screen.Min, monitor.WorkPos)
        r_screen.Max = monitor.WorkPos + monitor.WorkSize
    else
        -- Use the full viewport area (not work area) for popups
        r_screen = window.Viewport:GetMainRect()
    end

    local padding = g.Style.DisplaySafeAreaPadding
    r_screen:ExpandV2(ImVec2((r_screen:GetWidth() > padding.x * 2) and -padding.x or 0.0, (r_screen:GetHeight() > padding.y * 2) and -padding.y or 0.0))

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
        local parent_window = window.ParentWindow
        local horizontal_overlap = g.Style.ItemInnerSpacing.x  -- We want some overlap to convey the relative depth of each menu (currently the amount of overlap is hard-coded to style.ItemSpacing.x).

        local r_avoid
        if parent_window.DC.MenuBarAppending then
            r_avoid = ImRect(-FLT_MAX, parent_window.ClipRect.Min.y, FLT_MAX, parent_window.ClipRect.Max.y)  -- Avoid parent menu-bar. If we wanted multi-line menu-bar, we may instead want to have the calling window setup e.g. a NextWindowData.PosConstraintAvoidRect field
        else
            r_avoid = ImRect(parent_window.Pos.x + horizontal_overlap, -FLT_MAX, parent_window.Pos.x + parent_window.Size.x - horizontal_overlap - parent_window.ScrollbarSizes.x, FLT_MAX)
        end

        local pos
        pos, window.AutoPosLastDirection = ImGui.FindBestWindowPosForPopupEx(window.Pos, window.Size, window.AutoPosLastDirection, r_outer, r_avoid, ImGuiPopupPositionPolicy.Default)
        return pos
    end

    if bit.band(window.Flags, ImGuiWindowFlags_Popup) ~= 0 then
        local pos
        pos, window.AutoPosLastDirection = ImGui.FindBestWindowPosForPopupEx(window.Pos, window.Size, window.AutoPosLastDirection, r_outer, ImRect(window.Pos, window.Pos), ImGuiPopupPositionPolicy.Default)  -- Ideally we'd disable r_avoid here
        return pos
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

        if g.IO.MouseSource == ImGuiMouseSource.TouchScreen and ImGui.NavCalcPreferredRefPosSource(ImGuiWindowFlags_Tooltip) == ImGuiInputSource.Mouse then
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

        local pos
        pos, window.AutoPosLastDirection = ImGui.FindBestWindowPosForPopupEx(tooltip_pos, window.Size, window.AutoPosLastDirection, r_outer, r_avoid, ImGuiPopupPositionPolicy.Tooltip)
        return pos
    end

    IM_ASSERT(false)

    return window.Pos
end

---------------------------------------------------------------------------------------
-- [SECTION] NAVIGATION
---------------------------------------------------------------------------------------

--- @param window? ImGuiWindow
function ImGui.SetNavWindow(window)
    local g = GImGui
    if g.NavWindow ~= window then
        -- TODO:
        g.NavWindow = window
    end
end

function ImGui.SetNavID(id, nav_layer, focus_scope_id, rect_rel)
end

--- @param window_type ImGuiWindowFlags
--- @return ImGuiInputSource
function ImGui.NavCalcPreferredRefPosSource(window_type)
    local g = GImGui
    local window = g.NavWindow

    local activated_shortcut = g.ActiveId ~= 0 and g.ActiveIdFromShortcut and g.ActiveId == g.LastItemData.ID
    if (bit.band(window_type, ImGuiWindowFlags_Popup) ~= 0) and activated_shortcut then
        return ImGuiInputSource.Keyboard
    end

    if not g.NavCursorVisible or not g.NavHighlightItemUnderNav or not window then
        return ImGuiInputSource.Mouse
    else
        return ImGuiInputSource.Keyboard  -- or Nav in general
    end
end

--- @param window_type ImGuiWindowFlags
--- @return ImVec2
--- @nodiscard
function ImGui.NavCalcPreferredRefPos(window_type)
    local g = GImGui
    local window = g.NavWindow
    local source = ImGui.NavCalcPreferredRefPosSource(window_type)

    if source == ImGuiInputSource.Mouse then
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
            ref_rect = ImGui.WindowRectRelToAbs(window, window.NavRectRel[ImAxisToStr[g.NavLayer]])
        end

        -- Take account of upcoming scrolling (maybe set mouse pos should be done in EndFrame?)
        if window ~= nil and window.LastFrameActive ~= g.FrameCount and (window.ScrollTarget.x ~= FLT_MAX or window.ScrollTarget.y ~= FLT_MAX) then
            local next_scroll = CalcNextScrollFromScrollTargetAndClamp(window)
            ref_rect:Translate(window.Scroll - next_scroll)
        end

        local pos = ImVec2(ref_rect.Min.x + ImMin(g.Style.FramePadding.x * 4, ref_rect:GetWidth()), ref_rect.Max.y - ImMin(g.Style.FramePadding.y, ref_rect:GetHeight()))
        if window ~= nil then
            local viewport = window.Viewport
            if viewport then
                pos = ImClampV2(pos, viewport.Pos, viewport.Pos + viewport.Size)
            end
        end

        return ImTruncV2(pos)  -- ImTrunc() is important because non-integer mouse position application in backend might be lossy and result in undesirable non-zero delta.
    end
end

function ImGui.NavMoveRequestCancel()
    -- TODO:
end

---------------------------------------------------------------------------------------
-- [SECTION] DRAG AND DROP
---------------------------------------------------------------------------------------

function ImGui.IsDragDropPayloadBeingAccepted()
    local g = GImGui
    return g.DragDropActive and g.DragDropAcceptIdPrev ~= 0
end

---------------------------------------------------------------------------------------
-- [SECTION] VIEWPORTS, PLATFORM WINDOWS
---------------------------------------------------------------------------------------

function MT.ImGuiPlatformIO:ClearPlatformHandlers()
    self.Platform_GetClipboardTextFn = nil; self.Platform_SetClipboardTextFn      = nil; self.Platform_OpenInShellFn             = nil; self.Platform_SetImeDataFn = nil
    self.Platform_ClipboardUserData  = nil; self.Platform_OpenInShellUserData     = nil; self.Platform_ImeUserData               = nil
    self.Platform_CreateWindow       = nil; self.Platform_DestroyWindow           = nil; self.Platform_ShowWindow                = nil
    self.Platform_SetWindowPos       = nil; self.Platform_SetWindowSize           = nil
    self.Platform_GetWindowPos       = nil; self.Platform_GetWindowSize           = nil; self.Platform_GetWindowFramebufferScale = nil
    self.Platform_SetWindowFocus     = nil; self.Platform_GetWindowFocus          = nil; self.Platform_GetWindowMinimized        = nil
    self.Platform_SetWindowTitle     = nil; self.Platform_SetWindowAlpha          = nil; self.Platform_UpdateWindow              = nil
    self.Platform_RenderWindow       = nil; self.Platform_SwapBuffers             = nil; self.Platform_GetWindowDpiScale         = nil
    self.Platform_OnChangedViewport  = nil; self.Platform_GetWindowWorkAreaInsets = nil; self.Platform_CreateVkSurface           = nil
end

function MT.ImGuiPlatformIO:ClearRendererHandlers()
    self.Renderer_TextureMaxWidth = 0; self.Renderer_TextureMaxHeight = 0
    self.Renderer_RenderState     = nil
    self.Renderer_CreateWindow    = nil; self.Renderer_DestroyWindow  = nil
    self.Renderer_SetWindowSize   = nil
    self.Renderer_RenderWindow    = nil; self.Renderer_SwapBuffers    = nil
end

--- @return ImGuiViewport
function ImGui.GetMainViewport()
    local g = GImGui

    return g.Viewports:at(1)
end

--- @param viewport_id ImGuiID
--- @return ImGuiViewport?
function ImGui.FindViewportByID(viewport_id)
    local g = GImGui
    for _, viewport in g.Viewports:iter() do
        if viewport.ID == viewport_id then
            return viewport
        end
    end
    return nil
end

--- @param current_window? ImGuiWindow
--- @param viewport?       ImGuiViewportP
function ImGui.SetCurrentViewport(current_window, viewport)
    local g = GImGui

    if viewport then
        viewport.LastFrameActive = g.FrameCount
    end
    if g.CurrentViewport == viewport then
        return
    end

    g.CurrentDpiScale = viewport and viewport.DpiScale or 1.0
    g.CurrentViewport = viewport
    IM_ASSERT(g.CurrentDpiScale > 0.0 and g.CurrentDpiScale < 99.0)  -- Typical correct values would be between 1.0f and 4.0f
    -- IMGUI_DEBUG_LOG_VIEWPORT("[viewport] SetCurrentViewport changed '%s' 0x%08X", current_window and current_window.Name or "NULL", viewport and viewport.ID or 0)

    if g.IO.ConfigDpiScaleFonts then
        g.Style.FontScaleDpi = g.CurrentDpiScale
    end

    -- Notify platform layer of viewport changes
    -- FIXME-DPI: This is only currently used for experimenting with handling of multiple DPI
    if g.CurrentViewport and g.PlatformIO.Platform_OnChangedViewport then
        g.PlatformIO.Platform_OnChangedViewport(g.CurrentViewport)
    end
end

--- @param window   ImGuiWindow
--- @param viewport ImGuiViewportP
function ImGui.SetWindowViewport(window, viewport)
    -- Abandon viewport
    if window.ViewportOwned and window.Viewport.Window == window then
        window.Viewport.Size = ImVec2(0.0, 0.0)
    end

    window.Viewport = viewport
    window.ViewportId = viewport.ID
    window.ViewportOwned = (viewport.Window == window)
end

--- @param window ImGuiWindow
--- @return bool
function ImGui.GetWindowAlwaysWantOwnViewport(window)
    -- Tooltips and menus are not automatically forced into their own viewport when the NoMerge flag is set, however the multiplication of viewports makes them more likely to protrude and create their own.
    local g = GImGui
    if g.IO.ConfigViewportsNoAutoMerge or (bit.band(window.WindowClass.ViewportFlagsOverrideSet, ImGuiViewportFlags_NoAutoMerge) ~= 0) then
        if bit.band(g.ConfigFlagsCurrFrame, ImGuiConfigFlags_ViewportsEnable) ~= 0 then
            if not window.DockIsActive then
                if bit.band(window.Flags, bit.bor(ImGuiWindowFlags_ChildWindow, ImGuiWindowFlags_ChildMenu, ImGuiWindowFlags_Tooltip)) == 0 then
                    if bit.band(window.Flags, ImGuiWindowFlags_Popup) == 0 or bit.band(window.Flags, ImGuiWindowFlags_Modal) ~= 0 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

--- Heuristic, see #8948: depends on how backends handle OS-level parenting.
--- Due to how parent viewport stack is layed out, note that IsViewportAbove(a,b) isn't always the same as !IsViewportAbove(b,a).
--- @param potential_above ImGuiViewportP
--- @param potential_below ImGuiViewportP
--- @return bool
function ImGui.IsViewportAbove(potential_above, potential_below)
    -- If ImGuiBackendFlags.HasParentViewport if set, ->ParentViewport chain should be accurate.
    local g = GImGui
    if bit.band(g.IO.BackendFlags, ImGuiBackendFlags.HasParentViewport) ~= 0 then
        local v = potential_above --[[@as ImGuiViewport]]
        while v ~= nil and v.ParentViewport do
            if v.ParentViewport == potential_below then
                return true
            end
            v = v.ParentViewport
        end
    else
        if potential_above.ParentViewport == potential_below then
            return true
        end
    end

    if potential_above.LastFocusedStampCount > potential_below.LastFocusedStampCount then
        return true
    end
    return false
end

--- @param window       ImGuiWindow
--- @param viewport_dst ImGuiViewportP
function ImGui.UpdateTryMergeWindowIntoHostViewport(window, viewport_dst)
    local g = GImGui
    IM_ASSERT(window == window.RootWindowDockTree)

    local viewport_src = window.Viewport -- Current viewport
    if viewport_src == viewport_dst then
        return false
    end
    if bit.band(viewport_dst.Flags, ImGuiViewportFlags_CanHostOtherWindows) == 0 then
        return false
    end
    if bit.band(viewport_dst.Flags, ImGuiViewportFlags_IsMinimized) ~= 0 then
        return false
    end
    if not viewport_dst:GetMainRect():Contains(window:Rect()) then
        return false
    end
    if ImGui.GetWindowAlwaysWantOwnViewport(window) then
        return false
    end

    for _, viewport_obstructing in g.Viewports:iter() do
        if viewport_obstructing == viewport_src or viewport_obstructing == viewport_dst then
            goto CONTINUE
        end

        if viewport_obstructing:GetMainRect():Overlaps(window:Rect()) then
            if ImGui.IsViewportAbove(viewport_obstructing, viewport_dst) then
                if viewport_src == nil or ImGui.IsViewportAbove(viewport_src, viewport_obstructing) then
                    return false  -- viewport_obstructing is between viewport_src and viewport_dst -> Cannot merge.
                end
            end
        end

        ::CONTINUE::
    end

    -- Move to the existing viewport, Move child/hosted windows as well (FIXME-OPT: iterate child)
    IMGUI_DEBUG_LOG_VIEWPORT("[viewport] Window '%s' merge into Viewport 0X%08X", window.Name, viewport_dst.ID)
    if window.ViewportOwned then
        for n = 1, g.Windows.Size do
            if g.Windows.Data[n].Viewport == viewport_src then
                ImGui.SetWindowViewport(g.Windows.Data[n], viewport_dst)
            end
        end
    end

    ImGui.SetWindowViewport(window, viewport_dst)

    if bit.band(window.Flags, ImGuiWindowFlags_NoBringToFrontOnFocus) == 0 then
        ImGui.BringWindowToDisplayFront(window)
    end

    return true
end

-- FIXME: handle 0 to N host viewports
--- @param window ImGuiWindow
--- @return bool
function ImGui.UpdateTryMergeWindowIntoHostViewports(window)
    local g = GImGui
    return ImGui.UpdateTryMergeWindowIntoHostViewport(window, g.Viewports.Data[1])
end

--- Translate Dear ImGui windows when a Host Viewport has been moved
--- (This additionally keeps windows at the same place when ImGuiConfigFlags_ViewportsEnable is toggled!)
--- @param viewport ImGuiViewportP
--- @param old_pos  ImVec2
--- @param new_pos  ImVec2
--- @param old_size ImVec2
--- @param new_size ImVec2
function ImGui.TranslateWindowsInViewport(viewport, old_pos, new_pos, old_size, new_size)
    local g = GImGui
    -- IMGUI_DEBUG_LOG_VIEWPORT("[viewport] TranslateWindowsInViewport 0x%08X", viewport.ID)
    IM_ASSERT(viewport.Window == nil and (bit.band(viewport.Flags, ImGuiViewportFlags_CanHostOtherWindows) ~= 0))

    -- 1) We test if ImGuiConfigFlags_ViewportsEnable was just toggled, which allows us to conveniently
    -- translate imgui windows from OS-window-local to absolute coordinates or vice-versa.
    -- 2) If it's not going to fit into the new size, keep it at same absolute position.
    -- One problem with this is that most Win32 applications doesn't update their render while dragging,
    -- and so the window will appear to teleport when releasing the mouse.
    local translate_all_windows = (bit.band(g.ConfigFlagsCurrFrame, ImGuiConfigFlags_ViewportsEnable) ~= bit.band(g.ConfigFlagsLastFrame, ImGuiConfigFlags_ViewportsEnable))
    local test_still_fit_rect = ImRect(old_pos, old_pos + old_size)
    local delta_pos = new_pos - old_pos

    for _, window in g.Windows:iter() do  -- FIXME-OPT
        if translate_all_windows or (window.Viewport == viewport and (old_size == new_size or test_still_fit_rect:Contains(window:Rect()))) then
            ImGui.TranslateWindow(window, delta_pos)
        end
    end
end

--- @param mouse_platform_pos ImVec2
--- @return ImGuiViewportP?
function ImGui.FindHoveredViewportFromPlatformWindowStack(mouse_platform_pos)
    local g = GImGui
    local best_candidate = nil
    for _, viewport in g.Viewports:iter() do
        if bit.band(viewport.Flags, bit.bor(ImGuiViewportFlags_NoInputs, ImGuiViewportFlags_IsMinimized)) == 0 and viewport:GetMainRect():ContainsV2(mouse_platform_pos) then
            if best_candidate == nil or best_candidate.LastFocusedStampCount < viewport.LastFocusedStampCount then
                best_candidate = viewport
            end
        end
    end
    return best_candidate
end

function ImGui.UpdateViewportsNewFrame()
    local g = GImGui
    IM_ASSERT(g.PlatformIO.Viewports.Size <= g.Viewports.Size)

    -- Update Minimized status (we need it first in order to decide if we'll apply Pos/Size of the main viewport)
    -- Update Focused status
    local viewports_enabled = (bit.band(g.ConfigFlagsCurrFrame, ImGuiConfigFlags_ViewportsEnable) ~= 0)
    if viewports_enabled then
        local focused_viewport = nil

        for i = 1, g.Viewports.Size do
            local viewport = g.Viewports.Data[i]
            local platform_funcs_available = viewport.PlatformWindowCreated

            if g.PlatformIO.Platform_GetWindowMinimized and platform_funcs_available then
                local is_minimized = g.PlatformIO.Platform_GetWindowMinimized(viewport)
                if is_minimized then
                    viewport.Flags = bit.bor(viewport.Flags, ImGuiViewportFlags_IsMinimized)
                else
                    viewport.Flags = bit.band(viewport.Flags, bit.bnot(ImGuiViewportFlags_IsMinimized))
                end
            end

            -- Update our implicit z-order knowledge of platform windows, which is used when the backend cannot provide io.MouseHoveredViewport.
            -- When setting Platform_GetWindowFocus, it is expected that the platform backend can handle calls without crashing if it doesn't have data stored.
            if g.PlatformIO.Platform_GetWindowFocus and platform_funcs_available then
                local is_focused = g.PlatformIO.Platform_GetWindowFocus(viewport)
                if is_focused then
                    viewport.Flags = bit.bor(viewport.Flags, ImGuiViewportFlags_IsFocused)
                else
                    viewport.Flags = bit.band(viewport.Flags, bit.bnot(ImGuiViewportFlags_IsFocused))
                end
                if is_focused then
                    focused_viewport = viewport
                end
            end
        end

        -- Focused viewport has changed?
        if focused_viewport and g.PlatformLastFocusedViewportId ~= focused_viewport.ID then
            IMGUI_DEBUG_LOG_VIEWPORT("[viewport] Focused viewport changed %08X -> %08X '%s', attempting to apply our focus.", g.PlatformLastFocusedViewportId, focused_viewport.ID, focused_viewport.Window and focused_viewport.Window.Name or "n/a")
            local prev_focused_viewport = ImGui.FindViewportByID(g.PlatformLastFocusedViewportId)
            local prev_focused_has_been_destroyed = (prev_focused_viewport == nil) or (not prev_focused_viewport.PlatformWindowCreated)

            -- Store a tag so we can infer z-order easily from all our windows
            -- We compare PlatformLastFocusedViewportId so newly created viewports with _NoFocusOnAppearing flag
            -- will keep the front most stamp instead of losing it back to their parent viewport.
            if focused_viewport.LastFocusedStampCount ~= g.ViewportFocusedStampCount then
                g.ViewportFocusedStampCount = g.ViewportFocusedStampCount + 1
                focused_viewport.LastFocusedStampCount = g.ViewportFocusedStampCount
            end
            g.PlatformLastFocusedViewportId = focused_viewport.ID

            -- Focus associated dear imgui window
            -- - if focus didn't happen with a click within imgui boundaries, e.g. Clicking platform title bar. (#6299)
            -- - if focus didn't happen because we destroyed another window (#6462)
            -- FIXME: perhaps 'FocusTopMostWindowUnderOne()' can handle the 'focused_window.Window ~= nil' case as well.
            local apply_imgui_focus_on_focused_viewport = not ImGui.IsAnyMouseDown() and not prev_focused_has_been_destroyed
            if apply_imgui_focus_on_focused_viewport and g.IO.ConfigViewportsPlatformFocusSetsImGuiFocus then
                focused_viewport.LastFocusedHadNavWindow = focused_viewport.LastFocusedHadNavWindow or (g.NavWindow ~= nil and g.NavWindow.Viewport == focused_viewport)  -- Update so a window changing viewport won't lose focus.

                local focus_request_flags = bit.bor(ImGuiFocusRequestFlags_UnlessBelowModal, ImGuiFocusRequestFlags_RestoreFocusedChild)
                if focused_viewport.Window ~= nil then
                    ImGui.FocusWindow(focused_viewport.Window, focus_request_flags)
                elseif focused_viewport.LastFocusedHadNavWindow then
                    ImGui.FocusTopMostWindowUnderOne(nil, nil, focused_viewport, focus_request_flags)  -- Focus top most in viewport
                else
                    ImGui.FocusWindow(nil, focus_request_flags)  -- No window had focus last time viewport was focused
                end
            end
        end

        if focused_viewport then
            focused_viewport.LastFocusedHadNavWindow = (g.NavWindow ~= nil) and (g.NavWindow.Viewport == focused_viewport)
        end
    end

    -- Create/update main viewport with current platform position.
    -- FIXME-VIEWPORT: Size is driven by backend/user code for backward-compatibility but we should aim to make this more consistent.
    local main_viewport = g.Viewports.Data[1]
    IM_ASSERT(main_viewport.ID == IMGUI_VIEWPORT_DEFAULT_ID)
    IM_ASSERT(main_viewport.Window == nil)

    local main_viewport_pos
    if viewports_enabled then
        main_viewport_pos = g.PlatformIO.Platform_GetWindowPos(main_viewport)
    else
        main_viewport_pos = ImVec2(0.0, 0.0)
    end
    local main_viewport_size = g.IO.DisplaySize
    local main_viewport_framebuffer_scale = g.IO.DisplayFramebufferScale

    if viewports_enabled and (bit.band(main_viewport.Flags, ImGuiViewportFlags_IsMinimized) ~= 0) then
        ImVec2_Copy(main_viewport_pos, main_viewport.Pos) -- Preserve last pos/size when minimized (FIXME: We don't do the same for Size outside of the viewport path)
        ImVec2_Copy(main_viewport_size, main_viewport.Size)
        main_viewport_framebuffer_scale = main_viewport.FramebufferScale
    end

    ImGui.AddUpdateViewport(nil, IMGUI_VIEWPORT_DEFAULT_ID, main_viewport_pos, main_viewport_size, bit.bor(ImGuiViewportFlags_OwnedByApp, ImGuiViewportFlags_CanHostOtherWindows))

    g.CurrentDpiScale = 0.0
    g.CurrentViewport = nil
    g.MouseViewport = nil

    local n = 1
    while n <= g.Viewports.Size do
        local viewport = g.Viewports.Data[n]
        viewport.Idx = n

        -- Erase unused viewports
        if n > 1 and viewport.LastFrameActive < g.FrameCount - 2 then
            ImGui.DestroyViewport(viewport)
            -- n stays the same because we removed an element
        else
            local platform_funcs_available = viewport.PlatformWindowCreated

            if viewports_enabled then
                -- Update Position and Size (from Platform Window to ImGui) if requested.
                -- We do it early in the frame instead of waiting for UpdatePlatformWindows() to avoid a frame of lag when moving/resizing using OS facilities.
                if (bit.band(viewport.Flags, ImGuiViewportFlags_IsMinimized) == 0) and platform_funcs_available then
                    -- Viewport->WorkPos and WorkSize will be updated below
                    if viewport.PlatformRequestMove then
                        viewport.Pos = g.PlatformIO.Platform_GetWindowPos(viewport)
                        ImVec2_Copy(viewport.LastPlatformPos, viewport.Pos)
                    end
                    if viewport.PlatformRequestResize then
                        viewport.Size = g.PlatformIO.Platform_GetWindowSize(viewport)
                        ImVec2_Copy(viewport.LastPlatformSize, viewport.Size)
                    end
                    if g.PlatformIO.Platform_GetWindowFramebufferScale ~= nil then
                        viewport.FramebufferScale = g.PlatformIO.Platform_GetWindowFramebufferScale(viewport)
                    end
                end
            end

            -- Update/copy monitor info
            ImGui.UpdateViewportPlatformMonitor(viewport)

            -- Lock down space taken by menu bars and status bars + query initial insets from backend
            -- Setup initial value for functions like BeginMainMenuBar(), DockSpaceOverViewport() etc.
            viewport.WorkInsetMin = viewport.BuildWorkInsetMin
            viewport.WorkInsetMax = viewport.BuildWorkInsetMax
            viewport.BuildWorkInsetMin = ImVec2(0.0, 0.0)
            viewport.BuildWorkInsetMax = ImVec2(0.0, 0.0)

            if g.PlatformIO.Platform_GetWindowWorkAreaInsets ~= nil and platform_funcs_available then
                local insets = g.PlatformIO.Platform_GetWindowWorkAreaInsets(viewport)
                IM_ASSERT(insets.x >= 0.0 and insets.y >= 0.0 and insets.z >= 0.0 and insets.w >= 0.0)
                viewport.BuildWorkInsetMin = ImVec2(insets.x, insets.y)
                viewport.BuildWorkInsetMax = ImVec2(insets.z, insets.w)
            end

            viewport:UpdateWorkRect()

            -- Reset alpha every frame. Users of transparency (docking) needs to request a lower alpha back.
            viewport.Alpha = 1.0

            -- Translate Dear ImGui windows when a Host Viewport has been moved
            -- (This additionally keeps windows at the same place when ImGuiConfigFlags_ViewportsEnable is toggled!)
            local viewport_delta_pos = viewport.Pos - viewport.LastPos
            if (bit.band(viewport.Flags, ImGuiViewportFlags_CanHostOtherWindows) ~= 0) and (viewport_delta_pos.x ~= 0.0 or viewport_delta_pos.y ~= 0.0) then
                ImGui.TranslateWindowsInViewport(viewport, viewport.LastPos, viewport.Pos, viewport.LastSize, viewport.Size)
            end

            -- Update DPI scale
            local new_dpi_scale
            if g.PlatformIO.Platform_GetWindowDpiScale and platform_funcs_available then
                new_dpi_scale = g.PlatformIO.Platform_GetWindowDpiScale(viewport)
            elseif viewport.PlatformMonitor ~= -1 then
                new_dpi_scale = g.PlatformIO.Monitors.Data[viewport.PlatformMonitor].DpiScale
            else
                new_dpi_scale = (viewport.DpiScale ~= 0.0) and viewport.DpiScale or 1.0
            end

            IM_ASSERT(new_dpi_scale > 0.0 and new_dpi_scale < 99.0)  -- Typical correct values would be between 1.0f and 4.0f

            if viewport.DpiScale ~= 0.0 and new_dpi_scale ~= viewport.DpiScale then
                local scale_factor = new_dpi_scale / viewport.DpiScale
                if g.IO.ConfigDpiScaleViewports then
                    ImGui.ScaleWindowsInViewport(viewport, scale_factor)
                end
                -- if viewport == ImGui.GetMainViewport() then
                --     g.PlatformInterface.SetWindowSize(viewport, viewport.Size * scale_factor)
                -- end

                -- Scale our window moving pivot so that the window will rescale roughly around the mouse position.
                -- FIXME-VIEWPORT: This currently creates a resizing feedback loop when a window is straddling a DPI transition border.
                -- (Minor: since our sizes do not perfectly linearly scale, deferring the click offset scale until we know the actual window scale ratio may get us slightly more precise mouse positioning.)
                -- if g.MovingWindow ~= nil and g.MovingWindow.Viewport == viewport then
                --     g.ActiveIdClickOffset = ImTrunc(g.ActiveIdClickOffset * scale_factor)
                -- end
            end

            viewport.DpiScale = new_dpi_scale
            n = n + 1
        end
    end

    -- Update fallback monitor
    g.PlatformMonitorsFullWorkRect = ImRect(FLT_MAX, FLT_MAX, -FLT_MAX, -FLT_MAX)

    if g.PlatformIO.Monitors.Size == 0 then
        local monitor = g.FallbackMonitor
        ImVec2_Copy(monitor.MainPos, main_viewport.Pos)
        ImVec2_Copy(monitor.MainSize, main_viewport.Size)
        ImVec2_Copy(monitor.WorkPos, main_viewport.WorkPos)
        ImVec2_Copy(monitor.WorkSize, main_viewport.WorkSize)
        monitor.DpiScale = main_viewport.DpiScale

        g.PlatformMonitorsFullWorkRect:Add(monitor.WorkPos)
        g.PlatformMonitorsFullWorkRect:Add(monitor.WorkPos + monitor.WorkSize)
    else
        g.FallbackMonitor = g.PlatformIO.Monitors.Data[1]
    end

    for i = 1, g.PlatformIO.Monitors.Size do
        local monitor = g.PlatformIO.Monitors.Data[i]
        g.PlatformMonitorsFullWorkRect:Add(monitor.WorkPos)
        g.PlatformMonitorsFullWorkRect:Add(monitor.WorkPos + monitor.WorkSize)
    end

    if not viewports_enabled then
        g.MouseViewport = main_viewport
        return
    end

    -- Mouse handling: decide on the actual mouse viewport for this frame between the active/focused viewport and the hovered viewport.
    -- Note that 'viewport_hovered' should skip over any viewport that has the ImGuiViewportFlags_NoInputs flags set.
    local viewport_hovered = nil

    if bit.band(g.IO.BackendFlags, ImGuiBackendFlags.HasMouseHoveredViewport) ~= 0 then
        viewport_hovered = g.IO.MouseHoveredViewport and ImGui.FindViewportByID(g.IO.MouseHoveredViewport) or nil
        if viewport_hovered and (bit.band(viewport_hovered.Flags, ImGuiViewportFlags_NoInputs) ~= 0) then
            viewport_hovered = ImGui.FindHoveredViewportFromPlatformWindowStack(g.IO.MousePos)  -- Backend failed to handle _NoInputs viewport: revert to our fallback.
        end
    else
        -- If the backend doesn't know how to honor ImGuiViewportFlags_NoInputs, we do a search ourselves. Note that this search:
        -- A) won't take account of the possibility that non-imgui windows may be in-between our dragged window and our target window.
        -- B) won't take account of how the backend apply parent<>child relationship to secondary viewports, which affects their Z order.
        -- C) uses LastFrameAsRefViewport as a flawed replacement for the last time a window was focused (we could/should fix that by introducing Focus functions in PlatformIO)
        viewport_hovered = ImGui.FindHoveredViewportFromPlatformWindowStack(g.IO.MousePos)
    end

    if viewport_hovered ~= nil then
        g.MouseLastHoveredViewport = viewport_hovered
    elseif g.MouseLastHoveredViewport == nil then
        g.MouseLastHoveredViewport = g.Viewports.Data[1]
    end

    -- Update mouse reference viewport
    -- (when moving a window we aim at its viewport, but this will be overwritten below if we go in drag and drop mode)
    -- (MovingViewport->Viewport will be nil in the rare situation where the window disappared while moving, set UpdateMouseMovingWindowNewFrame() for details)
    if g.MovingWindow and g.MovingWindow.Viewport then
        g.MouseViewport = g.MovingWindow.Viewport
    else
        g.MouseViewport = g.MouseLastHoveredViewport
    end

    -- When dragging something, always refer to the last hovered viewport.
    -- - when releasing a moving window we will revert to aiming behind (at viewport_hovered)
    -- - when we are between viewports, our dragged preview will tend to show in the last viewport _even_ if we don't have tooltips in their viewports (when lacking monitor info)
    -- - consider the case of holding on a menu item to browse child menus: even thou a mouse button is held, there's no active id because menu items only react on mouse release.
    -- FIXME-VIEWPORT: This is essentially broken, when ImGuiBackendFlags.HasMouseHoveredViewport is set we want to trust when viewport_hovered==nil and use that.
    local is_mouse_dragging_with_an_expected_destination = g.DragDropActive
    if is_mouse_dragging_with_an_expected_destination and viewport_hovered == nil then
        viewport_hovered = g.MouseLastHoveredViewport
    end

    if is_mouse_dragging_with_an_expected_destination or g.ActiveId == 0 or not ImGui.IsAnyMouseDown() then
        if viewport_hovered ~= nil and viewport_hovered ~= g.MouseViewport and (bit.band(viewport_hovered.Flags, ImGuiViewportFlags_NoInputs) == 0) then
            g.MouseViewport = viewport_hovered
        end
    end

    IM_ASSERT(g.MouseViewport ~= nil)
end

function ImGui.UpdateViewportsEndFrame()
    local g = GImGui
    g.PlatformIO.Viewports:resize(0)

    for i = 1, g.Viewports.Size do
        local viewport = g.Viewports.Data[i]
        viewport.LastPos = ImVec2(viewport.Pos.x, viewport.Pos.y)
        viewport.LastSize = ImVec2(viewport.Size.x, viewport.Size.y)

        if viewport.LastFrameActive < g.FrameCount or viewport.Size.x <= 0.0 or viewport.Size.y <= 0.0 then
            if i > 1 then  -- Always include main viewport in the list
                goto CONTINUE
            end
        end
        if viewport.Window and not ImGui.IsWindowActiveAndVisible(viewport.Window) then
            goto CONTINUE
        end
        if i > 1 then
            IM_ASSERT(viewport.Window ~= nil)
        end
        g.PlatformIO.Viewports:push_back(viewport)

        ::CONTINUE::
    end

    g.Viewports.Data[1]:ClearRequestFlags()  -- Clear main viewport flags because UpdatePlatformWindows() won't do it and may not even be called
end

--- @param window? ImGuiWindow
--- @param id      ImGuiID
--- @param pos     ImVec2
--- @param size    ImVec2
--- @param flags   ImGuiViewportFlags
--- @return ImGuiViewportP
function ImGui.AddUpdateViewport(window, id, pos, size, flags)
    local g = GImGui
    IM_ASSERT(id ~= 0)

    flags = bit.bor(flags, ImGuiViewportFlags_IsPlatformWindow)
    if window ~= nil then
        local window_can_use_inputs = (bit.band(window.Flags, bit.bor(ImGuiWindowFlags_NoMouseInputs, ImGuiWindowFlags_NoNavInputs)) == 0)
        if g.MovingWindow and g.MovingWindow.RootWindowDockTree == window then
            flags = bit.bor(flags, ImGuiViewportFlags_NoInputs, ImGuiViewportFlags_NoFocusOnAppearing)
        end
        if not window_can_use_inputs then
            flags = bit.bor(flags, ImGuiViewportFlags_NoInputs)
        end
        if bit.band(window.Flags, ImGuiWindowFlags_NoFocusOnAppearing) ~= 0 then
            flags = bit.bor(flags, ImGuiViewportFlags_NoFocusOnAppearing)
        end
    end

    local viewport = ImGui.FindViewportByID(id)
    if viewport then
        --- @cast viewport ImGuiViewportP

        -- Always update for main viewport as we are already pulling correct platform pos/size (see #4900)
        local prev_pos = ImVec2(viewport.Pos.x, viewport.Pos.y)
        local prev_size = ImVec2(viewport.Size.x, viewport.Size.y)
        if not viewport.PlatformRequestMove or viewport.ID == IMGUI_VIEWPORT_DEFAULT_ID then
            ImVec2_Copy(viewport.Pos, pos)
        end
        if not viewport.PlatformRequestResize or viewport.ID == IMGUI_VIEWPORT_DEFAULT_ID then
            ImVec2_Copy(viewport.Size, size)
        end
        -- Preserve existing flags
        viewport.Flags = bit.bor(flags, bit.band(viewport.Flags, bit.bor(ImGuiViewportFlags_IsMinimized, ImGuiViewportFlags_IsFocused)))
        if prev_pos.x ~= viewport.Pos.x or prev_pos.y ~= viewport.Pos.y or prev_size.x ~= viewport.Size.x or prev_size.y ~= viewport.Size.y then
            ImGui.UpdateViewportPlatformMonitor(viewport)
        end
    else
        -- New viewport
        viewport = ImGuiViewportP()
        viewport.ID = id
        viewport.Idx = g.Viewports.Size
        ImVec2_Copy(viewport.Pos, pos)
        ImVec2_Copy(viewport.LastPos, pos)
        ImVec2_Copy(viewport.Size, size)
        ImVec2_Copy(viewport.LastSize, size)
        viewport.Flags = flags
        ImGui.UpdateViewportPlatformMonitor(viewport)
        g.Viewports:push_back(viewport)
        g.ViewportCreatedCount = g.ViewportCreatedCount + 1
        IMGUI_DEBUG_LOG_VIEWPORT("[viewport] Add Viewport %08X '%s'", id, window and window.Name or "<NULL>")

        -- We assume the window becomes front-most (even when ImGuiViewportFlags_NoFocusOnAppearing is used).
        -- This is useful for our platform z-order heuristic when io.MouseHoveredViewport is not available.
        g.ViewportFocusedStampCount = g.ViewportFocusedStampCount + 1
        viewport.LastFocusedStampCount = g.ViewportFocusedStampCount

        -- We normally setup for all viewports in NewFrame() but here need to handle the mid-frame creation of a new viewport.
        -- We need to extend the fullscreen clip rect so the OverlayDrawList clip is correct for that the first frame
        g.DrawListSharedData.ClipRectFullscreen.x = ImMin(g.DrawListSharedData.ClipRectFullscreen.x, viewport.Pos.x)
        g.DrawListSharedData.ClipRectFullscreen.y = ImMin(g.DrawListSharedData.ClipRectFullscreen.y, viewport.Pos.y)
        g.DrawListSharedData.ClipRectFullscreen.z = ImMax(g.DrawListSharedData.ClipRectFullscreen.z, viewport.Pos.x + viewport.Size.x)
        g.DrawListSharedData.ClipRectFullscreen.w = ImMax(g.DrawListSharedData.ClipRectFullscreen.w, viewport.Pos.y + viewport.Size.y)

        -- Store initial DpiScale before the OS platform window creation, based on expected monitor data.
        -- This is so we can select an appropriate font size on the first frame of our window lifetime
        viewport.DpiScale = ImGui.GetViewportPlatformMonitor(viewport).DpiScale
    end

    viewport.Window = window
    viewport.LastFrameActive = g.FrameCount
    viewport:UpdateWorkRect()
    IM_ASSERT(window == nil or viewport.ID == window.ID)

    if window ~= nil then
        window.ViewportOwned = true
    end

    return viewport
end

--- @param viewport ImGuiViewportP
function ImGui.DestroyViewport(viewport)
    -- Clear references to this viewport in windows (window->ViewportId becomes the master data)
    local g = GImGui
    for i = 1, g.Windows.Size do
        local window = g.Windows.Data[i]
        if window.Viewport ~= viewport then
            goto CONTINUE
        end
        window.Viewport = nil
        window.ViewportOwned = false
        ::CONTINUE::
    end

    if viewport == g.MouseLastHoveredViewport then
        g.MouseLastHoveredViewport = nil
    end

    -- Destroy
    IMGUI_DEBUG_LOG_VIEWPORT("[viewport] Delete Viewport %08X '%s'", viewport.ID, viewport.Window and viewport.Window.Name or "n/a")
    ImGui.DestroyPlatformWindow(viewport)  -- In most circumstances the platform window will already be destroyed here.
    IM_ASSERT(not g.PlatformIO.Viewports:contains(viewport))
    IM_ASSERT(g.Viewports.Data[viewport.Idx] == viewport)
    g.Viewports:erase(viewport.Idx)
    -- IM_DELETE(viewport)
end

--- @param window ImGuiWindow
function ImGui.WindowSelectViewport(window)
    local g = GImGui
    local flags = window.Flags
    window.ViewportAllowPlatformMonitorExtend = -1

    -- Restore main viewport if multi-viewport is not supported by the backend
    local main_viewport = ImGui.GetMainViewport() --[[@as ImGuiViewportP]]
    if bit.band(g.ConfigFlagsCurrFrame, ImGuiConfigFlags_ViewportsEnable) == 0 then
        ImGui.SetWindowViewport(window, main_viewport)
        return
    end
    window.ViewportOwned = false

    -- Appearing popups reset their viewport so they can inherit again
    if bit.band(flags, bit.bor(ImGuiWindowFlags_Popup, ImGuiWindowFlags_Tooltip)) ~= 0 and window.Appearing then
        window.Viewport = nil
        window.ViewportId = 0
    end

    if bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasViewport) == 0 then
        -- By default inherit from parent window
        if window.Viewport == nil and window.ParentWindow and (not window.ParentWindow.IsFallbackWindow or window.ParentWindow.WasActive) then
            window.Viewport = window.ParentWindow.Viewport
        end

        -- Attempt to restore saved viewport id (= window that hasn't been activated yet), try to restore the viewport based on saved 'window->ViewportPos' restored from .ini file
        if window.Viewport == nil and window.ViewportId ~= 0 then
            window.Viewport = ImGui.FindViewportByID(window.ViewportId) --[[@as ImGuiViewportP]]
            if window.Viewport == nil and window.ViewportPos.x ~= FLT_MAX and window.ViewportPos.y ~= FLT_MAX then
                window.Viewport = ImGui.AddUpdateViewport(window, window.ID, window.ViewportPos, window.Size, ImGuiViewportFlags_None)
            end
        end
    end

    local lock_viewport = false
    if bit.band(g.NextWindowData.HasFlags, ImGuiNextWindowDataFlags_HasViewport) ~= 0 then
        -- Code explicitly request a viewport
        window.Viewport = ImGui.FindViewportByID(g.NextWindowData.ViewportId) --[[@as ImGuiViewportP]]
        window.ViewportId = g.NextWindowData.ViewportId  -- Store ID even if Viewport isn't resolved yet.
        if window.Viewport and bit.band(window.Flags, ImGuiWindowFlags_DockNodeHost) ~= 0 and window.Viewport.Window ~= nil then
            window.Viewport.Window = window
            window.Viewport.ID = window.ID
            window.ViewportId = window.ID  -- Overwrite ID (always owned by node)
        end
        lock_viewport = true
    elseif bit.band(flags, ImGuiWindowFlags_ChildWindow) ~= 0 or bit.band(flags, ImGuiWindowFlags_ChildMenu) ~= 0 then
        -- Always inherit viewport from parent window
        if window.DockNode and window.DockNode.HostWindow then
            IM_ASSERT(window.DockNode.HostWindow.Viewport == window.ParentWindow.Viewport)
        end
        window.Viewport = window.ParentWindow.Viewport
    elseif window.DockNode and window.DockNode.HostWindow then
        -- This covers the "always inherit viewport from parent window" case for when a window reattach to a node that was just created mid-frame
        window.Viewport = window.DockNode.HostWindow.Viewport
    elseif bit.band(flags, ImGuiWindowFlags_Tooltip) ~= 0 then
        window.Viewport = g.MouseViewport
    elseif ImGui.GetWindowAlwaysWantOwnViewport(window) then
        window.Viewport = ImGui.AddUpdateViewport(window, window.ID, window.Pos, window.Size, ImGuiViewportFlags_None)
    elseif g.MovingWindow and g.MovingWindow.RootWindowDockTree == window and ImGui.IsMousePosValid() then
        if window.Viewport ~= nil and window.Viewport.Window == window then
            window.Viewport = ImGui.AddUpdateViewport(window, window.ID, window.Pos, window.Size, ImGuiViewportFlags_None)
        end
    else
        -- Merge into host viewport?
        -- We cannot test window->ViewportOwned as it set lower in the function.
        -- Testing (g.ActiveId == 0 || g.ActiveIdAllowOverlap) to avoid merging during a short-term widget interaction. Main intent was to avoid during resize (see #4212)
        local try_to_merge_into_host_viewport = (window.Viewport and window == window.Viewport.Window and (g.ActiveId == 0 or g.ActiveIdAllowOverlap))
        if try_to_merge_into_host_viewport then
            ImGui.UpdateTryMergeWindowIntoHostViewports(window)
        end
    end

    -- Fallback: merge in default viewport if z-order matches, otherwise create a new viewport
    if window.Viewport == nil then
        --- @cast main_viewport ImGuiViewportP
        if not ImGui.UpdateTryMergeWindowIntoHostViewport(window, main_viewport) then
            window.Viewport = ImGui.AddUpdateViewport(window, window.ID, window.Pos, window.Size, ImGuiViewportFlags_None)
        end
    end

    -- Mark window as allowed to protrude outside of its viewport and into the current monitor
    if not lock_viewport then
        if bit.band(flags, bit.bor(ImGuiWindowFlags_Tooltip, ImGuiWindowFlags_Popup)) ~= 0 then
            -- We need to take account of the possibility that mouse may become invalid.
            -- Popups/Tooltip always set ViewportAllowPlatformMonitorExtend so GetWindowAllowedExtentRect() will return full monitor bounds.
            local mouse_ref = bit.band(flags, ImGuiWindowFlags_Tooltip) ~= 0 and g.IO.MousePos or g.BeginPopupStack.Data[g.BeginPopupStack.Size].OpenMousePos
            local use_mouse_ref = not g.NavCursorVisible or not g.NavHighlightItemUnderNav or not g.NavWindow
            local mouse_valid = ImGui.IsMousePosValid(mouse_ref)
            if (window.Appearing or bit.band(flags, bit.bor(ImGuiWindowFlags_Tooltip, ImGuiWindowFlags_ChildMenu)) ~= 0) and (not use_mouse_ref or mouse_valid) then
                local pos_to_use = (use_mouse_ref and mouse_valid) and mouse_ref or ImGui.NavCalcPreferredRefPos(window.Flags)
                window.ViewportAllowPlatformMonitorExtend = ImGui.FindPlatformMonitorForPos(pos_to_use)
            else
                window.ViewportAllowPlatformMonitorExtend = window.Viewport.PlatformMonitor
            end
        elseif window.Viewport and window ~= window.Viewport.Window and window.Viewport.Window and bit.band(flags, ImGuiWindowFlags_ChildWindow) == 0 and window.DockNode == nil then
            -- When called from Begin() we don't have access to a proper version of the Hidden flag yet, so we replicate this code.
            local will_be_visible = (window.DockIsActive and not window.DockTabIsVisible) and false or true
            if bit.band(window.Flags, ImGuiWindowFlags_DockNodeHost) ~= 0 and window.Viewport.LastFrameActive < g.FrameCount and will_be_visible then
                -- Steal/transfer ownership
                IMGUI_DEBUG_LOG_VIEWPORT("[viewport] Window '%s' steal Viewport %08X from Window '%s'", window.Name, window.Viewport.ID, window.Viewport.Window.Name)
                window.Viewport.Window = window
                window.Viewport.ID = window.ID
                window.Viewport.LastNameHash = 0
            elseif not ImGui.UpdateTryMergeWindowIntoHostViewports(window) then  -- Merge?
                -- New viewport
                window.Viewport = ImGui.AddUpdateViewport(window, window.ID, window.Pos, window.Size, ImGuiViewportFlags_NoFocusOnAppearing)
            end
        elseif window.ViewportAllowPlatformMonitorExtend < 0 and bit.band(flags, ImGuiWindowFlags_ChildWindow) == 0 then
            -- Regular (non-child, non-popup) windows by default are also allowed to protrude
            -- Child windows are kept contained within their parent.
            window.ViewportAllowPlatformMonitorExtend = window.Viewport.PlatformMonitor
        end
    end

    -- Update flags
    window.ViewportOwned = (window == window.Viewport.Window)
    window.ViewportId = window.Viewport.ID

    -- If the OS window has a title bar, hide our imgui title bar
    -- if window.ViewportOwned and bit.band(window.Viewport.Flags, ImGuiViewportFlags_NoDecoration) == 0 then
    --     window.Flags = bit.bor(window.Flags, ImGuiWindowFlags_NoTitleBar)
    -- end
end

--- @param window                  ImGuiWindow
--- @param parent_window_in_stack? ImGuiWindow
function ImGui.WindowSyncOwnedViewport(window, parent_window_in_stack)
    local g = GImGui
    local viewport_rect_changed = false

    -- Synchronize window --> viewport in most situations
    -- Synchronize viewport -> window in case the platform window has been moved or resized from the OS/WM
    if window.Viewport.PlatformRequestMove then
        ImVec2_Copy(window.Pos, window.Viewport.Pos)
        -- ImGui.MarkIniSettingsDirty(window)
    elseif window.Viewport.Pos.x ~= window.Pos.x or window.Viewport.Pos.y ~= window.Pos.y then
        viewport_rect_changed = true
        window.Viewport.Pos = ImVec2(window.Pos.x, window.Pos.y)
    end

    if window.Viewport.PlatformRequestResize then
        ImVec2_Copy(window.Size, window.Viewport.Size)
        ImVec2_Copy(window.SizeFull, window.Viewport.Size)
        -- ImGui.MarkIniSettingsDirty(window)
    elseif window.Viewport.Size.x ~= window.Size.x or window.Viewport.Size.y ~= window.Size.y then
        viewport_rect_changed = true
        window.Viewport.Size = ImVec2(window.Size.x, window.Size.y)
    end
    window.Viewport:UpdateWorkRect()

    -- The viewport may have changed monitor since the global update in UpdateViewportsNewFrame()
    -- Either a SetNextWindowPos() call in the current frame or a SetWindowPos() call in the previous frame may have this effect.
    if viewport_rect_changed then
        ImGui.UpdateViewportPlatformMonitor(window.Viewport)
    end

    -- Update common viewport flags
    local viewport_flags_to_clear = bit.bor(ImGuiViewportFlags_TopMost, ImGuiViewportFlags_NoTaskBarIcon, ImGuiViewportFlags_NoDecoration, ImGuiViewportFlags_NoRendererClear)
    local viewport_flags = bit.band(window.Viewport.Flags, bit.bnot(viewport_flags_to_clear))
    local window_flags = window.Flags
    local is_modal = bit.band(window_flags, ImGuiWindowFlags_Modal) ~= 0
    local is_short_lived_floating_window = bit.band(window_flags, bit.bor(ImGuiWindowFlags_ChildMenu, ImGuiWindowFlags_Tooltip, ImGuiWindowFlags_Popup)) ~= 0

    if bit.band(window_flags, ImGuiWindowFlags_Tooltip) ~= 0 then
        viewport_flags = bit.bor(viewport_flags, ImGuiViewportFlags_TopMost)
    end

    if (g.IO.ConfigViewportsNoTaskBarIcon or is_short_lived_floating_window) and not is_modal then
        viewport_flags = bit.bor(viewport_flags, ImGuiViewportFlags_NoTaskBarIcon)
    end

    if g.IO.ConfigViewportsNoDecoration or is_short_lived_floating_window then
        viewport_flags = bit.bor(viewport_flags, ImGuiViewportFlags_NoDecoration)
    end

    -- Not correct to set modal as topmost because:
    -- - Because other popups can be stacked above a modal (e.g. combo box in a modal)
    -- - ImGuiViewportFlags_TopMost is currently handled different in backends: in Win32 it is "appear top most" whereas in GLFW and SDL it is "stay topmost"
    -- if bit.band(window_flags, ImGuiWindowFlags_Modal) ~= 0 then
    --     viewport_flags = bit.bor(viewport_flags, ImGuiViewportFlags_TopMost)
    -- end

    -- For popups and menus that may be protruding out of their parent viewport, we enable _NoFocusOnClick so that clicking on them
    -- won't steal the OS focus away from their parent window (which may be reflected in OS the title bar decoration).
    -- Setting _NoFocusOnClick would technically prevent us from bringing back to front in case they are being covered by an OS window from a different app,
    -- but it shouldn't be much of a problem considering those are already popups that are closed when clicking elsewhere.
    if is_short_lived_floating_window and not is_modal then
        viewport_flags = bit.bor(viewport_flags, ImGuiViewportFlags_NoFocusOnAppearing, ImGuiViewportFlags_NoFocusOnClick)
    end

    -- We can overwrite viewport flags using ImGuiWindowClass (advanced users)
    if window.WindowClass.ViewportFlagsOverrideSet ~= 0 then
        viewport_flags = bit.bor(viewport_flags, window.WindowClass.ViewportFlagsOverrideSet)
    end
    if window.WindowClass.ViewportFlagsOverrideClear ~= 0 then
        viewport_flags = bit.band(viewport_flags, bit.bnot(window.WindowClass.ViewportFlagsOverrideClear))
    end

    -- We can also tell the backend that clearing the platform window won't be necessary,
    -- as our window background is filling the viewport and we have disabled BgAlpha.
    -- FIXME: Work on support for per-viewport transparency (#2766)
    if bit.band(window_flags, ImGuiWindowFlags_NoBackground) == 0 then
        viewport_flags = bit.bor(viewport_flags, ImGuiViewportFlags_NoRendererClear)
    end

    window.Viewport.Flags = viewport_flags

    -- Update parent viewport ID
    -- (the !IsFallbackWindow test mimic the one done in WindowSelectViewport())
    if window.WindowClass.ParentViewportId ~= 0xFFFFFFFF then
        local old_parent_viewport_id = window.Viewport.ParentViewportId
        window.Viewport.ParentViewportId = window.WindowClass.ParentViewportId
        if window.Viewport.ParentViewportId ~= old_parent_viewport_id then
            window.Viewport.ParentViewport = ImGui.FindViewportByID(window.Viewport.ParentViewportId) --[[@as ImGuiViewport]]
        end
    elseif bit.band(window_flags, bit.bor(ImGuiWindowFlags_Popup, ImGuiWindowFlags_Tooltip)) ~= 0 and parent_window_in_stack and (not parent_window_in_stack.IsFallbackWindow or parent_window_in_stack.WasActive) then
        window.Viewport.ParentViewport = parent_window_in_stack.Viewport
        window.Viewport.ParentViewportId = parent_window_in_stack.Viewport.ID
    else
        if g.IO.ConfigViewportsNoDefaultParent then
            window.Viewport.ParentViewport = nil
        else
            window.Viewport.ParentViewport = ImGui.GetMainViewport()
        end
        window.Viewport.ParentViewportId = g.IO.ConfigViewportsNoDefaultParent and 0 or IMGUI_VIEWPORT_DEFAULT_ID
    end
end

function ImGui.UpdatePlatformWindows()
    local g = GImGui
    IM_ASSERT(g.FrameCountEnded == g.FrameCount, "Forgot to call Render() or EndFrame() before UpdatePlatformWindows()?")
    IM_ASSERT(g.FrameCountPlatformEnded < g.FrameCount)
    g.FrameCountPlatformEnded = g.FrameCount
    if bit.band(g.ConfigFlagsCurrFrame, ImGuiConfigFlags_ViewportsEnable) == 0 then
        return
    end

    -- Create/resize/destroy platform windows to match each active viewport.
    -- Skip the main viewport (index 0), which is always fully handled by the application!
    for i = 2, g.Viewports.Size do
        local viewport = g.Viewports.Data[i]

        -- Destroy platform window if the viewport hasn't been submitted or if it is hosting a hidden window
        -- (the implicit/fallback Debug##Default window will be registering its viewport then be disabled, causing a dummy DestroyPlatformWindow to be made each frame)
        local destroy_platform_window = false
        destroy_platform_window = destroy_platform_window or (viewport.LastFrameActive < g.FrameCount - 1)
        destroy_platform_window = destroy_platform_window or (viewport.Window and not ImGui.IsWindowActiveAndVisible(viewport.Window))
        if destroy_platform_window then
            ImGui.DestroyPlatformWindow(viewport)
            goto CONTINUE
        end

        -- New windows that appears directly in a new viewport won't always have a size on their first frame
        if viewport.LastFrameActive < g.FrameCount or viewport.Size.x <= 0 or viewport.Size.y <= 0 then
            goto CONTINUE
        end

        -- Create window
        local is_new_platform_window = not viewport.PlatformWindowCreated
        if is_new_platform_window then
            IMGUI_DEBUG_LOG_VIEWPORT("[viewport] Create Platform Window %08X '%s'", viewport.ID, viewport.Window and viewport.Window.Name or "n/a")
            g.PlatformIO.Platform_CreateWindow(viewport)
            if g.PlatformIO.Renderer_CreateWindow ~= nil then
                g.PlatformIO.Renderer_CreateWindow(viewport)
            end
            g.PlatformWindowsCreatedCount = g.PlatformWindowsCreatedCount + 1
            viewport.LastNameHash = 0
            viewport.LastPlatformPos = ImVec2(FLT_MAX, FLT_MAX)
            viewport.LastPlatformSize = ImVec2(FLT_MAX, FLT_MAX)  -- By clearing those we'll enforce a call to Platform_SetWindowPos/Size below, before Platform_ShowWindow (FIXME: Is that necessary?)
            viewport.LastRendererSize = ImVec2(viewport.Size.x, viewport.Size.y)  -- We don't need to call Renderer_SetWindowSize() as it is expected Renderer_CreateWindow() already did it.
            viewport.PlatformWindowCreated = true
        end

        -- Apply Position and Size (from ImGui to Platform/Renderer backends)
        if (viewport.LastPlatformPos.x ~= viewport.Pos.x or viewport.LastPlatformPos.y ~= viewport.Pos.y) and not viewport.PlatformRequestMove then
            g.PlatformIO.Platform_SetWindowPos(viewport, viewport.Pos)
        end
        if (viewport.LastPlatformSize.x ~= viewport.Size.x or viewport.LastPlatformSize.y ~= viewport.Size.y) and not viewport.PlatformRequestResize then
            g.PlatformIO.Platform_SetWindowSize(viewport, viewport.Size)
        end
        if (viewport.LastRendererSize.x ~= viewport.Size.x or viewport.LastRendererSize.y ~= viewport.Size.y) and g.PlatformIO.Renderer_SetWindowSize ~= nil then
            g.PlatformIO.Renderer_SetWindowSize(viewport, viewport.Size)
        end
        viewport.LastPlatformPos = ImVec2(viewport.Pos.x, viewport.Pos.y)
        viewport.LastPlatformSize = ImVec2(viewport.Size.x, viewport.Size.y)
        viewport.LastRendererSize = ImVec2(viewport.Size.x, viewport.Size.y)

        -- Update title bar (if it changed)
        local window_for_title = GetWindowForTitleDisplay(viewport.Window)
        if window_for_title ~= nil then
            local title = window_for_title.Name
            local title_begin = 1
            local title_end = ImGui.FindRenderedTextEnd(title)
            local title_hash = ImHashStr(title, nil, title_end - title_begin)
            if viewport.LastNameHash ~= title_hash then
                -- This still creates new strings
                g.PlatformIO.Platform_SetWindowTitle(viewport, string.sub(title, title_begin, title_end - 1))
                viewport.LastNameHash = title_hash
            end
        end

        -- Update alpha (if it changed)
        if viewport.LastAlpha ~= viewport.Alpha and g.PlatformIO.Platform_SetWindowAlpha ~= nil then
            g.PlatformIO.Platform_SetWindowAlpha(viewport, viewport.Alpha)
        end
        viewport.LastAlpha = viewport.Alpha

        -- Optional, general purpose call to allow the backend to perform general book-keeping even if things haven't changed.
        if g.PlatformIO.Platform_UpdateWindow ~= nil then
            g.PlatformIO.Platform_UpdateWindow(viewport)
        end

        if is_new_platform_window then
            -- On startup ensure new platform window don't steal focus (give it a few frames, as nested contents may lead to viewport being created a few frames late)
            if g.FrameCount < 3 then
                viewport.Flags = bit.bor(viewport.Flags, ImGuiViewportFlags_NoFocusOnAppearing)
            end

            -- Show window
            g.PlatformIO.Platform_ShowWindow(viewport)
        end

        -- Clear request flags
        viewport:ClearRequestFlags()

        ::CONTINUE::
    end
end

-- This is a default/basic function for performing the rendering/swap of multiple Platform Windows.
-- Custom renderers may prefer to not call this function at all, and instead iterate the publicly exposed platform data and handle rendering/sync themselves.
-- The Render/Swap functions stored in ImGuiPlatformIO are merely here to allow for this helper to exist, but you can do it yourself:
--
--    local platform_io = ImGui.GetPlatformIO()
--    for i = 2, platform_io.Viewports.Size do
--        if bit.band(platform_io.Viewports.Data[i].Flags, ImGuiViewportFlags_IsMinimized) == 0 then
--            MyRenderFunction(platform_io.Viewports.Data[i], my_args)
--        end
--    end
--    for i = 2, platform_io.Viewports.Size do
--        if bit.band(platform_io.Viewports.Data[i].Flags, ImGuiViewportFlags_IsMinimized) == 0 then
--            MySwapBufferFunction(platform_io.Viewports.Data[i], my_args)
--        end
--    end
--
function ImGui.RenderPlatformWindowsDefault(platform_render_arg, renderer_render_arg)
    -- Skip the main viewport (index 1 in Lua), which is always fully handled by the application!
    local platform_io = ImGui.GetPlatformIO()

    -- First pass: render all windows
    for i = 2, platform_io.Viewports.Size do
        local viewport = platform_io.Viewports.Data[i]
        if bit.band(viewport.Flags, ImGuiViewportFlags_IsMinimized) == 0 then
            if platform_io.Platform_RenderWindow then
                platform_io.Platform_RenderWindow(viewport, platform_render_arg)
            end
            if platform_io.Renderer_RenderWindow then
                platform_io.Renderer_RenderWindow(viewport, renderer_render_arg)
            end
        end
    end

    -- Second pass: swap buffers for all windows
    for i = 2, platform_io.Viewports.Size do
        local viewport = platform_io.Viewports.Data[i]
        if bit.band(viewport.Flags, ImGuiViewportFlags_IsMinimized) == 0 then
            if platform_io.Platform_SwapBuffers then
                platform_io.Platform_SwapBuffers(viewport, platform_render_arg)
            end
            if platform_io.Renderer_SwapBuffers then
                platform_io.Renderer_SwapBuffers(viewport, renderer_render_arg)
            end
        end
    end
end

--- @param pos ImVec2
function ImGui.FindPlatformMonitorForPos(pos)
    local g = GImGui
    for monitor_n = 1, g.PlatformIO.Monitors.Size do
        local monitor = g.PlatformIO.Monitors.Data[monitor_n]
        if ImRect(monitor.MainPos, monitor.MainPos + monitor.MainSize):ContainsV2(pos) then
            return monitor_n
        end
    end
    return -1
end

--- @param rect ImRect
--- @return int # Returns 0 if 1 monitor, -1 if 0 monitor, or a 1-based index if >= 2 monitors
function ImGui.FindPlatformMonitorForRect(rect)
    local g = GImGui
    local monitor_count = g.PlatformIO.Monitors.Size

    if monitor_count <= 1 then
        return monitor_count
    end

    -- Use a minimum threshold of 1.0f so a zero-sized rect won't false positive, and will still find the correct monitor given its position.
    -- This is necessary for tooltips which always resize down to zero at first.
    local surface_threshold = math.max(rect:GetWidth() * rect:GetHeight() * 0.5, 1.0)
    local best_monitor_n = 1  -- Default to the first monitor as fallback
    local best_monitor_surface = 0.001

    for monitor_n = 1, g.PlatformIO.Monitors.Size do
        if best_monitor_surface >= surface_threshold then
            break
        end

        local monitor = g.PlatformIO.Monitors.Data[monitor_n]
        local monitor_rect = ImRect(monitor.MainPos, monitor.MainPos + monitor.MainSize)

        if monitor_rect:Contains(rect) then
            return monitor_n
        end

        local overlapping_rect = ImRect(rect.Min.x, rect.Min.y, rect.Max.x, rect.Max.y)
        overlapping_rect:ClipWithFull(monitor_rect)
        local overlapping_surface = overlapping_rect:GetWidth() * overlapping_rect:GetHeight()

        if overlapping_surface <= best_monitor_surface then
            goto CONTINUE
        end

        best_monitor_surface = overlapping_surface
        best_monitor_n = monitor_n

        ::CONTINUE::
    end

    return best_monitor_n
end

--- @param viewport ImGuiViewportP
function ImGui.UpdateViewportPlatformMonitor(viewport)
    viewport.PlatformMonitor = ImGui.FindPlatformMonitorForRect(viewport:GetMainRect())
end

--- @param viewport_p ImGuiViewport
--- @return ImGuiPlatformMonitor
function ImGui.GetViewportPlatformMonitor(viewport_p)
    local g = GImGui
    local viewport = viewport_p --- @cast viewport ImGuiViewportP

    local monitor_idx = viewport.PlatformMonitor
    if monitor_idx >= 1 and monitor_idx <= g.PlatformIO.Monitors.Size then
        return g.PlatformIO.Monitors.Data[monitor_idx]
    end
    return g.FallbackMonitor
end

--- @param viewport ImGuiViewportP
function ImGui.DestroyPlatformWindow(viewport)
    local g = GImGui
    if viewport.PlatformWindowCreated then
        IMGUI_DEBUG_LOG_VIEWPORT("[viewport] Destroy Platform Window %08X '%s'", viewport.ID, viewport.Window and viewport.Window.Name or "n/a")
        if g.PlatformIO.Renderer_DestroyWindow then
            g.PlatformIO.Renderer_DestroyWindow(viewport)
        end
        if g.PlatformIO.Platform_DestroyWindow then
            g.PlatformIO.Platform_DestroyWindow(viewport)
        end
        IM_ASSERT(viewport.RendererUserData == nil and viewport.PlatformUserData == nil)

        -- Don't clear PlatformWindowCreated for the main viewport, as we initially set that up to true in Initialize()
        -- The righter way may be to leave it to the backend to set this flag all-together, and made the flag public.
        if viewport.ID ~= IMGUI_VIEWPORT_DEFAULT_ID then
            viewport.PlatformWindowCreated = false
        end
    else
        IM_ASSERT(viewport.RendererUserData == nil and viewport.PlatformUserData == nil and viewport.PlatformHandle == nil)
    end
    viewport.RendererUserData = nil
    viewport.PlatformUserData = nil
    viewport.PlatformHandle = nil
    viewport:ClearRequestFlags()
end

function ImGui.DestroyPlatformWindows()
    local g = GImGui
    for _, viewport in g.Viewports:iter() do
        ImGui.DestroyPlatformWindow(viewport)
    end
end