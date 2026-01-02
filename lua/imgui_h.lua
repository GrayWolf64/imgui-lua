local Enums

--- ImVec2
--
local _ImVec2 = {}
_ImVec2.__index = _ImVec2

local function ImVec2(x, y) return setmetatable({x = x or 0, y = y or 0}, _ImVec2) end

function _ImVec2:__add(other) return ImVec2(self.x + other.x, self.y + other.y) end
function _ImVec2:__sub(other) return ImVec2(self.x - other.x, self.y - other.y) end
function _ImVec2:__mul(other) if isnumber(self) then return ImVec2(self * other.x, self * other.y) elseif isnumber(other) then return ImVec2(self.x * other, self.y * other) else return ImVec2(self.x * other.x, self.y * other.y) end end
function _ImVec2:__eq(other) return self.x == other.x and self.y == other.y end
function _ImVec2:__tostring() return str_format("ImVec2(%g, %g)", self.x, self.y) end
function _ImVec2:copy() return ImVec2(self.x, self.y) end

--- A compact ImVector clone, maybe
-- ImVector<>
local _ImVector = {}
_ImVector.__index = _ImVector

function _ImVector:push_back(value) self.Size = self.Size + 1 self.Data[self.Size] = value end
function _ImVector:pop_back() if self.Size == 0 then return nil end local value = self.Data[self.Size] self.Data[self.Size] = nil self.Size = self.Size - 1 return value end
function _ImVector:clear() self.Size = 0 end
function _ImVector:clear_delete() for i = 1, self.Size do self.Data[i] = nil end self.Size = 0 end
function _ImVector:empty() return self.Size == 0 end
function _ImVector:back() if self.Size == 0 then return nil end return self.Data[self.Size] end
function _ImVector:erase(i) if i < 1 or i > self.Size then return nil end local removed = remove_at(self.Data, i) self.Size = self.Size - 1 return removed end
function _ImVector:at(i) if i < 1 or i > self.Size then return nil end return self.Data[i] end
function _ImVector:iter() local i, n = 0, self.Size return function() i = i + 1 if i <= n then return i, self.Data[i] end end end
function _ImVector:find_index(value) for i = 1, self.Size do if self.Data[i] == value then return i end end return 0 end
function _ImVector:erase_unsorted(index) if index < 1 or index > self.Size then return false end local last_idx = self.Size if index ~= last_idx then self.Data[index] = self.Data[last_idx] end self.Data[last_idx] = nil self.Size = self.Size - 1 return true end
function _ImVector:find_erase_unsorted(value) local idx = self:find_index(value) if idx > 0 then return self:erase_unsorted(idx) end return false end
function _ImVector:reserve() return end
function _ImVector:reserve_discard() return end
function _ImVector:shrink() return end
function _ImVector:resize(new_size) self.Size = new_size end

local function ImVector() return setmetatable({Data = {}, Size = 0}, _ImVector) end

local _ImTextureData = {}
_ImTextureData.__index = _ImTextureData

local function ImTextureData()
    return setmetatable({
        UniqueID             = nil,
        Status               = nil,
        BackendUserData      = nil,
        TexID                = 0, -- ImTextureID_Invalid
        Format               = nil,
        Width                = nil,
        Height               = nil,
        BytesPerPixel        = nil,
        Pixels               = nil,
        UsedRect             = nil,
        UpdateRect           = nil,
        Updates              = nil,
        UnusedFrames         = nil,
        RefCount             = nil,
        UseColors            = nil,
        WantDestroyNextFrame = nil
    }, _ImTextureData)
end

local _ImFontBaked = {}
_ImFontBaked.__index = _ImFontBaked

local function ImFontBaked()
    return setmetatable({
        IndexAdvanceX     = nil,
        FallbackAdvanceX  = nil,
        Size              = nil,
        RasterizerDensity = nil,

        IndexLookup        = nil,
        Glyphs             = nil,
        FallbackGlyphIndex = -1,

        Ascent               = nil,
        Descent              = nil,
        MetricsTotalSurface  = nil,
        WantDestroy          = nil,
        LoadNoFallback       = nil,
        LoadNoRenderOnLayout = nil,
        LastUsedFrame        = nil,
        BakedId              = nil,
        OwnerFont            = nil,
        FontLoaderDatas      = nil
    }, _ImFontBaked)
end

local _ImFont = {}
_ImFont.__index = _ImFont

local function ImFont()
    return setmetatable({
        LastBaked                = nil,
        OwnerAtlas               = nil,
        Flags                    = nil,
        CurrentRasterizerDensity = nil,

        FontId           = nil,
        LegacySize       = nil,
        Sources          = nil,
        EllipsisChar     = nil,
        FallbackChar     = nil,
        Used8kPagesMap   = nil,
        EllipsisAutoBake = nil,
        RemapPairs       = nil,
        Scale            = nil
    }, _ImFont)
end

--- struct ImFontConfig
--
local _ImFontConfig = {}
_ImFontConfig.__index = _ImFontConfig

local function ImFontConfig()
    return setmetatable({
        Name                 = nil,
        FontData             = nil,
        FontDataSize         = nil,
        FontDataOwnedByAtlas = nil,

        MergeMode          = nil,
        PixelSnapH         = nil,
        OversampleH        = nil,
        OversampleV        = nil,
        EllipsisChar       = nil,
        SizePixels         = nil,
        GlyphRanges        = nil,
        GlyphExcludeRanges = nil,
        GlyphExtraSpacing  = nil,
        GlyphOffset        = nil,
        GlyphMinAdvanceX   = nil,
        GlyphMaxAdvanceX   = nil,
        GlyphExtraAdvanceX = nil,
        FontNo             = nil,
        FontLoaderFlags    = nil,
        FontBuilderFlags   = nil,
        RasterizerMultiply = nil,
        RasterizerDensity  = nil,
        ExtraSizeScale     = nil,

        Flags          = nil,
        DstFont        = nil,
        FontLoader     = nil,
        FontLoaderData = nil
    }, _ImFontConfig)
end

local _ImFontAtlas = {}
_ImFontAtlas.__index = _ImFontAtlas

local function ImFontAtlas()
    return setmetatable({
        Flags            = nil,
        TexDesiredFormat = Enums.ImTextureFormat.RGBA32,
        TexGlyphPadding  = 1,
        TexMinWidth      = 512,
        TexMinHeight     = 128,
        TexMaxWidth      = 8192,
        TexMaxHeight     = 8192,

        TexData = ImTextureData(),

        TexList             = nil,
        Locked              = nil,
        RendererHasTextures = false,

        Fonts               = ImVector(),
        Sources             = ImVector(),
        TexUvLines          = nil, -- size = IM_DRAWLIST_TEX_LINES_WIDTH_MAX + 1
        TexNextUniqueID     = 1,
        FontNextUniqueID    = 1,
        DrawListSharedDatas = nil,
        Builder             = nil,
        FontLoader          = nil,
        FontLoaderName      = nil,
        FontLoaderData      = nil,
        FontLoaderFlags     = nil,
        RefCount            = nil,
        OwnerContext        = nil
    }, _ImFontAtlas)
end

Enums = {
    ImGuiDir = {
        Left  = 0,
        Right = 1,
        Up    = 2,
        Down  = 3
    },

    ImTextureFormat = {
        RGBA32 = 0,
        Alpha8 = 1
    },

    --- enum ImGuiWindowFlags_
    ImGuiWindowFlags = {
        None                      = 0,
        NoTitleBar                = bit.lshift(1, 0),
        NoResize                  = bit.lshift(1, 1),
        NoMove                    = bit.lshift(1, 2),
        NoScrollbar               = bit.lshift(1, 3),
        NoScrollWithMouse         = bit.lshift(1, 4),
        NoCollapse                = bit.lshift(1, 5),
        AlwaysAutoResize          = bit.lshift(1, 6),
        NoBackground              = bit.lshift(1, 7),
        NoSavedSettings           = bit.lshift(1, 8),
        NoMouseInputs             = bit.lshift(1, 9),
        MenuBar                   = bit.lshift(1, 10),
        HorizontalScrollbar       = bit.lshift(1, 11),
        NoFocusOnAppearing        = bit.lshift(1, 12),
        NoBringToFrontOnFocus     = bit.lshift(1, 13),
        AlwaysVerticalScrollbar   = bit.lshift(1, 14),
        AlwaysHorizontalScrollbar = bit.lshift(1, 15),
        NoNavInputs               = bit.lshift(1, 16),
        NoNavFocus                = bit.lshift(1, 17),
        UnsavedDocument           = bit.lshift(1, 18),

        ChildWindow = bit.lshift(1, 24),
        Tooltip     = bit.lshift(1, 25),
        Popup       = bit.lshift(1, 26),
        Modal       = bit.lshift(1, 27),
        ChildMenu   = bit.lshift(1, 28)
    },

    --- enum ImGuiItemFlags_
    ImGuiItemFlags = {
        None              = 0,
        NoTabStop         = bit.lshift(1, 0),
        NoNav             = bit.lshift(1, 1),
        NoNavDefaultFocus = bit.lshift(1, 2),
        ButtonRepeat      = bit.lshift(1, 3),
        AutoClosePopups   = bit.lshift(1, 4),
        AllowDuplicateID  = bit.lshift(1, 5)
    },

    ImGuiItemStatusFlags = {
        None             = 0,
        HoveredRect      = bit.lshift(1, 0),
        HasDisplayRect   = bit.lshift(1, 1),
        Edited           = bit.lshift(1, 2),
        ToggledSelection = bit.lshift(1, 3),
        ToggledOpen      = bit.lshift(1, 4),
        HasDeactivated   = bit.lshift(1, 5),
        Deactivated      = bit.lshift(1, 6),
        HoveredWindow    = bit.lshift(1, 7),
        Visible          = bit.lshift(1, 8),
        HasClipRect      = bit.lshift(1, 9),
        HasShortcut      = bit.lshift(1, 10)
    },

    --- enum ImDrawFlags_
    ImDrawFlags = {
        None                    = 0,
        Closed                  = bit.lshift(1, 0),
        RoundCornersTopLeft     = bit.lshift(1, 4),
        RoundCornersTopRight    = bit.lshift(1, 5),
        RoundCornersBottomLeft  = bit.lshift(1, 6),
        RoundCornersBottomRight = bit.lshift(1, 7),
        RoundCornersNone        = bit.lshift(1, 8)
    },

    --- enum ImDrawListFlags_
    ImDrawListFlags = {
        None                   = 0,
        AntiAliasedLines       = bit.lshift(1, 0),
        AntiAliasedLinesUseTex = bit.lshift(1, 1),
        AntiAliasedFill        = bit.lshift(1, 2),
        AllowVtxOffset         = bit.lshift(1, 3),
    }
}

Enums.ImGuiWindowFlags.NoNav        = bit.bor(Enums.ImGuiWindowFlags.NoNavInputs, Enums.ImGuiWindowFlags.NoNavFocus)
Enums.ImGuiWindowFlags.NoDecoration = bit.bor(Enums.ImGuiWindowFlags.NoTitleBar, Enums.ImGuiWindowFlags.NoResize, Enums.ImGuiWindowFlags.NoScrollbar, Enums.ImGuiWindowFlags.NoCollapse)
Enums.ImGuiWindowFlags.NoInputs     = bit.bor(Enums.ImGuiWindowFlags.NoMouseInputs, Enums.ImGuiWindowFlags.NoNavInputs, Enums.ImGuiWindowFlags.NoNavFocus)

Enums.ImDrawFlags.RoundCornersTop     = bit.bor(Enums.ImDrawFlags.RoundCornersTopLeft, Enums.ImDrawFlags.RoundCornersTopRight)
Enums.ImDrawFlags.RoundCornersBottom  = bit.bor(Enums.ImDrawFlags.RoundCornersBottomLeft, Enums.ImDrawFlags.RoundCornersBottomRight)
Enums.ImDrawFlags.RoundCornersLeft    = bit.bor(Enums.ImDrawFlags.RoundCornersBottomLeft, Enums.ImDrawFlags.RoundCornersTopLeft)
Enums.ImDrawFlags.RoundCornersRight   = bit.bor(Enums.ImDrawFlags.RoundCornersBottomRight, Enums.ImDrawFlags.RoundCornersTopRight)
Enums.ImDrawFlags.RoundCornersAll     = bit.bor(Enums.ImDrawFlags.RoundCornersTopLeft, Enums.ImDrawFlags.RoundCornersTopRight, Enums.ImDrawFlags.RoundCornersBottomLeft, Enums.ImDrawFlags.RoundCornersBottomRight)
Enums.ImDrawFlags.RoundCornersMask    = bit.bor(Enums.ImDrawFlags.RoundCornersAll, Enums.ImDrawFlags.RoundCornersNone)
Enums.ImDrawFlags.RoundCornersDefault = Enums.ImDrawFlags.RoundCornersAll

return {
    ImVec2   = ImVec2,
    ImVector = ImVector,

    _ImFontAtlas = _ImFontAtlas,
    ImFontAtlas  = ImFontAtlas,

    _ImFontConfig = _ImFontConfig,
    ImFontConfig  = ImFontConfig,

    _ImFont = _ImFont,
    ImFont  = ImFont,

    _ImFontBaked = _ImFontBaked,
    ImFontBaked  = ImFontBaked,

    Enums = Enums
}