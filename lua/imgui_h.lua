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

#IMGUI_DEFINE struct_def(_name) local GMetaTables = GMetaTables or {}; GMetaTables[_name] = {}; GMetaTables[_name].__index = GMetaTables[_name]
#IMGUI_DEFINE struct_method function GMetaTables.

#IMGUI_DEFINE IM_DELETE(_t) _t = nil

--- enum ImTextureStatus
#IMGUI_DEFINE ImTextureStatus_OK          0
#IMGUI_DEFINE ImTextureStatus_Destroyed   1
#IMGUI_DEFINE ImTextureStatus_WantCreate  2
#IMGUI_DEFINE ImTextureStatus_WantUpdates 3
#IMGUI_DEFINE ImTextureStatus_WantDestroy 4

--- enum ImFontAtlasFlags_
#IMGUI_DEFINE ImFontAtlasFlags_None               0
#IMGUI_DEFINE ImFontAtlasFlags_NoPowerOfTwoHeight bit.lshift(1, 0)
#IMGUI_DEFINE ImFontAtlasFlags_NoMouseCursors     bit.lshift(1, 1)
#IMGUI_DEFINE ImFontAtlasFlags_NoBakedLines       bit.lshift(1, 2)

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

--- @return ImVec2
--- @nodiscard
local function ImVec2(x, y) return setmetatable({x = x or 0, y = y or 0}, GMetaTables.ImVec2) end

struct_method ImVec2:__add(other) return ImVec2(self.x + other.x, self.y + other.y) end
struct_method ImVec2:__sub(other) return ImVec2(self.x - other.x, self.y - other.y) end
struct_method ImVec2:__mul(other) if isnumber(self) then return ImVec2(self * other.x, self * other.y) elseif isnumber(other) then return ImVec2(self.x * other, self.y * other) else return ImVec2(self.x * other.x, self.y * other.y) end end
struct_method ImVec2:__eq(other) return self.x == other.x and self.y == other.y end
struct_method ImVec2:__tostring() return string.format("ImVec2(%g, %g)", self.x, self.y) end
struct_method ImVec2:copy() return ImVec2(self.x, self.y) end

--- @class ImVec4
--- @field x number
--- @field y number
--- @field z number
--- @field w number
struct_def("ImVec4")

--- @return ImVec4
--- @nodiscard
local function ImVec4(x, y, z, w) return setmetatable({x = x or 0, y = y or 0, z = z or 0, w = w or 0}, GMetaTables.ImVec4) end

struct_method ImVec4:__add(other) return ImVec4(self.x + other.x, self.y + other.y, self.z + other.z, self.w + other.w) end
struct_method ImVec4:__sub(other) return ImVec4(self.x - other.x, self.y - other.y, self.z - other.z, self.w - other.w) end
struct_method ImVec4:__mul(other) if isnumber(self) then return ImVec4(self * other.x, self * other.y, self * other.z, self * other.w) elseif isnumber(other) then return ImVec4(self.x * other, self.y * other, self.z * other, self.w * other) else return ImVec4(self.x * other.x, self.y * other.y, self.z * other.z, self.w * other.w) end end
struct_method ImVec4:__eq(other) return self.x == other.x and self.y == other.y and self.z == other.z and self.w == other.w end

--- A compact ImVector clone, maybe
--- @class ImVector
struct_def("ImVector")

struct_method ImVector:push_back(value) self.Size = self.Size + 1 self.Data[self.Size] = value end
struct_method ImVector:pop_back() if self.Size == 0 then return nil end local value = self.Data[self.Size] self.Data[self.Size] = nil self.Size = self.Size - 1 return value end
struct_method ImVector:clear() self.Size = 0 end
struct_method ImVector:clear_delete() for i = 1, self.Size do self.Data[i] = nil end self.Size = 0 end
struct_method ImVector:empty() return self.Size == 0 end
struct_method ImVector:back() if self.Size == 0 then return nil end return self.Data[self.Size] end
struct_method ImVector:erase(i) if i < 1 or i > self.Size then return nil end local removed = table.remove(self.Data, i) self.Size = self.Size - 1 return removed end
struct_method ImVector:at(i) if i < 1 or i > self.Size then return nil end return self.Data[i] end
struct_method ImVector:iter() local i, n = 0, self.Size return function() i = i + 1 if i <= n then return i, self.Data[i] end end end
struct_method ImVector:find_index(value) for i = 1, self.Size do if self.Data[i] == value then return i end end return 0 end
struct_method ImVector:erase_unsorted(index) if index < 1 or index > self.Size then return false end local last_idx = self.Size if index ~= last_idx then self.Data[index] = self.Data[last_idx] end self.Data[last_idx] = nil self.Size = self.Size - 1 return true end
struct_method ImVector:find_erase_unsorted(value) local idx = self:find_index(value) if idx > 0 then return self:erase_unsorted(idx) end return false end
struct_method ImVector:reserve() return end
struct_method ImVector:reserve_discard() return end
struct_method ImVector:shrink() return end
struct_method ImVector:resize(new_size) self.Size = new_size end
struct_method ImVector:swap(other) self.Size, other.Size = other.Size, self.Size self.Data, other.Data = other.Data, self.Data end

--- @return ImVector
--- @nodiscard
local function ImVector() return setmetatable({Data = {}, Size = 0}, GMetaTables.ImVector) end

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
    }, GMetaTables.ImDrawCmd) -- TODO: callback
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
    }, GMetaTables.ImDrawCmdHeader)
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
    }, GMetaTables.ImDrawList)
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
    }, GMetaTables.ImDrawData)
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
    }, GMetaTables.ImTextureData)

    this.Status = ImTextureStatus_Destroyed
    this.TexID = ImTextureID_Invalid

    return this
end

struct_method ImTextureData:GetPixelsAt(x, y)
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
    }, GMetaTables.ImTextureRef)
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
    }, GMetaTables.ImFontBaked)
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
    }, GMetaTables.ImFont)
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
    }, GMetaTables.ImFontConfig)
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
    }, GMetaTables.ImFontAtlas)

    this.TexRef._TexID = ImTextureID_Invalid

    return this
end

local function ImFontAtlasRect()
    return {
        x = nil, y = nil,
        w = nil, h = nil,
        uv0 = ImVec2(),
        uv1 = ImVec2()
    }
end

--- struct ImFontGlyph
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

-- TODO: enums, evals?
#IMGUI_DEFINE ImGuiDir_Left  0
#IMGUI_DEFINE ImGuiDir_Right 1
#IMGUI_DEFINE ImGuiDir_Up    2
#IMGUI_DEFINE ImGuiDir_Down  3

--- enum ImGuiWindowFlags_
#IMGUI_DEFINE ImGuiWindowFlags_None                      0
#IMGUI_DEFINE ImGuiWindowFlags_NoTitleBar                bit.lshift(1, 0)
#IMGUI_DEFINE ImGuiWindowFlags_NoResize                  bit.lshift(1, 1)
#IMGUI_DEFINE ImGuiWindowFlags_NoMove                    bit.lshift(1, 2)
#IMGUI_DEFINE ImGuiWindowFlags_NoScrollbar               bit.lshift(1, 3)
#IMGUI_DEFINE ImGuiWindowFlags_NoScrollWithMouse         bit.lshift(1, 4)
#IMGUI_DEFINE ImGuiWindowFlags_NoCollapse                bit.lshift(1, 5)
#IMGUI_DEFINE ImGuiWindowFlags_AlwaysAutoResize          bit.lshift(1, 6)
#IMGUI_DEFINE ImGuiWindowFlags_NoBackground              bit.lshift(1, 7)
#IMGUI_DEFINE ImGuiWindowFlags_NoSavedSettings           bit.lshift(1, 8)
#IMGUI_DEFINE ImGuiWindowFlags_NoMouseInputs             bit.lshift(1, 9)
#IMGUI_DEFINE ImGuiWindowFlags_MenuBar                   bit.lshift(1, 10)
#IMGUI_DEFINE ImGuiWindowFlags_HorizontalScrollbar       bit.lshift(1, 11)
#IMGUI_DEFINE ImGuiWindowFlags_NoFocusOnAppearing        bit.lshift(1, 12)
#IMGUI_DEFINE ImGuiWindowFlags_NoBringToFrontOnFocus     bit.lshift(1, 13)
#IMGUI_DEFINE ImGuiWindowFlags_AlwaysVerticalScrollbar   bit.lshift(1, 14)
#IMGUI_DEFINE ImGuiWindowFlags_AlwaysHorizontalScrollbar bit.lshift(1, 15)
#IMGUI_DEFINE ImGuiWindowFlags_NoNavInputs               bit.lshift(1, 16)
#IMGUI_DEFINE ImGuiWindowFlags_NoNavFocus                bit.lshift(1, 17)
#IMGUI_DEFINE ImGuiWindowFlags_UnsavedDocument           bit.lshift(1, 18)
#IMGUI_DEFINE ImGuiWindowFlags_ChildWindow               bit.lshift(1, 24)
#IMGUI_DEFINE ImGuiWindowFlags_Tooltip                   bit.lshift(1, 25)
#IMGUI_DEFINE ImGuiWindowFlags_Popup                     bit.lshift(1, 26)
#IMGUI_DEFINE ImGuiWindowFlags_Modal                     bit.lshift(1, 27)
#IMGUI_DEFINE ImGuiWindowFlags_ChildMenu                 bit.lshift(1, 28)

#IMGUI_DEFINE ImGuiWindowFlags_NoNav        bit.bor(ImGuiWindowFlags_NoNavInputs, ImGuiWindowFlags_NoNavFocus)
#IMGUI_DEFINE ImGuiWindowFlags_NoDecoration bit.bor(ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoResize, ImGuiWindowFlags_NoScrollbar, ImGuiWindowFlags_NoCollapse)
#IMGUI_DEFINE ImGuiWindowFlags_NoInputs     bit.bor(ImGuiWindowFlags_NoMouseInputs, ImGuiWindowFlags_NoNavInputs, ImGuiWindowFlags_NoNavFocus)

--- enum ImGuiItemFlags_
#IMGUI_DEFINE ImGuiItemFlags_None              0
#IMGUI_DEFINE ImGuiItemFlags_NoTabStop         bit.lshift(1, 0)
#IMGUI_DEFINE ImGuiItemFlags_NoNav             bit.lshift(1, 1)
#IMGUI_DEFINE ImGuiItemFlags_NoNavDefaultFocus bit.lshift(1, 2)
#IMGUI_DEFINE ImGuiItemFlags_ButtonRepeat      bit.lshift(1, 3)
#IMGUI_DEFINE ImGuiItemFlags_AutoClosePopups   bit.lshift(1, 4)
#IMGUI_DEFINE ImGuiItemFlags_AllowDuplicateID  bit.lshift(1, 5)

#IMGUI_DEFINE ImGuiItemStatusFlags_None             0
#IMGUI_DEFINE ImGuiItemStatusFlags_HoveredRect      bit.lshift(1, 0)
#IMGUI_DEFINE ImGuiItemStatusFlags_HasDisplayRect   bit.lshift(1, 1)
#IMGUI_DEFINE ImGuiItemStatusFlags_Edited           bit.lshift(1, 2)
#IMGUI_DEFINE ImGuiItemStatusFlags_ToggledSelection bit.lshift(1, 3)
#IMGUI_DEFINE ImGuiItemStatusFlags_ToggledOpen      bit.lshift(1, 4)
#IMGUI_DEFINE ImGuiItemStatusFlags_HasDeactivated   bit.lshift(1, 5)
#IMGUI_DEFINE ImGuiItemStatusFlags_Deactivated      bit.lshift(1, 6)
#IMGUI_DEFINE ImGuiItemStatusFlags_HoveredWindow    bit.lshift(1, 7)
#IMGUI_DEFINE ImGuiItemStatusFlags_Visible          bit.lshift(1, 8)
#IMGUI_DEFINE ImGuiItemStatusFlags_HasClipRect      bit.lshift(1, 9)
#IMGUI_DEFINE ImGuiItemStatusFlags_HasShortcut      bit.lshift(1, 10)

--- enum ImDrawFlags_
#IMGUI_DEFINE ImDrawFlags_None                    0
#IMGUI_DEFINE ImDrawFlags_Closed                  bit.lshift(1, 0)
#IMGUI_DEFINE ImDrawFlags_RoundCornersTopLeft     bit.lshift(1, 4)
#IMGUI_DEFINE ImDrawFlags_RoundCornersTopRight    bit.lshift(1, 5)
#IMGUI_DEFINE ImDrawFlags_RoundCornersBottomLeft  bit.lshift(1, 6)
#IMGUI_DEFINE ImDrawFlags_RoundCornersBottomRight bit.lshift(1, 7)
#IMGUI_DEFINE ImDrawFlags_RoundCornersNone        bit.lshift(1, 8)

#IMGUI_DEFINE ImDrawFlags_RoundCornersTop     bit.bor(ImDrawFlags_RoundCornersTopLeft, ImDrawFlags_RoundCornersTopRight)
#IMGUI_DEFINE ImDrawFlags_RoundCornersBottom  bit.bor(ImDrawFlags_RoundCornersBottomLeft, ImDrawFlags_RoundCornersBottomRight)
#IMGUI_DEFINE ImDrawFlags_RoundCornersLeft    bit.bor(ImDrawFlags_RoundCornersBottomLeft, ImDrawFlags_RoundCornersTopLeft)
#IMGUI_DEFINE ImDrawFlags_RoundCornersRight   bit.bor(ImDrawFlags_RoundCornersBottomRight, ImDrawFlags_RoundCornersTopRight)
#IMGUI_DEFINE ImDrawFlags_RoundCornersAll     bit.bor(ImDrawFlags_RoundCornersTopLeft, ImDrawFlags_RoundCornersTopRight, ImDrawFlags_RoundCornersBottomLeft, ImDrawFlags_RoundCornersBottomRight)
#IMGUI_DEFINE ImDrawFlags_RoundCornersMask    bit.bor(ImDrawFlags_RoundCornersAll, ImDrawFlags_RoundCornersNone)
#IMGUI_DEFINE ImDrawFlags_RoundCornersDefault ImDrawFlags_RoundCornersAll

#IMGUI_DEFINE ImDrawListFlags_None                   0
#IMGUI_DEFINE ImDrawListFlags_AntiAliasedLines       bit.lshift(1, 0)
#IMGUI_DEFINE ImDrawListFlags_AntiAliasedLinesUseTex bit.lshift(1, 1)
#IMGUI_DEFINE ImDrawListFlags_AntiAliasedFill        bit.lshift(1, 2)
#IMGUI_DEFINE ImDrawListFlags_AllowVtxOffset         bit.lshift(1, 3)

--- enum ImFontFlags_
#IMGUI_DEFINE ImFontFlags_None           0
#IMGUI_DEFINE ImFontFlags_NoLoadError    bit.lshift(1, 1)
#IMGUI_DEFINE ImFontFlags_NoLoadGlyphs   bit.lshift(1, 2)
#IMGUI_DEFINE ImFontFlags_LockBakedSizes bit.lshift(1, 3)