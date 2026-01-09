--- If lower, the window title cross or arrow will look awful
-- TODO: let client decide?
RunConsoleCommand("mat_antialias", "8")

stbrp = include("imstb_rectpack.lua")

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
local ImFontAtlasUpdateDrawListsSharedData

local function ImFontAtlasTextureBlockCopy(src_tex, src_x, src_y, dst_tex, dst_x, dst_y, w, h)
    IM_ASSERT(src_tex.Pixels ~= nil and dst_tex.Pixels ~= nil)
    IM_ASSERT(src_tex.Format == dst_tex.Format)
    IM_ASSERT(src_x >= 0 and src_x + w <= src_tex.Width)
    IM_ASSERT(src_y >= 0 and src_y + h <= src_tex.Height)
    IM_ASSERT(dst_x >= 0 and dst_x + w <= dst_tex.Width)
    IM_ASSERT(dst_y >= 0 and dst_y + h <= dst_tex.Height)
    for y = 0, h - 1 do
        --memcpy(dst_tex->GetPixelsAt(dst_x, dst_y + y), src_tex->GetPixelsAt(src_x, src_y + y), w * dst_tex->BytesPerPixel);
        for i = 0, w - 1 do
            memcpy(dst_tex:GetPixelsAt(dst_x, dst_y + y), src_tex:GetPixelsAt(src_x, src_y + y), w)
        end
    end
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
        if (baked.WantDestroy or (bit.band(baked.OwnerFont.Flags, ImFontFlags_LockBakedSizes) ~= 0)) then
            continue
        end
        ImFontAtlasBakedDiscard(atlas, baked.OwnerFont, baked)
    end
end

local function ImFontAtlasTextureRepack(atlas, w, h)
    local builder = atlas.Builder
    atlas.LockDisableResize = true

    local old_tex = atlas.TexData
    local new_tex = ImFontAtlasTextureAdd(atlas, w, h)
    new_tex.UseColors = old_tex.UseColors
    -- IMGUI_DEBUG_LOG_FONT("[font] Texture #%03d: resize+repack %dx%d => Texture #%03d: %dx%d\n", old_tex->UniqueID, old_tex->Width, old_tex->Height, new_tex->UniqueID, new_tex->Width, new_tex->Height);

    ImFontAtlasPackInit(atlas)
    local old_rects = ImVector()
    local old_index = builder.RectsIndex
    old_rects:swap(builder.Rects)

    for _, index_entry in builder.RectsIndex:iter() do
        if index_entry.IsUsed == false then
            continue
        end
        local old_r = old_rects:at(index_entry.TargetIndex)
        if (old_r.w == 0 and old_r.h == 0) then
            continue
        end
        local new_r_id = ImFontAtlasPackAddRect(atlas, old_r.w, old_r.h, index_entry)
        if new_r_id == ImFontAtlasRectId_Invalid then
            -- IMGUI_DEBUG_LOG_FONT("[font] Texture #%03d: resize failed. Will grow.\n", new_tex->UniqueID);
            new_tex.WantDestroyNextFrame = true
            builder.Rects:swap(old_rects)
            builder.RectsIndex = old_index
            ImFontAtlasBuildSetTexture(atlas, old_tex)
            ImFontAtlasTextureGrow(atlas, w, h)

            return
        end
        -- IM_ASSERT(ImFontAtlasRectId_GetIndex(new_r_id) == builder->RectsIndex.index_from_ptr(&index_entry))
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
    //ImFontAtlasDebugWriteTexToDisk(new_tex, "After Pack");
end

function ImFontAtlasTextureGrow(atlas, old_tex_w, old_tex_h)
    local builder = atlas.Builder
    if (old_tex_w == -1) then
        old_tex_w = atlas.TexData.Width
    end
    if (old_tex_h == -1) then
        old_tex_h = atlas.TexData.Height
    end

    IM_ASSERT(ImIsPowerOfTwo(old_tex_w) && ImIsPowerOfTwo(old_tex_h))
    IM_ASSERT(ImIsPowerOfTwo(atlas.TexMinWidth) and ImIsPowerOfTwo(atlas.TexMaxWidth) and ImIsPowerOfTwo(atlas.TexMinHeight) and ImIsPowerOfTwo(atlas.TexMaxHeight))

    local new_tex_w = (old_tex_h <= old_tex_w) and old_tex_w or old_tex_w * 2
    local new_tex_h = (old_tex_h <= old_tex_w) and old_tex_h * 2 or old_tex_h

    local int pack_padding = atlas.TexGlyphPadding
    new_tex_w = ImMax(new_tex_w, ImUpperPowerOfTwo(builder.MaxRectSize.x + pack_padding))
    new_tex_h = ImMax(new_tex_h, ImUpperPowerOfTwo(builder.MaxRectSize.y + pack_padding))
    new_tex_w = ImClamp(new_tex_w, atlas.TexMinWidth, atlas.TexMaxWidth)
    new_tex_h = ImClamp(new_tex_h, atlas.TexMinHeight, atlas.TexMaxHeight)
    if (new_tex_w == old_tex_w and new_tex_h == old_tex_h) then
        return
    end

    ImFontAtlasTextureRepack(atlas, new_tex_w, new_tex_h)
end

local function ImFontAtlasTextureMakeSpace(atlas)
    local builder = atlas.Builder
    ImFontAtlasBuildDiscardBakes(atlas, 2)

    if (builder.RectsDiscardedSurface < builder.RectsPackedSurface * 0.20) then
        ImFontAtlasTextureGrow(atlas)
    else
        ImFontAtlasTextureRepack(atlas, atlas.TexData.Width, atlas.TexData.Height)
    end
end

local function ImFontAtlasPackReuseRectEntry(atlas, index_entry)
    IM_ASSERT(index_entry.IsUsed)
    index_entry.TargetIndex = atlas.Builder.Rects.Size
    local index_idx = atlas.Builder.RectsIndex.index_from_ptr(index_entry)
    return ImFontAtlasRectId_Make(index_idx, index_entry.Generation)
end

local function ImFontAtlasPackAllocRectEntry(atlas, rect_idx)
    local builder = atlas.Builder
    local index_idx, index_entry
    if builder.RectsIndexFreeListStart <= 0 then
        builder.RectsIndex:resize(builder.RectsIndex.Size + 1)
        index_idx = builder.RectsIndex.Size
        index_entry = ImFontAtlasRectEntry()
        builder.RectsIndex:push_back(index_entry)
    else
        index_idx = builder.RectsIndexFreeListStart
        index_entry = builder.RectsIndex:at(index_idx)
        IM_ASSERT(index_entry.IsUsed == false and index_entry.Generation > 0)
        builder.RectsIndexFreeListStart = index_entry.TargetIndex
    end

    index_entry.TargetIndex = rect_idx
    index_entry.IsUsed = true

    return ImFontAtlasRectId_Make(index_idx, index_entry.Generation)
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
        if pack_r.was_packed then
            break
        end

        if (attempts_remaining == 0 or builder.LockDisableResize) then
            -- IMGUI_DEBUG_LOG_FONT("[font] Failed packing %dx%d rectangle. Returning fallback.\n", w, h)
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
        return ImFontAtlasPackAllocRectEntry(atlas, builder.Rects.Size)
    end
end

function ImFontAtlasPackGetRect(atlas, id)
    IM_ASSERT(id ~= ImFontAtlasRectId_Invalid)
    local index_idx = ImFontAtlasRectId_GetIndex(id) + 1 -- XXX: 1 based indexing
    local builder = atlas.Builder
    local index_entry = builder.RectsIndex:at(index_idx)
    IM_ASSERT(index_entry.Generation == ImFontAtlasRectId_GetGeneration(id))
    IM_ASSERT(index_entry.IsUsed)
    return builder.Rects:at(index_entry.TargetIndex)
end

function ImFontAtlasPackGetRectSafe(atlas, id)
    if id == ImFontAtlasRectId_Invalid then
        return nil
    end

    local index_idx = ImFontAtlasRectId_GetIndex(id) + 1 -- XXX: 1 based indexing
    if atlas.Builder == nil then
        ImFontAtlasBuildInit(atlas)
    end
    local builder = atlas.Builder
    if index_idx > builder.RectsIndex.Size then
        return nil
    end
    local index_entry = builder.RectsIndex:at(index_idx)
    if (index_entry.Generation ~= ImFontAtlasRectId_GetGeneration(id) or not index_entry.IsUsed) then
        return nil
    end
    return builder.Rects:at(index_entry.TargetIndex)
end

local function ImGui_ImplStbTrueType_FontSrcData()
    return {
        FontInfo    = stbtt.fontinfo(),
        ScaleFactor = nil
    }
end

local function ImGui_ImplStbTrueType_FontSrcInit(atlas, src)
    -- IM_UNUSED(atlas)
    local bd_font_data = ImGui_ImplStbTrueType_FontSrcData()
    IM_ASSERT(src.FontLoaderData == nil)

    local font_offset = stbtt.GetFontOffsetForIndex(src.FontData, src.FontNo)
    if font_offset < 0 then
        IM_DELETE(bd_font_data)
        IM_ASSERT_USER_ERROR(0, "stbtt_GetFontOffsetForIndex(): FontData is incorrect, or FontNo cannot be found.")
        return false
    end
    if (not stbtt.InitFont(bd_font_data.FontInfo, src.FontData, font_offset)) then
        IM_DELETE(bd_font_data)
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
    IM_DELETE(src.FontLoaderData)
end

local function ImGui_ImplStbTrueType_FontSrcContainsGlyph(src, codepoint)
    -- IM_UNUSED(atlas)
    local bd_font_data = src.FontLoaderData
    IM_ASSERT(bd_font_data ~= NULL)

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

local function ImGui_ImplStbTrueType_FontBakedLoadGlyph(atlas, src, baked, codepoint, out_glyph, out_advance_x) -- FIXME: out_advance_x is a size = 1 table
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
        -- TODO:
    end
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

function ImFontAtlasBakedDiscard(atlas, font, baked)
    local builder = atlas.Builder

    for _, glyph in baked.Glyphs:iter() do
        if glyph.PackID ~= ImFontAtlasRectId_Invalid then
            ImFontAtlasPackDiscardRect(atlas, glyph.PackID)
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
    builder:ClearOutputData()
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

local function ImFontAtlasFontDestroyOutput(atlas, font)
    font:ClearOutputData()
    for _, src in font.Sources:iter() do
        local loader = src.FontLoader and src.FontLoader or atlas.FontLoader
        if loader and loader.FontSrcDestroy ~= nil then
            loader.FontSrcDestroy(atlas, src)
        end
    end
end

local function ImFontAtlasBuildSetupFontLoader(atlas, font_loader)
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
    return
end

local function ImFontAtlasBuildUpdatePointers(atlas)
    return
end

local function ImFontAtlasUpdateDrawListsTextures(atlas, old_tex, new_tex)
    for _, shared_data in atlas.DrawListSharedDatas:iter() do
        if (shared_data.Context and not shared_data.Context.WithinFrameScope) then
            continue
        end

        for _, draw_list in shared_data.DrawLists:iter() do
            if (draw_list.CmdBuffer.Size > 0 and draw_list._CmdHeader.TexRef == old_tex) then
                draw_list._SetTexture(new_tex)
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
    -- atlas->TexRef._TexID = tex->TexID; // <-- We intentionally don't do that. It would be misleading and betray promise that both fields aren't set.
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
        IM_ASSERT(old_tex.Status == ImTextureStatus_OK or old_tex.Status == ImTextureStatus_WantCreate or old_tex.Status == ImTextureStatus_WantUpdates)
    end

    new_tex:Create(atlas.TexDesiredFormat, w, h)
    atlas.TexIsBuilt = false

    ImFontAtlasBuildSetTexture(atlas, new_tex)

    return new_tex
end

local function ImFontAtlasBuildClear(atlas)
    return
end

function ImFontAtlasPackInit(atlas)
    local tex = atlas.TexData
    local builder = atlas.Builder

    local pack_node_count = ImFloor(tex.Width / 2)
    builder.PackNodes:resize(pack_node_count)

    stbrp.init_target(builder.PackContext, tex.Width, tex.Height, builder.PackNodes.Data, builder.PackNodes.Size)
    builder.RectsPackedCount = 0
    builder.RectsPackedSurface = 0
    builder.MaxRectSize = ImVec2(0, 0)
    builder.MaxRectBounds = ImVec2(0, 0)
end

function ImFontAtlasBuildUpdateLinesTexData(atlas)
    if bit.band(atlas.Flags, ImFontAtlasFlags_NoBakedLines) ~= 0 then
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
    -- TODO:
end

function ImFontAtlasBuildUpdateBasicTexData(atlas)
    -- TODO:
end

function ImFontAtlasUpdateDrawListsSharedData(atlas)
    for _, shared_data in atlas.DrawListSharedDatas:iter() do
        if (shared_data.FontAtlas == atlas) then
            shared_data.TexUvWhitePixel = atlas.TexUvWhitePixel
            shared_data.TexUvLines = atlas.TexUvLines
        end
    end
end

local function ImTextInitClassifiers()

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

local function ImFontAtlasBuildMain(atlas)
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

    atlas.TexIsBuilt = true
end

struct_method ImTextureData:DestroyPixels()
    self.Pixels = nil
    self.UseColors = false
end

local function ImTextureDataGetFormatBytesPerPixel(format)
    if format == ImTextureFormat_Alpha8 then
        return 1
    elseif format == ImTextureFormat_RGBA32 then
        return 4
    end
    IM_ASSERT(false)
    return 0
end

struct_method ImTextureData:Create(format, w, h)
    IM_ASSERT(self.Status == ImTextureStatus_Destroyed)
    self:DestroyPixels()
    self.Format = format
    self.Status = ImTextureStatus_WantCreate
    self.Width = w
    self.Height = h
    self.BytesPerPixel = ImTextureDataGetFormatBytesPerPixel(format)
    self.UseColors = false
    self.Pixels = {data = {}, offset = 0} -- TODO: investigate
    -- memset(Pixels, 0, Width * Height * BytesPerPixel)
    self.UsedRect.x = 0
    self.UsedRect.y = 0
    self.UsedRect.w = 0
    self.UsedRect.h = 0
    self.UpdateRect.x = -1
    self.UpdateRect.y = -1
    self.UpdateRect.w = 0
    self.UpdateRect.h = 0
end

struct_method ImFontBaked:ClearOutputData()
    self.FallbackAdvanceX = 0.0
    self.Glyphs:clear()
    self.IndexAdvanceX:clear()
    self.IndexLookup:clear()
    self.FallbackGlyphIndex = -1
    self.Ascent = 0.0
    self.Descent = 0.0
    self.MetricsTotalSurface = 0
end

struct_method ImFont:ClearOutputData()
    local atlas = self.OwnerAtlas
    if atlas ~= nil then
        ImFontAtlasFontDiscardBakes(atlas, self, 0)
    end

    self.LastBaked = nil
end

struct_method ImFontAtlas:SetFontLoader(font_loader)
    ImFontAtlasBuildSetupFontLoader(self, font_loader)
end

struct_method ImFontAtlas:AddFont(font_cfg_in)
    IM_ASSERT(not self.Locked, "Cannot modify a locked ImFontAtlas!")
    IM_ASSERT((font_cfg_in.FontData ~= nil and font_cfg_in.FontDataSize > 0) or (font_cfg_in.FontLoader ~= nil))
    --IM_ASSERT(font_cfg_in.SizePixels > 0.0, "Is ImFontConfig struct correctly initialized?")
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
        local size = #font_cfg.GlyphExcludeRanges
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

struct_method ImFontAtlas:AddFontDefault(font_cfg)
    if self.OwnerContext == nil or GetExpectedContextFontSize(self.OwnerContext) >= 16.0 then
        return self:AddFontDefaultVector(font_cfg)
    else
        return self:AddFontDefaultBitmap(font_cfg)
    end
end

struct_method ImFontAtlas:AddFontFromMemoryTTF(font_data, font_data_size, size_pixels, font_cfg_template, glyph_ranges)
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

struct_method ImFontAtlas:AddFontFromFileTTF(filename, size_pixels, font_cfg_template, glyph_ranges)
    IM_ASSERT(not self.Locked, "Cannot modify a locked ImFontAtlas!")

    local data, data_size = ImFileLoadToMemory(filename, "rb")
    if not data then
        if (font_cfg_template == nil or (bit.band(font_cfg_template.Flags, ImFontFlags_NoLoadError) == 0)) then
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

struct_method ImFontAtlas:AddFontDefaultBitmap(font_cfg_template)
    -- TODO: 
end

struct_method ImFontAtlas:AddFontDefaultVector(font_cfg_template)
    -- TODO: 
end

struct_method ImFontAtlas:GetCustomRect(id, out_r)
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

struct_method ImFontAtlas:AddCustomRect(width, height, out_r)
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

struct_method ImDrawData:Clear()
    self.Valid = false
    self.CmdListsCount = 0
    self.TotalIdxCount = 0
    self.TotalVtxCount = 0
    self.CmdLists:clear_delete()
    self.DisplayPos = ImVec2()
    self.DisplaySize = ImVec2()
end

function ImGui.AddDrawListToDrawDataEx(draw_data, out_list, draw_list)
    if draw_list.CmdBuffer.Size == 0 then return end
    if draw_list.CmdBuffer.Size == 1 and draw_list.CmdBuffer.Data[1].ElemCount == 0 then return end

    IM_ASSERT(draw_list.VtxBuffer.Size == 0 or draw_list._VtxWritePtr == draw_list.VtxBuffer.Size + 1)
    IM_ASSERT(draw_list.IdxBuffer.Size == 0 or draw_list._IdxWritePtr == draw_list.IdxBuffer.Size + 1)

    -- indexable check

    out_list:push_back(draw_list)
    draw_data.CmdListsCount = draw_data.CmdListsCount + 1
    draw_data.TotalVtxCount = draw_data.TotalVtxCount + draw_list.VtxBuffer.Size
    draw_data.TotalIdxCount = draw_data.TotalIdxCount + draw_list.IdxBuffer.Size
end

struct_method ImDrawData:AddDrawList(draw_list)
    IM_ASSERT(self.CmdLists.Size == self.CmdListsCount)
    draw_list:_PopUnusedDrawCmd()
    ImGui.AddDrawListToDrawDataEx(self, self.CmdLists, draw_list)
end

struct_method ImDrawListSharedData:SetCircleTessellationMaxError(max_error)
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
struct_method ImDrawList:_SetDrawListSharedData(data)
    if self._Data ~= nil then
        self._Data.DrawLists:find_erase_unsorted(self)
    end
    self._Data = data
    if self._Data ~= nil then
        self._Data.DrawLists:push_back(self)
    end
end

struct_method ImDrawList:_ResetForNewFrame()
    self.CmdBuffer:resize(0)
    self.IdxBuffer:resize(0)
    self.VtxBuffer:resize(0)
    self._VtxCurrentIdx = 1
    self._VtxWritePtr = 1
    self._IdxWritePtr = 1
    self._ClipRectStack:resize(0)
    self._TextureStack:resize(0)
    self._Path:resize(0)
    self.CmdBuffer:push_back(ImDrawCmd())
    self._FringeScale = self._Data.InitialFringeScale
end

struct_method ImDrawList:AddDrawCmd()
    local draw_cmd = ImDrawCmd()
    draw_cmd.ClipRect = self._CmdHeader.ClipRect
    draw_cmd.VtxOffset = self._CmdHeader.VtxOffset
    draw_cmd.IdxOffset = self.IdxBuffer.Size

    --- IM_ASSERT(draw_cmd.ClipRect.x <= draw_cmd.ClipRect.z && draw_cmd.ClipRect.y <= draw_cmd.ClipRect.w);
    self.CmdBuffer:push_back(draw_cmd)
end

struct_method ImDrawList:_PopUnusedDrawCmd()
    while self.CmdBuffer.Size > 0 do
        local curr_cmd = self.CmdBuffer.Data[self.CmdBuffer.Size]
        if curr_cmd.ElemCount ~= 0 then
            break
        end

        self.CmdBuffer:pop_back()
    end
end

struct_method ImDrawList:_OnChangedVtxOffset()
    self._VtxCurrentIdx = 1
    -- IM_ASSERT_PARANOID(CmdBuffer.Size > 0);

    local curr_cmd = self.CmdBuffer.Data[self.CmdBuffer.Size]
    if curr_cmd.ElemCount ~= 0 then
        self:AddDrawCmd()
        return
    end
    -- IM_ASSERT(curr_cmd->UserCallback == NULL)
    curr_cmd.VtxOffset = self._CmdHeader.VtxOffset
end

struct_method ImDrawList:AddConvexPolyFilled(points, points_count, col)
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

--- TODO: LIMIT: 65536 for imesh, 4096 for drawpoly
struct_method ImDrawList:PrimReserve(idx_count, vtx_count)
    -- IM_ASSERT_PARANOID(idx_count >= 0 && vtx_count >= 0)
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

struct_method ImDrawList:PrimUnreserve(idx_count, vtx_count)
    -- IM_ASSERT_PARANOID(idx_count >= 0 && vtx_count >= 0);

    local draw_cmd = self.CmdBuffer.Data[self.CmdBuffer.Size]
    draw_cmd.ElemCount = draw_cmd.ElemCount - idx_count
    self.VtxBuffer:shrink(self.VtxBuffer.Size - vtx_count)
    self.IdxBuffer:shrink(self.IdxBuffer.Size - idx_count)
end

struct_method ImDrawList:PrimRect(a, c, col)
    local b = ImVec2(c.x, a.y)
    local d = ImVec2(a.x, c.y)

    -- TODO: uv
    local idx = self._VtxCurrentIdx

    local idx_write_ptr = self._IdxWritePtr
    self.IdxBuffer.Data[idx_write_ptr] = idx
    self.IdxBuffer.Data[idx_write_ptr + 1] = idx + 1
    self.IdxBuffer.Data[idx_write_ptr + 2] = idx + 2

    self.IdxBuffer.Data[idx_write_ptr + 3] = idx
    self.IdxBuffer.Data[idx_write_ptr + 4] = idx + 2
    self.IdxBuffer.Data[idx_write_ptr + 5] = idx + 3

    local vtx_write_ptr = self._VtxWritePtr
    self.VtxBuffer.Data[vtx_write_ptr] = ImDrawVert()
    self.VtxBuffer.Data[vtx_write_ptr].pos = a
    self.VtxBuffer.Data[vtx_write_ptr].col = col

    self.VtxBuffer.Data[vtx_write_ptr + 1] = ImDrawVert()
    self.VtxBuffer.Data[vtx_write_ptr + 1].pos = b
    self.VtxBuffer.Data[vtx_write_ptr + 1].col = col

    self.VtxBuffer.Data[vtx_write_ptr + 2] = ImDrawVert()
    self.VtxBuffer.Data[vtx_write_ptr + 2].pos = c
    self.VtxBuffer.Data[vtx_write_ptr + 2].col = col

    self.VtxBuffer.Data[vtx_write_ptr + 3] = ImDrawVert()
    self.VtxBuffer.Data[vtx_write_ptr + 3].pos = d
    self.VtxBuffer.Data[vtx_write_ptr + 3].col = col

    self._VtxWritePtr = vtx_write_ptr + 4
    self._VtxCurrentIdx = idx + 4
    self._IdxWritePtr = idx_write_ptr + 6
end

--- void ImDrawList::AddPolyline(const ImVec2* points, const int points_count, ImU32 col, ImDrawFlags flags, float thickness)
--
struct_method ImDrawList:AddPolyline(points, points_count, col, flags, thickness)
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
        local use_texture = bit.band(self.Flags, ImDrawListFlags_AntiAliasedLinesUseTex) ~= 0
                        and integer_thickness < IM_DRAWLIST_TEX_LINES_WIDTH_MAX
                        and fractional_thickness <= 0.00001
                        and AA_SIZE == 1.0

        local idx_count = use_texture and (count * 6) or (thick_line and count * 18 or count * 12)
        local vtx_count = use_texture and (points_count * 2) or (thick_line and points_count * 4 or points_count * 3)
        self:PrimReserve(idx_count, vtx_count)

        -- Temporary buffer
        local temp_buffer_size = points_count * (use_texture or not thick_line and 3 or 5)
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
            self.IdxBuffer.Data[idx_write_ptr] = self._VtxCurrentIdx
            self.IdxBuffer.Data[idx_write_ptr + 1] = self._VtxCurrentIdx + 1
            self.IdxBuffer.Data[idx_write_ptr + 2] = self._VtxCurrentIdx + 2
            self.IdxBuffer.Data[idx_write_ptr + 3] = self._VtxCurrentIdx
            self.IdxBuffer.Data[idx_write_ptr + 4] = self._VtxCurrentIdx + 2
            self.IdxBuffer.Data[idx_write_ptr + 5] = self._VtxCurrentIdx + 3
            self._IdxWritePtr = idx_write_ptr + 6

            self._VtxCurrentIdx = self._VtxCurrentIdx + 4
        end
    end
end

local function FixRectCornerFlags(flags)
    -- IM_ASSERT(bit.band(flags, 0x0F) == 0, "Misuse of legacy hardcoded ImDrawCornerFlags values!")

    if (bit.band(flags, ImDrawFlags_RoundCornersMask) == 0) then
        flags = bit.bor(flags, ImDrawFlags_RoundCornersAll)
    end

    return flags
end

struct_method ImDrawList:PathRect(a, b, rounding, flags)
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

struct_method ImDrawList:AddRectFilled(p_min, p_max, col, rounding, flags)
    if col.a == 0 then return end -- TODO: pack color?

    if rounding < 0.5 or (bit.band(flags, ImDrawFlags_RoundCornersMask) == ImDrawFlags_RoundCornersNone) then
        self:PrimReserve(6, 4)
        self:PrimRect(p_min, p_max, col)
    else
        self:PathRect(p_min, p_max, rounding, flags)
        self:PathFillConvex(col)
    end
end

struct_method ImDrawList:AddRect(p_min, p_max, col, rounding, flags, thickness)
    if col.a == 0 then return end
    if bit.band(self.Flags, ImDrawListFlags_AntiAliasedLines) ~= 0 then
        self:PathRect(p_min + ImVec2(0.50, 0.50), p_max - ImVec2(0.50, 0.50), rounding, flags)
    else
        self:PathRect(p_min + ImVec2(0.50, 0.50), p_max - ImVec2(0.49, 0.49), rounding, flags)
    end

    self:PathStroke(col, ImDrawFlags_Closed, thickness)
end

struct_method ImDrawList:AddLine(p1, p2, col, thickness)
    if col.a == 0 then return end

    self:PathLineTo(p1 + ImVec2(0.5, 0.5))
    self:PathLineTo(p2 + ImVec2(0.5, 0.5))
    self:PathStroke(col, 0, thickness)
end

struct_method ImDrawList:AddTriangleFilled(p1, p2, p3, col)
    if col.a == 0 then return end

    self:PathLineTo(p1)
    self:PathLineTo(p2)
    self:PathLineTo(p3)
    self:PathFillConvex(col)
end

struct_method ImDrawList:AddText(text, font, pos, color)
    surface.SetTextPos(pos.x, pos.y)
    surface.SetFont(font)
    surface.SetTextColor(color)
    surface.DrawText(text)
end

struct_method ImDrawList:RenderTextClipped(text, font, pos, color, w, h)
    surface.SetFont(font)
    local text_width, text_height = surface.GetTextSize(text)
    local need_clipping = text_width > w or text_height > h

    -- TODO: clipping
    self:AddText(text, font, pos, color)
end

struct_method ImDrawList:_CalcCircleAutoSegmentCount(radius)
    local radius_idx = ImFloor(radius + 0.999999)

    if radius_idx >= 0 and radius_idx < 64 then -- IM_ARRAYSIZE(_Data->CircleSegmentCounts))
        return self._Data.CircleSegmentCounts[radius_idx] -- Use cached value
    else
        return IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC(radius, self._Data.CircleSegmentMaxError)
    end
end

struct_method ImDrawList:PushClipRect(cr_min, cr_max, intersect_with_current_clip_rect)
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
    -- _OnChangedClipRect()
end

--- void ImDrawList::_PathArcToFastEx
struct_method ImDrawList:_PathArcToFastEx(center, radius, a_min_sample, a_max_sample, a_step)
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

struct_method ImDrawList:PathArcToFast(center, radius, a_min_of_12, a_max_of_12)
    if radius < 0.5 then
        self._Path:push_back(center)
        return
    end

    self:_PathArcToFastEx(center, radius, a_min_of_12 * IM_DRAWLIST_ARCFAST_SAMPLE_MAX / 12, a_max_of_12 * IM_DRAWLIST_ARCFAST_SAMPLE_MAX / 12, 0)
end

struct_method ImDrawList:_PathArcToN(center, radius, a_min, a_max, num_segments)
    if radius < 0.5 then
        self._Path:push_back(center)
        return
    end

    for i = 0, num_segments do
        local a = a_min + (i / num_segments) * (a_max - a_min)
        self._Path:push_back(ImVec2(center.x + ImCos(a) * radius, center.y + ImSin(a) * radius))
    end
end

struct_method ImDrawList:PathArcTo(center, radius, a_min, a_max, num_segments)
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

--- ImGui::RenderArrow
local function RenderArrow(draw_list, pos, color, dir, scale)
    local h = GImGui.FontSize -- TODO: draw_list->_Data->FontSize * 1.00f?
    local r = h * 0.40 * scale

    center = pos + ImVec2(h * 0.50, h * 0.50 * scale)

    local a, b, c

    if dir == ImGuiDir_Up or dir == ImGuiDir_Down then
        if dir == ImGuiDir_Up then r = -r end
        a = ImVec2( 0.000,  0.750) * r
        b = ImVec2(-0.866, -0.750) * r
        c = ImVec2( 0.866, -0.750) * r
    elseif dir == ImGuiDir_Left or dir == ImGuiDir_Right then
        if dir == ImGuiDir_Left then r = -r end
        a = ImVec2( 0.750,  0.000) * r
        b = ImVec2(-0.750,  0.866) * r
        c = ImVec2(-0.750, -0.866) * r
    end

    draw_list:AddTriangleFilled(center + a, center + b, center + c, color)
end