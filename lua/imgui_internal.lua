--- ImGui Sincerely WIP
-- (internal structures/api)

-- I will avoid extensive type checks, since I ensure that types are correct in internal usage,
-- and runtime type checking is probably slow

--- @meta

local rawget = rawget

local b_and = bit.band; local b_or = bit.bor
local b_ls = bit.lshift; local b_rs = bit.rshift

local t_sort = table.sort

--- @alias ImGuiTableColumnIdx ImS16

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

IM_PI  = math.pi
ImPow  = math.pow
ImLog  = math.log
ImAbs  = math.abs
ImFabs = math.abs
ImFmod = function(a, b) if b < 0 then b = -b end; if a < 0 then return -(-a % b) else return a % b end; end

ImMin = math.min
ImMax = math.max

ImRound64 = function(val) return math.floor(val + 0.5) end -- FIXME: Positive values only

ImCeil  = math.ceil
ImSin   = math.sin
ImCos   = math.cos
ImAcos  = math.acos
ImAtan2 = math.atan2
ImSqrt  = math.sqrt

--- @generic T: number
--- @param a  T
--- @param b  T
--- @param mn T
--- @param mx T
--- @return T
function ImAddClampOverflow(a, b, mn, mx)
    if b < 0 and (a < mn - b) then return mn end
    if b > 0 and (a > mx - b) then return mx end
    return a + b
end

--- @generic T: number
--- @param a  T
--- @param b  T
--- @param mn T
--- @param mx T
--- @return T
function ImSubClampOverflow(a, b, mn, mx)
    if b > 0 and (a < mn + b) then return mn end
    if b < 0 and (a > mx + b) then return mx end
    return a - b
end

--- @param base     table
--- @param count    int
--- @param cmp_func fun(lhs, rhs): bool
ImStd.ImQsort = function(base, count, cmp_func) if count > 0 then t_sort(base, cmp_func) end end

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

--- @param f number
function ImTrunc(f) if f >= 0 then return math.floor(f) else return math.ceil(f) end end

--- @param v ImVec2
--- @nodiscard
function ImTruncV2(v) return ImVec2(ImTrunc(v.x), ImTrunc(v.y)) end

--- @param f float
function ImTrunc64(f) return ImTrunc(f) end

--- @param f float
function ImCeilFast(f)
    local i
    if f >= 0 then i = math.floor(f) else i = math.ceil(f) end -- same as `ImTrunc()`
    if f > i then return i + 1 end
    return i
end

function IM_ROUNDUP_TO_EVEN(n) return (ImCeil((n) / 2) * 2) end
function ImRsqrt(x)            return (1 / ImSqrt(x))       end

function IM_TRUNC(VAL) return math.floor(VAL) end -- Positive values only!
function IM_ROUND(VAL) return math.floor(VAL + 0.5) end

function ImFloor(f) if f >= 0 or math.floor(f) == f then return math.floor(f) else return math.floor(f) - 1 end end

--- @param v int
function ImIsPowerOfTwo(v)
    return (v ~= 0) and (b_and(v, (v - 1)) == 0)
end

function ImUpperPowerOfTwo(v)
    if v <= 0 then return 0 end
    if v <= 1 then return 1 end

    v = v - 1
    v = b_or(v, b_rs(v, 1))
    v = b_or(v, b_rs(v, 2))
    v = b_or(v, b_rs(v, 4))
    v = b_or(v, b_rs(v, 8))
    v = b_or(v, b_rs(v, 16))
    return v + 1
end

--- @param v unsigned_int
--- @return unsigned_int
function ImCountSetBits(v)
    local count = 0
    while v > 0 do
        v = b_and(v, v - 1)
        count = count + 1
    end
    return count
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

-- Uses `string.match` internally
--- @param str string
function ImAtof(str)
    return tonumber(string.match(str, "[+-]?%d*%.?%d+"))
end

--- @param s table # 1-based
--- @param c any
--- @param n int
function ImStd.memset(s, c, n)
    for i = 1, n do s[i] = c end
end

do

local _memmove = function(dest, dest_start, src, src_start, count)
    if count <= 0 then return end

    -- more compact instead of writing separate if-else and for loops
    local c = (dest == src and dest_start >= src_start)
    for i = (c and count - 1 or 0), (c and 0 or count - 1), (c and -1 or 1) do
        dest[dest_start + i] = src[src_start + i]
    end
end

if table.move then
    --- [GMod] Platform specific: the `table.move` polyfill in non-x86-64 currently uses `unpack` which will break if too many elements
    -- Remove this check when the polyfill is fixed or removed
    if not gmod or (gmod and BRANCH == "x86-64") then
        _memmove = function(dest, dest_start, src, src_start, count)
            table.move(src, src_start, src_start + count - 1, dest_start, dest)
        end
    end
end

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

function IMGUI_DEBUG_LOG_ACTIVEID(_str, ...) local g  = GImGui if b_and(g.DebugLogFlags, ImGuiDebugLogFlags.EventActiveId) ~= 0 then print(string.format(_str, ...)) end end
function IMGUI_DEBUG_LOG_POPUP(_str, ...)    local g  = GImGui if b_and(g.DebugLogFlags, ImGuiDebugLogFlags.EventPopup) ~= 0 then print(string.format(_str, ...)) end end
function IMGUI_DEBUG_LOG_FONT(_str, ...)     local g2 = GImGui if g2 and b_and(g2.DebugLogFlags, ImGuiDebugLogFlags.EventFont) ~= 0 then print(string.format(_str, ...)) end end
function IMGUI_DEBUG_LOG_VIEWPORT(_str, ...) local g  = GImGui if b_and(g.DebugLogFlags, ImGuiDebugLogFlags.EventViewport) ~= 0 then print(string.format(_str, ...)) end end

ImGuiSelectionUserData_Invalid = -1

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
    if b_and(key, ImGuiMod_Mask_) ~= 0 then key = ImGui.ConvertSingleModFlagToKey(key) end
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
    LoopX                 = b_ls(1, 0),
    LoopY                 = b_ls(1, 1),
    WrapX                 = b_ls(1, 2),
    WrapY                 = b_ls(1, 3),
    AllowCurrentNavId     = b_ls(1, 4),
    AlsoScoreVisibleSet   = b_ls(1, 5),
    ScrollToEdgeY         = b_ls(1, 6),
    Forwarded             = b_ls(1, 7),
    DebugNoResult         = b_ls(1, 8),
    FocusApi              = b_ls(1, 9),
    IsTabbing             = b_ls(1, 10),
    IsPageMove            = b_ls(1, 11),
    Activate              = b_ls(1, 12),
    NoSelect              = b_ls(1, 13),
    NoSetNavCursorVisible = b_ls(1, 14),
    NoClearActiveId       = b_ls(1, 15),
}

ImGuiNavMoveFlags.WrapMask_ = b_or(ImGuiNavMoveFlags.LoopX, ImGuiNavMoveFlags.LoopY, ImGuiNavMoveFlags.WrapX, ImGuiNavMoveFlags.WrapY)

--- @enum ImGuiNavLayer
ImGuiNavLayer = {
    Main  = 0,
    Menu  = 1,
    COUNT = 2
}

ImGuiItemFlags.ReadOnly               = b_ls(1, 11)
ImGuiItemFlags.MixedValue             = b_ls(1, 12)
ImGuiItemFlags.NoWindowHoverableCheck = b_ls(1, 13)
ImGuiItemFlags.AllowOverlap           = b_ls(1, 14)
ImGuiItemFlags.NoNavDisableMouseHover = b_ls(1, 15)
ImGuiItemFlags.NoMarkEdited           = b_ls(1, 16)
ImGuiItemFlags.NoFocus                = b_ls(1, 17)

ImGuiItemFlags.Inputable            = b_ls(1, 20)
ImGuiItemFlags.HasSelectionUserData = b_ls(1, 21)
ImGuiItemFlags.IsMultiSelect        = b_ls(1, 22)

ImGuiItemFlags.Default_ = ImGuiItemFlags.AutoClosePopups

--- @enum ImDrawTextFlags
ImDrawTextFlags = {
    None           = 0,
    CpuFineClip    = b_ls(1, 0),
    WrapKeepBlanks = b_ls(1, 1),
    StopOnNewLine  = b_ls(1, 2)
}

--- @enum ImGuiFocusRequestFlags
ImGuiFocusRequestFlags = {
    None                = 0,
    RestoreFocusedChild = b_ls(1, 0),
    UnlessBelowModal    = b_ls(1, 1)
}

--- @enum ImGuiTextFlags
ImGuiTextFlags = {
    None                       = 0,
    NoWidthForLargeClippedText = b_ls(1, 0)
}

--- @enum ImWcharClass
ImWcharClass = {
    Blank = 0,
    Punct = 1,
    Other = 2
}

--- @class ImVec1
--- @field x number
local IM_VEC1 = {}
IM_VEC1.__index = IM_VEC1

local function ImVec1(x) return setmetatable({x = x or 0}, IM_VEC1) end

function IM_VEC1:__tostring() return string.format("ImVec1(%g)", self.x) end

--- @param dest ImVec1
--- @param src  ImVec1
function ImVec1_Copy(dest, src)
    dest.x = src.x
end

--- @class ImRect
--- @field [1] ImVec2
--- @field [2] ImVec2
--- @field Min ImVec2
--- @field Max ImVec2
local IM_RECT = {}

--- @param t ImRect
--- @param k string
IM_RECT.__index = function(t, k)
    local method = IM_RECT[k]
    if method ~= nil  then return method end
    if     k == "Min" then return rawget(t, 1)
    elseif k == "Max" then return rawget(t, 2)
    end
end

--- @param t ImRect
--- @param k string
--- @param v ImVec2
IM_RECT.__newindex = function(t, k, v)
    if     k == "Min" then ImVec2_Copy(rawget(t, 1), v)
    elseif k == "Max" then ImVec2_Copy(rawget(t, 2), v)
    else IM_ASSERT(false)
    end
end

--- @nodiscard
function ImRect(a, b, c, d) if c and d then return setmetatable({ ImVec2(a, b), ImVec2(c, d) }, IM_RECT) end return setmetatable({ ImVec2(a and a.x or 0, a and a.y or 0), ImVec2(b and b.x or 0, b and b.y or 0) }, IM_RECT) end

function IM_RECT:__eq(other) return self[1] == other[1] and self[2] == other[2] end
function IM_RECT:__tostring() return string.format("ImRect(Min: %g,%g, Max: %g,%g)", self.Min.x, self.Min.y, self.Max.x, self.Max.y) end

--- @param other ImRect
function IM_RECT:Contains(other) return other[1][1] >= self[1][1] and other[2][1] <= self[2][1] and other[1][2] >= self[1][2] and other[2][2] <= self[2][2] end

--- @param p ImVec2
function IM_RECT:ContainsV2(p) return p[1] >= self[1][1] and p[2] >= self[1][2] and p[1] < self[2][1] and p[2] < self[2][2] end

--- @param p   ImVec2
--- @param pad ImVec2
function IM_RECT:ContainsWithPad(p, pad)
    return p[1] >= self[1][1] - pad[1] and p[2] >= self[1][2] - pad[2] and p[1] < self[2][1] + pad[1] and p[2] < self[2][2] + pad[2]
end

function IM_RECT:Overlaps(other)
    local min_x, min_y, max_x, max_y

    if other.Min then
        --- @cast other ImRect
        min_x = other[1][1]; min_y = other[1][2]
        max_x = other[2][1]; max_y = other[2][2]
    elseif other.z then
        --- @cast other ImVec4
        min_x = other[1]; min_y = other[2]
        max_x = other[3]; max_y = other[4]
    else
        IM_ASSERT(false)
    end

    return self[1][1] <= max_x and self[2][1] >= min_x and self[1][2] <= max_y and self[2][2] >= min_y
end

--- @nodiscard
function IM_RECT:GetCenter() return ImVec2((self[1][1] + self[2][1]) * 0.5, (self[1][2] + self[2][2]) * 0.5) end
function IM_RECT:GetWidth() return self[2][1] - self[1][1] end
function IM_RECT:GetHeight() return self[2][2] - self[1][2] end
--- @nodiscard
function IM_RECT:GetSize() return ImVec2(self[2][1] - self[1][1], self[2][2] - self[1][2]) end

--- @nodiscard
function IM_RECT:GetTL() return ImVec2(self[1][1], self[1][2]) end
--- @nodiscard
function IM_RECT:GetTR() return ImVec2(self[2][1], self[1][2]) end
--- @nodiscard
function IM_RECT:GetBL() return ImVec2(self[1][1], self[2][2]) end
--- @nodiscard
function IM_RECT:GetBR() return ImVec2(self[2][1], self[2][2]) end

--- @param r ImRect|ImVec4
function IM_RECT:ClipWith(r)
    if r.Min then
        --- @cast r ImRect
        self[1][1] = ImMax(self[1][1], r[1][1]) self[1][2] = ImMax(self[1][2], r[1][2])
        self[2][1] = ImMin(self[2][1], r[2][1]) self[2][2] = ImMin(self[2][2], r[2][2])
    elseif r.z then
        --- @cast r ImVec4
        self[1][1] = ImMax(self[1][1], r[1]) self[1][2] = ImMax(self[1][2], r[2])
        self[2][1] = ImMin(self[2][1], r[3]) self[2][2] = ImMin(self[2][2], r[4])
    else
        IM_ASSERT(false)
    end
end

--- @param r ImRect
function IM_RECT:ClipWithFull(r)
    self[1][1] = ImClamp(self[1][1], r[1][1], r[2][1]) self[1][2] = ImClamp(self[1][2], r[1][2], r[2][2])
    self[2][1] = ImClamp(self[2][1], r[1][1], r[2][1]) self[2][2] = ImClamp(self[2][2], r[1][2], r[2][2])
end

--- @param p ImRect|ImVec2
function IM_RECT:Add(p)
    if p.Min then
        --- @cast p ImRect
        self:Add(p[1])
        self:Add(p[2])
    else
        --- @cast p ImVec2
        if p[1] < self[1][1] then self[1][1] = p[1] end
        if p[2] < self[1][2] then self[1][2] = p[2] end
        if p[1] > self[2][1] then self[2][1] = p[1] end
        if p[2] > self[2][2] then self[2][2] = p[2] end
    end
end

--- @param amount float
function IM_RECT:Expand(amount)
    self[1][1] = self[1][1] - amount; self[1][2] = self[1][2] - amount
    self[2][1] = self[2][1] + amount; self[2][2] = self[2][2] + amount
end

--- @param amount ImVec2
function IM_RECT:ExpandV2(amount)
    self[1][1] = self[1][1] - amount[1]; self[1][2] = self[1][2] - amount[2]
    self[2][1] = self[2][1] + amount[1]; self[2][2] = self[2][2] + amount[2]
end

--- @nodiscard
function IM_RECT:ToVec4()
    return ImVec4(self[1][1], self[1][2], self[2][1], self[2][2])
end

--- @param d ImVec2
function IM_RECT:Translate(d)
    self[1][1] = self[1][1] + d[1]; self[1][2] = self[1][2] + d[2]
    self[2][1] = self[2][1] + d[1]; self[2][2] = self[2][2] + d[2]
end

function IM_RECT:GetArea() return (self[2][1] - self[1][1]) * (self[2][2] - self[1][2]) end

--- @nodiscard
function IM_RECT:AsVec4() return ImVec4(self[1][1], self[1][2], self[2][1], self[2][2]) end

--- @param dest ImRect
--- @param src  ImRect
function ImRect_Copy(dest, src)
    dest[1][1] = src[1][1]; dest[1][2] = src[1][2]
    dest[2][1] = src[2][1]; dest[2][2] = src[2][2]
end

--- @param dest ImRect
--- @param src  ImVec4
function ImRect_CopyFromV4(dest, src)
    dest[1][1] = src[1]; dest[1][2] = src[2]
    dest[2][1] = src[3]; dest[2][2] = src[4]
end

--- @param _ARRAY ImU32[]
--- @param _N     int
function IM_BITARRAY_TESTBIT(_ARRAY, _N)
    return b_and(_ARRAY[b_rs(_N - 1, 5) + 1], b_ls(1, b_and(_N - 1, 31))) ~= 0
end

--- @param _ARRAY ImU32[]
--- @param _N     int
function IM_BITARRAY_CLEARBIT(_ARRAY, _N)
    local idx = b_rs(_N - 1, 5) + 1
    _ARRAY[idx] = b_and(_ARRAY[idx], bit.bnot(b_ls(1, b_and(_N - 1, 31))))
end

--- @param arr ImU32[]
--- @param n   int
function ImBitArraySetBit(arr, n)
    local mask = b_ls(1, b_and(n - 1, 31))
    local idx = b_rs(n - 1, 5) + 1
    arr[idx] = b_or(arr[idx], mask)
end

--- @alias ImBitArrayForNamedKeys ImBitArray

--- NOTE: This struct is expensive to create
--- @class ImBitArray<BITCOUNT, OFFSET>
--- @field Data ImU32[]

--- @param BITCOUNT int
--- @param OFFSET?  int
--- @return ImBitArray
function ImBitArray(BITCOUNT, OFFSET)
    if OFFSET == nil then OFFSET = 0 end

    local this = { Data = {} }
    local size = b_rs(BITCOUNT + 31, 5)

    this.ClearAllBits = function(self) local data = self.Data; for i = 1, size do data[i] = 0 end end
    this.SetAllBits   = function(self) local data = self.Data; for i = 1, size do data[i] = 0xFFFFFFFF end end
    --- @param n int # 1-based
    --- @return boolean
    this.TestBit = function(self, n) n = n + OFFSET; IM_ASSERT(n >= 1 and n <= BITCOUNT); return IM_BITARRAY_TESTBIT(self.Data, n); end
    --- @param n int # 1-based
    this.SetBit  = function(self, n) IM_ASSERT(n >= 1 and n <= BITCOUNT); ImBitArraySetBit(self.Data, n); end

    this:ClearAllBits()

    return this
end

function MT.ImDrawList:PathClear() self._Path:clear() end

--- @param pos ImVec2
function MT.ImDrawList:PathLineTo(pos) self._Path:push_back(pos) end

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

--- @param col        ImU32
--- @param thickness? float
--- @param flags?     ImDrawFlags
function MT.ImDrawList:PathStroke(col, thickness, flags)
    if not thickness then thickness = 1.0 end
    if not flags     then flags     = 0   end

    self:AddPolyline(self._Path.Data, self._Path.Size, col, thickness, flags)
    self._Path.Size = 0
end

--- @param col ImU32
function ImGui.SetNextItemColorMarker(col)
    local g = GImGui
    g.NextItemData.HasFlags = b_or(g.NextItemData.HasFlags, ImGuiNextItemDataFlags.HasColorMarker)
    g.NextItemData.ColorMarker = col
end

--- @class ImDrawListSharedData
--- @field TexUvWhitePixel       ImVec2
--- @field TexUvLines            ImVec4[]
--- @field FontAtlas             ImFontAtlas
--- @field Font                  ImFont
--- @field FontSize              float
--- @field FontScale             float
--- @field CurveTessellationTol  float
--- @field CircleTessellationMaxError float
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
        CircleTessellationMaxError = 0,
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

    return this
end

--- @class ImFontAtlasBuilder
--- @field PackContext              stbrp_context
--- @field PackNodes                ImVector<stbrp_node>
--- @field Rects                    ImVector<ImTextureRect>
--- @field RectsIndex               ImVector<ImFontAtlasRectEntry>
--- @field TempBuffer               ImVector<char>
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
    this.TempBuffer               = ImVector()
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

--- Type information associated to one ImGuiDataType. Retrieve with DataTypeGetInfo()
--- @class ImGuiDataTypeInfo
--- @field Size     size_t # Size in bytes
--- @field Name     string # Short descriptive name for the type, for debugging
--- @field PrintFmt string # Default printf format for the type
--- @field ScanFmt  string # Default scanf format for the type

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

--- @class ImGuiTreeNodeStackData
--- @field ID                   ImGuiID
--- @field TreeFlags            ImGuiTreeNodeFlags
--- @field ItemFlags            ImGuiItemFlags
--- @field NavRect              ImRect
--- @field DrawLinesX1          float
--- @field DrawLinesToNodesY2   float
--- @field DrawLinesTableColumn ImGuiTableColumnIdx

--- @return ImGuiTreeNodeStackData
--- @nodiscard
local function ImGuiTreeNodeStackData()
    return {
        ID                   = nil,
        TreeFlags            = nil,
        ItemFlags            = nil,
        NavRect              = ImRect(),
        DrawLinesX1          = nil,
        DrawLinesToNodesY2   = nil,
        DrawLinesTableColumn = nil
    }
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
        RefVal            = 0,
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
    Move = b_ls(1, 0),
}

--- @enum ImGuiNextWindowDataFlags
ImGuiNextWindowDataFlags = {
    None              = 0,
    HasPos            = b_ls(1, 0),
    HasSize           = b_ls(1, 1),
    HasContentSize    = b_ls(1, 2),
    HasCollapsed      = b_ls(1, 3),
    HasSizeConstraint = b_ls(1, 4),
    HasFocus          = b_ls(1, 5),
    HasBgAlpha        = b_ls(1, 6),
    HasScroll         = b_ls(1, 7),
    HasWindowFlags    = b_ls(1, 8),
    HasChildFlags     = b_ls(1, 9),
    HasRefreshPolicy  = b_ls(1, 10),
    HasViewport       = b_ls(1, 11),
    HasDock           = b_ls(1, 12),
    HasWindowClass    = b_ls(1, 13)
}

--- @enum ImGuiLayoutType
ImGuiLayoutType = {
    Horizontal = 0,
    Vertical   = 1
}

--- @enum ImGuiSeparatorFlags
ImGuiSeparatorFlags = {
    None           = 0,
    Horizontal     = b_ls(1, 0), -- Axis default to current layout type, so generally Horizontal unless e.g. in a menu bar
    Vertical       = b_ls(1, 1),
    SpanAllColumns = b_ls(1, 2)  -- Make separator cover all columns of a legacy Columns() set
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
        DisabledAlpha = 0.60,

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

        TreeLinesFlags = ImGuiTreeNodeFlags.DrawLinesNone,
        TreeLinesSize  = 1.0,
        TreeLinesRounding = 0.0,
        MenuItemRounding = 0.0,
        SelectableRounding = 0.0,

        ColorMarkerSize = 3.0,
        ColorButtonPosition = ImGuiDir.Right,

        InputTextCursorSize = 1.0,
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

        Colors = {},

        ButtonTextAlign = ImVec2(0.5, 0.5),
        SelectableTextAlign = ImVec2(0.0, 0.0),

        WindowMinSize = ImVec2(32, 32),
        WindowTitleAlign = ImVec2(0.0, 0.5),
        WindowMenuButtonPosition = ImGuiDir.Left,
        ChildRounding = 0.0,
        ChildBorderSize = 1.0,
        PopupRounding = 0.0,
        PopupBorderSize = 1.0,

        DockingSeparatorSize = 2.0,
        MouseCursorScale = 1.0,

        ItemSpacing = ImVec2(8, 4),
        ItemInnerSpacing = ImVec2(4, 4),
        CellPadding = ImVec2(4, 2),

        ColumnsMinSpacing = 6.0,

        LogSliderDeadzone = 4.0,

        TabRounding = 5.0,
        TabBorderSize = 0.0,
        TabMinWidthBase = 1.0,
        TabMinWidthShrink = 80.0,
        TabCloseButtonMinWidthSelected = -1.0,
        TabCloseButtonMinWidthUnselected = 0.0,
        TabBarBorderSize = 1.0,
        TabBarOverlineSize = 1.0,
        TableAngledHeadersAngle = 35.0 * (IM_PI / 180.0),
        TableAngledHeadersTextAlign = ImVec2(0.5, 0.0),

        DragDropTargetRounding = 0.0,
        DragDropTargetBorderSize = 2.0,
        DragDropTargetPadding = 3.0,

        HoverFlagsForTooltipMouse = b_or(ImGuiHoveredFlags.Stationary, ImGuiHoveredFlags.DelayShort, ImGuiHoveredFlags.AllowWhenDisabled),
        HoverFlagsForTooltipNav = b_or(ImGuiHoveredFlags.NoSharedDelay, ImGuiHoveredFlags.DelayNormal, ImGuiHoveredFlags.AllowWhenDisabled),

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
--- @field EditedBefore         bool                # edited since activated
--- @field EditedThisFrame      bool                # edited this frame
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
        EditedBefore = false,
        EditedThisFrame = false,
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
local IMGUI_TEXTINDEX = {}
IMGUI_TEXTINDEX.__index = IMGUI_TEXTINDEX

function IMGUI_TEXTINDEX:clear() self.Offsets:clear(); self.EndOffset = 0; end

function IMGUI_TEXTINDEX:get_line_begin(base, n)
    return base + (self.Offsets.Size ~= 0 and self.Offsets[n] or 0)
end

function IMGUI_TEXTINDEX:get_line_end(base, n)
    return base + ((n + 1 < self.Offsets.Size) and (self.Offsets[n + 1] - 1) or self.EndOffset)
end

--- @return ImGuiTextIndex
local function ImGuiTextIndex()
    return setmetatable({ Offsets = ImVector(), EndOffset = 0 }, IMGUI_TEXTINDEX)
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
        LastEntriesBuf = {nil, nil, nil, nil, nil, nil},
    }

    for i = 1, 6 do
        this.LastEntriesBuf[i] = ImGuiDebugAllocEntry()
    end

    return this
end

--- @class ImGuiNavItemData
local _ImGuiNavItemData = {}
_ImGuiNavItemData.__index = _ImGuiNavItemData

--- @return ImGuiNavItemData
local function ImGuiNavItemData()
    return setmetatable({
        -- TODO:
    }, _ImGuiNavItemData)
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
--- @field FontAtlases                        ImVector<ImFontAtlas>
--- @field Font                               ImFont
--- @field FontBaked                          ImFontBaked?
--- @field FontSize                           float
--- @field FontSizeBase                       float
--- @field FontBakedScale                     float
--- @field FontRasterizerDensity              float
--- @field DrawListSharedData                 ImDrawListSharedData
--- @field NextItemData                       ImGuiNextItemData
--- @field LastItemData                       ImGuiLastItemData
--- @field NextWindowData                     ImGuiNextWindowData
--- @field WithinEndChildID                   ImGuiID
--- @field WithinEndPopupID                   ImGuiID
--- @field StyleVarStack                      ImVector
--- @field ActiveIdMouseButton                ImS8
--- @field Windows                            ImVector<ImGuiWindow>
--- @field WindowsFocusOrder                  ImVector<ImGuiWindow>
--- @field WindowsTempSortBuffer              ImVector<ImGuiWindow>
--- @field CurrentWindowStack                 ImVector<ImGuiWindowStackData>
--- @field FocusScopeStack                    ImVector<ImGuiFocusScopeData>
--- @field ItemFlagsStack                     ImVector<ImGuiItemFlags>
--- @field GroupStack                         ImVector<ImGuiGroupData>
--- @field OpenPopupStack                     ImVector<ImGuiPopupData>
--- @field BeginPopupStack                    ImVector<ImGuiPopupData>
--- @field TreeNodeStack                      ImVector<ImGuiTreeNodeStackData>
--- @field IO                                 ImGuiIO
--- @field PlatformIO                         ImGuiPlatformIO
--- @field Viewports                          ImVector<ImGuiViewportP>
--- @field DebugLogFlags                      ImGuiDebugLogFlags
--- @field DebugFlashStyleColorIdx            ImGuiCol
--- @field ColorEditCurrentID                 ImGuiID                        # Set temporarily while inside of the parent-most ColorEdit4/ColorPicker4 (because they call each others)
--- @field ColorEditSavedID                   ImGuiID                        # ID we are saving/restoring HS for
--- @field ColorEditSavedHue                  float                          # Backup of last Hue associated to LastColor, so we can restore Hue in lossy RGB<>HSV round trips
--- @field ColorEditSavedSat                  float                          # Backup of last Saturation associated to LastColor, so we can restore Saturation in lossy RGB<>HSV round trips
--- @field ColorEditSavedColor                ImU32                          # RGB value with alpha set to 0
--- @field ColorPickerRef                     ImVec4                         # Initial/reference color at the time of opening the color picker
--- @field MenusIdSubmittedThisFrame          ImVector<ImGuiID>
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
--- @field UserTextures                       ImVector<ImTextureData>
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

        WindowsTempSortBuffer = ImVector(),
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

        ActiveIdWasSelected = false, ActiveIdWasSoleSelected = false,
        LastActiveIdWasSelected = false, LastActiveIdWasSoleSelected = false,

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
        NavInitResult = ImGuiNavItemData(),
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

        GcCompactAll = false,

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

        TreeNodeStack = ImVector(ImGuiTreeNodeStackData),

        WithinEndChildID = 0, WithinEndPopupID = 0,

        BeginMenuDepth = 0, BeginComboDepth = 0,

        ColorEditCurrentID = 0, ColorEditSavedID = 0,
        ColorEditSavedHue = 0.0, ColorEditSavedSat = 0.0,
        ColorEditSavedColor = 0,
        ColorPickerRef = ImVec4(),

        MenusIdSubmittedThisFrame = ImVector(),

        DrawListSharedData = ImDrawListSharedData(),

        StackSizesInBeginForCurrentWindow = nil,

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

        ActiveIdValueOnActivation = 0,
        DataTypeZeroValue = 0,

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

        FocusScopeStack = ImVector(),
        CurrentFocusScopeId = 0,
        CurrentItemFlags = ImGuiItemFlags.None,

        DisabledAlphaBackup = 0.0,
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

        DebugLogFlags = b_or(ImGuiDebugLogFlags.EventError, ImGuiDebugLogFlags.OutputToTTY),
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

--- @class ImGuiMenuColumns
--- @field TotalWidth     ImU32
--- @field NextTotalWidth ImU32
--- @field Spacing        ImU16
--- @field OffsetIcon     ImU16   # Always zero for now
--- @field OffsetLabel    ImU16   # Offsets are locked in Update()
--- @field OffsetShortcut ImU16
--- @field OffsetMark     ImU16
--- @field Widths         ImU16[] # Width of: Icon, Label, Shortcut, Mark (accumulators for current frame)
MT.ImGuiMenuColumns = {}
MT.ImGuiMenuColumns.__index = MT.ImGuiMenuColumns

--- @return ImGuiMenuColumns
local function ImGuiMenuColumns()
    return setmetatable({
        TotalWidth     = 0,
        NextTotalWidth = 0,
        Spacing        = 0,
        OffsetIcon     = 0,
        OffsetLabel    = 0,
        OffsetShortcut = 0,
        OffsetMark     = 0,
        Widths         = {0, 0, 0, 0}
    }, MT.ImGuiMenuColumns)
end

--- @class ImGuiWindowTempData
--- @field CursorPos                     ImVec2
--- @field CursorPosPrevLine             ImVec2
--- @field CursorStartPos                ImVec2
--- @field CursorMaxPos                  ImVec2
--- @field IdealMaxPos                   ImVec2
--- @field CurrLineSize                  ImVec2
--- @field PrevLineSize                  ImVec2
--- @field CurrLineTextBaseOffset        float
--- @field PrevLineTextBaseOffset        float
--- @field IsSameLine                    bool
--- @field IsSetPos                      bool
--- @field Indent                        ImVec1
--- @field ColumnsOffset                 ImVec1
--- @field GroupOffset                   ImVec1
--- @field CursorStartPosLossyness       ImVec2
--- @field TextWrapPos                   float
--- @field TextWrapPosStack              ImVector
--- @field MenuBarAppending              bool
--- @field MenuBarOffset                 ImVec2
--- @field MenuColumns                   ImGuiMenuColumns
--- @field TreeDepth                     int
--- @field TreeHasStackDataDepthMask     ImU32
--- @field TreeRecordsClippedNodesY2Mask ImU32
--- @field ChildWindows                  ImVector<ImGuiWindow>
--- @field LayoutType                    ImGuiLayoutType

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
        MenuColumns = ImGuiMenuColumns(),
        TreeDepth = 0,
        TreeHasStackDataDepthMask = nil,
        TreeRecordsClippedNodesY2Mask = nil,

        ChildWindows = ImVector(),
        StateStorage = nil,

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
--- @field StateStorage                       {[ImGuiID]: bool}
--- @field MemoryDrawListIdxCapacity          int
--- @field MemoryDrawListVtxCapacity          int
--- @field MemoryCompacted                    bool
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

        StateStorage = {},

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
function ImFontAtlasRectId_GetIndex(id) return b_and(id, ImFontAtlasRectId_IndexMask_) end

--- @param id ImFontAtlasRectId # Expects 0-based!
--- @return unsigned_int
function ImFontAtlasRectId_GetGeneration(id) return b_rs(b_and(id, ImFontAtlasRectId_GenerationMask_), ImFontAtlasRectId_GenerationShift_) end

--- @param index_idx int      # Expects 0-based!
--- @param gen_idx int
--- @return ImFontAtlasRectId # 0-based!
function ImFontAtlasRectId_Make(index_idx, gen_idx)
    IM_ASSERT(index_idx >= 0 and index_idx <= ImFontAtlasRectId_IndexMask_ and gen_idx <= b_rs(ImFontAtlasRectId_GenerationMask_, ImFontAtlasRectId_GenerationShift_))
    return b_or(index_idx, b_ls(gen_idx, ImFontAtlasRectId_GenerationShift_))
end

--- @class ImFontAtlasPostProcessData
--- @field FontAtlas   ImFontAtlas
--- @field Font        ImFont
--- @field FontSrc     ImFontConfig
--- @field FontBaked   ImFontBaked
--- @field Glyph       ImFontGlyph
--- @field Pixels      unsigned_char[]
--- @field _PixelsBase int             # LUA: in cpp code the `Pixels` is a pointer. we can do this to avoid creating another custom structure to mimic it
--- @field Format      ImTextureFormat
--- @field Pitch       int
--- @field Width       int
--- @field Height      int

--- @param atlas       ImFontAtlas
--- @param font        ImFont
--- @param font_src    ImFontConfig
--- @param font_baked  ImFontBaked
--- @param glyph       ImFontGlyph
--- @param pixels      unsigned_char[]
--- @param pixels_base int
--- @param format      ImTextureFormat
--- @param pitch       int
--- @param width       int
--- @param height      int
--- @return ImFontAtlasPostProcessData
--- @nodiscard
function ImFontAtlasPostProcessData(atlas, font, font_src, font_baked, glyph, pixels, pixels_base, format, pitch, width, height)
    return {
        FontAtlas = atlas,
        Font      = font,
        FontSrc   = font_src,
        FontBaked = font_baked,
        Glyph     = glyph,

        Pixels = pixels,
        _PixelsBase = pixels_base,
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

--- @class ImGuiInputEventAppFocused
--- @field Focused bool

--- @return ImGuiInputEventAppFocused
--- @nodiscard
function ImGuiInputEventAppFocused()
    return { Focused = nil }
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
        MousePos      = nil, -- if Type == ImGuiInputEventType.MousePos
        MouseWheel    = nil, -- if Type == ImGuiInputEventType.MouseWheel
        MouseButton   = nil, -- if Type == ImGuiInputEventType.MouseButton
        MouseViewport = nil, -- if Type == ImGuiInputEventType.MouseViewport
        Key           = nil, -- if Type == ImGuiInputEventType.Key
        Text          = nil, -- if Type == ImGuiInputEventType.Text
        AppFocused    = nil, -- if Type == ImGuiInputEventType.Focus
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

ImGuiInputFlags.RepeatRateDefault                = b_ls(1, 1)
ImGuiInputFlags.RepeatRateNavMove                = b_ls(1, 2)
ImGuiInputFlags.RepeatRateNavTweak               = b_ls(1, 3)
ImGuiInputFlags.RepeatUntilRelease               = b_ls(1, 4)
ImGuiInputFlags.RepeatUntilKeyModsChange         = b_ls(1, 5)
ImGuiInputFlags.RepeatUntilKeyModsChangeFromNone = b_ls(1, 6)
ImGuiInputFlags.RepeatUntilOtherKeyPress         = b_ls(1, 7)
ImGuiInputFlags.LockThisFrame                    = b_ls(1, 20)
ImGuiInputFlags.LockUntilRelease                 = b_ls(1, 21)
ImGuiInputFlags.CondHovered                      = b_ls(1, 22)
ImGuiInputFlags.CondActive                       = b_ls(1, 23)

ImGuiInputFlags.CondDefault_                   = b_or(ImGuiInputFlags.CondHovered, ImGuiInputFlags.CondActive)
ImGuiInputFlags.RepeatRateMask_                = b_or(ImGuiInputFlags.RepeatRateDefault, ImGuiInputFlags.RepeatRateNavMove, ImGuiInputFlags.RepeatRateNavTweak)
ImGuiInputFlags.RepeatUntilMask_               = b_or(ImGuiInputFlags.RepeatUntilRelease, ImGuiInputFlags.RepeatUntilKeyModsChange, ImGuiInputFlags.RepeatUntilKeyModsChangeFromNone, ImGuiInputFlags.RepeatUntilOtherKeyPress)
ImGuiInputFlags.RepeatMask_                    = b_or(ImGuiInputFlags.Repeat, ImGuiInputFlags.RepeatRateMask_, ImGuiInputFlags.RepeatUntilMask_)
ImGuiInputFlags.CondMask_                      = b_or(ImGuiInputFlags.CondHovered, ImGuiInputFlags.CondActive)
ImGuiInputFlags.RouteTypeMask_                 = b_or(ImGuiInputFlags.RouteActive, ImGuiInputFlags.RouteFocused, ImGuiInputFlags.RouteGlobal, ImGuiInputFlags.RouteAlways)
ImGuiInputFlags.RouteOptionsMask_              = b_or(ImGuiInputFlags.RouteOverFocused, ImGuiInputFlags.RouteOverActive, ImGuiInputFlags.RouteUnlessBgFocused, ImGuiInputFlags.RouteFromRootWindow)
ImGuiInputFlags.SupportedByIsKeyPressed        = ImGuiInputFlags.RepeatMask_
ImGuiInputFlags.SupportedByIsMouseClicked      = ImGuiInputFlags.Repeat
ImGuiInputFlags.SupportedByShortcut            = b_or(ImGuiInputFlags.RepeatMask_, ImGuiInputFlags.RouteTypeMask_, ImGuiInputFlags.RouteOptionsMask_)
ImGuiInputFlags.SupportedBySetNextItemShortcut = b_or(ImGuiInputFlags.RepeatMask_, ImGuiInputFlags.RouteTypeMask_, ImGuiInputFlags.RouteOptionsMask_, ImGuiInputFlags.Tooltip)
ImGuiInputFlags.SupportedBySetKeyOwner         = b_or(ImGuiInputFlags.LockThisFrame, ImGuiInputFlags.LockUntilRelease)
ImGuiInputFlags.SupportedBySetItemKeyOwner     = b_or(ImGuiInputFlags.SupportedBySetKeyOwner, ImGuiInputFlags.CondMask_)

ImGuiAxis = { None = 0, X = 1, Y = 2 } --- @enum ImGuiAxis

ImGuiPlotType = { Lines = 0, Histogram = 1 } --- @enum ImGuiPlotType

--- @enum ImGuiActivateFlags
ImGuiActivateFlags = {
    None               = 0,
    PreferInput        = b_ls(1, 0),
    PreferTweak        = b_ls(1, 1),
    TryToPreserveState = b_ls(1, 2),
    FromTabbing        = b_ls(1, 3),
    FromShortcut       = b_ls(1, 4),
    FromFocusApi       = b_ls(1, 5)
}

--- @enum ImGuiScrollFlags
ImGuiScrollFlags = {
    None               = 0,
    KeepVisibleEdgeX   = b_ls(1, 0),
    KeepVisibleEdgeY   = b_ls(1, 1),
    KeepVisibleCenterX = b_ls(1, 2),
    KeepVisibleCenterY = b_ls(1, 3),
    AlwaysCenterX      = b_ls(1, 4),
    AlwaysCenterY      = b_ls(1, 5),
    NoScrollParent     = b_ls(1, 6),
}

ImGuiScrollFlags.MaskX_ = b_or(ImGuiScrollFlags.KeepVisibleEdgeX, ImGuiScrollFlags.KeepVisibleCenterX, ImGuiScrollFlags.AlwaysCenterX)
ImGuiScrollFlags.MaskY_ = b_or(ImGuiScrollFlags.KeepVisibleEdgeY, ImGuiScrollFlags.KeepVisibleCenterY, ImGuiScrollFlags.AlwaysCenterY)

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
    OverridePrevious = b_ls(1, 1)
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
    TryToAvoidRefresh = b_ls(1, 0),
    RefreshOnHover    = b_ls(1, 1),
    RefreshOnFocus    = b_ls(1, 2)
}

--- @enum ImGuiNavRenderCursorFlags
ImGuiNavRenderCursorFlags = {
    None       = 0,
    Compact    = b_ls(1, 1), -- Compact highlight, no padding/distance from focused item
    AlwaysDraw = b_ls(1, 2), -- Draw rectangular highlight if (g.NavId == id) even when g.NavCursorVisible == false, aka even when using the mouse
}

--- @enum ImGuiDebugLogFlags
ImGuiDebugLogFlags = {
    -- Event types
    None              = 0,
    EventError        = b_ls(1, 0), -- Error submitted by IM_ASSERT_USER_ERROR()
    EventActiveId     = b_ls(1, 1),
    EventFocus        = b_ls(1, 2),
    EventPopup        = b_ls(1, 3),
    EventNav          = b_ls(1, 4),
    EventClipper      = b_ls(1, 5),
    EventSelection    = b_ls(1, 6),
    EventIO           = b_ls(1, 7),
    EventFont         = b_ls(1, 8),
    EventInputRouting = b_ls(1, 9),
    EventDocking      = b_ls(1, 10),
    EventViewport     = b_ls(1, 11),
    EventTable        = b_ls(1, 12),

    OutputToTTY        = b_ls(1, 20),
    OutputToDebugger   = b_ls(1, 21),
    OutputToTestEngine = b_ls(1, 22),
}

ImGuiDebugLogFlags.EventMask_ = b_or(
    ImGuiDebugLogFlags.EventError,
    ImGuiDebugLogFlags.EventActiveId,
    ImGuiDebugLogFlags.EventFocus,
    ImGuiDebugLogFlags.EventPopup,
    ImGuiDebugLogFlags.EventNav,
    ImGuiDebugLogFlags.EventClipper,
    ImGuiDebugLogFlags.EventSelection,
    ImGuiDebugLogFlags.EventTable,
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
    TableReset                    = 5,
    TableResetOrder               = 6,
    TableResetVisibility          = 7,
    WindowingMainMenuBar          = 8,
    WindowingPopup                = 9,
    WindowingUntitled             = 10,
    OpenLink_s                    = 11,
    CopyLink                      = 12,
    DockingHideTabBar             = 13,
    DockingHoldShiftToDock        = 14,
    DockingDragToUndockOrMoveNode = 15,
    COUNT                         = 15
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
