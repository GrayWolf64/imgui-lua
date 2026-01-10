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

#IMGUI_DEFINE FLT_MAX math.huge
#IMGUI_DEFINE IM_PI   math.pi
#IMGUI_DEFINE ImAbs   math.abs
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

local function ImSaturate(f)
    return (f < 0.0 and 0.0) or (f > 1.0 and 1.0) or f
end

local function IM_ASSERT(_EXPR) end -- TODO: preprocess

#IMGUI_DEFINE IMGUI_FONT_SIZE_MAX 512

#IMGUI_DEFINE IMGUI_WINDOW_HARD_MIN_SIZE 16

#IMGUI_DEFINE IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MIN 4
#IMGUI_DEFINE IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX 512

#IMGUI_DEFINE IM_DRAWLIST_ARCFAST_TABLE_SIZE 48
#IMGUI_DEFINE IM_DRAWLIST_ARCFAST_SAMPLE_MAX IM_DRAWLIST_ARCFAST_TABLE_SIZE

#IMGUI_DEFINE IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC(_RAD, _MAXERROR) ImClamp(IM_ROUNDUP_TO_EVEN(ImCeil(IM_PI / ImAcos(1 - ImMin((_MAXERROR), (_RAD)) / (_RAD)))), IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MIN, IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX)
#IMGUI_DEFINE IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_R(_N, _MAXERROR)   ((_MAXERROR) / (1 - ImCos(IM_PI / ImMax(_N, IM_PI))))
#IMGUI_DEFINE IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_ERROR(_N, _RAD)    ((1 - ImCos(IM_PI / ImMax((_N), IM_PI))) / (_RAD))

#IMGUI_DEFINE IM_ASSERT_USER_ERROR(_EXPR, _MSG) if not (_EXPR) or (_EXPR) == 0 then error(_MSG, 2) end

--- ImVec1
--
struct_def("ImVec1")

local function ImVec1(x) return setmetatable({x = x or 0}, GMetaTables.ImVec1) end

struct_method ImVec1:__tostring() return string.format("ImVec1(%g)", self.x) end
struct_method ImVec1:copy() return ImVec1(self.x) end

--- struct IMGUI_API ImRect
struct_def("ImRect")

struct_method ImRect:__tostring() return string.format("ImRect(Min: %g,%g, Max: %g,%g)", self.Min.x, self.Min.y, self.Max.x, self.Max.y) end
struct_method ImRect:contains(other) return other.Min.x >= self.Min.x and other.Max.x <= self.Max.x and other.Min.y >= self.Min.y and other.Max.y <= self.Max.y end
struct_method ImRect:contains_point(p) return p.x >= self.Min.x and p.x <= self.Max.x and p.y >= self.Min.y and p.y <= self.Max.y end
struct_method ImRect:overlaps(other) return self.Min.x <= other.Max.x and self.Max.x >= other.Min.x and self.Min.y <= other.Max.y and self.Max.y >= other.Min.y end
struct_method ImRect:GetCenter() return ImVec2((self.Min.x + self.Max.x) * 0.5, (self.Min.y + self.Max.y) * 0.5) end

local function ImRect(a, b, c, d) if c and d then return setmetatable({Min = ImVec2(a, b), Max = ImVec2(c, d)}, GMetaTables.ImRect) end return setmetatable({Min = ImVec2(a and a.x or 0, a and a.y or 0), Max = ImVec2(b and b.x or 0, b and b.y or 0)}, GMetaTables.ImRect) end

struct_method ImDrawList:PathClear()
    self._Path:clear_delete() -- TODO: is clear() fine?
end

struct_method ImDrawList:PathLineTo(pos)
    self._Path:push_back(pos)
end

struct_method ImDrawList:PathLineToMergeDuplicate(pos)
    local path_size = self._Path.Size
    if path_size == 0 or self._Path.Data[path_size].x ~= pos.x or self._Path.Data[path_size].y ~= pos.y then
        self._Path:push_back(pos)
    end
end

struct_method ImDrawList:PathFillConvex(col)
    self:AddConvexPolyFilled(self._Path.Data, self._Path.Size, col)
    self._Path.Size = 0
end

struct_method ImDrawList:PathStroke(col, flags, thickness)
    self:AddPolyline(self._Path.Data, self._Path.Size, col, flags, thickness)
    self._Path.Size = 0
end

--- struct IMGUI_API ImDrawListSharedData
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
    }, GMetaTables.ImDrawListSharedData)

    for i = 0, IM_DRAWLIST_ARCFAST_TABLE_SIZE - 1 do
        local a = (i * 2 * IM_PI) / IM_DRAWLIST_ARCFAST_TABLE_SIZE
        this.ArcFastVtx[i] = ImVec2(ImCos(a), ImSin(a))
    end

    -- this is odd. CircleSegmentMaxError = 0 at this time resulting in ArcFastRadiusCutoff = 0
    this.ArcFastRadiusCutoff = IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_R(IM_DRAWLIST_ARCFAST_SAMPLE_MAX, this.CircleSegmentMaxError)

    return this
end

--- struct ImFontAtlasBuilder
--
struct_def("ImFontAtlasBuilder")

local function ImFontAtlasBuilder()
    local this = setmetatable({
        PackContext              = stbrp.context(), -- struct stbrp_context_opaque { char data[80]; };
        PackNodes                = ImVector(),
        Rects                    = ImVector(),
        RectsIndex               = ImVector(),
        TempBuffer               = {data = {}, offset = 0}, -- ImVector()
        RectsIndexFreeListStart  = nil,
        RectsPackedCount         = nil,
        RectsPackedSurface       = nil,
        RectsDiscardedCount      = nil,
        RectsDiscardedSurface    = nil,
        FrameCount               = nil,
        MaxRectSize              = nil,
        MaxRectBounds            = nil,
        LockDisableResize        = nil,
        PreloadedAllGlyphsRanges = nil,

        BakedPool           = ImVector(), -- ImStableVector<ImFontBaked,32>
        BakedMap            = nil,
        BakedDiscardedCount = nil,

        PackIDMouseCursors = nil,
        PackIDLinesTexData = nil
    }, GMetaTables.ImFontAtlasBuilder)

    this.FrameCount = 0
    this.RectsIndexFreeListStart = 0

    this.PackIdLinesTexData = -1
    this.PackIdMouseCursors = -1

    return this
end

--- struct ImGuiContext
local function ImGuiContext()
    local this = {
        Style = { -- TODO: ImGuiStyle
            FramePadding = ImVec2(4, 3),

            WindowRounding = 0,
            WindowBorderSize = 1,

            Colors = {},
            Alpha = 1.0,

            FontSizeBase = 18,
            FontScaleMain = 1,

            WindowMinSize = ImVec2(60, 60),

            FrameBorderSize = 1,
            ItemSpacing = ImVec2(8, 4),

            CircleTessellationMaxError = 0.30
        },

        Config = nil,
        Initialized = true,

        Windows = ImVector(), -- Windows sorted in display order, back to front
        WindowsByID = {}, -- Map window's ID to window ref

        WindowsBorderHoverPadding = 0,

        CurrentWindowStack = ImVector(),
        CurrentWindow = nil,

        IO = { -- TODO: make IO independent?
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

        FrameCount = 0,

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

        MouseCursor = "arrow"
    }

    return this
end

struct_def("ImGuiWindow")

struct_method ImGuiWindow:TitleBarRect()
    return ImRect(self.Pos, ImVec2(self.Pos.x + self.SizeFull.x, self.Pos.y + self.TitleBarHeight))
end

--- struct IMGUI_API ImGuiWindow
-- TODO: make this a struct
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

    return setmetatable(this, GMetaTables.ImGuiWindow)
end

--- struct ImGuiViewport
-- imgui.h
struct_def("ImGuiViewport")

struct_method ImGuiViewport:GetCenter()
    return ImVec2(self.Pos.x + self.Size.x * 0.5, self.Pos.y + self.Size.y * 0.5)
end

struct_method ImGuiViewport:GetWorkCenter()
    return ImVec2(self.WorkPos.x + self.WorkSize.x * 0.5, self.WorkPos.y + self.WorkSize.y * 0.5)
end

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
    }, GMetaTables.ImGuiViewport)
end

--- struct ImDrawDataBuilder
--
struct_def("ImDrawDataBuilder")

local function ImDrawDataBuilder()
    return setmetatable({
        Layers = {nil, nil},
        LayerData1 = ImVector()
    }, GMetaTables.ImDrawDataBuilder)
end

--- struct ImGuiViewportP : public ImGuiViewport
struct_def("ImGuiViewportP")

setmetatable(GMetaTables.ImGuiViewportP, {__index = GMetaTables.ImGuiViewport})

struct_method ImGuiViewportP:CalcWorkRectPos(inset_min)
    return ImVec2(self.Pos.x + inset_min.x, self.Pos.y + inset_min.y)
end

struct_method ImGuiViewportP:CalcWorkRectSize(inset_min, inset_max)
    return ImVec2(ImMax(0.0, self.Size.x - inset_min.x - inset_max.x), ImMax(0.0, self.Size.y - inset_min.y - inset_max.y))
end

struct_method ImGuiViewportP:UpdateWorkRect()
    self.WorkPos = self:CalcWorkRectPos(self.WorkInsetMin)
    self.WorkSize = self:CalcWorkRectSize(self.WorkInsetMin, self.WorkInsetMax)
end

struct_method ImGuiViewportP:GetMainRect()
    return ImRect(self.Pos.x, self.Pos.y,
        self.Pos.x + self.Size.x,
        self.Pos.y + self.Size.y)
end

struct_method ImGuiViewportP:GetWorkRect()
    return ImRect(self.WorkPos.x, self.WorkPos.y,
        self.WorkPos.x + self.WorkSize.x,
        self.WorkPos.y + self.WorkSize.y)
end

struct_method ImGuiViewportP:GetBuildWorkRect()
    local pos = self:CalcWorkRectPos(self.BuildWorkInsetMin)
    local size = self:CalcWorkRectSize(self.BuildWorkInsetMin, self.BuildWorkInsetMax)
    return ImRect(pos.x, pos.y, pos.x + size.x, pos.y + size.y)
end

local function ImGuiViewportP()
    local this = setmetatable(ImGuiViewport(), GMetaTables.ImGuiViewportP)

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

struct_def("ImFontLoader")

local function ImFontLoader()
    return setmetatable({
        Name                 = nil,
        LoaderInit           = nil,
        LoaderShutdown       = nil,
        FontSrcInit          = nil,
        FontSrcDestroy       = nil,
        FontSrcContainsGlyph = nil,
        FontBakedInit        = nil,
        FontBakedDestroy     = nil,
        FontBakedLoadGlyph   = nil,

        FontBakedSrcLoaderDataSize = nil
    }, GMetaTables.ImFontLoader)
end

local function ImFontAtlasRectEntry()
    return {
        TargetIndex = 0,
        Generation  = 0,
        IsUsed      = false
    }
end

#IMGUI_DEFINE ImFontAtlasRectId_IndexMask_       (0x0007FFFF)
#IMGUI_DEFINE ImFontAtlasRectId_GenerationMask_  (0x3FF00000)
#IMGUI_DEFINE ImFontAtlasRectId_GenerationShift_ (20)
local function ImFontAtlasRectId_GetIndex(id) return bit.band(id, ImFontAtlasRectId_IndexMask_) end
local function ImFontAtlasRectId_GetGeneration(id) return bit.rshift(bit.band(id, ImFontAtlasRectId_GenerationMask_), ImFontAtlasRectId_GenerationShift_) end
local function ImFontAtlasRectId_Make(index_idx, gen_idx)
    IM_ASSERT(index_idx >= 0 and index_idx <= ImFontAtlasRectId_IndexMask_ and gen_idx <= bit.rshift(ImFontAtlasRectId_GenerationMask_, ImFontAtlasRectId_GenerationShift_))
    return bit.bor(index_idx, bit.lshift(gen_idx, ImFontAtlasRectId_GenerationShift_))
end