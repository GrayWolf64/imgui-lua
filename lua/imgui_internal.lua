--- Some internal structures
-- I will avoid extensive type checks, since I ensure that types are correct in internal usage,
-- and runtime type checking is probably slow

--- @meta

-- TODO: Implement actual ImString type
--- @alias ImString char[]|string
--- @alias ImStringBuffer char[]

--- @type ImGuiContext?
local GImGui

-- Sets local `GImGui` in this file(imgui_internal.lua).
-- This is currently only used in main code `ImGui.SetCurrentContext()`
--- @param ctx ImGuiContext?
function ImGui._SetCurrentContext_Internal(ctx)
    GImGui = ctx
end

local setmetatable = setmetatable

local MT = ImGui.GetMetatables()

IM_TABSIZE = 4

FLT_MIN = 1.1754943508223e-38
FLT_MAX = 3.4028234663853e+38
DBL_MAX = 1.7976931348623e+308
INT_MIN = -0x7fffffff - 1
INT_MAX = 0x7fffffff
UINT_MAX = 0x7fffffff * 2 + 1
LLONG_MIN = -9223372036854775807 - 1
LLONG_MAX = 9223372036854775807

IM_PI  = math.pi
ImPow  = math.pow
ImLog  = math.log
ImAbs  = math.abs
ImFabs = math.abs
ImFmod = function(a, b) if b < 0 then b = -b end; if a < 0 then return -(-a % b) else return a % b end; end

ImMin = math.min

--- @param a ImVec2
--- @param b ImVec2
--- @return ImVec2
--- @nodiscard
function ImMinVec2(a, b) return ImVec2(ImMin(a.x, b.x), ImMin(a.y, b.y)) end

ImMax = math.max

--- @param a ImVec2
--- @param b ImVec2
--- @return ImVec2
--- @nodiscard
function ImMaxVec2(a, b) return ImVec2(ImMax(a.x, b.x), ImMax(a.y, b.y)) end

ImRound64 = function(val) return math.floor(val + 0.5) end -- FIXME: Positive values only

ImCeil  = math.ceil
ImSin   = math.sin
ImCos   = math.cos
ImAcos  = math.acos
ImAtan2 = math.atan2
ImSqrt  = math.sqrt

--- @param a number
--- @param b number
--- @param t number
function ImLerp(a, b, t) return ((a) + ((b) - (a)) * (t)) end

--- @param a ImVec2
--- @param b ImVec2
--- @param t float
function ImLerpV2V2(a, b, t)
    return ImVec2(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t)
end

--- @param a ImVec2
--- @param b ImVec2
--- @param t ImVec2
--- @return ImVec2
--- @nodiscard
function ImLerpV2V2V2(a, b, t) return ImVec2(a.x + (b.x - a.x) * t.x, a.y + (b.y - a.y) * t.y) end

--- @param a ImVec4
--- @param b ImVec4
--- @param t float
--- @nodiscard
function ImLerpV4V4(a, b, t) return ImVec4(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t, a.w + (b.w - a.w) * t) end

--- @param v   number
--- @param min number
--- @param max number
function ImClamp(v, min, max) return ImMin(ImMax(v, min), max) end

--- @param v   ImVec2
--- @param min ImVec2
--- @param max ImVec2
--- @return ImVec2
--- @nodiscard
function ImClampV2(v, min, max) return ImVec2(ImMin(ImMax(v.x, min.x), max.x), ImMin(ImMax(v.y, min.y), max.y)) end

--- @param f number
function ImTrunc(f) if f >= 0 then return math.floor(f) else return math.ceil(f) end end

--- @param v ImVec2
--- @nodiscard
function ImTruncV2(v) return ImVec2(ImTrunc(v.x), ImTrunc(v.y)) end

--- @param f float
function ImTrunc64(f) return ImTrunc(f) end

function IM_ROUNDUP_TO_EVEN(n) return (ImCeil((n) / 2) * 2) end
function ImRsqrt(x)            return (1 / ImSqrt(x))       end

function IM_TRUNC(VAL) return math.floor(VAL) end -- Positive values only!
function IM_ROUND(VAL) return math.floor(VAL + 0.5) end

function ImFloor(f) if f >= 0 or math.floor(f) == f then return math.floor(f) else return math.floor(f) - 1 end end

--- @param v int
function ImIsPowerOfTwo(v)
    return (v ~= 0) and (bit.band(v, (v - 1)) == 0)
end

function ImUpperPowerOfTwo(v)
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

--- @param avg    float
--- @param sample float
--- @param n      int
--- @return float
function ImStd.ImExponentialMovingAverage(avg, sample, n)
    avg = avg - avg / n
    avg = avg + sample / n
    return avg
end

do

local _memmove

if table.move then
    _memmove = function(dest, dest_start, src, src_start, count)
        table.move(src, src_start, src_start + count - 1, dest_start, dest)
    end
else
    _memmove = function(dest, dest_start, src, src_start, count)
        if count <= 0 then return end

        if dest == src then
            if dest_start < src_start then
                for i = 0, count - 1 do dest[dest_start + i] = src[src_start + i] end
            else
                for i = count - 1, 0, -1 do dest[dest_start + i] = src[src_start + i] end
            end
        else
            for i = 0, count - 1 do dest[dest_start + i] = src[src_start + i] end
        end
    end
end

--- @type fun(dest: table, dest_start: int, src: table, src_start: int, count: int)
ImStd.memmove = _memmove

end

--- @param str1 ImStringBuffer
--- @param str2 ImStringBuffer
function ImStd.strcmp(str1, str2)
    local i = 1
    while true do
        local c1 = str1[i] or 0
        local c2 = str2[i] or 0

        if c1 ~= c2 then
            return c1 - c2
        end

        if c1 == 0 then
            return 0
        end

        i = i + 1
    end
end

--- @param str1      ImStringBuffer
--- @param str2      ImStringBuffer
--- @param max_count int
function ImStd.strncmp(str1, str2, max_count)
    for i = 1, max_count do
        local c1 = str1[i] or 0
        local c2 = str2[i] or 0

        if c1 ~= c2 then
            return c1 - c2
        end

        if c1 == 0 then
            return 0
        end
    end
    return 0
end

function ImSaturate(f) return ((f < 0.0 and 0.0) or (f > 1.0 and 1.0) or f) end

IM_F32_TO_INT8_UNBOUND = function(val) return math.floor(val * 255.0 + (val >= 0 and 0.5 or -0.5)) end
IM_F32_TO_INT8_SAT = function(val) return math.floor(ImSaturate(val) * 255.0 + 0.5) end

--- @param s ImString
--- @param i int
--- @return char
function ImStrByte(s, i)
    if type(s) == "string" then
        return string.byte(s, i, i)
    else --- @cast s char[]
        return s[i]
    end
end

--- @class ImGuiColorMod
--- @field Col         ImGuiCol
--- @field BackupValue ImVec4

--- @param col          ImGuiCol
--- @param backup_value ImVec4
--- @return ImGuiColorMod
function ImGuiColorMod(col, backup_value)
    local this = {
        Col = col,
        BackupValue = ImVec4()
    }

    ImVec4_Copy(this.BackupValue, backup_value)

    return this
end

--- @param lhs ImVec2
--- @return float
function ImLengthSqr(lhs) return (lhs.x * lhs.x) + (lhs.y * lhs.y) end

--- @param v     ImVec2
--- @param cos_a float
--- @param sin_a float
--- @return ImVec2
--- @nodiscard
function ImRotate(v, cos_a, sin_a)
    return ImVec2(v.x * cos_a - v.y * sin_a, v.x * sin_a + v.y * cos_a)
end

--- @param a ImVec2
--- @param b ImVec2
function ImDot(a, b)
    return a.x * b.x + a.y * b.y
end

--- @param lhs ImVec2
--- @param rhs ImVec2
--- @nodiscard
function ImMul(lhs, rhs)
    return ImVec2(lhs.x * rhs.x, lhs.y * rhs.y)
end

--- @param str    char[]
--- @param begin? int
function ImStd.ImStrlen(str, begin)
    if begin == nil then begin = 1 end

    local l = #str

    for i = begin, l do
        if str[i] == 0 then
            return i - begin
        end
    end

    IM_ASSERT(false)
end

-- FIXME: should also accept count?
-- FIXME: avoid dynamic type checking?
-- string.find with patterns disabled
--- @param str        string|char[]
--- @param s          string|char
--- @param start_pos? int
--- @return int?
function ImMemchr(str, s, start_pos)
    local start = start_pos or 1
    if start < 1 then start = 1 end

    if type(str) == "table" then
        for i = start, #str do
            if str[i] == 0 then break end

            if str[i] == s then
                return i
            end
        end

        return nil
    end

    --- @cast str string
    local pos = string.find(str, s, start, true)

    return pos
end

IMGUI_FONT_SIZE_MAX                                = 512.0
IMGUI_FONT_SIZE_THRESHOLD_FOR_LOADADVANCEXONLYMODE = 128.0

IMGUI_WINDOW_HARD_MIN_SIZE = 4.0

IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MIN = 4
IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX = 512

IM_DRAWLIST_ARCFAST_TABLE_SIZE = 48
IM_DRAWLIST_ARCFAST_SAMPLE_MAX = IM_DRAWLIST_ARCFAST_TABLE_SIZE

function IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC(_RAD, _MAXERROR) return ImClamp(IM_ROUNDUP_TO_EVEN(ImCeil(IM_PI / ImAcos(1 - ImMin((_MAXERROR), (_RAD)) / (_RAD)))), IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MIN, IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX) end
function IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_R(_N, _MAXERROR) return ((_MAXERROR) / (1 - ImCos(IM_PI / ImMax(_N, IM_PI)))) end
function IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_ERROR(_N, _RAD)  return ((1 - ImCos(IM_PI / ImMax((_N), IM_PI))) / (_RAD)) end

function IM_ASSERT_USER_ERROR(_EXPR, _MSG) if not (_EXPR) or (_EXPR) == 0 then error(_MSG, 2) end end
function IM_ASSERT_USER_ERROR_RET(_EXPR, _MSG) if not (_EXPR) or (_EXPR) == 0 then error(_MSG, 2) end end

function IMGUI_DEBUG_LOG_ACTIVEID(_str, ...) local g  = GImGui if bit.band(g.DebugLogFlags, ImGuiDebugLogFlags.EventActiveId) ~= 0 then print(string.format(_str, ...)) end end
function IMGUI_DEBUG_LOG_POPUP(_str, ...)    local g  = GImGui if bit.band(g.DebugLogFlags, ImGuiDebugLogFlags.EventPopup) ~= 0 then print(string.format(_str, ...)) end end
function IMGUI_DEBUG_LOG_FONT(_str, ...)     local g2 = GImGui if g2 and bit.band(g2.DebugLogFlags, ImGuiDebugLogFlags.EventFont) ~= 0 then print(string.format(_str, ...)) end end
function IMGUI_DEBUG_LOG_VIEWPORT(_str, ...) local g  = GImGui if bit.band(g.DebugLogFlags, ImGuiDebugLogFlags.EventViewport) ~= 0 then print(string.format(_str, ...)) end end

ImGuiKeyOwner_Any     = 0
ImGuiKeyOwner_NoOwner = 4294967295

--- @param button ImGuiMouseButton
--- @return ImGuiKey
function ImGui.MouseButtonToKey(button) IM_ASSERT(button >= 0 and button < ImGuiMouseButton.COUNT) return ImGuiKey.MouseLeft + button end

--- @param key ImGuiKey
function ImGui.IsNamedKey(key)
    return key >= ImGuiKey.NamedKey_BEGIN and key < ImGuiKey.NamedKey_END
end

--- @param key ImGuiKey
function ImGui.IsKeyboardKey(key)
    return key >= ImGuiKey_Keyboard_BEGIN and key < ImGuiKey_Keyboard_END
end

--- @param key ImGuiKey
function ImGui.IsGamepadKey(key)
    return key >= ImGuiKey_Gamepad_BEGIN and key < ImGuiKey_Gamepad_END
end

--- @param key ImGuiKey
function ImGui.IsMouseKey(key)
    return key >= ImGuiKey_Mouse_BEGIN and key < ImGuiKey_Mouse_END
end

--- @param key ImGuiKey
function ImGui.IsAliasKey(key)
    return key >= ImGuiKey_Aliases_BEGIN and key < ImGuiKey_Aliases_END
end

--- @param key ImGuiKey
function ImGui.IsLRModKey(key)
    return key >= ImGuiKey.LeftCtrl and key <= ImGuiKey.RightSuper
end

--- @param key ImGuiKey
--- @return bool
function ImGui.IsNamedKeyOrMod(key)
    return (key >= ImGuiKey.NamedKey_BEGIN and key < ImGuiKey.NamedKey_END) or key == ImGuiMod_Ctrl or key == ImGuiMod_Shift or key == ImGuiMod_Alt or key == ImGuiMod_Super
end

--- @param key ImGuiKey
--- @return ImGuiKey
function ImGui.ConvertSingleModFlagToKey(key)
    if key == ImGuiMod_Ctrl then
        return ImGuiKey.ReservedForModCtrl
    elseif key == ImGuiMod_Shift then
        return ImGuiKey.ReservedForModShift
    elseif key == ImGuiMod_Alt then
        return ImGuiKey.ReservedForModAlt
    elseif key == ImGuiMod_Super then
        return ImGuiKey.ReservedForModSuper
    end
    return key
end

--- @param ctx ImGuiContext
--- @param key ImGuiKey
function ImGui.GetKeyOwnerData(ctx, key)
    if bit.band(key, ImGuiMod_Mask_) ~= 0 then key = ImGui.ConvertSingleModFlagToKey(key) end
    IM_ASSERT(ImGui.IsNamedKey(key))
    return ctx.KeysOwnerData[key - ImGuiKey.NamedKey_BEGIN]
end

--- @class ImGuiKeyOwnerData

--- @return ImGuiKeyOwnerData
--- @nodiscard
function ImGuiKeyOwnerData()
    return {
        OwnerCurr        = ImGuiKeyOwner_NoOwner,
        OwnerNext        = ImGuiKeyOwner_NoOwner,
        LockThisFrame    = false,
        LockUntilRelease = false
    }
end

--- @param size float
--- @return float
function ImGui.GetRoundedFontSize(size) return IM_ROUND(size) end

--- @param window ImGuiWindow
--- @param r      ImRect
--- @return ImRect
--- @nodiscard
function ImGui.WindowRectAbsToRel(window, r) local off = window.DC.CursorStartPos return ImRect(r.Min.x - off.x, r.Min.y - off.y, r.Max.x - off.x, r.Max.y - off.y) end

--- @param window ImGuiWindow
--- @param p      ImVec2
--- @return ImVec2
--- @nodiscard
function ImGui.WindowPosAbsToRel(window, p) local off = window.DC.CursorStartPos return ImVec2(p.x - off.x, p.y - off.y) end

--- @param c char
--- @return bool # True if this character is a ' ' or '\t'
function ImCharIsBlankA(c) return c == 32 or c == 9 end

--- @param c char
function ImCharIsBlankW(c) return c == 32 or c == 9 or c == 0x3000 end

--- @enum ImGuiNavMoveFlags
ImGuiNavMoveFlags = {
    None                  = 0,
    LoopX                 = bit.lshift(1, 0),
    LoopY                 = bit.lshift(1, 1),
    WrapX                 = bit.lshift(1, 2),
    WrapY                 = bit.lshift(1, 3),
    AllowCurrentNavId     = bit.lshift(1, 4),
    AlsoScoreVisibleSet   = bit.lshift(1, 5),
    ScrollToEdgeY         = bit.lshift(1, 6),
    Forwarded             = bit.lshift(1, 7),
    DebugNoResult         = bit.lshift(1, 8),
    FocusApi              = bit.lshift(1, 9),
    IsTabbing             = bit.lshift(1, 10),
    IsPageMove            = bit.lshift(1, 11),
    Activate              = bit.lshift(1, 12),
    NoSelect              = bit.lshift(1, 13),
    NoSetNavCursorVisible = bit.lshift(1, 14),
    NoClearActiveId       = bit.lshift(1, 15),
}

ImGuiNavMoveFlags.WrapMask_ = bit.bor(ImGuiNavMoveFlags.LoopX, ImGuiNavMoveFlags.LoopY, ImGuiNavMoveFlags.WrapX, ImGuiNavMoveFlags.WrapY)

--- @enum ImGuiNavLayer
ImGuiNavLayer = {
    Main  = 0,
    Menu  = 1,
    COUNT = 2
}

ImGuiItemFlags.ReadOnly               = bit.lshift(1, 11)
ImGuiItemFlags.MixedValue             = bit.lshift(1, 12)
ImGuiItemFlags.NoWindowHoverableCheck = bit.lshift(1, 13)
ImGuiItemFlags.AllowOverlap           = bit.lshift(1, 14)
ImGuiItemFlags.NoNavDisableMouseHover = bit.lshift(1, 15)
ImGuiItemFlags.NoMarkEdited           = bit.lshift(1, 16)
ImGuiItemFlags.NoFocus                = bit.lshift(1, 17)

ImGuiItemFlags.Inputable            = bit.lshift(1, 20)
ImGuiItemFlags.HasSelectionUserData = bit.lshift(1, 21)
ImGuiItemFlags.IsMultiSelect        = bit.lshift(1, 22)

ImGuiItemFlags.Default_ = ImGuiItemFlags.AutoClosePopups

--- @enum ImDrawTextFlags
ImDrawTextFlags = {
    None           = 0,
    CpuFineClip    = bit.lshift(1, 0),
    WrapKeepBlanks = bit.lshift(1, 1),
    StopOnNewLine  = bit.lshift(1, 2)
}

--- @enum ImGuiFocusRequestFlags
ImGuiFocusRequestFlags = {
    None                = 0,
    RestoreFocusedChild = bit.lshift(1, 0),
    UnlessBelowModal    = bit.lshift(1, 1)
}

--- @enum ImGuiTextFlags
ImGuiTextFlags = {
    None                          = 0,
    NoWidthForLargeClippedText    = bit.lshift(1, 0)
}

--- @enum ImWcharClass
ImWcharClass = {
    Blank = 0,
    Punct = 1,
    Other = 2
}

--- @class ImVec1
--- @field x number
MT.ImVec1 = {}
MT.ImVec1.__index = MT.ImVec1

local function ImVec1(x) return setmetatable({x = x or 0}, MT.ImVec1) end

function MT.ImVec1:__tostring() return string.format("ImVec1(%g)", self.x) end

--- @param dest ImVec1
--- @param src  ImVec1
function ImVec1_Copy(dest, src)
    dest.x = src.x
end

--- @class ImRect
--- @field Min ImVec2
--- @field Max ImVec2
MT.ImRect = {}
MT.ImRect.__index = MT.ImRect

--- @nodiscard
function ImRect(a, b, c, d) if c and d then return setmetatable({Min = ImVec2(a, b), Max = ImVec2(c, d)}, MT.ImRect) end return setmetatable({Min = ImVec2(a and a.x or 0, a and a.y or 0), Max = ImVec2(b and b.x or 0, b and b.y or 0)}, MT.ImRect) end

function MT.ImRect:__eq(other) return self.Min == other.Min and self.Max == other.Max end
function MT.ImRect:__tostring() return string.format("ImRect(Min: %g,%g, Max: %g,%g)", self.Min.x, self.Min.y, self.Max.x, self.Max.y) end

--- @param other ImRect
function MT.ImRect:Contains(other) return other.Min.x >= self.Min.x and other.Max.x <= self.Max.x and other.Min.y >= self.Min.y and other.Max.y <= self.Max.y end

--- @param p ImVec2
function MT.ImRect:ContainsV2(p) return p.x >= self.Min.x and p.y >= self.Min.y and p.x < self.Max.x and p.y < self.Max.y end

--- @param p   ImVec2
--- @param pad ImVec2
function MT.ImRect:ContainsWithPad(p, pad)
    return p.x >= self.Min.x - pad.x and p.y >= self.Min.y - pad.y and p.x < self.Max.x + pad.x and p.y < self.Max.y + pad.y
end

function MT.ImRect:Overlaps(other)
    local min_x, min_y, max_x, max_y

    if other.Min then
        --- @cast other ImRect
        min_x = other.Min.x; min_y = other.Min.y
        max_x = other.Max.x; max_y = other.Max.y
    elseif other.z then
        --- @cast other ImVec4
        min_x = other.x; min_y = other.y
        max_x = other.z; max_y = other.w
    else
        IM_ASSERT(false)
    end

    return self.Min.x <= max_x and self.Max.x >= min_x and self.Min.y <= max_y and self.Max.y >= min_y
end
function MT.ImRect:GetCenter() return ImVec2((self.Min.x + self.Max.x) * 0.5, (self.Min.y + self.Max.y) * 0.5) end
function MT.ImRect:GetWidth() return self.Max.x - self.Min.x end
function MT.ImRect:GetHeight() return self.Max.y - self.Min.y end
function MT.ImRect:GetSize() return ImVec2(self.Max.x - self.Min.x, self.Max.y - self.Min.y) end
function MT.ImRect:GetBL() return ImVec2(self.Min.x, self.Max.y) end

--- @param r ImRect|ImVec4
function MT.ImRect:ClipWith(r)
    if r.Min then
        --- @cast r ImRect
        self.Min.x = ImMax(self.Min.x, r.Min.x) self.Min.y = ImMax(self.Min.y, r.Min.y)
        self.Max.x = ImMin(self.Max.x, r.Max.x) self.Max.y = ImMin(self.Max.y, r.Max.y)
    elseif r.z then
        --- @cast r ImVec4
        self.Min.x = ImMax(self.Min.x, r.x) self.Min.y = ImMax(self.Min.y, r.y)
        self.Max.x = ImMin(self.Max.x, r.z) self.Max.y = ImMin(self.Max.y, r.w)
    else
        IM_ASSERT(false)
    end
end

function MT.ImRect:ClipWithFull(r)
    self.Min.x = ImClamp(self.Min.x, r.Min.x, r.Max.x) self.Min.y = ImClamp(self.Min.y, r.Min.y, r.Max.y)
    self.Max.x = ImClamp(self.Max.x, r.Min.x, r.Max.x) self.Max.y = ImClamp(self.Max.y, r.Min.y, r.Max.y)
end

--- @param p ImRect|ImVec2
function MT.ImRect:Add(p)
    if p.Min then
        --- @cast p ImRect
        self:Add(p.Min)
        self:Add(p.Max)
    else
        --- @cast p ImVec2
        if p.x < self.Min.x then self.Min.x = p.x end
        if p.y < self.Min.y then self.Min.y = p.y end
        if p.x > self.Max.x then self.Max.x = p.x end
        if p.y > self.Max.y then self.Max.y = p.y end
    end
end

--- @param amount float
function MT.ImRect:Expand(amount)
    self.Min.x = self.Min.x - amount; self.Min.y = self.Min.y - amount
    self.Max.x = self.Max.x + amount; self.Max.y = self.Max.y + amount
end

--- @param amount ImVec2
function MT.ImRect:ExpandV2(amount)
    self.Min.x = self.Min.x - amount.x; self.Min.y = self.Min.y - amount.y
    self.Max.x = self.Max.x + amount.x; self.Max.y = self.Max.y + amount.y
end

function MT.ImRect:ToVec4()
    return ImVec4(self.Min.x, self.Min.y, self.Max.x, self.Max.y)
end

--- @param d ImVec2
function MT.ImRect:Translate(d)
    self.Min.x = self.Min.x + d.x; self.Min.y = self.Min.y + d.y
    self.Max.x = self.Max.x + d.x; self.Max.y = self.Max.y + d.y
end

function MT.ImRect:GetArea() return (self.Max.x - self.Min.x) * (self.Max.y - self.Min.y) end

--- @nodiscard
function MT.ImRect:AsVec4() return ImVec4(self.Min.x, self.Min.y, self.Max.x, self.Max.y) end

--- @param dest ImRect
--- @param src  ImRect
function ImRect_Copy(dest, src)
    dest.Min.x = src.Min.x; dest.Min.y = src.Min.y
    dest.Max.x = src.Max.x; dest.Max.y = src.Max.y
end

--- @param dest ImRect
--- @param src  ImVec4
function ImRect_CopyFromV4(dest, src)
    dest.Min.x = src.x; dest.Min.y = src.y
    dest.Max.x = src.z; dest.Max.y = src.w
end

--- @param _ARRAY ImU32[]
--- @param _N     int
function IM_BITARRAY_TESTBIT(_ARRAY, _N)
    return bit.band(_ARRAY[bit.rshift(_N - 1, 5) + 1], bit.lshift(1, bit.band(_N - 1, 31))) ~= 0
end

--- @param _ARRAY ImU32[]
--- @param _N     int
function IM_BITARRAY_CLEARBIT(_ARRAY, _N)
    local idx = bit.rshift(_N - 1, 5) + 1
    _ARRAY[idx] = bit.band(_ARRAY[idx], bit.bnot(bit.lshift(1, bit.band(_N - 1, 31))))
end

--- @param arr ImU32[]
--- @param n   int
function ImBitArraySetBit(arr, n)
    local mask = bit.lshift(1, bit.band(n - 1, 31))
    local idx = bit.rshift(n - 1, 5) + 1
    arr[idx] = bit.bor(arr[idx], mask)
end

--- @alias ImBitArrayForNamedKeys ImBitArray

--- @class ImBitArray<BITCOUNT, OFFSET>
--- @field [1] ImU32[] # Data
--- @field [2] int     # BITCOUNT
--- @field [3] int     # OFFSET
--- @field [4] int     # Pre-calculated size of Data
local _ImBitArray = {}
_ImBitArray.__index = _ImBitArray

--- @param bitcount int
--- @param offset?  int
--- @return ImBitArray
function ImBitArray(bitcount, offset)
    local this = setmetatable({ {}, bitcount, offset or 0, bit.rshift(bitcount + 31, 5) }, _ImBitArray)
    this:ClearAllBits()
    return this
end

function _ImBitArray:ClearAllBits()
    for i = 1, self[4] do self[1][i] = 0 end
end

function _ImBitArray:SetAllBits()
    for i = 1, self[4] do self[1][i] = 0xFFFFFFFF end
end

--- @param n int
--- @return boolean
function _ImBitArray:TestBit(n) n = n + self[3]; IM_ASSERT(n >= 1 and n <= self[2]); return IM_BITARRAY_TESTBIT(self[1], n); end

--- @param n int
function _ImBitArray:SetBit(n) IM_ASSERT(n >= 1 and n <= self[2]); ImBitArraySetBit(self[1], n); end

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
    if not flags     then flags     = 0   end
    if not thickness then thickness = 1.0 end

    self:AddPolyline(self._Path.Data, self._Path.Size, col, flags, thickness)
    self._Path.Size = 0
end

--- @param col ImU32
function ImGui.SetNextItemColorMarker(col)
    local g = GImGui
    g.NextItemData.HasFlags = bit.bor(g.NextItemData.HasFlags, ImGuiNextItemDataFlags.HasColorMarker)
    g.NextItemData.ColorMarker = col
end

--- @class ImDrawListSharedData
--- @field TexUvWhitePixel       ImVec2
--- @field TexUvLines            ImVec4
--- @field FontAtlas             ImFontAtlas
--- @field Font                  ImFont
--- @field FontSize              float
--- @field FontScale             float
--- @field CurveTessellationTol  float
--- @field CircleSegmentMaxError float
--- @field InitialFringeScale    float
--- @field InitialFlags          ImDrawListFlags
--- @field ClipRectFullscreen?   ImVec4
--- @field TempBuffer            ImVector<ImVec2>
--- @field DrawLists             ImVector<ImDrawList>
--- @field Context?              ImGuiContext
--- @field ArcFastVtx            table<ImVec2>        # 1-based table
--- @field ArcFastRadiusCutoff   float
--- @field CircleSegmentCounts   table<int>           # 1-based table
MT.ImDrawListSharedData = {}
MT.ImDrawListSharedData.__index = MT.ImDrawListSharedData

--- @return ImDrawListSharedData
--- @nodiscard
function ImDrawListSharedData()
    local this = setmetatable({
        TexUvWhitePixel = nil,
        TexUvLines      = nil,
        FontAtlas       = nil,

        Font      = nil,
        FontSize  = 0,
        FontScale = 0,

        CurveTessellationTol  = 0,
        CircleSegmentMaxError = 0,
        InitialFringeScale    = 1,

        InitialFlags          = 0,
        ClipRectFullscreen    = nil,
        TempBuffer            = ImVector(ImVec2),
        DrawLists             = ImVector(),

        ArcFastVtx          = {},
        ArcFastRadiusCutoff = nil,
        CircleSegmentCounts = {},

        Context = nil
    }, MT.ImDrawListSharedData)

    for i = 1, IM_DRAWLIST_ARCFAST_TABLE_SIZE do
        local a = ((i - 1) * 2 * IM_PI) / IM_DRAWLIST_ARCFAST_TABLE_SIZE
        this.ArcFastVtx[i] = ImVec2(ImCos(a), ImSin(a))
    end

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
--- @field BakedPool                ImVector<ImFontBaked>
--- @field BakedMap                 table<ImGuiID, any>            # LUA: No ImGuiStorage
--- @field BakedDiscardedCount      int
--- @field PackIdMouseCursors       ImFontAtlasRectId
--- @field PackIdLinesTexData       ImFontAtlasRectId
MT.ImFontAtlasBuilder = {}
MT.ImFontAtlasBuilder.__index = MT.ImFontAtlasBuilder

--- @return ImFontAtlasBuilder
function ImFontAtlasBuilder()
    --- @type ImFontAtlasBuilder
    local this = setmetatable({}, MT.ImFontAtlasBuilder)

    this.PackContext              = nil -- struct stbrp_context_opaque { char data[80]; };
    this.PackNodes                = ImVector()
    this.Rects                    = ImVector()
    this.RectsIndex               = ImVector()
    this.TempBuffer               = IM_SLICE() -- ImVector()
    this.RectsIndexFreeListStart  = -1
    this.RectsPackedCount         = 0
    this.RectsPackedSurface       = 0
    this.RectsDiscardedCount      = 0
    this.RectsDiscardedSurface    = 0
    this.FrameCount               = -1
    this.MaxRectSize              = ImVec2()
    this.MaxRectBounds            = ImVec2()
    this.LockDisableResize        = false
    this.PreloadedAllGlyphsRanges = false

    this.BakedPool           = ImVector() -- ImStableVector<ImFontBaked,32>
    this.BakedMap            = {}
    this.BakedDiscardedCount = 0

    this.PackIdMouseCursors = -1
    this.PackIdLinesTexData = -1

    return this
end

--- @class ImFontStackData
--- @field Font                  ImFont
--- @field FontSizeBeforeScaling float
--- @field FontSizeAfterScaling  float

--- @return ImFontStackData
--- @param font                     ImFont
--- @param font_size_before_scaling float
--- @param font_size_after_scaling  float
--- @nodiscard
function ImFontStackData(font, font_size_before_scaling, font_size_after_scaling)
    return {
        Font                  = font,
        FontSizeBeforeScaling = font_size_before_scaling,
        FontSizeAfterScaling  = font_size_after_scaling
    }
end

--- `GetVarPtr()` is currently only used on `g.Style` in Dear ImGui, and we don't have pointers!
--- @class ImGuiStyleVarInfo
--- @field Count    ImU32
--- @field DataType ImGuiDataType
--- @field Key      string        # key in parent structure. Note that the cpp Dear ImGui uses `ImU32 Offset`!

--- @param count     ImU32
--- @param data_type ImGuiDataType
--- @param key       string
--- @return ImGuiStyleVarInfo
--- @nodiscard
function ImGuiStyleVarInfo(count, data_type, key)
    return { Count = count, DataType = data_type, Key = key }
end

--- @class ImGuiStyleMod
--- @field VarIdx       ImGuiStyleVar
--- @field BackupVal    table

--- @param idx ImGuiStyleVar
--- @param v   int|float|ImVec2
function ImGuiStyleMod(idx, v)
    local this = { VarIdx = idx, BackupVal = {nil, nil} }
    --- @cast this ImGuiStyleMod

    if type(v) == "number" then
        this.BackupVal[1] = v
    else -- ImVec2
        this.BackupVal[1] = v.x; this.BackupVal[2] = v.y
    end

    return this
end

--- Type information associated to one ImGuiDataType. Retrieve with DataTypeGetInfo().\
--- Unlike cpp impl, `Size` and `ScanFmt` fields are absent here
--- @class ImGuiDataTypeInfo
--- @field Name     string # Short descriptive name for the type, for debugging
--- @field PrintFmt string # Default printf format for the type

--- @class ImGuiLastItemData
--- @field ID          ImGuiID
--- @field ItemFlags   ImGuiItemFlags
--- @field StatusFlags ImGuiItemStatusFlags
--- @field Rect        ImRect
--- @field NavRect     ImRect
--- @field DisplayRect ImRect
--- @field ClipRect    ImRect
--- @field Shortcut    ImGuiKeyChord

--- @return ImGuiLastItemData
--- @nodiscard
function ImGuiLastItemData()
    return {
        ID          = 0,
        ItemFlags   = 0,
        StatusFlags = 0,
        Rect        = ImRect(),
        NavRect     = ImRect(),

        DisplayRect = ImRect(),
        ClipRect    = ImRect(),
        Shortcut    = 0
    }
end

--- @param dest ImGuiLastItemData
--- @param src  ImGuiLastItemData
function ImGuiLastItemData_Copy(dest, src)
    dest.ID = src.ID
    dest.ItemFlags = src.ItemFlags
    dest.StatusFlags = src.StatusFlags
    ImRect_Copy(dest.Rect, src.Rect)
    ImRect_Copy(dest.NavRect, src.NavRect)
    ImRect_Copy(dest.DisplayRect, src.DisplayRect)
    ImRect_Copy(dest.ClipRect, src.ClipRect)
    dest.Shortcut = src.Shortcut
end

--- @class ImGuiNextItemData
--- @field HasFlags          ImGuiNextItemDataFlags
--- @field ItemFlags         ImGuiItemFlags
--- @field FocusScopeId      ImGuiID
--- @field SelectionUserData any
--- @field Width             number
--- @field Shortcut          ImGuiKeyChord
--- @field ShortcutFlags     ImGuiInputFlags
--- @field OpenVal           boolean
--- @field OpenCond          ImGuiCond
--- @field RefVal            any
--- @field StorageId         ImGuiID
--- @field ColorMarker       ImU32
MT.ImGuiNextItemData = {}
MT.ImGuiNextItemData.__index = MT.ImGuiNextItemData

function MT.ImGuiNextItemData:ClearFlags()
    self.HasFlags = ImGuiNextItemDataFlags.None
    self.ItemFlags = ImGuiItemFlags.None
end

--- @return ImGuiNextItemData
--- @nodiscard
function ImGuiNextItemData()
    return setmetatable({
        HasFlags          = 0,
        ItemFlags         = 0,

        FocusScopeId      = 0,
        SelectionUserData = -1,
        Width             = 0.0,
        Shortcut          = 0,
        ShortcutFlags     = 0,
        OpenVal           = false,
        OpenCond          = 0,
        RefVal            = nil,
        StorageId         = 0,
        ColorMarker       = 0
    }, MT.ImGuiNextItemData)
end

--- @class ImGuiNextWindowData
--- @field HasFlags             ImGuiNextWindowDataFlags
--- @field PosCond              ImGuiCond
--- @field SizeCond             ImGuiCond
--- @field CollapsedCond        ImGuiCond
--- @field PosVal               ImVec2?
--- @field PosPivotVal          ImVec2?
--- @field SizeVal              ImVec2?
--- @field ContentSizeVal       ImVec2?
--- @field ScrollVal            ImVec2?
--- @field WindowFlags          ImGuiWindowFlags?
--- @field ChildFlags           ImGuiChildFlags?
--- @field CollapsedVal         boolean?
--- @field SizeConstraintRect   ImRect?
--- @field SizeCallback         function?
--- @field SizeCallbackUserData any
--- @field BgAlphaVal           number?
--- @field MenuBarOffsetMinVal  ImVec2?
--- @field RefreshFlagsVal      int?
MT.ImGuiNextWindowData = {}
MT.ImGuiNextWindowData.__index = MT.ImGuiNextWindowData

function MT.ImGuiNextWindowData:ClearFlags()
    self.HasFlags = ImGuiNextWindowDataFlags.None
end

--- @return ImGuiNextWindowData
--- @nodiscard
function ImGuiNextWindowData()
    return setmetatable({
        HasFlags = 0,

        PosCond              = 0,
        SizeCond             = 0,
        CollapsedCond        = 0,
        PosVal               = ImVec2(),
        PosPivotVal          = ImVec2(),
        SizeVal              = ImVec2(),
        ContentSizeVal       = ImVec2(),
        ScrollVal            = ImVec2(),
        WindowFlags          = nil,
        ChildFlags           = nil,
        CollapsedVal         = nil,
        SizeConstraintRect   = nil,
        SizeCallback         = nil,
        SizeCallbackUserData = nil,
        BgAlphaVal           = nil,
        MenuBarOffsetMinVal  = ImVec2(),
        RefreshFlagsVal      = nil
    }, MT.ImGuiNextWindowData)
end

--- @enum ImGuiWindowBgClickFlags
ImGuiWindowBgClickFlags = {
    None = 0,
    Move = bit.lshift(1, 0),
}

--- @enum ImGuiNextWindowDataFlags
ImGuiNextWindowDataFlags = {
    None              = 0,
    HasPos            = bit.lshift(1, 0),
    HasSize           = bit.lshift(1, 1),
    HasContentSize    = bit.lshift(1, 2),
    HasCollapsed      = bit.lshift(1, 3),
    HasSizeConstraint = bit.lshift(1, 4),
    HasFocus          = bit.lshift(1, 5),
    HasBgAlpha        = bit.lshift(1, 6),
    HasScroll         = bit.lshift(1, 7),
    HasWindowFlags    = bit.lshift(1, 8),
    HasChildFlags     = bit.lshift(1, 9),
    HasRefreshPolicy  = bit.lshift(1, 10),
    HasViewport       = bit.lshift(1, 11),
    HasDock           = bit.lshift(1, 12),
    HasWindowClass    = bit.lshift(1, 13)
}

--- @enum ImGuiLayoutType
ImGuiLayoutType = {
    Horizontal = 0,
    Vertical   = 1
}

--- @enum ImGuiSeparatorFlags
ImGuiSeparatorFlags = {
    None           = 0,
    Horizontal     = bit.lshift(1, 0), -- Axis default to current layout type, so generally Horizontal unless e.g. in a menu bar
    Vertical       = bit.lshift(1, 1),
    SpanAllColumns = bit.lshift(1, 2)  -- Make separator cover all columns of a legacy Columns() set
}

--- @class ImGuiStyle
MT.ImGuiStyle = {}
MT.ImGuiStyle.__index = MT.ImGuiStyle

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
        FrameRounding = 0.0,
        FrameBorderSize = 0.0,
        WindowPadding = ImVec2(8, 8),

        TouchExtraPadding = ImVec2(0, 0),
        IndentSpacing = 21.0,

        WindowRounding = 0,
        WindowBorderSize = 1,

        ScrollbarSize     = 14.0,
        ScrollbarRounding = 9.0,
        ScrollbarPadding  = 2.0,
        GrabMinSize = 12.0,
        GrabRounding = 0.0,
        ImageRounding = 0.0,
        ImageBorderSize = 0.0,

        WindowBorderHoverPadding = 4.0,

        ColorMarkerSize = 3.0,
        ColorButtonPosition = ImGuiDir.Right,

        SeparatorSize           = 1.0,
        SeparatorTextBorderSize = 3.0,
        SeparatorTextAlign      = ImVec2(0.0, 0.5),
        SeparatorTextPadding    = ImVec2(20.0, 3.0),

        DisplaySafeAreaPadding = ImVec2(3, 3),
        DisplayWindowPadding = ImVec2(19, 19),

        AntiAliasedLines = true,
        AntiAliasedLinesUseTex = true,
        AntiAliasedFill = true,

        CurveTessellationTol       = 1.25,
        CircleTessellationMaxError = 0.30,

        HoverStationaryDelay = 0.15,
        HoverDelayShort = 0.15,
        HoverDelayNormal = 0.40,

        PopupBorderSize = 1.0,

        Colors = {},

        ButtonTextAlign = ImVec2(0.5, 0.5),
        SelectableTextAlign = ImVec2(0.0, 0.0),

        WindowMinSize = ImVec2(32, 32),
        WindowTitleAlign = ImVec2(0.0, 0.5),
        WindowMenuButtonPosition = ImGuiDir.Left,

        MouseCursorScale = 1.0,

        ItemSpacing = ImVec2(8, 4),
        ItemInnerSpacing = ImVec2(4, 4),

        HoverFlagsForTooltipMouse = bit.bor(ImGuiHoveredFlags.Stationary, ImGuiHoveredFlags.DelayShort, ImGuiHoveredFlags.AllowWhenDisabled),
        HoverFlagsForTooltipNav = bit.bor(ImGuiHoveredFlags.NoSharedDelay, ImGuiHoveredFlags.DelayNormal, ImGuiHoveredFlags.AllowWhenDisabled),

        -- [Internal]
        _MainScale = 1.0,
        _NextFrameFontSizeBase = 0.0
    }

    ImGui.StyleColorsDark(this)

    setmetatable(this, MT.ImGuiStyle)

    return this
end

--- @class ImGuiWindowStackData

--- @return ImGuiWindowStackData
--- @nodiscard
function ImGuiWindowStackData()
    return {
        Window                              = nil,
        ParentLastItemDataBackup            = ImGuiLastItemData(),
        StackSizesInBegin                   = nil,
        DisabledOverrideReenable            = nil,
        DisabledOverrideReenableAlphaBackup = nil
    }
end

--- @class ImGuiComboPreviewData
--- @field PreviewRect                  ImRect
--- @field BackupCursorPos              ImVec2
--- @field BackupCursorMaxPos           ImVec2
--- @field BackupCursorPosPrevLine      ImVec2
--- @field BackupPrevLineTextBaseOffset float
--- @field BackupLayout                 ImGuiLayoutType

--- @return ImGuiComboPreviewData
--- @nodiscard
local function ImGuiComboPreviewData()
    return {
        PreviewRect                  = ImRect(),
        BackupCursorPos              = ImVec2(),
        BackupCursorMaxPos           = ImVec2(),
        BackupCursorPosPrevLine      = ImVec2(),
        BackupPrevLineTextBaseOffset = 0.0,
        BackupLayout                 = 0
    }
end

--- @alias IMSTB_TEXTEDIT_STRING ImGuiInputTextState

--- @alias ImStbTexteditState STB_TexteditState

--- @class ImGuiInputTextState
--- @field Ctx                  ImGuiContext        # parent UI context (needs to be set explicitly by parent)
--- @field Stb                  ImStbTexteditState  # State for stb_textedit.lua
--- @field Flags                ImGuiInputTextFlags
--- @field ID                   ImGuiID             # widget id owning the text state
--- @field TextLen              int                 # UTF-8 length of the string in TextA (in bytes)
--- @field TextSrc              ImStringBuffer      # == TextA.Data unless read-only, in which case == buf passed to InputText(). For _ReadOnly fields, pointer will be null outside the InputText() call
--- @field TextA                ImVector<char>      # main UTF8 buffer. TextA.Size is a buffer size! Should always be >= buf_size passed by user (and of course >= CurLenA + 1)
--- @field TextToRevertTo       ImVector<char>      # value to revert to when pressing Escape = backup of end-user buffer at the time of focus (in UTF-8, unaltered)
--- @field CallbackTextBackup   ImVector<char>      # temporary storage for callback to support automatic reconcile of undo-stack
--- @field BufCapacity          int                 # end-user buffer capacity (include zero terminator)
--- @field Scroll               ImVec2              # horizontal offset (managed manually) + vertical scrolling (pulled from child window's own Scroll.y)
--- @field LineCount            int                 # last line count (solely for debugging)
--- @field WrapWidth            float               # word-wrapping width
--- @field CursorAnim           float               # timer for cursor blink, reset on every user action so the cursor reappears immediately
--- @field CursorFollow         bool                # set when we want scrolling to follow the current cursor position (not always!)
--- @field CursorCenterY        bool                # set when we want scrolling to be centered over the cursor position (while resizing a word-wrapping field)
--- @field SelectedAllMouseLock bool                # after a double-click to select all, we ignore further mouse drags to update selection
MT.ImGuiInputTextState = {}
MT.ImGuiInputTextState.__index = MT.ImGuiInputTextState

local function ImGuiInputTextState()
    local this = {
        Ctx   = nil,
        Stb   = STB_TexteditState(), -- FIXME: no global!
        Flags = 0,
        ID    = 0,

        TextLen            = 0,
        TextSrc            = nil,
        TextA              = ImVector(),
        TextToRevertTo     = ImVector(),
        CallbackTextBackup = ImVector(),

        BufCapacity = 0,
        Scroll      = ImVec2(),
        LineCount   = 0,
        WrapWidth   = 0.0,

        CursorAnim    = 0.0,
        CursorFollow  = false,
        CursorCenterY = false,
        SelectedAllMouseLock = false,
    }

    return setmetatable(this, MT.ImGuiInputTextState)
end

--- @class ImGuiInputTextDeactivatedState
--- @field ID    ImGuiID        # widget id owning the text state (which just got deactivated)
--- @field TextA ImVector<char> # text buffer
MT.ImGuiInputTextDeactivatedState = {}
MT.ImGuiInputTextDeactivatedState.__index = MT.ImGuiInputTextDeactivatedState

function MT.ImGuiInputTextDeactivatedState:ClearFreeMemory()
    self.ID = 0
    self.TextA:clear()
end

--- @return ImGuiInputTextDeactivatedState
--- @nodiscard
local function ImGuiInputTextDeactivatedState()
    return setmetatable({
        ID    = 0,
        TextA = ImVector()
    }, MT.ImGuiInputTextDeactivatedState)
end

--- @alias ImGuiKeyRoutingIndex ImS16

--- @class ImGuiKeyRoutingData
--- @field NextEntryIndex   ImGuiKeyRoutingIndex
--- @field Mods             ImU16
--- @field RoutingCurrScore ImU16
--- @field RoutingNextScore ImU16
--- @field RoutingCurr      ImGuiID
--- @field RoutingNext      ImGuiID

--- @return ImGuiKeyRoutingData
--- @nodiscard
function ImGuiKeyRoutingData()
    return {
        NextEntryIndex = -1,
        Mods = 0,
        RoutingCurrScore = 0,
        RoutingNextScore = 0,
        RoutingCurr = ImGuiKeyOwner_NoOwner,
        RoutingNext = ImGuiKeyOwner_NoOwner
    }
end

--- @class ImGuiKeyRoutingTable
--- @field Index       ImGuiKeyRoutingIndex[]
--- @field Entries     ImVector<ImGuiKeyRoutingData>
--- @field EntriesNext ImVector<ImGuiKeyRoutingData>
local _ImGuiKeyRoutingTable = {}
_ImGuiKeyRoutingTable.__index = _ImGuiKeyRoutingTable

function _ImGuiKeyRoutingTable:Clear()
    for n = 1, ImGuiKey.NamedKey_COUNT do self.Index[n] = -1 end
    self.Entries:clear()
    self.EntriesNext:clear()
end

--- @return ImGuiKeyRoutingTable
local function ImGuiKeyRoutingTable()
    local this = setmetatable({
        Index       = {},
        Entries     = ImVector(),
        EntriesNext = ImVector()
    }, _ImGuiKeyRoutingTable)

    this:Clear()

    return this
end

--- @class ImGuiTextIndex
--- @field Offsets   ImVector<int>
--- @field EndOffset int
local _ImGuiTextIndex = {}
_ImGuiTextIndex.__index = _ImGuiTextIndex

function _ImGuiTextIndex:get_line_begin(base, n)
    return base + (self.Offsets.Size ~= 0 and self.Offsets[n] or 0)
end

function _ImGuiTextIndex:get_line_end(base, n)
    return base + ((n + 1 < self.Offsets.Size) and (self.Offsets[n + 1] - 1) or self.EndOffset)
end

--- @return ImGuiTextIndex
local function ImGuiTextIndex()
    return setmetatable({
        Offsets = ImVector(),
        EndOffset = 0
    }, _ImGuiTextIndex)
end

--- @class ImGuiDebugAllocEntry
--- @field FrameCount int
--- @field AllocCount int
--- @field FreeCount  int

--- @return ImGuiDebugAllocEntry
local function ImGuiDebugAllocEntry()
    return { FrameCount = 0, AllocCount = 0, FreeCount = 0 }
end

--- @class ImGuiDebugAllocInfo
--- @field TotalAllocCount int
--- @field TotalFreeCount  int
--- @field LastEntriesIdx  ImS16
--- @field LastEntriesBuf  ImGuiDebugAllocEntry[]

--- @return ImGuiDebugAllocInfo
local function ImGuiDebugAllocInfo()
    local this = {
        TotalAllocCount = 0,
        TotalFreeCount = 0,
        LastEntriesIdx = 1,
        LastEntriesBuf = {nil, nil, nil, nil, nil, nil}
    }

    for i = 1, 6 do
        this.LastEntriesBuf[i] = ImGuiDebugAllocEntry()
    end

    return this
end

--- @class ImGuiContext
--- @field Initialized                        bool
--- @field WithinFrameScope                   bool
--- @field WithinFrameScopeWithImplicitWindow bool
--- @field FrameCount                         int
--- @field FrameCountEnded                    int
--- @field CurrentWindow                      ImGuiWindow
--- @field HoveredWindow                      ImGuiWindow
--- @field Style                              ImGuiStyle
--- @field StyleVarStack                      ImVector
--- @field ActiveIdMouseButton                ImS8
--- @field Windows                            ImVector<ImGuiWindow>
--- @field WindowsFocusOrder                  ImVector<ImGuiWindow>
--- @field CurrentWindowStack                 ImVector<ImGuiWindowStackData>
--- @field ItemFlagsStack                     ImVector<ImGuiItemFlags>
--- @field GroupStack                         ImVector<ImGuiGroupData>
--- @field OpenPopupStack                     ImVector<ImGuiPopupData>
--- @field BeginPopupStack                    ImVector<ImGuiPopupData>
--- @field PlatformIO                         ImGuiPlatformIO
--- @field Viewports                          ImVector<ImGuiViewportP>
--- @field DebugLogFlags                      ImGuiDebugLogFlags
--- @field DebugFlashStyleColorIdx            ImGuiCol
--- @field ColorEditOptions                   ImGuiColorEditFlags            # Store user options for color edit widgets
--- @field ColorEditCurrentID                 ImGuiID                        # Set temporarily while inside of the parent-most ColorEdit4/ColorPicker4 (because they call each others)
--- @field ColorEditSavedID                   ImGuiID                        # ID we are saving/restoring HS for
--- @field ColorEditSavedHue                  float                          # Backup of last Hue associated to LastColor, so we can restore Hue in lossy RGB<>HSV round trips
--- @field ColorEditSavedSat                  float                          # Backup of last Saturation associated to LastColor, so we can restore Saturation in lossy RGB<>HSV round trips
--- @field ColorEditSavedColor                ImU32                          # RGB value with alpha set to 0
--- @field ColorPickerRef                     ImVec4                         # Initial/reference color at the time of opening the color picker
--- @field InputTextState                     ImGuiInputTextState
--- @field InputTextLineIndex                 ImGuiTextIndex
--- @field InputTextDeactivatedState          ImGuiInputTextDeactivatedState
--- @field InputTextPasswordFontBackupBaked   ImFontBaked
--- @field KeysMayBeCharInput                 ImBitArrayForNamedKeys
--- @field KeysOwnerData                      ImGuiKeyOwnerData[]
--- @field KeysRoutingTable                   ImGuiKeyRoutingTable
--- @field NavFocusRoute                      ImVector<ImGuiFocusScopeData>
--- @field PlatformImeData                    ImGuiPlatformImeData
--- @field PlatformImeDataPrev                ImGuiPlatformImeData
--- @field DebugAllocInfo                     ImGuiDebugAllocInfo

--- @param shared_font_atlas? ImFontAtlas
--- @return ImGuiContext
--- @nodiscard
function ImGuiContext(shared_font_atlas) -- TODO: tidy up / complete this structure
    local this = {
        Style = ImGuiStyle(),
        ColorStack = ImVector(),
        StyleVarStack = ImVector(),

        Config = nil,
        Initialized = false,
        WithinFrameScope = false,
        WithinFrameScopeWithImplicitWindow = false,

        Windows = ImVector(), -- Windows sorted in display order, back to front
        WindowsById = {}, -- Map window's ID to window ref

        WindowsBorderHoverPadding = 0,

        WindowsActiveCount = 0,

        CurrentWindowStack = ImVector(),
        CurrentWindow = nil,

        WindowsFocusOrder = ImVector(),

        IO = ImGuiIO(),
        PlatformIO = ImGuiPlatformIO(),

        ConfigFlagsCurrFrame = ImGuiConfigFlags.None,
        ConfigFlagsLastFrame = ImGuiConfigFlags.None,

        MouseLastValidPos = ImVec2(),

        KeysMayBeCharInput = ImBitArray(ImGuiKey.NamedKey_COUNT, -ImGuiKey.NamedKey_BEGIN),
        KeysOwnerData = {}, -- size = ImGuiKey.NamedKey_COUNT
        KeysRoutingTable = ImGuiKeyRoutingTable(),

        InputEventsQueue = ImVector(),

        InputEventsNextMouseSource = ImGuiMouseSource.Mouse,
        InputEventsNextEventId = 1,

        MovingWindow = nil,

        WheelingWindow = nil,
        WheelingWindowStartFrame = -1, WheelingWindowScrolledFrame = -1,
        WheelingWindowReleaseTimer = 0.0,
        WheelingWindowRefMousePos = ImVec2(),
        WheelingWindowWheelRemainder = ImVec2(),
        WheelingAxisAvg = ImVec2(),

        ActiveIdClickOffset = ImVec2(),

        HoveredWindow = nil,
        HoveredWindowUnderMovingWindow = nil,
        HoveredIdIsDisabled = false,

        ActiveIdFromShortcut = false,

        ActiveId = 0,
        ActiveIdWindow = nil,

        ActiveIdMouseButton = -1,

        ActiveIdIsJustActivated = false,

        ActiveIdNoClearOnFocusLoss = false,
        ActiveIdHasBeenPressedBefore = false,

        ActiveIdIsAlive = nil,

        ActiveIdPreviousFrame = 0,

        ActiveIdTimer = 0.0,

        LastActiveId = 0,
        LastActiveIdTimer = 0.0,

        ActiveIdUsingNavDirMask = 0x00,
        ActiveIdUsingAllKeyboardKeys = false,

        DeactivatedItemData = {
            ID = 0,
            ElapseFrame = 0,
            HasBeenEditedBefore = false,
            IsAlive = false
        },

        HoveredId = 0,
        HoveredIdTimer = 0.0,
        HoveredIdNotActiveTimer = 0.0,
        HoveredIdAllowOverlap = false,

        HoverItemDelayId = 0, HoverItemDelayIdPreviousFrame = 0, HoverItemUnlockedStationaryId = 0, HoverWindowUnlockedStationaryId = 0,
        HoverItemDelayTimer = 0.0, HoverItemDelayClearTimer = 0.0,

        ActiveIdAllowOverlap = false,

        NavLayer = ImGuiNavLayer.Main,
        NavId = 0,
        NavWindow = nil,
        NavHighlightActivatedId = 0,
        NavCursorVisible = false,
        NavHighlightItemUnderNav = false,
        NavIdIsAlive = false,

        NavFocusRoute = ImVector(),

        NavAnyRequest = false,
        NavInitRequest = false,
        NavInitRequestFromMove = false,
        NavMoveSubmitted = false,
        NavMoveScoringItems = false,
        NavMoveForwardToNextFrame = false,
        NavMoveFlags = ImGuiNavMoveFlags.None,
        NavMoveScrollFlags = ImGuiScrollFlags.None,
        NavMoveKeyMods = ImGuiMod_None,
        NavMoveDir = ImGuiDir.None, NavMoveDirForDebug = ImGuiDir.None, NavMoveClipDir = ImGuiDir.None,

        FrameCount = -1,

        FrameCountEnded = -1,
        FrameCountPlatformEnded = -1,
        FrameCountRendered = -1,

        Time = 0,

        NextItemData = ImGuiNextItemData(),
        LastItemData = ImGuiLastItemData(),
        NextWindowData = ImGuiNextWindowData(),

        Viewports = ImVector(),

        FallbackMonitor = nil,

        CurrentViewport = nil,
        MouseViewport = nil, MouseLastHoveredViewport = nil,
        PlatformLastFocusedViewportId = 1,
        ViewportCreatedCount = 0, PlatformWindowsCreatedCount = 0,
        ViewportFocusedStampCount = 0,

        Font = nil,
        FontSize = 0.0,
        FontSizeBase = 0.0,
        CurrentDpiScale = 0.0,

        FontRefSize = 0.0,

        FontRasterizerDensity = 1.0,

        FontAtlases = ImVector(),

        FontStack = ImVector(),

        OpenPopupStack = ImVector(),
        BeginPopupStack = ImVector(),

        WithinEndChildID = 0,

        BeginMenuDepth = 0, BeginComboDepth = 0,
        ColorEditOptions = ImGuiColorEditFlags.DefaultOptions_,
        ColorEditCurrentID = 0, ColorEditSavedID = 0,
        ColorEditSavedHue = 0.0, ColorEditSavedSat = 0.0,
        ColorEditSavedColor = 0,
        ColorPickerRef = ImVec4(),

        DrawListSharedData = ImDrawListSharedData(),

        -- StackSizesInBeginForCurrentWindow = nil,

        --- Misc
        FramerateSecPerFrame = {}, -- size = 60
        FramerateSecPerFrameIdx = 0,
        FramerateSecPerFrameCount = 0,
        FramerateSecPerFrameAccum = 0,

        WantCaptureMouseNextFrame = -1,
        WantCaptureKeyboardNextFrame = -1,
        WantTextInputNextFrame = -1,

        MouseCursor = ImGuiMouseCursor.Arrow,
        MouseStationaryTimer = 0.0,

        InputTextState = ImGuiInputTextState(),
        InputTextLineIndex = ImGuiTextIndex(),
        InputTextDeactivatedState = ImGuiInputTextDeactivatedState(),
        InputTextPasswordFontBackupBaked = ImFontBaked(),

        ComboPreviewData = ImGuiComboPreviewData(),

        WindowResizeBorderExpectedRect = ImRect(),
        WindowResizeRelativeMode = false,

        ScrollbarSeekMode = 0,
        ScrollbarClickDeltaToGrabCenter = 0.0,

        SliderGrabClickOffset = 0.0,
        SliderCurrentAccum = 0.0,
        SliderCurrentAccumDirty = false,
        DragCurrentAccumDirty = false,
        DragCurrentAccum = 0.0,
        DragSpeedDefaultRatio = 1.0 / 100.0,

        TooltipOverrideCount = 0,
        TooltipPreviousWindow = nil,

        CurrentFocusScopeId = 0,
        CurrentItemFlags = ImGuiItemFlags.None,

        DisabledStackSize = 0,

        ItemFlagsStack = ImVector(),
        GroupStack = ImVector(),

        PlatformImeData = ImGuiPlatformImeData(),
        PlatformImeDataPrev = ImGuiPlatformImeData(),

        -- Extensions
        UserTextures = ImVector(),

        -- Settings
        SettingsWindows = ImVector(),

        -- Drag and Drop
        DragDropActive = false,
        DragDropWithinSource = false,
        DragDropWithinTarget = false,
        DragDropSourceFlags = 0,

        DragDropAcceptIdPrev = 0, DragDropAcceptIdCurr = 0,

        LocalizationTable = {},

        DebugLogFlags = bit.bor(ImGuiDebugLogFlags.EventError, ImGuiDebugLogFlags.OutputToTTY),
        DebugFlashStyleColorIdx = nil,

        DebugAllocInfo = ImGuiDebugAllocInfo()
    }

    for i = 0, 59 do this.FramerateSecPerFrame[i] = 0 end

    this.IO.Fonts = (shared_font_atlas ~= nil) and shared_font_atlas or ImFontAtlas()
    if shared_font_atlas == nil then
        this.IO.Fonts.OwnerContext = this
    end

    for i = 0, ImGuiKey.NamedKey_COUNT - 1 do
        this.KeysOwnerData[i] = ImGuiKeyOwnerData()
    end

    this.IO.Ctx = this
    this.InputTextState.Ctx = this

    ImVec2_Copy(this.PlatformImeDataPrev.InputPos, ImVec2(-1.0, -1.0))

    return this
end

--- @class ImGuiWindowSettings
--- @field ID           int     # Window ID
--- @field Pos          ImVec2  # Window position
--- @field Size         ImVec2  # Window size
--- @field Collapsed    bool    # Whether window is collapsed
--- @field IsChild      bool    # Whether window is a child window
--- @field WantApply    bool    # Set when loaded from .ini data
--- @field WantDelete   bool    # Set to invalidate/delete the settings entry
--- @field Name         string  # Window name
MT.ImGuiWindowSettings = {}
MT.ImGuiWindowSettings.__index = MT.ImGuiWindowSettings

function ImGuiWindowSettings()
    return setmetatable({
        ID           = 0,
        Pos          = ImVec2(0, 0),
        Size         = ImVec2(0, 0),
        Collapsed    = false,
        IsChild      = false,
        WantApply    = false,
        WantDelete   = false,
        Name         = "",
    }, MT.ImGuiWindowSettings)
end

function MT.ImGuiWindowSettings:GetName()
    return self.Name
end

--- @class ImGuiWindowTempData
--- @field CursorPos               ImVec2
--- @field CursorPosPrevLine       ImVec2
--- @field CursorStartPos          ImVec2
--- @field CursorMaxPos            ImVec2
--- @field IdealMaxPos             ImVec2
--- @field CurrLineSize            ImVec2
--- @field PrevLineSize            ImVec2
--- @field CurrLineTextBaseOffset  float
--- @field PrevLineTextBaseOffset  float
--- @field IsSameLine              bool
--- @field IsSetPos                bool
--- @field Indent                  ImVec1
--- @field ColumnsOffset           ImVec1
--- @field GroupOffset             ImVec1
--- @field CursorStartPosLossyness ImVec2
--- @field TextWrapPos             float
--- @field TextWrapPosStack        ImVector
--- @field MenuBarAppending        bool
--- @field MenuBarOffset           ImVec2
--- @field ChildWindows            ImVector<ImGuiWindow>
--- @field LayoutType              ImGuiLayoutType

--- @return ImGuiWindowTempData
--- @nodiscard
local function ImGuiWindowTempData()
    return {
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
        CursorStartPosLossyness = ImVec2(),

        ItemWidth = 0,
        ItemWidthDefault = 0,
        TextWrapPos = 0,
        ItemWidthStack = ImVector(),
        TextWrapPosStack = ImVector(),

        MenuBarAppending = false, -- FIXME: Remove this
        MenuBarOffset = ImVec2(),

        ChildWindows = ImVector(),

        LayoutType = nil
    }
end

--- @class ImGuiWindow
--- @field Ctx                                ImGuiContext
--- @field Name                               string
--- @field ID                                 ImGuiID
--- @field Flags                              ImGuiWindowFlags
--- @field FlagsPreviousFrame                 ImGuiWindowFlags
--- @field ChildFlags                         ImGuiChildFlags
--- @field WindowClass                        ImGuiWindowClass
--- @field Viewport                           ImGuiViewportP
--- @field ViewportId                         ImGuiID
--- @field ViewportPos                        ImVec2
--- @field ViewportAllowPlatformMonitorExtend int
--- @field Pos                                ImVec2
--- @field Size                               ImVec2
--- @field SizeFull                           ImVec2
--- @field ContentSize                        ImVec2
--- @field ContentSizeIdeal                   ImVec2
--- @field ContentSizeExplicit                ImVec2
--- @field IsExplicitChild                    bool
--- @field FocusOrder                         short               # 1-based, order within WindowsFocusOrder, altered when windows are focused. Can be -1 if invalid
--- @field IDStack                            ImVector<ImGuiID>
--- @field DC                                 ImGuiWindowTempData
--- @field OuterRectClipped                   ImRect
--- @field InnerRect                          ImRect
--- @field InnerClipRect                      ImRect
--- @field WorkRect                           ImRect
--- @field ParentWorkRect                     ImRect
--- @field ClipRect                           ImRect
--- @field ContentRegionRect                  ImRect
--- @field DrawList                           ImDrawList          # Points to DrawListInst
--- @field DrawListInst                       ImDrawList
--- @field ParentWindow?                      ImGuiWindow
--- @field RootWindow                         ImGuiWindow
--- @field RootWindowPopupTree                ImGuiWindow
--- @field RootWindowDockTree                 ImGuiWindow
MT.ImGuiWindow = {}
MT.ImGuiWindow.__index = MT.ImGuiWindow

--- @return ImRect
--- @nodiscard
function MT.ImGuiWindow:Rect()
    return ImRect(self.Pos.x, self.Pos.y, self.Pos.x + self.Size.x, self.Pos.y + self.Size.y)
end

--- @return ImRect
--- @nodiscard
function MT.ImGuiWindow:TitleBarRect()
    return ImRect(self.Pos, ImVec2(self.Pos.x + self.SizeFull.x, self.Pos.y + self.TitleBarHeight))
end

--- @return ImRect
--- @nodiscard
function MT.ImGuiWindow:MenuBarRect()
    local y1 = self.Pos.y + self.TitleBarHeight
    return ImRect(self.Pos.x, y1, self.Pos.x + self.SizeFull.x, y1 + self.MenuBarHeight)
end

--- @return ImGuiWindow
--- @nodiscard
function ImGuiWindow(ctx, name)
    local this = {
        ID = 0,

        MoveId = 0,

        Ctx = ctx,
        Name = name,

        Flags = 0,

        ChildFlags = 0,
        WindowClass = ImGuiWindowClass(),

        Pos = ImVec2(),
        Size = ImVec2(), -- Current size (==SizeFull or collapsed title bar size)
        SizeFull = ImVec2(),

        Active = false,
        WasActive = false,

        Collapsed = false,

        SkipItems = false,

        SkipRefresh = false,

        Appearing = false,

        Hidden = false,
        IsFallbackWindow = false,

        IsExplicitChild = nil,

        ResizeBorderHovered = -1,
        ResizeBorderHeld = -1,

        BeginCount = 0,
        BeginCountPreviousFrame = 0,
        BeginOrderWithinParent = 0,
        BeginOrderWithinContext = 0,

        FocusOrder = nil,

        HiddenFramesCanSkipItems = 0,
        HiddenFramesCannotSkipItems = 0,
        HiddenFramesForRenderOnly = 0,

        DisableInputsFrames = 0,

        WindowRounding = 0,
        WindowBorderSize = 1,

        TitleBarHeight = 0, MenuBarHeight = 0,

        DecoOuterSizeX1 = 0, DecoOuterSizeY1 = 0,
        DecoOuterSizeX2 = 0, DecoOuterSizeY2 = 0,
        DecoInnerSizeX1 = 0, DecoInnerSizeY1 = 0,

        ContentSize = ImVec2(),
        ContentSizeIdeal = ImVec2(),
        ContentSizeExplicit = ImVec2(),

        AutoFitFramesX = -1, AutoFitFramesY = -1,
        AutoFitOnlyGrows = false,

        HasCloseButton = true,

        BgClickFlags = 0,

        SetWindowPosAllowFlags = 0, SetWindowSizeAllowFlags = 0, SetWindowCollapsedAllowFlags = 0,
        SetWindowPosVal = ImVec2(FLT_MAX, FLT_MAX),
        SetWindowPosPivot = ImVec2(FLT_MAX, FLT_MAX),

        SettingsOffset = -1,

        ScrollbarSizes = ImVec2(),
        Scroll = ImVec2(),

        ScrollbarX = false,
        ScrollbarY = false,
        ScrollMax = ImVec2(),
        ScrollTarget = ImVec2(FLT_MAX, FLT_MAX),
        ScrollTargetCenterRatio = ImVec2(0.5, 0.5),
        ScrollTargetEdgeSnapDist = ImVec2(),

        ScrollbarXStabilizeToggledHistory = 0,

        DrawList = nil,
        DrawListInst = ImDrawList(ctx.DrawListSharedData),

        RootWindow = nil,
        RootWindowPopupTree = nil,
        RootWindowDockTree = nil,

        ParentWindow = nil,
        ParentWindowInBeginStack = nil,

        IDStack = ImVector(),

        ViewportAllowPlatformMonitorExtend = -1,
        Viewport = nil,
        ViewportId = 0,
        ViewportPos = ImVec2(FLT_MAX, FLT_MAX),
        ViewportOwned = nil,

        --- struct IMGUI_API ImGuiWindowTempData
        DC = ImGuiWindowTempData(),

        OuterRectClipped  = ImRect(),
        InnerRect         = ImRect(),
        InnerClipRect     = ImRect(),
        WorkRect          = ImRect(),
        ParentWorkRect    = ImRect(),
        ContentRegionRect = ImRect(),

        ClipRect = ImRect(),

        LastFrameActive = -1,
        LastFrameJustFocused = -1,
        LastTimeActive = -1.0,

        WriteAccessed = false,

        FontWindowScale = 1.0,
        FontWindowScaleParents = 1.0,

        HitTestHoleSize = ImVec2(),

        NavLastChildNavWindow = nil,
        NavLastIds = {[0] = 0, [1] = 0}, -- FIXME: 1-based instead
        NavRectRel = {[0] = ImRect(), [1] = ImRect()},
        NavPreferredScoringPosRel = {[0] = ImVec2(), [1] = ImVec2()},
        NavRootFocusScopeId = 0
    }

    this.DrawList = this.DrawListInst
    this.DrawList._OwnerName = name

    setmetatable(this, MT.ImGuiWindow)

    this.ID = ImHashStr(name)
    this.IDStack:push_back(this.ID)
    this.MoveId = this:GetID("#MOVE")

    return this
end

--- @class ImDrawDataBuilder
--- @field Layers     table<ImDrawList?>   # 1-based size=2 table
--- @field LayerData1 ImVector<ImDrawList>
MT.ImDrawDataBuilder = {}
MT.ImDrawDataBuilder.__index = MT.ImDrawDataBuilder

--- @return ImDrawDataBuilder
--- @nodiscard
local function ImDrawDataBuilder()
    return setmetatable({
        Layers     = {nil, nil},
        LayerData1 = ImVector()
    }, MT.ImDrawDataBuilder)
end

--- @class ImGuiViewportP : ImGuiViewport
--- @field Window?                     ImGuiWindow
--- @field Idx                         int                      # Initial value = -1, then becomes 1-based index
--- @field LastFrameActive             int
--- @field LastFocusedStampCount       int
--- @field LastNameHash                ImGuiID
--- @field LastPos                     ImVec2
--- @field LastSize                    ImVec2
--- @field Alpha                       float
--- @field LastAlpha                   float
--- @field LastFocusedHadNavWindow     bool
--- @field PlatformMonitor             short
--- @field BgFgDrawListsLastTimeActive [int, int]               # 1-based
--- @field BgFgDrawLists               [ImDrawList, ImDrawList] # 1-based
--- @field DrawDataP                   ImDrawData
--- @field DrawDataBuilder             ImDrawDataBuilder
--- @field LastPlatformPos             ImVec2
--- @field LastPlatformSize            ImVec2
--- @field LastRendererSize            ImVec2
--- @field WorkInsetMin                ImVec2
--- @field WorkInsetMax                ImVec2
--- @field BuildWorkInsetMin           ImVec2
--- @field BuildWorkInsetMax           ImVec2
MT.ImGuiViewportP = {}
MT.ImGuiViewportP.__index = MT.ImGuiViewportP

setmetatable(MT.ImGuiViewportP, {__index = MT.ImGuiViewport})

function MT.ImGuiViewportP:ClearRequestFlags()
    self.PlatformRequestClose  = false
    self.PlatformRequestMove   = false
    self.PlatformRequestResize = false
end

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

--- @nodiscard
function MT.ImGuiViewportP:GetMainRect()
    return ImRect(self.Pos.x, self.Pos.y,
        self.Pos.x + self.Size.x,
        self.Pos.y + self.Size.y)
end

--- @nodiscard
function MT.ImGuiViewportP:GetWorkRect()
    return ImRect(self.WorkPos.x, self.WorkPos.y,
        self.WorkPos.x + self.WorkSize.x,
        self.WorkPos.y + self.WorkSize.y)
end

--- @nodiscard
function MT.ImGuiViewportP:GetBuildWorkRect()
    local pos = self:CalcWorkRectPos(self.BuildWorkInsetMin)
    local size = self:CalcWorkRectSize(self.BuildWorkInsetMin, self.BuildWorkInsetMax)
    return ImRect(pos.x, pos.y, pos.x + size.x, pos.y + size.y)
end

--- @return ImGuiViewportP
--- @nodiscard
function ImGuiViewportP()
    local this = setmetatable(ImGuiViewport(), MT.ImGuiViewportP) --- @cast this ImGuiViewportP

    this.Window = nil
    this.Idx = -1

    this.LastFrameActive       = -1
    this.LastFocusedStampCount = -1
    this.LastNameHash          = 0
    this.LastPos               = ImVec2() -- ImGuiViewport() { memset(this, 0, sizeof(*this)); }
    this.LastSize              = ImVec2()

    this.Alpha     = 1.0
    this.LastAlpha = 1.0

    this.LastFocusedHadNavWindow = false
    this.PlatformMonitor = -1

    this.BgFgDrawListsLastTimeActive = {-1, -1}
    this.BgFgDrawLists = {nil, nil}
    this.DrawDataP = ImDrawData()
    this.DrawDataBuilder = ImDrawDataBuilder()

    this.LastPlatformPos  = ImVec2(FLT_MAX, FLT_MAX)
    this.LastPlatformSize = ImVec2(FLT_MAX, FLT_MAX)
    this.LastRendererSize = ImVec2(FLT_MAX, FLT_MAX)

    this.WorkInsetMin = ImVec2(0, 0)
    this.WorkInsetMax = ImVec2(0, 0)
    this.BuildWorkInsetMin = ImVec2(0, 0)
    this.BuildWorkInsetMax = ImVec2(0, 0)

    return this
end

--- @class ImFontLoader
--- @field Name                       string
--- @field LoaderInit?                fun(atlas: ImFontAtlas): bool
--- @field LoaderShutdown?            fun(atlas: ImFontAtlas)
--- @field FontSrcInit?               fun(atlas: ImFontAtlas, src: ImFontConfig): bool
--- @field FontSrcDestroy?            fun(atlas: ImFontAtlas, src: ImFontConfig)
--- @field FontSrcContainsGlyph?      fun(atlas: ImFontAtlas, src: ImFontConfig, codepoint: ImWchar): bool
--- @field FontBakedInit?             fun(atlas: ImFontAtlas, src: ImFontConfig, baked: ImFontBaked, loader_data_for_baked_src?: any): bool
--- @field FontBakedDestroy?          fun(atlas: ImFontAtlas, src: ImFontConfig, baked: ImFontBaked, loader_data_for_baked_src?: any)
--- @field FontBakedLoadGlyph         fun(atlas: ImFontAtlas, src: ImFontConfig, baked: ImFontBaked, loader_data_for_baked_src?: any, codepoint: ImWchar, out_glyph?: ImFontGlyph, advance_x?: float): bool, float?
--- @field FontBakedSrcLoaderDataSize unsigned_int
MT.ImFontLoader = {}
MT.ImFontLoader.__index = MT.ImFontLoader

--- @return ImFontLoader
--- @nodiscard
function ImFontLoader()
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
--- @field TargetIndex int          # 0-based! When IsUsed = true, TargetIndex = this rect's index in Rects; IsUsed = false, TargetIndex = the next unused RectsIndex entry's index
--- @field Generation  unsigned_int # How many times this entry is reused
--- @field IsUsed      bool

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

--- @param id ImFontAtlasRectId # Expects 0-based!
--- @return int                 # 0-based!
function ImFontAtlasRectId_GetIndex(id) return bit.band(id, ImFontAtlasRectId_IndexMask_) end

--- @param id ImFontAtlasRectId # Expects 0-based!
--- @return unsigned_int
function ImFontAtlasRectId_GetGeneration(id) return bit.rshift(bit.band(id, ImFontAtlasRectId_GenerationMask_), ImFontAtlasRectId_GenerationShift_) end

--- @param index_idx int      # Expects 0-based!
--- @param gen_idx int
--- @return ImFontAtlasRectId # 0-based!
function ImFontAtlasRectId_Make(index_idx, gen_idx)
    IM_ASSERT(index_idx >= 0 and index_idx <= ImFontAtlasRectId_IndexMask_ and gen_idx <= bit.rshift(ImFontAtlasRectId_GenerationMask_, ImFontAtlasRectId_GenerationShift_))
    return bit.bor(index_idx, bit.lshift(gen_idx, ImFontAtlasRectId_GenerationShift_))
end

--- @class ImFontAtlasPostProcessData
--- @field FontAtlas ImFontAtlas
--- @field Font      ImFont
--- @field FontSrc   ImFontConfig
--- @field FontBaked ImFontBaked
--- @field Glyph     ImFontGlyph
--- @field Pixels    ImSlice
--- @field Format    ImTextureFormat
--- @field Pitch     int
--- @field Width     int
--- @field Height    int

--- @param atlas      ImFontAtlas
--- @param font       ImFont
--- @param font_src   ImFontConfig
--- @param font_baked ImFontBaked
--- @param glyph      ImFontGlyph
--- @param pixels     ImSlice
--- @param format     ImTextureFormat
--- @param pitch      int
--- @param width      int
--- @param height     int
--- @return ImFontAtlasPostProcessData
--- @nodiscard
function ImFontAtlasPostProcessData(atlas, font, font_src, font_baked, glyph, pixels, format, pitch, width, height)
    return {
        FontAtlas = atlas,
        Font      = font,
        FontSrc   = font_src,
        FontBaked = font_baked,
        Glyph     = glyph,

        Pixels = pixels,
        Format = format,
        Pitch  = pitch,
        Width  = width,
        Height = height,
    }
end

--- @enum ImGuiInputSource
ImGuiInputSource = {
    None     = 0,
    Mouse    = 1,
    Keyboard = 2,
    Gamepad  = 3,
    COUNT    = 4
}

--- @class ImGuiInputEventMousePos
--- @field PosX float
--- @field PosY float
--- @field MouseSource ImGuiMouseSource

--- @return ImGuiInputEventMousePos
--- @nodiscard
function ImGuiInputEventMousePos()
    return { PosX = 0, PosY = 0, MouseSource = ImGuiMouseSource.Mouse }
end

--- @class ImGuiInputEventMouseButton
--- @field Button int
--- @field Down   bool
--- @field MouseSource ImGuiMouseSource

--- @return ImGuiInputEventMouseButton
--- @nodiscard
function ImGuiInputEventMouseButton()
    return { Button = 0, Down = false, MouseSource = ImGuiMouseSource.Mouse }
end

--- @class ImGuiInputEventMouseWheel
--- @field WheelX float
--- @field WheelY float
--- @field MouseSource ImGuiMouseSource

--- @return ImGuiInputEventMouseWheel
--- @nodiscard
function ImGuiInputEventMouseWheel()
    return { WheelX = 0, WheelY = 0, MouseSource = ImGuiMouseSource.Mouse }
end

--- @class ImGuiInputEventKey
--- @field Key         ImGuiKey
--- @field Down        bool
--- @field AnalogValue float

--- @return ImGuiInputEventKey
--- @nodiscard
function ImGuiInputEventKey()
    return { Key = 0, Down = false, AnalogValue = 0 }
end

--- @class ImGuiInputEventText
--- @field Char unsigned_int

--- @return ImGuiInputEventText
--- @nodiscard
function ImGuiInputEventText()
    return { Char = nil }
end

--- @class ImGuiInputEventMouseViewport
--- @field HoveredViewportID ImGuiID

--- @return ImGuiInputEventMouseViewport
--- @nodiscard
function ImGuiInputEventMouseViewport()
    return { HoveredViewportID = 0 }
end

--- @class ImGuiInputEvent

--- @return ImGuiInputEvent
--- @nodiscard
function ImGuiInputEvent()
    return {
        Type    = 0,
        Source  = 0,
        EventId = 0,

        -- union
        MousePos      = nil,   -- if Type == ImGuiInputEventType.MousePos
        MouseWheel    = nil,   -- if Type == ImGuiInputEventType.MouseWheel
        MouseButton   = nil,   -- if Type == ImGuiInputEventType.MouseButton
        MouseViewport = nil,   -- if Type == ImGuiInputEventType.MouseViewport
        Key           = nil,   -- if Type == ImGuiInputEventType.Key
        Text          = nil,   -- if Type == ImGuiInputEventType.Text
        AppFocused    = nil,   -- if Type == ImGuiInputEventType.Focus
    }
end

ImGuiKey_Keyboard_BEGIN = ImGuiKey.NamedKey_BEGIN
ImGuiKey_Keyboard_END   = ImGuiKey.GamepadStart
ImGuiKey_Gamepad_BEGIN  = ImGuiKey.GamepadStart
ImGuiKey_Gamepad_END    = ImGuiKey.GamepadRStickDown + 1
ImGuiKey_Mouse_BEGIN    = ImGuiKey.MouseLeft
ImGuiKey_Mouse_END      = ImGuiKey.MouseWheelY + 1
ImGuiKey_Aliases_BEGIN  = ImGuiKey_Mouse_BEGIN
ImGuiKey_Aliases_END    = ImGuiKey_Mouse_END

ImGuiKey.NavKeyboardTweakSlow = ImGuiMod_Ctrl
ImGuiKey.NavKeyboardTweakFast = ImGuiMod_Shift
ImGuiKey.NavGamepadTweakSlow = ImGuiKey.GamepadL1
ImGuiKey.NavGamepadTweakFast = ImGuiKey.GamepadR1

--- @enum ImGuiInputEventType
ImGuiInputEventType = {
    None          = 0,
    MousePos      = 1,
    MouseWheel    = 2,
    MouseButton   = 3,
    MouseViewport = 4,
    Key           = 5,
    Text          = 6,
    Focus         = 7,
    COUNT         = 8
}

ImGuiInputFlags.RepeatRateDefault                = bit.lshift(1, 1)
ImGuiInputFlags.RepeatRateNavMove                = bit.lshift(1, 2)
ImGuiInputFlags.RepeatRateNavTweak               = bit.lshift(1, 3)
ImGuiInputFlags.RepeatUntilRelease               = bit.lshift(1, 4)
ImGuiInputFlags.RepeatUntilKeyModsChange         = bit.lshift(1, 5)
ImGuiInputFlags.RepeatUntilKeyModsChangeFromNone = bit.lshift(1, 6)
ImGuiInputFlags.RepeatUntilOtherKeyPress         = bit.lshift(1, 7)
ImGuiInputFlags.LockThisFrame                    = bit.lshift(1, 20)
ImGuiInputFlags.LockUntilRelease                 = bit.lshift(1, 21)
ImGuiInputFlags.CondHovered                      = bit.lshift(1, 22)
ImGuiInputFlags.CondActive                       = bit.lshift(1, 23)

ImGuiInputFlags.CondDefault_                   = bit.bor(ImGuiInputFlags.CondHovered, ImGuiInputFlags.CondActive)
ImGuiInputFlags.RepeatRateMask_                = bit.bor(ImGuiInputFlags.RepeatRateDefault, ImGuiInputFlags.RepeatRateNavMove, ImGuiInputFlags.RepeatRateNavTweak)
ImGuiInputFlags.RepeatUntilMask_               = bit.bor(ImGuiInputFlags.RepeatUntilRelease, ImGuiInputFlags.RepeatUntilKeyModsChange, ImGuiInputFlags.RepeatUntilKeyModsChangeFromNone, ImGuiInputFlags.RepeatUntilOtherKeyPress)
ImGuiInputFlags.RepeatMask_                    = bit.bor(ImGuiInputFlags.Repeat, ImGuiInputFlags.RepeatRateMask_, ImGuiInputFlags.RepeatUntilMask_)
ImGuiInputFlags.CondMask_                      = bit.bor(ImGuiInputFlags.CondHovered, ImGuiInputFlags.CondActive)
ImGuiInputFlags.RouteTypeMask_                 = bit.bor(ImGuiInputFlags.RouteActive, ImGuiInputFlags.RouteFocused, ImGuiInputFlags.RouteGlobal, ImGuiInputFlags.RouteAlways)
ImGuiInputFlags.RouteOptionsMask_              = bit.bor(ImGuiInputFlags.RouteOverFocused, ImGuiInputFlags.RouteOverActive, ImGuiInputFlags.RouteUnlessBgFocused, ImGuiInputFlags.RouteFromRootWindow)
ImGuiInputFlags.SupportedByIsKeyPressed        = ImGuiInputFlags.RepeatMask_
ImGuiInputFlags.SupportedByIsMouseClicked      = ImGuiInputFlags.Repeat
ImGuiInputFlags.SupportedByShortcut            = bit.bor(ImGuiInputFlags.RepeatMask_, ImGuiInputFlags.RouteTypeMask_, ImGuiInputFlags.RouteOptionsMask_)
ImGuiInputFlags.SupportedBySetNextItemShortcut = bit.bor(ImGuiInputFlags.RepeatMask_, ImGuiInputFlags.RouteTypeMask_, ImGuiInputFlags.RouteOptionsMask_, ImGuiInputFlags.Tooltip)
ImGuiInputFlags.SupportedBySetKeyOwner         = bit.bor(ImGuiInputFlags.LockThisFrame, ImGuiInputFlags.LockUntilRelease)
ImGuiInputFlags.SupportedBySetItemKeyOwner     = bit.bor(ImGuiInputFlags.SupportedBySetKeyOwner, ImGuiInputFlags.CondMask_)

--- @enum ImGuiAxis
ImGuiAxis = {
    None = -1,
    X    = 0,
    Y    = 1
}

--- @enum ImGuiPlotType
ImGuiPlotType = {
    Lines     = 0,
    Histogram = 1
}

--- @enum ImGuiActivateFlags
ImGuiActivateFlags = {
    None               = 0,
    PreferInput        = bit.lshift(1, 0), -- Favor activation that requires keyboard text input (e.g. for Slider/Drag). Default for Enter key
    PreferTweak        = bit.lshift(1, 1), -- Favor activation for tweaking with arrows or gamepad (e.g. for Slider/Drag). Default for Space key and if keyboard is not used
    TryToPreserveState = bit.lshift(1, 2), -- Request widget to preserve state if it can (e.g. InputText will try to preserve cursor/selection)
    FromTabbing        = bit.lshift(1, 3), -- Activation requested by a tabbing request (ImGuiNavMoveFlags_IsTabbing)
    FromShortcut       = bit.lshift(1, 4), -- Activation requested by an item shortcut via SetNextItemShortcut() function
    FromFocusApi       = bit.lshift(1, 5)  -- Activation requested by an api request (ImGuiNavMoveFlags_FocusApi)
}

--- @enum ImGuiScrollFlags
ImGuiScrollFlags = {
    None               = 0,
    KeepVisibleEdgeX   = bit.lshift(1, 0),
    KeepVisibleEdgeY   = bit.lshift(1, 1),
    KeepVisibleCenterX = bit.lshift(1, 2),
    KeepVisibleCenterY = bit.lshift(1, 3),
    AlwaysCenterX      = bit.lshift(1, 4),
    AlwaysCenterY      = bit.lshift(1, 5),
    NoScrollParent     = bit.lshift(1, 6),
}

ImGuiScrollFlags.MaskX_ = bit.bor(ImGuiScrollFlags.KeepVisibleEdgeX, ImGuiScrollFlags.KeepVisibleCenterX, ImGuiScrollFlags.AlwaysCenterX)
ImGuiScrollFlags.MaskY_ = bit.bor(ImGuiScrollFlags.KeepVisibleEdgeY, ImGuiScrollFlags.KeepVisibleCenterY, ImGuiScrollFlags.AlwaysCenterY)

--- @class ImGuiGroupData
--- @field WindowID                             ImGuiID
--- @field BackupCursorPos                      ImVec2
--- @field BackupCursorMaxPos                   ImVec2
--- @field BackupCursorPosPrevLine              ImVec2
--- @field BackupIndent                         ImVec1
--- @field BackupGroupOffset                    ImVec1
--- @field BackupCurrLineSize                   ImVec2
--- @field BackupCurrLineTextBaseOffset         float
--- @field BackupActiveIdIsAlive                ImGuiID
--- @field BackupActiveIdHasBeenEditedThisFrame bool
--- @field BackupDeactivatedIdIsAlive           bool
--- @field BackupHoveredIdIsAlive               bool
--- @field BackupIsSameLine                     bool
--- @field EmitItem                             bool

--- @return ImGuiGroupData
--- @nodiscard
function ImGuiGroupData()
    return {
        WindowID                             = nil,
        BackupCursorPos                      = ImVec2(),
        BackupCursorMaxPos                   = ImVec2(),
        BackupCursorPosPrevLine              = ImVec2(),
        BackupIndent                         = ImVec1(),
        BackupGroupOffset                    = ImVec1(),
        BackupCurrLineSize                   = ImVec2(),
        BackupCurrLineTextBaseOffset         = nil,
        BackupActiveIdIsAlive                = nil,
        BackupActiveIdHasBeenEditedThisFrame = nil,
        BackupDeactivatedIdIsAlive           = nil,
        BackupHoveredIdIsAlive               = nil,
        BackupIsSameLine                     = nil,
        EmitItem                             = nil
    }
end

--- @enum ImGuiTooltipFlags
ImGuiTooltipFlags = {
    None             = 0,
    OverridePrevious = bit.lshift(1, 1)
}

--- @enum ImGuiPopupPositionPolicy
ImGuiPopupPositionPolicy = {
    Default  = 0,
    ComboBox = 1,
    Tooltip  = 2
}

--- @class ImGuiPopupData
--- @field PopupId          ImGuiID
--- @field Window           ImGuiWindow
--- @field RestoreNavWindow ImGuiWindow
--- @field ParentNavLayer   int
--- @field OpenFrameCount   int
--- @field OpenParentId     ImGuiID
--- @field OpenPopupPos     ImVec2
--- @field OpenMousePos     ImVec2

--- @return ImGuiPopupData
--- @nodiscard
function ImGuiPopupData()
    return {
        PopupId          = 0,
        Window           = nil,
        RestoreNavWindow = nil,
        ParentNavLayer   = -1,
        OpenFrameCount   = -1,
        OpenParentId     = 0,
        OpenPopupPos     = ImVec2(),
        OpenMousePos     = ImVec2()
    }
end

--- @enum ImGuiWindowRefreshFlags
ImGuiWindowRefreshFlags = {
    None              = 0,
    TryToAvoidRefresh = bit.lshift(1, 0),
    RefreshOnHover    = bit.lshift(1, 1),
    RefreshOnFocus    = bit.lshift(1, 2)
}

--- @enum ImGuiNavRenderCursorFlags
ImGuiNavRenderCursorFlags = {
    None       = 0,
    Compact    = bit.lshift(1, 1), -- Compact highlight, no padding/distance from focused item
    AlwaysDraw = bit.lshift(1, 2), -- Draw rectangular highlight if (g.NavId == id) even when g.NavCursorVisible == false, aka even when using the mouse
    NoRounding = bit.lshift(1, 3),
}

--- @enum ImGuiDebugLogFlags
ImGuiDebugLogFlags = {
    -- Event types
    None              = 0,
    EventError        = bit.lshift(1, 0), -- Error submitted by IM_ASSERT_USER_ERROR()
    EventActiveId     = bit.lshift(1, 1),
    EventFocus        = bit.lshift(1, 2),
    EventPopup        = bit.lshift(1, 3),
    EventNav          = bit.lshift(1, 4),
    EventClipper      = bit.lshift(1, 5),
    EventSelection    = bit.lshift(1, 6),
    EventIO           = bit.lshift(1, 7),
    EventFont         = bit.lshift(1, 8),
    EventInputRouting = bit.lshift(1, 9),
    EventDocking      = bit.lshift(1, 10),
    EventViewport     = bit.lshift(1, 11),

    OutputToTTY        = bit.lshift(1, 20), -- Also send output to TTY
    OutputToDebugger   = bit.lshift(1, 21), -- Also send output to Debugger Console
    OutputToTestEngine = bit.lshift(1, 22), -- Also send output to Dear ImGui Test Engine
}

ImGuiDebugLogFlags.EventMask_ = bit.bor(
    ImGuiDebugLogFlags.EventError,
    ImGuiDebugLogFlags.EventActiveId,
    ImGuiDebugLogFlags.EventFocus,
    ImGuiDebugLogFlags.EventPopup,
    ImGuiDebugLogFlags.EventNav,
    ImGuiDebugLogFlags.EventClipper,
    ImGuiDebugLogFlags.EventSelection,
    ImGuiDebugLogFlags.EventIO,
    ImGuiDebugLogFlags.EventFont,
    ImGuiDebugLogFlags.EventInputRouting,
    ImGuiDebugLogFlags.EventDocking,
    ImGuiDebugLogFlags.EventViewport
)

--- @enum ImGuiLocKey
ImGuiLocKey = {
    VersionStr                    = 1,
    TableSizeOne                  = 2,
    TableSizeAllFit               = 3,
    TableSizeAllDefault           = 4,
    TableResetOrder               = 5,
    WindowingMainMenuBar          = 6,
    WindowingPopup                = 7,
    WindowingUntitled             = 8,
    OpenLink_s                    = 9,
    CopyLink                      = 10,
    DockingHideTabBar             = 11,
    DockingHoldShiftToDock        = 12,
    DockingDragToUndockOrMoveNode = 13,
    COUNT                         = 13
}

--- @class ImGuiLocEntry
--- @field Key  ImGuiLocKey
--- @field Text string

--- @param key ImGuiLocKey
--- @return string
function ImGui.LocalizeGetMsg(key)
    local g = GImGui
    local msg = g.LocalizationTable[key]
    if msg then return msg else return "*Missing Text*" end
end

--- @param id ImGuiID
function ImGui.TempInputIsActive(id)
    local g = GImGui
    return g.ActiveId == id and g.TempInputId == id
end

--- @param id ImGuiID
--- @return ImGuiInputTextState?
function ImGui.GetInputTextState(id)
    local g = GImGui
    if id ~= 0 and g.InputTextState.ID == id then
        return g.InputTextState
    end
    return nil
end

-- Storage for PushFocusScope(), g.FocusScopeStack[], g.NavFocusRoute[]
--- @class ImGuiFocusScopeData
--- @field ID       ImGuiID
--- @field WindowID ImGuiID

--- @return ImGuiFocusScopeData
--- @nodiscard
function ImGuiFocusScopeData() return { ID = nil, WindowID = nil } end
