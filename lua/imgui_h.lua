--- ImGui Sincerely WIP
-- (Definitions)

--- @meta

--- @alias ImU8           integer
--- @alias ImU16          integer
--- @alias ImU32          integer
--- @alias ImU64          integer
--- @alias ImS8           integer
--- @alias ImS64          integer
--- @alias float          number

--- @alias int            integer
--- @alias unsigned_int   integer

--- @alias short          integer
--- @alias unsigned_short integer

--- @alias size_t unsigned_int

--- @alias char          integer
--- @alias unsigned_char integer

--- @alias ImWchar16 unsigned_short
--- @alias ImWchar   ImWchar16

--- @alias bool boolean

--- @alias ImGuiID unsigned_int

--- @alias ImTextureID ImU64

--- @alias ImGuiKeyChord int

--- @alias ImDrawIdx unsigned_int

IM_UNICODE_CODEPOINT_INVALID = 0xFFFD
IM_UNICODE_CODEPOINT_MAX     = 0xFFFF

---------------------------------------------------------------------------------------
-- [SECTION] METATABLE MANAGEMENT
---------------------------------------------------------------------------------------

--- File-scope metatable storage
local MT = {}

function ImGui.GetMetatables() return MT end

--- @param _EXPR boolean|nil
--- @param _MSG string?
function IM_ASSERT(_EXPR, _MSG) assert((_EXPR), _MSG) end

IM_ASSERT_PARANOID = IM_ASSERT

---------------------------------------------------------------------------------------
-- [SECTION] C POINTER / ARRAY LIKE OPERATIONS SUPPORT
---------------------------------------------------------------------------------------

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

--- @param p ImSlice
function IM_SLICE_RESET(p) p.offset = 0 end

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

--- @param x? unsigned_short
--- @param y? unsigned_short
--- @param w? unsigned_short
--- @param h? unsigned_short
--- @return ImTextureRect
function ImTextureRect(x, y, w, h)
    return {
        x = x, y = y,
        w = w, h = h
    }
end

-- This structure supports indexing on string keys `x`, `y` and number keys `ImGuiAxis.X`, `ImGuiAxis.Y`.
-- But note that the later is likely to be more expensive.
--- @class ImVec2
--- @field x number
--- @field y number
MT.ImVec2 = {}
MT.ImVec2.__index = function(t, k)
    if k == ImGuiAxis.X then
        return rawget(t, "x")
    elseif k == ImGuiAxis.Y then
        return rawget(t, "y")
    end
end

MT.ImVec2.__newindex = function(t, k, v)
    if k == ImGuiAxis.X then
        rawset(t, "x", v)
    elseif k == ImGuiAxis.Y then
        rawset(t, "y", v)
    end
end

--- @param x? number
--- @param y? number
--- @return ImVec2
--- @nodiscard
function ImVec2(x, y) return setmetatable({x = x or 0, y = y or 0}, MT.ImVec2) end

function MT.ImVec2:__add(other) return ImVec2(self.x + other.x, self.y + other.y) end
function MT.ImVec2:__sub(other) return ImVec2(self.x - other.x, self.y - other.y) end
function MT.ImVec2:__mul(other) if type(self) == "number" then return ImVec2(self * other.x, self * other.y) elseif type(other) == "number" then return ImVec2(self.x * other, self.y * other) else return ImVec2(self.x * other.x, self.y * other.y) end end
function MT.ImVec2:__eq(other) return self.x == other.x and self.y == other.y end
function MT.ImVec2:__tostring() return string.format("ImVec2(%g, %g)", self.x, self.y) end

--- @param dest ImVec2
--- @param src  ImVec2
function ImVec2_Copy(dest, src)
    dest.x = src.x; dest.y = src.y
end

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
function MT.ImVec4:__mul(other) if type(self) == "number" then return ImVec4(self * other.x, self * other.y, self * other.z, self * other.w) elseif type(other) == "number" then return ImVec4(self.x * other, self.y * other, self.z * other, self.w * other) else return ImVec4(self.x * other.x, self.y * other.y, self.z * other.z, self.w * other.w) end end
function MT.ImVec4:__eq(other) return self.x == other.x and self.y == other.y and self.z == other.z and self.w == other.w end
function MT.ImVec4:__tostring() return string.format("ImVec4(%g, %g, %g, %g)", self.x, self.y, self.z, self.w) end

--- @param dest ImVec4
--- @param src  ImVec4
function ImVec4_Copy(dest, src)
    dest.x = src.x; dest.y = src.y; dest.z = src.z; dest.w = src.w
end

--- A compact ImVector clone
--- @class ImVector
--- @field Data table # 1-based table
--- @field Size int   # >= 0
MT.ImVector = {}
MT.ImVector.__index = MT.ImVector

--- @return ImVector
--- @nodiscard
function ImVector() return setmetatable({Data = {}, Size = 0}, MT.ImVector) end

function MT.ImVector:push_back(value) self.Size = self.Size + 1 self.Data[self.Size] = value return value end
function MT.ImVector:pop_back() IM_ASSERT(self.Size > 0) local value = self.Data[self.Size] self.Data[self.Size] = nil self.Size = self.Size - 1 return value end
function MT.ImVector:clear() self.Size = 0 end
function MT.ImVector:clear_delete() for i = 1, self.Size do self.Data[i] = nil end self.Size = 0 end
function MT.ImVector:empty() return self.Size == 0 end
function MT.ImVector:back()   IM_ASSERT(self.Size > 0) return self.Data[self.Size] end
function MT.ImVector:erase(i) IM_ASSERT(i >= 1 and i <= self.Size) local removed = table.remove(self.Data, i) self.Size = self.Size - 1 return removed end
function MT.ImVector:at(i)    IM_ASSERT(i >= 1 and i <= self.Size) return self.Data[i] end
local function _iter(v, i) i = i + 1 if i <= v.Size then return i, v.Data[i] end end
function MT.ImVector:iter() return _iter, self, 0 end
function MT.ImVector:find_index(value) for i = 1, self.Size do if self.Data[i] == value then return i end end return nil end
function MT.ImVector:erase_unsorted(index) IM_ASSERT(i >= 1 and i <= self.Size) local last_idx = self.Size if index ~= last_idx then self.Data[index] = self.Data[last_idx] end self.Data[last_idx] = nil self.Size = self.Size - 1 return true end
function MT.ImVector:find_erase_unsorted(value) local idx = self:find_index(value) if idx then return self:erase_unsorted(idx) end return false end
function MT.ImVector:reserve(new_capacity) return end
function MT.ImVector:reserve_discard(new_capacity) return end
function MT.ImVector:shrink(new_size) IM_ASSERT(new_size <= self.Size) self.Size = new_size end
function MT.ImVector:resize(new_size, v) local old_size = self.Size if new_size > old_size and v ~= nil then for i = old_size + 1, new_size do self.Data[i] = v end end self.Size = new_size end
function MT.ImVector:swap(other) self.Size, other.Size = other.Size, self.Size self.Data, other.Data = other.Data, self.Data end
function MT.ImVector:contains(v) for i = 1, self.Size do if self.Data[i] == v then return true end return false end end
function MT.ImVector:insert(pos, value) IM_ASSERT(pos >= 1 and pos <= self.Size + 1) for i = self.Size, pos, -1 do self.Data[i + 1] = self.Data[i] end self.Data[pos] = value self.Size = self.Size + 1 return value end

--- @nodiscard
function MT.ImVector:copy() local other = ImVector() other.Size = self.Size for i = 1, self.Size do other.Data[i] = self.Data[i] end return other end

--- @return int # 0-based index
function MT.ImVector:index_from_ptr(p)
    local data = self.Data
    local size = self.Size
    local mid = bit.rshift(size, 1)

    for i = size, mid + 1, -1 do
        if data[i] == p then
            return i - 1
        end
    end

    for i = mid, 1, -1 do
        if data[i] == p then
            return i - 1
        end
    end

    --- @diagnostic disable-next-line
    assert(false, "index_from_ptr failed!")
end

function MT.ImVector:ptr_from_offset(offset)
    if offset < 0 or offset >= self.Size then
        return nil
    end
    return self.Data[offset + 1]
end

--- @class ImDrawCmd
MT.ImDrawCmd = {}
MT.ImDrawCmd.__index = MT.ImDrawCmd

--- @return ImDrawCmd
--- @nodiscard
function ImDrawCmd()
    return setmetatable({
        ClipRect               = ImVec4(),
        TexRef                 = nil,
        VtxOffset              = 0,
        IdxOffset              = 0,
        ElemCount              = 0,
        UserCallback           = nil,
        UserCallbackData       = nil,
        UserCallbackDataSize   = 0,
        UserCallbackDataOffset = 0
    }, MT.ImDrawCmd)
end

--- @return ImTextureID
function MT.ImDrawCmd:GetTexID()
    local tex_id = (self.TexRef._TexData) and self.TexRef._TexData.TexID or self.TexRef._TexID
    if self.TexRef._TexData ~= nil then
        IM_ASSERT(tex_id ~= ImTextureID_Invalid, "ImDrawCmd is referring to ImTextureData that wasn't uploaded to graphics system. Backend must call ImTextureData::SetTexID() after handling ImTextureStatus_WantCreate request!")
    end
    return tex_id
end

--- @class ImDrawVert
--- @field pos ImVec2
--- @field uv  ImVec2
--- @field col ImU32

--- @return ImDrawVert
--- @nodiscard
function ImDrawVert()
    return {
        pos = ImVec2(),
        uv  = ImVec2(),
        col = nil
    }
end

--- @class ImDrawCmdHeader
--- @field ClipRect  ImVec4
--- @field TexRef    ImTextureRef
--- @field VtxOffset unsigned_int
MT.ImDrawCmdHeader = {}
MT.ImDrawCmdHeader.__index = MT.ImDrawCmdHeader

--- @return ImDrawCmdHeader
--- @nodiscard
function ImDrawCmdHeader()
    return setmetatable({
        ClipRect  = ImVec4(),
        TexRef    = nil,
        VtxOffset = 0
    }, MT.ImDrawCmdHeader)
end

--- @class ImDrawChannel
--- @field _CmdBuffer ImVector<ImDrawCmd>
--- @field _IdxBuffer ImVector<ImDrawIdx>

--- @return ImDrawChannel
--- @nodiscard
function ImDrawChannel()
    return {
        _CmdBuffer = ImVector(),
        _IdxBuffer = ImVector()
    }
end

--- @class ImDrawListSplitter
--- @field _Current  int
--- @field _Count    int
--- @field _Channels ImVector<ImDrawChannel>

--- @return ImDrawListSplitter
--- @nodiscard
function ImDrawListSplitter()
    return {
        _Current  = 0,
        _Count    = 0,
        _Channels = ImVector()
    }
end

--- @class ImDrawList
--- @field CmdBuffer         ImVector<ImDrawCmd>
--- @field IdxBuffer         ImVector<ImDrawIdx>
--- @field VtxBuffer         ImVector<ImDrawVert>
--- @field Flags             ImDrawListFlags
--- @field _VtxCurrentIdx    unsigned_int         # 1-based, generally == (VtxBuffer.Size + 1)
--- @field _Data             ImDrawListSharedData # Pointes to shared draw data
--- @field _VtxWritePtr      unsigned_int         # 1-based, points to the current writing index in VtxBuffer.Data
--- @field _IdxWritePtr      unsigned_int         # 1-based, points to the current writing index in IdxBuffer.Data
--- @field _Path             ImVector<ImVec2>     # current path building
--- @field _CmdHeader        ImDrawCmdHeader      # template of active commands. Fields should match those of CmdBuffer:back()
--- @field _Splitter         ImDrawListSplitter
--- @field _ClipRectStack    ImVector<ImVec4>
--- @field _TextureStack     ImVector<ImTextureRef>
--- @field _CallbacksDataBuf any
--- @field _FringeScale      float
--- @field _OwnerName        string
MT.ImDrawList = {}
MT.ImDrawList.__index = MT.ImDrawList

--- @param pos ImVec2
--- @param uv  ImVec2
--- @param col ImU32
function MT.ImDrawList:PrimWriteVtx(pos, uv, col)
    local vtx = ImDrawVert()
    ImVec2_Copy(vtx.pos, pos)
    ImVec2_Copy(vtx.uv, uv)
    vtx.col = col
    self.VtxBuffer.Data[self._VtxWritePtr] = vtx
    self._VtxWritePtr = self._VtxWritePtr + 1
    self._VtxCurrentIdx = self._VtxCurrentIdx + 1
end

--- @param idx ImDrawIdx
function MT.ImDrawList:PrimWriteIdx(idx)
    self.IdxBuffer.Data[self._IdxWritePtr] = idx
    self._IdxWritePtr = self._IdxWritePtr + 1
end

--- @param pos ImVec2
--- @param uv  ImVec2
--- @param col ImU32
function MT.ImDrawList:PrimVtx(pos, uv, col)
    self:PrimWriteIdx(self._VtxCurrentIdx)
    self:PrimWriteVtx(pos, uv, col)
end

--- @param data? ImDrawListSharedData
--- @return ImDrawList
--- @nodiscard
function ImDrawList(data)
    --- @type ImDrawList
    local this = setmetatable({
        CmdBuffer = ImVector(),
        IdxBuffer = ImVector(),
        VtxBuffer = ImVector(),
        Flags     = 0,

        _VtxCurrentIdx = 1,
        _Data          = data,
        _VtxWritePtr   = 1,
        _IdxWritePtr   = 1,
        _Path          = ImVector(),
        _CmdHeader     = ImDrawCmdHeader(),
        _Splitter      = ImDrawListSplitter(),
        _ClipRectStack = ImVector(),
        _TextureStack  = ImVector(),
        _CallbacksDataBuf = nil,

        _FringeScale = 0,
        _OwnerName = nil
    }, MT.ImDrawList)

    this:_SetDrawListSharedData(data)

    return this
end

--- @class ImDrawData
--- @field Valid            bool
--- @field CmdListsCount    int
--- @field TotalIdxCount    int
--- @field TotalVtxCount    int
--- @field CmdLists         ImVector<ImDrawList>
--- @field DisplayPos       ImVec2
--- @field DisplaySize      ImVec2
--- @field FramebufferScale ImVec2
--- @field OwnerViewport    ImGuiViewport
--- @field Textures         ImVector<ImTextureData>
MT.ImDrawData = {}
MT.ImDrawData.__index = MT.ImDrawData

--- @return ImDrawData
function ImDrawData()
    --- @type ImDrawData
    local this = setmetatable({}, MT.ImDrawData)

    this.CmdLists = ImVector()
    this:Clear()

    return this
end

--- @class ImTextureData
--- @field UniqueID             int
--- @field Status               ImTextureStatus
--- @field BackendUserData      any
--- @field TexID                ImTextureID
--- @field Format               ImTextureFormat
--- @field Width                int
--- @field Height               int
--- @field BytesPerPixel        int
--- @field Pixels               ImSlice<unsigned_char>
--- @field UsedRect             ImTextureRect
--- @field UpdateRect           ImTextureRect
--- @field Updates              ImVector<ImTextureRect>
--- @field UnusedFrames         int
--- @field RefCount             unsigned_short
--- @field UseColors            bool
--- @field WantDestroyNextFrame bool
MT.ImTextureData = {}
MT.ImTextureData.__index = MT.ImTextureData

--- @return ImTextureData
--- @nodiscard
function ImTextureData()
    --- @type ImTextureData
    local this = setmetatable({}, MT.ImTextureData)

    this.UniqueID             = 0
    this.Status               = ImTextureStatus.Destroyed
    this.BackendUserData      = nil
    this.TexID                = ImTextureID_Invalid
    this.Format               = 0
    this.Width                = 0
    this.Height               = 0
    this.BytesPerPixel        = 0
    this.Pixels               = IM_SLICE()
    this.UsedRect             = ImTextureRect()
    this.UpdateRect           = ImTextureRect()
    this.Updates              = ImVector()
    this.UnusedFrames         = 0
    this.RefCount             = 0
    this.UseColors            = false
    this.WantDestroyNextFrame = false

    return this
end

--- @param x int
--- @param y int
--- @return ImSlice
--- @nodiscard
function MT.ImTextureData:GetPixelsAt(x, y)
    local pixels = IM_SLICE(self.Pixels.data)
    IM_SLICE_INC(pixels, (x + y * self.Width) * self.BytesPerPixel)
    return pixels
end

function MT.ImTextureData:GetPitch() return self.Width * self.BytesPerPixel end
function MT.ImTextureData:GetTexID() return self.TexID end

--- @param tex_id ImTextureID
function MT.ImTextureData:SetTexID(tex_id) self.TexID = tex_id end

--- @param status ImTextureStatus
function MT.ImTextureData:SetStatus(status) self.Status = status if (status == ImTextureStatus.Destroyed and not self.WantDestroyNextFrame and self.Pixels ~= nil) then self.Status = ImTextureStatus.WantCreate end end

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
--- @field IndexAdvanceX        ImVector<float>       # Glyphs->AdvanceX in a directly indexable way. Note that codepoint starts from 0, so IndexAdvanceX.Data[0 + 1] holds the advanceX of glyph at codepoint 0
--- @field FallbackAdvanceX     float
--- @field Size                 float
--- @field RasterizerDensity    float
--- @field IndexLookup          ImVector<ImU16>       # Index glyphs by Unicode codepoint. use IndexLookup.Data[codepoint + 1] for codepoint. Stores 1-based index!
--- @field Glyphs               ImVector<ImFontGlyph>
--- @field FallbackGlyphIndex   int                   # Initial value = -1, then becomes 1-based index if fallback char is set
--- @field Ascent               float
--- @field Descent              float
--- @field MetricsTotalSurface  unsigned_int
--- @field WantDestroy          bool
--- @field LoadNoFallback       bool
--- @field LoadNoRenderOnLayout bool
--- @field LastUsedFrame        int
--- @field BakedId              ImGuiID
--- @field OwnerFont            ImFont
--- @field FontLoaderDatas      any
MT.ImFontBaked = {}
MT.ImFontBaked.__index = MT.ImFontBaked

--- @return ImFontBaked
--- @nodiscard
function ImFontBaked()
    --- @type ImFontBaked
    local this = setmetatable({}, MT.ImFontBaked)

    this.IndexAdvanceX     = ImVector()
    this.FallbackAdvanceX  = 0
    this.Size              = 0
    this.RasterizerDensity = 0

    this.IndexLookup        = ImVector()
    this.Glyphs             = ImVector()
    this.FallbackGlyphIndex = -1

    this.Ascent               = 0
    this.Descent              = 0
    this.MetricsTotalSurface  = 0
    this.WantDestroy          = false
    this.LoadNoFallback       = false
    this.LoadNoRenderOnLayout = false
    this.LastUsedFrame        = 0
    this.BakedId              = 0
    this.OwnerFont            = nil
    this.FontLoaderDatas      = nil

    return this
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
--- @field Used8kPagesMap           ImU8[]                 # 1-based table
--- @field EllipsisAutoBake         bool
--- @field RemapPairs               table<ImGuiID, any>    # LUA: No ImGuiStorage
--- @field Scale                    float
MT.ImFont = {}
MT.ImFont.__index = MT.ImFont

function MT.ImFont:IsLoaded() return self.OwnerAtlas ~= nil end

--- @return ImFont
--- @nodiscard
function ImFont()
    --- @type ImFont
    local this = setmetatable({}, MT.ImFont)

    this.LastBaked                = nil
    this.OwnerAtlas               = nil
    this.Flags                    = 0
    this.CurrentRasterizerDensity = 0
    this.FontId           = 0
    this.LegacySize       = 0
    this.Sources          = ImVector()
    this.EllipsisChar     = 0
    this.FallbackChar     = 0
    this.Used8kPagesMap   = {}
    this.EllipsisAutoBake = false
    this.RemapPairs       = {}
    this.Scale            = 0

    return this
end

--- @class ImFontConfig
--- @field Name                 string
--- @field FontData             ImSlice
--- @field FontDataSize         int
--- @field FontDataOwnedByAtlas bool
--- @field MergeMode            bool
--- @field PixelSnapH           bool
--- @field OversampleH          ImS8
--- @field OversampleV          ImS8
--- @field EllipsisChar         ImWchar
--- @field SizePixels           float
--- @field GlyphRanges          ImWchar[]
--- @field GlyphExcludeRanges   ImWchar[]
--- @field GlyphOffset          ImVec2
--- @field GlyphMinAdvanceX     float
--- @field GlyphMaxAdvanceX     float
--- @field GlyphExtraAdvanceX   float
--- @field FontNo               ImU32
--- @field FontLoaderFlags      unsigned_int
--- @field RasterizerMultiply   float
--- @field RasterizerDensity    float
--- @field ExtraSizeScale       float
--- @field Flags                ImFontFlags
--- @field DstFont              ImFont
--- @field FontLoader           ImFontLoader
--- @field FontLoaderData       ImGui_ImplStbTrueType_FontSrcData|
MT.ImFontConfig = {}
MT.ImFontConfig.__index = MT.ImFontConfig

--- @return ImFontConfig
--- @nodiscard
function ImFontConfig()
    --- @type ImFontConfig
    local this = setmetatable({}, MT.ImFontConfig)

    this.Name                 = nil
    this.FontData             = nil
    this.FontDataSize         = 0
    this.FontDataOwnedByAtlas = true

    this.MergeMode          = false
    this.PixelSnapH         = false
    this.OversampleH        = 0
    this.OversampleV        = 0
    this.EllipsisChar       = 0
    this.SizePixels         = 0
    this.GlyphRanges        = nil
    this.GlyphExcludeRanges = nil
    this.GlyphOffset        = ImVec2()
    this.GlyphMinAdvanceX   = 0
    this.GlyphMaxAdvanceX   = FLT_MAX
    this.GlyphExtraAdvanceX = 0
    this.FontNo             = 0
    this.FontLoaderFlags    = 0
    this.RasterizerMultiply = 1.0
    this.RasterizerDensity  = 1.0
    this.ExtraSizeScale     = 1.0

    this.Flags          = 0
    this.DstFont        = nil
    this.FontLoader     = nil
    this.FontLoaderData = nil

    return this
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
--- @field TexData             ImTextureData
--- @field TexList             ImVector<ImTextureData>
--- @field Locked              bool
--- @field RenderHasTextures   bool
--- @field TexPixelsUseColors  bool
--- @field TexUvScale          ImVec2
--- @field TexUvWhitePixel     ImVec2
--- @field Fonts               ImVector<ImFont>
--- @field Sources             ImVector<ImFontConfig>
--- @field TexUvLines          ImVec4[]                       # 0-based table
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

    this.TexData             = nil

    this.TexList             = ImVector()
    this.Locked              = false
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
    this.RefCount            = 0
    this.OwnerContext        = nil

    return this
end

--- @class ImFontAtlasRect
--- @field x   unsigned_short
--- @field y   unsigned_short
--- @field w   unsigned_short
--- @field h   unsigned_short
--- @field uv0 ImVec2
--- @field uv1 ImVec2

--- @alias ImFontAtlasRectId int

ImFontAtlasRectId_Invalid = -1

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
--- @field Colored   boolean
--- @field Visible   boolean
--- @field SourceIdx unsigned_int
--- @field Codepoint unsigned_int
--- @field AdvanceX  float
--- @field X0        float
--- @field Y0        float
--- @field X1        float
--- @field Y1        float
--- @field U0        float
--- @field V0        float
--- @field U1        float
--- @field V1        float
--- @field PackId    int

--- @return ImFontGlyph
--- @nodiscard
function ImFontGlyph()
    return {
        Colored   = false,
        Visible   = false,
        SourceIdx = 0,
        Codepoint = 0,
        AdvanceX  = 0,

        X0 = 0, Y0 = 0, X1 = 0, Y1 = 0,
        U0 = 0, V0 = 0, U1 = 0, V1 = 0,

        PackId = -1
    }
end

--- @class ImGuiKeyData
--- @field Down             bool
--- @field DownDuration     float
--- @field DownDurationPrev float
--- @field AnalogValue      float

--- @return ImGuiKeyData
--- @nodiscard
function ImGuiKeyData()
    return {
        Down             = false,
        DownDuration     = nil,
        DownDurationPrev = nil,
        AnalogValue      = nil
    }
end

--- @alias ImGuiConfigFlags int
ImGuiConfigFlags_None                   = 0
ImGuiConfigFlags_NavEnableKeyboard      = bit.lshift(1, 0)  -- Master keyboard navigation enable flag. Enable full Tabbing + directional arrows + space/enter to activate.
ImGuiConfigFlags_NavEnableGamepad       = bit.lshift(1, 1)  -- Master gamepad navigation enable flag. Backend also needs to set ImGuiBackendFlags.HasGamepad.
ImGuiConfigFlags_NoMouse                = bit.lshift(1, 4)  -- Instruct dear imgui to disable mouse inputs and interactions.
ImGuiConfigFlags_NoMouseCursorChange    = bit.lshift(1, 5)  -- Instruct backend to not alter mouse cursor shape and visibility. Use if the backend cursor changes are interfering with yours and you don't want to use SetMouseCursor() to change mouse cursor. You may want to honor requests from imgui by reading GetMouseCursor() yourself instead.
ImGuiConfigFlags_NoKeyboard             = bit.lshift(1, 6)  -- Instruct dear imgui to disable keyboard inputs and interactions. This is done by ignoring keyboard events and clearing existing states.
ImGuiConfigFlags_ViewportsEnable        = bit.lshift(1, 10)
ImGuiConfigFlags_IsSRGB                 = bit.lshift(1, 20) -- Application is SRGB-aware.
ImGuiConfigFlags_IsTouchScreen          = bit.lshift(1, 21) -- Application is using a touch screen instead of a mouse.

--- @class ImGuiIO
MT.ImGuiIO = {}
MT.ImGuiIO.__index = MT.ImGuiIO

--- @return ImGuiIO
function ImGuiIO()
    local this = {
        Ctx = nil,

        KeyCtrl  = false,
        KeyShift = false,
        KeyAlt   = false,
        KeySuper = false,

        KeyMods  = nil,

        BackendFlags = ImGuiBackendFlags.None,
        ConfigFlags  = ImGuiConfigFlags_None,
        DisplaySize = ImVec2(-1.0, -1.0),

        DeltaTime = 1.0 / 60.0,

        DisplayFramebufferScale = ImVec2(1.0, 1.0),

        MousePos = ImVec2(),
        MousePosPrev = ImVec2(),

        WantSetMousePos = false,

        MouseDelta = ImVec2(),

        MouseDown             = {[0] = false, [1] = false, [2] = false},

        MouseWheel = 0,
        MouseWheelH = 0,

        MouseCtrlLeftAsRightClick = false,

        MouseWheelRequestAxisSwap = false,

        ConfigMacOSXBehaviors = false,
        ConfigNavCursorVisibleAuto = true,
        ConfigInputTrickleEventQueue = true,
        ConfigWindowsResizeFromEdges = true,

        ConfigViewportsNoAutoMerge = false,
        ConfigViewportsNoTaskBarIcon = false,
        ConfigViewportsNoDecoration = true,
        ConfigViewportsNoDefaultParent = true,
        ConfigViewportsPlatformFocusSetsImGuiFocus = true,

        MouseDrawCursor = false,

        MouseClicked          = {[0] = false, [1] = false, [2] = false},
        MouseReleased         = {[0] = false, [1] = false, [2] = false},
        MouseClickedCount     = {[0] =  0, [1] =  0, [2] =  0},
        MouseClickedLastCount = {[0] =  0, [1] =  0, [2] =  0},
        MouseDownDuration     = {[0] = -1, [1] = -1, [2] = -1},
        MouseDownDurationPrev = {[0] = -1, [1] = -1, [2] = -1},

        MouseDownOwned    = {[0] = nil, [1] = nil, [2] = nil},
        MouseClickedTime  = {[0] = 0, [1] = 0, [2] = 0},
        MouseReleasedTime = {[0] = 0, [1] = 0, [2] = 0},
        MouseClickedPos   = {[0] = ImVec2(), [1] = ImVec2(), [2] = ImVec2()},

        MouseDoubleClicked = {[0] = false, [1] = false, [2] = false},

        MouseDoubleClickTime    = 0.30,
        MouseDoubleClickMaxDist = 6.0,
        MouseDragThreshold      = 6.0,
        KeyRepeatDelay          = 0.275,
        KeyRepeatRate           = 0.050,

        KeysData = {}, -- size = ImGuiKey.NamedKey_COUNT

        WantCaptureMouse    = nil,
        WantCaptureKeyboard = nil,
        WantTextInput       = nil,

        Framerate = 0,

        MetricsRenderWindows = 0,

        Fonts = nil,
        FontDefault = nil,

        BackendPlatformUserData = nil,
        BackendRendererUserData = nil,

        InputQueueCharacters = ImVector(),

        AppAcceptingEvents = true
    }

    for i = 0, ImGuiKey.NamedKey_COUNT - 1 do
        this.KeysData[i] = ImGuiKeyData()
    end

    return setmetatable(this, MT.ImGuiIO)
end

--- @enum ImGuiMouseCursor
ImGuiMouseCursor = {
    None       = -1,
    Arrow      = 0,
    TextInput  = 1,
    ResizeAll  = 2,
    ResizeNS   = 3,
    ResizeEW   = 4,
    ResizeNESW = 5,
    ResizeNWSE = 6,
    Hand       = 7,
    Wait       = 8,
    Progress   = 9,
    NotAllowed = 10,
    COUNT      = 11
}

--- @enum ImGuiViewportFlags
ImGuiViewportFlags = {
    None                = 0,
    IsPlatformWindow    = bit.lshift(1, 0),
    IsPlatformMonitor   = bit.lshift(1, 1),
    OwnedByApp          = bit.lshift(1, 2),
    NoDecoration        = bit.lshift(1, 3),
    NoTaskBarIcon       = bit.lshift(1, 4),
    NoFocusOnAppearing  = bit.lshift(1, 5),
    NoFocusOnClick      = bit.lshift(1, 6),
    NoInputs            = bit.lshift(1, 7),
    NoRendererClear     = bit.lshift(1, 8),
    NoAutoMerge         = bit.lshift(1, 9),
    TopMost             = bit.lshift(1, 10),
    CanHostOtherWindows = bit.lshift(1, 11),

    IsMinimized = bit.lshift(1, 12),
    IsFocused   = bit.lshift(1, 13)
}

--- @class ImGuiViewport
--- @field ID                    ImGuiID
--- @field Flags                 ImGuiViewportFlags
--- @field Pos                   ImVec2
--- @field Size                  ImVec2
--- @field FramebufferScale      ImVec2
--- @field WorkPos               ImVec2
--- @field WorkSize              ImVec2
--- @field DpiScale              float
--- @field ParentViewportId      ImGuiID
--- @field ParentViewport        ImGuiViewport
--- @field DrawData              ImDrawData
--- @field RendererUserData      any
--- @field PlatformUserData      any
--- @field PlatformHandle        any
--- @field PlatformHandleRaw     any
--- @field PlatformWindowCreated bool
--- @field PlatformRequestMove   bool
--- @field PlatformRequestResize bool
--- @field PlatformRequestClose  bool
MT.ImGuiViewport = {}
MT.ImGuiViewport.__index = MT.ImGuiViewport

function MT.ImGuiViewport:GetCenter()
    return ImVec2(self.Pos.x + self.Size.x * 0.5, self.Pos.y + self.Size.y * 0.5)
end

function MT.ImGuiViewport:GetWorkCenter()
    return ImVec2(self.WorkPos.x + self.WorkSize.x * 0.5, self.WorkPos.y + self.WorkSize.y * 0.5)
end

--- @return ImGuiViewport
--- @nodiscard
function ImGuiViewport()
    return setmetatable({
        ID       = 0,
        Flags    = 0,
        Pos      = ImVec2(),
        Size     = ImVec2(),
        FramebufferScale = ImVec2(),
        WorkPos  = ImVec2(),
        WorkSize = ImVec2(),
        DpiScale = 0,

        PlatformHandle = nil,
        PlatformHandleRaw = nil,
        PlatformWindowCreated = false
    }, MT.ImGuiViewport)
end

--- @class ImGuiPlatformIO
--- @field Platform_GetClipboardTextFn fun(ctx: ImGuiContext): string
--- @field Platform_CreateWindow       fun(vp: ImGuiViewport)
--- @field Platform_OnChangedViewport  fun(vp: ImGuiViewport)
--- @field Monitors                    ImVector<ImGuiPlatformMonitor>
--- @field Textures                    ImVector<ImTextureData>
--- @field Viewports                   ImVector<ImGuiViewport>
MT.ImGuiPlatformIO = {}
MT.ImGuiPlatformIO.__index = MT.ImGuiPlatformIO

--- @return ImGuiPlatformIO
--- @nodiscard
function ImGuiPlatformIO()
    local this = {
        Platform_GetClipboardTextFn = nil,
        Platform_SetClipboardTextFn = nil,

        Platform_OpenInShellFn = nil,
        Platform_OpenInShellUserData = nil,

        Renderer_TextureMaxWidth = 0,
        Renderer_TextureMaxHeight = 0,

        Renderer_RenderState = nil,

        Monitors = ImVector(),
        Textures = ImVector(),
        Viewports = ImVector(),

        Platform_LocaleDecimalPoint = '.',

        Platform_OnChangedViewport = nil,
    }

    return setmetatable(this, MT.ImGuiPlatformIO)
end

--- @class ImGuiPlatformMonitor
--- @field MainPos        ImVec2
--- @field MainSize       ImVec2
--- @field WorkPos        ImVec2
--- @field WorkSize       ImVec2
--- @field DpiScale       float
--- @field PlatformHandle any

--- @return ImGuiPlatformMonitor
--- @nodiscard
function ImGuiPlatformMonitor()
    return {
        MainPos  = ImVec2(0, 0),
        MainSize = ImVec2(0, 0),
        WorkPos  = ImVec2(0, 0),
        WorkSize = ImVec2(0, 0),
        DpiScale = 1.0,

        PlatformHandle = nil
    }
end

--- @enum ImGuiDir
ImGuiDir = {
    None  = -1,
    Left  = 0,
    Right = 1,
    Up    = 2,
    Down  = 3,
    COUNT = 4
}

--- @enum ImGuiMouseButton
ImGuiMouseButton = {
    Left   = 0,
    Right  = 1,
    Middle = 2,
    COUNT  = 5
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
ImGuiWindowFlags_NoDocking                 = bit.lshift(1, 19)
ImGuiWindowFlags_DockNodeHost              = bit.lshift(1, 23)
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
ImGuiItemFlags_AllowDuplicateId  = bit.lshift(1, 5)
ImGuiItemFlags_Disabled          = bit.lshift(1, 6)

--- @enum ImGuiItemStatusFlags
ImGuiItemStatusFlags = {
    None             = 0,
    HoveredRect      = bit.lshift(1, 0), -- Mouse position is within item rectangle (does NOT mean that the window is in correct z-order and can be hovered!, this is only one part of the most-common IsItemHovered test)
    HasDisplayRect   = bit.lshift(1, 1), -- g.LastItemData.DisplayRect is valid
    Edited           = bit.lshift(1, 2), -- Value exposed by item was edited in the current frame (should match the bool return value of most widgets)
    ToggledSelection = bit.lshift(1, 3), -- Set when Selectable(), TreeNode() reports toggling a selection. We can't report "Selected", only state changes, in order to easily handle clipping with less issues
    ToggledOpen      = bit.lshift(1, 4), -- Set when TreeNode() reports toggling their open state
    HasDeactivated   = bit.lshift(1, 5), -- Set if the widget/group is able to provide data for the ImGuiItemStatusFlags.Deactivated flag
    Deactivated      = bit.lshift(1, 6), -- Only valid if ImGuiItemStatusFlags.HasDeactivated is set
    HoveredWindow    = bit.lshift(1, 7), -- Override the HoveredWindow test to allow cross-window hover testing
    Visible          = bit.lshift(1, 8), -- [WIP] Set when item is overlapping the current clipping rectangle (Used internally. Please don't use yet: API/system will change as we refactor Itemadd())
    HasClipRect      = bit.lshift(1, 9), -- g.LastItemData.ClipRect is valid
    HasShortcut      = bit.lshift(1, 10) -- g.LastItemData.Shortcut valid. Set by SetNextItemShortcut() -> ItemAdd()
}

--- @alias ImGuiChildFlags integer
ImGuiChildFlags_None                   = 0
ImGuiChildFlags_ResizeX                = bit.lshift(1, 0)
ImGuiChildFlags_ResizeY                = bit.lshift(1, 1)
ImGuiChildFlags_ResizeBoth             = bit.bor(ImGuiChildFlags_ResizeX, ImGuiChildFlags_ResizeY)
ImGuiChildFlags_Border                 = bit.lshift(1, 5)
ImGuiChildFlags_AlwaysUseWindowPadding = bit.lshift(1, 6)
ImGuiChildFlags_ResizeXAndY            = ImGuiChildFlags_ResizeBoth
ImGuiChildFlags_NavFlattened           = bit.lshift(1, 7)

--- @enum ImGuiNextItemDataFlags
ImGuiNextItemDataFlags = {
    None           = 0,
    HasWidth       = bit.lshift(1, 0),
    HasOpen        = bit.lshift(1, 1),
    HasShortcut    = bit.lshift(1, 2),
    HasRefVal      = bit.lshift(1, 3),
    HasStorageID   = bit.lshift(1, 4),
    HasColorMarker = bit.lshift(1, 5)
}

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
ImDrawFlags_RoundCornersMask_       = bit.bor(ImDrawFlags_RoundCornersAll, ImDrawFlags_RoundCornersNone)
ImDrawFlags_RoundCornersDefault_    = ImDrawFlags_RoundCornersAll

--- @enum ImDrawListFlags
ImDrawListFlags = {
    None                   = 0,
    AntiAliasedLines       = bit.lshift(1, 0), -- Enable anti-aliased lines/borders (*2 the number of triangles for 1.0f wide line or lines thin enough to be drawn using textures, otherwise *3 the number of triangles)
    AntiAliasedLinesUseTex = bit.lshift(1, 1), -- Enable anti-aliased lines/borders using textures when possible. Require backend to render with bilinear filtering (NOT point/nearest filtering)
    AntiAliasedFill        = bit.lshift(1, 2), -- Enable anti-aliased edge around filled shapes (rounded rectangles, circles)
    AllowVtxOffset         = bit.lshift(1, 3)  -- Can emit 'VtxOffset > 0' to allow large meshes. Set when 'ImGuiBackendFlags.RendererHasVtxOffset' is enabled
}

--- @enum ImFontFlags
ImFontFlags = {
    None           = 0,
    NoLoadError    = bit.lshift(1, 1),
    NoLoadGlyphs   = bit.lshift(1, 2),
    LockBakedSizes = bit.lshift(1, 3)
}

--- @enum ImGuiMouseSource
ImGuiMouseSource = {
    Mouse       = 0,
    TouchScreen = 1,
    Pen         = 2,
    COUNT       = 3
}

--- @enum ImGuiCond
ImGuiCond = {
    None          = 0,                -- No condition (always set the variable), same as .Always
    Always        = bit.lshift(1, 0), -- No condition (always set the variable), same as .None
    Once          = bit.lshift(1, 1), -- Set the variable once per runtime session (only the first call will succeed)
    FirstUseEver  = bit.lshift(1, 2), -- Set the variable if the object/window has no persistently saved data (no entry in .ini file)
    Appearing     = bit.lshift(1, 3)  -- Set the variable if the object/window is appearing after being hidden/inactive (or the first time)
}

--- @alias ImGuiInputFlags int
ImGuiInputFlags_None                 = 0
ImGuiInputFlags_Repeat               = bit.lshift(1, 0)
ImGuiInputFlags_RouteActive          = bit.lshift(1, 10)
ImGuiInputFlags_RouteFocused         = bit.lshift(1, 11)
ImGuiInputFlags_RouteGlobal          = bit.lshift(1, 12)
ImGuiInputFlags_RouteAlways          = bit.lshift(1, 13)
ImGuiInputFlags_RouteOverFocused     = bit.lshift(1, 14)
ImGuiInputFlags_RouteOverActive      = bit.lshift(1, 15)
ImGuiInputFlags_RouteUnlessBgFocused = bit.lshift(1, 16)
ImGuiInputFlags_RouteFromRootWindow  = bit.lshift(1, 17)
ImGuiInputFlags_Tooltip              = bit.lshift(1, 18)

--- @alias ImGuiButtonFlags int
ImGuiButtonFlags_None                   = 0
ImGuiButtonFlags_MouseButtonLeft        = bit.lshift(1, 0)
ImGuiButtonFlags_MouseButtonRight       = bit.lshift(1, 1)
ImGuiButtonFlags_MouseButtonMiddle      = bit.lshift(1, 2)
ImGuiButtonFlags_MouseButtonMask_       = bit.bor(ImGuiButtonFlags_MouseButtonLeft, ImGuiButtonFlags_MouseButtonRight, ImGuiButtonFlags_MouseButtonMiddle)
ImGuiButtonFlags_EnableNav              = bit.lshift(1, 3)

ImGuiButtonFlags_PressedOnClick                = bit.lshift(1, 4)
ImGuiButtonFlags_PressedOnClickRelease         = bit.lshift(1, 5)
ImGuiButtonFlags_PressedOnClickReleaseAnywhere = bit.lshift(1, 6)
ImGuiButtonFlags_PressedOnRelease              = bit.lshift(1, 7)
ImGuiButtonFlags_PressedOnDoubleClick          = bit.lshift(1, 8)
ImGuiButtonFlags_PressedOnDragDropHold         = bit.lshift(1, 9)
ImGuiButtonFlags_FlattenChildren               = bit.lshift(1, 11)
ImGuiButtonFlags_AllowOverlap                  = bit.lshift(1, 12)
ImGuiButtonFlags_AlignTextBaseLine             = bit.lshift(1, 15)
ImGuiButtonFlags_NoKeyModsAllowed              = bit.lshift(1, 16)
ImGuiButtonFlags_NoHoldingActiveId             = bit.lshift(1, 17)
ImGuiButtonFlags_NoNavFocus                    = bit.lshift(1, 18)
ImGuiButtonFlags_NoHoveredOnFocus              = bit.lshift(1, 19)
ImGuiButtonFlags_NoSetKeyOwner                 = bit.lshift(1, 20)
ImGuiButtonFlags_NoTestKeyOwner                = bit.lshift(1, 21)
ImGuiButtonFlags_NoFocus                       = bit.lshift(1, 22)

ImGuiButtonFlags_PressedOnMask_ = bit.bor(
    ImGuiButtonFlags_PressedOnClick,
    ImGuiButtonFlags_PressedOnClickRelease,
    ImGuiButtonFlags_PressedOnClickReleaseAnywhere,
    ImGuiButtonFlags_PressedOnRelease,
    ImGuiButtonFlags_PressedOnDoubleClick,
    ImGuiButtonFlags_PressedOnDragDropHold
)

ImGuiButtonFlags_PressedOnDefault_ = ImGuiButtonFlags_PressedOnClickRelease
ImGuiButtonFlags_NoKeyModifiers    = ImGuiButtonFlags_NoKeyModsAllowed

--- @enum ImGuiStyleVar
ImGuiStyleVar = {
    Alpha                       = 0,
    DisabledAlpha               = 1,
    WindowPadding               = 2,
    WindowRounding              = 3,
    WindowBorderSize            = 4,
    WindowMinSize               = 5,
    WindowTitleAlign            = 6,
    ChildRounding               = 7,
    ChildBorderSize             = 8,
    PopupRounding               = 9,
    PopupBorderSize             = 10,
    FramePadding                = 11,
    FrameRounding               = 12,
    FrameBorderSize             = 13,
    ItemSpacing                 = 14,
    ItemInnerSpacing            = 15,
    IndentSpacing               = 16,
    CellPadding                 = 17,
    ScrollbarSize               = 18,
    ScrollbarRounding           = 19,
    ScrollbarPadding            = 20,
    GrabMinSize                 = 21,
    GrabRounding                = 22,
    ImageRounding               = 23,
    ImageBorderSize             = 24,
    TabRounding                 = 25,
    TabBorderSize               = 26,
    TabMinWidthBase             = 27,
    TabMinWidthShrink           = 28,
    TabBarBorderSize            = 29,
    TabBarOverlineSize          = 30,
    TableAngledHeadersAngle     = 31,
    TableAngledHeadersTextAlign = 32,
    TreeLinesSize               = 33,
    TreeLinesRounding           = 34,
    ButtonTextAlign             = 35,
    SelectableTextAlign         = 36,
    SeparatorTextBorderSize     = 37,
    SeparatorTextAlign          = 38,
    SeparatorTextPadding        = 39,
    COUNT                       = 40
}

--- @alias ImGuiHoveredFlags int
ImGuiHoveredFlags_None                         = 0
ImGuiHoveredFlags_ChildWindows                 = bit.lshift(1, 0)
ImGuiHoveredFlags_RootWindow                   = bit.lshift(1, 1)
ImGuiHoveredFlags_AnyWindow                    = bit.lshift(1, 2)
ImGuiHoveredFlags_NoPopupHierarchy             = bit.lshift(1, 3)
ImGuiHoveredFlags_AllowWhenBlockedByPopup      = bit.lshift(1, 5)
ImGuiHoveredFlags_AllowWhenBlockedByActiveItem = bit.lshift(1, 7)
ImGuiHoveredFlags_AllowWhenOverlappedByItem    = bit.lshift(1, 8)
ImGuiHoveredFlags_AllowWhenOverlappedByWindow  = bit.lshift(1, 9)
ImGuiHoveredFlags_AllowWhenDisabled            = bit.lshift(1, 10)
ImGuiHoveredFlags_NoNavOverride                = bit.lshift(1, 11)
ImGuiHoveredFlags_ForTooltip                   = bit.lshift(1, 12)
ImGuiHoveredFlags_Stationary                   = bit.lshift(1, 13)
ImGuiHoveredFlags_DelayNone                    = bit.lshift(1, 14)
ImGuiHoveredFlags_DelayShort                   = bit.lshift(1, 15)
ImGuiHoveredFlags_DelayNormal                  = bit.lshift(1, 16)
ImGuiHoveredFlags_NoSharedDelay                = bit.lshift(1, 17)

ImGuiHoveredFlags_AllowWhenOverlapped = bit.bor(ImGuiHoveredFlags_AllowWhenOverlappedByItem, ImGuiHoveredFlags_AllowWhenOverlappedByWindow)
ImGuiHoveredFlags_RectOnly            = bit.bor(ImGuiHoveredFlags_AllowWhenBlockedByPopup, ImGuiHoveredFlags_AllowWhenBlockedByActiveItem, ImGuiHoveredFlags_AllowWhenOverlapped)
ImGuiHoveredFlags_RootAndChildWindows = bit.bor(ImGuiHoveredFlags_RootWindow, ImGuiHoveredFlags_ChildWindows)

ImGuiHoveredFlags_DelayMask_ = bit.bor(
    ImGuiHoveredFlags_DelayNone,
    ImGuiHoveredFlags_DelayShort,
    ImGuiHoveredFlags_DelayNormal,
    ImGuiHoveredFlags_NoSharedDelay
)

ImGuiHoveredFlags_AllowedMaskForIsWindowHovered = bit.bor(
    ImGuiHoveredFlags_ChildWindows,
    ImGuiHoveredFlags_RootWindow,
    ImGuiHoveredFlags_AnyWindow,
    ImGuiHoveredFlags_NoPopupHierarchy,
    ImGuiHoveredFlags_AllowWhenBlockedByPopup,
    ImGuiHoveredFlags_AllowWhenBlockedByActiveItem,
    ImGuiHoveredFlags_ForTooltip,
    ImGuiHoveredFlags_Stationary
)

ImGuiHoveredFlags_AllowedMaskForIsItemHovered = bit.bor(
    ImGuiHoveredFlags_AllowWhenBlockedByPopup,
    ImGuiHoveredFlags_AllowWhenBlockedByActiveItem,
    ImGuiHoveredFlags_AllowWhenOverlapped,
    ImGuiHoveredFlags_AllowWhenDisabled,
    ImGuiHoveredFlags_NoNavOverride,
    ImGuiHoveredFlags_ForTooltip,
    ImGuiHoveredFlags_Stationary,
    ImGuiHoveredFlags_DelayMask_
)

--- @enum ImGuiKey
ImGuiKey = {
    None = 0,

    NamedKey_BEGIN = 512,

    Tab        = 512,
    LeftArrow  = 513,
    RightArrow = 514,
    UpArrow    = 515,
    DownArrow  = 516,
    PageUp     = 517,
    PageDown   = 518,
    Home       = 519,
    End        = 520,
    Insert     = 521,
    Delete     = 522,
    Backspace  = 523,
    Space      = 524,
    Enter      = 525,
    Escape     = 526,
    LeftCtrl   = 527, LeftShift  = 528, LeftAlt  = 529, LeftSuper  = 530,
    RightCtrl  = 531, RightShift = 532, RightAlt = 533, RightSuper = 534,
    Menu       = 535,

    -- 1 ~ 9
    K0 = 536, K1 = 537, K2 = 538, K3 = 539, K4 = 540, K5 = 541, K6 = 542, K7 = 543, K8 = 544, K9 = 545,

    A = 546, B = 547, C = 548, D = 549, E = 550, F = 551, G = 552, H = 553, I = 554, J = 555,
    K = 556, L = 557, M = 558, N = 559, O = 560, P = 561, Q = 562, R = 563, S = 564, T = 565,
    U = 566, V = 567, W = 568, X = 569, Y = 570, Z = 571,

    F1  = 572, F2  = 573, F3  = 574, F4  = 575, F5  = 576, F6  = 577,
    F7  = 578, F8  = 579, F9  = 580, F10 = 581, F11 = 582, F12 = 583,
    F13 = 584, F14 = 585, F15 = 586, F16 = 587, F17 = 588, F18 = 589,
    F19 = 590, F20 = 591, F21 = 592, F22 = 593, F23 = 594, F24 = 595,

    Apostrophe     = 596,
    Comma          = 597,
    Minus          = 598,
    Period         = 599,
    Slash          = 600,
    Semicolon      = 601,
    Equal          = 602,
    LeftBracket    = 603,
    Backslash      = 604,
    RightBracket   = 605,
    GraveAccent    = 606,
    CapsLock       = 607,
    ScrollLock     = 608,
    NumLock        = 609,
    PrintScreen    = 610,
    Pause          = 611,
    Keypad0        = 612,
    Keypad1        = 613,
    Keypad2        = 614,
    Keypad3        = 615,
    Keypad4        = 616,
    Keypad5        = 617,
    Keypad6        = 618,
    Keypad7        = 619,
    Keypad8        = 620,
    Keypad9        = 621,
    KeypadDecimal  = 622,
    KeypadDivide   = 623,
    KeypadMultiply = 624,
    KeypadSubtract = 625,
    KeypadAdd      = 626,
    KeypadEnter    = 627,
    KeypadEqual    = 628,
    AppBack        = 629,
    AppForward     = 630,
    Oem102         = 631,

    GamepadStart       = 632,
    GamepadBack        = 633,
    GamepadFaceLeft    = 634,
    GamepadFaceRight   = 635,
    GamepadFaceUp      = 636,
    GamepadFaceDown    = 637,
    GamepadDpadLeft    = 638,
    GamepadDpadRight   = 639,
    GamepadDpadUp      = 640,
    GamepadDpadDown    = 641,
    GamepadL1          = 642,
    GamepadR1          = 643,
    GamepadL2          = 644,
    GamepadR2          = 645,
    GamepadL3          = 646,
    GamepadR3          = 647,
    GamepadLStickLeft  = 648,
    GamepadLStickRight = 649,
    GamepadLStickUp    = 650,
    GamepadLStickDown  = 651,
    GamepadRStickLeft  = 652,
    GamepadRStickRight = 653,
    GamepadRStickUp    = 654,
    GamepadRStickDown  = 655,

    MouseLeft = 656, MouseRight = 657, MouseMiddle = 658, MouseX1 = 659, MouseX2 = 660, MouseWheelX = 661, MouseWheelY = 662,

    ReservedForModCtrl = 663, ReservedForModShift = 664, ReservedForModAlt = 665, ReservedForModSuper = 666,

    NamedKey_END = 667
}

ImGuiKey.NamedKey_COUNT = ImGuiKey.NamedKey_END - ImGuiKey.NamedKey_BEGIN

ImGuiMod_None  = 0
ImGuiMod_Ctrl  = bit.lshift(1, 12)
ImGuiMod_Shift = bit.lshift(1, 13)
ImGuiMod_Alt   = bit.lshift(1, 14)
ImGuiMod_Super = bit.lshift(1, 15)
ImGuiMod_Mask_ = 0xF000

--- @enum ImGuiCol
ImGuiCol = {
    Text                      = 0,
    TextDisabled              = 1,
    WindowBg                  = 2,
    ChildBg                   = 3,
    PopupBg                   = 4,
    Border                    = 5,
    BorderShadow              = 6,
    FrameBg                   = 7,
    FrameBgHovered            = 8,
    FrameBgActive             = 9,
    TitleBg                   = 10,
    TitleBgActive             = 11,
    TitleBgCollapsed          = 12,
    MenuBarBg                 = 13,
    ScrollbarBg               = 14,
    ScrollbarGrab             = 15,
    ScrollbarGrabHovered      = 16,
    ScrollbarGrabActive       = 17,
    CheckMark                 = 18,
    SliderGrab                = 19,
    SliderGrabActive          = 20,
    Button                    = 21,
    ButtonHovered             = 22,
    ButtonActive              = 23,
    Header                    = 24,
    HeaderHovered             = 25,
    HeaderActive              = 26,
    Separator                 = 27,
    SeparatorHovered          = 28,
    SeparatorActive           = 29,
    ResizeGrip                = 30,
    ResizeGripHovered         = 31,
    ResizeGripActive          = 32,
    InputTextCursor           = 33,
    TabHovered                = 34,
    Tab                       = 35,
    TabSelected               = 36,
    TabSelectedOverline       = 37,
    TabDimmed                 = 38,
    TabDimmedSelected         = 39,
    TabDimmedSelectedOverline = 40,
    PlotLines                 = 41,
    PlotLinesHovered          = 42,
    PlotHistogram             = 43,
    PlotHistogramHovered      = 44,
    TableHeaderBg             = 45,
    TableBorderStrong         = 46,
    TableBorderLight          = 47,
    TableRowBg                = 48,
    TableRowBgAlt             = 49,
    TextLink                  = 50,
    TextSelectedBg            = 51,
    TreeLines                 = 52,
    DragDropTarget            = 53,
    DragDropTargetBg          = 54,
    UnsavedMarker             = 55,
    NavCursor                 = 56,
    NavWindowingHighlight     = 57,
    NavWindowingDimBg         = 58,
    ModalWindowDimBg          = 59,
    COUNT                     = 60
}

--- @enum ImGuiBackendFlags
ImGuiBackendFlags = {
    None                  = 0,
    HasGamepad            = bit.lshift(1, 0),
    HasMouseCursors       = bit.lshift(1, 1),
    HasSetMousePos        = bit.lshift(1, 2),
    RendererHasVtxOffset  = bit.lshift(1, 3),
    RendererHasTextures   = bit.lshift(1, 4),

    -- [BETA] Multi-Viewports
    RendererHasViewports    = bit.lshift(1, 10),
    PlatformHasViewports    = bit.lshift(1, 11),
    HasMouseHoveredViewport = bit.lshift(1, 12),
    HasParentViewport       = bit.lshift(1, 13)
}

--- @alias ImGuiDragDropFlags int
ImGuiDragDropFlags_None                     = 0
ImGuiDragDropFlags_SourceNoPreviewTooltip   = bit.lshift(1, 0)
ImGuiDragDropFlags_SourceNoDisableHover     = bit.lshift(1, 1)
ImGuiDragDropFlags_SourceNoHoldToOpenOthers = bit.lshift(1, 2)
ImGuiDragDropFlags_SourceAllowNullID        = bit.lshift(1, 3)
ImGuiDragDropFlags_SourceExtern             = bit.lshift(1, 4)
ImGuiDragDropFlags_PayloadAutoExpire        = bit.lshift(1, 5)
ImGuiDragDropFlags_PayloadNoCrossContext    = bit.lshift(1, 6)
ImGuiDragDropFlags_PayloadNoCrossProcess    = bit.lshift(1, 7)

ImGuiDragDropFlags_AcceptBeforeDelivery    = bit.lshift(1, 10)
ImGuiDragDropFlags_AcceptNoDrawDefaultRect = bit.lshift(1, 11)
ImGuiDragDropFlags_AcceptNoPreviewTooltip  = bit.lshift(1, 12)
ImGuiDragDropFlags_AcceptDrawAsHovered     = bit.lshift(1, 13)

ImGuiDragDropFlags_AcceptPeekOnly = bit.bor(ImGuiDragDropFlags_AcceptBeforeDelivery, ImGuiDragDropFlags_AcceptNoDrawDefaultRect)

--- A primary data type
--- @enum ImGuiDataType
ImGuiDataType = {
    S8     = 0,  -- signed char / char
    U8     = 1,  -- unsigned char
    S16    = 2,  -- short
    U16    = 3,  -- unsigned short
    S32    = 4,  -- int
    U32    = 5,  -- unsigned int
    S64    = 6,  -- long long / __int64
    U64    = 7,  -- unsigned long long / unsigned __int64
    Float  = 8,  -- float
    Double = 9,  -- double
    Bool   = 10, -- bool (provided for user convenience, not supported by scalar widgets)
    String = 11, -- string (provided for user convenience, not supported by scalar widgets)
    COUNT  = 12
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

--- @alias ImGuiPopupFlags int
ImGuiPopupFlags_None                    = 0
ImGuiPopupFlags_MouseButtonLeft         = bit.lshift(1, 2)
ImGuiPopupFlags_MouseButtonRight        = bit.lshift(2, 2)
ImGuiPopupFlags_MouseButtonMiddle       = bit.lshift(3, 2)
ImGuiPopupFlags_NoReopen                = bit.lshift(1, 5)
ImGuiPopupFlags_NoOpenOverExistingPopup = bit.lshift(1, 7)
ImGuiPopupFlags_NoOpenOverItems         = bit.lshift(1, 8)
ImGuiPopupFlags_AnyPopupId              = bit.lshift(1, 10)
ImGuiPopupFlags_AnyPopupLevel           = bit.lshift(1, 11)

ImGuiPopupFlags_AnyPopup          = bit.bor(ImGuiPopupFlags_AnyPopupId, ImGuiPopupFlags_AnyPopupLevel)
ImGuiPopupFlags_MouseButtonShift_ = 2
ImGuiPopupFlags_MouseButtonMask_  = 0x0C
ImGuiPopupFlags_InvalidMask_      = 0x03

--- @alias ImGuiComboFlags int
ImGuiComboFlags_None            = 0
ImGuiComboFlags_PopupAlignLeft  = bit.lshift(1, 0)
ImGuiComboFlags_HeightSmall     = bit.lshift(1, 1)
ImGuiComboFlags_HeightRegular   = bit.lshift(1, 2)
ImGuiComboFlags_HeightLarge     = bit.lshift(1, 3)
ImGuiComboFlags_HeightLargest   = bit.lshift(1, 4)
ImGuiComboFlags_NoArrowButton   = bit.lshift(1, 5)
ImGuiComboFlags_NoPreview       = bit.lshift(1, 6)
ImGuiComboFlags_WidthFitPreview = bit.lshift(1, 7)

ImGuiComboFlags_HeightMask_ = bit.bor(ImGuiComboFlags_HeightSmall, ImGuiComboFlags_HeightRegular, ImGuiComboFlags_HeightLarge, ImGuiComboFlags_HeightLargest)

ImGuiComboFlags_CustomPreview = bit.lshift(1, 20)

--- @enum ImGuiSelectableFlags
ImGuiSelectableFlags = {
    None              = 0,
    NoAutoClosePopups = bit.lshift(1, 0), -- Clicking this doesn't close parent popup window (overrides ImGuiItemFlags_AutoClosePopups)
    SpanAllColumns    = bit.lshift(1, 1), -- Frame will span all columns of its container table (text will still fit in current column)
    AllowDoubleClick  = bit.lshift(1, 2), -- Generate press events on double clicks too
    Disabled          = bit.lshift(1, 3), -- Cannot be selected, display grayed out text
    AllowOverlap      = bit.lshift(1, 4), -- (WIP) Hit testing to allow subsequent widgets to overlap this one
    Highlight         = bit.lshift(1, 5), -- Make the item be displayed as if it is hovered
    SelectOnNav       = bit.lshift(1, 6), -- Auto-select when moved into, unless Ctrl is held. Automatic when in a BeginMultiSelect() block

    NoHoldingActiveID    = bit.lshift(1, 20),
    SelectOnClick        = bit.lshift(1, 22), -- Override button behavior to react on Click (default is Click+Release)
    SelectOnRelease      = bit.lshift(1, 23), -- Override button behavior to react on Release (default is Click+Release)
    SpanAvailWidth       = bit.lshift(1, 24), -- Span all avail width even if we declared less for layout purpose. FIXME: We may be able to remove this (added in 6251d379, 2bcafc86 for menus)
    SetNavIdOnHover      = bit.lshift(1, 25), -- Set Nav/Focus ID on mouse hover (used by MenuItem)
    NoPadWithHalfSpacing = bit.lshift(1, 26), -- Disable padding each side with ItemSpacing * 0.5f
    NoSetKeyOwner        = bit.lshift(1, 27), -- Don't set key/input owner on the initial click (note: mouse buttons are keys! often, the key in question will be ImGuiKey_MouseLeft!)
}

-- Flags for ColorEdit3() / ColorEdit4() / ColorPicker3() / ColorPicker4() / ColorButton()
--- @enum ImGuiColorEditFlags
ImGuiColorEditFlags = {
    None           = 0,
    NoAlpha        = bit.lshift(1, 1),  -- ColorEdit, ColorPicker, ColorButton: ignore Alpha component (will only read 3 components from the input pointer).
    NoPicker       = bit.lshift(1, 2),  -- ColorEdit: disable picker when clicking on color square.
    NoOptions      = bit.lshift(1, 3),  -- ColorEdit: disable toggling options menu when right-clicking on inputs/small preview.
    NoSmallPreview = bit.lshift(1, 4),  -- ColorEdit, ColorPicker: disable color square preview next to the inputs. (e.g. to show only the inputs)
    NoInputs       = bit.lshift(1, 5),  -- ColorEdit, ColorPicker: disable inputs sliders/text widgets (e.g. to show only the small preview color square).
    NoTooltip      = bit.lshift(1, 6),  -- ColorEdit, ColorPicker, ColorButton: disable tooltip when hovering the preview.
    NoLabel        = bit.lshift(1, 7),  -- ColorEdit, ColorPicker: disable display of inline text label (the label is still forwarded to the tooltip and picker).
    NoSidePreview  = bit.lshift(1, 8),  -- ColorPicker: disable bigger color preview on right side of the picker, use small color square preview instead.
    NoDragDrop     = bit.lshift(1, 9),  -- ColorEdit: disable drag and drop target/source. ColorButton: disable drag and drop source.
    NoBorder       = bit.lshift(1, 10), -- ColorButton: disable border (which is enforced by default)
    NoColorMarkers = bit.lshift(1, 11), -- ColorEdit: disable rendering R/G/B/A color marker. May also be disabled globally by setting style.ColorMarkerSize = 0.

    -- Alpha preview
    -- - Prior to 1.91.8 (2025/01/21): alpha was made opaque in the preview by default using old name ImGuiColorEditFlags_AlphaPreview.
    -- - We now display the preview as transparent by default. You can use ImGuiColorEditFlags_AlphaOpaque to use old behavior.
    -- - The new flags may be combined better and allow finer controls.
    AlphaOpaque      = bit.lshift(1, 12), -- ColorEdit, ColorPicker, ColorButton: disable alpha in the preview,. Contrary to _NoAlpha it may still be edited when calling ColorEdit4()/ColorPicker4(). For ColorButton() this does the same as _NoAlpha.
    AlphaNoBg        = bit.lshift(1, 13), -- ColorEdit, ColorPicker, ColorButton: disable rendering a checkerboard background behind transparent color.
    AlphaPreviewHalf = bit.lshift(1, 14), -- ColorEdit, ColorPicker, ColorButton: display half opaque / half transparent preview.

    -- User Options (right-click on widget to change some of them).
    AlphaBar       = bit.lshift(1, 18), -- ColorEdit, ColorPicker: show vertical alpha bar/gradient in picker.
    HDR            = bit.lshift(1, 19), -- (WIP) ColorEdit: Currently only disable 0.0f..1.0f limits in RGBA edition (note: you probably want to use ImGuiColorEditFlags_Float flag as well).
    DisplayRGB     = bit.lshift(1, 20), -- [Display]  -- ColorEdit: override _display_ type among RGB/HSV/Hex. ColorPicker: select any combination using one or more of RGB/HSV/Hex.
    DisplayHSV     = bit.lshift(1, 21), -- [Display]  -- "
    DisplayHex     = bit.lshift(1, 22), -- [Display]  -- "
    Uint8          = bit.lshift(1, 23), -- [DataType] -- ColorEdit, ColorPicker, ColorButton: _display_ values formatted as 0..255.
    Float          = bit.lshift(1, 24), -- [DataType] -- ColorEdit, ColorPicker, ColorButton: _display_ values formatted as 0.0f..1.0f floats instead of 0..255 integers. No round-trip of value via integers.
    PickerHueBar   = bit.lshift(1, 25), -- [Picker]   -- ColorPicker: bar for Hue, rectangle for Sat/Value.
    PickerHueWheel = bit.lshift(1, 26), -- [Picker]   -- ColorPicker: wheel for Hue, triangle for Sat/Value.
    InputRGB       = bit.lshift(1, 27), -- [Input]    -- ColorEdit, ColorPicker: input and output data in RGB format.
    InputHSV       = bit.lshift(1, 28)  -- [Input]    -- ColorEdit, ColorPicker: input and output data in HSV format.
}

-- Defaults Options. You can set application defaults using SetColorEditOptions(). The intent is that you probably don't want to
-- override them in most of your calls. Let the user choose via the option menu and/or call SetColorEditOptions() once during startup.
ImGuiColorEditFlags.DefaultOptions_ = bit.bor(ImGuiColorEditFlags.Uint8, ImGuiColorEditFlags.DisplayRGB, ImGuiColorEditFlags.InputRGB, ImGuiColorEditFlags.PickerHueBar)

ImGuiColorEditFlags.AlphaMask_ = bit.bor(
    ImGuiColorEditFlags.NoAlpha,
    ImGuiColorEditFlags.AlphaOpaque,
    ImGuiColorEditFlags.AlphaNoBg,
    ImGuiColorEditFlags.AlphaPreviewHalf
)

ImGuiColorEditFlags.DisplayMask_ = bit.bor(
    ImGuiColorEditFlags.DisplayRGB,
    ImGuiColorEditFlags.DisplayHSV,
    ImGuiColorEditFlags.DisplayHex
)

ImGuiColorEditFlags.DataTypeMask_ = bit.bor(
    ImGuiColorEditFlags.Uint8,
    ImGuiColorEditFlags.Float
)

ImGuiColorEditFlags.PickerMask_ = bit.bor(
    ImGuiColorEditFlags.PickerHueWheel,
    ImGuiColorEditFlags.PickerHueBar
)

ImGuiColorEditFlags.InputMask_ = bit.bor(
    ImGuiColorEditFlags.InputRGB,
    ImGuiColorEditFlags.InputHSV
)

--- @enum ImGuiSliderFlags
ImGuiSliderFlags = {
    None            = 0,
    Logarithmic     = bit.lshift(1, 5),  -- Make the widget logarithmic (linear otherwise). Consider using ImGuiSliderFlags.NoRoundToFormat with this if using a format-string with small amount of digits.
    NoRoundToFormat = bit.lshift(1, 6),  -- Disable rounding underlying value to match precision of the display format string (e.g. %.3f values are rounded to those 3 digits).
    NoInput         = bit.lshift(1, 7),  -- Disable Ctrl+Click or Enter key allowing to input text directly into the widget.
    WrapAround      = bit.lshift(1, 8),  -- Enable wrapping around from max to min and from min to max. Only supported by DragXXX() functions for now.
    ClampOnInput    = bit.lshift(1, 9),  -- Clamp value to min/max bounds when input manually with Ctrl+Click. By default Ctrl+Click allows going out of bounds.
    ClampZeroRange  = bit.lshift(1, 10), -- Clamp even if min==max==0.0f. Otherwise due to legacy reason DragXXX functions don't clamp with those values. When your clamping limits are dynamic you almost always want to use it.
    NoSpeedTweaks   = bit.lshift(1, 11), -- Disable keyboard modifiers altering tweak speed. Useful if you want to alter tweak speed yourself based on your own logic.
    ColorMarkers    = bit.lshift(1, 12), -- DragScalarN(), SliderScalarN(): Draw R/G/B/A color markers on each component.
    InvalidMask_    = 0x7000000F,        -- [Internal] We treat using those bits as being potentially a 'float power' argument from legacy API (obsoleted 2020-08) that has got miscast to this enum, and will trigger an assert if needed.
}

ImGuiSliderFlags.AlwaysClamp        = bit.bor(ImGuiSliderFlags.ClampOnInput, ImGuiSliderFlags.ClampZeroRange)

--- @class ImGuiWindowClass
--- @field ClassId                    ImGuiID
--- @field ParentViewportId           ImGuiID
--- @field FocusRouteParentWindowId   ImGuiID
--- @field ViewportFlagsOverrideSet   ImGuiViewportFlags
--- @field ViewportFlagsOverrideClear ImGuiViewportFlags

--- @return ImGuiWindowClass
--- @nodiscard
function ImGuiWindowClass()
    return {
        ClassId                    = 0,
        ParentViewportId           = 0xFFFFFFFF,
        FocusRouteParentWindowId   = 0,
        ViewportFlagsOverrideSet   = 0,
        ViewportFlagsOverrideClear = 0,

        TabItemFlagsOverrideSet  = 0,
        DockNodeFlagsOverrideSet = 0,
        DockingAlwaysTabBar      = false,
        DockingAllowUnclassed    = true
    }
end