--- @alias ImU8           integer
--- @alias ImU16          integer
--- @alias ImU32          integer
--- @alias ImU64          integer
--- @alias ImS8           integer
--- @alias float          number
--- @alias unsigned_int   integer
--- @alias int            integer
--- @alias unsigned_short integer

--- @alias size_t unsigned_int

--- @alias char integer

--- @alias ImWchar16 unsigned_short
--- @alias ImWchar   ImWchar16

--- @alias bool boolean

--- @alias ImGuiID unsigned_int

--- @alias ImTextureID ImU64

--- @alias ImGuiKeyChord int

--- @alias ImGCFriendly function # I tag a function with this to mark that: it minimizes / avoids Lua table creation

IM_UNICODE_CODEPOINT_INVALID = 0xFFFD
IM_UNICODE_CODEPOINT_MAX     = 0xFFFF

----------------------------------------------------------------
-- [SECTION] METATABLE MANAGEMENT
----------------------------------------------------------------

--- File-scope metatable storage
--- @type table<string, table>
local MT = {}

--- @param _EXPR boolean
--- @param _MSG string?
function IM_ASSERT(_EXPR, _MSG) assert((_EXPR), _MSG) end

IM_ASSERT_PARANOID = IM_ASSERT

----------------------------------------------------------------
-- [SECTION] C POINTER / ARRAY LIKE OPERATIONS SUPPORT
----------------------------------------------------------------

-- TODO: try to reduce its usage
--- @alias float_ptr float[] # Size = 1
--- @alias bool_ptr  bool[]  # Size = 1

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
function MT.ImVec4:copy() return ImVec4(self.x, self.y, self.z, self.w) end

-- TODO: use asserts, no return nil
--- A compact ImVector clone
--- @class ImVector
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
function MT.ImVector:iter() local i, n = 0, self.Size return function() i = i + 1 if i <= n then return i, self.Data[i] end end end
function MT.ImVector:find_index(value) for i = 1, self.Size do if self.Data[i] == value then return i end end return nil end
function MT.ImVector:erase_unsorted(index) if index < 1 or index > self.Size then return false end local last_idx = self.Size if index ~= last_idx then self.Data[index] = self.Data[last_idx] end self.Data[last_idx] = nil self.Size = self.Size - 1 return true end
function MT.ImVector:find_erase_unsorted(value) local idx = self:find_index(value) if idx then return self:erase_unsorted(idx) end return false end
function MT.ImVector:reserve() return end
function MT.ImVector:reserve_discard() return end
function MT.ImVector:shrink(new_size) IM_ASSERT(new_size <= self.Size) self.Size = new_size end
function MT.ImVector:resize(new_size, v) local old_size = self.Size if new_size > old_size then for i = old_size + 1, new_size do self.Data[i] = v end end self.Size = new_size end
function MT.ImVector:swap(other) self.Size, other.Size = other.Size, self.Size self.Data, other.Data = other.Data, self.Data end
function MT.ImVector:contains(v) for i = 1, self.Size do if self.Data[i] == v then return true end return false end end
function MT.ImVector:insert(pos, value) if pos < 1 or pos > self.Size + 1 then return nil end --[[if self.Size == self.Capacity then self:reserve(self:_grow_capacity(self.Size + 1)) end--]] for i = self.Size, pos, -1 do self.Data[i + 1] = self.Data[i] end self.Data[pos] = value self.Size = self.Size + 1 return value end
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
        TexRef                 = nil, -- TODO: validate
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

--- @class ImDrawList
MT.ImDrawList = {}
MT.ImDrawList.__index = MT.ImDrawList

--- @param data? ImDrawListSharedData
--- @return ImDrawList
function ImDrawList(data)
    --- @type ImDrawList
    local this = setmetatable({
        CmdBuffer = ImVector(),
        IdxBuffer = ImVector(),
        VtxBuffer = ImVector(),
        Flags     = 0,

        _VtxCurrentIdx = 1,    -- TODO: validate
        _Data          = data, -- ImDrawListSharedData*, Pointer to shared draw data (you can use ImGui:GetDrawListSharedData() to get the one from current ImGui context)
        _VtxWritePtr   = 1,
        _IdxWritePtr   = 1,
        _Path          = ImVector(),
        _CmdHeader     = ImDrawCmdHeader(),
        _ClipRectStack = ImVector(),
        _TextureStack  = ImVector(),

        _FringeScale = 0
    }, MT.ImDrawList)

    -- GLUA: Keep Reference
    if data then this._CmdHeader.TexRef = data.FontAtlas.TexRef end

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
--- @field Pixels               ImSlice
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
    this.Pixels               = IM_SLICE() -- XXX: ptr: unsigned char
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
--- @field IndexAdvanceX        ImVector<float>
--- @field FallbackAdvanceX     float
--- @field Size                 float
--- @field RasterizerDensity    float
--- @field IndexLookup          ImVector<ImU16>
--- @field Glyphs               ImVector<ImFontGlyph>
--- @field FallbackGlyphIndex   int                   # Initial value = -1
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
--- @field Used8kPagesMap           ImU8[]
--- @field EllipsisAutoBake         bool
--- @field RemapPairs               table<ImGuiID, any>    # GLUA: No ImGuiStorage
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
ImGuiConfigFlags_NavEnableGamepad       = bit.lshift(1, 1)  -- Master gamepad navigation enable flag. Backend also needs to set ImGuiBackendFlags_HasGamepad.
ImGuiConfigFlags_NoMouse                = bit.lshift(1, 4)  -- Instruct dear imgui to disable mouse inputs and interactions.
ImGuiConfigFlags_NoMouseCursorChange    = bit.lshift(1, 5)  -- Instruct backend to not alter mouse cursor shape and visibility. Use if the backend cursor changes are interfering with yours and you don't want to use SetMouseCursor() to change mouse cursor. You may want to honor requests from imgui by reading GetMouseCursor() yourself instead.
ImGuiConfigFlags_NoKeyboard             = bit.lshift(1, 6)  -- Instruct dear imgui to disable keyboard inputs and interactions. This is done by ignoring keyboard events and clearing existing states.
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

        BackendFlags = 0,
        ConfigFlags  = 0,

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

        KeysData = {}, -- size = ImGuiKey_NamedKey_COUNT

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

    for i = 0, ImGuiKey_NamedKey_COUNT - 1 do
        this.KeysData[i] = ImGuiKeyData()
    end

    return setmetatable(this, MT.ImGuiIO)
end

--- @alias ImGuiViewportFlags int
ImGuiViewportFlags_None              = 0
ImGuiViewportFlags_IsPlatformWindow  = bit.lshift(1, 0)
ImGuiViewportFlags_IsPlatformMonitor = bit.lshift(1, 1)
ImGuiViewportFlags_OwnedByApp        = bit.lshift(1, 2)

--- @class ImGuiViewport
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
        WorkPos  = ImVec2(),
        WorkSize = ImVec2(),

        PlatformHandle = nil,
        PlatformHandleRaw = nil
    }, MT.ImGuiViewport)
end

--- @class ImGuiPlatformIO

--- @return ImGuiPlatformIO
function ImGuiPlatformIO()
    return {
        Renderer_TextureMaxWidth = 0,
        Renderer_TextureMaxHeight = 0,

        Renderer_RenderState = nil,

        Textures = ImVector(),

        Platform_LocaleDecimalPoint = '.'
    }
end

--- @enum ImGuiDir
ImGuiDir = {
    Left  = 0,
    Right = 1,
    Up    = 2,
    Down  = 3,
    COUNT = 4
}

--- @alias ImGuiMouseButton int
ImGuiMouseButton_Left   = 0
ImGuiMouseButton_Right  = 1
ImGuiMouseButton_Middle = 2
ImGuiMouseButton_COUNT  = 5

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
ImGuiItemFlags_AllowDuplicateId  = bit.lshift(1, 5)
ImGuiItemFlags_Disabled          = bit.lshift(1, 6)

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

--- @alias ImGuiChildFlags integer
ImGuiChildFlags_None                   = 0
ImGuiChildFlags_ResizeX                = bit.lshift(1, 0)
ImGuiChildFlags_ResizeY                = bit.lshift(1, 1)
ImGuiChildFlags_ResizeBoth             = bit.bor(ImGuiChildFlags_ResizeX, ImGuiChildFlags_ResizeY)
ImGuiChildFlags_Border                 = bit.lshift(1, 5)
ImGuiChildFlags_AlwaysUseWindowPadding = bit.lshift(1, 6)
ImGuiChildFlags_ResizeXAndY            = ImGuiChildFlags_ResizeBoth
ImGuiChildFlags_NavFlattened           = bit.lshift(1, 7)

--- @alias ImGuiNextItemDataFlags integer
ImGuiNextItemDataFlags_None                 = 0
ImGuiNextItemDataFlags_HasFlags             = bit.lshift(1, 0)
ImGuiNextItemDataFlags_HasShortcut          = bit.lshift(1, 1)
ImGuiNextItemDataFlags_HasSelectionUserData = bit.lshift(1, 2)

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

--- @alias ImGuiMouseSource int # This is probably impractical in GMod
ImGuiMouseSource_Mouse       = 0
ImGuiMouseSource_TouchScreen = 1
ImGuiMouseSource_Pen         = 2
ImGuiMouseSource_COUNT       = 3

--- @alias ImGuiCond int
ImGuiCond_None          = 0
ImGuiCond_Always        = bit.lshift(1, 0)
ImGuiCond_Once          = bit.lshift(1, 1)
ImGuiCond_FirstUseEver  = bit.lshift(1, 2)
ImGuiCond_Appearing     = bit.lshift(1, 3)

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

--- @alias ImGuiKey int
ImGuiKey_None           = 0
ImGuiKey_NamedKey_BEGIN = 512

ImGuiKey_Tab            = 512
ImGuiKey_LeftArrow      = 513
ImGuiKey_RightArrow     = 514
ImGuiKey_UpArrow        = 515
ImGuiKey_DownArrow      = 516
ImGuiKey_PageUp         = 517
ImGuiKey_PageDown       = 518
ImGuiKey_Home           = 519
ImGuiKey_End            = 520
ImGuiKey_Insert         = 521
ImGuiKey_Delete         = 522
ImGuiKey_Backspace      = 523
ImGuiKey_Space          = 524
ImGuiKey_Enter          = 525
ImGuiKey_Escape         = 526
ImGuiKey_LeftCtrl       = 527
ImGuiKey_LeftShift      = 528
ImGuiKey_LeftAlt        = 529
ImGuiKey_LeftSuper      = 530
ImGuiKey_RightCtrl      = 531
ImGuiKey_RightShift     = 532
ImGuiKey_RightAlt       = 533
ImGuiKey_RightSuper     = 534
ImGuiKey_Menu           = 535
ImGuiKey_0              = 536
ImGuiKey_1              = 537
ImGuiKey_2              = 538
ImGuiKey_3              = 539
ImGuiKey_4              = 540
ImGuiKey_5              = 541
ImGuiKey_6              = 542
ImGuiKey_7              = 543
ImGuiKey_8              = 544
ImGuiKey_9              = 545
ImGuiKey_A              = 546
ImGuiKey_B              = 547
ImGuiKey_C              = 548
ImGuiKey_D              = 549
ImGuiKey_E              = 550
ImGuiKey_F              = 551
ImGuiKey_G              = 552
ImGuiKey_H              = 553
ImGuiKey_I              = 554
ImGuiKey_J              = 555
ImGuiKey_K              = 556
ImGuiKey_L              = 557
ImGuiKey_M              = 558
ImGuiKey_N              = 559
ImGuiKey_O              = 560
ImGuiKey_P              = 561
ImGuiKey_Q              = 562
ImGuiKey_R              = 563
ImGuiKey_S              = 564
ImGuiKey_T              = 565
ImGuiKey_U              = 566
ImGuiKey_V              = 567
ImGuiKey_W              = 568
ImGuiKey_X              = 569
ImGuiKey_Y              = 570
ImGuiKey_Z              = 571
ImGuiKey_F1             = 572
ImGuiKey_F2             = 573
ImGuiKey_F3             = 574
ImGuiKey_F4             = 575
ImGuiKey_F5             = 576
ImGuiKey_F6             = 577
ImGuiKey_F7             = 578
ImGuiKey_F8             = 579
ImGuiKey_F9             = 580
ImGuiKey_F10            = 581
ImGuiKey_F11            = 582
ImGuiKey_F12            = 583
ImGuiKey_F13            = 584
ImGuiKey_F14            = 585
ImGuiKey_F15            = 586
ImGuiKey_F16            = 587
ImGuiKey_F17            = 588
ImGuiKey_F18            = 589
ImGuiKey_F19            = 590
ImGuiKey_F20            = 591
ImGuiKey_F21            = 592
ImGuiKey_F22            = 593
ImGuiKey_F23            = 594
ImGuiKey_F24            = 595
ImGuiKey_Apostrophe     = 596
ImGuiKey_Comma          = 597
ImGuiKey_Minus          = 598
ImGuiKey_Period         = 599
ImGuiKey_Slash          = 600
ImGuiKey_Semicolon      = 601
ImGuiKey_Equal          = 602
ImGuiKey_LeftBracket    = 603
ImGuiKey_Backslash      = 604
ImGuiKey_RightBracket   = 605
ImGuiKey_GraveAccent    = 606
ImGuiKey_CapsLock       = 607
ImGuiKey_ScrollLock     = 608
ImGuiKey_NumLock        = 609
ImGuiKey_PrintScreen    = 610
ImGuiKey_Pause          = 611
ImGuiKey_Keypad0        = 612
ImGuiKey_Keypad1        = 613
ImGuiKey_Keypad2        = 614
ImGuiKey_Keypad3        = 615
ImGuiKey_Keypad4        = 616
ImGuiKey_Keypad5        = 617
ImGuiKey_Keypad6        = 618
ImGuiKey_Keypad7        = 619
ImGuiKey_Keypad8        = 620
ImGuiKey_Keypad9        = 621
ImGuiKey_KeypadDecimal  = 622
ImGuiKey_KeypadDivide   = 623
ImGuiKey_KeypadMultiply = 624
ImGuiKey_KeypadSubtract = 625
ImGuiKey_KeypadAdd      = 626
ImGuiKey_KeypadEnter    = 627
ImGuiKey_KeypadEqual    = 628
ImGuiKey_AppBack        = 629
ImGuiKey_AppForward     = 630
ImGuiKey_Oem102         = 631

ImGuiKey_GamepadStart       = 632
ImGuiKey_GamepadBack        = 633
ImGuiKey_GamepadFaceLeft    = 634
ImGuiKey_GamepadFaceRight   = 635
ImGuiKey_GamepadFaceUp      = 636
ImGuiKey_GamepadFaceDown    = 637
ImGuiKey_GamepadDpadLeft    = 638
ImGuiKey_GamepadDpadRight   = 639
ImGuiKey_GamepadDpadUp      = 640
ImGuiKey_GamepadDpadDown    = 641
ImGuiKey_GamepadL1          = 642
ImGuiKey_GamepadR1          = 643
ImGuiKey_GamepadL2          = 644
ImGuiKey_GamepadR2          = 645
ImGuiKey_GamepadL3          = 646
ImGuiKey_GamepadR3          = 647
ImGuiKey_GamepadLStickLeft  = 648
ImGuiKey_GamepadLStickRight = 649
ImGuiKey_GamepadLStickUp    = 650
ImGuiKey_GamepadLStickDown  = 651
ImGuiKey_GamepadRStickLeft  = 652
ImGuiKey_GamepadRStickRight = 653
ImGuiKey_GamepadRStickUp    = 654
ImGuiKey_GamepadRStickDown  = 655

ImGuiKey_MouseLeft   = 656
ImGuiKey_MouseRight  = 657
ImGuiKey_MouseMiddle = 658
ImGuiKey_MouseX1     = 659
ImGuiKey_MouseX2     = 660
ImGuiKey_MouseWheelX = 661
ImGuiKey_MouseWheelY = 662

ImGuiKey_ReservedForModCtrl  = 663
ImGuiKey_ReservedForModShift = 664
ImGuiKey_ReservedForModAlt   = 665
ImGuiKey_ReservedForModSuper = 666

ImGuiKey_NamedKey_END   = 667
ImGuiKey_NamedKey_COUNT = ImGuiKey_NamedKey_END - ImGuiKey_NamedKey_BEGIN

ImGuiMod_None  = 0
ImGuiMod_Ctrl  = bit.lshift(1, 12)
ImGuiMod_Shift = bit.lshift(1, 13)
ImGuiMod_Alt   = bit.lshift(1, 14)
ImGuiMod_Super = bit.lshift(1, 15)
ImGuiMod_Mask_ = 0xF000

--- @enum ImGuiBackendFlags
ImGuiBackendFlags = {
    None                  = 0,
    HasGamepad            = bit.lshift(1, 0),
    HasMouseCursors       = bit.lshift(1, 1),
    HasSetMousePos        = bit.lshift(1, 2),
    RendererHasVtxOffset  = bit.lshift(1, 3),
    RendererHasTextures   = bit.lshift(1, 4)
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