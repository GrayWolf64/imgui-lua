--- @alias ImU32 integer
--- @alias float number
--- @alias unsigned_int integer
--- @alias int integer
--- @alias unsigned_short integer

local function IM_ASSERT(_EXPR, _MSG) assert((_EXPR), _MSG) end

--- XXX: ptr
#IMGUI_DEFINE ptr_index_get(p, i)    p.data[p.offset + i + 1]
#IMGUI_DEFINE ptr_index_set(p, i, v) p.data[p.offset + i + 1] = v

local function memcpy(_dst, _src, _cnt)
    for i = 0, _cnt - 1 do
        ptr_index_set(_dst, i, ptr_index_get(_src, i))
    end
end

local function memset(_dst, _val, _cnt)
    for i = 0, _cnt - 1 do
        ptr_index_set(_dst, i, _val)
    end
end

#IMGUI_DEFINE IM_DRAWLIST_TEX_LINES_WIDTH_MAX 32
#IMGUI_DEFINE ImFontAtlasRectId_Invalid -1
#IMGUI_DEFINE ImTextureID_Invalid 0

#IMGUI_DEFINE ImTextureFormat_RGBA32 0
#IMGUI_DEFINE ImTextureFormat_Alpha8 1

#IMGUI_DEFINE struct_def(_name) local MT = MT or {} MT[_name] = {} MT[_name].__index = MT[_name]

#IMGUI_DEFINE IM_DELETE(_t) _t = nil

--- enum ImTextureStatus
#IMGUI_DEFINE ImTextureStatus_OK          0
#IMGUI_DEFINE ImTextureStatus_Destroyed   1
#IMGUI_DEFINE ImTextureStatus_WantCreate  2
#IMGUI_DEFINE ImTextureStatus_WantUpdates 3
#IMGUI_DEFINE ImTextureStatus_WantDestroy 4

--- @enum ImFontAtlasFlags
ImFontAtlasFlags = {
    None               = 0,
    NoPowerOfTwoHeight = bit.lshift(1, 0),
    NoMouseCursors     = bit.lshift(1, 1),
    NoBakedLines       = bit.lshift(1, 2)
}

local function ImTextureRect(x, y, w, h)
    return {
        x = x, y = y,
        w = w, h = h
    }
end

--- @class ImVec2
--- @field x number
--- @field y number
struct_def("ImVec2")

--- @param x number?
--- @param y number?
--- @return ImVec2
--- @nodiscard
local function ImVec2(x, y) return setmetatable({x = x or 0, y = y or 0}, MT.ImVec2) end

function MT.ImVec2:__add(other) return ImVec2(self.x + other.x, self.y + other.y) end
function MT.ImVec2:__sub(other) return ImVec2(self.x - other.x, self.y - other.y) end
function MT.ImVec2:__mul(other) if isnumber(self) then return ImVec2(self * other.x, self * other.y) elseif isnumber(other) then return ImVec2(self.x * other, self.y * other) else return ImVec2(self.x * other.x, self.y * other.y) end end
function MT.ImVec2:__eq(other) return self.x == other.x and self.y == other.y end
function MT.ImVec2:__tostring() return string.format("ImVec2(%g, %g)", self.x, self.y) end
function MT.ImVec2:copy() return ImVec2(self.x, self.y) end

--- @class ImVec4
--- @field x number
--- @field y number
--- @field z number
--- @field w number
struct_def("ImVec4")

--- @return ImVec4
--- @nodiscard
local function ImVec4(x, y, z, w) return setmetatable({x = x or 0, y = y or 0, z = z or 0, w = w or 0}, MT.ImVec4) end

function MT.ImVec4:__add(other) return ImVec4(self.x + other.x, self.y + other.y, self.z + other.z, self.w + other.w) end
function MT.ImVec4:__sub(other) return ImVec4(self.x - other.x, self.y - other.y, self.z - other.z, self.w - other.w) end
function MT.ImVec4:__mul(other) if isnumber(self) then return ImVec4(self * other.x, self * other.y, self * other.z, self * other.w) elseif isnumber(other) then return ImVec4(self.x * other, self.y * other, self.z * other, self.w * other) else return ImVec4(self.x * other.x, self.y * other.y, self.z * other.z, self.w * other.w) end end
function MT.ImVec4:__eq(other) return self.x == other.x and self.y == other.y and self.z == other.z and self.w == other.w end

--- A compact ImVector clone, maybe
--- @class ImVector
struct_def("ImVector")

function MT.ImVector:push_back(value) self.Size = self.Size + 1 self.Data[self.Size] = value end
function MT.ImVector:pop_back() if self.Size == 0 then return nil end local value = self.Data[self.Size] self.Data[self.Size] = nil self.Size = self.Size - 1 return value end
function MT.ImVector:clear() self.Size = 0 end
function MT.ImVector:clear_delete() for i = 1, self.Size do self.Data[i] = nil end self.Size = 0 end
function MT.ImVector:empty() return self.Size == 0 end
function MT.ImVector:back() if self.Size == 0 then return nil end return self.Data[self.Size] end
function MT.ImVector:erase(i) if i < 1 or i > self.Size then return nil end local removed = table.remove(self.Data, i) self.Size = self.Size - 1 return removed end
function MT.ImVector:at(i) if i < 1 or i > self.Size then return nil end return self.Data[i] end
function MT.ImVector:iter() local i, n = 0, self.Size return function() i = i + 1 if i <= n then return i, self.Data[i] end end end
function MT.ImVector:find_index(value) for i = 1, self.Size do if self.Data[i] == value then return i end end return 0 end
function MT.ImVector:erase_unsorted(index) if index < 1 or index > self.Size then return false end local last_idx = self.Size if index ~= last_idx then self.Data[index] = self.Data[last_idx] end self.Data[last_idx] = nil self.Size = self.Size - 1 return true end
function MT.ImVector:find_erase_unsorted(value) local idx = self:find_index(value) if idx > 0 then return self:erase_unsorted(idx) end return false end
function MT.ImVector:reserve() return end
function MT.ImVector:reserve_discard() return end
function MT.ImVector:shrink() return end
function MT.ImVector:resize(new_size) self.Size = new_size end
function MT.ImVector:swap(other) self.Size, other.Size = other.Size, self.Size self.Data, other.Data = other.Data, self.Data end

--- @return ImVector
--- @nodiscard
local function ImVector() return setmetatable({Data = {}, Size = 0}, MT.ImVector) end

--- @class ImDrawCmd
struct_def("ImDrawCmd")

--- @return ImDrawCmd
--- @nodiscard
local function ImDrawCmd()
    return setmetatable({
        ClipRect = ImVec4(),
        VtxOffset = 0,
        IdxOffset = 0,
        ElemCount = 0
    }, MT.ImDrawCmd) -- TODO: callback
end

--- @class ImDrawVert

--- @return ImDrawVert
--- @nodiscard
local function ImDrawVert()
    return {
        pos = ImVec2(),
        uv  = nil,
        col = nil
    }
end

--- @class ImDrawCmdHeader
struct_def("ImDrawCmdHeader")

--- @return ImDrawCmdHeader
--- @nodiscard
local function ImDrawCmdHeader()
    return setmetatable({
        ClipRect = ImVec4(),
        VtxOffset = 0
    }, MT.ImDrawCmdHeader)
end

--- @class ImDrawList
struct_def("ImDrawList")

--- @return ImDrawList
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
        _TextureStack = ImVector(),

        _FringeScale = 0
    }, MT.ImDrawList)
end

--- @class ImDrawData
struct_def("ImDrawData")

--- @return ImDrawData
local function ImDrawData()
    return setmetatable({
        Valid = false,
        CmdListsCount = 0,
        TotalIdxCount = 0,
        TotalVtxCount = 0,
        CmdLists = ImVector(),
        DisplayPos = ImVec2(),
        DisplaySize = ImVec2()
    }, MT.ImDrawData)
end

--- @class ImTextureData
struct_def("ImTextureData")

--- @return ImTextureData
--- @nodiscard
local function ImTextureData()
    local this = setmetatable({
        UniqueID             = nil,
        Status               = nil,
        BackendUserData      = nil,
        TexID                = ImTextureID_Invalid,
        Format               = nil,
        Width                = nil,
        Height               = nil,
        BytesPerPixel        = nil,
        Pixels               = {data = {}, offset = 0}, -- XXX: ptr: unsigned char
        UsedRect             = ImTextureRect(),
        UpdateRect           = ImTextureRect(),
        Updates              = ImVector(),
        UnusedFrames         = nil,
        RefCount             = nil,
        UseColors            = nil,
        WantDestroyNextFrame = nil
    }, MT.ImTextureData)

    this.Status = ImTextureStatus_Destroyed
    this.TexID = ImTextureID_Invalid

    return this
end

function MT.ImTextureData:GetPixelsAt(x, y)
    self.Pixels.offset = self.Pixels.offset + (x + y * self.Width) * self.BytesPerPixel
    return self.Pixels
end

--- @class ImTextureRef
struct_def("ImTextureRef")

--- @return ImTextureRef
--- @nodiscard
local function ImTextureRef(tex_id)
    return setmetatable({
        _TexData = nil,
        _TexID   = tex_id or ImTextureID_Invalid
    }, MT.ImTextureRef)
end

--- @class ImFontBaked
struct_def("ImFontBaked")

--- @return ImFontBaked
--- @nodiscard
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
    }, MT.ImFontBaked)
end

--- @class ImFont
struct_def("ImFont")

--- @return ImFont
--- @nodiscard
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
    }, MT.ImFont)
end

--- @class ImFontConfig
struct_def("ImFontConfig")

--- @return ImFontConfig
--- @nodiscard
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
    }, MT.ImFontConfig)
end

--- @class ImFontAtlas
struct_def("ImFontAtlas")

--- @return ImFontAtlas
--- @nodiscard
local function ImFontAtlas()
    local this = setmetatable({
        Flags            = 0,
        TexDesiredFormat = ImTextureFormat_RGBA32,
        TexGlyphPadding  = 1,
        TexMinWidth      = 512,
        TexMinHeight     = 128,
        TexMaxWidth      = 8192,
        TexMaxHeight     = 8192,

        TexData = nil,

        TexRef = ImTextureRef(),
        TexID  = nil,

        TexList             = ImVector(),
        Locked              = nil,
        RendererHasTextures = false,

        Fonts               = ImVector(),
        Sources             = ImVector(),
        TexUvLines          = {}, -- size = IM_DRAWLIST_TEX_LINES_WIDTH_MAX + 1
        TexNextUniqueID     = 1,
        FontNextUniqueID    = 1,
        DrawListSharedDatas = ImVector(),
        Builder             = nil,
        FontLoader          = nil,
        FontLoaderName      = nil,
        FontLoaderData      = nil,
        FontLoaderFlags     = nil,
        RefCount            = nil,
        OwnerContext        = nil
    }, MT.ImFontAtlas)

    this.TexRef._TexID = ImTextureID_Invalid

    return this
end

--- @class ImFontAtlasRect
--- @field x unsigned_short
--- @field y unsigned_short
--- @field w unsigned_short
--- @field h unsigned_short
--- @field uv0 ImVec2
--- @field uv1 ImVec2

--- @return ImFontAtlasRect
--- @nodiscard
local function ImFontAtlasRect()
    return {
        x = nil, y = nil,
        w = nil, h = nil,
        uv0 = ImVec2(),
        uv1 = ImVec2()
    }
end

--- @class ImFontGlyph
--- @field Colored boolean
--- @field Visible boolean
--- @field SourceIdx unsigned_int
--- @field Codepoint unsigned_int
--- @field AdvanceX float
--- @field X0 float
--- @field Y0 float
--- @field X1 float
--- @field Y1 float
--- @field U0 float
--- @field V0 float
--- @field U1 float
--- @field V1 float
--- @field PackId int

--- @return ImFontGlyph
--- @nodiscard
local function ImFontGlyph()
    return {
        Colored   = 0,
        Visible   = 0,
        SourceIdx = 0,
        Codepoint = 0,
        AdvanceX  = 0,

        X0 = 0, Y0 = 0, X1 = 0, Y1 = 0,
        U0 = 0, V0 = 0, U1 = 0, V1 = 0,

        PackId = -1
    }
end

--- @enum ImGuiDir
ImGuiDir = {
    Left  = 0,
    Right = 1,
    Up    = 2,
    Down  = 3
}

--- @alias ImGuiWindowFlags integer
ImGuiWindowFlags_None                      = 0
ImGuiWindowFlags_NoTitleBar                = bit.lshift(1, 0)
ImGuiWindowFlags_NoResize                  = bit.lshift(1, 1)
ImGuiWindowFlags_NoMove                    = bit.lshift(1, 2)
ImGuiWindowFlags_NoScrollbar               = bit.lshift(1, 3)
ImGuiWindowFlags_NoScrollWithMouse         = bit.lshift(1, 4)
ImGuiWindowFlags_NoCollapse                = bit.lshift(1, 5)
ImGuiWindowFlags_AlwaysAutoResize          = bit.lshift(1, 6)
ImGuiWindowFlags_NoBackground              = bit.lshift(1, 7)
ImGuiWindowFlags_NoSavedSettings           = bit.lshift(1, 8)
ImGuiWindowFlags_NoMouseInputs             = bit.lshift(1, 9)
ImGuiWindowFlags_MenuBar                   = bit.lshift(1, 10)
ImGuiWindowFlags_HorizontalScrollbar       = bit.lshift(1, 11)
ImGuiWindowFlags_NoFocusOnAppearing        = bit.lshift(1, 12)
ImGuiWindowFlags_NoBringToFrontOnFocus     = bit.lshift(1, 13)
ImGuiWindowFlags_AlwaysVerticalScrollbar   = bit.lshift(1, 14)
ImGuiWindowFlags_AlwaysHorizontalScrollbar = bit.lshift(1, 15)
ImGuiWindowFlags_NoNavInputs               = bit.lshift(1, 16)
ImGuiWindowFlags_NoNavFocus                = bit.lshift(1, 17)
ImGuiWindowFlags_UnsavedDocument           = bit.lshift(1, 18)
ImGuiWindowFlags_ChildWindow               = bit.lshift(1, 24)
ImGuiWindowFlags_Tooltip                   = bit.lshift(1, 25)
ImGuiWindowFlags_Popup                     = bit.lshift(1, 26)
ImGuiWindowFlags_Modal                     = bit.lshift(1, 27)
ImGuiWindowFlags_ChildMenu                 = bit.lshift(1, 28)
ImGuiWindowFlags_NoNav                     = bit.bor(ImGuiWindowFlags_NoNavInputs, ImGuiWindowFlags_NoNavFocus)
ImGuiWindowFlags_NoDecoration              = bit.bor(ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoResize, ImGuiWindowFlags_NoScrollbar, ImGuiWindowFlags_NoCollapse)
ImGuiWindowFlags_NoInputs                  = bit.bor(ImGuiWindowFlags_NoMouseInputs, ImGuiWindowFlags_NoNavInputs, ImGuiWindowFlags_NoNavFocus)

--- @alias ImGuiItemFlags integer
ImGuiItemFlags_None              = 0
ImGuiItemFlags_NoTabStop         = bit.lshift(1, 0)
ImGuiItemFlags_NoNav             = bit.lshift(1, 1)
ImGuiItemFlags_NoNavDefaultFocus = bit.lshift(1, 2)
ImGuiItemFlags_ButtonRepeat      = bit.lshift(1, 3)
ImGuiItemFlags_AutoClosePopups   = bit.lshift(1, 4)
ImGuiItemFlags_AllowDuplicateID  = bit.lshift(1, 5)

--- @alias ImGuiItemStatusFlags integer
ImGuiItemStatusFlags_None             = 0
ImGuiItemStatusFlags_HoveredRect      = bit.lshift(1, 0)
ImGuiItemStatusFlags_HasDisplayRect   = bit.lshift(1, 1)
ImGuiItemStatusFlags_Edited           = bit.lshift(1, 2)
ImGuiItemStatusFlags_ToggledSelection = bit.lshift(1, 3)
ImGuiItemStatusFlags_ToggledOpen      = bit.lshift(1, 4)
ImGuiItemStatusFlags_HasDeactivated   = bit.lshift(1, 5)
ImGuiItemStatusFlags_Deactivated      = bit.lshift(1, 6)
ImGuiItemStatusFlags_HoveredWindow    = bit.lshift(1, 7)
ImGuiItemStatusFlags_Visible          = bit.lshift(1, 8)
ImGuiItemStatusFlags_HasClipRect      = bit.lshift(1, 9)
ImGuiItemStatusFlags_HasShortcut      = bit.lshift(1, 10)

--- @alias ImDrawFlags integer
ImDrawFlags_None                    = 0
ImDrawFlags_Closed                  = bit.lshift(1, 0)
ImDrawFlags_RoundCornersTopLeft     = bit.lshift(1, 4)
ImDrawFlags_RoundCornersTopRight    = bit.lshift(1, 5)
ImDrawFlags_RoundCornersBottomLeft  = bit.lshift(1, 6)
ImDrawFlags_RoundCornersBottomRight = bit.lshift(1, 7)
ImDrawFlags_RoundCornersNone        = bit.lshift(1, 8)
ImDrawFlags_RoundCornersTop         = bit.bor(ImDrawFlags_RoundCornersTopLeft, ImDrawFlags_RoundCornersTopRight)
ImDrawFlags_RoundCornersBottom      = bit.bor(ImDrawFlags_RoundCornersBottomLeft, ImDrawFlags_RoundCornersBottomRight)
ImDrawFlags_RoundCornersLeft        = bit.bor(ImDrawFlags_RoundCornersBottomLeft, ImDrawFlags_RoundCornersTopLeft)
ImDrawFlags_RoundCornersRight       = bit.bor(ImDrawFlags_RoundCornersBottomRight, ImDrawFlags_RoundCornersTopRight)
ImDrawFlags_RoundCornersAll         = bit.bor(ImDrawFlags_RoundCornersTopLeft, ImDrawFlags_RoundCornersTopRight, ImDrawFlags_RoundCornersBottomLeft, ImDrawFlags_RoundCornersBottomRight)
ImDrawFlags_RoundCornersMask        = bit.bor(ImDrawFlags_RoundCornersAll, ImDrawFlags_RoundCornersNone)
ImDrawFlags_RoundCornersDefault     = ImDrawFlags_RoundCornersAll

--- @alias ImDrawListFlags integer
ImDrawListFlags_None                   = 0
ImDrawListFlags_AntiAliasedLines       = bit.lshift(1, 0)
ImDrawListFlags_AntiAliasedLinesUseTex = bit.lshift(1, 1)
ImDrawListFlags_AntiAliasedFill        = bit.lshift(1, 2)
ImDrawListFlags_AllowVtxOffset         = bit.lshift(1, 3)

--- @alias ImFontFlags integer
ImFontFlags_None           = 0
ImFontFlags_NoLoadError    = bit.lshift(1, 1)
ImFontFlags_NoLoadGlyphs   = bit.lshift(1, 2)
ImFontFlags_LockBakedSizes = bit.lshift(1, 3)

#IMGUI_DEFINE IM_COL32_R_SHIFT 0
#IMGUI_DEFINE IM_COL32_G_SHIFT 8
#IMGUI_DEFINE IM_COL32_B_SHIFT 16
#IMGUI_DEFINE IM_COL32_A_SHIFT 24
#IMGUI_DEFINE IM_COL32_A_MASK  0xFF000000

#IMGUI_DEFINE IM_COL32(R, G, B, A) (bit.bor(bit.lshift(A, IM_COL32_A_SHIFT), bit.lshift(B, IM_COL32_B_SHIFT), bit.lshift(G, IM_COL32_G_SHIFT), bit.lshift(R, IM_COL32_R_SHIFT)))
#IMGUI_DEFINE IM_COL32_WHITE       IM_COL32(255, 255, 255, 255)
#IMGUI_DEFINE IM_COL32_BLACK       IM_COL32(0, 0, 0, 255)
#IMGUI_DEFINE IM_COL32_BLACK_TRANS IM_COL32(0, 0, 0, 0)
