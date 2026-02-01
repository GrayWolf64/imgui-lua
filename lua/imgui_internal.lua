--- Some internal structures
-- I won't implement type checks, since I ensure that types are correct in internal usage,
-- and runtime type checking is very slow

local setmetatable = setmetatable

local MT = ImGui.GetMetatables()

local stbrp_context = IM_INCLUDE"imstb_rectpack.lua".context

IM_TABSIZE = 4

FLT_MAX = math.huge
IM_PI   = math.pi
ImAbs   = math.abs
ImFabs  = math.abs

ImMin = math.min

--- @param a ImVec2
--- @param b ImVec2
--- @return ImVec2
--- @nodiscard
function ImMinVec2(a, b) return ImVec2(math.min(a.x, b.x), math.min(a.y, b.y)) end

ImMax = math.max

--- @param a ImVec2
--- @param b ImVec2
--- @return ImVec2
--- @nodiscard
function ImMaxVec2(a, b) return ImVec2(math.max(a.x, b.x), math.max(a.y, b.y)) end

ImRound = math.Round
ImCeil  = math.ceil
ImSin   = math.sin
ImCos   = math.cos
ImAcos  = math.acos
ImSqrt  = math.sqrt

--- @param a number
--- @param b number
--- @param t number
function ImLerp(a, b, t) return ((a) + ((b) - (a)) * (t)) end

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
function ImTrunc(f) return f >= 0 and math.floor(f) or math.ceil(f) end

--- @param v ImVec2
--- @nodiscard
function ImTruncV2(v) return ImVec2(ImTrunc(v.x), ImTrunc(v.y)) end

function ImTrunc64(f) return ImTrunc(f) end

function IM_ROUNDUP_TO_EVEN(n) return (ImCeil((n) / 2) * 2) end
function ImRsqrt(x)            return (1 / ImSqrt(x))       end

function IM_TRUNC(VAL) return math.floor(VAL) end -- Positive values only!
function IM_ROUND(VAL) return math.floor(VAL + 0.5) end

function ImFloor(f) if f >= 0 or math.floor(f) == f then return math.floor(f) else return math.floor(f) - 1 end end

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

function ImSaturate(f) return ((f < 0.0 and 0.0) or (f > 1.0 and 1.0) or f) end

IM_F32_TO_INT8_SAT = function(val) return math.floor(ImSaturate(val) * 255.0 + 0.5) end

--- @param col          ImGuiCol
--- @param backup_value ImVec4
function ImGuiColorMod(col, backup_value)
    return {
        Col = col,
        BackupValue = backup_value
    }
end

--- @param lhs ImVec2
--- @return float
function ImLengthSqr(lhs) return (lhs.x * lhs.x) + (lhs.y * lhs.y) end

--- @return int?
function ImMemchr(str, char, start_pos)
    local start = start_pos or 1
    if start < 1 then start = 1 end

    local pos = string.find(str, char, start, true)

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

function IMGUI_DEBUG_LOG_FONT(_str, ...) print(string.format(_str, ...)) end

ImGuiKeyOwner_Any     = 0
ImGuiKeyOwner_NoOwner = 4294967295

--- @param button ImGuiMouseButton
--- @return ImGuiKey
function ImGui.MouseButtonToKey(button) IM_ASSERT(button >= 0 and button < ImGuiMouseButton_COUNT) return ImGuiKey_MouseLeft + button end

--- @param key ImGuiKey
function ImGui.IsNamedKey(key)
    return key >= ImGuiKey_NamedKey_BEGIN and key < ImGuiKey_NamedKey_END
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
--- @return bool
function ImGui.IsNamedKeyOrMod(key)
    return (key >= ImGuiKey_NamedKey_BEGIN and key < ImGuiKey_NamedKey_END) or key == ImGuiMod_Ctrl or key == ImGuiMod_Shift or key == ImGuiMod_Alt or key == ImGuiMod_Super
end

--- @param key ImGuiKey
function ImGui.ConvertSingleModFlagToKey(key)
    if key == ImGuiMod_Ctrl then
        return ImGuiKey_ReservedForModCtrl
    elseif key == ImGuiMod_Shift then
        return ImGuiKey_ReservedForModShift
    elseif key == ImGuiMod_Alt then
        return ImGuiKey_ReservedForModAlt
    elseif key == ImGuiMod_Super then
        return ImGuiKey_ReservedForModSuper
    end
    return key
end

--- @param ctx ImGuiContext
--- @param key ImGuiKey
function ImGui.GetKeyOwnerData(ctx, key)
    if bit.band(key, ImGuiMod_Mask_) ~= 0 then key = ImGui.ConvertSingleModFlagToKey(key) end
    IM_ASSERT(ImGui.IsNamedKey(key))
    return ctx.KeysOwnerData[key - ImGuiKey_NamedKey_BEGIN]
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

--- @param c char
--- @return bool # True if this character is a ' ' or '\t'
function ImCharIsBlankA(c) return c == 32 or c == 9 end

--- @enum ImGuiNavLayer
ImGuiNavLayer = {
    Main  = 0,
    Menu  = 1,
    COUNT = 2
}

ImGuiItemFlags_ReadOnly               = bit.lshift(1, 11)
ImGuiItemFlags_MixedValue             = bit.lshift(1, 12)
ImGuiItemFlags_NoWindowHoverableCheck = bit.lshift(1, 13)
ImGuiItemFlags_AllowOverlap           = bit.lshift(1, 14)
ImGuiItemFlags_NoNavDisableMouseHover = bit.lshift(1, 15)
ImGuiItemFlags_NoMarkEdited           = bit.lshift(1, 16)
ImGuiItemFlags_NoFocus                = bit.lshift(1, 17)

ImGuiItemFlags_Inputable            = bit.lshift(1, 20)
ImGuiItemFlags_HasSelectionUserData = bit.lshift(1, 21)
ImGuiItemFlags_IsMultiSelect        = bit.lshift(1, 22)

ImGuiItemFlags_Default_ = ImGuiItemFlags_AutoClosePopups

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
function MT.ImVec1:copy() return ImVec1(self.x) end

--- @class ImRect
--- @field Min ImVec2
--- @field Max ImVec2
MT.ImRect = {}
MT.ImRect.__index = MT.ImRect

--- @nodiscard
function ImRect(a, b, c, d) if c and d then return setmetatable({Min = ImVec2(a, b), Max = ImVec2(c, d)}, MT.ImRect) end return setmetatable({Min = ImVec2(a and a.x or 0, a and a.y or 0), Max = ImVec2(b and b.x or 0, b and b.y or 0)}, MT.ImRect) end

function MT.ImRect:__eq(other) return self.Min == other.Min and self.Max == other.Max end
function MT.ImRect:__tostring() return string.format("ImRect(Min: %g,%g, Max: %g,%g)", self.Min.x, self.Min.y, self.Max.x, self.Max.y) end
function MT.ImRect:copy() return ImRect(self.Min.x, self.Min.y, self.Max.x, self.Max.y) end

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

    if other.Min then -- ImRect
        min_x = other.Min.x; min_y = other.Min.y
        max_x = other.Max.x; max_y = other.Max.y
    elseif other.z then -- ImVec4
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

function MT.ImRect:ClipWith(r)
    if r.Min then -- ImRect
        self.Min.x = ImMax(self.Min.x, r.Min.x) self.Min.y = ImMax(self.Min.y, r.Min.y)
        self.Max.x = ImMin(self.Max.x, r.Max.x) self.Max.y = ImMin(self.Max.y, r.Max.y)
    elseif r.z then -- ImVec4
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
        self:Add(p.Min)
        self:Add(p.Max)
    else
        if p.x < self.Min.x then self.Min.x = p.x end
        if p.y < self.Min.y then self.Min.y = p.y end
        if p.x > self.Max.x then self.Max.x = p.x end
        if p.y > self.Max.y then self.Max.y = p.y end
    end
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
        TempBuffer            = ImVector(),
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
--- @field BakedMap                 table<ImGuiID, any>            # GLUA: No ImGuiStorage
--- @field BakedDiscardedCount      int
--- @field PackIdMouseCursors       ImFontAtlasRectId
--- @field PackIdLinesTexData       ImFontAtlasRectId
MT.ImFontAtlasBuilder = {}
MT.ImFontAtlasBuilder.__index = MT.ImFontAtlasBuilder

--- @return ImFontAtlasBuilder
function ImFontAtlasBuilder()
    --- @type ImFontAtlasBuilder
    local this = setmetatable({}, MT.ImFontAtlasBuilder)

    this.PackContext              = stbrp_context() -- struct stbrp_context_opaque { char data[80]; };
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

--- @class ImGuiLastItemData

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
    self.ItemFlags = ImGuiItemFlags_None
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
    self.HasFlags = ImGuiNextWindowDataFlags_None
end

--- @return ImGuiNextWindowData
--- @nodiscard
function ImGuiNextWindowData()
    return setmetatable({
        HasFlags = 0,

        PosCond              = 0,
        SizeCond             = 0,
        CollapsedCond        = 0,
        PosVal               = nil,
        PosPivotVal          = nil,
        SizeVal              = nil,
        ContentSizeVal       = nil,
        ScrollVal            = nil,
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

--- @alias ImGuiNextWindowDataFlags int
ImGuiNextWindowDataFlags_None               = 0
ImGuiNextWindowDataFlags_HasPos             = bit.lshift(1, 0)
ImGuiNextWindowDataFlags_HasSize            = bit.lshift(1, 1)
ImGuiNextWindowDataFlags_HasContentSize     = bit.lshift(1, 2)
ImGuiNextWindowDataFlags_HasCollapsed       = bit.lshift(1, 3)
ImGuiNextWindowDataFlags_HasSizeConstraint  = bit.lshift(1, 4)
ImGuiNextWindowDataFlags_HasFocus           = bit.lshift(1, 5)
ImGuiNextWindowDataFlags_HasBgAlpha         = bit.lshift(1, 6)
ImGuiNextWindowDataFlags_HasScroll          = bit.lshift(1, 7)
ImGuiNextWindowDataFlags_HasWindowFlags     = bit.lshift(1, 8)
ImGuiNextWindowDataFlags_HasChildFlags      = bit.lshift(1, 9)
ImGuiNextWindowDataFlags_HasRefreshPolicy   = bit.lshift(1, 10)

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
        WindowPadding = ImVec2(8, 8),

        TouchExtraPadding = ImVec2(0, 0),
        IndentSpacing = 21.0,

        WindowRounding = 0,
        WindowBorderSize = 1,

        ScrollbarSize     = 14.0,
        ScrollbarRounding = 9.0,
        ScrollbarPadding  = 2.0,

        WindowBorderHoverPadding = 4.0,

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

        PopupBorderSize = 1.0,

        Colors = {},

        ButtonTextAlign = ImVec2(0.5, 0.5),

        WindowMinSize = ImVec2(32, 32),
        WindowTitleAlign = ImVec2(0.0, 0.5),
        WindowMenuButtonPosition = ImGuiDir.Left,

        MouseCursorScale = 1.0,

        FrameBorderSize = 1,
        ItemSpacing = ImVec2(8, 4),
        ItemInnerSpacing = ImVec2(4, 4),

        HoverFlagsForTooltipMouse = bit.bor(ImGuiHoveredFlags_Stationary, ImGuiHoveredFlags_DelayShort, ImGuiHoveredFlags_AllowWhenDisabled),
        HoverFlagsForTooltipNav = bit.bor(ImGuiHoveredFlags_NoSharedDelay, ImGuiHoveredFlags_DelayNormal, ImGuiHoveredFlags_AllowWhenDisabled),

        _NextFrameFontSizeBase = 0.0
    }

    ImGui.StyleColorsDark(this)

    return this
end

--- @class ImGuiWindowStackData

--- @return ImGuiWindowStackData
--- @nodiscard
function ImGuiWindowStackData()
    return {
        Window                              = nil,
        ParentLastItemDataBackup            = nil,
        StackSizesInBegin                   = nil,
        DisabledOverrideReenable            = nil,
        DisabledOverrideReenableAlphaBackup = nil
    }
end

--- @class ImGuiContext
--- @field CurrentWindowStack ImVector<ImGuiWindowStackData>

--- @param shared_font_atlas? ImFontAtlas
--- @return ImGuiContext
--- @nodiscard
function ImGuiContext(shared_font_atlas) -- TODO: tidy up this structure
    local this = {
        Style = ImGuiStyle(),
        ColorStack = ImVector(),

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

        IO = ImGuiIO(),
        PlatformIO = ImGuiPlatformIO(),

        MouseLastValidPos = ImVec2(),

        KeysOwnerData = {}, -- size = ImGuiKey_NamedKey_COUNT

        InputEventsQueue = ImVector(),

        InputEventsNextMouseSource = ImGuiMouseSource_Mouse,
        InputEventsNextEventId = 1,

        MovingWindow = nil,

        WheelingWindow = nil,

        ActiveIdClickOffset = ImVec2(),

        HoveredWindow = nil,
        HoveredWindowUnderMovingWindow = nil,
        HoveredIdIsDisabled = false,

        ActiveIdFromShortcut = false,

        ActiveId = 0, -- Active widget
        ActiveIdWindow = nil, -- Active window

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

        ActiveIdAllowOverlap = false,

        NavLayer = ImGuiNavLayer.Main,
        NavId = 0,
        NavWindow = nil,
        NavHighlightActivatedId = 0,
        NavCursorVisible = false,
        NavHighlightItemUnderNav = false,
        NavIdIsAlive = false,

        FrameCount = -1,

        FrameCountEnded = -1,
        FrameCountRendered = -1,

        Time = 0,

        NextItemData = ImGuiNextItemData(),
        LastItemData = ImGuiLastItemData(),
        NextWindowData = ImGuiNextWindowData(),

        Viewports = ImVector(),

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

        WindowResizeBorderExpectedRect = ImRect(),
        WindowResizeRelativeMode = false,

        TooltipOverrideCount = 0,
        TooltipPreviousWindow = nil,

        CurrentItemFlags = ImGuiItemFlags_None,

        DisabledStackSize = 0,

        ItemFlagsStack = ImVector(),

        -- Extensions
        UserTextures = ImVector(),

        -- Settings
        SettingsWindows = ImVector(),

        -- Drag and Drop
        DragDropActive = false,
        DragDropWithinSource = false,
        DragDropWithinTarget = false,
        DragDropSourceFlags = 0,
        -- TODO: 

        DebugFlashStyleColorIdx = nil,
    }

    this.IO.Fonts = (shared_font_atlas ~= nil) and shared_font_atlas or ImFontAtlas()
    if shared_font_atlas == nil then
        this.IO.Fonts.OwnerContext = this
    end

    for i = 0, ImGuiKey_NamedKey_COUNT - 1 do
        this.KeysOwnerData[i] = ImGuiKeyOwnerData()
    end

    this.IO.Ctx = this

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
--- @field CursorStartPosLossyness ImVec1
--- @field TextWrapPos             float
--- @field TextWrapPosStack        ImVector
--- @field MenuBarOffset           ImVec2
--- @field ChildWindows            ImVector<ImGuiWindow>

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
        CursorStartPosLossyness = ImVec1(),

        ItemWidth = 0,
        ItemWidthDefault = 0,
        TextWrapPos = 0,
        TextWrapPosStack = ImVector(),

        MenuBarOffset = ImVec2(),

        ChildWindows = ImVector()
    }
end

--- @class ImGuiWindow
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

        Pos = nil,
        Size = nil, -- Current size (==SizeFull or collapsed title bar size)
        SizeFull = nil,

        Active = false,
        WasActive = false,

        Collapsed = false,

        SkipItems = false,

        SkipRefresh = false,

        Appearing = false,

        Hidden = false,
        IsFallbackWindow = false,

        ResizeBorderHovered = -1,
        ResizeBorderHeld = -1,

        BeginCount = 0,
        BeginCountPreviousFrame = 0,
        BeginOrderWithinParent = 0,
        BeginOrderWithinContext = 0,

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

        ScrollbarSizes = ImVec2(),
        Scroll = ImVec2(),

        ContentSize = ImVec2(),
        ContentSizeIdeal = ImVec2(),
        ContentSizeExplicit = ImVec2(),

        AutoFitFramesX = -1, AutoFitFramesY = -1,
        AutoFitOnlyGrows = false,

        HasCloseButton = true,

        BgClickFlags = 0,

        SetWindowPosAllowFlags = 0,
        SetWindowPosVal = ImVec2(FLT_MAX, FLT_MAX),
        SetWindowPosPivot = ImVec2(FLT_MAX, FLT_MAX),
        SetWindowSizeAllowFlags = 0,
        SetWindowCollapsedAllowFlags = 0,
        SettingsOffset = -1,

        ScrollbarX = false,
        ScrollbarY = false,

        DrawList = nil,
        DrawListInst = ImDrawList(ctx.DrawListSharedData),

        RootWindow = nil,
        RootWindowPopupTree = nil,

        ParentWindow = nil,
        ParentWindowInBeginStack = nil,

        IDStack = ImVector(),

        Viewport = nil,

        --- struct IMGUI_API ImGuiWindowTempData
        DC = ImGuiWindowTempData(),

        OuterRectClipped = nil,
        InnerRect        = ImRect(),
        InnerClipRect    = ImRect(),
        WorkRect         = ImRect(),
        ParentWorkRect   = ImRect(),
        ContentRegionRect = ImRect(),

        ClipRect = nil,

        LastFrameActive = -1,
        LastTimeActive = -1.0,

        WriteAccessed = false,

        FontWindowScale = 1.0,
        FontWindowScaleParents = 1.0,

        HitTestHoleSize = ImVec2()
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
MT.ImGuiViewportP = {}
MT.ImGuiViewportP.__index = MT.ImGuiViewportP

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

--- @alias ImGuiInputSource int
ImGuiInputSource_None     = 0
ImGuiInputSource_Mouse    = 1
ImGuiInputSource_Keyboard = 2
ImGuiInputSource_Gamepad  = 3
ImGuiInputSource_COUNT    = 4

--- @class ImGuiInputEventMousePos
--- @field PosX float
--- @field PosY float
--- @field MouseSource ImGuiMouseSource

--- @return ImGuiInputEventMousePos
--- @nodiscard
function ImGuiInputEventMousePos()
    return {
        PosX = 0,
        PosY = 0,
        MouseSource = ImGuiMouseSource_Mouse
    }
end

--- @class ImGuiInputEventMouseButton
--- @field Button int
--- @field Down bool
--- @field MouseSource ImGuiMouseSource

--- @return ImGuiInputEventMouseButton
--- @nodiscard
function ImGuiInputEventMouseButton()
    return {
        Button = 0,
        Down = false,
        MouseSource = ImGuiMouseSource_Mouse
    }
end

--- @class ImGuiInputEventMouseWheel
--- @field WheelX float
--- @field WheelY float
--- @field MouseSource ImGuiMouseSource

--- @return ImGuiInputEventMouseWheel
--- @nodiscard
function ImGuiInputEventMouseWheel()
    return {
        WheelX = 0,
        WheelY = 0,
        MouseSource = ImGuiMouseSource_Mouse
    }
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
        MousePos    = nil, -- if Type == ImGuiInputEventType.MousePos
        MouseWheel  = nil, -- if Type == ImGuiInputEventType.MouseWheel
        MouseButton = nil, -- if Type == ImGuiInputEventType.MouseButton
        Key         = nil, -- if Type == ImGuiInputEventType.Key
        Text        = nil, -- if Type == ImGuiInputEventType.Text
        AppFocused  = nil, -- if Type == ImGuiInputEventType.Focus
    }
end

ImGuiKey_Keyboard_BEGIN = ImGuiKey_NamedKey_BEGIN
ImGuiKey_Keyboard_END   = ImGuiKey_GamepadStart
ImGuiKey_Gamepad_BEGIN  = ImGuiKey_GamepadStart
ImGuiKey_Gamepad_END    = ImGuiKey_GamepadRStickDown + 1
ImGuiKey_Mouse_BEGIN    = ImGuiKey_MouseLeft
ImGuiKey_Mouse_END      = ImGuiKey_MouseWheelY + 1
ImGuiKey_Aliases_BEGIN  = ImGuiKey_Mouse_BEGIN
ImGuiKey_Aliases_END    = ImGuiKey_Mouse_END

--- @enum ImGuiInputEventType
ImGuiInputEventType = {
    None        = 0,
    MousePos    = 1,
    MouseWheel  = 2,
    MouseButton = 3,
    Key         = 4,
    Text        = 5,
    Focus       = 6,
    COUNT       = 7
}

ImGuiInputFlags_RepeatRateDefault                = bit.lshift(1, 1)
ImGuiInputFlags_RepeatRateNavMove                = bit.lshift(1, 2)
ImGuiInputFlags_RepeatRateNavTweak               = bit.lshift(1, 3)
ImGuiInputFlags_RepeatUntilRelease               = bit.lshift(1, 4)
ImGuiInputFlags_RepeatUntilKeyModsChange         = bit.lshift(1, 5)
ImGuiInputFlags_RepeatUntilKeyModsChangeFromNone = bit.lshift(1, 6)
ImGuiInputFlags_RepeatUntilOtherKeyPress         = bit.lshift(1, 7)
ImGuiInputFlags_LockThisFrame                    = bit.lshift(1, 20)
ImGuiInputFlags_LockUntilRelease                 = bit.lshift(1, 21)
ImGuiInputFlags_CondHovered                      = bit.lshift(1, 22)
ImGuiInputFlags_CondActive                       = bit.lshift(1, 23)

ImGuiInputFlags_CondDefault_                   = bit.bor(ImGuiInputFlags_CondHovered, ImGuiInputFlags_CondActive)
ImGuiInputFlags_RepeatRateMask_                = bit.bor(ImGuiInputFlags_RepeatRateDefault, ImGuiInputFlags_RepeatRateNavMove, ImGuiInputFlags_RepeatRateNavTweak)
ImGuiInputFlags_RepeatUntilMask_               = bit.bor(ImGuiInputFlags_RepeatUntilRelease, ImGuiInputFlags_RepeatUntilKeyModsChange, ImGuiInputFlags_RepeatUntilKeyModsChangeFromNone, ImGuiInputFlags_RepeatUntilOtherKeyPress)
ImGuiInputFlags_RepeatMask_                    = bit.bor(ImGuiInputFlags_Repeat, ImGuiInputFlags_RepeatRateMask_, ImGuiInputFlags_RepeatUntilMask_)
ImGuiInputFlags_CondMask_                      = bit.bor(ImGuiInputFlags_CondHovered, ImGuiInputFlags_CondActive)
ImGuiInputFlags_RouteTypeMask_                 = bit.bor(ImGuiInputFlags_RouteActive, ImGuiInputFlags_RouteFocused, ImGuiInputFlags_RouteGlobal, ImGuiInputFlags_RouteAlways)
ImGuiInputFlags_RouteOptionsMask_              = bit.bor(ImGuiInputFlags_RouteOverFocused, ImGuiInputFlags_RouteOverActive, ImGuiInputFlags_RouteUnlessBgFocused, ImGuiInputFlags_RouteFromRootWindow)
ImGuiInputFlags_SupportedByIsKeyPressed        = ImGuiInputFlags_RepeatMask_
ImGuiInputFlags_SupportedByIsMouseClicked      = ImGuiInputFlags_Repeat
ImGuiInputFlags_SupportedByShortcut            = bit.bor(ImGuiInputFlags_RepeatMask_, ImGuiInputFlags_RouteTypeMask_, ImGuiInputFlags_RouteOptionsMask_)
ImGuiInputFlags_SupportedBySetNextItemShortcut = bit.bor(ImGuiInputFlags_RepeatMask_, ImGuiInputFlags_RouteTypeMask_, ImGuiInputFlags_RouteOptionsMask_, ImGuiInputFlags_Tooltip)
ImGuiInputFlags_SupportedBySetKeyOwner         = bit.bor(ImGuiInputFlags_LockThisFrame, ImGuiInputFlags_LockUntilRelease)
ImGuiInputFlags_SupportedBySetItemKeyOwner     = bit.bor(ImGuiInputFlags_SupportedBySetKeyOwner, ImGuiInputFlags_CondMask_)

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

--- @enum ImGuiWindowRefreshFlags
ImGuiWindowRefreshFlags = {
    None              = 0,
    TryToAvoidRefresh = bit.lshift(1, 0),
    RefreshOnHover    = bit.lshift(1, 1),
    RefreshOnFocus    = bit.lshift(1, 2)
}