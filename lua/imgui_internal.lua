--- Some internal structures
-- I won't implement type checks, since I ensure that types are correct in internal usage,
-- and runtime type checking is very slow
local setmetatable = setmetatable
local isnumber     = isnumber
local IsValid      = IsValid

local ScrW = ScrW
local ScrH = ScrH

local SysTime = SysTime

local GetMouseX = gui.MouseX
local GetMouseY = gui.MouseY

local surface = surface
local render  = render
local draw    = draw
local bit     = bit
local math    = math

local stbrp
local stbtt

IM_TABSIZE = 4

FLT_MAX = math.huge
#IMGUI_DEFINE IM_PI   math.pi
#IMGUI_DEFINE ImAbs   math.abs
#IMGUI_DEFINE ImFabs  math.abs
#IMGUI_DEFINE ImMin   math.min
#IMGUI_DEFINE ImMax   math.max
#IMGUI_DEFINE ImFloor math.floor
#IMGUI_DEFINE ImRound math.Round
#IMGUI_DEFINE ImCeil  math.ceil
#IMGUI_DEFINE ImSin   math.sin
#IMGUI_DEFINE ImCos   math.cos
#IMGUI_DEFINE ImAcos  math.acos
#IMGUI_DEFINE ImSqrt  math.sqrt
#IMGUI_DEFINE ImLerp(a, b, t)       ((a) + ((b) - (a)) * (t))
#IMGUI_DEFINE ImClamp(v, min, max)  ImMin(ImMax((v), (min)), (max))
#IMGUI_DEFINE ImTrunc(f)            ImFloor((f) + 0.5)
#IMGUI_DEFINE IM_ROUNDUP_TO_EVEN(n) (ImCeil((n) / 2) * 2)
#IMGUI_DEFINE ImRsqrt(x)            (1 / ImSqrt(x))

local function ImIsPowerOfTwo(v)
    return (v ~= 0) and (bit.band(v, (v - 1)) == 0)
end

local function ImUpperPowerOfTwo(v)
    if v <= 0 then return 0 end
    if v <= 1 then return 1 end

    v = v - 1
    v = bit.bor(v, bit.rshift(v, 1))
    v = bit.bor(v, bit.rshift(v, 2))
    v = bit.bor(v, bit.rshift(v, 4))
    v = bit.bor(v, bit.rshift(v, 8))
    v = bit.bor(v, bit.rshift(v, 16))
    return v + 1
end

function ImSaturate(f) return ((f < 0.0 and 0.0) or (f > 1.0 and 1.0) or f) end

--- @return int?
function ImMemchr(str, char, start_pos)
    local start = start_pos or 1
    if start < 1 then start = 1 end

    local pos = string.find(str, char, start, true)

    return pos
end

IMGUI_FONT_SIZE_MAX                                = 512.0
IMGUI_FONT_SIZE_THRESHOLD_FOR_LOADADVANCEXONLYMODE = 128.0

#IMGUI_DEFINE IMGUI_WINDOW_HARD_MIN_SIZE 16

#IMGUI_DEFINE IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MIN 4
#IMGUI_DEFINE IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX 512

#IMGUI_DEFINE IM_DRAWLIST_ARCFAST_TABLE_SIZE 48
#IMGUI_DEFINE IM_DRAWLIST_ARCFAST_SAMPLE_MAX IM_DRAWLIST_ARCFAST_TABLE_SIZE

#IMGUI_DEFINE IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC(_RAD, _MAXERROR) ImClamp(IM_ROUNDUP_TO_EVEN(ImCeil(IM_PI / ImAcos(1 - ImMin((_MAXERROR), (_RAD)) / (_RAD)))), IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MIN, IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX)
#IMGUI_DEFINE IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_R(_N, _MAXERROR) ((_MAXERROR) / (1 - ImCos(IM_PI / ImMax(_N, IM_PI))))
#IMGUI_DEFINE IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_ERROR(_N, _RAD)  ((1 - ImCos(IM_PI / ImMax((_N), IM_PI))) / (_RAD))

function IM_ASSERT_USER_ERROR(_EXPR, _MSG) if not (_EXPR) or (_EXPR) == 0 then error(_MSG, 2) end end

#IMGUI_DEFINE struct_def(_name) MT[_name] = {} MT[_name].__index = MT[_name]

--- @param size float
function ImGui.GetRoundedFontSize(size) return ImRound(size) end

function ImCharIsBlankA(c) return c == chr' ' or c == chr '\t' end

--- @enum ImGuiNavLayer
ImGuiNavLayer = {
    Main  = 0,
    Menu  = 1,
    COUNT = 2
}

-- TODO: ImGuiItemFlagsPrivate_
ImGuiItemFlags_NoFocus = bit.lshift(1, 17)

--- @enum ImDrawTextFlags
ImDrawTextFlags = {
    None           = 0,
    CpuFineClip    = bit.lshift(1, 0),
    WrapKeepBlanks = bit.lshift(1, 1),
    StopOnNewLine  = bit.lshift(1, 2)
}

--- @enum ImWcharClass
ImWcharClass = {
    Blank = 0,
    Punct = 1,
    Other = 2
}

--- ImVec1
--
struct_def("ImVec1")

local function ImVec1(x) return setmetatable({x = x or 0}, MT.ImVec1) end

function MT.ImVec1:__tostring() return string.format("ImVec1(%g)", self.x) end
function MT.ImVec1:copy() return ImVec1(self.x) end

--- @class ImRect
MT.ImRect = {}
MT.ImRect.__index = MT.ImRect

function MT.ImRect:__tostring() return string.format("ImRect(Min: %g,%g, Max: %g,%g)", self.Min.x, self.Min.y, self.Max.x, self.Max.y) end
function MT.ImRect:contains(other) return other.Min.x >= self.Min.x and other.Max.x <= self.Max.x and other.Min.y >= self.Min.y and other.Max.y <= self.Max.y end
function MT.ImRect:contains_point(p) return p.x >= self.Min.x and p.x <= self.Max.x and p.y >= self.Min.y and p.y <= self.Max.y end
function MT.ImRect:overlaps(other) return self.Min.x <= other.Max.x and self.Max.x >= other.Min.x and self.Min.y <= other.Max.y and self.Max.y >= other.Min.y end
function MT.ImRect:GetCenter() return ImVec2((self.Min.x + self.Max.x) * 0.5, (self.Min.y + self.Max.y) * 0.5) end
function MT.ImRect:GetWidth() return self.Max.x - self.Min.x end

local function ImRect(a, b, c, d) if c and d then return setmetatable({Min = ImVec2(a, b), Max = ImVec2(c, d)}, MT.ImRect) end return setmetatable({Min = ImVec2(a and a.x or 0, a and a.y or 0), Max = ImVec2(b and b.x or 0, b and b.y or 0)}, MT.ImRect) end

function MT.ImDrawList:PathClear()
    self._Path:clear_delete() -- TODO: is clear() fine?
end

function MT.ImDrawList:PathLineTo(pos)
    self._Path:push_back(pos)
end

function MT.ImDrawList:PathLineToMergeDuplicate(pos)
    local path_size = self._Path.Size
    if path_size == 0 or self._Path.Data[path_size].x ~= pos.x or self._Path.Data[path_size].y ~= pos.y then
        self._Path:push_back(pos)
    end
end

function MT.ImDrawList:PathFillConvex(col)
    self:AddConvexPolyFilled(self._Path.Data, self._Path.Size, col)
    self._Path.Size = 0
end

function MT.ImDrawList:PathStroke(col, flags, thickness)
    self:AddPolyline(self._Path.Data, self._Path.Size, col, flags, thickness)
    self._Path.Size = 0
end

--- @class ImDrawListSharedData
struct_def("ImDrawListSharedData")

local function ImDrawListSharedData()
    local this = setmetatable({
        TexUvWhitePixel = nil,

        InitialFringeScale = 1,

        CircleSegmentMaxError = 0,

        TempBuffer = ImVector(),
        DrawLists = ImVector(),

        ArcFastVtx = {}, -- size = IM_DRAWLIST_ARCFAST_TABLE_SIZE
        ArcFastRadiusCutoff = nil,
        CircleSegmentCounts = {} -- size = 64
    }, MT.ImDrawListSharedData)

    for i = 0, IM_DRAWLIST_ARCFAST_TABLE_SIZE - 1 do
        local a = (i * 2 * IM_PI) / IM_DRAWLIST_ARCFAST_TABLE_SIZE
        this.ArcFastVtx[i] = ImVec2(ImCos(a), ImSin(a))
    end

    -- this is odd. CircleSegmentMaxError = 0 at this time resulting in ArcFastRadiusCutoff = 0
    this.ArcFastRadiusCutoff = IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_R(IM_DRAWLIST_ARCFAST_SAMPLE_MAX, this.CircleSegmentMaxError)

    return this
end

--- @class ImFontAtlasBuilder
--- @field PackContext              stbrp_context
--- @field PackNodes                ImVector<stbrp_node>
--- @field Rects                    ImVector<ImTextureRect>
--- @field RectsIndex               ImVector<ImFontAtlasRectEntry>
--- @field TempBuffer               ImSlice
--- @field RectsIndexFreeListStart  int
--- @field RectsPackedCount         int
--- @field RectsPackedSurface       int
--- @field RectsDiscardedCount      int
--- @field RectsDiscardedSurface    int
--- @field FrameCount               int
--- @field MaxRectSize              ImVec2
--- @field MaxRectBounds            ImVec2
--- @field LockDisableResize        bool
--- @field PreloadedAllGlyphsRanges bool
--- @field BakedPool                ImVector<ImFontBaked, 32>
--- @field BakedMap                 ImGuiStorage
--- @field BakedDiscardedCount      int
--- @field PackIdMouseCursors       ImFontAtlasRectId
--- @field PackIdLinesTexData       ImFontAtlasRectId
MT.ImFontAtlasBuilder = {}
MT.ImFontAtlasBuilder.__index = MT.ImFontAtlasBuilder

--- @return ImFontAtlasBuilder
function ImFontAtlasBuilder()
    --- @type ImFontAtlasBuilder
    local this = setmetatable({}, MT.ImFontAtlasBuilder)

    this.PackContext              = stbrp.context() -- struct stbrp_context_opaque { char data[80]; };
    this.PackNodes                = ImVector()
    this.Rects                    = ImVector()
    this.RectsIndex               = ImVector()
    this.TempBuffer               = IM_SLICE() -- ImVector()
    this.RectsIndexFreeListStart  = 0
    this.RectsPackedCount         = 0
    this.RectsPackedSurface       = 0
    this.RectsDiscardedCount      = 0
    this.RectsDiscardedSurface    = 0
    this.FrameCount               = 0
    this.MaxRectSize              = ImVec2()
    this.MaxRectBounds            = ImVec2()
    this.LockDisableResize        = false
    this.PreloadedAllGlyphsRanges = false

    this.BakedPool           = ImVector() -- ImStableVector<ImFontBaked,32>
    this.BakedMap            = ImGuiStorage()
    this.BakedDiscardedCount = 0

    this.PackIdMouseCursors = -1
    this.PackIdLinesTexData = -1

    return this
end

--- @class ImFontStackData
--- @field Font ImFont
--- @field FontSizeBeforeScaling float
--- @field FontSizeAfterScaling float

--- @return ImFontStackData
--- @param font ImFont
--- @param font_size_before_scaling float
--- @param font_size_after_scaling float
function ImFontStackData(font, font_size_before_scaling, font_size_after_scaling)
    return {
        Font                  = font,
        FontSizeBeforeScaling = font_size_before_scaling,
        FontSizeAfterScaling  = font_size_after_scaling
    }
end

--- @class ImGuiStyle

--- @return ImGuiStyle
--- @nodiscard
function ImGuiStyle()
    --- @type ImGuiStyle
    local this = {
        FontSizeBase  = 0.0,
        FontScaleMain = 1.0,
        FontScaleDpi  = 1.0,

        Alpha = 1.0,

        FramePadding = ImVec2(4, 3),

        WindowRounding = 0,
        WindowBorderSize = 1,

        Colors = {},

        WindowMinSize = ImVec2(64, 64),
        WindowTitleAlign = ImVec2(0.0,0.5),
        WindowMenuButtonPosition = ImGuiDir.Left,

        FrameBorderSize = 1,
        ItemSpacing = ImVec2(8, 4),
        ItemInnerSpacing = ImVec2(4, 4),

        CircleTessellationMaxError = 0.30,

        _NextFrameFontSizeBase = 0.0
    }

    ImGui.StyleColorsDark(this)

    return this
end

--- @class ImGuiContext

--- @param shared_font_atlas? ImFontAtlas
--- @return ImGuiContext
--- @nodiscard
function ImGuiContext(shared_font_atlas) -- TODO: tidy up this structure
    local this = {
        Style = ImGuiStyle(),

        Config = nil,
        Initialized = false,

        Windows = ImVector(), -- Windows sorted in display order, back to front
        WindowsByID = {}, -- Map window's ID to window ref

        WindowsBorderHoverPadding = 0,

        CurrentWindowStack = ImVector(),
        CurrentWindow = nil,

        IO = { -- TODO: make IO independent?
            BackendFlags = 0,

            MousePos = ImVec2(),
            IsMouseDown = input.IsMouseDown,

            --- Just support 2 buttons now, L & R
            MouseDown             = {false, false},
            MouseClicked          = {false, false},
            MouseReleased         = {false, false},
            MouseDownDuration     = {-1, -1},
            MouseDownDurationPrev = {-1, -1},

            MouseDownOwned = {nil, nil},

            MouseClickedTime = {nil, nil},
            MouseReleasedTime = {nil, nil},

            MouseClickedPos = {ImVec2(), ImVec2()},

            WantCaptureMouse = nil,
            -- WantCaptureKeyboard = nil,
            -- WantTextInput = nil,

            DeltaTime = 1 / 60,
            Framerate = 0,

            MetricsRenderWindows = 0,

            Fonts = ImFontAtlas()
        },

        MovingWindow = nil,
        ActiveIDClickOffset = ImVec2(),

        HoveredWindow = nil,

        ActiveID = 0, -- Active widget
        ActiveIDWindow = nil, -- Active window

        ActiveIDIsJustActivated = false,

        ActiveIDIsAlive = nil,

        ActiveIDPreviousFrame = 0,

        DeactivatedItemData = {
            ID = 0,
            ElapseFrame = 0,
            HasBeenEditedBefore = false,
            IsAlive = false
        },

        HoveredID = 0,

        NavWindow = nil,

        FrameCount = -1,

        FrameCountEnded = -1,
        FrameCountRendered = -1,

        Time = 0,

        NextItemData = {

        },

        LastItemData = {
            ID = 0,
            ItemFlags = 0,
            StatusFlags = 0,

            Rect        = ImRect(),
            NavRect     = ImRect(),
            DisplayRect = ImRect(),
            ClipRect    = ImRect()
            -- Shortcut = 
        },

        Viewports = ImVector(),

        Font = nil, -- Currently bound *FontName* to be used with surface.SetFont
        FontSize = 18,
        FontSizeBase = 18,

        FontRasterizerDensity = 1.0,

        FontAtlases = ImVector(),

        --- Contains ImFontStackData
        FontStack = ImVector(),

        DrawListSharedData = ImDrawListSharedData(),

        -- StackSizesInBeginForCurrentWindow = nil,

        --- Misc
        FramerateSecPerFrame = {}, -- size = 60
        FramerateSecPerFrameIdx = 0,
        FramerateSecPerFrameCount = 0,
        FramerateSecPerFrameAccum = 0,

        WantCaptureMouseNextFrame = -1,
        -- WantCaptureKeyboardNextFrame = -1,
        -- WantTextInputNextFrame = -1

        MouseCursor = "arrow",

        CurrentItemFlags = ImGuiItemFlags_None
    }

    if shared_font_atlas == nil then
        this.IO.Fonts.OwnerContext = this
    end

    return this
end

--- @class ImGuiWindow
struct_def("ImGuiWindow")

function MT.ImGuiWindow:TitleBarRect()
    return ImRect(self.Pos, ImVec2(self.Pos.x + self.SizeFull.x, self.Pos.y + self.TitleBarHeight))
end

--- @return ImGuiWindow
--- @nodiscard
local function ImGuiWindow(ctx, name)
    local this = {
        ID = 0,

        MoveID = 0,

        Ctx = ctx,
        Name = name,

        Flags = 0,

        Pos = nil,
        Size = nil, -- Current size (==SizeFull or collapsed title bar size)
        SizeFull = nil,

        TitleBarHeight = 0,

        Active = false,
        WasActive = false,

        Collapsed = false,

        SkipItems = false,

        SkipRefresh = false,

        Hidden = false,

        HiddenFramesCanSkipItems = 0,
        HiddenFramesCannotSkipItems = 0,
        HiddenFramesForRenderOnly = 0,

        WindowRounding = 0,
        WindowBorderSize = 1,

        HasCloseButton = true,

        ScrollbarX = false,
        ScrollbarY = false,

        DrawList = ImDrawList(),

        IDStack = ImVector(),

        Viewport = nil,

        --- struct IMGUI_API ImGuiWindowTempData
        DC = {
            CursorPos         = ImVec2(),
            CursorPosPrevLine = ImVec2(),
            CursorStartPos    = ImVec2(),
            CursorMaxPos      = ImVec2(),
            IdealMaxPos       = ImVec2(),
            CurrLineSize      = ImVec2(),
            PrevLineSize      = ImVec2(),

            CurrLineTextBaseOffset = 0,
            PrevLineTextBaseOffset = 0,

            IsSameLine = false,
            IsSetPos = false,

            Indent                  = ImVec1(),
            ColumnsOffset           = ImVec1(),
            GroupOffset             = ImVec1(),
            CursorStartPosLossyness = ImVec1(),

            TextWrapPos = 0
        },

        ClipRect = ImRect(),

        LastFrameActive = -1
    }

    this.DrawList:_SetDrawListSharedData(ctx.DrawListSharedData)

    return setmetatable(this, MT.ImGuiWindow)
end

--- @class ImGuiViewport
struct_def("ImGuiViewport")

function MT.ImGuiViewport:GetCenter()
    return ImVec2(self.Pos.x + self.Size.x * 0.5, self.Pos.y + self.Size.y * 0.5)
end

function MT.ImGuiViewport:GetWorkCenter()
    return ImVec2(self.WorkPos.x + self.WorkSize.x * 0.5, self.WorkPos.y + self.WorkSize.y * 0.5)
end

--- @return ImGuiViewport
--- @nodiscard
local function ImGuiViewport()
    return setmetatable({
        ID = 0,
        Flags = 0,
        Pos = ImVec2(),
        Size = ImVec2(),
        WorkPos = ImVec2(),
        WorkSize = ImVec2(),

        PlatformHandle = nil,
        PlatformHandleRaw = nil
    }, MT.ImGuiViewport)
end

--- @class ImDrawDataBuilder
struct_def("ImDrawDataBuilder")

--- @return ImDrawDataBuilder
--- @nodiscard
local function ImDrawDataBuilder()
    return setmetatable({
        Layers = {nil, nil},
        LayerData1 = ImVector()
    }, MT.ImDrawDataBuilder)
end

--- @class ImGuiViewportP : ImGuiViewport
struct_def("ImGuiViewportP")

setmetatable(MT.ImGuiViewportP, {__index = MT.ImGuiViewport})

function MT.ImGuiViewportP:CalcWorkRectPos(inset_min)
    return ImVec2(self.Pos.x + inset_min.x, self.Pos.y + inset_min.y)
end

function MT.ImGuiViewportP:CalcWorkRectSize(inset_min, inset_max)
    return ImVec2(ImMax(0.0, self.Size.x - inset_min.x - inset_max.x), ImMax(0.0, self.Size.y - inset_min.y - inset_max.y))
end

function MT.ImGuiViewportP:UpdateWorkRect()
    self.WorkPos = self:CalcWorkRectPos(self.WorkInsetMin)
    self.WorkSize = self:CalcWorkRectSize(self.WorkInsetMin, self.WorkInsetMax)
end

function MT.ImGuiViewportP:GetMainRect()
    return ImRect(self.Pos.x, self.Pos.y,
        self.Pos.x + self.Size.x,
        self.Pos.y + self.Size.y)
end

function MT.ImGuiViewportP:GetWorkRect()
    return ImRect(self.WorkPos.x, self.WorkPos.y,
        self.WorkPos.x + self.WorkSize.x,
        self.WorkPos.y + self.WorkSize.y)
end

function MT.ImGuiViewportP:GetBuildWorkRect()
    local pos = self:CalcWorkRectPos(self.BuildWorkInsetMin)
    local size = self:CalcWorkRectSize(self.BuildWorkInsetMin, self.BuildWorkInsetMax)
    return ImRect(pos.x, pos.y, pos.x + size.x, pos.y + size.y)
end

--- @return ImGuiViewportP
--- @nodiscard
local function ImGuiViewportP()

    local this = setmetatable(ImGuiViewport(), MT.ImGuiViewportP)
    --- @cast this ImGuiViewportP

    this.BgFgDrawListsLastFrame = {-1, -1}
    this.BgFgDrawLists = {nil, nil}
    this.DrawDataP = ImDrawData()
    this.DrawDataBuilder = ImDrawDataBuilder()

    this.WorkInsetMin = ImVec2(0, 0)
    this.WorkInsetMax = ImVec2(0, 0)
    this.BuildWorkInsetMin = ImVec2(0, 0)
    this.BuildWorkInsetMax = ImVec2(0, 0)

    return this
end

--- @class ImFontLoader
--- @field Name                       string
--- @field LoaderInit?                function(atlas: ImFontAtlas): bool
--- @field LoaderShutdown?            function(atlas: ImFontAtlas)
--- @field FontSrcInit?               function(atlas: ImFontAtlas, src: ImFontConfig): bool
--- @field FontSrcDestroy?            function(atlas: ImFontAtlas, src: ImFontConfig)
--- @field FontSrcContainsGlyph?      function(atlas: ImFontAtlas, src: ImFontConfig, codepoint: ImWchar): bool
--- @field FontBakedInit?             function(atlas: ImFontAtlas, src: ImFontConfig, baked: ImFontBaked, loader_data_for_baked_src?: any): bool
--- @field FontBakedDestroy?          function(atlas: ImFontAtlas, src: ImFontConfig, baked: ImFontBaked, loader_data_for_baked_src?: any)
--- @field FontBakedLoadGlyph         function(atlas: ImFontAtlas, src: ImFontConfig, baked: ImFontBaked, loader_data_for_baked_src?: any, codepoint: ImWchar, out_glyph: ImFontGlyph, out_advance_x: float_ptr): bool
--- @field FontBakedSrcLoaderDataSize unsigned_int
MT.ImFontLoader = {}
MT.ImFontLoader.__index = MT.ImFontLoader

--- @return ImFontLoader
--- @nodiscard
local function ImFontLoader()
    --- @type ImFontLoader
    local this = setmetatable({}, MT.ImFontLoader)

    this.Name                 = nil
    this.LoaderInit           = nil
    this.LoaderShutdown       = nil
    this.FontSrcInit          = nil
    this.FontSrcDestroy       = nil
    this.FontSrcContainsGlyph = nil
    this.FontBakedInit        = nil
    this.FontBakedDestroy     = nil
    this.FontBakedLoadGlyph   = nil

    this.FontBakedSrcLoaderDataSize = 0

    return this
end

--- @class ImFontAtlasRectEntry

--- @return ImFontAtlasRectEntry
--- @nodiscard
function ImFontAtlasRectEntry()
    return {
        TargetIndex = 0,
        Generation  = 0,
        IsUsed      = false
    }
end

local ImFontAtlasRectId_IndexMask_       = 0x0007FFFF
local ImFontAtlasRectId_GenerationMask_  = 0x3FF00000
local ImFontAtlasRectId_GenerationShift_ = 20

--- @param id ImFontAtlasRectId
--- @return int
function ImFontAtlasRectId_GetIndex(id) return bit.band(id, ImFontAtlasRectId_IndexMask_) end

--- @param id ImFontAtlasRectId
--- @return unsigned_int
function ImFontAtlasRectId_GetGeneration(id) return bit.rshift(bit.band(id, ImFontAtlasRectId_GenerationMask_), ImFontAtlasRectId_GenerationShift_) end

--- @param index_idx int
--- @param gen_idx int
--- @return ImFontAtlasRectId
function ImFontAtlasRectId_Make(index_idx, gen_idx)
    IM_ASSERT(index_idx >= 0 and index_idx <= ImFontAtlasRectId_IndexMask_ and gen_idx <= bit.rshift(ImFontAtlasRectId_GenerationMask_, ImFontAtlasRectId_GenerationShift_))
    return bit.bor(index_idx, bit.lshift(gen_idx, ImFontAtlasRectId_GenerationShift_))
end