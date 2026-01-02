--- Some internal structures
-- I won't implement type checks, since I ensure that types are correct in internal usage,
-- and runtime type checking is very slow
local insert_at    = table.insert
local remove_at    = table.remove
local setmetatable = setmetatable
local isnumber     = isnumber
local IsValid      = IsValid
local str_byte     = string.byte
local str_format   = string.format

local pairs  = pairs
local ipairs = ipairs
local assert = assert

local ScrW = ScrW
local ScrH = ScrH

local SysTime = SysTime

local GetMouseX = gui.MouseX
local GetMouseY = gui.MouseY

local surface = surface
local render  = render
local draw    = draw
local bit     = bit

local FLT_MAX = math.huge
local IM_PI = math.pi
local ImAbs = math.abs
local ImMin = math.min
local ImMax = math.max
local ImFloor = math.floor
local ImRound = math.Round
local ImCeil = math.ceil
local ImSin = math.sin
local ImCos = math.cos
local ImAcos = math.acos
local ImSqrt = math.sqrt
local function ImLerp(a, b, t) return a + (b - a) * t end
local function ImClamp(v, min, max) return ImMin(ImMax(v, min), max) end
local function ImTrunc(f) return ImFloor(f + 0.5) end
local function IM_ROUNDUP_TO_EVEN(n) return ImCeil(n / 2) * 2 end
local function ImRsqrt(x) return 1 / ImSqrt(x) end

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
    if f < 0.0 then return 0.0
    elseif f > 1.0 then return 1.0
    else return f end
end

local function IM_ASSERT(_EXPR) end -- TODO: preprocess

local IMGUI_FONT_SIZE_MAX = 512

local IMGUI_WINDOW_HARD_MIN_SIZE = 16 -- 4

local IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MIN = 4
local IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX = 512

local IM_DRAWLIST_ARCFAST_TABLE_SIZE = 48
local IM_DRAWLIST_ARCFAST_SAMPLE_MAX = 48

local IMGUI_VIEWPORT_DEFAULT_ID = 0x11111111

local function IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC(_RAD, _MAXERROR) return ImClamp(IM_ROUNDUP_TO_EVEN(ImCeil(IM_PI / ImAcos(1 - ImMin(_MAXERROR, _RAD) / _RAD))), IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MIN, IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX) end
local function IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_R(N, MAXERROR) return MAXERROR / (1 - ImCos(IM_PI / ImMax(N, IM_PI))) end
local function IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_ERROR(N, RAD) return (1 - ImCos(IM_PI / ImMax(N, IM_PI))) / RAD end

--- struct ImVec4
--
Metatables.ImVec4 = {}
Metatables.ImVec4.__index = Metatables.ImVec4

local function ImVec4(x, y, z, w) return setmetatable({x = x or 0, y = y or 0, z = z or 0, w = w or 0}, Metatables.ImVec4) end

function Metatables.ImVec4:__add(other) return ImVec4(self.x + other.x, self.y + other.y, self.z + other.z, self.w + other.w) end
function Metatables.ImVec4:__sub(other) return ImVec4(self.x - other.x, self.y - other.y, self.z - other.z, self.w - other.w) end
function Metatables.ImVec4:__mul(other) if isnumber(self) then return ImVec4(self * other.x, self * other.y, self * other.z, self * other.w) elseif isnumber(other) then return ImVec4(self.x * other, self.y * other, self.z * other, self.w * other) else return ImVec4(self.x * other.x, self.y * other.y, self.z * other.z, self.w * other.w) end end
function Metatables.ImVec4:__eq(other) return self.x == other.x and self.y == other.y and self.z == other.z and self.w == other.w end

--- ImVec1
--
Metatables.ImVec1 = {}
Metatables.ImVec1.__index = Metatables.ImVec1

local function ImVec1(x) return setmetatable({x = x or 0}, Metatables.ImVec1) end

function Metatables.ImVec1:__tostring() return str_format("ImVec1(%g)", self.x) end
function Metatables.ImVec1:copy() return ImVec1(self.x) end

--- struct IMGUI_API ImRect
Metatables.ImRect = {}
Metatables.ImRect.__index = Metatables.ImRect

function Metatables.ImRect:__tostring() return str_format("ImRect(Min: %g,%g, Max: %g,%g)", self.Min.x, self.Min.y, self.Max.x, self.Max.y) end
function Metatables.ImRect:contains(other) return other.Min.x >= self.Min.x and other.Max.x <= self.Max.x and other.Min.y >= self.Min.y and other.Max.y <= self.Max.y end
function Metatables.ImRect:contains_point(p) return p.x >= self.Min.x and p.x <= self.Max.x and p.y >= self.Min.y and p.y <= self.Max.y end
function Metatables.ImRect:overlaps(other) return self.Min.x <= other.Max.x and self.Max.x >= other.Min.x and self.Min.y <= other.Max.y and self.Max.y >= other.Min.y end
function Metatables.ImRect:GetCenter() return ImVec2((self.Min.x + self.Max.x) * 0.5, (self.Min.y + self.Max.y) * 0.5) end

local function ImRect(a, b, c, d) if c and d then return setmetatable({Min = ImVec2(a, b), Max = ImVec2(c, d)}, Metatables.ImRect) end return setmetatable({Min = ImVec2(a and a.x or 0, a and a.y or 0), Max = ImVec2(b and b.x or 0, b and b.y or 0)}, Metatables.ImRect) end

--- struct ImDrawCmd
--
Metatables.ImDrawCmd = {}
Metatables.ImDrawCmd.__index = Metatables.ImDrawCmd

local function ImDrawCmd()
    return setmetatable({
        ClipRect = ImVec4(),
        VtxOffset = 0,
        IdxOffset = 0,
        ElemCount = 0
    }, Metatables.ImDrawCmd) -- TODO: callback
end

--- struct ImDrawVert
-- imgui.h
Metatables.ImDrawVert = {}
Metatables.ImDrawVert.__index = Metatables.ImDrawVert

local function ImDrawVert()
    return setmetatable({
        pos = ImVec2(),
        uv  = nil,
        col = nil
    }, Metatables.ImDrawVert)
end

--- struct ImDrawCmdHeader
--
Metatables.ImDrawCmdHeader = {}
Metatables.ImDrawCmdHeader.__index = Metatables.ImDrawCmdHeader

local function ImDrawCmdHeader()
    return setmetatable({
        ClipRect = ImVec4(),
        VtxOffset = 0
    }, Metatables.ImDrawCmdHeader)
end

--- struct ImDrawList
-- imgui.h
Metatables.ImDrawList = {}
Metatables.ImDrawList.__index = Metatables.ImDrawList

function Metatables.ImDrawList:PathClear()
    self._Path:clear_delete() -- TODO: is clear() fine?
end

function Metatables.ImDrawList:PathLineTo(pos)
    self._Path:push_back(pos)
end

function Metatables.ImDrawList:PathLineToMergeDuplicate(pos)
    local path_size = self._Path.Size
    if path_size == 0 or self._Path.Data[path_size].x ~= pos.x or self._Path.Data[path_size].y ~= pos.y then
        self._Path:push_back(pos)
    end
end

function Metatables.ImDrawList:PathFillConvex(col)
    self:AddConvexPolyFilled(self._Path.Data, self._Path.Size, col)
    self._Path.Size = 0
end

function Metatables.ImDrawList:PathStroke(col, flags, thickness)
    self:AddPolyline(self._Path.Data, self._Path.Size, col, flags, thickness)
    self._Path.Size = 0
end

local function ImDrawList(data)
    return setmetatable({
        CmdBuffer = ImVector(),
        IdxBuffer = ImVector(),
        VtxBuffer = ImVector(),
        Flags = 0,

        _VtxCurrentIdx = 1, -- TODO: validate
        _Data = data, -- ImDrawListSharedData*, Pointer to shared draw data (you can use ImGui:GetDrawListSharedData() to get the one from current ImGui context)
        _VtxWritePtr = 1,
        _IdxWritePtr = 1,
        _Path = ImVector(),
        _CmdHeader = ImDrawCmdHeader(),
        _ClipRectStack = ImVector(),

        _FringeScale = 0
    }, Metatables.ImDrawList)
end

--- struct ImDrawData
-- imgui.h
Metatables.ImDrawData = {}
Metatables.ImDrawData.__index = Metatables.ImDrawData

local function ImDrawData()
    return setmetatable({
        Valid = false,
        CmdListsCount = 0,
        TotalIdxCount = 0,
        TotalVtxCount = 0,
        CmdLists = ImVector(),
        DisplayPos = ImVec2(),
        DisplaySize = ImVec2()
    }, Metatables.ImDrawData)
end

--- struct IMGUI_API ImDrawListSharedData
-- imgui_internal.h
Metatables.ImDrawListSharedData = {}
Metatables.ImDrawListSharedData.__index = Metatables.ImDrawListSharedData

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
    }, Metatables.ImDrawListSharedData)

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
Metatables.ImFontAtlasBuilder = {}
Metatables.ImFontAtlasBuilder.__index = Metatables.ImFontAtlasBuilder

local function ImFontAtlasBuilder()
    return setmetatable({
        PackContext              = nil,
        PackNodes                = nil,
        Rects                    = nil,
        RectsIndex               = nil,
        TempBuffer               = nil,
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

        BakedPool           = nil,
        BakedMap            = nil,
        BakedDiscardedCount = nil,

        PackIDMouseCursors = nil,
        PackIDLinesTexData = nil
    }, Metatables.ImFontAtlasBuilder)
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

    return this
end

--- struct ImGuiViewport
-- imgui.h
Metatables.ImGuiViewport = {}
Metatables.ImGuiViewport.__index = Metatables.ImGuiViewport

function Metatables.ImGuiViewport:GetCenter()
    return ImVec2(self.Pos.x + self.Size.x * 0.5, self.Pos.y + self.Size.y * 0.5)
end

function Metatables.ImGuiViewport:GetWorkCenter()
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
    }, Metatables.ImGuiViewport)
end

--- struct ImDrawDataBuilder
--
Metatables.ImDrawDataBuilder = {}
Metatables.ImDrawDataBuilder.__index = Metatables.ImDrawDataBuilder

local function ImDrawDataBuilder()
    return setmetatable({
        Layers = {nil, nil},
        LayerData1 = ImVector()
    }, Metatables.ImDrawDataBuilder)
end

--- struct ImGuiViewportP : public ImGuiViewport
-- imgui_internal.h
Metatables.ImGuiViewportP = {}
Metatables.ImGuiViewportP.__index = Metatables.ImGuiViewportP
setmetatable(Metatables.ImGuiViewportP, {__index = Metatables.ImGuiViewport})

function Metatables.ImGuiViewportP:CalcWorkRectPos(inset_min)
    return ImVec2(self.Pos.x + inset_min.x, self.Pos.y + inset_min.y)
end

function Metatables.ImGuiViewportP:CalcWorkRectSize(inset_min, inset_max)
    return ImVec2(ImMax(0.0, self.Size.x - inset_min.x - inset_max.x), ImMax(0.0, self.Size.y - inset_min.y - inset_max.y))
end

function Metatables.ImGuiViewportP:UpdateWorkRect()
    self.WorkPos = self:CalcWorkRectPos(self.WorkInsetMin)
    self.WorkSize = self:CalcWorkRectSize(self.WorkInsetMin, self.WorkInsetMax)
end

function Metatables.ImGuiViewportP:GetMainRect()
    return ImRect(self.Pos.x, self.Pos.y,
        self.Pos.x + self.Size.x,
        self.Pos.y + self.Size.y)
end

function Metatables.ImGuiViewportP:GetWorkRect()
    return ImRect(self.WorkPos.x, self.WorkPos.y,
        self.WorkPos.x + self.WorkSize.x,
        self.WorkPos.y + self.WorkSize.y)
end

function Metatables.ImGuiViewportP:GetBuildWorkRect()
    local pos = self:CalcWorkRectPos(self.BuildWorkInsetMin)
    local size = self:CalcWorkRectSize(self.BuildWorkInsetMin, self.BuildWorkInsetMax)
    return ImRect(pos.x, pos.y, pos.x + size.x, pos.y + size.y)
end

local function ImGuiViewportP()
    local this = setmetatable(ImGuiViewport(), Metatables.ImGuiViewportP)

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

Metatables.ImFontLoader = {}
Metatables.ImFontLoader.__index = Metatables.ImFontLoader

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
    }, Metatables.ImFontLoader)
end