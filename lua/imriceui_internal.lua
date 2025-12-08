--- Some internal structures
-- I won't implement type checks, since I ensure that types are correct in internal usage,
-- and runtime type checking is very slow
local remove_at    = table.remove
local setmetatable = setmetatable
local next         = next
local isnumber     = isnumber
local IsValid      = IsValid
local str_format   = string.format

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

local IM_PI = math.pi
local ImMin = math.min
local ImMax = math.max
local ImFloor = math.floor
local ImRound = math.Round
local ImCeil = math.ceil
local ImSin = math.sin
local ImCos = math.cos
local ImAcos = math.acos
local function ImLerp(a, b, t) return a + (b - a) * t end
local function ImClamp(v, min, max) return ImMin(ImMax(v, min), max) end
local function ImTrunc(f) return ImFloor(f + 0.5) end
local function IM_ROUNDUP_TO_EVEN(n) return ImCeil(n / 2) * 2 end

local IM_DRAWLIST_ARCFAST_TABLE_SIZE = 48
local IM_DRAWLIST_ARCFAST_SAMPLE_MAX = 48

local function IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC(_RAD, _MAXERROR) return ImClamp(IM_ROUNDUP_TO_EVEN(ImCeil(IM_PI / ImAcos(1 - ImMin(_MAXERROR, _RAD) / _RAD))), IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MIN, IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX) end
local function IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_R(N, MAXERROR) return MAXERROR / (1 - ImCos(IM_PI / ImMax(N, IM_PI))) end
local function IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_ERROR(N, RAD) return (1 - ImCos(IM_PI / ImMax(N, IM_PI))) / RAD end

--- A compact ImVector clone, maybe
-- ImVector<>
local _ImVector = {}
_ImVector.__index = _ImVector

function _ImVector:push_back(value) self._top = self._top + 1 self._items[self._top] = value end
function _ImVector:pop_back() if self._top == 0 then return nil end local value = self._items[self._top] self._items[self._top] = nil self._top = self._top - 1 return value end
function _ImVector:clear() self._top = 0 end
function _ImVector:clear_delete() for i = 1, self._top do self._items[i] = nil end self._top = 0 end
function _ImVector:size() return self._top end
function _ImVector:empty() return self._top == 0 end
function _ImVector:peek() if self._top == 0 then return nil end return self._items[self._top] end
function _ImVector:erase(i) if i < 1 or i > self._top then return nil end local removed = remove_at(self._items, i) self._top = self._top - 1 return removed end
function _ImVector:at(i) if i < 1 or i > self._top then return nil end return self._items[i] end
function _ImVector:iter() local i, n = 0, self._top return function() i = i + 1 if i <= n then return i, self._items[i] end end end

local function ImVector() return setmetatable({_items = {}, _top = 0}, _ImVector) end

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

--- struct ImVec4
--
local _ImVec4 = {}
_ImVec4.__index = _ImVec4

local function ImVec4(x, y, z, w) return setmetatable({x = x or 0, y = y or 0, z = z or 0, w = w or 0}, _ImVec4) end

function _ImVec4:__add(other) return ImVec4(self.x + other.x, self.y + other.y, self.z + other.z, self.w + other.w) end
function _ImVec4:__sub(other) return ImVec4(self.x - other.x, self.y - other.y, self.z - other.z, self.w - other.w) end
function _ImVec4:__mul(other) if isnumber(self) then return ImVec4(self * other.x, self * other.y, self * other.z, self * other.w) elseif isnumber(other) then return ImVec4(self.x * other, self.y * other, self.z * other, self.w * other) else return ImVec4(self.x * other.x, self.y * other.y, self.z * other.z, self.w * other.w) end end
function _ImVec4:__eq(other) return self.x == other.x and self.y == other.y and self.z == other.z and self.w == other.w end

--- ImVec1
--
local _ImVec1 = {}
_ImVec1.__index = _ImVec1

function ImVec1(x) return setmetatable({x = x or 0}, _ImVec1) end

function _ImVec1:__tostring() return str_format("ImVec1(%g)", self.x) end
function _ImVec1:copy() return ImVec1.new(self.x) end

--- struct IMGUI_API ImRect
local _ImRect = {}
_ImRect.__index = _ImRect

function _ImRect:__tostring() return str_format("ImRect(Min: %g,%g, Max: %g,%g)", self.Min.x, self.Min.y, self.Max.x, self.Max.y) end
function _ImRect:contains(other) return other.Min.x >= self.Min.x and other.Max.x <= self.Max.x and other.Min.y >= self.Min.y and other.Max.y <= self.Max.y end
function _ImRect:contains_point(p) return p.x >= self.Min.x and p.x <= self.Max.x and p.y >= self.Min.y and p.y <= self.Max.y end
function _ImRect:overlaps(other) return self.Min.x <= other.Max.x and self.Max.x >= other.Min.x and self.Min.y <= other.Max.y and self.Max.y >= other.Min.y end
function _ImRect:GetCenter() return ImVec2((self.Min.x + self.Max.x) * 0.5, (self.Min.y + self.Max.y) * 0.5) end

local function ImRect(min, max) return setmetatable({Min = ImVec2(min and min.x or 0, min and min.y or 0), Max = ImVec2(max and max.x or 0, max and max.y or 0)}, _ImRect) end

local _ImDrawListSharedData = {}
_ImDrawListSharedData.__index = _ImDrawListSharedData

function ImDrawListSharedData()
    return setmetatable({
        CircleSegmentMaxError = nil,

        ArcFastVtx = {}, -- size = IM_DRAWLIST_ARCFAST_TABLE_SIZE
        ArcFastRadiusCutoff = nil,
        CircleSegmentCounts = {} -- size = 64
    }, _ImDrawListSharedData)
end

--- struct ImGuiContext
local function ImGuiContext()
    return {
        Style = {
            FramePadding = ImVec2(4, 3),

            WindowRounding = 0,

            Colors = nil,

            FontSizeBase = 18,
            FontScaleMain = 1,

            WindowMinSize = ImVec2(60, 60),

            FrameBorderSize = 1,
            ItemSpacing = ImVec2(8, 4)
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
            Framerate = 0
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

        Font = nil, -- Currently bound *FontName* to be used with surface.SetFont
        FontSize = 18,
        FontSizeBase = 18,

        --- Contains ImFontStackData
        FontStack = ImVector(),

        DrawListSharedData = nil,

        -- StackSizesInBeginForCurrentWindow = nil,

        --- Misc
        FramerateSecPerFrame = {}, -- size = 60
        FramerateSecPerFrameIdx = 0,
        FramerateSecPerFrameCount = 0,
        FramerateSecPerFrameAccum = 0,

        WantCaptureMouseNextFrame = -1,
        -- WantCaptureKeyboardNextFrame = -1,
        -- WantTextInputNextFrame = -1
    }
end

--- struct IMGUI_API ImGuiWindow
local function ImGuiWindow()
    return {
        ID = 0,

        MoveID = 0,

        Name = "",
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

        HasCloseButton = true,

        ScrollbarX = false,
        ScrollbarY = false,

        --- struct ImDrawList
        DrawList = {
            CmdBuffer = {},

            _CmdHeader = {},
            _ClipRectStack = {}
        },

        IDStack = ImVector(),

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
end