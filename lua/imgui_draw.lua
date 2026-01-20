--- If lower, the window title cross or arrow will look awful
-- TODO: let client decide?
RunConsoleCommand("mat_antialias", "8")

--- @param _c string
--- @return char
--- @package
local function chr(_c) return string.byte(_c) end

FONT_ATLAS_DEFAULT_TEX_DATA_W = 122
FONT_ATLAS_DEFAULT_TEX_DATA_H = 27

IM_FONTGLYPH_INDEX_UNUSED    = 0xFFFF
IM_FONTGLYPH_INDEX_NOT_FOUND = 0xFFFE

--- Original ImGui pixel art!
FONT_ATLAS_DEFAULT_TEX_DATA_PIXELS = IM_SLICE(string.ToTable(
    "..-         -XXXXXXX-    X    -           X           -XXXXXXX          -          XXXXXXX-     XX          - XX       XX " ..
    "..-         -X.....X-   X.X   -          X.X          -X.....X          -          X.....X-    X..X         -X..X     X..X" ..
    "---         -XXX.XXX-  X...X  -         X...X         -X....X           -           X....X-    X..X         -X...X   X...X" ..
    "X           -  X.X  - X.....X -        X.....X        -X...X            -            X...X-    X..X         - X...X X...X " ..
    "XX          -  X.X  -X.......X-       X.......X       -X..X.X           -           X.X..X-    X..X         -  X...X...X  " ..
    "X.X         -  X.X  -XXXX.XXXX-       XXXX.XXXX       -X.X X.X          -          X.X X.X-    X..XXX       -   X.....X   " ..
    "X..X        -  X.X  -   X.X   -          X.X          -XX   X.X         -         X.X   XX-    X..X..XXX    -    X...X    " ..
    "X...X       -  X.X  -   X.X   -    XX    X.X    XX    -      X.X        -        X.X      -    X..X..X..XX  -     X.X     " ..
    "X....X      -  X.X  -   X.X   -   X.X    X.X    X.X   -       X.X       -       X.X       -    X..X..X..X.X -    X...X    " ..
    "X.....X     -  X.X  -   X.X   -  X..X    X.X    X..X  -        X.X      -      X.X        -XXX X..X..X..X..X-   X.....X   " ..
    "X......X    -  X.X  -   X.X   - X...XXXXXX.XXXXXX...X -         X.X   XX-XX   X.X         -X..XX........X..X-  X...X...X  " ..
    "X.......X   -  X.X  -   X.X   -X.....................X-          X.X X.X-X.X X.X          -X...X...........X- X...X X...X " ..
    "X........X  -  X.X  -   X.X   - X...XXXXXX.XXXXXX...X -           X.X..X-X..X.X           - X..............X-X...X   X...X" ..
    "X.........X -XXX.XXX-   X.X   -  X..X    X.X    X..X  -            X...X-X...X            -  X.............X-X..X     X..X" ..
    "X..........X-X.....X-   X.X   -   X.X    X.X    X.X   -           X....X-X....X           -  X.............X- XX       XX " ..
    "X......XXXXX-XXXXXXX-   X.X   -    XX    X.X    XX    -          X.....X-X.....X          -   X............X--------------" ..
    "X...X..X    ---------   X.X   -          X.X          -          XXXXXXX-XXXXXXX          -   X...........X -             " ..
    "X..X X..X   -       -XXXX.XXXX-       XXXX.XXXX       -------------------------------------    X..........X -             " ..
    "X.X  X..X   -       -X.......X-       X.......X       -    XX           XX    -           -    X..........X -             " ..
    "XX    X..X  -       - X.....X -        X.....X        -   X.X           X.X   -           -     X........X  -             " ..
    "      X..X  -       -  X...X  -         X...X         -  X..X           X..X  -           -     X........X  -             " ..
    "       XX   -       -   X.X   -          X.X          - X...XXXXXXXXXXXXX...X -           -     XXXXXXXXXX  -             " ..
    "-------------       -    X    -           X           -X.....................X-           -------------------             " ..
    "                    ----------------------------------- X...XXXXXXXXXXXXX...X -                                           " ..
    "                                                      -  X..X           X..X  -                                           " ..
    "                                                      -   X.X           X.X   -                                           " ..
    "                                                      -    XX           XX    -                                           "
))

--- @module "imstb_rectpack"
stbrp = include("imstb_rectpack.lua")

--- @module "imstb_truetype"
stbtt = include("imstb_truetype.lua")

function ImGui.StyleColorsDark(dst)
    local style = dst and dst or ImGui.GetStyle()
    local colors = style.Colors

    -- i don't use enums to index here
    colors["Text"]              = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors["WindowBg"]          = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors["Border"]            = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors["BorderShadow"]      = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors["TitleBg"]           = ImVec4(0.04, 0.04, 0.04, 1.00)
    colors["TitleBgActive"]     = ImVec4(0.16, 0.29, 0.48, 1.00)
    colors["TitleBgCollapsed"]  = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors["MenuBarBg"]         = ImVec4(0.14, 0.14, 0.14, 1.00)
    colors["Button"]            = ImVec4(0.26, 0.59, 0.98, 0.40)
    colors["ButtonHovered"]     = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors["ButtonActive"]      = ImVec4(0.06, 0.53, 0.98, 1.00)
    colors["ResizeGrip"]        = ImVec4(0.26, 0.59, 0.98, 0.20)
    colors["ResizeGripHovered"] = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors["ResizeGripActive"]  = ImVec4(0.26, 0.59, 0.98, 0.95)
end

local ImFontAtlasTextureAdd
local ImFontAtlasTextureGrow
local ImFontAtlasPackInit
local ImFontAtlasPackAddRect
local ImFontAtlasPackGetRect
local ImFontAtlasPackGetRectSafe
local ImFontAtlasBakedDiscard
local ImFontAtlasBuildSetTexture
local ImFontAtlasBuildUpdateLinesTexData
local ImFontAtlasBuildUpdateBasicTexData
local ImFontAtlasBuildSetupFontLoader
local ImFontAtlasBuildDestroy
local ImFontAtlasFontSourceInit
local ImFontAtlasFontSourceAddToFont
local ImFontAtlasFontDestroySourceData
local ImFontAtlasFontDestroyOutput
local ImFontAtlasBuildSetupFontSpecialGlyphs
local ImFontAtlasBuildSetupFontBakedFallback

function MT.ImFontAtlas:Clear()
    local backup_renderer_has_textures = self.RendererHasTextures
    self.RendererHasTextures = false
    self:ClearFonts()
    self:ClearTexData()
    self.RendererHasTextures = backup_renderer_has_textures
end

function MT.ImFontAtlas:SetFontLoader(font_loader)
    ImFontAtlasBuildSetupFontLoader(self, font_loader)
end

function MT.ImFontAtlas:ClearInputData()
    IM_ASSERT(not self.Locked, "Cannot modify a locked ImFontAtlas!")

    for _, font in self.Fonts:iter() do
        ImFontAtlasFontDestroyOutput(self, font)
    end
    for _, font_cfg in self.Sources:iter() do
        ImFontAtlasFontDestroySourceData(self, font_cfg)
    end
    for _, font in self.Fonts:iter() do
        font.Sources:clear()
        font.Flags = bit.bor(font.Flags, ImFontFlags.NoLoadGlyphs)
    end
    self.Sources:clear()
end

function MT.ImFontAtlas:ClearTexData()
    IM_ASSERT(not self.Locked, "Cannot modify a locked ImFontAtlas!")
    IM_ASSERT(self.RendererHasTextures == false, "Not supported for dynamic atlases, but you may call Clear().")

    for _, tex in self.TexList:iter() do
        tex:DestroyPixels()
    end
end

function MT.ImFontAtlas:ClearFonts()
    IM_ASSERT(not self.Locked, "Cannot modify a locked ImFontAtlas!")

    for _, font in self.Fonts:iter() do
        ImFontAtlasBuildNotifySetFont(self, font, nil)
    end

    ImFontAtlasBuildDestroy(self)
    self:ClearInputData()
    self.Fonts:clear_delete()
    self.TexIsBuilt = false

    for _, shared_data in self.DrawListSharedDatas:iter() do
        if shared_data.FontAtlas == self then
            shared_data.Font = nil
            shared_data.FontSize = 0.0
            shared_data.FontScale = 0.0
        end
    end
end

--- @param atlas                 ImFontAtlas
--- @param frame_count           int
--- @param renderer_has_textures any
function ImFontAtlasUpdateNewFrame(atlas, frame_count, renderer_has_textures)
    IM_ASSERT(atlas.Builder == nil or atlas.Builder.FrameCount < frame_count)
    atlas.RendererHasTextures = renderer_has_textures

    if (atlas.RendererHasTextures) then
        atlas.TexIsBuilt = true
        if (atlas.Builder == nil) then
            ImFontAtlasBuildMain(atlas)
        end
    end

    if (not atlas.RendererHasTextures) then
        IM_ASSERT_USER_ERROR(atlas.TexIsBuilt, "Backend does not support ImGuiBackendFlags_RendererHasTextures, and font atlas is not built! Update backend OR make sure you called ImGui_ImplXXXX_NewFrame() function for renderer backend, which should call io.Fonts->GetTexDataAsRGBA32() / GetTexDataAsAlpha8().")
    end
    if (atlas.TexIsBuilt and atlas.Builder.PreloadedAllGlyphsRanges) then
        IM_ASSERT_USER_ERROR(atlas.RendererHasTextures == false, "Called ImFontAtlas::Build() before ImGuiBackendFlags_RendererHasTextures got set! With new backends: you don't need to call Build().")
    end

    local builder = atlas.Builder
    builder.FrameCount = frame_count
    for _, font in atlas.Fonts:iter() do
        font.LastBaked = nil
    end

    if builder.BakedDiscardedCount > 0 then
        local dst_n = 1

        for src_n = 1, builder.BakedPool.Size do
            local p_src = builder.BakedPool.Data[src_n]
            if p_src.WantDestroy then
                continue
            end
            local p_dst = builder.BakedPool.Data[dst_n]
            dst_n = dst_n + 1
            if p_dst == p_src then
                continue
            end
            builder.BakedPool.Data[dst_n - 1] = p_src
            builder.BakedMap:SetVoidPtr(p_src.BakedId, p_src)
        end

        IM_ASSERT(dst_n - 1 + builder.BakedDiscardedCount == builder.BakedPool.Size)

        builder.BakedPool.Size = builder.BakedPool.Size - builder.BakedDiscardedCount
        builder.BakedDiscardedCount = 0
    end

    local tex_n = 1
    while tex_n <= atlas.TexList.Size do
        local tex = atlas.TexList.Data[tex_n]
        local remove_from_list = false
        if tex.Status == ImTextureStatus.OK then
            tex.Updates:resize(0)
            tex.UpdateRect.x = 65535 tex.UpdateRect.y = 65535
            tex.UpdateRect.w = 0     tex.UpdateRect.h = 0
        end
        if (tex.Status == ImTextureStatus.WantCreate and atlas.RendererHasTextures) then
            IM_ASSERT(tex.TexID == ImTextureID_Invalid and tex.BackendUserData == nil, "Backend set texture's TexID/BackendUserData but did not update Status to OK.")
        end

        if (tex.WantDestroyNextFrame and tex.Status ~= ImTextureStatus.Destroyed and tex.Status ~= ImTextureStatus.WantDestroy) then
            IM_ASSERT(tex.Status == ImTextureStatus.OK or tex.Status == ImTextureStatus.WantCreate or tex.Status == ImTextureStatus.WantUpdates)
            tex.Status = ImTextureStatus.WantDestroy
        end

        if (tex.Status == ImTextureStatus.WantDestroy and tex.TexID == ImTextureID_Invalid and tex.BackendUserData == nil) then
            tex.Status = ImTextureStatus.Destroyed
        end

        if (tex.Status == ImTextureStatus.Destroyed) then
            IM_ASSERT(tex.TexID == ImTextureID_Invalid and tex.BackendUserData == nil, "Backend set texture Status to Destroyed but did not clear TexID/BackendUserData!")
            if (tex.WantDestroyNextFrame) then
                remove_from_list = true
            else
                tex.Status = ImTextureStatus.WantCreate
            end
        end

        if (tex.Status == ImTextureStatus.WantDestroy) then
            tex.UnusedFrames = tex.UnusedFrames + 1
        end

        if remove_from_list then
            IM_ASSERT(atlas.TexData ~= tex)
            tex:DestroyPixels()
            tex = nil
            atlas.TexList:erase(tex_n)
            tex_n = tex_n - 1
        end

        tex_n = tex_n + 1
    end
end

-- TODO: validate
--- @param src_pixels ImSlice
--- @param src_fmt    ImTextureFormat
--- @param src_pitch  int
--- @param dst_pixels ImSlice
--- @param dst_fmt    ImTextureFormat
--- @param dst_pitch  int
--- @param w          int
--- @param h          int
function ImFontAtlasTextureBlockConvert(src_pixels, src_fmt, src_pitch, dst_pixels, dst_fmt, dst_pitch, w, h)
    IM_ASSERT(src_pixels ~= nil and dst_pixels ~= nil)
    if src_fmt == dst_fmt then
        local line_sz = w * ImTextureDataGetFormatBytesPerPixel(src_fmt)
        for ny = h, 1, -1 do
            IM_SLICE_COPY(dst_pixels, src_pixels, line_sz)
            IM_SLICE_INC(src_pixels, src_pitch)
            IM_SLICE_INC(dst_pixels, dst_pitch)
        end
    elseif src_fmt == ImTextureFormat.Alpha8 and dst_fmt == ImTextureFormat.RGBA32 then
        for ny = h, 1, -1 do
            for nx = w, 1, -1 do
                local alpha = IM_SLICE_GET(src_pixels, 0)
                IM_SLICE_INC(src_pixels, 1)

                local rgba32 = IM_COL32(255, 255, 255, alpha)
                IM_SLICE_SET(dst_pixels, 0, bit.band(rgba32, 0xFF))
                IM_SLICE_SET(dst_pixels, 1, bit.band(bit.rshift(rgba32, 8), 0xFF))
                IM_SLICE_SET(dst_pixels, 2, bit.band(bit.rshift(rgba32, 16), 0xFF))
                IM_SLICE_SET(dst_pixels, 3, bit.band(bit.rshift(rgba32, 24), 0xFF))
                IM_SLICE_INC(dst_pixels, 4)
            end

            IM_SLICE_INC(src_pixels, src_pitch - w)
            IM_SLICE_INC(dst_pixels, dst_pitch - w * 4)
        end
    elseif src_fmt == ImTextureFormat.RGBA32 and dst_fmt == ImTextureFormat.Alpha8 then
        for ny = h, 1, -1 do
            for nx = w, 1, -1 do
                local alpha = IM_SLICE_GET(src_pixels, 3)
                IM_SLICE_INC(src_pixels, 4)

                IM_SLICE_SET(dst_pixels, 0, alpha)
                IM_SLICE_INC(dst_pixels, 1)
            end

            IM_SLICE_INC(src_pixels, src_pitch - w * 4)
            IM_SLICE_INC(dst_pixels, dst_pitch - w)
        end
    else
        IM_ASSERT(false)
    end
end

--- @param data ImFontAtlasPostProcessData
function ImFontAtlasTextureBlockPostProcess(data)
    if data.FontSrc.RasterizerMultiply ~= 1.0 then
        ImFontAtlasTextureBlockPostProcessMultiply(data, data.FontSrc.RasterizerMultiply)
    end
end

--- @param data            ImFontAtlasPostProcessData
--- @param multiply_factor float
function ImFontAtlasTextureBlockPostProcessMultiply(data, multiply_factor)
    local pixels = data.Pixels
    local pitch = data.Pitch
    if data.Format == ImTextureFormat.Alpha8 then
        for ny = data.Height, 1, -1 do
            local p = pixels
            for nx = data.Width, 1, -1 do
                local v = ImMin(ImFloor(IM_SLICE_GET(p, 0) * multiply_factor), 255)
                IM_SLICE_SET(p, 0, v)

                IM_SLICE_INC(p)
            end

            IM_SLICE_INC(pixels, pitch)
        end
    elseif data.Format == ImTextureFormat.RGBA32 then
        for ny = data.Height, 1, -1 do
            local p = pixels
            for nx = data.Width, 1, -1 do
                local alpha = ImMin(ImFloor(IM_SLICE_GET(p, 3) * multiply_factor), 255)

                local rgba32 = IM_COL32(IM_SLICE_GET(p, 0), IM_SLICE_GET(p, 1), IM_SLICE_GET(p, 2), alpha)
                IM_SLICE_SET(p, 0, bit.band(rgba32, 0xFF))
                IM_SLICE_SET(p, 1, bit.band(bit.rshift(rgba32, 8), 0xFF))
                IM_SLICE_SET(p, 2, bit.band(bit.rshift(rgba32, 16), 0xFF))
                IM_SLICE_SET(p, 3, bit.band(bit.rshift(rgba32, 24), 0xFF))

                IM_SLICE_INC(p, 4)
            end

            IM_SLICE_INC(pixels, pitch)
        end
    else
        IM_ASSERT(false)
    end
end

--- @param src_tex ImTextureData
--- @param src_x   int
--- @param src_y   int
--- @param dst_tex ImTextureData
--- @param dst_x   int
--- @param dst_y   int
--- @param w       int
--- @param h       int
function ImFontAtlasTextureBlockCopy(src_tex, src_x, src_y, dst_tex, dst_x, dst_y, w, h)
    IM_ASSERT(src_tex.Pixels ~= nil and dst_tex.Pixels ~= nil)
    IM_ASSERT(src_tex.Format == dst_tex.Format)
    IM_ASSERT(src_x >= 0 and src_x + w <= src_tex.Width)
    IM_ASSERT(src_y >= 0 and src_y + h <= src_tex.Height)
    IM_ASSERT(dst_x >= 0 and dst_x + w <= dst_tex.Width)
    IM_ASSERT(dst_y >= 0 and dst_y + h <= dst_tex.Height)
    for y = 0, h - 1 do
        IM_SLICE_COPY(dst_tex:GetPixelsAt(dst_x, dst_y + y), src_tex:GetPixelsAt(src_x, src_y + y), w * dst_tex.BytesPerPixel)
    end
end

--- @param atlas ImFontAtlas
--- @param tex   ImTextureData
--- @param x     int
--- @param y     int
--- @param w     int
--- @param h     int
function ImFontAtlasTextureBlockQueueUpload(atlas, tex, x, y, w, h)
    IM_ASSERT(tex.Status ~= ImTextureStatus.WantDestroy and tex.Status ~= ImTextureStatus.Destroyed)
    IM_ASSERT(x >= 0 and x <= 0xFFFF and y >= 0 and y <= 0xFFFF and w >= 0 and x + w <= 0x10000 and h >= 0 and y + h <= 0x10000)
    -- IM_UNUSED(atlas)

    local req = ImTextureRect(x, y, w, h) -- (unsigned short)
    local new_x1 = ImMax(tex.UpdateRect.w == 0 and 0 or tex.UpdateRect.x + tex.UpdateRect.w, req.x + req.w)
    local new_y1 = ImMax(tex.UpdateRect.h == 0 and 0 or tex.UpdateRect.y + tex.UpdateRect.h, req.y + req.h)
    tex.UpdateRect.x = ImMin(tex.UpdateRect.x, req.x)
    tex.UpdateRect.y = ImMin(tex.UpdateRect.y, req.y)
    tex.UpdateRect.w = (new_x1 - tex.UpdateRect.x) -- (unsigned short)
    tex.UpdateRect.h = (new_y1 - tex.UpdateRect.y) -- (unsigned short)
    tex.UsedRect.x = ImMin(tex.UsedRect.x, req.x)
    tex.UsedRect.y = ImMin(tex.UsedRect.y, req.y)
    tex.UsedRect.w = (ImMax(tex.UsedRect.x + tex.UsedRect.w, req.x + req.w) - tex.UsedRect.x) -- (unsigned short)
    tex.UsedRect.h = (ImMax(tex.UsedRect.y + tex.UsedRect.h, req.y + req.h) - tex.UsedRect.y) -- (unsigned short)
    atlas.TexIsBuilt = false

    if (tex.Status == ImTextureStatus.OK or tex.Status == ImTextureStatus.WantUpdates) then
        tex.Status = ImTextureStatus.WantUpdates
        tex.Updates:push_back(req)
    end
end

--- @param atlas      ImFontAtlas
--- @param baked      ImFontBaked
--- @param src        ImFontConfig
--- @param glyph      ImFontGlyph
--- @param r          ImTextureRect
--- @param src_pixels ImSlice
--- @param src_fmt    ImTextureFormat
--- @param src_pitch  int
local function ImFontAtlasBakedSetFontGlyphBitmap(atlas, baked, src, glyph, r, src_pixels, src_fmt, src_pitch)
    local tex = atlas.TexData
    IM_ASSERT(r.x + r.w <= tex.Width and r.y + r.h <= tex.Height)
    ImFontAtlasTextureBlockConvert(src_pixels, src_fmt, src_pitch, tex:GetPixelsAt(r.x, r.y), tex.Format, tex:GetPitch(), r.w, r.h)
    local pp_data = ImFontAtlasPostProcessData(atlas, baked.OwnerFont, src, baked, glyph, tex:GetPixelsAt(r.x, r.y), tex.Format, tex:GetPitch(), r.w, r.h)
    ImFontAtlasTextureBlockPostProcess(pp_data)
    ImFontAtlasTextureBlockQueueUpload(atlas, tex, r.x, r.y, r.w, r.h)
end

local function ImFontAtlasBuildGetOversampleFactors(src, baked)
    local raster_size = baked.Size * baked.RasterizerDensity * src.RasterizerDensity
    local out_oversample_h
    if src.OversampleH ~= 0 then
        out_oversample_h = src.OversampleH
    elseif raster_size > 36.0 or src.PixelSnapH then
        out_oversample_h = 1
    else
        out_oversample_h = 2
    end
    local out_oversample_v = (src.OversampleV ~= 0) and src.OversampleV or 1
    return out_oversample_h, out_oversample_v
end

local function ImFontAtlasBuildDiscardBakes(atlas, unused_frames)
    local builder = atlas.Builder

    for baked_n = 1, builder.BakedPool.Size do
        local baked = builder.BakedPool:at(baked_n)
        if (baked.LastUsedFrame + unused_frames > atlas.Builder.FrameCount) then
            continue
        end
        if (baked.WantDestroy or (bit.band(baked.OwnerFont.Flags, ImFontFlags.LockBakedSizes) ~= 0)) then
            continue
        end
        ImFontAtlasBakedDiscard(atlas, baked.OwnerFont, baked)
    end
end

function ImFontAtlasAddDrawListSharedData(atlas, data)
    IM_ASSERT(not atlas.DrawListSharedDatas:contains(data))
    atlas.DrawListSharedDatas:push_back(data)
end

--- @param atlas ImFontAtlas
--- @param w     int
--- @param h     int
local function ImFontAtlasTextureRepack(atlas, w, h)
    local builder = atlas.Builder
    atlas.LockDisableResize = true

    local old_tex = atlas.TexData
    local new_tex = ImFontAtlasTextureAdd(atlas, w, h)
    new_tex.UseColors = old_tex.UseColors

    IMGUI_DEBUG_LOG_FONT("[font] Texture #%03d: resize+repack %dx%d => Texture #%03d: %dx%d", old_tex.UniqueID, old_tex.Width, old_tex.Height, new_tex.UniqueID, new_tex.Width, new_tex.Height)

    ImFontAtlasPackInit(atlas)
    local old_rects = ImVector()
    local old_index = builder.RectsIndex:copy()
    old_rects:swap(builder.Rects)

    for _, index_entry in builder.RectsIndex:iter() do
        if index_entry.IsUsed == false then
            continue
        end
        local old_r = old_rects:at(index_entry.TargetIndex + 1)
        if (old_r.w == 0 and old_r.h == 0) then
            continue
        end
        local new_r_id = ImFontAtlasPackAddRect(atlas, old_r.w, old_r.h, index_entry)
        if new_r_id == ImFontAtlasRectId_Invalid then
            IMGUI_DEBUG_LOG_FONT("[font] Texture #%03d: resize failed. Will grow.", new_tex.UniqueID)

            new_tex.WantDestroyNextFrame = true
            builder.Rects:swap(old_rects)
            builder.RectsIndex = old_index
            ImFontAtlasBuildSetTexture(atlas, old_tex)
            ImFontAtlasTextureGrow(atlas, w, h)

            return
        end

        IM_ASSERT(ImFontAtlasRectId_GetIndex(new_r_id) == builder.RectsIndex:index_from_ptr(index_entry))

        local new_r = ImFontAtlasPackGetRect(atlas, new_r_id)
        ImFontAtlasTextureBlockCopy(old_tex, old_r.x, old_r.y, new_tex, new_r.x, new_r.y, new_r.w, new_r.h)
    end
    IM_ASSERT(old_rects.Size == builder.Rects.Size + builder.RectsDiscardedCount)
    builder.RectsDiscardedCount = 0
    builder.RectsDiscardedSurface = 0

    for baked_n = 1, builder.BakedPool.Size do
        for _, glyph in builder.BakedPool:at(baked_n).Glyphs:iter() do
            if (glyph.PackId ~= ImFontAtlasRectId_Invalid) then
                local r = ImFontAtlasPackGetRect(atlas, glyph.PackId)
                glyph.U0 = (r.x) * atlas.TexUvScale.x
                glyph.V0 = (r.y) * atlas.TexUvScale.y
                glyph.U1 = (r.x + r.w) * atlas.TexUvScale.x
                glyph.V1 = (r.y + r.h) * atlas.TexUvScale.y
            end
        end
    end

    ImFontAtlasBuildUpdateLinesTexData(atlas)
    ImFontAtlasBuildUpdateBasicTexData(atlas)

    builder.LockDisableResize = false
    ImFontAtlasUpdateDrawListsSharedData(atlas)
    -- ImFontAtlasDebugWriteTexToDisk(new_tex, "After Pack");
end

function ImFontAtlasTextureGrow(atlas, old_tex_w, old_tex_h)
    local builder = atlas.Builder

    old_tex_w = old_tex_w or -1
    old_tex_h = old_tex_h or -1

    if (old_tex_w == -1) then
        old_tex_w = atlas.TexData.Width
    end
    if (old_tex_h == -1) then
        old_tex_h = atlas.TexData.Height
    end

    IM_ASSERT(ImIsPowerOfTwo(old_tex_w) and ImIsPowerOfTwo(old_tex_h))
    IM_ASSERT(ImIsPowerOfTwo(atlas.TexMinWidth) and ImIsPowerOfTwo(atlas.TexMaxWidth) and ImIsPowerOfTwo(atlas.TexMinHeight) and ImIsPowerOfTwo(atlas.TexMaxHeight))

    local new_tex_w = (old_tex_h <= old_tex_w) and old_tex_w or old_tex_w * 2
    local new_tex_h = (old_tex_h <= old_tex_w) and old_tex_h * 2 or old_tex_h

    local pack_padding = atlas.TexGlyphPadding
    new_tex_w = ImMax(new_tex_w, ImUpperPowerOfTwo(builder.MaxRectSize.x + pack_padding))
    new_tex_h = ImMax(new_tex_h, ImUpperPowerOfTwo(builder.MaxRectSize.y + pack_padding))
    new_tex_w = ImClamp(new_tex_w, atlas.TexMinWidth, atlas.TexMaxWidth)
    new_tex_h = ImClamp(new_tex_h, atlas.TexMinHeight, atlas.TexMaxHeight)
    if (new_tex_w == old_tex_w and new_tex_h == old_tex_h) then
        return
    end

    ImFontAtlasTextureRepack(atlas, new_tex_w, new_tex_h)
end

--- @param atlas ImFontAtlas
local function ImFontAtlasTextureMakeSpace(atlas)
    local builder = atlas.Builder
    ImFontAtlasBuildDiscardBakes(atlas, 2)

    if (builder.RectsDiscardedSurface < builder.RectsPackedSurface * 0.20) then
        ImFontAtlasTextureGrow(atlas)
    else
        ImFontAtlasTextureRepack(atlas, atlas.TexData.Width, atlas.TexData.Height)
    end
end

--- @param atlas    ImFontAtlas
--- @param rect_idx ImFontAtlasRectId
local function ImFontAtlasPackAllocRectEntry(atlas, rect_idx)
    local builder = atlas.Builder
    local index_idx, index_entry
    if builder.RectsIndexFreeListStart < 0 then
        builder.RectsIndex:resize(builder.RectsIndex.Size + 1)
        index_idx = builder.RectsIndex.Size - 1
        index_entry = ImFontAtlasRectEntry()
        builder.RectsIndex.Data[builder.RectsIndex.Size] = index_entry
    else
        index_idx = builder.RectsIndexFreeListStart
        index_entry = builder.RectsIndex:at(index_idx + 1)
        IM_ASSERT(index_entry.IsUsed == false and index_entry.Generation > 0)
        builder.RectsIndexFreeListStart = index_entry.TargetIndex
    end

    index_entry.TargetIndex = rect_idx
    index_entry.IsUsed = true

    return ImFontAtlasRectId_Make(index_idx, index_entry.Generation)
end

--- @param atlas       ImFontAtlas
--- @param index_entry ImFontAtlasRectEntry
local function ImFontAtlasPackReuseRectEntry(atlas, index_entry)
    IM_ASSERT(index_entry.IsUsed)
    index_entry.TargetIndex = atlas.Builder.Rects.Size - 1
    local index_idx = atlas.Builder.RectsIndex:index_from_ptr(index_entry)
    return ImFontAtlasRectId_Make(index_idx, index_entry.Generation)
end

--- @param atlas ImFontAtlas
--- @param id    ImFontAtlasRectId
function ImFontAtlasPackDiscardRect(atlas, id)
    IM_ASSERT(id ~= ImFontAtlasRectId_Invalid)

    local rect = ImFontAtlasPackGetRect(atlas, id)
    if (rect == nil) then
        return
    end

    local builder = atlas.Builder
    local index_idx = ImFontAtlasRectId_GetIndex(id)
    local index_entry = builder.RectsIndex:at(index_idx + 1) -- TODO: indexing validation
    IM_ASSERT(index_entry.IsUsed and index_entry.TargetIndex >= 0)
    index_entry.IsUsed = false
    index_entry.TargetIndex = builder.RectsIndexFreeListStart
    index_entry.Generation = index_entry.Generation + 1
    if (index_entry.Generation == 0) then
        index_entry.Generation = index_entry.Generation + 1
    end

    local pack_padding = atlas.TexGlyphPadding
    builder.RectsIndexFreeListStart = index_idx
    builder.RectsDiscardedCount = builder.RectsDiscardedCount + 1
    builder.RectsDiscardedSurface = builder.RectsDiscardedSurface + ((rect.w + pack_padding) * (rect.h + pack_padding))
    rect.w = 0 rect.h = 0
end

function ImFontAtlasPackAddRect(atlas, w, h, overwrite_entry)
    IM_ASSERT(w > 0 and w <= 0xFFFF)
    IM_ASSERT(h > 0 and h <= 0xFFFF)

    local builder = atlas.Builder
    local pack_padding = atlas.TexGlyphPadding
    builder.MaxRectSize.x = ImMax(builder.MaxRectSize.x, w)
    builder.MaxRectSize.y = ImMax(builder.MaxRectSize.y, h)

    local r = ImTextureRect(0, 0, w, h)
    for attempts_remaining = 3, 0, -1 do
        local pack_r = stbrp.rect()
        pack_r.w = w + pack_padding
        pack_r.h = h + pack_padding
        stbrp.pack_rects(builder.PackContext, {pack_r}, 1)
        r.x = pack_r.x -- (unsigned short)
        r.y = pack_r.y -- (unsigned short)
        if pack_r.was_packed == 1 then
            break
        end

        if (attempts_remaining == 0 or builder.LockDisableResize) then
            IMGUI_DEBUG_LOG_FONT("[font] Failed packing %dx%d rectangle. Returning fallback.", w, h)

            return ImFontAtlasRectId_Invalid
        end

        ImFontAtlasTextureMakeSpace(atlas)
    end

    builder.MaxRectBounds.x = ImMax(builder.MaxRectBounds.x, r.x + r.w + pack_padding)
    builder.MaxRectBounds.y = ImMax(builder.MaxRectBounds.y, r.y + r.h + pack_padding)
    builder.RectsPackedCount = builder.RectsPackedCount + 1
    builder.RectsPackedSurface = builder.RectsPackedSurface + (w + pack_padding) * (h + pack_padding)

    builder.Rects:push_back(r)
    if (overwrite_entry ~= nil) then
        return ImFontAtlasPackReuseRectEntry(atlas, overwrite_entry)
    else
        return ImFontAtlasPackAllocRectEntry(atlas, builder.Rects.Size - 1)
    end
end

--- @param atlas ImFontAtlas
--- @param id    ImFontAtlasRectId
--- @return ImTextureRect
function ImFontAtlasPackGetRect(atlas, id)
    IM_ASSERT(id ~= ImFontAtlasRectId_Invalid)
    local index_idx = ImFontAtlasRectId_GetIndex(id)
    local builder = atlas.Builder
    local index_entry = builder.RectsIndex:at(index_idx + 1) -- TODO: indexing validation
    IM_ASSERT(index_entry.Generation == ImFontAtlasRectId_GetGeneration(id))
    IM_ASSERT(index_entry.IsUsed)
    --- @type ImTextureRect
    return builder.Rects:at(index_entry.TargetIndex + 1) -- TODO: indexing validation
end

--- @param atlas ImFontAtlas
--- @param id    ImFontAtlasRectId
function ImFontAtlasPackGetRectSafe(atlas, id)
    if id == ImFontAtlasRectId_Invalid then
        return nil
    end

    local index_idx = ImFontAtlasRectId_GetIndex(id)
    if atlas.Builder == nil then
        ImFontAtlasBuildInit(atlas)
    end
    local builder = atlas.Builder
    if index_idx >= builder.RectsIndex.Size then
        return nil
    end
    local index_entry = builder.RectsIndex:at(index_idx + 1) -- TODO: indexing validation
    if (index_entry.Generation ~= ImFontAtlasRectId_GetGeneration(id) or not index_entry.IsUsed) then
        return nil
    end
    return builder.Rects:at(index_entry.TargetIndex + 1) -- TODO: indexing validation
end

--- @param src       ImFontConfig
--- @param codepoint ImWchar
--- @return bool
function ImFontAtlasBuildAcceptCodepointForSource(src, codepoint)
    local exclude_list = src.GlyphExcludeRanges
    if exclude_list then
        local i = 1
        while exclude_list[i] ~= 0 do
            if codepoint >= exclude_list[i] and codepoint <= exclude_list[i + 1] then
                return false
            end

            i = i + 2
        end
    end

    return true
end

--- @param baked    ImFontBaked
--- @param new_size int
function ImFontBaked_BuildGrowIndex(baked, new_size)
    IM_ASSERT(baked.IndexAdvanceX.Size == baked.IndexLookup.Size)
    if (new_size <= baked.IndexLookup.Size) then
        return
    end
    baked.IndexAdvanceX:resize(new_size, -1.0)
    baked.IndexLookup:resize(new_size, IM_FONTGLYPH_INDEX_UNUSED)
end

--- @class ImGui_ImplStbTrueType_FontSrcData
--- @field FontInfo    stbtt_fontinfo
--- @field ScaleFactor float

--- @return ImGui_ImplStbTrueType_FontSrcData
--- @nodiscard
local function ImGui_ImplStbTrueType_FontSrcData()
    return {
        FontInfo    = stbtt.fontinfo(),
        ScaleFactor = nil
    }
end

local function ImGui_ImplStbTrueType_FontSrcInit(atlas, src)
    -- IM_UNUSED(atlas)

    --- @type ImGui_ImplStbTrueType_FontSrcData?
    local bd_font_data = ImGui_ImplStbTrueType_FontSrcData()
    IM_ASSERT(src.FontLoaderData == nil)

    local font_offset = stbtt.GetFontOffsetForIndex(src.FontData, src.FontNo)
    if font_offset < 0 then
        bd_font_data = nil
        IM_ASSERT_USER_ERROR(0, "stbtt_GetFontOffsetForIndex(): FontData is incorrect, or FontNo cannot be found.")
        return false
    end
    if (not stbtt.InitFont(bd_font_data.FontInfo, src.FontData, font_offset)) then
        bd_font_data = nil
        IM_ASSERT_USER_ERROR(0, "stbtt_InitFont(): failed to parse FontData. It is correct and complete? Check FontDataSize.")
        return false
    end
    src.FontLoaderData = bd_font_data

    local ref_size = src.DstFont.Sources:at(1).SizePixels
    if (src.MergeMode and src.SizePixels == 0.0) then
        src.SizePixels = ref_size
    end

    bd_font_data.ScaleFactor = stbtt.ScaleForPixelHeight(bd_font_data.FontInfo, 1.0)
    if (src.MergeMode and src.SizePixels ~= 0.0 and ref_size ~= 0.0) then
        bd_font_data.ScaleFactor = bd_font_data.ScaleFactor * (src.SizePixels / ref_size)
    end
    bd_font_data.ScaleFactor = bd_font_data.ScaleFactor * src.ExtraSizeScale

    return true
end

local function ImGui_ImplStbTrueType_FontSrcDestroy(atlas, src)
    -- IM_UNUSED(atlas)
    src.FontLoaderData = nil
end

local function ImGui_ImplStbTrueType_FontSrcContainsGlyph(atlas, src, codepoint)
    -- IM_UNUSED(atlas)
    local bd_font_data = src.FontLoaderData
    IM_ASSERT(bd_font_data ~= nil)

    local glyph_index = stbtt.FindGlyphIndex(bd_font_data.FontInfo, codepoint)
    return (glyph_index ~= 0)
end

local function ImGui_ImplStbTrueType_FontBakedInit(atlas, src, baked)
    -- IM_UNUSED(atlas)

    local bd_font_data = src.FontLoaderData
    if (src.MergeMode == false) then
        local scale_for_layout = bd_font_data.ScaleFactor * baked.Size
        local unscaled_ascent, unscaled_descent, unscaled_line_gap = stbtt.GetFontVMetrics(bd_font_data.FontInfo)

        baked.Ascent = ImCeil(unscaled_ascent * scale_for_layout)
        baked.Descent = ImFloor(unscaled_descent * scale_for_layout)
    end

    return true
end

--- @param atlas         ImFontAtlas
--- @param src           ImFontConfig
--- @param baked         ImFontBaked
--- @param _             any
--- @param codepoint     ImWchar
--- @param out_glyph     ImFontGlyph
--- @param out_advance_x float_ptr
--- @return bool
local function ImGui_ImplStbTrueType_FontBakedLoadGlyph(atlas, src, baked, _, codepoint, out_glyph, out_advance_x)
    local bd_font_data = src.FontLoaderData
    IM_ASSERT(bd_font_data ~= nil)
    local glyph_index = stbtt.FindGlyphIndex(bd_font_data.FontInfo, codepoint)
    if (glyph_index == 0) then
        return false
    end

    local oversample_h, oversample_v = ImFontAtlasBuildGetOversampleFactors(src, baked)
    local scale_for_layout = bd_font_data.ScaleFactor * baked.Size
    local rasterizer_density = src.RasterizerDensity * baked.RasterizerDensity
    local scale_for_raster_x = bd_font_data.ScaleFactor * baked.Size * rasterizer_density * oversample_h
    local scale_for_raster_y = bd_font_data.ScaleFactor * baked.Size * rasterizer_density * oversample_v

    local x0, y0, x1, y1 = stbtt.GetGlyphBitmapBoxSubpixel(bd_font_data.FontInfo, glyph_index, scale_for_raster_x, scale_for_raster_y, 0, 0)
    local advance, lsb = stbtt.GetGlyphHMetrics(bd_font_data.FontInfo, glyph_index)

    if (out_advance_x ~= nil) then
        IM_ASSERT(out_glyph == nil)
        out_advance_x[1] = advance * scale_for_layout

        return true
    end

    out_glyph.Codepoint = codepoint
    out_glyph.AdvanceX = advance * scale_for_layout

    local is_visible = (x0 ~= x1 and y0 ~= y1)
    if is_visible then
        local w = (x1 - x0 + oversample_h - 1)
        local h = (y1 - y0 + oversample_v - 1)
        local pack_id = ImFontAtlasPackAddRect(atlas, w, h)
        if (pack_id == ImFontAtlasRectId_Invalid) then
            -- Pathological out of memory case (TexMaxWidth/TexMaxHeight set too small?)
            IM_ASSERT(pack_id ~= ImFontAtlasRectId_Invalid, "Out of texture memory.")
            return false
        end

        local r = ImFontAtlasPackGetRect(atlas, pack_id)

        x0, y0, x1, y1 = stbtt.GetGlyphBitmapBox(bd_font_data.FontInfo, glyph_index, scale_for_raster_x, scale_for_raster_y)
        local builder = atlas.Builder
        -- builder.TempBuffer:resize(w * h * 1)
        local bitmap_pixels = builder.TempBuffer
        IM_SLICE_FILL(bitmap_pixels, 0, w * h * 1)

        local sub_x, sub_y = stbtt.MakeGlyphBitmapSubpixelPrefilter(bd_font_data.FontInfo, bitmap_pixels, w, h, w,
            scale_for_raster_x, scale_for_raster_y, 0, 0, oversample_h, oversample_v, glyph_index)

        local ref_size = baked.OwnerFont.Sources:at(1).SizePixels
        local offsets_scale = (ref_size ~= 0.0) and (baked.Size / ref_size) or 1.0
        local font_off_x = ImFloor(src.GlyphOffset.x * offsets_scale + 0.5)
        local font_off_y = ImFloor(src.GlyphOffset.y * offsets_scale + 0.5)
        font_off_x = font_off_x + sub_x
        font_off_y = font_off_y + (sub_y + IM_ROUND(baked.Ascent))
        local recip_h = 1.0 / (oversample_h * rasterizer_density)
        local recip_v = 1.0 / (oversample_v * rasterizer_density)

        out_glyph.X0 = x0 * recip_h + font_off_x
        out_glyph.Y0 = y0 * recip_v + font_off_y
        out_glyph.X1 = (x0 + r.w) * recip_h + font_off_x
        out_glyph.Y1 = (y0 + r.h) * recip_v + font_off_y
        out_glyph.Visible = true
        out_glyph.PackId = pack_id

        ImFontAtlasBakedSetFontGlyphBitmap(atlas, baked, src, out_glyph, r, bitmap_pixels, ImTextureFormat.Alpha8, w)
    end

    return true
end

local function ImFontAtlasGetFontLoaderForStbTruetype()
    local loader = ImFontLoader()

    loader.Name                 = "stb_truetype"
    loader.FontSrcInit          = ImGui_ImplStbTrueType_FontSrcInit
    loader.FontSrcDestroy       = ImGui_ImplStbTrueType_FontSrcDestroy
    loader.FontSrcContainsGlyph = ImGui_ImplStbTrueType_FontSrcContainsGlyph
    loader.FontBakedInit        = ImGui_ImplStbTrueType_FontBakedInit
    loader.FontBakedDestroy     = nil
    loader.FontBakedLoadGlyph   = ImGui_ImplStbTrueType_FontBakedLoadGlyph

    return loader
end

--- @param atlas ImFontAtlas
--- @param baked ImFontBaked
function ImFontAtlasBuildSetupFontBakedBlanks(atlas, baked)
    local space_glyph = baked:FindGlyphNoFallback(chr' ')
    if space_glyph ~= nil then
        space_glyph.Visible = false
    end

    if baked:FindGlyphNoFallback(chr'\t') == nil and space_glyph ~= nil then
        local tab_glyph = ImFontGlyph()
        tab_glyph.Codepoint = chr'\t'
        tab_glyph.AdvanceX = space_glyph.AdvanceX * IM_TABSIZE
        ImFontAtlasBakedAddFontGlyph(atlas, baked, nil, tab_glyph)
    end
end

--- @param atlas                   ImFontAtlas
--- @param font                    ImFont
--- @param font_size               float
--- @param font_rasterizer_density float
--- @param baked_id                ImGuiID
--- @return ImFontBaked?
function ImFontAtlasBakedAdd(atlas, font, font_size, font_rasterizer_density, baked_id)
    -- IMGUI_DEBUG_LOG_FONT("[font] Created baked %.2fpx\n", font_size)
    local baked = atlas.Builder.BakedPool:push_back(ImFontBaked())

    baked.Size              = font_size
    baked.RasterizerDensity = font_rasterizer_density
    baked.BakedId           = baked_id
    baked.OwnerFont         = font
    baked.LastUsedFrame     = atlas.Builder.FrameCount

    local loader_data_size = 0
    for _, src in font.Sources:iter() do
        local loader = src.FontLoader and src.FontLoader or atlas.FontLoader
        loader_data_size = loader_data_size + loader.FontBakedSrcLoaderDataSize
    end
    -- baked.FontLoaderDatas = (loader_data_size > 0) and IM_ALLOC(loader_data_size) or nil
    -- local loader_data_p = baked->FontLoaderDatas
    for _, src in font.Sources:iter() do
        local loader = src.FontLoader and src.FontLoader or atlas.FontLoader
        if (loader.FontBakedInit) then
            loader.FontBakedInit(atlas, src, baked--[[, loader_data_p--]])
        end
        -- loader_data_p += loader->FontBakedSrcLoaderDataSize
    end

    ImFontAtlasBuildSetupFontBakedBlanks(atlas, baked)
    return baked
end

--- @param atlas                   ImFontAtlas
--- @param font                    ImFont
--- @param font_size               float
--- @param font_rasterizer_density float
--- @return ImFontBaked?
function ImFontAtlasBakedGetClosestMatch(atlas, font, font_size, font_rasterizer_density)
    local builder = atlas.Builder

    for step_n = 0, 1 do
        local closest_larger_match
        local closest_smaller_match
        for baked_n = 1, builder.BakedPool.Size do
            local baked = builder.BakedPool:at(baked_n)
            if (baked.OwnerFont ~= font or baked.WantDestroy) then
                continue
            end
            if (step_n == 0 and baked.RasterizerDensity ~= font_rasterizer_density) then
                continue
            end
            if (baked.Size > font_size and (closest_larger_match == nil or baked.Size < closest_larger_match.Size)) then
                closest_larger_match = baked
            end
            if (baked.Size < font_size and (closest_smaller_match == nil or baked.Size > closest_smaller_match.Size)) then
                closest_smaller_match = baked
            end
        end
        if (closest_larger_match) then
            if (closest_smaller_match == nil or (closest_larger_match.Size >= font_size * 2.0 and closest_smaller_match.Size > font_size * 0.5)) then
                return closest_larger_match
            end
        end
        if (closest_smaller_match) then
            return closest_smaller_match
        end
    end

    return nil
end

function ImFontAtlasBakedDiscard(atlas, font, baked)
    local builder = atlas.Builder

    for _, glyph in baked.Glyphs:iter() do
        if glyph.PackId ~= ImFontAtlasRectId_Invalid then
            ImFontAtlasPackDiscardRect(atlas, glyph.PackId)
        end
    end

    -- char* loader_data_p = (char*)baked->FontLoaderDatas
    for _, src in font.Sources:iter() do
        local loader = src.FontLoader and src.FontLoader or atlas.FontLoader
        if loader.FontBakedDestroy then
            loader.FontBakedDestroy(atlas, src, baked)
        end
    end

    if baked.FontLoaderDatas then
        baked.FontLoaderDatas = nil
    end

    builder.BakedDiscardedCount = builder.BakedDiscardedCount + 1
    baked:ClearOutputData()
    baked.WantDestroy = true
    font.LastBaked = nil
end

local function ImFontAtlasFontDiscardBakes(atlas, font, unused_frames)
    local builder = atlas.Builder
    if builder then
        for baked_n = 1, builder.BakedPool.Size do
            local baked = builder.BakedPool:at(baked_n)
            if baked.LastUsedFrame + unused_frames > atlas.Builder.FrameCount then
                continue
            end
            if (baked.OwnerFont ~= font) or baked.WantDestroy then
                continue
            end
            ImFontAtlasBakedDiscard(atlas, font, baked)
        end
    end
end

function ImFontAtlasFontInitOutput(atlas, font)
    local ret = true
    for _, src in font.Sources:iter() do
        if not ImFontAtlasFontSourceInit(atlas, src) then
            ret = false
        end
    end
    IM_ASSERT(ret)
    return ret
end

function ImFontAtlasFontDestroyOutput(atlas, font)
    font:ClearOutputData()
    for _, src in font.Sources:iter() do
        local loader = src.FontLoader and src.FontLoader or atlas.FontLoader
        if loader and loader.FontSrcDestroy ~= nil then
            loader.FontSrcDestroy(atlas, src)
        end
    end
end

--- @param atlas ImFontAtlas
--- @param src ImFontConfig
--- @return boolean
function ImFontAtlasFontSourceInit(atlas, src)
    local loader = (src.FontLoader) and src.FontLoader or atlas.FontLoader
    if (loader.FontSrcInit ~= nil and not loader.FontSrcInit(atlas, src)) then
        return false
    end
    return true
end

--- @param atlas ImFontAtlas
--- @param font ImFont
--- @param src ImFontConfig
function ImFontAtlasFontSourceAddToFont(atlas, font, src)
    if src.MergeMode == false then
        font:ClearOutputData()
        font.OwnerAtlas = atlas
        IM_ASSERT(font.Sources:at(1) == src)
    end
    atlas.TexIsBuilt = false
    ImFontAtlasBuildSetupFontSpecialGlyphs(atlas, font, src)
end

--- @param atlas ImFontAtlas
--- @param src ImFontConfig
function ImFontAtlasFontDestroySourceData(atlas, src)
    -- IM_UNUSED(atlas)

    -- if src.FontDataOwnedByAtlas then
    --     IM_FREE(src.FontData)
    -- end
    src.FontData = nil
    -- if src.GlyphExcludeRanges then
    --     IM_FREE(src.GlyphExcludeRanges)
    -- end
    src.GlyphExcludeRanges = nil
end

--- @param atlas ImFontAtlas
--- @param font ImFont
--- @param src ImFontConfig
function ImFontAtlasBuildSetupFontSpecialGlyphs(atlas, font, src)
    -- IM_UNUSED(atlas)
    IM_ASSERT(font.Sources:contains(src))

    --- @type ImWchar[]
    local fallback_chars = {font.FallbackChar, IM_UNICODE_CODEPOINT_INVALID, chr'?', chr' '}
    if font.FallbackChar == 0 then
        for _, candidate_char in ipairs(fallback_chars) do
            if candidate_char ~= 0 and font:IsGlyphInFont(candidate_char) then
                font.FallbackChar = candidate_char

                break
            end
        end
    end

    --- @type ImWchar[]
    local ellipsis_chars = {src.EllipsisChar, 0x2026, 0x0085}
    if font.EllipsisChar == 0 then
        for _, candidate_char in ipairs(ellipsis_chars) do
            if candidate_char ~= 0 and font:IsGlyphInFont(candidate_char) then
                font.EllipsisChar = candidate_char

                break
            end
        end
    end

    if font.EllipsisChar == 0 then
        font.EllipsisChar = 0x0085
        font.EllipsisAutoBake = true
    end
end

--- @param atlas ImFontAtlas
--- @param baked ImFontBaked
--- @return ImFontGlyph?
function ImFontAtlasBuildSetupFontBakedEllipsis(atlas, baked)
    local font = baked.OwnerFont
    IM_ASSERT(font.EllipsisChar ~= 0)

    local dot_glyph = baked:FindGlyphNoFallback(chr'.')
    if (dot_glyph == nil) then
        dot_glyph = baked:FindGlyphNoFallback(0xFF0E)
    end
    if (dot_glyph == nil) then
        return nil
    end
    local dot_r_id = dot_glyph.PackId
    local dot_r = ImFontAtlasPackGetRect(atlas, dot_r_id)
    local dot_spacing = 1
    local dot_step = (dot_glyph.X1 - dot_glyph.X0) + dot_spacing

    local pack_id = ImFontAtlasPackAddRect(atlas, (dot_r.w * 3 + dot_spacing * 2), dot_r.h)
    local r = ImFontAtlasPackGetRect(atlas, pack_id)

    local glyph = ImFontGlyph()
    glyph.Codepoint = font.EllipsisChar
    glyph.AdvanceX = ImMax(dot_glyph.AdvanceX, dot_glyph.X0 + dot_step * 3.0 - dot_spacing)
    glyph.X0 = dot_glyph.X0
    glyph.Y0 = dot_glyph.Y0
    glyph.X1 = dot_glyph.X0 + dot_step * 3 - dot_spacing
    glyph.Y1 = dot_glyph.Y1
    glyph.Visible = true
    glyph.PackId = pack_id
    glyph = ImFontAtlasBakedAddFontGlyph(atlas, baked, nil, glyph)
    dot_glyph = nil

    dot_r = ImFontAtlasPackGetRect(atlas, dot_r_id)
    local tex = atlas.TexData
    for n = 0, 2 do
        ImFontAtlasTextureBlockCopy(tex, dot_r.x, dot_r.y, tex, r.x + (dot_r.w + dot_spacing) * n, r.y, dot_r.w, dot_r.h)
    end
    ImFontAtlasTextureBlockQueueUpload(atlas, tex, r.x, r.y, r.w, r.h)

    return glyph
end

--- @param baked ImFontBaked
function ImFontAtlasBuildSetupFontBakedFallback(baked)
    IM_ASSERT(baked.FallbackGlyphIndex == 0)
    IM_ASSERT(baked.FallbackAdvanceX == 0.0)
    local font = baked.OwnerFont
    local fallback_glyph, fallback_glyph_index
    if (font.FallbackChar ~= 0) then
        fallback_glyph = baked:FindGlyphNoFallback(font.FallbackChar)
    end
    if (fallback_glyph == nil) then
        local space_glyph = baked:FindGlyphNoFallback(chr' ')
        local glyph = ImFontGlyph()
        glyph.Codepoint = 0
        glyph.AdvanceX = space_glyph and space_glyph.AdvanceX or IM_ROUND(baked.Size * 0.40)
        fallback_glyph, fallback_glyph_index = ImFontAtlasBakedAddFontGlyph(font.OwnerAtlas, baked, nil, glyph)
    end
    baked.FallbackGlyphIndex = fallback_glyph_index
    baked.FallbackAdvanceX = fallback_glyph.AdvanceX
end

function ImFontAtlasBuildSetupFontLoader(atlas, font_loader)
    if atlas.FontLoader == font_loader then
        return
    end
    IM_ASSERT(not atlas.Locked, "Cannot modify a locked ImFontAtlas!")

    for _, font in atlas.Fonts:iter() do
        ImFontAtlasFontDestroyOutput(atlas, font)
    end
    if atlas.Builder and atlas.FontLoader and atlas.FontLoader.LoaderShutdown then
        atlas.FontLoader.LoaderShutdown(atlas)
    end

    atlas.FontLoader = font_loader
    atlas.FontLoaderName = font_loader and font_loader.Name or "NULL"
    IM_ASSERT(atlas.FontLoaderData == nil)

    if atlas.Builder and atlas.FontLoader and atlas.FontLoader.LoaderInit then
        atlas.FontLoader.LoaderInit(atlas)
    end
    for _, font in atlas.Fonts:iter() do
        ImFontAtlasFontInitOutput(atlas, font)
    end
    for _, font in atlas.Fonts:iter() do
        for _, src in font.Sources:iter() do
            ImFontAtlasFontSourceAddToFont(atlas, font, src)
        end
    end
end

local function ImFontAtlasBuildUpdateRendererHasTexturesFromContext(atlas)
    for _, shared_data in atlas.DrawListSharedDatas:iter() do
        local imgui_ctx = shared_data.Context
        if (imgui_ctx) then
            atlas.RendererHasTextures = bit.band(imgui_ctx.IO.BackendFlags, ImGuiBackendFlags.RendererHasTextures) ~= 0

            break
        end
    end
end

local function ImFontAtlasBuildUpdatePointers(atlas)
    return -- UNNECESSARY
end

--- @param atlas   ImFontAtlas
--- @param old_tex ImTextureRef
--- @param new_tex ImTextureRef
local function ImFontAtlasUpdateDrawListsTextures(atlas, old_tex, new_tex)
    for _, shared_data in atlas.DrawListSharedDatas:iter() do
        if (shared_data.Context and not shared_data.Context.WithinFrameScope) then
            continue
        end

        for _, draw_list in shared_data.DrawLists:iter() do
            if (draw_list.CmdBuffer.Size > 0 and draw_list._CmdHeader.TexRef == old_tex) then
                draw_list:_SetTexture(new_tex)
            end

            for _, stacked_tex in draw_list._TextureStack:iter() do
                if (stacked_tex == old_tex) then
                    stacked_tex = new_tex
                end
            end
        end
    end
end

function ImFontAtlasBuildSetTexture(atlas, tex)
    local old_tex_ref = atlas.TexRef
    atlas.TexData = tex
    atlas.TexUvScale = ImVec2(1.0 / tex.Width, 1.0 / tex.Height)
    atlas.TexRef._TexData = tex
    -- atlas->TexRef._TexID = tex->TexID; <-- We intentionally don't do that. It would be misleading and betray promise that both fields aren't set.
    ImFontAtlasUpdateDrawListsTextures(atlas, old_tex_ref, atlas.TexRef)
end

function ImFontAtlasTextureAdd(atlas, w, h)
    local old_tex = atlas.TexData
    local new_tex

    -- FIXME: Cannot reuse texture because old UV may have been used already (unless we remap UV).
    new_tex = ImTextureData()
    new_tex.UniqueID = atlas.TexNextUniqueID
    atlas.TexNextUniqueID = atlas.TexNextUniqueID + 1
    atlas.TexList:push_back(new_tex)

    if old_tex ~= nil then
        old_tex.WantDestroyNextFrame = true
        IM_ASSERT(old_tex.Status == ImTextureStatus.OK or old_tex.Status == ImTextureStatus.WantCreate or old_tex.Status == ImTextureStatus.WantUpdates)
    end

    new_tex:Create(atlas.TexDesiredFormat, w, h)
    atlas.TexIsBuilt = false

    ImFontAtlasBuildSetTexture(atlas, new_tex)

    return new_tex
end

--- @param atlas ImFontAtlas
--- @return ImVec2
function ImFontAtlasTextureGetSizeEstimate(atlas)
    local min_w = ImUpperPowerOfTwo(atlas.TexMinWidth)
    local min_h = ImUpperPowerOfTwo(atlas.TexMinHeight)
    if (atlas.Builder == nil or atlas.TexData == nil or atlas.TexData.Status == ImTextureStatus.WantDestroy) then
        return ImVec2(min_w, min_h) -- ImVec2i
    end

    local builder = atlas.Builder
    min_w = ImMax(ImUpperPowerOfTwo(builder.MaxRectSize.x), min_w)
    min_h = ImMax(ImUpperPowerOfTwo(builder.MaxRectSize.y), min_h)
    local surface_approx = builder.RectsPackedSurface - builder.RectsDiscardedSurface
    local surface_sqrt = ImFloor(ImSqrt(surface_approx))

    local new_tex_w
    local new_tex_h
    if (min_w >= min_h) then
        new_tex_w = ImMax(min_w, ImUpperPowerOfTwo(surface_sqrt))
        new_tex_h = ImMax(min_h, ImFloor((surface_approx + new_tex_w - 1) / new_tex_w))
        if (bit.band(atlas.Flags, ImFontAtlasFlags.NoPowerOfTwoHeight) == 0) then
            new_tex_h = ImUpperPowerOfTwo(new_tex_h)
        end
    else
        new_tex_h = ImMax(min_h, ImUpperPowerOfTwo(surface_sqrt))
        if (bit.band(atlas.Flags, ImFontAtlasFlags.NoPowerOfTwoHeight) == 0) then
            new_tex_h = ImUpperPowerOfTwo(new_tex_h)
        end
        new_tex_w = ImMax(min_w, ImFloor((surface_approx + new_tex_h - 1) / new_tex_h))
    end

    IM_ASSERT(ImIsPowerOfTwo(new_tex_w) and ImIsPowerOfTwo(new_tex_h))
    return ImVec2(new_tex_w, new_tex_h) -- ImVec2i
end

--- @param atlas ImFontAtlas
local function ImFontAtlasBuildClear(atlas)
    local new_tex_size = ImFontAtlasTextureGetSizeEstimate(atlas) -- ImVec2i
    ImFontAtlasBuildDestroy(atlas)
    ImFontAtlasTextureAdd(atlas, new_tex_size.x, new_tex_size.y)
    ImFontAtlasBuildInit(atlas)
    for _, src in atlas.Sources:iter() do
        ImFontAtlasFontSourceInit(atlas, src)
    end
    for _, font in atlas.Fonts:iter() do
        for _, src in font.Sources:iter() do
            ImFontAtlasFontSourceAddToFont(atlas, font, src)
        end
    end
end

--- @param atlas ImFontAtlas
function ImFontAtlasPackInit(atlas)
    local tex = atlas.TexData
    local builder = atlas.Builder

    local pack_node_count = ImFloor(tex.Width / 2)
    builder.PackNodes:resize(pack_node_count)
    for i = 1, builder.PackNodes.Size do builder.PackNodes.Data[i] = stbrp.node() end

    stbrp.init_target(builder.PackContext, tex.Width, tex.Height, builder.PackNodes.Data, builder.PackNodes.Size)
    builder.RectsPackedCount = 0
    builder.RectsPackedSurface = 0
    builder.MaxRectSize = ImVec2(0, 0) -- ImVec2i
    builder.MaxRectBounds = ImVec2(0, 0) -- ImVec2i
end

-- TODO: validate
--- @param atlas ImFontAtlas
function ImFontAtlasBuildUpdateLinesTexData(atlas)
    if bit.band(atlas.Flags, ImFontAtlasFlags.NoBakedLines) ~= 0 then
        return
    end

    local tex = atlas.TexData
    local builder = atlas.Builder

    local r = ImFontAtlasRect()
    local add_and_draw = (atlas:GetCustomRect(builder.PackIdLinesTexData, r) == false)
    if add_and_draw then
        local pack_size = ImVec2(IM_DRAWLIST_TEX_LINES_WIDTH_MAX + 2, IM_DRAWLIST_TEX_LINES_WIDTH_MAX + 1) -- ImVec2i
        builder.PackIdLinesTexData = atlas:AddCustomRect(pack_size.x, pack_size.y, r)
        IM_ASSERT(builder.PackIdLinesTexData ~= ImFontAtlasRectId_Invalid)
    end

    for n = 0, IM_DRAWLIST_TEX_LINES_WIDTH_MAX do
        local y = n
        local line_width = n

        --- @type int # If not floored, will cause black and purple horizontal stripes appearing on the right of the arrow(triangle) in the upper-left most area of the atlas
        local pad_left = math.floor((r.w - line_width) / 2)
        --- @type int
        local pad_right = r.w - (pad_left + line_width)

        IM_ASSERT(pad_left + line_width + pad_right == r.w and y < r.h)

        if (add_and_draw and tex.Format == ImTextureFormat.Alpha8) then
            local write_ptr = tex:GetPixelsAt(r.x, r.y + y) -- ImU8*

            for i = 0, pad_left - 1 do
                IM_SLICE_SET(write_ptr, i, 0x00)
            end

            for i = 0, line_width - 1 do
                IM_SLICE_SET(write_ptr, pad_left + i, 0xFF)
            end

            for i = 0, pad_right - 1 do
                IM_SLICE_SET(write_ptr, pad_left + line_width + i, 0x00)
            end
        elseif (add_and_draw and tex.Format == ImTextureFormat.RGBA32) then
            local write_ptr = tex:GetPixelsAt(r.x, r.y + y) -- ImU32*

            for i = 0, pad_left - 1 do
                local rgba32 = IM_COL32(255, 255, 255, 0)
                local base = i * 4

                IM_SLICE_SET(write_ptr, base + 0, bit.band(rgba32, 0xFF))
                IM_SLICE_SET(write_ptr, base + 1, bit.band(bit.rshift(rgba32, 8), 0xFF))
                IM_SLICE_SET(write_ptr, base + 2, bit.band(bit.rshift(rgba32, 16), 0xFF))
                IM_SLICE_SET(write_ptr, base + 3, bit.band(bit.rshift(rgba32, 24), 0xFF))
            end

            for i = 0, line_width - 1 do
                local rgba32 = IM_COL32_WHITE
                local base = (pad_left + i) * 4

                IM_SLICE_SET(write_ptr, base + 0, bit.band(rgba32, 0xFF))
                IM_SLICE_SET(write_ptr, base + 1, bit.band(bit.rshift(rgba32, 8), 0xFF))
                IM_SLICE_SET(write_ptr, base + 2, bit.band(bit.rshift(rgba32, 16), 0xFF))
                IM_SLICE_SET(write_ptr, base + 3, bit.band(bit.rshift(rgba32, 24), 0xFF))
            end

            for i = 0, pad_right - 1 do
                local rgba32 = IM_COL32(255, 255, 255, 0)
                local base = (pad_left + line_width + i) * 4

                IM_SLICE_SET(write_ptr, base + 0, bit.band(rgba32, 0xFF))
                IM_SLICE_SET(write_ptr, base + 1, bit.band(bit.rshift(rgba32, 8), 0xFF))
                IM_SLICE_SET(write_ptr, base + 2, bit.band(bit.rshift(rgba32, 16), 0xFF))
                IM_SLICE_SET(write_ptr, base + 3, bit.band(bit.rshift(rgba32, 24), 0xFF))
            end
        end

        local uv0 = ImVec2((r.x + pad_left - 1), (r.y + y)) * atlas.TexUvScale
        local uv1 = ImVec2((r.x + pad_left + line_width + 1), (r.y + y + 1)) * atlas.TexUvScale
        local half_v = (uv0.y + uv1.y) * 0.5
        atlas.TexUvLines[n] = ImVec4(uv0.x, half_v, uv1.x, half_v) -- TODO: indexing validation
    end
end

-- TODO: validate
--- @param atlas          ImFontAtlas
--- @param x              int
--- @param y              int
--- @param w              int
--- @param h              int
--- @param in_str         ImSlice
--- @param in_marker_char string
function ImFontAtlasBuildRenderBitmapFromString(atlas, x, y, w, h, in_str, in_marker_char)
    local tex = atlas.TexData
    IM_ASSERT(x >= 0 and x + w <= tex.Width)
    IM_ASSERT(y >= 0 and y + h <= tex.Height)

    if tex.Format == ImTextureFormat.Alpha8 then
        --- @type ImSlice<ImU8>
        local out_p = tex:GetPixelsAt(x, y)
        for off_y = 0, h - 1 do
            for off_x = 0, w - 1 do
                IM_SLICE_SET(out_p, off_x, (IM_SLICE_GET(in_str, off_x) == in_marker_char) and 0xFF or 0x00)
            end

            IM_SLICE_INC(out_p, tex.Width)
            IM_SLICE_INC(in_str, w)
        end
    elseif tex.Format == ImTextureFormat.RGBA32 then
        --- @type ImSlice<ImU32>
        local out_p = tex:GetPixelsAt(x, y)
        for off_y = 0, h - 1 do
            for off_x = 0, w - 1 do
                local rgba32 = (IM_SLICE_GET(in_str, off_x) == in_marker_char) and IM_COL32_WHITE or IM_COL32_BLACK_TRANS

                IM_SLICE_SET(out_p, off_x * 4 + 0, bit.band(rgba32, 0xFF))
                IM_SLICE_SET(out_p, off_x * 4 + 1, bit.band(bit.rshift(rgba32, 8), 0xFF))
                IM_SLICE_SET(out_p, off_x * 4 + 2, bit.band(bit.rshift(rgba32, 16), 0xFF))
                IM_SLICE_SET(out_p, off_x * 4 + 3, bit.band(bit.rshift(rgba32, 24), 0xFF))
            end

            IM_SLICE_INC(out_p, tex.Width * 4)
            IM_SLICE_INC(in_str, w)
        end
    end

    -- We have changed the offset of in_str, now change it back to 0
    IM_SLICE_RESET(in_str)
end

--- @param atlas ImFontAtlas
function ImFontAtlasBuildUpdateBasicTexData(atlas)
    local builder = atlas.Builder
    local pack_size = (bit.band(atlas.Flags, ImFontAtlasFlags.NoMouseCursors) ~= 0) and ImVec2(2, 2) or ImVec2(FONT_ATLAS_DEFAULT_TEX_DATA_W * 2 + 1, FONT_ATLAS_DEFAULT_TEX_DATA_H)

    local r = ImFontAtlasRect()
    local add_and_draw = (atlas:GetCustomRect(builder.PackIdMouseCursors, r) == false)
    if (add_and_draw) then
        builder.PackIdMouseCursors = atlas:AddCustomRect(pack_size.x, pack_size.y, r)
        IM_ASSERT(builder.PackIdMouseCursors ~= ImFontAtlasRectId_Invalid)

        if bit.band(atlas.Flags, ImFontAtlasFlags.NoMouseCursors) ~= 0 then
            ImFontAtlasBuildRenderBitmapFromString(atlas, r.x, r.y, 2, 2, IM_SLICE{"X", "X", "X", "X"}, "X")
        else
            local x_for_white = r.x
            local x_for_black = r.x + FONT_ATLAS_DEFAULT_TEX_DATA_W + 1
            ImFontAtlasBuildRenderBitmapFromString(atlas, x_for_white, r.y, FONT_ATLAS_DEFAULT_TEX_DATA_W, FONT_ATLAS_DEFAULT_TEX_DATA_H, FONT_ATLAS_DEFAULT_TEX_DATA_PIXELS, ".")
            ImFontAtlasBuildRenderBitmapFromString(atlas, x_for_black, r.y, FONT_ATLAS_DEFAULT_TEX_DATA_W, FONT_ATLAS_DEFAULT_TEX_DATA_H, FONT_ATLAS_DEFAULT_TEX_DATA_PIXELS, "X")
        end
    end

    atlas.TexUvWhitePixel = ImVec2((r.x + 0.5) * atlas.TexUvScale.x, (r.y + 0.5) * atlas.TexUvScale.y)
end

function ImFontAtlasUpdateDrawListsSharedData(atlas)
    for _, shared_data in atlas.DrawListSharedDatas:iter() do
        if (shared_data.FontAtlas == atlas) then
            shared_data.TexUvWhitePixel = atlas.TexUvWhitePixel
            shared_data.TexUvLines = atlas.TexUvLines
        end
    end
end

local function ImFontAtlasBuildInit(atlas)
    if atlas.FontLoader == nil then
        -- IMGUI_ENABLE_STB_TRUETYPE
        atlas:SetFontLoader(ImFontAtlasGetFontLoaderForStbTruetype())
    end

    if atlas.TexData == nil or atlas.TexData.Pixels == nil then
        ImFontAtlasTextureAdd(atlas, ImUpperPowerOfTwo(atlas.TexMinWidth), ImUpperPowerOfTwo(atlas.TexMinHeight))
    end
    atlas.Builder = ImFontAtlasBuilder()
    if atlas.FontLoader.LoaderInit then
        atlas.FontLoader.LoaderInit(atlas)
    end

    ImFontAtlasBuildUpdateRendererHasTexturesFromContext(atlas)

    ImFontAtlasPackInit(atlas)

    ImFontAtlasBuildUpdateLinesTexData(atlas)
    ImFontAtlasBuildUpdateBasicTexData(atlas)

    ImFontAtlasBuildUpdatePointers(atlas)

    ImFontAtlasUpdateDrawListsSharedData(atlas)

    ImTextInitClassifiers()
end

--- @param atlas ImFontAtlas
function ImFontAtlasBuildDestroy(atlas)
    for _, font in atlas.Fonts:iter() do
        ImFontAtlasFontDestroyOutput(atlas, font)
    end
    if atlas.Builder and atlas.FontLoader and atlas.FontLoader.LoaderShutdown then
        atlas.FontLoader.LoaderShutdown(atlas)
        IM_ASSERT(atlas.FontLoaderData == nil)
    end
    atlas.Builder = nil
end

--- @param atlas ImFontAtlas
function ImFontAtlasBuildMain(atlas)
    IM_ASSERT(not atlas.Locked, "Cannot modify a locked ImFontAtlas!")
    if (atlas.TexData and atlas.TexData.Format ~= atlas.TexDesiredFormat) then
        ImFontAtlasBuildClear(atlas)
    end

    if atlas.Builder == nil then
        ImFontAtlasBuildInit(atlas)
    end

    -- Default font is none are specified
    if atlas.Sources.Size == 0 then
        atlas:AddFontDefault()
    end

    -- [LEGACY] For backends not supporting RendererHasTextures: preload all glyphs
    -- ImFontAtlasBuildUpdateRendererHasTexturesFromContext(atlas);
    -- if atlas.RendererHasTextures == false then
    --     ImFontAtlasBuildLegacyPreloadAllGlyphRanges(atlas)
    -- end

    atlas.TexIsBuilt = true
end

function MT.ImTextureData:DestroyPixels()
    self.Pixels = nil
    self.UseColors = false
end

function ImTextureDataGetFormatBytesPerPixel(format)
    if format == ImTextureFormat.Alpha8 then
        return 1
    elseif format == ImTextureFormat.RGBA32 then
        return 4
    end
    IM_ASSERT(false)
    return 0
end

function MT.ImTextureData:Create(format, w, h)
    IM_ASSERT(self.Status == ImTextureStatus.Destroyed)
    self:DestroyPixels()
    self.Format = format
    self.Status = ImTextureStatus.WantCreate
    self.Width = w
    self.Height = h
    self.BytesPerPixel = ImTextureDataGetFormatBytesPerPixel(format)
    self.UseColors = false
    self.Pixels = IM_SLICE()
    IM_SLICE_FILL(self.Pixels, 0, self.Width * self.Height * self.BytesPerPixel)
    self.UsedRect.x = 0
    self.UsedRect.y = 0
    self.UsedRect.w = 0
    self.UsedRect.h = 0
    self.UpdateRect.x = 65535
    self.UpdateRect.y = 65535
    self.UpdateRect.w = 0
    self.UpdateRect.h = 0
end

function MT.ImFontBaked:ClearOutputData()
    self.FallbackAdvanceX = 0.0
    self.Glyphs:clear()
    self.IndexAdvanceX:clear()
    self.IndexLookup:clear()
    self.FallbackGlyphIndex = 0
    self.Ascent = 0.0
    self.Descent = 0.0
    self.MetricsTotalSurface = 0
end

--- @param c ImWchar
--- @return ImFontGlyph?
function MT.ImFontBaked:FindGlyph(c) -- TODO: indexing validation
    if c < self.IndexLookup.Size then -- IM_LIKELY
        local i = self.IndexLookup.Data[c + 1]
        if i == IM_FONTGLYPH_INDEX_NOT_FOUND then
            return self.Glyphs.Data[self.FallbackGlyphIndex]
        end
        if i ~= IM_FONTGLYPH_INDEX_UNUSED then
            return self.Glyphs.Data[i]
        end
    end

    local glyph = ImFontBaked_BuildLoadGlyph(self, c, nil)
    return (glyph ~= nil) and glyph or self.Glyphs.Data[self.FallbackGlyphIndex]
end

--- @param c ImWchar
--- @return ImFontGlyph?
function MT.ImFontBaked:FindGlyphNoFallback(c) -- TODO: indexing validation
    if c < self.IndexLookup.Size then -- IM_LIKELY
        local i = self.IndexLookup.Data[c + 1]
        if i == IM_FONTGLYPH_INDEX_NOT_FOUND then
            return nil
        end
        if i ~= IM_FONTGLYPH_INDEX_UNUSED then
            return self.Glyphs.Data[i]
        end
    end

    self.LoadNoFallback = true
    local glyph = ImFontBaked_BuildLoadGlyph(self, c, nil)
    self.LoadNoFallback = false
    return glyph
end

function MT.ImFont:ClearOutputData()
    local atlas = self.OwnerAtlas
    if atlas ~= nil then
        ImFontAtlasFontDiscardBakes(atlas, self, 0)
    end

    for i = 1, (IM_UNICODE_CODEPOINT_MAX + 1) / 8192 / 8 do self.Used8kPagesMap[i] = 0 end
    self.LastBaked = nil
end

--- @param font_id            ImGuiID
--- @param baked_size         float
--- @param rasterizer_density float
--- @return ImGuiID
function ImFontAtlasBakedGetId(font_id, baked_size, rasterizer_density)
    local hashed_data = {font_id, baked_size, rasterizer_density}
    return ImHashData(hashed_data)
end

--- @param atlas                   ImFontAtlas
--- @param font                    ImFont
--- @param font_size               float
--- @param font_rasterizer_density float
--- @return ImFontBaked?
function ImFontAtlasBakedGetOrAdd(atlas, font, font_size, font_rasterizer_density)
    IM_ASSERT(font_size > 0.0 and font_rasterizer_density > 0.0)
    local baked_id = ImFontAtlasBakedGetId(font.FontId, font_size, font_rasterizer_density)
    local builder = atlas.Builder
    local baked = builder.BakedMap:GetVoidPtrRef(baked_id)
    if baked ~= nil then
        IM_ASSERT(baked.Size == font_size and baked.OwnerFont == font and baked.BakedId == baked_id)

        return baked
    end

    if (bit.band(font.Flags, ImFontFlags.LockBakedSizes) ~= 0 or atlas.Locked) then
        baked = ImFontAtlasBakedGetClosestMatch(atlas, font, font_size, font_rasterizer_density)
        if baked ~= nil then
            return baked
        end
        if atlas.Locked then
            IM_ASSERT(not atlas.Locked, "Cannot use dynamic font size with a locked ImFontAtlas!")
            return nil
        end
    end

    baked = ImFontAtlasBakedAdd(atlas, font, font_size, font_rasterizer_density, baked_id)
    builder.BakedMap:SetVoidPtr(baked_id, baked)

    return baked
end

--- @param atlas    ImFontAtlas
--- @param baked    ImFontBaked
--- @param src?     ImFontConfig
--- @param in_glyph ImFontGlyph
--- @return ImFontGlyph, int
function ImFontAtlasBakedAddFontGlyph(atlas, baked, src, in_glyph)
    local glyph_idx = baked.Glyphs.Size + 1
    baked.Glyphs:push_back(in_glyph)
    local glyph = baked.Glyphs.Data[glyph_idx]
    IM_ASSERT(baked.Glyphs.Size < 0xFFFE)

    if (glyph.PackId ~= ImFontAtlasRectId_Invalid) then
        local r = ImFontAtlasPackGetRect(atlas, glyph.PackId)
        IM_ASSERT(glyph.U0 == 0.0 and glyph.V0 == 0.0 and glyph.U1 == 0.0 and glyph.V1 == 0.0)
        glyph.U0 = (r.x) * atlas.TexUvScale.x
        glyph.V0 = (r.y) * atlas.TexUvScale.y
        glyph.U1 = (r.x + r.w) * atlas.TexUvScale.x
        glyph.V1 = (r.y + r.h) * atlas.TexUvScale.y
        baked.MetricsTotalSurface = baked.MetricsTotalSurface + r.w * r.h
    end

    if (src ~= nil) then
        local ref_size = baked.OwnerFont.Sources:at(1).SizePixels
        local offsets_scale = (ref_size ~= 0.0) and (baked.Size / ref_size) or 1.0
        local advance_x = ImClamp(glyph.AdvanceX, src.GlyphMinAdvanceX * offsets_scale, src.GlyphMaxAdvanceX * offsets_scale)
        if (advance_x ~= glyph.AdvanceX) then
            local char_off_x = src.PixelSnapH and ImTrunc((advance_x - glyph.AdvanceX) * 0.5) or (advance_x - glyph.AdvanceX) * 0.5
            glyph.X0 = glyph.X0 + char_off_x
            glyph.X1 = glyph.X1 + char_off_x
        end

        if (src.PixelSnapH) then
            advance_x = IM_ROUND(advance_x)
        end

        glyph.AdvanceX = advance_x + src.GlyphExtraAdvanceX
    end
    if (glyph.Colored) then
        atlas.TexData.UseColors  = true
        atlas.TexPixelsUseColors = true
    end

    local codepoint = glyph.Codepoint
    ImFontBaked_BuildGrowIndex(baked, codepoint + 1)
    baked.IndexAdvanceX.Data[codepoint + 1] = glyph.AdvanceX -- TODO: indexing validation
    baked.IndexLookup.Data[codepoint + 1] = glyph_idx -- (ImU16)
    local page_n = codepoint / 8192
    baked.OwnerFont.Used8kPagesMap[bit.rshift(page_n, 3) + 1] = bit.bor(baked.OwnerFont.Used8kPagesMap[bit.rshift(page_n, 3) + 1], bit.lshift(1, bit.band(page_n, 7))) -- TODO: indexing validation

    return glyph, glyph_idx
end

function ImFontAtlasBakedAddFontGlyphAdvancedX(atlas, baked, src, codepoint, advance_x)
    error("NOT IMPLEMENTED", 2)
end

--- @param size    float
--- @param density float?
--- @return ImFontBaked?
function MT.ImFont:GetFontBaked(size, density)
    if not density then density = -1.0 end

    --- @type ImFontBaked?
    local baked = self.LastBaked

    size = ImGui.GetRoundedFontSize(size)

    if density < 0.0 then
        density = self.CurrentRasterizerDensity
    end
    if baked and baked.Size == size and baked.RasterizerDensity == density then
        return baked
    end

    local atlas = self.OwnerAtlas
    local builder = atlas.Builder
    baked = ImFontAtlasBakedGetOrAdd(atlas, self, size, density)
    if baked == nil then
        return nil
    end
    baked.LastUsedFrame = builder.FrameCount
    self.LastBaked = baked

    return baked
end

--- @param atlas ImFontAtlas
--- @param font  ImFont
--- @param c     ImWchar
--- @return ImWchar
--- @nodiscard
function ImFontAtlas_FontHookRemapCodepoint(atlas, font, c)
    -- IM_UNUSED(atlas)
    if font.RemapPairs.Data.Size ~= 0 then
        return font.RemapPairs:GetInt(c, c)
    end

    return c
end

--- @param baked                ImFontBaked
--- @param codepoint            ImWchar
--- @param only_load_advance_x? float_ptr
--- @return ImFontGlyph?, int?
function ImFontBaked_BuildLoadGlyph(baked, codepoint, only_load_advance_x)
    local font = baked.OwnerFont
    local atlas = font.OwnerAtlas
    if atlas.Locked or bit.band(font.Flags, ImFontFlags.NoLoadGlyphs) ~= 0 then
        if baked.FallbackGlyphIndex == 0 and baked.LoadNoFallback == false then
            ImFontAtlasBuildSetupFontBakedFallback(baked)
        end

        return nil
    end

    local src_codepoint = codepoint
    codepoint = ImFontAtlas_FontHookRemapCodepoint(atlas, font, codepoint)

    if (codepoint == font.EllipsisChar and font.EllipsisAutoBake) then
        local glyph = ImFontAtlasBuildSetupFontBakedEllipsis(atlas, baked)
        if (glyph) then
            return glyph
        end
    end

    -- local loader_user_data_p = baked.FontLoaderDatas
    local src_n = 1
    for _, src in font.Sources:iter() do
        local loader = src.FontLoader and src.FontLoader or atlas.FontLoader

        if (not src.GlyphExcludeRanges or ImFontAtlasBuildAcceptCodepointForSource(src, codepoint)) then
            if only_load_advance_x == nil then
                local glyph_buf = ImFontGlyph()

                if loader.FontBakedLoadGlyph(atlas, src, baked, loader_user_data_p, codepoint, glyph_buf, nil) then
                    glyph_buf.Codepoint = src_codepoint
                    glyph_buf.SourceIdx = src_n

                    return ImFontAtlasBakedAddFontGlyph(atlas, baked, src, glyph_buf)
                end
            else
                if (loader.FontBakedLoadGlyph(atlas, src, baked, loader_user_data_p, codepoint, nil, only_load_advance_x)) then
                    ImFontAtlasBakedAddFontGlyphAdvancedX(atlas, baked, src, codepoint, only_load_advance_x)

                    return nil
                end
            end
        end

        -- loader_user_data_p = loader_user_data_p + loader.FontBakedSrcLoaderDataSize
        src_n = src_n + 1
    end

    if (baked.LoadNoFallback) then
        return nil
    end
    if (baked.FallbackGlyphIndex == 0) then
        ImFontAtlasBuildSetupFontBakedFallback(baked)
    end

    ImFontBaked_BuildGrowIndex(baked, codepoint + 1);
    baked.IndexAdvanceX.Data[codepoint + 1] = baked.FallbackAdvanceX -- TODO: indexing validation
    baked.IndexLookup.Data[codepoint + 1] = IM_FONTGLYPH_INDEX_NOT_FOUND

    return nil
end

--- @param baked ImFontBaked
--- @param codepoint ImWchar
--- @return float
function ImFontBaked_BuildLoadGlyphAdvanceX(baked, codepoint)
    if (baked.Size >= IMGUI_FONT_SIZE_THRESHOLD_FOR_LOADADVANCEXONLYMODE) or baked.LoadNoRenderOnLayout then
        --- @type float_ptr
        local only_advance_x = {0.0}
        local glyph = ImFontBaked_BuildLoadGlyph(baked, codepoint, only_advance_x)
        return glyph and glyph.AdvanceX or only_advance_x[1]
    else
        local glyph = ImFontBaked_BuildLoadGlyph(baked, codepoint, nil)
        return glyph and glyph.AdvanceX or baked.FallbackAdvanceX
    end
end

--- @param c ImWchar
--- @return bool
function MT.ImFont:IsGlyphInFont(c)
    local atlas = self.OwnerAtlas
    c = ImFontAtlas_FontHookRemapCodepoint(atlas, self, c)
    for _, src in self.Sources:iter() do
        local loader = src.FontLoader and src.FontLoader or atlas.FontLoader
        if loader.FontSrcContainsGlyph ~= nil and loader.FontSrcContainsGlyph(atlas, src, c) then
            return true
        end
    end

    return false
end

function BuildLoadGlyphGetAdvanceOrFallback(baked, codepoint)
    return ImFontBaked_BuildLoadGlyphAdvanceX(baked, codepoint)
end

--- @param text       string
--- @param text_begin int
--- @param text_end   int
--- @param flags      ImDrawTextFlags
--- @return int
function ImTextCalcWordWrapNextLineStart(text, text_begin, text_end, flags)
    local pos = text_begin

    if bit.band(flags, ImDrawTextFlags.WrapKeepBlanks) == 0 then
        while pos < text_end and ImCharIsBlankA(string.byte(text, pos)) do
            pos = pos + 1
        end
    end

    if pos < text_end and string.byte(text, pos) == chr'\n' then
        pos = pos + 1
    end

    return pos
end

--- @param bits          ImU32[]
--- @param codepoint_min unsigned_int
--- @param codepoint_end unsigned_int
--- @param char_class    ImWcharClass
function ImTextClassifierClear(bits, codepoint_min, codepoint_end, char_class)
    for c = codepoint_min, codepoint_end - 1 do
        ImTextClassifierSetCharClass(bits, codepoint_min, codepoint_end, char_class, c)
    end
end

--- @param bits          ImU32[]
--- @param codepoint_min unsigned_int
--- @param codepoint_end unsigned_int
--- @param char_class    ImWcharClass
--- @param c             unsigned_int
function ImTextClassifierSetCharClass(bits, codepoint_min, codepoint_end, char_class, c)
    IM_ASSERT(c >= codepoint_min and c < codepoint_end)
    -- IM_UNUSED(codepoint_end)
    c = c - codepoint_min
    local shift = bit.lshift(bit.band(c, 15), 1)
    bits[bit.rshift(c, 4) + 1] = bit.bor(bit.band(bits[bit.rshift(c, 4) + 1], bit.bnot(bit.lshift(0x03, shift))), bit.lshift(char_class, shift))
end

function ImTextClassifierSetCharClassFromStr(bits, codepoint_min, codepoint_end, char_class, s)
    local s_end = #s + 1
    local pos = 1
    while (pos < s_end) do
        local wanted, c = ImTextCharFromUtf8(s, pos, s_end)
        pos = pos + wanted
        ImTextClassifierSetCharClass(bits, codepoint_min, codepoint_end, char_class, c)
    end
end

function ImTextClassifierGet(_BITS, _CHAR_OFFSET)
    return bit.band(bit.rshift(_BITS[bit.rshift(_CHAR_OFFSET, 4) + 1], bit.lshift(bit.band(_CHAR_OFFSET, 15), 1)), 0x03)
end

local g_CharClassifierIsSeparator_0000_007f = {} for i = 1, 128 / 16 do g_CharClassifierIsSeparator_0000_007f[i] = 0 end
local g_CharClassifierIsSeparator_3000_300f = {} for i = 1, 16 / 16 do g_CharClassifierIsSeparator_3000_300f[i] = 0 end

function ImTextInitClassifiers()
    if (ImTextClassifierGet(g_CharClassifierIsSeparator_0000_007f, chr',') ~= 0) then
        return
    end

    ImTextClassifierClear(g_CharClassifierIsSeparator_0000_007f, 0, 128, ImWcharClass.Other)
    ImTextClassifierSetCharClassFromStr(g_CharClassifierIsSeparator_0000_007f, 0, 128, ImWcharClass.Blank, " \t")
    ImTextClassifierSetCharClassFromStr(g_CharClassifierIsSeparator_0000_007f, 0, 128, ImWcharClass.Punct, ".,;!?\"")

    ImTextClassifierClear(g_CharClassifierIsSeparator_3000_300f, 0x3000, 0x300F, ImWcharClass.Other)
    ImTextClassifierSetCharClass(g_CharClassifierIsSeparator_3000_300f, 0x3000, 0x300F, ImWcharClass.Blank, 0x3000)
    ImTextClassifierSetCharClass(g_CharClassifierIsSeparator_3000_300f, 0x3000, 0x300F, ImWcharClass.Punct, 0x3001)
    ImTextClassifierSetCharClass(g_CharClassifierIsSeparator_3000_300f, 0x3000, 0x300F, ImWcharClass.Punct, 0x3002)
end

--- @param font       ImFont
--- @param size       float
--- @param text       string
--- @param pos        int
--- @param text_end   int
--- @param wrap_width float
--- @param flags      ImDrawTextFlags
--- @return int
function ImFontCalcWordWrapPositionEx(font, size, text, pos, text_end, wrap_width, flags)
    local baked = font:GetFontBaked(size)
    local scale = size / baked.Size

    local line_width = 0.0
    local blank_width = 0.0
    wrap_width = wrap_width / scale

    local s = pos
    IM_ASSERT(text_end ~= nil)

    local prev_type = ImWcharClass.Other
    local keep_blanks = bit.band(flags, ImDrawTextFlags.WrapKeepBlanks) ~= 0

    local span_end = s
    local span_width = 0.0

    while s < text_end do
        --- @type unsigned_int
        local c = string.byte(text, s)
        local next_s
        if c < 0x80 then
            next_s = s + 1
        else
            local wanted, out_char = ImTextCharFromUtf8(text, s, text_end)
            c = out_char
            next_s = s + wanted
        end

        if c < 32 then
            if c == chr'\n' then
                return s
            end
            if c == chr'\r' then
                s = next_s

                continue
            end
        end

        local char_width = (c < baked.IndexAdvanceX.Size) and baked.IndexAdvanceX.Data[c + 1] or -1.0 -- TODO: indexing validation
        if char_width < 0.0 then
            char_width = BuildLoadGlyphGetAdvanceOrFallback(baked, c)
        end

        local curr_type
        if c < 128 then
            curr_type = ImTextClassifierGet(g_CharClassifierIsSeparator_0000_007f, c)
        elseif (c >= 0x3000 and c < 0x3010) then
            curr_type = ImTextClassifierGet(g_CharClassifierIsSeparator_3000_300f, bit.band(c, 15))
        else
            curr_type = ImWcharClass.Other
        end

        if curr_type == ImWcharClass.Blank then
            if (prev_type ~= ImWcharClass.Blank and not keep_blanks) then
                span_end = s
                line_width = line_width + span_width
                span_width = 0.0
            end

            blank_width = blank_width + char_width
        else
            if (prev_type == ImWcharClass.Punct and curr_type ~= ImWcharClass.Punct and not (c >= chr'0' and c <= chr'9')) then
                span_end = s
                line_width = line_width + (span_width + blank_width)
                blank_width = 0.0
                span_width = 0.0
            elseif (prev_type == ImWcharClass.Blank and keep_blanks) then
                span_end = s
                line_width = line_width + (span_width + blank_width)
                blank_width = 0.0
                span_width = 0.0
            end

            span_width = span_width + char_width
        end

        if (span_width + blank_width + line_width > wrap_width) then
            if span_width + blank_width > wrap_width then
                break
            end

            return span_end
        end

        prev_type = curr_type
        s = next_s
    end

    if s == pos and s < text_end then
        local bytes = ImTextCountUtf8BytesFromChar(text, s, text_end)

        return s + bytes
    end

    return s
end

--- @param font             ImFont
--- @param size             float
--- @param max_width        float
--- @param wrap_width       float
--- @param text             string
--- @param text_begin       int
--- @param text_end_display int?
--- @param text_end         int?
--- @param flags            ImDrawTextFlags
--- @return ImVec2, int, ImVec2
function ImFontCalcTextSizeEx(font, size, max_width, wrap_width, text, text_begin, text_end_display, text_end, flags)
    if not text_end then
        text_end = #text + 1
    end
    if not text_end_display then
        text_end_display = text_end
    end

    local baked = font:GetFontBaked(size)
    local line_height = size
    local scale = line_height / baked.Size

    local text_size = ImVec2()
    local line_width = 0.0

    local word_wrap_enabled = (wrap_width > 0.0)
    local word_wrap_eol

    local s = text_begin
    while s < text_end_display do
        if word_wrap_enabled then
            if not word_wrap_eol then
                word_wrap_eol = ImFontCalcWordWrapPositionEx(font, size, text, s, text_end, wrap_width - line_width, flags)
            end

            if s >= word_wrap_eol then
                if text_size.x < line_width then
                    text_size.x = line_width
                end
                text_size.y = text_size.y + line_height
                line_width = 0.0
                s = ImTextCalcWordWrapNextLineStart(text, s, text_end, flags)
                if bit.band(flags, ImDrawTextFlags_StopOnNewLine) ~= 0 then
                    break
                end
                word_wrap_eol = nil

                continue
            end
        end

        local prev_s = s
        local c = string.byte(text, s)
        if c < 0x80 then
            s = s + 1
        else
            local wanted, out_char = ImTextCharFromUtf8(text, s, text_end)
            c = out_char
            s = s + wanted
        end

        if c == chr'\n' then
            text_size.x = ImMax(text_size.x, line_width)
            text_size.y = text_size.y + line_height
            line_width = 0.0
            if bit.band(flags, ImDrawTextFlags.StopOnNewLine) ~= 0 then
                break
            end

            continue
        end

        if c == chr'\r' then
            continue
        end

        local char_width = (c < baked.IndexAdvanceX.Size) and baked.IndexAdvanceX.Data[c + 1] or -1.0 -- TODO: indexing validation
        if (char_width < 0.0) then
            char_width = BuildLoadGlyphGetAdvanceOrFallback(baked, c)
        end
        char_width = char_width * scale

        if (line_width + char_width >= max_width) then
            s = prev_s
            break
        end

        line_width = line_width + char_width
    end

    if (text_size.x < line_width) then
        text_size.x = line_width
    end

    local out_offset = ImVec2(line_width, text_size.y + line_height)

    if (line_width > 0 or text_size.y == 0.0) then
        text_size.y = text_size.y + line_height
    end

    local out_remaining = s

    return text_size, out_remaining, out_offset
end

function MT.ImFont:CalcTextSizeA(size, max_width, wrap_width, text, text_begin, text_end)
    return ImFontCalcTextSizeEx(self, size, max_width, wrap_width, text, text_begin, text_end, text_end, ImDrawTextFlags.None)
end

function MT.ImFontAtlas:AddFont(font_cfg_in)
    IM_ASSERT(not self.Locked, "Cannot modify a locked ImFontAtlas!")
    IM_ASSERT((font_cfg_in.FontData ~= nil and font_cfg_in.FontDataSize > 0) or (font_cfg_in.FontLoader ~= nil))
    IM_ASSERT(font_cfg_in.SizePixels > 0.0, "Is ImFontConfig struct correctly initialized?")
    IM_ASSERT(font_cfg_in.RasterizerDensity > 0.0, "Is ImFontConfig struct correctly initialized?")

    if font_cfg_in.GlyphOffset.x ~= 0.0 or font_cfg_in.GlyphOffset.y ~= 0.0 or
        font_cfg_in.GlyphMinAdvanceX ~= 0.0 or font_cfg_in.GlyphMaxAdvanceX ~= FLT_MAX then
        IM_ASSERT(font_cfg_in.SizePixels ~= 0.0,
            "Specifying glyph offset/advances requires a reference size to base it on.")
    end

    if self.Builder == nil then
        ImFontAtlasBuildInit(self)
    end

    local font
    if not font_cfg_in.MergeMode then
        font = ImFont()
        font.FontId = self.FontNextUniqueID
        self.FontNextUniqueID = self.FontNextUniqueID + 1
        font.Flags = font_cfg_in.Flags
        font.LegacySize = font_cfg_in.SizePixels
        font.CurrentRasterizerDensity = font_cfg_in.RasterizerDensity
        self.Fonts:push_back(font)
    else
        IM_ASSERT(self.Fonts.Size > 0, "Cannot use MergeMode for the first font")
        font = (font_cfg_in.DstFont ~= nil) and font_cfg_in.DstFont or self.Fonts:back()
    end

    self.Sources:push_back(font_cfg_in)
    local font_cfg = self.Sources:back()
    if (font_cfg.DstFont == nil) then
        font_cfg.DstFont = font
    end
    font.Sources:push_back(font_cfg)
    ImFontAtlasBuildUpdatePointers(self)

    if font_cfg.GlyphExcludeRanges ~= nil then
        local size = 0
        for _, v in ipairs(font_cfg.GlyphExcludeRanges) do if v == 0 then break end size = size + 1 end
        IM_ASSERT(bit.band(size, 1) == 0, "GlyphExcludeRanges[] size must be multiple of two!")
        IM_ASSERT(size <= 64, "GlyphExcludeRanges[] size must be small!")
    end

    if font_cfg.FontLoader ~= nil then
        IM_ASSERT(font_cfg.FontLoader.FontBakedLoadGlyph ~= nil)
        IM_ASSERT(font_cfg.FontLoader.LoaderInit == nil and font_cfg.FontLoader.LoaderShutdown == nil)
    end
    IM_ASSERT(font_cfg.FontLoaderData == nil)

    if not ImFontAtlasFontSourceInit(self, font_cfg) then
        ImFontAtlasFontDestroySourceData(self, font_cfg)
        self.Sources:pop_back()
        font.Sources:pop_back()
        if not font_cfg.MergeMode then
            font = nil
            self.Fonts:pop_back()
        end
        return nil
    end
    ImFontAtlasFontSourceAddToFont(self, font, font_cfg)

    return font
end

--- @param ctx ImGuiContext
--- @return float
local function GetExpectedContextFontSize(ctx)
    return ((ctx.Style.FontSizeBase > 0.0) and ctx.Style.FontSizeBase or 13.0) * ctx.Style.FontScaleMain * ctx.Style.FontScaleDpi
end

--- @param font_cfg ImFontConfig
function MT.ImFontAtlas:AddFontDefault(font_cfg)
    if self.OwnerContext == nil or GetExpectedContextFontSize(self.OwnerContext) >= 16.0 then
        return self:AddFontDefaultVector(font_cfg)
    else
        return self:AddFontDefaultBitmap(font_cfg)
    end
end

function MT.ImFontAtlas:AddFontFromMemoryTTF(font_data, font_data_size, size_pixels, font_cfg_template, glyph_ranges)
    IM_ASSERT(not self.Locked, "Cannot modify a locked ImFontAtlas!")
    local font_cfg = font_cfg_template and font_cfg_template or ImFontConfig()
    IM_ASSERT(font_cfg.FontData == nil)
    IM_ASSERT(font_data_size > 100, "Incorrect value for font_data_size!")
    font_cfg.FontData = font_data
    font_cfg.FontDataSize = font_data_size
    font_cfg.SizePixels = (size_pixels > 0.0) and size_pixels or font_cfg.SizePixels
    if glyph_ranges then
        font_cfg.GlyphRanges = glyph_ranges
    end
    return self:AddFont(font_cfg)
end

function MT.ImFontAtlas:AddFontFromMemoryCompressedTTF()
    -- TODO: 
end

function MT.ImFontAtlas:AddFontFromFileTTF(filename, size_pixels, font_cfg_template, glyph_ranges)
    IM_ASSERT(not self.Locked, "Cannot modify a locked ImFontAtlas!")

    local data, data_size = ImFileLoadToMemory(filename, "rb")
    if not data then
        if (font_cfg_template == nil or (bit.band(font_cfg_template.Flags, ImFontFlags.NoLoadError) == 0)) then
            -- IMGUI_DEBUG_LOG("While loading '%s'\n", filename)
            IM_ASSERT_USER_ERROR(0, "Could not load font file!")
        end

        return nil
    end

    local font_cfg = font_cfg_template and font_cfg_template or ImFontConfig()
    if not font_cfg.Name or font_cfg.Name == "" then
        font_cfg.Name = string.GetFileFromFilename(filename) -- TODO: validate
    end

    return self:AddFontFromMemoryTTF(data, data_size, size_pixels, font_cfg, glyph_ranges)
end

function GetDefaultFontDataProggyClean()
    return ImFileLoadToMemory("resource/fonts/ProggyClean.ttf", "rb")
end

--- @param font_cfg_template ImFontConfig
function MT.ImFontAtlas:AddFontDefaultBitmap(font_cfg_template)
    -- #ifndef IMGUI_DISABLE_DEFAULT_FONT
    local font_cfg = font_cfg_template and font_cfg_template or ImFontConfig()
    if not font_cfg_template then
        font_cfg.OversampleV = 1
        font_cfg.OversampleH = 1
        font_cfg.PixelSnapH  = true
    end
    if font_cfg.SizePixels <= 0.0 then
        font_cfg.SizePixels = 13.0
    end
    if not font_cfg.Name or font_cfg.Name == "" then
        font_cfg.Name = "ProggyClean.ttf"
    end
    font_cfg.EllipsisChar = 0x0085
    font_cfg.GlyphOffset.y = font_cfg.GlyphOffset.y +  1.0 * (font_cfg.SizePixels / 13.0)

    local ttf_data, ttf_data_size = GetDefaultFontDataProggyClean()
    return self:AddFontFromMemoryTTF(ttf_data, ttf_data_size, font_cfg.SizePixels, font_cfg)
    -- #else

    -- #endif
end

--- @param font_cfg_template ImFontConfig
function MT.ImFontAtlas:AddFontDefaultVector(font_cfg_template)
    -- TODO: 
end

function MT.ImFontAtlas:GetCustomRect(id, out_r)
    local r = ImFontAtlasPackGetRectSafe(self, id)
    if r == nil then
        return false
    end
    IM_ASSERT(self.TexData.Width > 0 and self.TexData.Height > 0)
    if out_r == nil then
        return true
    end
    out_r.x = r.x
    out_r.y = r.y
    out_r.w = r.w
    out_r.h = r.h
    out_r.uv0 = ImVec2((r.x), (r.y)) * self.TexUvScale
    out_r.uv1 = ImVec2((r.x + r.w), (r.y + r.h)) * self.TexUvScale

    return true
end

function MT.ImFontAtlas:AddCustomRect(width, height, out_r)
    IM_ASSERT(width > 0 and width <= 0xFFFF)
    IM_ASSERT(height > 0 and height <= 0xFFFF)

    if (self.Builder == nil) then
        ImFontAtlasBuildInit(self)
    end

    local r_id = ImFontAtlasPackAddRect(self, width, height)
    if (r_id == ImFontAtlasRectId_Invalid) then
        return ImFontAtlasRectId_Invalid
    end
    if (out_r ~= nil) then
        self:GetCustomRect(r_id, out_r)
    end

    if (self.RendererHasTextures) then
        local r = ImFontAtlasPackGetRect(self, r_id)
        ImFontAtlasTextureBlockQueueUpload(self, self.TexData, r.x, r.y, r.w, r.h)
    end

    return r_id
end

local function IM_NORMALIZE2F_OVER_ZERO(VX, VY)
    local d2 = VX * VX + VY * VY
    if d2 > 0.0 then
        local inv_len = ImRsqrt(d2)
        VX = VX * inv_len
        VY = VY * inv_len
    end
    return VX, VY
end

local IM_FIXNORMAL2F_MAX_INVLEN2 = 100

local function IM_FIXNORMAL2F(VX, VY)
    local d2 = VX * VX + VY * VY
    if d2 > 0.000001 then
        local inv_len2 = 1.0 / d2
        if inv_len2 > IM_FIXNORMAL2F_MAX_INVLEN2 then
            inv_len2 = IM_FIXNORMAL2F_MAX_INVLEN2
        end
        VX = VX * inv_len2
        VY = VY * inv_len2
    end
    return VX, VY
end

function MT.ImDrawData:Clear()
    self.Valid         = false
    self.CmdListsCount = 0
    self.TotalIdxCount = 0
    self.TotalVtxCount = 0
    self.CmdLists:resize(0)
    self.DisplayPos       = ImVec2(0.0, 0.0)
    self.DisplaySize      = ImVec2(0.0, 0.0)
    self.FramebufferScale = ImVec2(0.0, 0.0)
    self.OwnerViewport    = nil
    self.Textures         = nil
end

function ImGui.AddDrawListToDrawDataEx(draw_data, out_list, draw_list)
    if draw_list.CmdBuffer.Size == 0 then
        return
    end
    if draw_list.CmdBuffer.Size == 1 and draw_list.CmdBuffer.Data[1].ElemCount == 0 and draw_list.CmdBuffer[1].UserCallback == nil then
        return
    end

    IM_ASSERT(draw_list.VtxBuffer.Size == 0 or draw_list._VtxWritePtr == draw_list.VtxBuffer.Size + 1)
    IM_ASSERT(draw_list.IdxBuffer.Size == 0 or draw_list._IdxWritePtr == draw_list.IdxBuffer.Size + 1)
    if (bit.band(draw_list.Flags, ImDrawListFlags_AllowVtxOffset) == 0) then
        IM_ASSERT(draw_list._VtxCurrentIdx == draw_list.VtxBuffer.Size + 1)
    end

    out_list:push_back(draw_list)
    draw_data.CmdListsCount = draw_data.CmdListsCount + 1
    draw_data.TotalVtxCount = draw_data.TotalVtxCount + draw_list.VtxBuffer.Size
    draw_data.TotalIdxCount = draw_data.TotalIdxCount + draw_list.IdxBuffer.Size
end

function MT.ImDrawData:AddDrawList(draw_list)
    IM_ASSERT(self.CmdLists.Size == self.CmdListsCount)
    draw_list:_PopUnusedDrawCmd()
    ImGui.AddDrawListToDrawDataEx(self, self.CmdLists, draw_list)
end

function MT.ImDrawListSharedData:SetCircleTessellationMaxError(max_error)
    if self.CircleSegmentMaxError == max_error then return end
    IM_ASSERT(max_error > 0)

    self.CircleSegmentMaxError = max_error
    for i = 0, 64 - 1 do
        local radius = i
        self.CircleSegmentCounts[i] = i > 0 and IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC(radius, self.CircleSegmentMaxError) or IM_DRAWLIST_ARCFAST_SAMPLE_MAX
    end

    self.ArcFastRadiusCutoff = IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_R(IM_DRAWLIST_ARCFAST_SAMPLE_MAX, self.CircleSegmentMaxError)
end

--- void ImDrawList::_SetDrawListSharedData(ImDrawListSharedData* data)
function MT.ImDrawList:_SetDrawListSharedData(data)
    if self._Data ~= nil then
        self._Data.DrawLists:find_erase_unsorted(self)
    end
    self._Data = data
    if self._Data ~= nil then
        self._Data.DrawLists:push_back(self)
    end

    -- GLUA: Keep Reference
    if data then self._CmdHeader.TexRef = data.FontAtlas.TexRef end
end

function MT.ImDrawList:_ResetForNewFrame()
    self.CmdBuffer:resize(0)
    self.IdxBuffer:resize(0)
    self.VtxBuffer:resize(0)

    -- GLUA: Keep Reference
    local tex_ref = self._CmdHeader.TexRef
    self._CmdHeader = ImDrawCmdHeader()
    self._CmdHeader.TexRef = tex_ref

    self._VtxCurrentIdx = 1
    self._VtxWritePtr = 1
    self._IdxWritePtr = 1
    self._ClipRectStack:resize(0)
    self._TextureStack:resize(0)
    self._Path:resize(0)

    -- GLUA: Keep Reference
    local draw_cmd = ImDrawCmd()
    draw_cmd.TexRef = tex_ref
    self.CmdBuffer:push_back(draw_cmd)

    self._FringeScale = self._Data.InitialFringeScale
end

function MT.ImDrawList:_ClearFreeMemory()
    self.CmdBuffer:clear()
    self.IdxBuffer:clear()
    self.VtxBuffer:clear()

    self.Flags = ImDrawListFlags_None

    self._VtxCurrentIdx = 1
    self._VtxWritePtr = 1
    self._IdxWritePtr = 1

    self._ClipRectStack:clear()
    self._TextureStack:clear()
    -- self._CallbacksDataBuf:clear()
    self._Path:clear()
    -- self._Splitter.ClearFreeMemory()
end

function MT.ImDrawList:AddDrawCmd()
    local draw_cmd = ImDrawCmd()

    draw_cmd.ClipRect  = self._CmdHeader.ClipRect
    draw_cmd.TexRef    = self._CmdHeader.TexRef
    draw_cmd.VtxOffset = self._CmdHeader.VtxOffset
    draw_cmd.IdxOffset = self.IdxBuffer.Size

    IM_ASSERT(draw_cmd.ClipRect.x <= draw_cmd.ClipRect.z and draw_cmd.ClipRect.y <= draw_cmd.ClipRect.w)
    self.CmdBuffer:push_back(draw_cmd)
end

function MT.ImDrawList:_PopUnusedDrawCmd()
    while self.CmdBuffer.Size > 0 do
        local curr_cmd = self.CmdBuffer.Data[self.CmdBuffer.Size]
        if curr_cmd.ElemCount ~= 0 then
            break
        end

        self.CmdBuffer:pop_back()
    end
end

function MT.ImDrawList:_OnChangedClipRect()
    IM_ASSERT_PARANOID(self.CmdBuffer.Size > 0)
    local curr_cmd = self.CmdBuffer.Data[self.CmdBuffer.Size]
    if (curr_cmd.ElemCount ~= 0 and self._CmdHeader.ClipRect ~= curr_cmd.ClipRect) then
        self:AddDrawCmd()

        return
    end

    IM_ASSERT(curr_cmd.UserCallback == nil)

    -- TODO: 
    -- local prev_cmd = self.CmdBuffer.Data[self.CmdBuffer.Size - 1]
    -- if (curr_cmd.ElemCount == 0 and self.CmdBuffer.Size > 1 and ImDrawCmd_HeaderCompare(self._CmdHeader, prev_cmd) and ImDrawCmd_AreSequentialIdxOffset(prev_cmd, curr_cmd) and prev_cmd.UserCallback == nil) then
    --     self.CmdBuffer.pop_back()

    --     return
    -- end

    curr_cmd.ClipRect = self._CmdHeader.ClipRect
end

function MT.ImDrawList:_OnChangedTexture()
    IM_ASSERT_PARANOID(self.CmdBuffer.Size > 0)
    local curr_cmd = self.CmdBuffer.Data[self.CmdBuffer.Size]
    if curr_cmd.ElemCount ~= 0 and curr_cmd.TexRef ~= self._CmdHeader.TexRef then
        self:AddDrawCmd()

        return
    end

    if curr_cmd.UserCallback ~= nil then
        return
    end

    -- TODO: 
    -- local prev_cmd = self.CmdBuffer.Data[self.CmdBuffer.Size - 1]
    -- if curr_cmd.ElemCount == 0 and self.CmdBuffer.Size > 1 and ImDrawCmd_HeaderCompare(self._CmdHeader, prev_cmd) and ImDrawCmd_AreSequentialIdxOffset(prev_cmd, curr_cmd) and prev_cmd.UserCallback == nil then
    --     self.CmdBuffer:pop_back()

    --     return
    -- end

    curr_cmd.TexRef = self._CmdHeader.TexRef
end

function MT.ImDrawList:_OnChangedVtxOffset()
    self._VtxCurrentIdx = 1
    IM_ASSERT_PARANOID(self.CmdBuffer.Size > 0)

    local curr_cmd = self.CmdBuffer.Data[self.CmdBuffer.Size]
    if curr_cmd.ElemCount ~= 0 then
        self:AddDrawCmd()
        return
    end
    IM_ASSERT(curr_cmd.UserCallback == nil)
    curr_cmd.VtxOffset = self._CmdHeader.VtxOffset
end

function MT.ImDrawList:AddConvexPolyFilled(points, points_count, col) -- TODO: cleanup
    if points_count < 3 or col.a == 0 then return end

    local uv = self._Data.TexUvWhitePixel

    if bit.band(self.Flags, ImDrawListFlags_AntiAliasedFill) ~= 0 then
        local AA_SIZE = self._FringeScale
        local col_trans = {r = col.r, g = col.g, b = col.b, a = 0}
        local idx_count = (points_count - 2) * 3 + points_count * 6
        local vtx_count = points_count * 2
        self:PrimReserve(idx_count, vtx_count)

        local vtx_inner_idx = self._VtxCurrentIdx
        local vtx_outer_idx = self._VtxCurrentIdx + 1
        for i = 2, points_count - 1 do
            local idx_write_ptr = self._IdxWritePtr
            self.IdxBuffer.Data[idx_write_ptr] = vtx_inner_idx
            self.IdxBuffer.Data[idx_write_ptr + 1] = vtx_inner_idx + ((i - 1) * 2)
            self.IdxBuffer.Data[idx_write_ptr + 2] = vtx_inner_idx + (i * 2)
            self._IdxWritePtr = idx_write_ptr + 3
        end

        self._Data.TempBuffer:reserve_discard(points_count)
        local temp_normals = self._Data.TempBuffer.Data

        local i0 = points_count
        for i1 = 1, points_count do
            local p0 = points[i0]
            local p1 = points[i1]
            local dx = p1.x - p0.x
            local dy = p1.y - p0.y
            dx, dy = IM_NORMALIZE2F_OVER_ZERO(dx, dy)
            temp_normals[i0].x = dy
            temp_normals[i0].y = -dx

            i0 = i1
        end

        i0 = points_count
        for i1 = 1, points_count do
            local n0 = temp_normals[i0]
            local n1 = temp_normals[i1]
            local dm_x = (n0.x + n1.x) * 0.5
            local dm_y = (n0.y + n1.y) * 0.5
            dm_x, dm_y = IM_FIXNORMAL2F(dm_x, dm_y)
            dm_x = dm_x * AA_SIZE * 0.5
            dm_y = dm_y * AA_SIZE * 0.5

            local p1 = points[i1]
            local vtx_write_ptr = self._VtxWritePtr

            self.VtxBuffer.Data[vtx_write_ptr] = ImDrawVert()
            self.VtxBuffer.Data[vtx_write_ptr].pos.x = p1.x - dm_x
            self.VtxBuffer.Data[vtx_write_ptr].pos.y = p1.y - dm_y
            self.VtxBuffer.Data[vtx_write_ptr].uv = uv
            self.VtxBuffer.Data[vtx_write_ptr].col = col

            self.VtxBuffer.Data[vtx_write_ptr + 1] = ImDrawVert()
            self.VtxBuffer.Data[vtx_write_ptr + 1].pos.x = p1.x + dm_x
            self.VtxBuffer.Data[vtx_write_ptr + 1].pos.y = p1.y + dm_y
            self.VtxBuffer.Data[vtx_write_ptr + 1].uv = uv
            self.VtxBuffer.Data[vtx_write_ptr + 1].col = col_trans

            self._VtxWritePtr = vtx_write_ptr + 2

            local idx_write_ptr = self._IdxWritePtr

            self.IdxBuffer.Data[idx_write_ptr] = vtx_inner_idx + ((i1 - 1) * 2)
            self.IdxBuffer.Data[idx_write_ptr + 1] = vtx_inner_idx + ((i0 - 1) * 2)
            self.IdxBuffer.Data[idx_write_ptr + 2] = vtx_outer_idx + ((i0 - 1) * 2)
            self.IdxBuffer.Data[idx_write_ptr + 3] = vtx_outer_idx + ((i0 - 1) * 2)
            self.IdxBuffer.Data[idx_write_ptr + 4] = vtx_outer_idx + ((i1 - 1) * 2)
            self.IdxBuffer.Data[idx_write_ptr + 5] = vtx_inner_idx + ((i1 - 1) * 2)
            self._IdxWritePtr = idx_write_ptr + 6

            i0 = i1
        end
        self._VtxCurrentIdx = self._VtxCurrentIdx + vtx_count
    else
        local idx_count = (points_count - 2) * 3
        local vtx_count = points_count
        self:PrimReserve(idx_count, vtx_count)

        for i = 1, points_count do
            local vtx_write_ptr = self._VtxWritePtr
            self.VtxBuffer.Data[vtx_write_ptr] = ImDrawVert()
            self.VtxBuffer.Data[vtx_write_ptr].pos = points[i]
            self.VtxBuffer.Data[vtx_write_ptr].uv = uv
            self.VtxBuffer.Data[vtx_write_ptr].col = col
            self._VtxWritePtr = vtx_write_ptr + 1
        end

        for i = 3, points_count do
            local idx_write_ptr = self._IdxWritePtr
            self.IdxBuffer.Data[idx_write_ptr] = self._VtxCurrentIdx
            self.IdxBuffer.Data[idx_write_ptr + 1] = self._VtxCurrentIdx + i - 2
            self.IdxBuffer.Data[idx_write_ptr + 2] = self._VtxCurrentIdx + i - 1
            self._IdxWritePtr = idx_write_ptr + 3
        end

        self._VtxCurrentIdx = self._VtxCurrentIdx + vtx_count
    end
end

function MT.ImDrawList:PushTexture(tex_ref)
    self._TextureStack:push_back(tex_ref)
    self._CmdHeader.TexRef = tex_ref
    if (tex_ref._TexData ~= nil) then
        IM_ASSERT(tex_ref._TexData.WantDestroyNextFrame == false)
    end
    self:_OnChangedTexture()
end

function MT.ImDrawList:PopTexture()
    self._TextureStack:pop_back()
    self._CmdHeader.TexRef = (self._TextureStack.Size == 0) and ImTextureRef() or self._TextureStack.Data[self._TextureStack.Size]
    self:_OnChangedTexture()
end

function MT.ImDrawList:_SetTexture(tex_ref)
    if (self._CmdHeader.TexRef == tex_ref) then
        return
    end
    self._CmdHeader.TexRef = tex_ref
    self._TextureStack.Data[self._TextureStack.Size] = tex_ref
    self:_OnChangedTexture()
end

--- TODO: LIMIT: 65536 for imesh, 4096 for drawpoly
function MT.ImDrawList:PrimReserve(idx_count, vtx_count)
    IM_ASSERT_PARANOID(idx_count >= 0 and vtx_count >= 0)

    if self._VtxCurrentIdx + vtx_count >= 4096 then
        self._CmdHeader.VtxOffset = self.VtxBuffer.Size + 1
        self:_OnChangedVtxOffset()
    end

    local draw_cmd = self.CmdBuffer.Data[self.CmdBuffer.Size]
    draw_cmd.ElemCount = draw_cmd.ElemCount + idx_count

    local vtx_buffer_old_size = self.VtxBuffer.Size
    self.VtxBuffer:resize(vtx_buffer_old_size + vtx_count)
    self._VtxWritePtr = vtx_buffer_old_size + 1

    local idx_buffer_old_size = self.IdxBuffer.Size
    self.IdxBuffer:resize(idx_buffer_old_size + idx_count)
    self._IdxWritePtr = idx_buffer_old_size + 1
end

function MT.ImDrawList:PrimUnreserve(idx_count, vtx_count)
    IM_ASSERT_PARANOID(idx_count >= 0 and vtx_count >= 0)

    local draw_cmd = self.CmdBuffer.Data[self.CmdBuffer.Size]
    draw_cmd.ElemCount = draw_cmd.ElemCount - idx_count

    self.VtxBuffer:shrink(self.VtxBuffer.Size - vtx_count)
    self.IdxBuffer:shrink(self.IdxBuffer.Size - idx_count)

    self._VtxWritePtr = self.VtxBuffer.Size + 1
    self._IdxWritePtr = self.IdxBuffer.Size + 1
end

function MT.ImDrawList:PrimRect(a, c, col)
    local b = ImVec2(c.x, a.y) local d = ImVec2(a.x, c.y)
    local uv = self._Data.TexUvWhitePixel

    local idx = self._VtxCurrentIdx

    local idx_write_ptr = self._IdxWritePtr
    self.IdxBuffer.Data[idx_write_ptr + 0] = idx
    self.IdxBuffer.Data[idx_write_ptr + 1] = idx + 1
    self.IdxBuffer.Data[idx_write_ptr + 2] = idx + 2

    self.IdxBuffer.Data[idx_write_ptr + 3] = idx
    self.IdxBuffer.Data[idx_write_ptr + 4] = idx + 2
    self.IdxBuffer.Data[idx_write_ptr + 5] = idx + 3

    local vtx_write_ptr = self._VtxWritePtr
    self.VtxBuffer.Data[vtx_write_ptr + 0] = ImDrawVert()
    self.VtxBuffer.Data[vtx_write_ptr + 0].pos = a
    self.VtxBuffer.Data[vtx_write_ptr + 0].uv = uv
    self.VtxBuffer.Data[vtx_write_ptr + 0].col = col

    self.VtxBuffer.Data[vtx_write_ptr + 1] = ImDrawVert()
    self.VtxBuffer.Data[vtx_write_ptr + 1].pos = b
    self.VtxBuffer.Data[vtx_write_ptr + 1].uv = uv
    self.VtxBuffer.Data[vtx_write_ptr + 1].col = col

    self.VtxBuffer.Data[vtx_write_ptr + 2] = ImDrawVert()
    self.VtxBuffer.Data[vtx_write_ptr + 2].pos = c
    self.VtxBuffer.Data[vtx_write_ptr + 2].uv = uv
    self.VtxBuffer.Data[vtx_write_ptr + 2].col = col

    self.VtxBuffer.Data[vtx_write_ptr + 3] = ImDrawVert()
    self.VtxBuffer.Data[vtx_write_ptr + 3].pos = d
    self.VtxBuffer.Data[vtx_write_ptr + 3].uv = uv
    self.VtxBuffer.Data[vtx_write_ptr + 3].col = col

    self._VtxWritePtr = vtx_write_ptr + 4
    self._VtxCurrentIdx = idx + 4
    self._IdxWritePtr = idx_write_ptr + 6
end

--- @param a    ImVec2
--- @param c    ImVec2
--- @param uv_a ImVec2
--- @param uv_c ImVec2
--- @param col  any
function MT.ImDrawList:PrimRectUV(a, c, uv_a, uv_c, col)
    local b = ImVec2(c.x, a.y)          local d = ImVec2(a.x, c.y)
    local uv_b = ImVec2(uv_c.x, uv_a.y) local uv_d = ImVec2(uv_a.x, uv_c.y)

    local idx = self._VtxCurrentIdx

    local idx_write_ptr = self._IdxWritePtr
    self.IdxBuffer.Data[idx_write_ptr + 0] = idx
    self.IdxBuffer.Data[idx_write_ptr + 1] = idx + 1
    self.IdxBuffer.Data[idx_write_ptr + 2] = idx + 2

    self.IdxBuffer.Data[idx_write_ptr + 3] = idx
    self.IdxBuffer.Data[idx_write_ptr + 4] = idx + 2
    self.IdxBuffer.Data[idx_write_ptr + 5] = idx + 3

    local vtx_write_ptr = self._VtxWritePtr
    self.VtxBuffer.Data[vtx_write_ptr + 0] = ImDrawVert()
    self.VtxBuffer.Data[vtx_write_ptr + 0].pos = a
    self.VtxBuffer.Data[vtx_write_ptr + 0].uv  = uv_a
    self.VtxBuffer.Data[vtx_write_ptr + 0].col = col

    self.VtxBuffer.Data[vtx_write_ptr + 1] = ImDrawVert()
    self.VtxBuffer.Data[vtx_write_ptr + 1].pos = b
    self.VtxBuffer.Data[vtx_write_ptr + 1].uv  = uv_b
    self.VtxBuffer.Data[vtx_write_ptr + 1].col = col

    self.VtxBuffer.Data[vtx_write_ptr + 2] = ImDrawVert()
    self.VtxBuffer.Data[vtx_write_ptr + 2].pos = c
    self.VtxBuffer.Data[vtx_write_ptr + 2].uv  = uv_c
    self.VtxBuffer.Data[vtx_write_ptr + 2].col = col

    self.VtxBuffer.Data[vtx_write_ptr + 3] = ImDrawVert()
    self.VtxBuffer.Data[vtx_write_ptr + 3].pos = d
    self.VtxBuffer.Data[vtx_write_ptr + 3].uv  = uv_d
    self.VtxBuffer.Data[vtx_write_ptr + 3].col = col

    self._VtxWritePtr   = vtx_write_ptr + 4
    self._VtxCurrentIdx = idx + 4
    self._IdxWritePtr   = idx_write_ptr + 6
end

--- void ImDrawList::AddPolyline(const ImVec2* points, const int points_count, ImU32 col, ImDrawFlags flags, float thickness)
-- TODO: fix this
function MT.ImDrawList:AddPolyline(points, points_count, col, flags, thickness)
    if points_count < 2 or col.a == 0 then
        return
    end

    local closed = bit.band(flags, ImDrawFlags_Closed) ~= 0
    local opaque_uv = self._Data.TexUvWhitePixel
    local count = closed and points_count or points_count - 1  -- Number of line segments
    local thick_line = thickness > self._FringeScale

    if bit.band(self.Flags, ImDrawListFlags_AntiAliasedLines) ~= 0 then
        -- Anti-aliased stroke
        local AA_SIZE = self._FringeScale
        local col_trans = {x = col.x, y = col.y, z = col.z, w = 0}

        -- Thicknesses <1.0 should behave like thickness 1.0
        thickness = ImMax(thickness, 1.0)
        local integer_thickness = ImFloor(thickness)
        local fractional_thickness = thickness - integer_thickness

        -- Do we want to draw this line using a texture?
        local use_texture = bit.band(self.Flags, ImDrawListFlags_AntiAliasedLinesUseTex) ~= 0 and integer_thickness < IM_DRAWLIST_TEX_LINES_WIDTH_MAX and fractional_thickness <= 0.00001 and AA_SIZE == 1.0

        IM_ASSERT_PARANOID((not use_texture) or bit.band(self._Data.Font.OwnerAtlas.Flags, ImFontAtlasFlags_NoBakedLines) == 0)

        local idx_count = use_texture and (count * 6) or (thick_line and count * 18 or count * 12)
        local vtx_count = use_texture and (points_count * 2) or (thick_line and points_count * 4 or points_count * 3)
        self:PrimReserve(idx_count, vtx_count)

        -- Temporary buffer
        local temp_buffer_size = points_count * ((use_texture or not thick_line) and 3 or 5)
        self._Data.TempBuffer:reserve_discard(temp_buffer_size)
        local temp_normals = self._Data.TempBuffer.Data
        local temp_points = {}  -- Will be calculated

        -- Calculate normals (tangents) for each line segment
        for i1 = 1, count do
            local i2 = (i1 == points_count) and 1 or i1 + 1
            local p1 = points[i1]
            local p2 = points[i2]
            local dx = p2.x - p1.x
            local dy = p2.y - p1.y
            dx, dy = IM_NORMALIZE2F_OVER_ZERO(dx, dy)
            temp_normals[i1] = ImVec2(dy, -dx)
        end
        if not closed then
            temp_normals[points_count] = temp_normals[points_count - 1]
        end

        -- If we are drawing a one-pixel-wide line without a texture, or a textured line of any width
        if use_texture or not thick_line then
            -- [PATH 1] Texture-based lines (thick or non-thick)
            -- [PATH 2] Non texture-based lines (non-thick)
            local half_draw_size = use_texture and (thickness * 0.5 + 1) or AA_SIZE
            temp_points = {}

            -- If line is not closed, the first and last points need to be generated differently
            if not closed then
                temp_points[1] = points[1] + temp_normals[1] * half_draw_size
                temp_points[2] = points[1] - temp_normals[1] * half_draw_size
                local last_idx = (points_count - 1) * 2
                temp_points[last_idx + 1] = points[points_count] + temp_normals[points_count] * half_draw_size
                temp_points[last_idx + 2] = points[points_count] - temp_normals[points_count] * half_draw_size
            end

            -- Generate indices and vertices
            local idx1 = self._VtxCurrentIdx
            for i1 = 1, count do
                local i2 = (i1 == points_count) and 1 or i1 + 1
                local idx2 = (i1 == points_count) and self._VtxCurrentIdx or (idx1 + (use_texture and 2 or 3))

                -- Average normals
                local n1 = temp_normals[i1]
                local n2 = temp_normals[i2]
                local dm_x = (n1.x + n2.x) * 0.5
                local dm_y = (n1.y + n2.y) * 0.5
                dm_x, dm_y = IM_FIXNORMAL2F(dm_x, dm_y)
                dm_x = dm_x * half_draw_size
                dm_y = dm_y * half_draw_size

                -- Add temporary vertices for the outer edges
                local out_idx = i2 * 2
                temp_points[out_idx - 1] = ImVec2(points[i2].x + dm_x, points[i2].y + dm_y)
                temp_points[out_idx] = ImVec2(points[i2].x - dm_x, points[i2].y - dm_y)

                if use_texture then
                    -- Add indices for two triangles
                    local idx_write_ptr = self._IdxWritePtr
                    self.IdxBuffer.Data[idx_write_ptr] = idx2
                    self.IdxBuffer.Data[idx_write_ptr + 1] = idx1
                    self.IdxBuffer.Data[idx_write_ptr + 2] = idx1 + 1
                    self.IdxBuffer.Data[idx_write_ptr + 3] = idx2 + 1
                    self.IdxBuffer.Data[idx_write_ptr + 4] = idx1 + 1
                    self.IdxBuffer.Data[idx_write_ptr + 5] = idx2
                    self._IdxWritePtr = idx_write_ptr + 6
                else
                    -- Add indices for four triangles
                    local idx_write_ptr = self._IdxWritePtr
                    self.IdxBuffer.Data[idx_write_ptr] = idx2
                    self.IdxBuffer.Data[idx_write_ptr + 1] = idx1
                    self.IdxBuffer.Data[idx_write_ptr + 2] = idx1 + 2
                    self.IdxBuffer.Data[idx_write_ptr + 3] = idx1 + 2
                    self.IdxBuffer.Data[idx_write_ptr + 4] = idx2 + 2
                    self.IdxBuffer.Data[idx_write_ptr + 5] = idx2
                    self.IdxBuffer.Data[idx_write_ptr + 6] = idx2 + 1
                    self.IdxBuffer.Data[idx_write_ptr + 7] = idx1 + 1
                    self.IdxBuffer.Data[idx_write_ptr + 8] = idx1
                    self.IdxBuffer.Data[idx_write_ptr + 9] = idx1
                    self.IdxBuffer.Data[idx_write_ptr + 10] = idx2
                    self.IdxBuffer.Data[idx_write_ptr + 11] = idx2 + 1
                    self._IdxWritePtr = idx_write_ptr + 12
                end

                idx1 = idx2
            end

            -- Add vertices
            if use_texture then
                -- Texture-based: need to implement TexUvLines lookup
                local tex_uvs = self._Data.TexUvLines[integer_thickness] or ImVec4(0, 0, 1, 1)
                local tex_uv0 = ImVec2(tex_uvs.x, tex_uvs.y)
                local tex_uv1 = ImVec2(tex_uvs.z, tex_uvs.w)
                for i = 1, points_count do
                    local vtx_write_ptr = self._VtxWritePtr
                    self.VtxBuffer.Data[vtx_write_ptr] = ImDrawVert()
                    self.VtxBuffer.Data[vtx_write_ptr].pos = temp_points[i * 2 - 1]
                    self.VtxBuffer.Data[vtx_write_ptr].uv = tex_uv0
                    self.VtxBuffer.Data[vtx_write_ptr].col = col

                    self.VtxBuffer.Data[vtx_write_ptr + 1] = ImDrawVert()
                    self.VtxBuffer.Data[vtx_write_ptr + 1].pos = temp_points[i * 2]
                    self.VtxBuffer.Data[vtx_write_ptr + 1].uv = tex_uv1
                    self.VtxBuffer.Data[vtx_write_ptr + 1].col = col

                    self._VtxWritePtr = vtx_write_ptr + 2
                end
            else
                -- Non-texture: center vertex plus two outer vertices
                for i = 1, points_count do
                    local vtx_write_ptr = self._VtxWritePtr

                    -- Center of line
                    self.VtxBuffer.Data[vtx_write_ptr] = ImDrawVert()
                    self.VtxBuffer.Data[vtx_write_ptr].pos = points[i]
                    self.VtxBuffer.Data[vtx_write_ptr].uv = opaque_uv
                    self.VtxBuffer.Data[vtx_write_ptr].col = col

                    -- Left outer edge
                    self.VtxBuffer.Data[vtx_write_ptr + 1] = ImDrawVert()
                    self.VtxBuffer.Data[vtx_write_ptr + 1].pos = temp_points[i * 2 - 1]
                    self.VtxBuffer.Data[vtx_write_ptr + 1].uv = opaque_uv
                    self.VtxBuffer.Data[vtx_write_ptr + 1].col = col_trans

                    -- Right outer edge
                    self.VtxBuffer.Data[vtx_write_ptr + 2] = ImDrawVert()
                    self.VtxBuffer.Data[vtx_write_ptr + 2].pos = temp_points[i * 2]
                    self.VtxBuffer.Data[vtx_write_ptr + 2].uv = opaque_uv
                    self.VtxBuffer.Data[vtx_write_ptr + 2].col = col_trans

                    self._VtxWritePtr = vtx_write_ptr + 3
                end
            end
        else
            -- [PATH 3] Non texture-based lines (thick)
            local half_inner_thickness = (thickness - AA_SIZE) * 0.5
            temp_points = {}

            -- If line is not closed, handle first and last points
            if not closed then
                local last_idx = (points_count - 1) * 4
                local n1 = temp_normals[1]
                local n_last = temp_normals[points_count]

                temp_points[1] = points[1] + n1 * (half_inner_thickness + AA_SIZE)
                temp_points[2] = points[1] + n1 * half_inner_thickness
                temp_points[3] = points[1] - n1 * half_inner_thickness
                temp_points[4] = points[1] - n1 * (half_inner_thickness + AA_SIZE)

                temp_points[last_idx + 1] = points[points_count] + n_last * (half_inner_thickness + AA_SIZE)
                temp_points[last_idx + 2] = points[points_count] + n_last * half_inner_thickness
                temp_points[last_idx + 3] = points[points_count] - n_last * half_inner_thickness
                temp_points[last_idx + 4] = points[points_count] - n_last * (half_inner_thickness + AA_SIZE)
            end

            -- Generate indices and vertices
            local idx1 = self._VtxCurrentIdx
            for i1 = 1, count do
                local i2 = (i1 == points_count) and 1 or i1 + 1
                local idx2 = (i1 == points_count) and self._VtxCurrentIdx or (idx1 + 4)

                -- Average normals
                local n1 = temp_normals[i1]
                local n2 = temp_normals[i2]
                local dm_x = (n1.x + n2.x) * 0.5
                local dm_y = (n1.y + n2.y) * 0.5
                dm_x, dm_y = IM_FIXNORMAL2F(dm_x, dm_y)
                local dm_out_x = dm_x * (half_inner_thickness + AA_SIZE)
                local dm_out_y = dm_y * (half_inner_thickness + AA_SIZE)
                local dm_in_x = dm_x * half_inner_thickness
                local dm_in_y = dm_y * half_inner_thickness

                -- Add temporary vertices
                local out_idx = i2 * 4 - 3
                temp_points[out_idx] = ImVec2(points[i2].x + dm_out_x, points[i2].y + dm_out_y)
                temp_points[out_idx + 1] = ImVec2(points[i2].x + dm_in_x, points[i2].y + dm_in_y)
                temp_points[out_idx + 2] = ImVec2(points[i2].x - dm_in_x, points[i2].y - dm_in_y)
                temp_points[out_idx + 3] = ImVec2(points[i2].x - dm_out_x, points[i2].y - dm_out_y)

                -- Add indices (18 per segment)
                local idx_write_ptr = self._IdxWritePtr
                local base = 1
                self.IdxBuffer.Data[idx_write_ptr] = idx2 + 1; self.IdxBuffer.Data[idx_write_ptr + 1] = idx1 + 1; self.IdxBuffer.Data[idx_write_ptr + 2] = idx1 + 2
                self.IdxBuffer.Data[idx_write_ptr + 3] = idx1 + 2; self.IdxBuffer.Data[idx_write_ptr + 4] = idx2 + 2; self.IdxBuffer.Data[idx_write_ptr + 5] = idx2 + 1
                self.IdxBuffer.Data[idx_write_ptr + 6] = idx2 + 1; self.IdxBuffer.Data[idx_write_ptr + 7] = idx1 + 1; self.IdxBuffer.Data[idx_write_ptr + 8] = idx1 + 0
                self.IdxBuffer.Data[idx_write_ptr + 9] = idx1 + 0; self.IdxBuffer.Data[idx_write_ptr + 10] = idx2 + 0; self.IdxBuffer.Data[idx_write_ptr + 11] = idx2 + 1
                self.IdxBuffer.Data[idx_write_ptr + 12] = idx2 + 2; self.IdxBuffer.Data[idx_write_ptr + 13] = idx1 + 2; self.IdxBuffer.Data[idx_write_ptr + 14] = idx1 + 3
                self.IdxBuffer.Data[idx_write_ptr + 15] = idx1 + 3; self.IdxBuffer.Data[idx_write_ptr + 16] = idx2 + 3; self.IdxBuffer.Data[idx_write_ptr + 17] = idx2 + 2
                self._IdxWritePtr = idx_write_ptr + 18

                idx1 = idx2
            end

            -- Add vertices
            for i = 1, points_count do
                local vtx_write_ptr = self._VtxWritePtr
                local base = i * 4 - 3

                self.VtxBuffer.Data[vtx_write_ptr] = ImDrawVert()
                self.VtxBuffer.Data[vtx_write_ptr].pos = temp_points[base]
                self.VtxBuffer.Data[vtx_write_ptr].uv = opaque_uv
                self.VtxBuffer.Data[vtx_write_ptr].col = col_trans

                self.VtxBuffer.Data[vtx_write_ptr + 1] = ImDrawVert()
                self.VtxBuffer.Data[vtx_write_ptr + 1].pos = temp_points[base + 1]
                self.VtxBuffer.Data[vtx_write_ptr + 1].uv = opaque_uv
                self.VtxBuffer.Data[vtx_write_ptr + 1].col = col

                self.VtxBuffer.Data[vtx_write_ptr + 2] = ImDrawVert()
                self.VtxBuffer.Data[vtx_write_ptr + 2].pos = temp_points[base + 2]
                self.VtxBuffer.Data[vtx_write_ptr + 2].uv = opaque_uv
                self.VtxBuffer.Data[vtx_write_ptr + 2].col = col

                self.VtxBuffer.Data[vtx_write_ptr + 3] = ImDrawVert()
                self.VtxBuffer.Data[vtx_write_ptr + 3].pos = temp_points[base + 3]
                self.VtxBuffer.Data[vtx_write_ptr + 3].uv = opaque_uv
                self.VtxBuffer.Data[vtx_write_ptr + 3].col = col_trans

                self._VtxWritePtr = vtx_write_ptr + 4
            end
        end
        self._VtxCurrentIdx = self._VtxCurrentIdx + vtx_count
    else
        -- [PATH 4] Non texture-based, Non anti-aliased lines
        local idx_count = count * 6
        local vtx_count = count * 4
        self:PrimReserve(idx_count, vtx_count)

        local base_idx = self._VtxCurrentIdx
        for i1 = 1, count do
            local i2 = (i1 == points_count) and 1 or i1 + 1
            local p1 = points[i1]
            local p2 = points[i2]

            local dx = p2.x - p1.x
            local dy = p2.y - p1.y
            dx, dy = IM_NORMALIZE2F_OVER_ZERO(dx, dy)
            dx = dx * (thickness * 0.5)
            dy = dy * (thickness * 0.5)

            -- Add vertices for this segment
            local vtx_write_ptr = self._VtxWritePtr
            self.VtxBuffer.Data[vtx_write_ptr] = ImDrawVert()
            self.VtxBuffer.Data[vtx_write_ptr].pos.x = p1.x + dy
            self.VtxBuffer.Data[vtx_write_ptr].pos.y = p1.y - dx
            self.VtxBuffer.Data[vtx_write_ptr].uv = opaque_uv
            self.VtxBuffer.Data[vtx_write_ptr].col = col

            self.VtxBuffer.Data[vtx_write_ptr + 1] = ImDrawVert()
            self.VtxBuffer.Data[vtx_write_ptr + 1].pos.x = p2.x + dy
            self.VtxBuffer.Data[vtx_write_ptr + 1].pos.y = p2.y - dx
            self.VtxBuffer.Data[vtx_write_ptr + 1].uv = opaque_uv
            self.VtxBuffer.Data[vtx_write_ptr + 1].col = col

            self.VtxBuffer.Data[vtx_write_ptr + 2] = ImDrawVert()
            self.VtxBuffer.Data[vtx_write_ptr + 2].pos.x = p2.x - dy
            self.VtxBuffer.Data[vtx_write_ptr + 2].pos.y = p2.y + dx
            self.VtxBuffer.Data[vtx_write_ptr + 2].uv = opaque_uv
            self.VtxBuffer.Data[vtx_write_ptr + 2].col = col

            self.VtxBuffer.Data[vtx_write_ptr + 3] = ImDrawVert()
            self.VtxBuffer.Data[vtx_write_ptr + 3].pos.x = p1.x - dy
            self.VtxBuffer.Data[vtx_write_ptr + 3].pos.y = p1.y + dx
            self.VtxBuffer.Data[vtx_write_ptr + 3].uv = opaque_uv
            self.VtxBuffer.Data[vtx_write_ptr + 3].col = col

            self._VtxWritePtr = vtx_write_ptr + 4

            -- Add indices for two triangles
            local idx_write_ptr = self._IdxWritePtr
            self.IdxBuffer.Data[idx_write_ptr] = base_idx
            self.IdxBuffer.Data[idx_write_ptr + 1] = base_idx + 1
            self.IdxBuffer.Data[idx_write_ptr + 2] = base_idx + 2
            self.IdxBuffer.Data[idx_write_ptr + 3] = base_idx
            self.IdxBuffer.Data[idx_write_ptr + 4] = base_idx + 2
            self.IdxBuffer.Data[idx_write_ptr + 5] = base_idx + 3
            self._IdxWritePtr = idx_write_ptr + 6

            base_idx = base_idx + 4
        end

        self._VtxCurrentIdx = self._VtxCurrentIdx + vtx_count
    end
end

local function FixRectCornerFlags(flags)
    IM_ASSERT(bit.band(flags, 0x0F) == 0, "Misuse of legacy hardcoded ImDrawCornerFlags values!")

    if (bit.band(flags, ImDrawFlags_RoundCornersMask) == 0) then
        flags = bit.bor(flags, ImDrawFlags_RoundCornersAll)
    end

    return flags
end

function MT.ImDrawList:PathRect(a, b, rounding, flags)
    if rounding >= 0.5 then
        flags = FixRectCornerFlags(flags)
        rounding = ImMin(rounding, ImAbs(b.x - a.x) * (((bit.band(flags, ImDrawFlags_RoundCornersTop) == ImDrawFlags_RoundCornersTop) or (bit.band(flags, ImDrawFlags_RoundCornersBottom) == ImDrawFlags_RoundCornersBottom)) and 0.5 or 1.0) - 1.0)
        rounding = ImMin(rounding, ImAbs(b.y - a.y) * (((bit.band(flags, ImDrawFlags_RoundCornersLeft) == ImDrawFlags_RoundCornersLeft) or (bit.band(flags, ImDrawFlags_RoundCornersRight) == ImDrawFlags_RoundCornersRight)) and 0.5 or 1.0) - 1.0)
    end
    if rounding < 0.5 or (bit.band(flags, ImDrawFlags_RoundCornersMask) == ImDrawFlags_RoundCornersNone) then
        self:PathLineTo(a)
        self:PathLineTo(ImVec2(b.x, a.y))
        self:PathLineTo(b)
        self:PathLineTo(ImVec2(a.x, b.y))
    else
        local rounding_tl = (bit.band(flags, ImDrawFlags_RoundCornersTopLeft) ~= 0) and rounding or 0.0
        local rounding_tr = (bit.band(flags, ImDrawFlags_RoundCornersTopRight) ~= 0) and rounding or 0.0
        local rounding_br = (bit.band(flags, ImDrawFlags_RoundCornersBottomRight) ~= 0) and rounding or 0.0
        local rounding_bl = (bit.band(flags, ImDrawFlags_RoundCornersBottomLeft) ~= 0) and rounding or 0.0
        self:PathArcToFast(ImVec2(a.x + rounding_tl, a.y + rounding_tl), rounding_tl, 6, 9)
        self:PathArcToFast(ImVec2(b.x - rounding_tr, a.y + rounding_tr), rounding_tr, 9, 12)
        self:PathArcToFast(ImVec2(b.x - rounding_br, b.y - rounding_br), rounding_br, 0, 3)
        self:PathArcToFast(ImVec2(a.x + rounding_bl, b.y - rounding_bl), rounding_bl, 3, 6)
    end
end

function MT.ImDrawList:AddRectFilled(p_min, p_max, col, rounding, flags)
    if not rounding then rounding = 0.0 end
    if not flags    then flags    = 0   end

    if col.w == 0 then return end -- TODO: pack color?

    if rounding < 0.5 or (bit.band(flags, ImDrawFlags_RoundCornersMask) == ImDrawFlags_RoundCornersNone) then
        self:PrimReserve(6, 4)
        self:PrimRect(p_min, p_max, col)
    else
        self:PathRect(p_min, p_max, rounding, flags)
        self:PathFillConvex(col)
    end
end

function MT.ImDrawList:AddRect(p_min, p_max, col, rounding, flags, thickness)
    if col.w == 0 then return end
    if bit.band(self.Flags, ImDrawListFlags_AntiAliasedLines) ~= 0 then
        self:PathRect(p_min + ImVec2(0.50, 0.50), p_max - ImVec2(0.50, 0.50), rounding, flags)
    else
        self:PathRect(p_min + ImVec2(0.50, 0.50), p_max - ImVec2(0.49, 0.49), rounding, flags)
    end

    self:PathStroke(col, ImDrawFlags_Closed, thickness)
end

function MT.ImDrawList:AddLine(p1, p2, col, thickness)
    if col.w == 0 then return end

    self:PathLineTo(p1 + ImVec2(0.5, 0.5))
    self:PathLineTo(p2 + ImVec2(0.5, 0.5))
    self:PathStroke(col, 0, thickness)
end

function MT.ImDrawList:AddTriangleFilled(p1, p2, p3, col)
    if col.w == 0 then return end

    self:PathLineTo(p1)
    self:PathLineTo(p2)
    self:PathLineTo(p3)
    self:PathFillConvex(col)
end

function MT.ImDrawList:AddText(font, font_size, pos, col, text, text_begin, text_end, wrap_width, cpu_fine_clip_rect)
    if col.w == 0 then return end

    if text_begin == text_end then
        return
    end

    if font == nil then
        font = self._Data.Font
    end
    if font_size == 0.0 then
        font_size = self._Data.FontSize
    end

    local clip_rect = self._CmdHeader.ClipRect
    if (cpu_fine_clip_rect) then
        clip_rect.x = ImMax(clip_rect.x, cpu_fine_clip_rect.x)
        clip_rect.y = ImMax(clip_rect.y, cpu_fine_clip_rect.y)
        clip_rect.z = ImMin(clip_rect.z, cpu_fine_clip_rect.z)
        clip_rect.w = ImMin(clip_rect.w, cpu_fine_clip_rect.w)
    end

    font:RenderText(self, font_size, pos, col, clip_rect, text, text_begin, text_end, wrap_width, (cpu_fine_clip_rect ~= nil) and ImDrawTextFlags.CpuFineClip or ImDrawTextFlags.None)
end

function MT.ImDrawList:RenderTextClipped(text, font, pos, color, w, h)
    surface.SetFont(font)
    local text_width, text_height = surface.GetTextSize(text)
    local need_clipping = text_width > w or text_height > h

    -- TODO: 
    -- self:AddText(text, font, pos, color)
end

function MT.ImDrawList:_CalcCircleAutoSegmentCount(radius)
    local radius_idx = ImFloor(radius + 0.999999)

    if radius_idx >= 0 and radius_idx < 64 then -- IM_ARRAYSIZE(_Data->CircleSegmentCounts)
        return self._Data.CircleSegmentCounts[radius_idx] -- Use cached value
    else
        return IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC(radius, self._Data.CircleSegmentMaxError)
    end
end

function MT.ImDrawList:PushClipRect(cr_min, cr_max, intersect_with_current_clip_rect)
    local cr = ImVec4(cr_min.x, cr_min.y, cr_max.x, cr_max.y)

    if intersect_with_current_clip_rect then
        local current = self._CmdHeader.ClipRect

        if cr.x < current.x then cr.x = current.x end
        if cr.y < current.y then cr.y = current.y end
        if cr.z > current.z then cr.z = current.z end
        if cr.w > current.w then cr.w = current.w end
    end

    cr.z = ImMax(cr.x, cr.z)
    cr.w = ImMax(cr.y, cr.w)

    self._ClipRectStack:push_back(cr)
    self._CmdHeader.ClipRect = cr
    self:_OnChangedClipRect()
end

--- void ImDrawList::_PathArcToFastEx
function MT.ImDrawList:_PathArcToFastEx(center, radius, a_min_sample, a_max_sample, a_step)
    if radius < 0.5 then
        self._Path:push_back(center)
        return
    end

    if a_step <= 0 then
        a_step = ImFloor(IM_DRAWLIST_ARCFAST_SAMPLE_MAX / self:_CalcCircleAutoSegmentCount(radius)) -- FIXME: I may forget to add ImFloor if result is int somewhere
    end

    a_step = ImClamp(a_step, 1, ImFloor(IM_DRAWLIST_ARCFAST_TABLE_SIZE / 4))

    local sample_range = ImAbs(a_max_sample - a_min_sample)
    local a_next_step = a_step

    local samples = sample_range + 1
    local extra_max_sample = false
    if a_step > 1 then
        samples = sample_range / a_step + 1
        local overstep = sample_range % a_step

        if overstep > 0 then
            extra_max_sample = true
            samples = samples + 1

            if sample_range > 0 then
                a_step = a_step - ImFloor((a_step - overstep) / 2)
            end
        end
    end

    self._Path:resize(self._Path.Size + samples)
    local out_ptr = _Path.Size - samples + 1

    local sample_index = a_min_sample
    if sample_index < 0 or sample_index >= IM_DRAWLIST_ARCFAST_SAMPLE_MAX then
        sample_index = sample_index % IM_DRAWLIST_ARCFAST_SAMPLE_MAX
        if sample_index < 0 then
            sample_index = sample_index + IM_DRAWLIST_ARCFAST_SAMPLE_MAX
        end
    end

    if a_max_sample >= a_min_sample then
        local a = a_min_sample
        while a <= a_max_sample do
            if sample_index >= IM_DRAWLIST_ARCFAST_SAMPLE_MAX then
                sample_index = sample_index - IM_DRAWLIST_ARCFAST_SAMPLE_MAX
            end

            local s = self._Data.ArcFastVtx[sample_index]
            self._Path.Data[out_ptr] = ImVec2(center.x + s.x * radius, center.y + s.y * radius)
            out_ptr = out_ptr + 1

            a = a + a_step
            sample_index = sample_index + a_step
            a_step = a_next_step
        end
    else
        local a = a_min_sample
        while a >= a_max_sample do
            if sample_index < 0 then
                sample_index = sample_index + IM_DRAWLIST_ARCFAST_SAMPLE_MAX
            end

            local s = self._Data.ArcFastVtx[sample_index]
            self._Path.Data[out_ptr] = ImVec2(center.x + s.x * radius, center.y + s.y * radius)
            out_ptr = out_ptr + 1

            a = a - a_step
            sample_index = sample_index - a_step
            a_step = a_next_step
        end
    end

    if extra_max_sample then
        local normalized_max_sample = a_max_sample % IM_DRAWLIST_ARCFAST_SAMPLE_MAX
        if normalized_max_sample < 0 then
            normalized_max_sample = normalized_max_sample + IM_DRAWLIST_ARCFAST_SAMPLE_MAX
        end

        local s = self._Data.ArcFastVtx[sample_index]
        self._Path.Data[out_ptr] = ImVec2(center.x + s.x * radius, center.y + s.y * radius)
        out_ptr = out_ptr + 1
    end

    --- IM_ASSERT_PARANOID(_Path.Data + _Path.Size == out_ptr);
end

function MT.ImDrawList:PathArcToFast(center, radius, a_min_of_12, a_max_of_12)
    if radius < 0.5 then
        self._Path:push_back(center)
        return
    end

    self:_PathArcToFastEx(center, radius, a_min_of_12 * IM_DRAWLIST_ARCFAST_SAMPLE_MAX / 12, a_max_of_12 * IM_DRAWLIST_ARCFAST_SAMPLE_MAX / 12, 0)
end

function MT.ImDrawList:_PathArcToN(center, radius, a_min, a_max, num_segments)
    if radius < 0.5 then
        self._Path:push_back(center)
        return
    end

    for i = 0, num_segments do
        local a = a_min + (i / num_segments) * (a_max - a_min)
        self._Path:push_back(ImVec2(center.x + ImCos(a) * radius, center.y + ImSin(a) * radius))
    end
end

function MT.ImDrawList:PathArcTo(center, radius, a_min, a_max, num_segments)
    if radius < 0.5 then
        self._Path:push_back(center)
        return
    end

    if num_segments > 0 then
        self:_PathArcToN(center, radius, a_min, a_max, num_segments)
        return
    end

    if radius <= self._Data.ArcFastRadiusCutoff then
        local a_is_reverse = a_max < a_min

        local a_min_sample_f = IM_DRAWLIST_ARCFAST_SAMPLE_MAX * a_min / (IM_PI * 2.0)
        local a_max_sample_f = IM_DRAWLIST_ARCFAST_SAMPLE_MAX * a_max / (IM_PI * 2.0)

        local a_min_sample = a_is_reverse and ImFloor(a_min_sample_f) or ImCeil(a_min_sample_f)
        local a_max_sample = a_is_reverse and ImCeil(a_max_sample_f) or ImFloor(a_max_sample_f)
        local a_mid_samples = a_is_reverse and ImMax(a_min_sample - a_max_sample, 0) or ImMax(a_max_sample - a_min_sample, 0)

        local a_min_segment_angle = a_min_sample * IM_PI * 2.0 / IM_DRAWLIST_ARCFAST_SAMPLE_MAX
        local a_max_segment_angle = a_max_sample * IM_PI * 2.0 / IM_DRAWLIST_ARCFAST_SAMPLE_MAX
        local a_emit_start = ImAbs(a_min_segment_angle - a_min) >= 1e-5
        local a_emit_end = ImAbs(a_max - a_max_segment_angle) >= 1e-5

        if a_emit_start then
            self._Path:push_back(ImVec2(center.x + ImCos(a_min) * radius, center.y + ImSin(a_min) * radius))
        end

        if a_mid_samples > 0 then
            self:_PathArcToFastEx(center, radius, a_min_sample, a_max_sample, 0)
        end

        if a_emit_end then
            self._Path:push_back(ImVec2(center.x + ImCos(a_max) * radius, center.y + ImSin(a_max) * radius))
        end
    else
        local arc_length = ImAbs(a_max - a_min)
        local circle_segment_count = self:_CalcCircleAutoSegmentCount(radius)
        local arc_segment_count = ImMax(
            ImCeil(circle_segment_count * arc_length / (IM_PI * 2.0)),
            2.0 * IM_PI / arc_length
        )

        self:_PathArcToN(center, radius, a_min, a_max, arc_segment_count)
    end
end

--- @param draw_list  ImDrawList
--- @param size       float
--- @param pos        ImVec2
--- @param col        ImVec4
--- @param clip_rect  ImVec4
--- @param text       string
--- @param text_begin int
--- @param text_end   int?
--- @param wrap_width float
--- @param flags      ImDrawTextFlags
function MT.ImFont:RenderText(draw_list, size, pos, col, clip_rect, text, text_begin, text_end, wrap_width, flags)
    local x = IM_TRUNC(pos.x)
    local y = IM_TRUNC(pos.y)
    if y > clip_rect.w then
        return
    end

    --- @type int
    text_end = (text_end ~= nil) and text_end or (#text + 1)

    local line_height = size
    local baked = self:GetFontBaked(size)

    local scale = size / baked.Size
    local origin_x = x
    local word_wrap_enabled = (wrap_width > 0.0)

    local s = text_begin
    if y + line_height < clip_rect.y then
        while y + line_height < clip_rect.y and s < text_end do
            local line_end = ImMemchr(text, '\n', s)
            if word_wrap_enabled then
                s = ImFontCalcWordWrapPositionEx(self, size, text, s, (line_end ~= nil) and line_end or text_end, wrap_width, flags)
                s = ImTextCalcWordWrapNextLineStart(text, s, text_end, flags)
            else
                s = (line_end ~= nil) and (line_end + 1) or text_end
            end

            y = y + line_height
        end
    end

    if text_end - s > 1e4 and not word_wrap_enabled then
        local s_end = s
        local y_end = y
        while (y_end < clip_rect.w and s_end < text_end) do
            local _end = ImMemchr(text, '\n', s_end)
            s_end = (_end ~= nil) and (_end + 1) or text_end
            y_end = y_end + line_height
        end

        text_end = s_end
    end

    if s == text_end then
        return
    end

    local vtx_count_max = (text_end - s) * 4
    local idx_count_max = (text_end - s) * 6
    local idx_expected_size = draw_list.IdxBuffer.Size + idx_count_max
    draw_list:PrimReserve(idx_count_max, vtx_count_max)
    local vtx_write = draw_list._VtxWritePtr
    local idx_write = draw_list._IdxWritePtr
    local vtx_index = draw_list._VtxCurrentIdx
    local cmd_count = draw_list.CmdBuffer.Size
    local cpu_fine_clip = bit.band(flags, ImDrawTextFlags.CpuFineClip) ~= 0

    local color_untinted = col:copy()
    color_untinted.w = 1.0 -- TODO: packed colors

    local word_wrap_eol

    while s < text_end do
        if word_wrap_enabled then
            if not word_wrap_eol then
                word_wrap_eol = ImFontCalcWordWrapPositionEx(self, size, text, s, text_end, wrap_width - (x - origin_x), flags)
            end

            if s >= word_wrap_eol then
                x = origin_x
                y = y + line_height
                if y > clip_rect.w then
                    break
                end
                word_wrap_eol = nil
                s = ImTextCalcWordWrapNextLineStart(text, s, text_end, flags)

                continue
            end
        end

        local c = string.byte(text, s)
        if c < 0x80 then
            s = s + 1
        else
            local wanted, out_char = ImTextCharFromUtf8(text, s, text_end)
            c = out_char
            s = s + wanted
        end

        if c < 32 then
            if c == chr'\n' then
                x = origin_x
                y = y + line_height
                if y > clip_rect.w then
                    break
                end

                continue
            end

            if c == chr'\r' then
                continue
            end
        end

        local glyph = baked:FindGlyph(c)

        local char_width = glyph.AdvanceX * scale
        if glyph.Visible then
            local x1 = x + glyph.X0 * scale
            local x2 = x + glyph.X1 * scale
            local y1 = y + glyph.Y0 * scale
            local y2 = y + glyph.Y1 * scale
            if x1 <= clip_rect.z and x2 >= clip_rect.x then
                local u1 = glyph.U0
                local v1 = glyph.V0
                local u2 = glyph.U1
                local v2 = glyph.V1

                if (cpu_fine_clip) then
                    if (x1 < clip_rect.x) then
                        u1 = u1 + (1.0 - (x2 - clip_rect.x) / (x2 - x1)) * (u2 - u1)
                        x1 = clip_rect.x
                    end
                    if (y1 < clip_rect.y) then
                        v1 = v1 + (1.0 - (y2 - clip_rect.y) / (y2 - y1)) * (v2 - v1)
                        y1 = clip_rect.y
                    end
                    if (x2 > clip_rect.z) then
                        u2 = u1 + ((clip_rect.z - x1) / (x2 - x1)) * (u2 - u1)
                        x2 = clip_rect.z
                    end
                    if (y2 > clip_rect.w) then
                        v2 = v1 + ((clip_rect.w - y1) / (y2 - y1)) * (v2 - v1)
                        y2 = clip_rect.w
                    end
                    if (y1 >= y2) then
                        x = x + char_width

                        continue
                    end
                end

                local glyph_col = glyph.Colored and color_untinted or col

                do
                    draw_list.VtxBuffer.Data[vtx_write + 0] = ImDrawVert(); draw_list.VtxBuffer.Data[vtx_write + 0].pos.x = x1; draw_list.VtxBuffer.Data[vtx_write + 0].pos.y = y1; draw_list.VtxBuffer.Data[vtx_write + 0].col = glyph_col; draw_list.VtxBuffer.Data[vtx_write + 0].uv.x = u1; draw_list.VtxBuffer.Data[vtx_write + 0].uv.y = v1;
                    draw_list.VtxBuffer.Data[vtx_write + 1] = ImDrawVert(); draw_list.VtxBuffer.Data[vtx_write + 1].pos.x = x2; draw_list.VtxBuffer.Data[vtx_write + 1].pos.y = y1; draw_list.VtxBuffer.Data[vtx_write + 1].col = glyph_col; draw_list.VtxBuffer.Data[vtx_write + 1].uv.x = u2; draw_list.VtxBuffer.Data[vtx_write + 1].uv.y = v1;
                    draw_list.VtxBuffer.Data[vtx_write + 2] = ImDrawVert(); draw_list.VtxBuffer.Data[vtx_write + 2].pos.x = x2; draw_list.VtxBuffer.Data[vtx_write + 2].pos.y = y2; draw_list.VtxBuffer.Data[vtx_write + 2].col = glyph_col; draw_list.VtxBuffer.Data[vtx_write + 2].uv.x = u2; draw_list.VtxBuffer.Data[vtx_write + 2].uv.y = v2;
                    draw_list.VtxBuffer.Data[vtx_write + 3] = ImDrawVert(); draw_list.VtxBuffer.Data[vtx_write + 3].pos.x = x1; draw_list.VtxBuffer.Data[vtx_write + 3].pos.y = y2; draw_list.VtxBuffer.Data[vtx_write + 3].col = glyph_col; draw_list.VtxBuffer.Data[vtx_write + 3].uv.x = u1; draw_list.VtxBuffer.Data[vtx_write + 3].uv.y = v2;
                    draw_list.IdxBuffer.Data[idx_write + 0] = vtx_index; draw_list.IdxBuffer.Data[idx_write + 1] = vtx_index + 1; draw_list.IdxBuffer.Data[idx_write + 2] = vtx_index + 2;
                    draw_list.IdxBuffer.Data[idx_write + 3] = vtx_index; draw_list.IdxBuffer.Data[idx_write + 4] = vtx_index + 2; draw_list.IdxBuffer.Data[idx_write + 5] = vtx_index + 3;
                    vtx_write = vtx_write + 4
                    vtx_index = vtx_index + 4
                    idx_write = idx_write + 6
                end
            end
        end

        x = x + char_width
    end

    draw_list.VtxBuffer.Size = vtx_write - 1
    draw_list.IdxBuffer.Size = idx_write - 1
    draw_list.CmdBuffer.Data[draw_list.CmdBuffer.Size].ElemCount = draw_list.CmdBuffer.Data[draw_list.CmdBuffer.Size].ElemCount - (idx_expected_size - draw_list.IdxBuffer.Size)
    draw_list._VtxWritePtr = vtx_write
    draw_list._IdxWritePtr = idx_write
    draw_list._VtxCurrentIdx = vtx_index
end

--- @param draw_list ImDrawList
--- @param pos ImVec2
--- @param color ImU32
--- @param dir ImGuiDir
--- @param scale float
function ImGui.RenderArrow(draw_list, pos, color, dir, scale)
    local h = GImGui.FontSize -- TODO: draw_list->_Data->FontSize * 1.00f?
    local r = h * 0.40 * scale

    center = pos + ImVec2(h * 0.50, h * 0.50 * scale)

    local a, b, c

    if dir == ImGuiDir.Up or dir == ImGuiDir.Down then
        if dir == ImGuiDir.Up then r = -r end
        a = ImVec2( 0.000,  0.750) * r
        b = ImVec2(-0.866, -0.750) * r
        c = ImVec2( 0.866, -0.750) * r
    elseif dir == ImGuiDir.Left or dir == ImGuiDir.Right then
        if dir == ImGuiDir.Left then r = -r end
        a = ImVec2( 0.750,  0.000) * r
        b = ImVec2(-0.750,  0.866) * r
        c = ImVec2(-0.750, -0.866) * r
    end

    draw_list:AddTriangleFilled(center + a, center + b, center + c, color)
end