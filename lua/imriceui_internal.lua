--- Some internal structures
-- I won't implement type checks, since I ensure that types are correct in internal usage,
-- and runtime type checking is very slow
local remove_at    = table.remove
local setmetatable = setmetatable
local next         = next
local isnumber     = isnumber
local str_format   = string.format

--- A compact ImVector clone, maybe
-- ImVector<>
local ImVector = {}
ImVector.__index = ImVector

function ImVector:push_back(value)
    self._top = self._top + 1
    self._items[self._top] = value
end

function ImVector:pop_back()
    if self._top == 0 then return nil end
    local value = self._items[self._top]
    self._items[self._top] = nil
    self._top = self._top - 1
    return value
end

function ImVector:clear()
    self._top = 0
end

function ImVector:clear_delete()
    for i = 1, self._top do
        self._items[i] = nil
    end
    self._top = 0
end

function ImVector:size() return self._top end
function ImVector:empty() return self._top == 0 end

function ImVector:peek()
    if self._top == 0 then return nil end
    return self._items[self._top]
end

function ImVector:erase(i)
    if i < 1 or i > self._top then return nil end
    local removed = remove_at(self._items, i)
    self._top = self._top - 1
    return removed
end

function ImVector:at(i)
    if i < 1 or i > self._top then return nil end
    return self._items[i]
end

function ImVector:iter()
    local i = 0
    local n = self._top
    return function()
        i = i + 1
        if i <= n then
            return i, self._items[i]
        end
    end
end

local function _ImVector()
    return setmetatable({_items = {}, _top = 0}, ImVector)
end

--- ImVec2
local ImVec2 = {}
ImVec2.__index = ImVec2

local function _ImVec2(x, y)
    return setmetatable({
        x = x or 0,
        y = y or 0
    }, ImVec2)
end

function ImVec2:__add(other)
    return _ImVec2(self.x + other.x, self.y + other.y)
end

function ImVec2:__sub(other)
    return _ImVec2(self.x - other.x, self.y - other.y)
end

function ImVec2:__mul(other)
    if isnumber(self) then
        return _ImVec2(self * other.x, self * other.y)
    elseif isnumber(other) then
        return _ImVec2(self.x * other, self.y * other)
    else
        return _ImVec2(self.x * other.x, self.y * other.y)
    end
end

function ImVec2:__eq(other)
    return self.x == other.x and self.y == other.y
end

function ImVec2:copy()
    return _ImVec2(self.x, self.y)
end

function ImVec2:__tostring()
    return str_format("ImVec2(%g, %g)", self.x, self.y)
end

--- struct ImVec4
local ImVec4 = {}
ImVec4.__index = ImVec4

local function _ImVec4(x, y, z, w)
    return setmetatable({
        x = x or 0,
        y = y or 0,
        z = z or 0,
        w = w or 0
    }, ImVec4)
end

function ImVec4:__add(other)
    return _ImVec4(self.x + other.x, self.y + other.y, self.z + other.z, self.w + other.w)
end

function ImVec4:__sub(other)
    return _ImVec4(self.x - other.x, self.y - other.y, self.z - other.z, self.w - other.w)
end

function ImVec4:__mul(other)
    if isnumber(self) then
        return _ImVec4(self * other.x, self * other.y, self * other.z, self * other.w)
    elseif isnumber(other) then
        return _ImVec4(self.x * other, self.y * other, self.z * other, self.w * other)
    else
        return _ImVec4(self.x * other.x, self.y * other.y, self.z * other.z, self.w * other.w)
    end
end

function ImVec4:__eq(other)
    return self.x == other.x and self.y == other.y and self.z == other.z and self.w == other.w
end

--- ImVec1
local ImVec1 = {}
ImVec1.__index = ImVec1

function _ImVec1(x)
    return setmetatable({
        x = x or 0
    }, ImVec1)
end

function ImVec1:copy()
    return ImVec1.new(self.x)
end

function ImVec1:__tostring()
    return str_format("ImVec1(%g)", self.x)
end

--- struct IMGUI_API ImRect
local ImRect = {}
ImRect.__index = ImRect

function ImRect:contains(other)
    return other.Min.x >= self.Min.x and other.Max.x <= self.Max.x and
        other.Min.y >= self.Min.y and other.Max.y <= self.Max.y
end

function ImRect:contains_point(p)
    return p.x >= self.Min.x and p.x <= self.Max.x and
        p.y >= self.Min.y and p.y <= self.Max.y
end

function ImRect:overlaps(other)
    return self.Min.x <= other.Max.x and self.Max.x >= other.Min.x and
        self.Min.y <= other.Max.y and self.Max.y >= other.Min.y
end

function ImRect:GetCenter()
    return _ImVec2(
        (self.Min.x + self.Max.x) * 0.5,
        (self.Min.y + self.Max.y) * 0.5
    )
end

function ImRect:__tostring()
    return str_format("ImRect(Min: %g,%g, Max: %g,%g)",
        self.Min.x, self.Min.y, self.Max.x, self.Max.y)
end

local function _ImRect(min, max)
    return setmetatable({
        Min = _ImVec2(min and min.x or 0, min and min.y or 0),
        Max = _ImVec2(max and max.x or 0, max and max.y or 0)
    }, ImRect)
end

--- struct ImGuiContext
local function _Context()
    return {
        Style = {
            FramePadding = _ImVec2(4, 3),

            WindowRounding = 0,

            Colors = nil,

            FontSizeBase = 18,
            FontScaleMain = 1,

            WindowMinSize = _ImVec2(60, 60),

            FrameBorderSize = 1,
            ItemSpacing = _ImVec2(8, 4)
        },

        Config = nil,
        Initialized = true,

        Windows = _ImVector(), -- Windows sorted in display order, back to front
        WindowsByID = {}, -- Map window's ID to window ref

        WindowsBorderHoverPadding = 0,

        CurrentWindowStack = _ImVector(),
        CurrentWindow = nil,

        IO = { -- TODO: make IO independent?
            MousePos = _ImVec2(),
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

            MouseClickedPos = {_ImVec2(), _ImVec2()},

            WantCaptureMouse = nil,
            -- WantCaptureKeyboard = nil,
            -- WantTextInput = nil,

            DeltaTime = 1 / 60,
            Framerate = 0
        },

        MovingWindow = nil,
        ActiveIDClickOffset = _ImVec2(),

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

            Rect        = _ImRect(),
            NavRect     = _ImRect(),
            DisplayRect = _ImRect(),
            ClipRect    = _ImRect()
            -- Shortcut = 
        },

        Font = nil, -- Currently bound *FontName* to be used with surface.SetFont
        FontSize = 18,
        FontSizeBase = 18,

        --- Contains ImFontStackData
        FontStack = _ImVector(),

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
local function _Window()
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

        --- struct ImDrawList
        DrawList = {
            CmdBuffer = {},

            _CmdHeader = {},
            _ClipRectStack = {}
        },

        IDStack = _ImVector(),

        --- struct IMGUI_API ImGuiWindowTempData
        DC = {
            CursorPos         = _ImVec2(),
            CursorPosPrevLine = _ImVec2(),
            CursorStartPos    = _ImVec2(),
            CursorMaxPos      = _ImVec2(),
            IdealMaxPos       = _ImVec2(),
            CurrLineSize      = _ImVec2(),
            PrevLineSize      = _ImVec2(),

            CurrLineTextBaseOffset = 0,
            PrevLineTextBaseOffset = 0,

            IsSameLine = false,
            IsSetPos = false,

            Indent                  = _ImVec1(),
            ColumnsOffset           = _ImVec1(),
            GroupOffset             = _ImVec1(),
            CursorStartPosLossyness = _ImVec1()
        },

        ClipRect = _ImRect(),

        LastFrameActive = -1
    }
end

return _ImVector, _ImVec2, _ImVec4, _ImVec1, _ImRect, _Context, _Window