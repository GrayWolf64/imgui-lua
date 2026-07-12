--- ImGui Sincerely WIP
-- (Definitions)

--- @meta

-- [LuaBitOp](https://bitop.luajit.org/semantics.html)
local b_and = bit.band; local b_or = bit.bor
local b_ls = bit.lshift

--- @class char          : integer
--- @class unsigned_char : integer

--- @alias ImS8 char
--- @alias ImU8 unsigned_char

--- @class ImU16 : integer
--- @class ImS16 : integer

--- @class ImU32 : integer
--- @class ImS32 : integer

--- @param val number
--- @return ImU8
function ImU8(val) return b_and(val, 0xFF) end
--- @param val number
--- @return ImS8
function ImS8(val) return b_and(val, 0xFF) - (b_and(val, 0x80) ~= 0 and 0x100 or 0) end

--- @param val number
--- @return ImU16
function ImU16(val) return b_and(val, 0xFFFF) end
--- @param val number
--- @return ImS16
function ImS16(val) return b_and(val, 0xFFFF) - (b_and(val, 0x8000) ~= 0 and 0x10000 or 0) end

--- @param val number
--- @return ImU32
function ImU32(val) return b_and(val, 0xFFFFFFFF) end
--- @param val number
--- @return ImS32
function ImS32(val) return b_and(val, 0xFFFFFFFF) end

--- @alias float          number
--- @class double : number

--- @alias int            integer
--- @alias unsigned_int   integer

--- @alias short          integer
--- @alias unsigned_short integer

--- @alias size_t unsigned_int

--- @alias ImWchar16 unsigned_short
--- @alias ImWchar   ImWchar16

--- @alias bool boolean

--- @alias ImGuiID unsigned_int

--- @alias ImTextureID integer

--- @alias ImGuiKeyChord int

--- @alias ImDrawIdx unsigned_int

IM_UNICODE_CODEPOINT_INVALID = 0xFFFD
IM_UNICODE_CODEPOINT_MAX     = 0xFFFF

IM_ALLOC = ImGui.MemAlloc
IM_FREE = ImGui.MemFree

---------------------------------------------------------------------------------------
-- [SECTION] METATABLE MANAGEMENT
---------------------------------------------------------------------------------------

--- File-scope metatable storage
local MT = {}

function ImGui.GetMetatables() return MT end

--- @param _EXPR any
--- @param _MSG  string?
function IM_ASSERT(_EXPR, _MSG) assert((_EXPR), _MSG) end

IM_ASSERT_PARANOID = IM_ASSERT

ImTextureID_Invalid = -1

ImTextureFormat = { RGBA32 = 0, Alpha8 = 1 } --- @enum ImTextureFormat

ImTextureStatus = { OK = 0, Destroyed = 1, WantCreate = 2, WantUpdates = 3, WantDestroy = 4 } --- @enum ImTextureStatus

ImFontAtlasFlags = { None = 0, NoPowerOfTwoHeight = b_ls(1, 0), NoMouseCursors = b_ls(1, 1), NoBakedLines = b_ls(1, 2) } --- @enum ImFontAtlasFlags

ImGuiDir = { None = -1, Left = 0, Right = 1, Up = 2, Down = 3, COUNT = 4 } --- @enum ImGuiDir

ImGuiMouseButton = { Left = 0, Right = 1, Middle = 2, COUNT = 5 } --- @enum ImGuiMouseButton

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
function ImTextureRect(x, y, w, h) return { x = x, y = y, w = w, h = h } end

local rawget = rawget; local rawset = rawset

-- This structure supports indexing on string keys `x`, `y` and number keys 1, 2.
-- But note that the former is likely to be more expensive.
--- @class ImVec2
--- @operator add(ImVec2): ImVec2
--- @operator sub(ImVec2): ImVec2
--- @operator mul(number): ImVec2
--- @field [1] number
--- @field [2] number
--- @field x number
--- @field y number
local IM_VEC2 = {}

--- @param t ImVec2
--- @param k int
IM_VEC2.__index = function(t, k)
    if     k == "x" then return rawget(t, 1)
    elseif k == "y" then return rawget(t, 2)
    end
end

--- @param t ImVec2
--- @param k int
--- @param v number
IM_VEC2.__newindex = function(t, k, v)
    if     k == "x" then rawset(t, 1, v)
    elseif k == "y" then rawset(t, 2, v)
    end
end

--- @param x? number
--- @param y? number
--- @return ImVec2
--- @nodiscard
function ImVec2(x, y) return setmetatable({x or 0, y or 0}, IM_VEC2) end

function IM_VEC2.__add(lhs, rhs) return ImVec2(lhs[1] + rhs[1], lhs[2] + rhs[2]) end
function IM_VEC2.__sub(lhs, rhs) return ImVec2(lhs[1] - rhs[1], lhs[2] - rhs[2]) end
function IM_VEC2.__mul(lhs, rhs) return ImVec2(lhs[1] * rhs, lhs[2] * rhs) end
function IM_VEC2.__eq(lhs, rhs) return lhs[1] == rhs[1] and lhs[2] == rhs[2] end

function IM_VEC2:__tostring() return string.format("ImVec2(%g, %g)", self.x, self.y) end

--- @param dest ImVec2
--- @param src  ImVec2
function ImVec2_Copy(dest, src) dest[1] = src[1]; dest[2] = src[2] end

--- @param dest  ImVec2
--- @param src_x number
--- @param src_y number
function ImVec2_CopyV(dest, src_x, src_y) dest[1] = src_x; dest[2] = src_y end

--- @param lhs ImVec2
--- @param rhs ImVec2
function ImVec2_AddV(lhs, rhs) return lhs[1] + rhs[1], lhs[2] + rhs[2] end

--- @param lhs ImVec2
--- @param rhs ImVec2
function ImVec2_SubV(lhs, rhs) return lhs[1] - rhs[1], lhs[2] - rhs[2] end

--- @param v     ImVec2
--- @param add_x number
--- @param add_y number
function ImVec2_AddVA(v, add_x, add_y) return v[1] + add_x, v[2] + add_y end

--- @param v     ImVec2
--- @param sub_x number
--- @param sub_y number
function ImVec2_SubVA(v, sub_x, sub_y) return v[1] - sub_x, v[2] - sub_y end

--- @param lhs ImVec2
--- @param rhs number
function ImVec2_MulNV(lhs, rhs) return lhs[1] * rhs, lhs[2] * rhs end

--- @param lhs ImVec2
--- @param rhs ImVec2
--- @nodiscard
function ImVec2_MulComp(lhs, rhs) return ImVec2(lhs[1] * rhs[1], lhs[2] * rhs[2]) end

--- @param lhs ImVec2
--- @param rhs ImVec2
function ImVec2_MulCompV(lhs, rhs) return lhs[1] * rhs[1], lhs[2] * rhs[2] end

--- An inlined version of `ImVec2_Copy` currently for use in certain ImVector<ImVec2> `push_back`
--- @param t ImVec2[]
--- @param k int
--- @param v ImVec2
local function ImVec2_TCopy(t, k, v) local dest = t[k]; dest[1] = v[1]; dest[2] = v[2]; end

-- This structure supports indexing on string keys `x`, `y`, `z`, `w` and number keys 1, 2, 3, 4.
-- But note that the former is likely to be more expensive.
--- @class ImVec4
--- @operator add(ImVec4): ImVec4
--- @operator sub(ImVec4): ImVec4
--- @operator mul(number): ImVec4
--- @field [1] number
--- @field [2] number
--- @field [3] number
--- @field [4] number
--- @field x number
--- @field y number
--- @field z number
--- @field w number
local IM_VEC4 = {}

--- @param t ImVec4
--- @param k int
IM_VEC4.__index = function(t, k)
    if     k == "x" then return rawget(t, 1)
    elseif k == "y" then return rawget(t, 2)
    elseif k == "z" then return rawget(t, 3)
    elseif k == "w" then return rawget(t, 4)
    end
end

--- @param t ImVec4
--- @param k int
--- @param v number
IM_VEC4.__newindex = function(t, k, v)
    if     k == "x" then rawset(t, 1, v)
    elseif k == "y" then rawset(t, 2, v)
    elseif k == "z" then rawset(t, 3, v)
    elseif k == "w" then rawset(t, 4, v)
    end
end

--- @param x? number
--- @param y? number
--- @param z? number
--- @param w? number
--- @return ImVec4
--- @nodiscard
function ImVec4(x, y, z, w) return setmetatable({x or 0, y or 0, z or 0, w or 0}, IM_VEC4) end

function IM_VEC4.__add(lhs, rhs) return ImVec4(lhs[1] + rhs[1], lhs[2] + rhs[2], lhs[3] + rhs[3], lhs[4] + rhs[4]) end
function IM_VEC4.__sub(lhs, rhs) return ImVec4(lhs[1] - rhs[1], lhs[2] - rhs[2], lhs[3] - rhs[3], lhs[4] - rhs[4]) end
function IM_VEC4.__mul(lhs, rhs) return ImVec4(lhs[1] * rhs, lhs[2] * rhs, lhs[3] * rhs, lhs[4] * rhs) end
function IM_VEC4.__eq(lhs, rhs) return lhs[1] == rhs[1] and lhs[2] == rhs[2] and lhs[3] == rhs[3] and lhs[4] == rhs[4] end

function IM_VEC4:__tostring() return string.format("ImVec4(%g, %g, %g, %g)", self.x, self.y, self.z, self.w) end

--- @param dest ImVec4
--- @param src  ImVec4
function ImVec4_Copy(dest, src) dest[1] = src[1]; dest[2] = src[2]; dest[3] = src[3]; dest[4] = src[4] end

--- A compact ImVector clone
--- @class ImVector<T>
--- @field Data          T[] # 1-based table
--- @field Size          int # >= 0
--- @field _Constructor  function
--- @field _CopyFunc     function
local IM_VECTOR = {}

-- Support 1-based number key indexing while keep method accessing speed
--- @param t ImVector
--- @param k string|int
--- @return any
IM_VECTOR.__index = function(t, k)
    return IM_VECTOR[k] or t.Data[IM_ASSERT(k >= 1 and k <= t.Size) or k] -- if the mt access turns out nil, the k must be int index into Data
end

--- @param t ImVector
--- @param k int
--- @param v any
IM_VECTOR.__newindex = function(t, k, v)
    IM_ASSERT(k >= 1 and k <= t.Size)
    t.Data[k] = v
end

local _default_constructor = function() return nil end
local _default_copyfunc = function(t, k, v) t[k] = v end

local function _grow_capacity(v, sz) local new_capacity = (v.Capacity ~= 0) and math.floor(v.Capacity + v.Capacity / 2) or 8; return (new_capacity > sz) and new_capacity or sz; end

--- @param T?         function
--- @param COPY_FUNC? function
--- @return ImVector
--- @nodiscard
function ImVector(T, COPY_FUNC) return setmetatable({Data = {}, Size = 0, Capacity = 0, _Constructor = T or _default_constructor, _CopyFunc = COPY_FUNC or _default_copyfunc}, IM_VECTOR) end

function IM_VECTOR:push_back(value) if self.Size == self.Capacity then self:reserve(_grow_capacity(self, self.Size + 1)) end; self._CopyFunc(self.Data, self.Size + 1, value); self.Size = self.Size + 1; return value end
function IM_VECTOR:pop_back() IM_ASSERT(self.Size > 0); self.Size = self.Size - 1; end
function IM_VECTOR:push_front(value) if self.Size == 0 then self:push_back(value) else self:insert(1, value) end end
function IM_VECTOR:clear() self.Size = 0 end
function IM_VECTOR:clear_delete() for i = 1, self.Size do self.Data[i] = nil end self.Size = 0 end
function IM_VECTOR:empty() return self.Size == 0 end
function IM_VECTOR:back()   IM_ASSERT(self.Size > 0) return self.Data[self.Size] end
function IM_VECTOR:erase(i) IM_ASSERT(i >= 1 and i <= self.Size) local removed = (table.remove(self.Data, i)) ~= nil self.Size = self.Size - 1 return removed end
local function _iter(v, i) i = i + 1 if i <= v.Size then return i, v.Data[i] end end
function IM_VECTOR:iter() return _iter, self, 0 end
function IM_VECTOR:find_index(value) for i = 1, self.Size do if self.Data[i] == value then return i end end return nil end
function IM_VECTOR:erase_unsorted(index) IM_ASSERT(index >= 1 and index <= self.Size) local last_idx = self.Size if index ~= last_idx then self.Data[index] = self.Data[last_idx] end self.Data[last_idx] = nil self.Size = self.Size - 1 return true end
function IM_VECTOR:find_erase(value) local idx = self:find_index(value) if idx then return self:erase(idx) end return false end
function IM_VECTOR:find_erase_unsorted(value) local idx = self:find_index(value) if idx then return self:erase_unsorted(idx) end return false end

function IM_VECTOR:reserve(new_capacity)
    if new_capacity <= self.Capacity then return end
    local new_data = IM_ALLOC(self._Constructor, new_capacity)
    if self.Data then
        ImStd.memmove(new_data, 1, self.Data, 1, self.Size)
        IM_FREE(self, "Data")
    end
    self.Data = new_data
    self.Capacity = new_capacity
end

function IM_VECTOR:reserve_discard(new_capacity)
    if new_capacity <= self.Capacity then return end
    if self.Data then IM_FREE(self, "Data") end
    self.Data = IM_ALLOC(self._Constructor, new_capacity)
    self.Capacity = new_capacity
end

function IM_VECTOR:shrink(new_size) IM_ASSERT(new_size <= self.Size) self.Size = new_size end

function IM_VECTOR:resize(new_size, v)
    if new_size > self.Capacity then self:reserve(_grow_capacity(self, new_size)) end
    if v ~= nil and new_size > self.Size then
        local data = self.Data
        for n = self.Size + 1, new_size do data[n] = v end
    end
    self.Size = new_size
end

function IM_VECTOR:swap(other) self.Size, other.Size = other.Size, self.Size; self.Capacity, other.Capacity = other.Capacity, self.Capacity; self.Data, other.Data = other.Data, self.Data end
function IM_VECTOR:contains(v) for i = 1, self.Size do if self.Data[i] == v then return true end end return false end

-- NOTE: This currently does not use type-aware copy!
function IM_VECTOR:insert(pos, value) IM_ASSERT(pos >= 1 and pos <= self.Size + 1); if self.Size == self.Capacity then self:reserve(_grow_capacity(self, self.Size + 1)) end; for i = self.Size, pos, -1 do self.Data[i + 1] = self.Data[i] end self.Data[pos] = value self.Size = self.Size + 1 return value end

-- NOTE: This currently does not copy type related info!
--- @nodiscard
function IM_VECTOR:copy()
    local v = ImVector(); v:resize(self.Size)
    local dest = v.Data; local src = self.Data
    for i = 1, v.Size do dest[i] = src[i] end
    return v
end

-- Not keeping value-key records inside `ImVector`, instead just find it
--- @return int # 0-based index
function IM_VECTOR:index_from_ptr(p)
    local data = self.Data; for i = 1, self.Size do if p == data[i] then return i - 1 end end
    --- @diagnostic disable-next-line
    IM_ASSERT(false, "index_from_ptr failed!")
end

--- @class ImDrawCmd
--- @field ClipRect               ImVec4
--- @field TexRef                 ImTextureRef
--- @field VtxOffset              unsigned_int
--- @field IdxOffset              unsigned_int
--- @field ElemCount              unsigned_int
--- @field UserCallback           ImDrawCallback
--- @field UserCallbackData       any
--- @field UserCallbackDataSize   int
--- @field UserCallbackDataOffset int
local IM_DRAWCMD = {}
IM_DRAWCMD.__index = IM_DRAWCMD

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
    }, IM_DRAWCMD)
end

--- @return ImTextureID
function IM_DRAWCMD:GetTexID()
    local tex_id = (self.TexRef._TexData) and self.TexRef._TexData.TexID or self.TexRef._TexID
    if self.TexRef._TexData ~= nil then
        IM_ASSERT(tex_id ~= ImTextureID_Invalid, "ImDrawCmd is referring to ImTextureData that wasn't uploaded to graphics system. Backend must call ImTextureData::SetTexID() after handling ImTextureStatus_WantCreate request!")
    end
    return tex_id
end

--- @class ImDrawVert
--- @field [1] ImVec2 # pos
--- @field [2] ImVec2 # uv
--- @field [3] ImU32  # col

--- @return ImDrawVert
--- @nodiscard
function ImDrawVert() return { ImVec2(), ImVec2(), nil } end

--- @class ImDrawCmdHeader
--- @field ClipRect  ImVec4
--- @field TexRef    ImTextureRef
--- @field VtxOffset unsigned_int

--- @return ImDrawCmdHeader
--- @nodiscard
function ImDrawCmdHeader() return { ClipRect = ImVec4(), TexRef = nil, VtxOffset = 0 } end

--- @class ImDrawChannel
--- @field _CmdBuffer ImVector<ImDrawCmd>
--- @field _IdxBuffer ImVector<ImDrawIdx>

--- @return ImDrawChannel
--- @nodiscard
function ImDrawChannel() return { _CmdBuffer = ImVector(), _IdxBuffer = ImVector() } end

--- @class ImDrawListSplitter
--- @field _Current  int
--- @field _Count    int
--- @field _Channels ImVector<ImDrawChannel>

--- @return ImDrawListSplitter
--- @nodiscard
function ImDrawListSplitter() return { _Current = 0, _Count = 0, _Channels = ImVector() } end

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
    local vtx = self.VtxBuffer.Data[self._VtxWritePtr]
    ImVec2_Copy(vtx[1], pos)
    ImVec2_Copy(vtx[2], uv)
    vtx[3] = col
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
        VtxBuffer = ImVector(ImDrawVert),
        Flags     = 0,

        _VtxCurrentIdx = 1,
        _Data          = nil,
        _VtxWritePtr   = 1,
        _IdxWritePtr   = 1,
        _Path          = ImVector(ImVec2, ImVec2_TCopy),
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
--- @field Pixels               unsigned_char[]
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
    this.Pixels               = nil
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
function MT.ImTextureData:GetPixelsAt(x, y)
    return self.Pixels, (x + y * self.Width) * self.BytesPerPixel + 1
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
function MT.ImFont:GetDebugName() if self.Sources.Size > 0 then return self.Sources[1].Name else return "<unknown>" end end

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
--- @field FontData             table
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
--- @field RendererHasTextures bool
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
    this.TexUvLines          = {}
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
function ImGuiKeyData() return { Down = false, DownDuration = nil, DownDurationPrev = nil, AnalogValue = nil } end

--- @enum ImGuiConfigFlags
ImGuiConfigFlags = {
    None                = 0,
    NavEnableKeyboard   = bit.lshift(1, 0),
    NavEnableGamepad    = bit.lshift(1, 1),
    NoMouse             = bit.lshift(1, 4),
    NoMouseCursorChange = bit.lshift(1, 5),
    NoKeyboard          = bit.lshift(1, 6),
    ViewportsEnable     = bit.lshift(1, 10),
    IsSRGB              = bit.lshift(1, 20),
    IsTouchScreen       = bit.lshift(1, 21)
}

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
        ConfigFlags  = ImGuiConfigFlags.None,
        DisplaySize = ImVec2(-1.0, -1.0),

        DeltaTime = 1.0 / 60.0,

        DisplayFramebufferScale = ImVec2(1.0, 1.0),

        MousePos = ImVec2(),
        MousePosPrev = ImVec2(),

        WantSetMousePos = false,

        MouseDelta = ImVec2(),

        MouseDown = {[0] = false, [1] = false, [2] = false},

        MouseWheel = 0,
        MouseWheelH = 0,

        MouseCtrlLeftAsRightClick = false,

        MouseWheelRequestAxisSwap = false,

        ConfigColorEditFlags = ImGuiColorEditFlags.DefaultOptions_,

        ConfigMacOSXBehaviors = false,
        ConfigNavCursorVisibleAuto = true,
        ConfigInputTrickleEventQueue = true,
        ConfigWindowsResizeFromEdges = true,

        ConfigDebugIniSettings = false,

        ConfigViewportsNoAutoMerge = false,
        ConfigViewportsNoTaskBarIcon = false,
        ConfigViewportsNoDecoration = true,
        ConfigViewportsNoDefaultParent = true,
        ConfigViewportsPlatformFocusSetsImGuiFocus = true,

        ConfigMemoryCompactTimer = 60.0,

        MouseDrawCursor = false,

        MouseClicked          = {[0] = false, [1] = false, [2] = false},
        MouseReleased         = {[0] = false, [1] = false, [2] = false},
        MouseClickedCount     = {[0] =  0, [1] =  0, [2] =  0},
        MouseClickedLastCount = {[0] =  0, [1] =  0, [2] =  0},
        MouseDownDuration     = {[0] = -1, [1] = -1, [2] = -1},
        MouseDownDurationPrev = {[0] = -1, [1] = -1, [2] = -1},

        MouseDragMaxDistanceAbs = {[0] = ImVec2(), [1] = ImVec2(), [2] = ImVec2()},
        MouseDragMaxDistanceSqr = {[0] = 0, [1] = 0, [2] = 0},

        MouseDownOwned    = {[0] = nil, [1] = nil, [2] = nil},
        MouseDownOwnedUnlessPopupClose = {[0] = nil, [1] = nil, [2] = nil},
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

        AppAcceptingEvents = true,
        InputQueueSurrogate = 0
    }

    for i = 0, ImGuiKey.NamedKey_COUNT - 1 do
        this.KeysData[i] = ImGuiKeyData()
    end

    return setmetatable(this, MT.ImGuiIO)
end

--- @class ImGuiPlatformImeData
--- @field WantVisible     bool
--- @field WantTextInput   bool
--- @field InputPos        ImVec2
--- @field InputLineHeight float
--- @field ViewportId      ImGuiID

--- @return ImGuiPlatformImeData
--- @nodiscard
function ImGuiPlatformImeData()
    return {
        WantVisible     = false,
        WantTextInput   = false,
        InputPos        = ImVec2(),
        InputLineHeight = 0.0,
        ViewportId      = 0
    }
end

--- @param dest ImGuiPlatformImeData
--- @param src  ImGuiPlatformImeData
function ImGuiPlatformImeData_Copy(dest, src)
    dest.WantVisible = src.WantVisible
    dest.WantTextInput = src.WantTextInput
    ImVec2_Copy(dest.InputPos, src.InputPos)
    dest.InputLineHeight = src.InputLineHeight
    dest.ViewportId = src.ViewportId
end

--- @param data1 ImGuiPlatformImeData
--- @param data2 ImGuiPlatformImeData
function ImGuiPlatformImeData_Compare(data1, data2)
    if data1.WantVisible ~= data2.WantVisible or
        data1.WantTextInput ~= data2.WantTextInput or
        data1.InputPos ~= data2.InputPos or
        data1.InputLineHeight ~= data2.InputLineHeight or
        data1.ViewportId ~= data2.ViewportId then
        return false
    end

    return true
end

ImGuiMouseCursor = { None = -1, Arrow = 0, TextInput = 1, ResizeAll = 2, ResizeNS = 3, ResizeEW = 4, ResizeNESW = 5, ResizeNWSE = 6, Hand = 7, Wait = 8, Progress = 9, NotAllowed = 10, COUNT = 11 } --- @enum ImGuiMouseCursor

--- @enum ImGuiViewportFlags
ImGuiViewportFlags = {
    None                = 0,
    IsPlatformWindow    = b_ls(1, 0),
    IsPlatformMonitor   = b_ls(1, 1),
    OwnedByApp          = b_ls(1, 2),
    NoDecoration        = b_ls(1, 3),
    NoTaskBarIcon       = b_ls(1, 4),
    NoFocusOnAppearing  = b_ls(1, 5),
    NoFocusOnClick      = b_ls(1, 6),
    NoInputs            = b_ls(1, 7),
    NoRendererClear     = b_ls(1, 8),
    NoAutoMerge         = b_ls(1, 9),
    TopMost             = b_ls(1, 10),
    CanHostOtherWindows = b_ls(1, 11),

    IsMinimized = b_ls(1, 12),
    IsFocused   = b_ls(1, 13)
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
--- @field Platform_GetClipboardTextFn fun(ctx?: ImGuiContext): string
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

        Platform_LocaleDecimalPoint = 46, -- '.'

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

--- @enum ImGuiWindowFlags
ImGuiWindowFlags = {
    None                      = 0,
    NoTitleBar                = b_ls(1, 0),
    NoResize                  = b_ls(1, 1),
    NoMove                    = b_ls(1, 2),
    NoScrollbar               = b_ls(1, 3),
    NoScrollWithMouse         = b_ls(1, 4),
    NoCollapse                = b_ls(1, 5),
    AlwaysAutoResize          = b_ls(1, 6),
    NoBackground              = b_ls(1, 7),
    NoSavedSettings           = b_ls(1, 8),
    NoMouseInputs             = b_ls(1, 9),
    MenuBar                   = b_ls(1, 10),
    HorizontalScrollbar       = b_ls(1, 11),
    NoFocusOnAppearing        = b_ls(1, 12),
    NoBringToFrontOnFocus     = b_ls(1, 13),
    AlwaysVerticalScrollbar   = b_ls(1, 14),
    AlwaysHorizontalScrollbar = b_ls(1, 15),
    NoNavInputs               = b_ls(1, 16),
    NoNavFocus                = b_ls(1, 17),
    UnsavedDocument           = b_ls(1, 18),
    NoDocking                 = b_ls(1, 19),
    DockNodeHost              = b_ls(1, 23),
    ChildWindow               = b_ls(1, 24),
    Tooltip                   = b_ls(1, 25),
    Popup                     = b_ls(1, 26),
    Modal                     = b_ls(1, 27),
    ChildMenu                 = b_ls(1, 28)
}

-- [Internal]
ImGuiWindowFlags.NoNav        = b_or(ImGuiWindowFlags.NoNavInputs, ImGuiWindowFlags.NoNavFocus)
ImGuiWindowFlags.NoDecoration = b_or(ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.NoCollapse)
ImGuiWindowFlags.NoInputs     = b_or(ImGuiWindowFlags.NoMouseInputs, ImGuiWindowFlags.NoNavInputs, ImGuiWindowFlags.NoNavFocus)

--- @enum ImGuiItemFlags
ImGuiItemFlags = {
    None              = 0,
    NoTabStop         = b_ls(1, 0),
    NoNav             = b_ls(1, 1),
    NoNavDefaultFocus = b_ls(1, 2),
    ButtonRepeat      = b_ls(1, 3),
    AutoClosePopups   = b_ls(1, 4),
    AllowDuplicateId  = b_ls(1, 5),
    Disabled          = b_ls(1, 6)
}

--- @enum ImGuiItemStatusFlags
ImGuiItemStatusFlags = {
    None             = 0,
    HoveredRect      = b_ls(1, 0),
    HasDisplayRect   = b_ls(1, 1),
    Edited           = b_ls(1, 2),
    ToggledSelection = b_ls(1, 3),
    ToggledOpen      = b_ls(1, 4),
    HasDeactivated   = b_ls(1, 5),
    Deactivated      = b_ls(1, 6),
    HoveredWindow    = b_ls(1, 7),
    Visible          = b_ls(1, 8),
    HasClipRect      = b_ls(1, 9),
    HasShortcut      = b_ls(1, 10),
    EditedInternal   = b_ls(1, 11)
}

--- @enum ImGuiChildFlags
ImGuiChildFlags = {
    None                   = 0,
    Borders                = b_ls(1, 0),
    AlwaysUseWindowPadding = b_ls(1, 1),
    ResizeX                = b_ls(1, 2),
    ResizeY                = b_ls(1, 3),
    AutoResizeX            = b_ls(1, 4),
    AutoResizeY            = b_ls(1, 5),
    AlwaysAutoResize       = b_ls(1, 6),
    FrameStyle             = b_ls(1, 7),
    NavFlattened           = b_ls(1, 8)
}

ImGuiChildFlags.ResizeBoth = b_or(ImGuiChildFlags.ResizeX, ImGuiChildFlags.ResizeY)
ImGuiChildFlags.ResizeXAndY = ImGuiChildFlags.ResizeBoth

--- @enum ImGuiNextItemDataFlags
ImGuiNextItemDataFlags = {
    None           = 0,
    HasWidth       = b_ls(1, 0),
    HasOpen        = b_ls(1, 1),
    HasShortcut    = b_ls(1, 2),
    HasRefVal      = b_ls(1, 3),
    HasStorageID   = b_ls(1, 4),
    HasColorMarker = b_ls(1, 5)
}

--- @enum ImDrawFlags
ImDrawFlags = {
    None                    = 0,
    RoundCornersTopLeft     = b_ls(1, 4),
    RoundCornersTopRight    = b_ls(1, 5),
    RoundCornersBottomLeft  = b_ls(1, 6),
    RoundCornersBottomRight = b_ls(1, 7),
    RoundCornersNone        = b_ls(1, 8),
    Closed                  = b_ls(1, 9)
}

ImDrawFlags.RoundCornersTop      = b_or(ImDrawFlags.RoundCornersTopLeft, ImDrawFlags.RoundCornersTopRight)
ImDrawFlags.RoundCornersBottom   = b_or(ImDrawFlags.RoundCornersBottomLeft, ImDrawFlags.RoundCornersBottomRight)
ImDrawFlags.RoundCornersLeft     = b_or(ImDrawFlags.RoundCornersBottomLeft, ImDrawFlags.RoundCornersTopLeft)
ImDrawFlags.RoundCornersRight    = b_or(ImDrawFlags.RoundCornersBottomRight, ImDrawFlags.RoundCornersTopRight)
ImDrawFlags.RoundCornersAll      = b_or(ImDrawFlags.RoundCornersTopLeft, ImDrawFlags.RoundCornersTopRight, ImDrawFlags.RoundCornersBottomLeft, ImDrawFlags.RoundCornersBottomRight)
ImDrawFlags.RoundCornersDefault_ = ImDrawFlags.RoundCornersAll
ImDrawFlags.RoundCornersMask_    = b_or(ImDrawFlags.RoundCornersAll, ImDrawFlags.RoundCornersNone)
ImDrawFlags.InvalidMask_         = 0x8000000F

--- @enum ImDrawListFlags
ImDrawListFlags = {
    None                   = 0,
    AntiAliasedLines       = b_ls(1, 0),
    AntiAliasedLinesUseTex = b_ls(1, 1),
    AntiAliasedFill        = b_ls(1, 2),
    AllowVtxOffset         = b_ls(1, 3),
    TextNoPixelSnap        = b_ls(1, 4)
}

--- @enum ImFontFlags
ImFontFlags = {
    None            = 0,
    NoLoadError     = b_ls(1, 1),
    NoLoadGlyphs    = b_ls(1, 2),
    LockBakedSizes  = b_ls(1, 3),
    ImplicitRefSize = b_ls(1, 4)
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
    None          = 0,
    Always        = b_ls(1, 0),
    Once          = b_ls(1, 1),
    FirstUseEver  = b_ls(1, 2),
    Appearing     = b_ls(1, 3)
}

--- @enum ImGuiInputFlags
ImGuiInputFlags = {
    None                 = 0,
    Repeat               = b_ls(1, 0),
    RouteActive          = b_ls(1, 10),
    RouteFocused         = b_ls(1, 11),
    RouteGlobal          = b_ls(1, 12),
    RouteAlways          = b_ls(1, 13),
    RouteOverFocused     = b_ls(1, 14),
    RouteOverActive      = b_ls(1, 15),
    RouteUnlessBgFocused = b_ls(1, 16),
    RouteFromRootWindow  = b_ls(1, 17),
    Tooltip              = b_ls(1, 18)
}

--- @enum ImGuiButtonFlags
ImGuiButtonFlags = {
    None                          = 0,
    MouseButtonLeft               = b_ls(1, 0),
    MouseButtonRight              = b_ls(1, 1),
    MouseButtonMiddle             = b_ls(1, 2),
    EnableNav                     = b_ls(1, 3),
    PressedOnClick                = b_ls(1, 4),
    PressedOnClickRelease         = b_ls(1, 5),
    PressedOnClickReleaseAnywhere = b_ls(1, 6),
    PressedOnRelease              = b_ls(1, 7),
    PressedOnDoubleClick          = b_ls(1, 8),
    PressedOnDragDropHold         = b_ls(1, 9),
    FlattenChildren               = b_ls(1, 11),
    AllowOverlap                  = b_ls(1, 12),
    AlignTextBaseLine             = b_ls(1, 15),
    NoKeyModsAllowed              = b_ls(1, 16),
    NoHoldingActiveId             = b_ls(1, 17),
    NoNavFocus                    = b_ls(1, 18),
    NoHoveredOnFocus              = b_ls(1, 19),
    NoSetKeyOwner                 = b_ls(1, 20),
    NoTestKeyOwner                = b_ls(1, 21),
    NoFocus                       = b_ls(1, 22)
}

ImGuiButtonFlags.MouseButtonMask_  = b_or(ImGuiButtonFlags.MouseButtonLeft, ImGuiButtonFlags.MouseButtonRight, ImGuiButtonFlags.MouseButtonMiddle)
ImGuiButtonFlags.PressedOnMask_    = b_or(ImGuiButtonFlags.PressedOnClick, ImGuiButtonFlags.PressedOnClickRelease, ImGuiButtonFlags.PressedOnClickReleaseAnywhere, ImGuiButtonFlags.PressedOnRelease, ImGuiButtonFlags.PressedOnDoubleClick, ImGuiButtonFlags.PressedOnDragDropHold)
ImGuiButtonFlags.PressedOnDefault_ = ImGuiButtonFlags.PressedOnClickRelease
ImGuiButtonFlags.NoKeyModifiers    = ImGuiButtonFlags.NoKeyModsAllowed

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
    MenuItemRounding            = 35,
    SelectableRounding          = 36,
    DragDropTargetRounding      = 37,
    ButtonTextAlign             = 38,
    SelectableTextAlign         = 39,
    SeparatorTextBorderSize     = 40,
    SeparatorTextAlign          = 41,
    SeparatorTextPadding        = 42,
    COUNT                       = 43
}

--- @enum ImGuiHoveredFlags
ImGuiHoveredFlags = {
    None                         = 0,
    ChildWindows                 = b_ls(1, 0),
    RootWindow                   = b_ls(1, 1),
    AnyWindow                    = b_ls(1, 2),
    NoPopupHierarchy             = b_ls(1, 3),
    AllowWhenBlockedByPopup      = b_ls(1, 5),
    AllowWhenBlockedByActiveItem = b_ls(1, 7),
    AllowWhenOverlappedByItem    = b_ls(1, 8),
    AllowWhenOverlappedByWindow  = b_ls(1, 9),
    AllowWhenDisabled            = b_ls(1, 10),
    NoNavOverride                = b_ls(1, 11),
    ForTooltip                   = b_ls(1, 12),
    Stationary                   = b_ls(1, 13),
    DelayNone                    = b_ls(1, 14),
    DelayShort                   = b_ls(1, 15),
    DelayNormal                  = b_ls(1, 16),
    NoSharedDelay                = b_ls(1, 17)
}

ImGuiHoveredFlags.AllowWhenOverlapped = b_or(ImGuiHoveredFlags.AllowWhenOverlappedByItem, ImGuiHoveredFlags.AllowWhenOverlappedByWindow)
ImGuiHoveredFlags.RectOnly            = b_or(ImGuiHoveredFlags.AllowWhenBlockedByPopup, ImGuiHoveredFlags.AllowWhenBlockedByActiveItem, ImGuiHoveredFlags.AllowWhenOverlapped)
ImGuiHoveredFlags.RootAndChildWindows = b_or(ImGuiHoveredFlags.RootWindow, ImGuiHoveredFlags.ChildWindows)
ImGuiHoveredFlags.DelayMask_ = b_or(ImGuiHoveredFlags.DelayNone, ImGuiHoveredFlags.DelayShort, ImGuiHoveredFlags.DelayNormal, ImGuiHoveredFlags.NoSharedDelay)
ImGuiHoveredFlags.AllowedMaskForIsWindowHovered = b_or(ImGuiHoveredFlags.ChildWindows, ImGuiHoveredFlags.RootWindow, ImGuiHoveredFlags.AnyWindow, ImGuiHoveredFlags.NoPopupHierarchy, ImGuiHoveredFlags.AllowWhenBlockedByPopup, ImGuiHoveredFlags.AllowWhenBlockedByActiveItem, ImGuiHoveredFlags.ForTooltip, ImGuiHoveredFlags.Stationary)
ImGuiHoveredFlags.AllowedMaskForIsItemHovered = b_or(ImGuiHoveredFlags.AllowWhenBlockedByPopup, ImGuiHoveredFlags.AllowWhenBlockedByActiveItem, ImGuiHoveredFlags.AllowWhenOverlapped, ImGuiHoveredFlags.AllowWhenDisabled, ImGuiHoveredFlags.NoNavOverride, ImGuiHoveredFlags.ForTooltip, ImGuiHoveredFlags.Stationary, ImGuiHoveredFlags.DelayMask_)

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
ImGuiMod_Ctrl  = b_ls(1, 12)
ImGuiMod_Shift = b_ls(1, 13)
ImGuiMod_Alt   = b_ls(1, 14)
ImGuiMod_Super = b_ls(1, 15)
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
    CheckboxSelectedBg        = 19,
    SliderGrab                = 20,
    SliderGrabActive          = 21,
    Button                    = 22,
    ButtonHovered             = 23,
    ButtonActive              = 24,
    Header                    = 25,
    HeaderHovered             = 26,
    HeaderActive              = 27,
    Separator                 = 28,
    SeparatorHovered          = 29,
    SeparatorActive           = 30,
    ResizeGrip                = 31,
    ResizeGripHovered         = 32,
    ResizeGripActive          = 33,
    InputTextCursor           = 34,
    TabHovered                = 35,
    Tab                       = 36,
    TabSelected               = 37,
    TabSelectedOverline       = 38,
    TabDimmed                 = 39,
    TabDimmedSelected         = 40,
    TabDimmedSelectedOverline = 41,
    PlotLines                 = 42,
    PlotLinesHovered          = 43,
    PlotHistogram             = 44,
    PlotHistogramHovered      = 45,
    TableHeaderBg             = 46,
    TableBorderStrong         = 47,
    TableBorderLight          = 48,
    TableRowBg                = 49,
    TableRowBgAlt             = 50,
    TextLink                  = 51,
    TextSelectedBg            = 52,
    TreeLines                 = 53,
    DragDropTarget            = 54,
    DragDropTargetBg          = 55,
    UnsavedMarker             = 56,
    NavCursor                 = 57,
    NavWindowingHighlight     = 58,
    NavWindowingDimBg         = 59,
    ModalWindowDimBg          = 60,
    COUNT                     = 61
}

--- @enum ImGuiBackendFlags
ImGuiBackendFlags = {
    None                  = 0,
    HasGamepad            = b_ls(1, 0),
    HasMouseCursors       = b_ls(1, 1),
    HasSetMousePos        = b_ls(1, 2),
    RendererHasVtxOffset  = b_ls(1, 3),
    RendererHasTextures   = b_ls(1, 4),

    -- [BETA] Multi-Viewports
    RendererHasViewports    = b_ls(1, 10),
    PlatformHasViewports    = b_ls(1, 11),
    HasMouseHoveredViewport = b_ls(1, 12),
    HasParentViewport       = b_ls(1, 13)
}

--- @enum ImGuiDragDropFlags
ImGuiDragDropFlags = {
    None                     = 0,
    SourceNoPreviewTooltip   = b_ls(1, 0),
    SourceNoDisableHover     = b_ls(1, 1),
    SourceNoHoldToOpenOthers = b_ls(1, 2),
    SourceAllowNullID        = b_ls(1, 3),
    SourceExtern             = b_ls(1, 4),
    PayloadAutoExpire        = b_ls(1, 5),
    PayloadNoCrossContext    = b_ls(1, 6),
    PayloadNoCrossProcess    = b_ls(1, 7),
    AcceptBeforeDelivery     = b_ls(1, 10),
    AcceptNoDrawDefaultRect  = b_ls(1, 11),
    AcceptNoPreviewTooltip   = b_ls(1, 12),
    AcceptDrawAsHovered      = b_ls(1, 13)
}

ImGuiDragDropFlags.AcceptPeekOnly = b_or(ImGuiDragDropFlags.AcceptBeforeDelivery, ImGuiDragDropFlags.AcceptNoDrawDefaultRect)

--- Note that `S64` and `U64` are not supported
--- @enum ImGuiDataType
ImGuiDataType = {
    S8     = 0, -- signed char / char
    U8     = 1, -- unsigned char
    S16    = 2, -- short
    U16    = 3, -- unsigned short
    S32    = 4, -- int
    U32    = 5, -- unsigned int
    Float  = 6, -- float
    Double = 7, -- double
    Bool   = 8, -- bool (provided for user convenience, not supported by scalar widgets)
    String = 9, -- string (provided for user convenience, not supported by scalar widgets)
    COUNT  = 10
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
IM_COL32             = function(R, G, B, A) return (b_or(b_ls(A, IM_COL32_A_SHIFT), b_ls(B, IM_COL32_B_SHIFT), b_ls(G, IM_COL32_G_SHIFT), b_ls(R, IM_COL32_R_SHIFT))) end
IM_COL32_WHITE       = IM_COL32(255, 255, 255, 255)
IM_COL32_BLACK       = IM_COL32(0, 0, 0, 255)
IM_COL32_BLACK_TRANS = IM_COL32(0, 0, 0, 0)

--- @enum ImGuiPopupFlags
ImGuiPopupFlags = {
    None                    = 0,
    MouseButtonLeft         = b_ls(1, 2),
    MouseButtonRight        = b_ls(2, 2),
    MouseButtonMiddle       = b_ls(3, 2),
    NoReopen                = b_ls(1, 5),
    NoOpenOverExistingPopup = b_ls(1, 7),
    NoOpenOverItems         = b_ls(1, 8),
    AnyPopupId              = b_ls(1, 10),
    AnyPopupLevel           = b_ls(1, 11)
}

ImGuiPopupFlags.AnyPopup          = b_or(ImGuiPopupFlags.AnyPopupId, ImGuiPopupFlags.AnyPopupLevel)
ImGuiPopupFlags.MouseButtonShift_ = 2
ImGuiPopupFlags.MouseButtonMask_  = 0x0C
ImGuiPopupFlags.InvalidMask_      = 0x03

--- @enum ImGuiComboFlags
ImGuiComboFlags = {
    None            = 0,
    PopupAlignLeft  = b_ls(1, 0),
    HeightSmall     = b_ls(1, 1),
    HeightRegular   = b_ls(1, 2),
    HeightLarge     = b_ls(1, 3),
    HeightLargest   = b_ls(1, 4),
    NoArrowButton   = b_ls(1, 5),
    NoPreview       = b_ls(1, 6),
    WidthFitPreview = b_ls(1, 7)
}

ImGuiComboFlags.HeightMask_ = b_or(ImGuiComboFlags.HeightSmall, ImGuiComboFlags.HeightRegular, ImGuiComboFlags.HeightLarge, ImGuiComboFlags.HeightLargest)
ImGuiComboFlags.CustomPreview = b_ls(1, 20)

--- @enum ImGuiSelectableFlags
ImGuiSelectableFlags = {
    None              = 0,
    NoAutoClosePopups = b_ls(1, 0),
    SpanAllColumns    = b_ls(1, 1),
    AllowDoubleClick  = b_ls(1, 2),
    Disabled          = b_ls(1, 3),
    AllowOverlap      = b_ls(1, 4),
    Highlight         = b_ls(1, 5),
    SelectOnNav       = b_ls(1, 6),

    NoHoldingActiveID    = b_ls(1, 20),
    SelectOnClick        = b_ls(1, 22),
    SelectOnRelease      = b_ls(1, 23),
    SpanAvailWidth       = b_ls(1, 24),
    SetNavIdOnHover      = b_ls(1, 25),
    NoPadWithHalfSpacing = b_ls(1, 26),
    NoSetKeyOwner        = b_ls(1, 27),
}

--- @enum ImGuiColorEditFlags
ImGuiColorEditFlags = {
    None           = 0,
    NoAlpha        = b_ls(1, 1),
    NoPicker       = b_ls(1, 2),
    NoOptions      = b_ls(1, 3),
    NoSmallPreview = b_ls(1, 4),
    NoInputs       = b_ls(1, 5),
    NoTooltip      = b_ls(1, 6),
    NoLabel        = b_ls(1, 7),
    NoSidePreview  = b_ls(1, 8),
    NoDragDrop     = b_ls(1, 9),
    NoBorder       = b_ls(1, 10),
    NoColorMarkers = b_ls(1, 11),

    -- Alpha preview
    AlphaOpaque      = b_ls(1, 12),
    AlphaNoBg        = b_ls(1, 13),
    AlphaPreviewHalf = b_ls(1, 14),

    -- User Options (right-click on widget to change some of them)
    AlphaBar       = b_ls(1, 18),
    HDR            = b_ls(1, 19),
    DisplayRGB     = b_ls(1, 20),
    DisplayHSV     = b_ls(1, 21),
    DisplayHex     = b_ls(1, 22),
    Uint8          = b_ls(1, 23),
    Float          = b_ls(1, 24),
    PickerHueBar   = b_ls(1, 25),
    PickerHueWheel = b_ls(1, 26),
    PickerNoRotate = b_ls(1, 27),
    InputRGB       = b_ls(1, 28),
    InputHSV       = b_ls(1, 29)
}

ImGuiColorEditFlags.DefaultOptions_ = b_or(ImGuiColorEditFlags.Uint8, ImGuiColorEditFlags.DisplayRGB, ImGuiColorEditFlags.InputRGB, ImGuiColorEditFlags.PickerHueBar)
ImGuiColorEditFlags.AlphaMask_ = b_or( ImGuiColorEditFlags.NoAlpha, ImGuiColorEditFlags.AlphaOpaque, ImGuiColorEditFlags.AlphaNoBg, ImGuiColorEditFlags.AlphaPreviewHalf )
ImGuiColorEditFlags.DisplayMask_ = b_or( ImGuiColorEditFlags.DisplayRGB, ImGuiColorEditFlags.DisplayHSV, ImGuiColorEditFlags.DisplayHex )
ImGuiColorEditFlags.DataTypeMask_ = b_or( ImGuiColorEditFlags.Uint8, ImGuiColorEditFlags.Float )
ImGuiColorEditFlags.PickerMask_ = b_or( ImGuiColorEditFlags.PickerHueWheel, ImGuiColorEditFlags.PickerHueBar )
ImGuiColorEditFlags.InputMask_ = b_or( ImGuiColorEditFlags.InputRGB, ImGuiColorEditFlags.InputHSV )

--- @enum ImGuiSliderFlags
ImGuiSliderFlags = {
    None            = 0,
    Logarithmic     = b_ls(1, 5),
    NoRoundToFormat = b_ls(1, 6),
    NoInput         = b_ls(1, 7),
    WrapAround      = b_ls(1, 8),
    ClampOnInput    = b_ls(1, 9),
    ClampZeroRange  = b_ls(1, 10),
    NoSpeedTweaks   = b_ls(1, 11),
    ColorMarkers    = b_ls(1, 12),
    InvalidMask_    = 0x7000000F,
}

ImGuiSliderFlags.AlwaysClamp = b_or(ImGuiSliderFlags.ClampOnInput, ImGuiSliderFlags.ClampZeroRange)

ImGuiSliderFlags.Vertical = b_ls(1, 20)
ImGuiSliderFlags.ReadOnly = b_ls(1, 21)

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

--- @enum ImGuiInputTextFlags
ImGuiInputTextFlags = {
    None = 0,

    -- Basic filters (also see ImGuiInputTextFlags.CallbackCharFilter)
    CharsDecimal     = b_ls(1, 0),
    CharsHexadecimal = b_ls(1, 1),
    CharsScientific  = b_ls(1, 2),
    CharsUppercase   = b_ls(1, 3),
    CharsNoBlank     = b_ls(1, 4),

    -- Inputs
    AllowTabInput       = b_ls(1, 5),
    EnterReturnsTrue    = b_ls(1, 6),
    EscapeClearsAll     = b_ls(1, 7),
    CtrlEnterForNewLine = b_ls(1, 8),

    -- Other options
    ReadOnly           = b_ls(1, 9),
    Password           = b_ls(1, 10),
    AlwaysOverwrite    = b_ls(1, 11),
    AutoSelectAll      = b_ls(1, 12),
    ParseEmptyRefVal   = b_ls(1, 13),
    DisplayEmptyRefVal = b_ls(1, 14),
    NoHorizontalScroll = b_ls(1, 15),
    NoUndoRedo         = b_ls(1, 16),

    -- Elide display / Alignment
    ElideLeft = b_ls(1, 17),

    -- Callback features
    CallbackCompletion = b_ls(1, 18),
    CallbackHistory    = b_ls(1, 19),
    CallbackAlways     = b_ls(1, 20),
    CallbackCharFilter = b_ls(1, 21),
    CallbackResize     = b_ls(1, 22),
    CallbackEdit       = b_ls(1, 23),

    -- Multi-line Word-Wrapping [BETA]
    WordWrap = b_ls(1, 24),

    -- [Internal]
    Multiline            = b_ls(1, 26),
    TempInput            = b_ls(1, 27),
    LocalizeDecimalPoint = b_ls(1, 28),
}

--- @class ImGuiInputTextCallbackData

--- @return ImGuiInputTextCallbackData
function ImGuiInputTextCallbackData()
    return {}
end

--- @alias ImGuiInputTextCallback fun(data: ImGuiInputTextCallbackData)

--- @alias ImGuiMemAllocFunc fun(T: function, start_idx: int, end_idx: int, userdata: any): table
--- @alias ImGuiMemFreeFunc fun(owner: table, field: string, userdata: any)

--- @alias ImDrawCallback fun(parent_list: ImDrawList, cmd: ImDrawCmd)

--- @enum ImGuiTreeNodeFlags
ImGuiTreeNodeFlags = {
    None                 = 0,
    Selected             = b_ls(1, 0),
    Framed               = b_ls(1, 1),
    AllowOverlap         = b_ls(1, 2),
    NoTreePushOnOpen     = b_ls(1, 3),
    NoAutoOpenOnLog      = b_ls(1, 4),
    DefaultOpen          = b_ls(1, 5),
    OpenOnDoubleClick    = b_ls(1, 6),
    OpenOnArrow          = b_ls(1, 7),
    Leaf                 = b_ls(1, 8),
    Bullet               = b_ls(1, 9),
    FramePadding         = b_ls(1, 10),
    SpanAvailWidth       = b_ls(1, 11),
    SpanFullWidth        = b_ls(1, 12),
    SpanLabelWidth       = b_ls(1, 13),
    SpanAllColumns       = b_ls(1, 14),
    LabelSpanAllColumns  = b_ls(1, 15),
    NavLeftJumpsToParent = b_ls(1, 17),
    DrawLinesNone        = b_ls(1, 18),
    DrawLinesFull        = b_ls(1, 19),
    DrawLinesToNodes     = b_ls(1, 20),

    NoNavFocus                 = b_ls(1, 27),
    ClipLabelForTrailingButton = b_ls(1, 28),
    UpsideDownArrow            = b_ls(1, 29),
}

ImGuiTreeNodeFlags.CollapsingHeader = b_or(ImGuiTreeNodeFlags.Framed, ImGuiTreeNodeFlags.NoTreePushOnOpen, ImGuiTreeNodeFlags.NoAutoOpenOnLog)

ImGuiTreeNodeFlags.OpenOnMask_ = b_or(ImGuiTreeNodeFlags.OpenOnDoubleClick, ImGuiTreeNodeFlags.OpenOnArrow)
ImGuiTreeNodeFlags.DrawLinesMask_ = b_or(ImGuiTreeNodeFlags.DrawLinesNone, ImGuiTreeNodeFlags.DrawLinesFull, ImGuiTreeNodeFlags.DrawLinesToNodes)

--- @enum ImGuiTableFlags
ImGuiTableFlags = {
    None = 0,
}
