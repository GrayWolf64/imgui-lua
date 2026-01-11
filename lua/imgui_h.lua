--- @alias ImU8           integer
--- @alias ImU32          integer
--- @alias float          number
--- @alias unsigned_int   integer
--- @alias int            integer
--- @alias unsigned_short integer

--- @alias ImWchar16 unsigned_short
--- @alias ImWchar   ImWchar16

--- @alias bool boolean

--- @alias ImGuiID unsigned_int

----------------------------------------------------------------
-- [SECTION] METATABLE MANAGEMENT
----------------------------------------------------------------

--- File-scope metatable storage
--- @type table<string, table>
local MT = {}

--- @param _EXPR boolean
--- @param _MSG string?
function IM_ASSERT(_EXPR, _MSG) assert((_EXPR), _MSG) end

----------------------------------------------------------------
-- [SECTION] C POINTER / ARRAY LIKE OPERATIONS SUPPORT
----------------------------------------------------------------

--- @class ImSlice
--- @field data table
--- @field offset integer

--- @param _data table?
--- @return ImSlice
function IM_SLICE(_data) return {data = _data or {}, offset = 0} end

--- @param p ImSlice
--- @param i integer
--- @return any
function IM_SLICE_GET(p, i) return p.data[p.offset + i + 1] end

--- @param p ImSlice
--- @param i integer
--- @param v any
function IM_SLICE_SET(p, i, v) p.data[p.offset + i + 1] = v end

--- @param p ImSlice
--- @param n integer?
function IM_SLICE_INC(p, n) p.offset = p.offset + (n or 1) end

--- @param _dst ImSlice
--- @param _src ImSlice
--- @param _cnt integer
function IM_SLICE_COPY(_dst, _src, _cnt)
    for i = 0, _cnt - 1 do
        IM_SLICE_SET(_dst, i, IM_SLICE_GET(_src, i))
    end
end

--- @param _dst ImSlice
--- @param _val any
--- @param _cnt integer
function IM_SLICE_FILL(_dst, _val, _cnt)
    for i = 0, _cnt - 1 do
        IM_SLICE_SET(_dst, i, _val)
    end
end

IM_DRAWLIST_TEX_LINES_WIDTH_MAX = 32
ImFontAtlasRectId_Invalid       = -1
ImTextureID_Invalid             = 0

--- @enum ImTextureFormat
ImTextureFormat = {
    RGBA32 = 0,
    Alpha8 = 1
}

--- @enum ImTextureStatus
ImTextureStatus = {
    OK          = 0,
    Destroyed   = 1,
    WantCreate  = 2,
    WantUpdates = 3,
    WantDestroy = 4
}

--- @enum ImFontAtlasFlags
ImFontAtlasFlags = {
    None               = 0,
    NoPowerOfTwoHeight = bit.lshift(1, 0),
    NoMouseCursors     = bit.lshift(1, 1),
    NoBakedLines       = bit.lshift(1, 2)
}

--- @class ImTextureRect
--- @field x unsigned_short
--- @field y unsigned_short
--- @field w unsigned_short
--- @field h unsigned_short

--- @param x unsigned_short?
--- @param y unsigned_short?
--- @param w unsigned_short?
--- @param h unsigned_short?
--- @return ImTextureRect
function ImTextureRect(x, y, w, h)
    return {
        x = x, y = y,
        w = w, h = h
    }
end

--- @class ImVec2
--- @field x number
--- @field y number
MT.ImVec2 = {}
MT.ImVec2.__index = MT.ImVec2

--- @param x number?
--- @param y number?
--- @return ImVec2
--- @nodiscard
function ImVec2(x, y) return setmetatable({x = x or 0, y = y or 0}, MT.ImVec2) end

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
MT.ImVec4 = {}
MT.ImVec4.__index = MT.ImVec4

--- @return ImVec4
--- @nodiscard
function ImVec4(x, y, z, w) return setmetatable({x = x or 0, y = y or 0, z = z or 0, w = w or 0}, MT.ImVec4) end

function MT.ImVec4:__add(other) return ImVec4(self.x + other.x, self.y + other.y, self.z + other.z, self.w + other.w) end
function MT.ImVec4:__sub(other) return ImVec4(self.x - other.x, self.y - other.y, self.z - other.z, self.w - other.w) end
function MT.ImVec4:__mul(other) if isnumber(self) then return ImVec4(self * other.x, self * other.y, self * other.z, self * other.w) elseif isnumber(other) then return ImVec4(self.x * other, self.y * other, self.z * other, self.w * other) else return ImVec4(self.x * other.x, self.y * other.y, self.z * other.z, self.w * other.w) end end
function MT.ImVec4:__eq(other) return self.x == other.x and self.y == other.y and self.z == other.z and self.w == other.w end

--- A compact ImVector clone
--- @class ImVector
MT.ImVector = {}
MT.ImVector.__index = MT.ImVector

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
function ImVector() return setmetatable({Data = {}, Size = 0}, MT.ImVector) end

--- @class ImDrawCmd
MT.ImDrawCmd = {}
MT.ImDrawCmd.__index = MT.ImDrawCmd

--- @return ImDrawCmd
--- @nodiscard
function ImDrawCmd()
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
function ImDrawVert()
    return {
        pos = ImVec2(),
        uv  = nil,
        col = nil
    }
end

--- @class ImDrawCmdHeader
MT.ImDrawCmdHeader = {}
MT.ImDrawCmdHeader.__index = MT.ImDrawCmdHeader

--- @return ImDrawCmdHeader
--- @nodiscard
function ImDrawCmdHeader()
    return setmetatable({
        ClipRect = ImVec4(),
        VtxOffset = 0
    }, MT.ImDrawCmdHeader)
end

--- @class ImDrawList
MT.ImDrawList = {}
MT.ImDrawList.__index = MT.ImDrawList

--- @return ImDrawList
function ImDrawList(data)
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
MT.ImDrawData = {}
MT.ImDrawData.__index = MT.ImDrawData

--- @return ImDrawData
function ImDrawData()
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
MT.ImTextureData = {}
MT.ImTextureData.__index = MT.ImTextureData

--- @return ImTextureData
--- @nodiscard
function ImTextureData()
    local this = setmetatable({
        UniqueID             = nil,
        Status               = nil,
        BackendUserData      = nil,
        TexID                = ImTextureID_Invalid,
        Format               = nil,
        Width                = nil,
        Height               = nil,
        BytesPerPixel        = nil,
        Pixels               = IM_SLICE(), -- XXX: ptr: unsigned char
        UsedRect             = ImTextureRect(),
        UpdateRect           = ImTextureRect(),
        Updates              = ImVector(),
        UnusedFrames         = nil,
        RefCount             = nil,
        UseColors            = nil,
        WantDestroyNextFrame = nil
    }, MT.ImTextureData)

    this.Status = ImTextureStatus.Destroyed
    this.TexID = ImTextureID_Invalid

    return this
end

function MT.ImTextureData:GetPixelsAt(x, y)
    self.Pixels.offset = self.Pixels.offset + (x + y * self.Width) * self.BytesPerPixel
    return self.Pixels
end

--- @class ImTextureRef
MT.ImTextureRef = {}
MT.ImTextureRef.__index = MT.ImTextureRef

--- @return ImTextureRef
--- @nodiscard
function ImTextureRef(tex_id)
    return setmetatable({
        _TexData = nil,
        _TexID   = tex_id or ImTextureID_Invalid
    }, MT.ImTextureRef)
end

--- @class ImFontBaked
MT.ImFontBaked = {}
MT.ImFontBaked.__index = MT.ImFontBaked

--- @return ImFontBaked
--- @nodiscard
function ImFontBaked()
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
--- @field LastBaked                ImFontBaked
--- @field OwnerAtlas               ImFontAtlas
--- @field Flags                    ImFontFlags
--- @field CurrentRasterizerDensity float
--- @field FontId                   ImGuiID
--- @field LegacySize               float
--- @field Sources                  ImVector<ImFontConfig>
--- @field EllipsisChar             ImWchar
--- @field FallbackChar             ImWchar
--- @field Used8kPagesMap           ImU8
--- @field EllipsisAutoBake         bool
--- @field Scale                    float
MT.ImFont = {}
MT.ImFont.__index = MT.ImFont

--- @return ImFont
--- @nodiscard
function ImFont()
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
        RemapPairs       = nil, -- TODO: ImGuiStorage
        Scale            = nil
    }, MT.ImFont)
end

--- @class ImFontConfig
MT.ImFontConfig = {}
MT.ImFontConfig.__index = MT.ImFontConfig

--- @return ImFontConfig
--- @nodiscard
function ImFontConfig()
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
--- @field Flags               ImFontAtlasFlags
--- @field TexDesiredFormat    ImTextureFormat
--- @field TexGlyphPadding     int
--- @field TexMinWidth         int
--- @field TexMinHeight        int
--- @field TexMaxWidth         int
--- @field TexMaxHeight        int
--- @field TexRef              ImTextureRef
--- @field TexID               ImTextureRef
--- @field TexData             ImTextureData
--- @field TexList             ImVector<ImTextureData>
--- @field Locked              bool
--- @field RenderHasTextures   bool
--- @field TexPixelsUseColors  bool
--- @field TexUvScale          ImVec2
--- @field TexUvWhitePixel     ImVec2
--- @field Fonts               ImVector<ImFont>
--- @field Sources             ImVector<ImFontConfig>
--- @field TexUvLines          ImVec4[]
--- @field TexNextUniqueID     int
--- @field FontNextUniqueID    int
--- @field DrawListSharedDatas ImVector<ImDrawListSharedData>
--- @field Builder             ImFontAtlasBuilder
--- @field FontLoader          ImFontLoader
--- @field FontLoaderName      string
--- @field FontLoaderData      any
--- @field FontLoaderFlags     unsigned_int
--- @field RefCount            int
--- @field OwnerContext        ImGuiContext
MT.ImFontAtlas = {}
MT.ImFontAtlas.__index = MT.ImFontAtlas

--- @return ImFontAtlas
--- @nodiscard
function ImFontAtlas()
    --- @type ImFontAtlas
    local this = setmetatable({}, MT.ImFontAtlas)

    this.Flags               = 0
    this.TexDesiredFormat    = ImTextureFormat.RGBA32
    this.TexGlyphPadding     = 1
    this.TexMinWidth         = 512
    this.TexMinHeight        = 128
    this.TexMaxWidth         = 8192
    this.TexMaxHeight        = 8192

    this.TexRef              = ImTextureRef()
    this.TexID               = nil

    this.TexData             = nil

    this.TexList             = ImVector()
    this.Locked              = nil
    this.RendererHasTextures = false
    this.TexPixelsUseColors  = nil
    this.TexUvScale          = nil
    this.TexUvWhitePixel     = nil
    this.Fonts               = ImVector()
    this.Sources             = ImVector()
    this.TexUvLines          = {} -- size = IM_DRAWLIST_TEX_LINES_WIDTH_MAX + 1
    this.TexNextUniqueID     = 1
    this.FontNextUniqueID    = 1
    this.DrawListSharedDatas = ImVector()
    this.Builder             = nil
    this.FontLoader          = nil
    this.FontLoaderName      = nil
    this.FontLoaderData      = nil
    this.FontLoaderFlags     = nil
    this.RefCount            = nil
    this.OwnerContext        = nil

    this.TexRef._TexID       = ImTextureID_Invalid

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
function ImFontAtlasRect()
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

--- @enum ImFontFlags
ImFontFlags = {
    None           = 0,
    NoLoadError    = bit.lshift(1, 1),
    NoLoadGlyphs   = bit.lshift(1, 2),
    LockBakedSizes = bit.lshift(1, 3)
}

IM_COL32_R_SHIFT = 0
IM_COL32_G_SHIFT = 8
IM_COL32_B_SHIFT = 16
IM_COL32_A_SHIFT = 24
IM_COL32_A_MASK  = 0xFF000000

--- @param R ImU32
--- @param G ImU32
--- @param B ImU32
--- @param A ImU32
IM_COL32             = function(R, G, B, A) return (bit.bor(bit.lshift(A, IM_COL32_A_SHIFT), bit.lshift(B, IM_COL32_B_SHIFT), bit.lshift(G, IM_COL32_G_SHIFT), bit.lshift(R, IM_COL32_R_SHIFT))) end
IM_COL32_WHITE       = IM_COL32(255, 255, 255, 255)
IM_COL32_BLACK       = IM_COL32(0, 0, 0, 255)
IM_COL32_BLACK_TRANS = IM_COL32(0, 0, 0, 0)

return MT