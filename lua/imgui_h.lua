--- Flag defs, misc small functions and some constants
--

local Metatables = {}

local ImDir = {
    Left  = 0,
    Right = 1,
    Up    = 2,
    Down  = 3
}

local ImFontAtlasRectId_Invalid = -1

local IM_DRAWLIST_TEX_LINES_WIDTH_MAX = 32

Metatables.ImFontBaked = {}
Metatables.ImFontBaked.__index = Metatables.ImFontBaked

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
    }, Metatables.ImFontBaked)
end

Metatables.ImFont = {}
Metatables.ImFont.__index = Metatables.ImFont

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
    }, Metatables.ImFont)
end

--- struct ImFontConfig
--
Metatables.ImFontConfig = {}
Metatables.ImFontConfig.__index = Metatables.ImFontConfig

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
    }, Metatables.ImFontConfig)
end

Metatables.ImFontAtlas = {}
Metatables.ImFontAtlas.__index = Metatables.ImFontAtlas

local function ImFontAtlas()
    return setmetatable({
        Flags            = nil,
        TexDesiredFormat = nil,
        TexGlyphPadding  = nil,
        TexMinWidth      = nil,
        TexMinHeight     = nil,
        TexMaxWidth      = nil,

        TexData = nil,

        TexList = nil,
        Locked  = nil,

        Fonts               = nil,
        Sources             = nil,
        TexUvLines          = nil, -- size = IM_DRAWLIST_TEX_LINES_WIDTH_MAX + 1
        TexNextUniqueID     = nil,
        FontNextUniqueID    = nil,
        DrawListSharedDatas = nil,
        Builder             = nil,
        FontLoader          = nil,
        FontLoaderName      = nil,
        FontLoaderData      = nil,
        FontLoaderFlags     = nil,
        RefCount            = nil,
        OwnerContext        = nil
    }, Metatables.ImFontAtlas)
end

local Enums = {
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