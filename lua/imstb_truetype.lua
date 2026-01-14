---------------------------
--- stb_truetype in Lua5.1!
-- with imgui patches

-- stb_truetype.h - v1.26 - public domain
-- authored from 2009-2021 by Sean Barrett / RAD Game Tools

--- Note: When calling these functions, you must ensure
-- the `data` related param is correctly structured:
--   1. It's a table
--   2. Contains fields named `data`, `offset` and optionally `size`
--   3. the `data` is a generic 1-based table, and `offset` is initially 0
--   4. `size` is a constant since the creation of `data`, and size == #data
-- It's so painful to port og pointer arithmetics into Lua, so I just
-- use this instead

local stbtt_fontinfo

local stbtt_InitFont
local stbtt_MakeGlyphBitmapSubpixelPrefilter
local stbtt_GetFontVMetrics
local stbtt_GetGlyphBitmapBox
local stbtt_GetGlyphBitmapBoxSubpixel
local stbtt_GetGlyphHMetrics
local stbtt_GetFontOffsetForIndex
local stbtt_ScaleForPixelHeight
local stbtt_FindGlyphIndex

------------------------------
--- C Pointer / Array Mimicing
--

--- @class stbtt_slice
--- @field data table
--- @field offset integer

--- @param p stbtt_slice
--- @param n integer
local function ptr_inc(p, n) p.offset = p.offset + n end

local function ptr_deref(p) return p.data[p.offset + 1] end
local function ptr_set_deref(p, v) p.data[p.offset + 1] = v end

--- @param p stbtt_slice
--- @param n integer
--- @return stbtt_slice
--- @nodiscard
local function ptr_add(p, n) return {data = p.data, offset = p.offset + n, size = p.size} end

local function ptr_index_get(p, i) return p.data[p.offset + i + 1] end
local function ptr_index_set(p, i, v) p.data[p.offset + i + 1] = v end

local STBTT_MAX_OVERSAMPLE = 8

--- @enum STBTT_PLATFORM_ID
local STBTT_PLATFORM_ID = {
    UNICODE   = 0,
    MAC       = 1,
    ISO       = 2,
    MICROSOFT = 3,
}

--- @enum STBTT_MS_EID
local STBTT_MS_EID = {
    SYMBOL       = 0,
    UNICODE_BMP  = 1,
    SHIFTJIS     = 2,
    UNICODE_FULL = 10
}

local STBTT_vmove  = 1
local STBTT_vline  = 2
local STBTT_vcurve = 3
local STBTT_vcubic = 4

local bit = bit

local STBTT_assert = assert
local STBTT_sqrt = math.sqrt
local STBTT_fabs = math.abs
local STBTT_pow = math.pow
local STBTT_cos = math.cos
local STBTT_acos = math.acos
local floor = math.floor
local STBTT_ifloor = floor
local STBTT_iceil = math.ceil
local STBTT_fmod = math.fmod
local trunc = function(x)
    if x >= 0 then
        return floor(x)
    else
        return math.ceil(x)
    end
end

local STBTT_sort = table.sort

local STBTT_memset = function() error("memset() not allowed!", 2) end
local STBTT_memcpy = function() error("memcpy() not allowed!", 2) end

local function STBTT__NOTUSED(_) return end

local function stbtt_int32(value)
    return bit.band(value, 0xFFFFFFFF) - (bit.band(value, 0x80000000) ~= 0 and 0x100000000 or 0)
end

local function stbtt_uint32(value)
    return bit.band(value, 0xFFFFFFFF)
end

local function stbtt_int16(value)
    return bit.band(value, 0xFFFF) - (bit.band(value, 0x8000) ~= 0 and 0x10000 or 0)
end

local function stbtt_uint16(value)
    return bit.band(value, 0xFFFF)
end

local function stbtt_int8(value)
    return bit.band(value, 0xFF) - (bit.band(value, 0x80) ~= 0 and 0x100 or 0)
end

local function stbtt_uint8(value)
    return bit.band(value, 0xFF)
end

local function unsigned_char(value)
    return bit.band(value, 0xFF)
end

local function stbtt__buf()
    return {
        data   = nil, -- byte array
        cursor = nil, -- > = 0
        size   = nil
    }
end

function stbtt_fontinfo()
    return {
        data      = nil,
        fontstart = nil,

        numGlyphs = nil,

        loca = nil,
        head = nil,
        glyf = nil,
        hhea = nil,
        hmtx = nil,
        kern = nil,
        gpos = nil,
        svg  = nil,

        index_map        = nil,
        indexToLocFormat = nil,

        cff         = nil,
        charstrings = nil,
        gsubrs      = nil,
        subrs       = nil,
        fontdicts   = nil,
        fdselect    = nil
    }
end

local function stbtt_vertex()
    return {
        x = nil,
        y = nil,
        cx = nil,
        cy = nil,
        cx1 = nil,
        cy1 = nil,
        type = nil,
        padding = nil
    }
end

local function stbtt__csctx()
    return {
        bounds  = nil,
        started = nil,
        first_x = nil,
        first_y = nil,
        x       = nil,
        y       = nil,
        min_x   = nil,
        max_x   = nil,
        min_y   = nil,
        max_y   = nil,

        pvertices    = nil,
        num_vertices = nil
    }
end

local function STBTT__CSCTX_INIT(bounds)
    local this = stbtt__csctx()

    this.bounds  = bounds
    this.started = 0
    this.first_x = 0
    this.first_y = 0
    this.x       = 0
    this.y       = 0
    this.min_x   = 0
    this.max_x   = 0
    this.min_y   = 0
    this.max_y   = 0

    this.pvertices = nil
    this.num_vertices = 0

    return this
end

-- local function stbtt_kerningentry()
-- end

local function stbtt__edge()
    return {
        x0 = nil,
        y0 = nil,
        x1 = nil,
        y1 = nil,
        invert = nil
    }
end

--- XXX: STBTT_RASTERIZER_VERSION == 2
local function stbtt__active_edge()
    return {
        next = nil,
        fx = nil,
        fdx = nil,
        fdy = nil,
        direction = nil,
        sy = nil,
        ey = nil
    }
end

local function stbtt__new_active(e, off_x, start_point)
    local z = stbtt__active_edge()
    local dxdy = (e.x1 - e.x0) / (e.y1 - e.y0)

    z.fdx = dxdy
    z.fdy = (dxdy ~= 0.0) and (1.0 / dxdy) or 0.0
    z.fx = e.x0 + dxdy * (start_point - e.y0)
    z.fx = z.fx - off_x
    z.direction = (e.invert ~= 0) and 1.0 or -1.0
    z.sy = e.y0
    z.ey = e.y1
    z.next = nil

    return z
end

local function stbtt__bitmap()
    return {
        w      = nil,
        h      = nil,
        stride = nil,
        pixels = nil
    }
end

--- @class stbtt__point
--- @field x number
--- @field y number

--- @return stbtt__point
local function stbtt__point()
    return {
        x = nil,
        y = nil
    }
end

-- local function stbrp_node()
-- end

-- local function stbrp_context()
-- end

-- local function stbrp_rect()
-- end

-- local function stbtt_pack_range()
-- end

-- local function stbtt_packedchar()
-- end

----------------------------------------------
--- stbtt__buf helpers to parse data from file
--
local function stbtt__buf_get8(b)
    if b.cursor >= b.size then return 0 end
    local result = b.data[b.cursor]
    b.cursor = b.cursor + 1
    return result
end

local function stbtt__buf_peek8(b)
    if b.cursor >= b.size then return 0 end
    return b.data[b.cursor]
end

local function stbtt__buf_seek(b, o)
    STBTT_assert(not (o > b.size or o < 0))
    if o > b.size or o < 0 then
        b.cursor = b.size
    else
        b.cursor = o
    end
end

local function stbtt__buf_skip(b, o)
    stbtt__buf_seek(b, b.cursor + o)
end

local function stbtt__buf_get(b, n)
    local v = 0
    STBTT_assert(n >= 1 and n <= 4)
    for _ = 1, n do
        v = bit.bor(bit.lshift(v, 8), stbtt__buf_get8(b))
    end
    return v
end

local function stbtt__new_buf(p, size)
    local r = stbtt__buf()
    STBTT_assert(size < 0x40000000)
    r.data = p
    r.size = trunc(size)
    r.cursor = 0
    return r
end

local function stbtt__buf_get16(b) return stbtt__buf_get(b, 2) end
local function stbtt__buf_get32(b) return stbtt__buf_get(b, 4) end

local function stbtt__buf_range(b, o, s)
    local r = stbtt__new_buf(nil, 0)
    if (o < 0 or s < 0 or o > b.size or s > (b.size - o)) then
        return r
    end
    r.data = b.data + o
    r.size = s
    return r
end

local function stbtt__cff_get_index(b)
    local count, start, offsize
    start = b.cursor
    count = stbtt__buf_get16(b)
    if count > 0 then
        offsize = stbtt__buf_get8(b)
        STBTT_assert(offsize >= 1 and offsize <= 4)
        stbtt__buf_skip(b, count * offsize)
        stbtt__buf_skip(b, stbtt__buf_get(b, offsize) - 1)
    end
    return stbtt__buf_range(b, start, b.cursor - start)
end

local function stbtt__cff_int(b)
    local b0 = stbtt__buf_get8(b)
    if b0 >= 32 and b0 <= 246 then return b0 - 139
    elseif b0 >= 247 and b0 <= 250 then return (b0 - 247) * 256 + stbtt__buf_get8(b) + 108
    elseif b0 >= 251 and b0 <= 254 then return -(b0 - 251) * 256 - stbtt__buf_get8(b) - 108
    elseif b0 == 28 then return stbtt__buf_get16(b)
    elseif b0 == 29 then return stbtt__buf_get32(b)
    end
    STBTT_assert(false)
    return 0
end

local function stbtt__cff_skip_operand(b)
    local v
    local b0 = stbtt__buf_peek8(b)
    STBTT_assert(b0 >= 28)
    if b0 == 30 then
        stbtt__buf_skip(b, 1)
        while b.cursor < b.size do
            v = stbtt__buf_get8(b)
            if (bit.band(v, 0xF) == 0xF or bit.rshift(v, 4) == 0xF) then
                break
            end
        end
    else
        stbtt__cff_int(b)
    end
end

local function stbtt__dict_get(b, key)
    stbtt__buf_seek(b, 0)
    while b.cursor < b.size do
        local start = b.cursor
        local _end, op
        while stbtt__buf_peek8(b) >= 28 do
            stbtt__cff_skip_operand(b)
        end
        _end = b.cursor
        op = stbtt__buf_get8(b)
        if op == 12 then op = bit.bor(stbtt__buf_get8(b), 0x100) end
        if op == key then return stbtt__buf_range(b, start, _end - start) end
    end
    return stbtt__buf_range(b, 0, 0)
end

local function stbtt__dict_get_ints(b, key, outcount)
    local operands = stbtt__dict_get(b, key)
    local out = {}
    for i = 1, outcount do
        if operands.cursor >= operands.size then break end
        out[i] = stbtt__cff_int(operands)
    end
    return out
end

local function stbtt__cff_index_count(b)
    stbtt__buf_seek(b, 0)
    return stbtt__buf_get16(b)
end

local function stbtt__cff_index_get(b, i)
    local count, offsize, start, _end
    stbtt__buf_seek(b, 0)
    count = stbtt__buf_get16(b)
    offsize = stbtt__buf_get8(b)
    STBTT_assert(i >= 0 and i < count)
    STBTT_assert(offsize >= 1 and offsize <= 4)
    stbtt__buf_skip(b, i * offsize)
    start = stbtt__buf_get(b, offsize)
    _end = stbtt__buf_get(b, offsize)
    return stbtt__buf_range(b, 2 + (count + 1) * offsize + start, _end - start)
end

-------------------------------------
--- accessors to parse data from file
--
local function ttUSHORT(p) return stbtt_uint16(p.data[p.offset + 1] * 256 + p.data[p.offset + 2]) end
local function ttSHORT(p) return stbtt_int16(p.data[p.offset + 1] * 256 + p.data[p.offset + 2]) end
local function ttULONG(p) return stbtt_uint32(bit.lshift(p.data[p.offset + 1], 24) + bit.lshift(p.data[p.offset + 2], 16) + bit.lshift(p.data[p.offset + 3], 8) + p.data[p.offset + 4]) end
local function ttLONG(p) return stbtt_int32(bit.lshift(p.data[p.offset + 1], 24) + bit.lshift(p.data[p.offset + 2], 16) + bit.lshift(p.data[p.offset + 3], 8) + p.data[p.offset + 4]) end

local function ttBYTE(p) return stbtt_uint8(ptr_deref(p)) end
local function ttCHAR(p) return stbtt_int8(ptr_deref(p)) end

local function stbtt_tag4(p, c0, c1, c2, c3) return p.data[p.offset + 1] == c0 and p.data[p.offset + 2] == c1 and p.data[p.offset + 3] == c2 and p.data[p.offset + 4] == c3 end
local function stbtt_tag(p, str) return stbtt_tag4(p, string.byte(str, 1, 4)) end

local function stbtt__isfont(font)
    if stbtt_tag4(font, string.byte("1"), 0, 0, 0) then return true end
    if stbtt_tag(font, "typ1") then return true end
    if stbtt_tag(font, "OTTO") then return true end
    if stbtt_tag4(font, 0, 1, 0, 0) then return true end
    if stbtt_tag(font, "true") then return true end
    return false
end

local function stbtt__find_table(data, font_start, tag)
    local num_tables = ttUSHORT(ptr_add(data, font_start + 4))
    local tabledir = font_start + 12
    for i = 0, num_tables - 1 do
        local loc = tabledir + i * 16
        if stbtt_tag(ptr_add(data, loc + 0), tag) then
            return ttULONG(ptr_add(data, loc + 8))
        end
    end
    return 0
end

local function stbtt_GetFontOffsetForIndex_internal(font_collection, index)
    if stbtt__isfont(font_collection) then
        if index == 0 then return 0 else return -1 end
    end

    if stbtt_tag(font_collection, "ttcf") then
        if ttULONG(ptr_add(font_collection, 4)) == 0x00010000 or ttULONG(ptr_add(font_collection, 4)) == 0x00020000 then
            local n = ttLONG(ptr_add(font_collection, 8))
            if index >= n then
                return -1
            end
            return ttULONG(ptr_add(font_collection, 12 + index * 4))
        end
    end

    return -1
end

local function stbtt_GetNumberOfFonts_internal(font_collection)
    if stbtt__isfont(font_collection) then
        return 1
    end

    if stbtt_tag(font_collection, "ttcf") then
        if ttULONG(ptr_add(font_collection, 4)) == 0x00010000 or ttULONG(ptr_add(font_collection, 4)) == 0x00020000 then
            return ttLONG(ptr_add(font_collection, 8))
        end
    end

    return 0
end

local function stbtt__get_subrs(cff, fontdict) -- stbtt__buf cff, stbtt__buf fontdict
    local private_loc = stbtt__dict_get_ints(fontdict, 18, 2)
    if (private_loc[2] == 0 or private_loc[1] == 0) then
        return stbtt__new_buf(nil, 0)
    end
    local pdict = stbtt__buf_range(cff, private_loc[2], private_loc[1])
    local subrsoff = stbtt__dict_get_ints(pdict, 19, 1)
    if subrsoff[1] == 0 then
        return stbtt__new_buf(nil, 0)
    end
    stbtt__buf_seek(cff, private_loc[2] + subrsoff[1])
    return stbtt__cff_get_index(cff)
end

local function stbtt__get_svg(info) -- stbtt_fontinfo *info
    local t
    if info.svg < 0 then
        t = stbtt__find_table(info.data, info.fontstart, "SVG ")
        if t ~= 0 then
            local offset = ttULONG(ptr_add(info.data, t + 2))
            info.svg = t + offset
        else
            info.svg = 0
        end
    end
    return info.svg
end

--- @return bool
local function stbtt_InitFont_internal(info, data, fontstart)
    local cmap
    local numTables

    info.data = data
    info.fontstart = fontstart
    info.cff = stbtt__new_buf(nil, 0)

    cmap = stbtt__find_table(data, fontstart, "cmap")
    info.loca = stbtt__find_table(data, fontstart, "loca")
    info.head = stbtt__find_table(data, fontstart, "head")
    info.glyf = stbtt__find_table(data, fontstart, "glyf")
    info.hhea = stbtt__find_table(data, fontstart, "hhea")
    info.hmtx = stbtt__find_table(data, fontstart, "hmtx")
    info.kern = stbtt__find_table(data, fontstart, "kern")
    info.gpos = stbtt__find_table(data, fontstart, "GPOS")

    if (cmap == 0 or info.head == 0 or info.hhea == 0 or info.hmtx == 0) then
        return false
    end
    if info.glyf ~= 0 then
        if info.loca == 0 then
            return false
        end
    else
        local cff = stbtt__find_table(data, fontstart, "CFF ")
        if cff == 0 then
            return false
        end

        info.fontdicts = stbtt__new_buf(nil, 0)
        info.fdselect = stbtt__new_buf(nil, 0)

        info.cff = stbtt__new_buf(ptr_add(data, cff), 8 * 1024 * 1024) -- TODO: i didn't solve the og todo, and further decreased it. 8MB
        local b = info.cff

        -- read the header
        stbtt__buf_skip(b, 2)
        stbtt__buf_seek(b, stbtt__buf_get8(b))

        -- TODO: the name INDEX could list multiple fonts,
        -- but we just use the first one.
        stbtt__cff_get_index(b) -- name INDEX
        local topdictidx = stbtt__cff_get_index(b)
        local topdict = stbtt__cff_index_get(topdictidx, 0)
        stbtt__cff_get_index(b) -- string INDEX
        info.gsubrs = stbtt__cff_get_index(b)

        local charstrings = stbtt__dict_get_ints(topdict, 17, 1)
        local cstype      = stbtt__dict_get_ints(topdict, bit.bor(0x100, 6), 1)
        local fdarrayoff  = stbtt__dict_get_ints(topdict, bit.bor(0x100, 36), 1)
        local fdselectoff = stbtt__dict_get_ints(topdict, bit.bor(0x100, 37), 1)
        info.subrs = stbtt__get_subrs(b, topdict)

        if cstype[1] ~= 2 then
            return false
        end
        if charstrings[1] == 0 then
            return false
        end

        if fdarrayoff[1] ~= 0 then
            if fdselectoff[1] == 0 then
                return false
            end

            stbtt__buf_seek(b, fdarrayoff[1])
            info.fontdicts = stbtt__cff_get_index(b)
            info.fdselect = stbtt__buf_range(b, fdselectoff[1], b.size - fdselectoff[1])
        end

        stbtt__buf_seek(b, charstrings[1])
        info.charstrings = stbtt__cff_get_index(b)
    end

    local t = stbtt__find_table(data, fontstart, "maxp")
    if t ~= 0 then
        info.numGlyphs = ttUSHORT(ptr_add(data, t + 4))
    else
        info.numGlyphs = 0xffff
    end

    info.svg = -1

    numTables = ttUSHORT(ptr_add(data, cmap + 2))
    info.index_map = 0
    for i = 0, numTables - 1 do
        local encoding_record = cmap + 4 + 8 * i
        local platform_id = ttUSHORT(ptr_add(data, encoding_record))

        if platform_id == STBTT_PLATFORM_ID.MICROSOFT then
            local ms_eid = ttUSHORT(ptr_add(data, encoding_record + 2))

            if ms_eid == STBTT_MS_EID.UNICODE_BMP or ms_eid == STBTT_MS_EID.UNICODE_FULL then
                info.index_map = cmap + ttULONG(ptr_add(data, encoding_record + 4))
            end
        elseif platform_id == STBTT_PLATFORM_ID.UNICODE then
            info.index_map = cmap + ttULONG(ptr_add(data, encoding_record + 4))
        end
    end
    if info.index_map == 0 then
        return false
    end

    info.indexToLocFormat = ttUSHORT(ptr_add(data, info.head + 50))
    return true
end

function stbtt_FindGlyphIndex(info, unicode_codepoint)
    local data = info.data
    local index_map = info.index_map

    local format = ttUSHORT(ptr_add(data, index_map + 0))
    if format == 0 then
        local bytes = ttUSHORT(ptr_add(data, index_map + 2))
        if unicode_codepoint < bytes - 6 then
            return ttBYTE(ptr_add(data, index_map + 6 + unicode_codepoint))
        end
        return 0
    elseif format == 6 then
        local first = ttUSHORT(ptr_add(data, index_map + 6))
        local count = ttUSHORT(ptr_add(data, index_map + 8))
        if unicode_codepoint >= first and unicode_codepoint < first + count then
            return ttUSHORT(ptr_add(data, index_map + 10 + (unicode_codepoint - first) * 2))
        end
        return 0
    elseif format == 2 then
        STBTT_assert(false) -- TODO: high-byte mapping for japanese/chinese/korean
        return 0
    elseif format == 4 then
        local segcount = bit.rshift(ttUSHORT(ptr_add(data, index_map + 6)), 1)
        local searchRange = bit.rshift(ttUSHORT(ptr_add(data, index_map + 8)), 1)
        local entrySelector = ttUSHORT(ptr_add(data, index_map + 10))
        local rangeShift = bit.rshift(ttUSHORT(ptr_add(data, index_map + 12)), 1)

        local endCount = index_map + 14
        local search = endCount

        if unicode_codepoint > 0xffff then
            return 0
        end

        if unicode_codepoint >= ttUSHORT(ptr_add(data, search + searchRange * 2)) then
            search = search + searchRange * 2
        end

        search = search - 2
        while entrySelector ~= 0 do
            searchRange = bit.rshift(searchRange, 1)
            local _end = ttUSHORT(ptr_add(data, search + searchRange * 2))
            if unicode_codepoint > _end then
                search = search + searchRange * 2
            end
            entrySelector = entrySelector - 1
        end
        search = search + 2

        do
            local item = stbtt_uint16(bit.rshift(search - endCount, 1))

            local start = ttUSHORT(ptr_add(data, index_map + 14 + segcount * 2 + 2 + 2 * item))
            local last = ttUSHORT(ptr_add(data, endCount + 2 * item))
            if unicode_codepoint < start or unicode_codepoint > last then
                return 0
            end

            local offset = ttUSHORT(ptr_add(data, index_map + 14 + segcount * 6 + 2 + 2 * item))
            if offset == 0 then
                return stbtt_uint16(unicode_codepoint + ttSHORT(ptr_add(data, index_map + 14 + segcount * 4 + 2 + 2 * item)))
            end

            return ttUSHORT(ptr_add(data, offset + (unicode_codepoint - start) * 2 + index_map + 14 + segcount * 6 + 2 + 2 * item))
        end
    elseif format == 12 or format == 13 then
        local ngroups = ttULONG(ptr_add(data, index_map + 12))
        local low = 0
        local high = ngroups
        while low < high do
            local mid = low + bit.rshift(high - low, 1)
            local start_char = ttULONG(ptr_add(data, index_map + 16 + mid * 12))
            local end_char = ttULONG(ptr_add(data, index_map + 16 + mid * 12 + 4))
            if unicode_codepoint < start_char then
                high = mid
            elseif unicode_codepoint > end_char then
                low = mid + 1
            else
                local start_glyph = ttULONG(ptr_add(data, index_map + 16 + mid * 12 + 8))
                if format == 12 then
                    return start_glyph + unicode_codepoint - start_char
                else -- format == 13
                    return start_glyph
                end
            end
        end
        return 0
    end

    -- TODO
    STBTT_assert(false)
    return 0
end

local function stbtt_setvertex(v, _type, x, y, cx, cy)
    v.type = _type
    v.x = stbtt_int16(x)
    v.y = stbtt_int16(y)
    v.cx = stbtt_int16(cx)
    v.cy = stbtt_int16(cy)
end

local function stbtt__GetGlyfOffset(info, glyph_index)
    STBTT_assert(info.cff.size == 0)

    if glyph_index >= info.numGlyphs then return -1 end
    if info.indexToLocFormat >= 2 then return -1 end

    local g1, g2
    if info.indexToLocFormat == 0 then
        g1 = info.glyf + ttUSHORT(ptr_add(info.data, info.loca + glyph_index * 2)) * 2
        g2 = info.glyf + ttUSHORT(ptr_add(info.data, info.loca + glyph_index * 2 + 2)) * 2
    else
        g1 = info.glyf + ttULONG(ptr_add(info.data, info.loca + glyph_index * 4))
        g2 = info.glyf + ttULONG(ptr_add(info.data, info.loca + glyph_index * 4 + 4))
    end

    if g1 == g2 then return -1 else return g1 end
end

local stbtt__GetGlyphInfoT2

--- @return integer, integer?, integer?, integer?, integer?
local function stbtt_GetGlyphBox(info, glyph_index)
    local n, x0, y0, x1, y1

    if info.cff.size ~= 0 then
        n, x0, y0, x1, y1 = stbtt__GetGlyphInfoT2(info, glyph_index)
    else
        local g = stbtt__GetGlyfOffset(info, glyph_index)
        if g < 0 then return 0 end

        x0 = ttSHORT(ptr_add(info.data, g + 2))
        y0 = ttSHORT(ptr_add(info.data, g + 4))
        x1 = ttSHORT(ptr_add(info.data, g + 6))
        y1 = ttSHORT(ptr_add(info.data, g + 8))
    end

    return 1, x0, y0, x1, y1
end

local function stbtt_GetCodepointBox(info, codepoint)
    return stbtt_GetGlyphBox(info, stbtt_FindGlyphIndex(info, codepoint))
end

local function stbtt_IsGlyphEmpty(info, glyph_index)
    if info.cff.size ~= 0 then
        return stbtt__GetGlyphInfoT2(info, glyph_index) == 0
    end

    local g = stbtt__GetGlyfOffset(info, glyph_index)
    if g < 0 then return 1 end

    local numberOfContours = ttSHORT(info.data + g)
    return numberOfContours == 0
end

local function stbtt__close_shape(vertices, num_vertices, was_off, start_off, sx, sy, scx, scy, cx, cy)
    if start_off ~= 0 then
        if was_off ~= 0 then
            stbtt_setvertex(vertices[num_vertices + 1], STBTT_vcurve, bit.rshift(cx + scx, 1), bit.rshift(cy + scy, 1), cx, cy)
            num_vertices = num_vertices + 1
        end
        stbtt_setvertex(vertices[num_vertices + 1], STBTT_vcurve, sx, sy, scx, scy)
        num_vertices = num_vertices + 1
    else
        if was_off ~= 0 then
            stbtt_setvertex(vertices[num_vertices + 1], STBTT_vcurve, sx, sy, cx, cy)
            num_vertices = num_vertices + 1
        else
            stbtt_setvertex(vertices[num_vertices + 1], STBTT_vline, sx, sy, 0, 0)
            num_vertices = num_vertices + 1
        end
    end
    return num_vertices
end

local stbtt_GetGlyphShape
local stbtt__GetGlyphShapeT2

local function stbtt__GetGlyphShapeTT(info, glyph_index)
    local data = info.data
    local num_vertices

    local vertices = nil

    local g = stbtt__GetGlyfOffset(info, glyph_index)

    if g < 0 then return 0 end

    local numberOfContours = ttSHORT(ptr_add(data, g))

    if numberOfContours > 0 then
        local endPtsOfContours = ptr_add(data, g + 10)
        local ins = ttUSHORT(ptr_add(data, g + 10 + numberOfContours * 2))
        local points = ptr_add(data, g + 10 + numberOfContours * 2 + 2 + ins)

        local n = 1 + ttUSHORT(ptr_add(endPtsOfContours, numberOfContours * 2 - 2))
        local m = n + 2 * numberOfContours

        vertices = {}
        for i = 1, m do vertices[i] = stbtt_vertex() end

        local j = 0
        local was_off = 0
        local start_off = 0
        local next_move = 0
        local flagcount = 0

        local off = m - n

        -- first load flags
        local flags = 0
        for i = 1, n do
            if flagcount == 0 then
                flags = ptr_deref(points)
                ptr_inc(points, 1)

                if bit.band(flags, 8) ~= 0 then
                    flagcount = ptr_deref(points)
                    ptr_inc(points, 1)
                end
            else
                flagcount = flagcount - 1
            end

            vertices[off + i].type = flags
        end

        -- now load x coordinates
        local x = 0
        for i = 1, n do
            flags = vertices[off + i].type
            if bit.band(flags, 2) ~= 0 then
                local dx = ptr_deref(points)
                ptr_inc(points, 1)
                if bit.band(flags, 16) ~= 0 then
                    x = x + dx
                else
                    x = x - dx
                end
            else
                if bit.band(flags, 16) == 0 then
                    x = x + stbtt_int16(ptr_index_get(points, 0) * 256 + ptr_index_get(points, 1))
                    ptr_inc(points, 2)
                end
            end

            vertices[off + i].x = stbtt_int16(x)
        end

        -- now load y coordinates
        local y = 0
        for i = 1, n do
            flags = vertices[off + i].type
            if bit.band(flags, 4) ~= 0 then
                local dy = ptr_deref(points)
                ptr_inc(points, 1)
                if bit.band(flags, 32) ~= 0 then
                    y = y + dy
                else
                    y = y - dy
                end
            else
                if bit.band(flags, 32) == 0 then
                    y = y + stbtt_int16(ptr_index_get(points, 0) * 256 + ptr_index_get(points, 1))
                    ptr_inc(points, 2)
                end
            end

            vertices[off + i].y = stbtt_int16(y)
        end

        -- now convert them to our format
        num_vertices = 0
        local sx, sy, cx, cy, scx, scy = 0, 0, 0, 0, 0, 0
        for i = 1, n do
            flags = vertices[off + i].type
            x = stbtt_int16(vertices[off + i].x)
            y = stbtt_int16(vertices[off + i].y)

            if next_move == i - 1 then
                if i ~= 1 then
                    num_vertices = stbtt__close_shape(vertices, num_vertices, was_off, start_off, sx, sy, scx, scy, cx, cy)
                end

                -- now start the new one
                start_off = ((bit.band(flags, 1) == 0) and 1 or 0)
                if start_off ~= 0 then
                    scx = x
                    scy = y
                    if bit.band(vertices[off + i + 1].type, 1) == 0 then
                        sx = bit.rshift(x + stbtt_int32(vertices[off + i + 1].x), 1)
                        sy = bit.rshift(y + stbtt_int32(vertices[off + i + 1].y), 1)
                    else
                        sx = stbtt_int32(vertices[off + i + 1].x)
                        sy = stbtt_int32(vertices[off + i + 1].y)
                        i = i + 1
                    end
                else
                    sx = x
                    sy = y
                end
                stbtt_setvertex(vertices[num_vertices + 1], STBTT_vmove, sx, sy, 0, 0)
                num_vertices = num_vertices + 1
                was_off = 0
                next_move = 1 + ttUSHORT(ptr_add(endPtsOfContours, j * 2))
                j = j + 1
            else
                if bit.band(flags, 1) == 0 then
                    if was_off ~= 0 then
                        stbtt_setvertex(vertices[num_vertices + 1], STBTT_vcurve, bit.rshift(cx + x, 1), bit.rshift(cy + y, 1), cx, cy)
                        num_vertices = num_vertices + 1
                    end

                    cx = x
                    cy = y
                    was_off = 1
                else
                    if was_off ~= 0 then
                        stbtt_setvertex(vertices[num_vertices + 1], STBTT_vcurve, x, y, cx, cy)
                        num_vertices = num_vertices + 1
                    else
                        stbtt_setvertex(vertices[num_vertices + 1], STBTT_vline, x, y, 0, 0)
                        num_vertices = num_vertices + 1
                    end

                    was_off = 0
                end
            end
        end

        num_vertices = stbtt__close_shape(vertices, num_vertices, was_off, start_off, sx, sy, scx, scy, cx, cy)
    elseif numberOfContours < 0 then
        local more = 1
        local comp = data + g + 10
        num_vertices = 0

        while more ~= 0 do
            local flags, gidx
            local comp_num_vertices = 0
            local comp_verts

            local mtx = {1, 0, 0, 1, 0, 0}
            local m, n

            flags = ttSHORT(comp) ptr_inc(comp, 2)
            gidx = ttSHORT(comp) ptr_inc(comp, 2)

            if bit.band(flags, 2) ~= 0 then
                if bit.band(flags, 1) ~= 0 then
                    mtx[5] = ttSHORT(comp) ptr_inc(comp, 2)
                    mtx[6] = ttSHORT(comp) ptr_inc(comp, 2)
                else
                    mtx[5] = ttCHAR(comp) ptr_inc(comp, 1)
                    mtx[6] = ttCHAR(comp) ptr_inc(comp, 1)
                end
            else
                -- TODO: handle matching point
                STBTT_assert(false)
            end

            if bit.band(flags, bit.lshift(1, 3)) ~= 0 then -- WE_HAVE_A_SCALE
                mtx[4] = ttSHORT(comp) / 16384.0
                mtx[1] = mtx[4]
                ptr_inc(comp, 2)

                mtx[3] = 0
                mtx[2] = mtx[3]
            elseif bit.band(flags, bit.lshift(1, 6)) ~= 0 then -- WE_HAVE_AN_X_AND_YSCALE
                mtx[1] = ttSHORT(comp) / 16384.0
                ptr_inc(comp, 2)

                mtx[3] = 0
                mtx[2] = mtx[3]

                mtx[4] = ttSHORT(comp) / 16384.0
                ptr_inc(comp, 2)
            elseif bit.band(flags, bit.lshift(1, 7)) ~= 0 then -- WE_HAVE_A_TWO_BY_TWO
                mtx[1] = ttSHORT(comp) / 16384.0 ptr_inc(comp, 2)
                mtx[2] = ttSHORT(comp) / 16384.0 ptr_inc(comp, 2)
                mtx[3] = ttSHORT(comp) / 16384.0 ptr_inc(comp, 2)
                mtx[4] = ttSHORT(comp) / 16384.0 ptr_inc(comp, 2)
            end

            m = STBTT_sqrt(mtx[1] * mtx[1] + mtx[2] * mtx[2])
            n = STBTT_sqrt(mtx[3] * mtx[3] + mtx[4] * mtx[4])

            comp_num_vertices, comp_verts = stbtt_GetGlyphShape(info, gidx)
            if comp_num_vertices > 0 then
                for i = 1, comp_num_vertices do
                    local v = comp_verts[i]
                    local x = v.x
                    local y = v.y
                    v.x = m * (mtx[1] * x + mtx[3] * y + mtx[5])
                    v.y = n * (mtx[2] * x + mtx[4] * y + mtx[6])
                    x = v.cx
                    y = v.cy
                    v.cx = m * (mtx[1] * x + mtx[3] * y + mtx[5])
                    v.cy = n * (mtx[2] * x + mtx[4] * y + mtx[6])
                end

                -- append vertices
                local tmp = {}
                if num_vertices > 0 and vertices then
                    for i = 1, num_vertices do
                        tmp[i] = vertices[i]
                    end
                end
                for i = 1, comp_num_vertices do
                    tmp[num_vertices + i] = comp_verts[i]
                end
                vertices = tmp

                num_vertices = num_vertices + comp_num_vertices
            end

            more = bit.band(flags, bit.lshift(1, 5))
        end
    end

    return num_vertices, vertices
end

local function stbtt__track_vertex(c, x, y)
    if x > c.max_x or c.started == 0 then c.max_x = x end
    if y > c.max_y or c.started == 0 then c.max_y = y end
    if x < c.min_x or c.started == 0 then c.min_x = x end
    if y < c.min_y or c.started == 0 then c.min_y = y end
    c.started = 1
end

local function stbtt__csctx_v(c, _type, x, y, cx, cy, cx1, cy1)
    if c.bounds ~= 0 then
        stbtt__track_vertex(c, x, y)
        if _type == STBTT_vcubic then
            stbtt__track_vertex(c, cx, cy)
            stbtt__track_vertex(c, cx1, cy1)
        end
    else
        stbtt_setvertex(c.pvertices[c.num_vertices + 1], _type, x, y, cx, cy)
        c.pvertices[c.num_vertices + 1].cx1 = stbtt_int16(cx1)
        c.pvertices[c.num_vertices + 1].cy1 = stbtt_int16(cy1)
    end
end

local function stbtt__csctx_close_shape(ctx)
    if ctx.first_x ~= ctx.x or ctx.first_y ~= ctx.y then
        stbtt__csctx_v(ctx, STBTT_vline, trunc(ctx.first_x), trunc(ctx.first_y), 0, 0, 0, 0)
    end
end

local function stbtt__csctx_rmove_to(ctx, dx, dy)
    stbtt__csctx_close_shape(ctx)
    ctx.x = ctx.x + dx
    ctx.first_x = ctx.x
    ctx.y = ctx.y + dy
    ctx.first_y = ctx.y
    stbtt__csctx_v(ctx, STBTT_vmove, trunc(ctx.x), trunc(ctx.y), 0, 0, 0, 0)
end

local function stbtt__csctx_rline_to(ctx, dx, dy)
    ctx.x = ctx.x + dx
    ctx.y = ctx.y + dy
    stbtt__csctx_v(ctx, STBTT_vline, trunc(ctx.x), trunc(ctx.y), 0, 0, 0, 0)
end

local function stbtt__csctx_rccurve_to(ctx, dx1, dy1, dx2, dy2, dx3, dy3)
    local cx1 = ctx.x + dx1
    local cy1 = ctx.y + dy1
    local cx2 = cx1 + dx2
    local cy2 = cy1 + dy2
    ctx.x = cx2 + dx3
    ctx.y = cy2 + dy3
    stbtt__csctx_v(ctx, STBTT_vcubic, trunc(ctx.x), trunc(ctx.y), trunc(cx1), trunc(cy1), trunc(cx2), trunc(cy2))
end

local function stbtt__get_subr(idx, n)
    local count = stbtt__cff_index_count(idx)
    local bias = 107
    if count >= 33900 then
        bias = 32768
    elseif count >= 1240 then
        bias = 1131
    end
    n = n + bias
    if n < 0 or n >= count then
        return stbtt__new_buf(nil, 0)
    end
    return stbtt__cff_index_get(idx, n)
end

local function stbtt__cid_get_glyph_subrs(info, glyph_index)
    local fdselect = info.fdselect
    local fdselector = -1

    stbtt__buf_seek(fdselect, 0)
    local fmt = stbtt__buf_get8(fdselect)
    if fmt == 0 then
        -- untested
        stbtt__buf_skip(fdselect, glyph_index)
        fdselector = stbtt__buf_get8(fdselect)
    elseif fmt == 3 then
        local nranges = stbtt__buf_get16(fdselect)
        local start = stbtt__buf_get16(fdselect)
        for i = 0, nranges - 1 do
            local v = stbtt__buf_get8(fdselect)
            local _end = stbtt__buf_get16(fdselect)
            if glyph_index >= start and glyph_index < _end then
                fdselector = v
                break
            end
            start = _end
        end
    end
    if fdselector == -1 then return stbtt__new_buf(nil, 0) end -- [DEAR IMGUI] fixed, see #6007 and nothings/stb#1422
    return stbtt__get_subrs(info.cff, stbtt__cff_index_get(info.fontdicts, fdselector))
end

local function stbtt__run_charstring(info, glyph_index, c) -- const stbtt_fontinfo *info, int glyph_index, stbtt__csctx *c
    local in_header = 1
    local maskbits = 0
    local subr_stack_height = 0
    local sp = 0
    local has_subrs = 0
    local clear_stack

    local s = {} -- size = 48, 0-based

    local subr_stack = {} for i = 1, 10 do subr_stack[i] = stbtt__buf() end

    local subrs = info.subrs
    local b, f

    local function STBTT__CSERR(_s) return 0 end

    -- this currently ignores the initial width value, which isn't needed if we have hmtx
    b = stbtt__cff_index_get(info.charstrings, glyph_index)
    local i, v, b0
    while b.cursor < b.size do
        i = 0
        clear_stack = 1
        b0 = stbtt__buf_get8(b)

        -- TODO: implement hinting
        if b0 == 0x13 or b0 == 0x14 then -- hintmask or cntrmask
            if in_header ~= 0 then
                maskbits = maskbits + trunc(sp / 2)  -- implicit "vstem"
            end
            in_header = 0
            stbtt__buf_skip(b, trunc((maskbits + 7) / 8))
        elseif b0 == 0x01 or b0 == 0x03 or b0 == 0x12 or b0 == 0x17 then -- hstem, vstem, hstemhm, vstemhm
            maskbits = maskbits + trunc(sp / 2)
        elseif b0 == 0x15 then -- rmoveto
            in_header = 0
            if sp < 2 then return STBTT__CSERR("rmoveto stack") end
            stbtt__csctx_rmove_to(c, s[sp - 2], s[sp - 1])
        elseif b0 == 0x04 then -- vmoveto
            in_header = 0
            if sp < 1 then return STBTT__CSERR("vmoveto stack") end
            stbtt__csctx_rmove_to(c, 0, s[sp - 1])
        elseif b0 == 0x16 then -- hmoveto
            in_header = 0
            if sp < 1 then return STBTT__CSERR("hmoveto stack") end
            stbtt__csctx_rmove_to(c, s[sp - 1], 0)
        elseif b0 == 0x05 then -- rlineto
            if sp < 2 then return STBTT__CSERR("rlineto stack") end
            while i + 1 < sp do
                stbtt__csctx_rline_to(c, s[i], s[i + 1])
                i = i + 2
            end

        -- hlineto/vlineto and vhcurveto/hvcurveto alternate horizontal and vertical
        -- starting from a different place.

        elseif b0 == 0x07 then -- vlineto
            if sp < 1 then return STBTT__CSERR("vlineto stack") end
            while true do
                if i >= sp then break end
                stbtt__csctx_rline_to(c, 0, s[i])
                i = i + 1
                if i >= sp then break end
                stbtt__csctx_rline_to(c, s[i], 0)
                i = i + 1
            end
        elseif b0 == 0x06 then -- hlineto
            if sp < 1 then return STBTT__CSERR("hlineto stack") end

            while true do
                if i >= sp then break end
                stbtt__csctx_rline_to(c, s[i], 0)
                i = i + 1
            -- vlineto
                if i >= sp then break end
                stbtt__csctx_rline_to(c, 0, s[i])
                i = i + 1
            end
        elseif b0 == 0x1F then -- hvcurveto
            if sp < 4 then return STBTT__CSERR("hvcurveto stack") end
            while true do
                if i + 3 >= sp then break end
                stbtt__csctx_rccurve_to(c, s[i], 0, s[i + 1], s[i + 2], ((sp - i) == 5) and s[i + 4] or 0.0, s[i + 3])
                i = i + 4
                if i + 3 >= sp then break end
                stbtt__csctx_rccurve_to(c, 0, s[i], s[i + 1], s[i + 2], s[i + 3], ((sp - i) == 5) and s[i + 4] or 0.0)
                i = i + 4
            end
        elseif b0 == 0x1E then -- vhcurveto
            if sp < 4 then return STBTT__CSERR("vhcurveto stack") end

            while true do
                if i + 3 >= sp then break end
                stbtt__csctx_rccurve_to(c, 0, s[i], s[i + 1], s[i + 2], s[i + 3], ((sp - i) == 5) and s[i + 4] or 0.0)
                i = i + 4
            -- hvcurveto
                if i + 3 >= sp then break end
                stbtt__csctx_rccurve_to(c, s[i], 0, s[i + 1], s[i + 2], ((sp - i) == 5) and s[i + 4] or 0.0, s[i + 3])
                i = i + 4
            end
        elseif b0 == 0x08 then -- rrcurveto
            if sp < 6 then return STBTT__CSERR("rcurveline stack") end

            while i + 5 < sp do
                stbtt__csctx_rccurve_to(c, s[i], s[i + 1], s[i + 2], s[i + 3], s[i + 4], s[i + 5])
                i = i + 6
            end
        elseif b0 == 0x18 then -- rcurveline
            if sp < 8 then return STBTT__CSERR("rcurveline stack") end

            while i + 5 < sp - 2 do
                stbtt__csctx_rccurve_to(c, s[i], s[i + 1], s[i + 2], s[i + 3], s[i + 4], s[i + 5])
                i = i + 6
            end
            if i + 1 >= sp then return STBTT__CSERR("rcurveline stack") end
            stbtt__csctx_rline_to(c, s[i], s[i + 1])
        elseif b0 == 0x19 then -- rlinecurve
            if sp < 8 then return STBTT__CSERR("rlinecurve stack") end

            while i + 1 < sp - 6 do
                stbtt__csctx_rline_to(c, s[i], s[i + 1])
                i = i + 2
            end
            if i + 5 >= sp then return STBTT__CSERR("rlinecurve stack") end
            stbtt__csctx_rccurve_to(c, s[i], s[i + 1], s[i + 2], s[i + 3], s[i + 4], s[i + 5])
        elseif b0 == 0x1A or b0 == 0x1B then -- vvcurveto or hhcurveto
            if sp < 4 then return STBTT__CSERR("(vv|hh)curveto stack") end
            f = 0.0

            if bit.band(sp, 1) ~= 0 then
                f = s[i]
                i = i + 1
            end
            while i + 3 < sp do
                if b0 == 0x1B then
                    stbtt__csctx_rccurve_to(c, s[i], f, s[i + 1], s[i + 2], s[i + 3], 0.0)
                else
                    stbtt__csctx_rccurve_to(c, f, s[i], s[i + 1], s[i + 2], 0.0, s[i + 3])
                end
                f = 0.0
                i = i + 4
            end
        elseif b0 == 0x0A -- callsubr
            or b0 == 0x1D then

            if b0 == 0x0A and has_subrs == 0 then
                if info.fdselect.size ~= 0 then
                    subrs = stbtt__cid_get_glyph_subrs(info, glyph_index)
                end
                has_subrs = 1
            end

            -- callgsubr
            if sp < 1 then return STBTT__CSERR("call(g|)subr stack") end
            sp = sp - 1
            v = trunc(s[sp])
            if subr_stack_height >= 10 then return STBTT__CSERR("recursion limit") end
            subr_stack[subr_stack_height + 1] = b
            subr_stack_height = subr_stack_height + 1
            b = stbtt__get_subr((b0 == 0x0A) and subrs or info.gsubrs, v)
            if b.size == 0 then return STBTT__CSERR("subr not found") end
            b.cursor = 0
            clear_stack = 0
        elseif b0 == 0x0B then -- return
            if subr_stack_height <= 0 then return STBTT__CSERR("return outside subr") end
            subr_stack_height = subr_stack_height - 1
            b = subr_stack[subr_stack_height + 1]
            clear_stack = 0
        elseif b0 == 0x0E then -- endchar
            stbtt__csctx_close_shape(c)
            return 1
        elseif b0 == 0x0C then -- two-byte escape
            local b1 = stbtt__buf_get8(b)

            if b1 == 0x22 then -- hflex
                if sp < 7 then return STBTT__CSERR("hflex stack") end
                local dx1 = s[0]
                local dx2 = s[1]
                local dy2 = s[2]
                local dx3 = s[3]
                local dx4 = s[4]
                local dx5 = s[5]
                local dx6 = s[6]
                stbtt__csctx_rccurve_to(c, dx1, 0, dx2, dy2, dx3, 0)
                stbtt__csctx_rccurve_to(c, dx4, 0, dx5, -dy2, dx6, 0)
            elseif b1 == 0x23 then -- flex
                if sp < 13 then return STBTT__CSERR("flex stack") end
                local dx1 = s[0]
                local dy1 = s[1]
                local dx2 = s[2]
                local dy2 = s[3]
                local dx3 = s[4]
                local dy3 = s[5]
                local dx4 = s[6]
                local dy4 = s[7]
                local dx5 = s[8]
                local dy5 = s[9]
                local dx6 = s[10]
                local dy6 = s[11]
                -- fd is s[12]
                stbtt__csctx_rccurve_to(c, dx1, dy1, dx2, dy2, dx3, dy3)
                stbtt__csctx_rccurve_to(c, dx4, dy4, dx5, dy5, dx6, dy6)
            elseif b1 == 0x24 then -- hflex1
                if sp < 9 then return STBTT__CSERR("hflex1 stack") end
                local dx1 = s[0]
                local dy1 = s[1]
                local dx2 = s[2]
                local dy2 = s[3]
                local dx3 = s[4]
                local dx4 = s[5]
                local dx5 = s[6]
                local dy5 = s[7]
                local dx6 = s[8]
                stbtt__csctx_rccurve_to(c, dx1, dy1, dx2, dy2, dx3, 0)
                stbtt__csctx_rccurve_to(c, dx4, 0, dx5, dy5, dx6, -(dy1 + dy2 + dy5))
            elseif b1 == 0x25 then -- flex1
                if sp < 11 then return STBTT__CSERR("flex1 stack") end
                local dx1 = s[0]
                local dy1 = s[1]
                local dx2 = s[2]
                local dy2 = s[3]
                local dx3 = s[4]
                local dy3 = s[5]
                local dx4 = s[6]
                local dy4 = s[7]
                local dx5 = s[8]
                local dy5 = s[9]
                local dx6 = s[10]
                local dy6 = s[10]
                local dx = dx1 + dx2 + dx3 + dx4 + dx5
                local dy = dy1 + dy2 + dy3 + dy4 + dy5
                if STBTT_fabs(dx) > STBTT_fabs(dy) then
                    dy6 = -dy
                else
                    dx6 = -dx
                end
                stbtt__csctx_rccurve_to(c, dx1, dy1, dx2, dy2, dx3, dy3)
                stbtt__csctx_rccurve_to(c, dx4, dy4, dx5, dy5, dx6, dy6)
            else
                return STBTT__CSERR("unimplemented")
            end
        else
            if b0 ~= 255 and b0 ~= 28 and b0 < 32 then
                return STBTT__CSERR("reserved operator")
            end

            -- push immediate
            if b0 == 255 then
                f = stbtt__buf_get32(b) / 0x10000
            else
                stbtt__buf_skip(b, -1)
                f = stbtt_int16(stbtt__cff_int(b))
            end
            if sp >= 48 then return STBTT__CSERR("push stack overflow") end
            s[sp] = f
            sp = sp + 1
            clear_stack = 0
        end

        if clear_stack ~= 0 then
            sp = 0
        end
    end

    return STBTT__CSERR("no endchar")
end

function stbtt__GetGlyphShapeT2(info, glyph_index)
    -- runs the charstring twice, once to count and once to output (to avoid realloc)
    local vertices = nil
    local count_ctx = STBTT__CSCTX_INIT(1)
    local output_ctx = STBTT__CSCTX_INIT(0)
    if stbtt__run_charstring(info, glyph_index, count_ctx) ~= 0 then
        vertices = {} for i = 1, count_ctx.num_vertices do vertices[i] = stbtt_vertex() end

        output_ctx.pvertices = vertices
        if stbtt__run_charstring(info, glyph_index, output_ctx) ~= 0 then
            STBTT_assert(output_ctx.num_vertices == count_ctx.num_vertices)
            return output_ctx.num_vertices, vertices
        end
    end

    return 0, vertices
end

function stbtt__GetGlyphInfoT2(info, glyph_index) -- const stbtt_fontinfo *info, int glyph_index, int *x0, int *y0, int *x1, int *y1
    local c = STBTT__CSCTX_INIT(1)
    local r = stbtt__run_charstring(info, glyph_index, c)
    local x0, y0, x1, y1
    x0 = (r ~= 0) and c.min_x or 0
    y0 = (r ~= 0) and c.min_y or 0
    x1 = (r ~= 0) and c.max_x or 0
    y1 = (r ~= 0) and c.max_y or 0
    return ((r ~= 0) and c.num_vertices or 0), x0, y0, x1, y1
end

function stbtt_GetGlyphShape(info, glyph_index)
    if info.cff.size == 0 then
        return stbtt__GetGlyphShapeTT(info, glyph_index)
    else
        return stbtt__GetGlyphShapeT2(info, glyph_index)
    end
end

function stbtt_GetGlyphHMetrics(info, glyph_index) -- const stbtt_fontinfo *info, int glyph_index, int *advanceWidth, int *leftSideBearing
    local numOfLongHorMetrics = ttUSHORT(ptr_add(info.data, info.hhea + 34))

    local advanceWidth, leftSideBearing
    if glyph_index < numOfLongHorMetrics then
        advanceWidth = ttSHORT(ptr_add(info.data, info.hmtx + 4 * glyph_index))
        leftSideBearing = ttSHORT(ptr_add(info.data, info.hmtx + 4 * glyph_index + 2))
    else
        advanceWidth = ttSHORT(ptr_add(info.data, info.hmtx + 4 * (numOfLongHorMetrics - 1)))
        leftSideBearing = ttSHORT(ptr_add(info.data, info.hmtx + 4 * numOfLongHorMetrics + 2 * (glyph_index - numOfLongHorMetrics)))
    end

    return advanceWidth, leftSideBearing
end

local function stbtt_GetKerningTableLength(info)
    local data = ptr_add(info.data, info.kern)

    -- we only look at the first table. it must be 'horizontal' and format 0
    if info.kern == 0 then
        return 0
    end
    if ttUSHORT(ptr_add(data, 2)) < 1 then -- number of tables, need at least 1
        return 0
    end
    if ttUSHORT(ptr_add(data, 8)) ~= 1 then -- horizontal flag must be set in format
        return 0
    end

    return ttUSHORT(ptr_add(data, 10))
end

local function stbtt_GetKerningTable(info, _table, table_length)
    local data = ptr_add(info.data, info.kern)

    -- we only look at the first table. it must be 'horizontal' and format 0
    if info.kern == 0 then
        return 0
    end
    if ttUSHORT(ptr_add(data, 2)) < 1 then -- number of tables, need at least 1
        return 0
    end
    if ttUSHORT(ptr_add(data, 8)) ~= 1 then -- horizontal flag must be set in format
        return 0
    end

    local length = ttUSHORT(ptr_add(data, 10))
    if table_length < length then
        length = table_length
    end

    for k = 0, length - 1 do
        _table[k].glyph1 = ttUSHORT(ptr_add(data, 18 + (k * 6)))
        _table[k].glyph2 = ttUSHORT(ptr_add(data, 20 + (k * 6)))
        _table[k].advance = ttSHORT(ptr_add(data, 22 + (k * 6)))
    end

    return length
end

local function stbtt__GetGlyphKernInfoAdvance(info, glyph1, glyph2)
    local data = ptr_add(info.data, info.kern)

    -- we only look at the first table. it must be 'horizontal' and format 0
    if info.kern == 0 then
        return 0
    end
    if ttUSHORT(ptr_add(data, 2)) < 1 then -- number of tables, need at least 1
        return 0
    end
    if ttUSHORT(ptr_add(data, 8)) ~= 1 then -- horizontal flag must be set in format
        return 0
    end

    local m
    local l = 0
    local r = ttUSHORT(ptr_add(data, 10)) - 1
    local needle = bit.bor(bit.lshift(glyph1, 16), glyph2)
    local straw
    while l <= r do
        m = bit.rshift(l + r, 1)
        straw = ttULONG(ptr_add(data, 18 + (m * 6)))
        if needle < straw then
            r = m - 1
        elseif needle > straw then
            l = m + 1
        else
            return ttSHORT(ptr_add(data, 22 + (m * 6)))
        end
    end
    return 0
end

local function stbtt__GetCoverageIndex(coverageTable, glyph)
    local coverageFormat = ttUSHORT(coverageTable)

    if coverageFormat == 1 then
        local glyphCount = ttUSHORT(ptr_add(coverageTable, 2))

        -- Binary search
        local l = 0
        local r = glyphCount - 1

        while l <= r do
            local glyphArray = ptr_add(coverageTable, 4)
            local m = bit.rshift(l + r, 1)
            local glyphID = ttUSHORT(ptr_add(glyphArray, 2 * m))

            if glyph < glyphID then
                r = m - 1
            elseif glyph > glyphID then
                l = m + 1
            else
                return m
            end
        end
    elseif coverageFormat == 2 then
        local rangeCount = ttUSHORT(ptr_add(coverageTable, 2))
        local rangeArray = ptr_add(coverageTable, 4)

        -- Binary search
        local l = 0
        local r = rangeCount - 1

        while l <= r do
            local m = bit.rshift(l + r, 1)
            local rangeRecord = ptr_add(rangeArray, 6 * m)
            local strawStart = ttUSHORT(rangeRecord)
            local strawEnd = ttUSHORT(ptr_add(rangeRecord, 2))

            if glyph < strawStart then
                r = m - 1
            elseif glyph > strawEnd then
                l = m + 1
            else
                local startCoverageIndex = ttUSHORT(ptr_add(rangeRecord, 4))
                return startCoverageIndex + glyph - strawStart
            end
        end
    end

    return -1 -- unsupported
end

local function stbtt__GetGlyphClass(classDefTable, glyph)
    local classDefFormat = ttUSHORT(classDefTable)

    if classDefFormat == 1 then
        local startGlyphID = ttUSHORT(ptr_add(classDefTable, 2))
        local glyphCount = ttUSHORT(ptr_add(classDefTable, 4))
        local classDef1ValueArray = ptr_add(classDefTable, 6)

        if glyph >= startGlyphID and glyph < startGlyphID + glyphCount then
            return stbtt_int32(ttUSHORT(ptr_add(classDef1ValueArray, 2 * (glyph - startGlyphID))))
        end
    elseif classDefFormat == 2 then
        local classRangeCount = ttUSHORT(ptr_add(classDefTable, 2))
        local classRangeRecords = ptr_add(classDefTable, 4)

        -- Binary search
        local l = 0
        local r = classRangeCount - 1
        while l <= r do
            local m = bit.rshift(l + r, 1)
            local classRangeRecord = ptr_add(classRangeRecords, 6 * m)
            local strawStart = ttUSHORT(classRangeRecord)
            local strawEnd = ttUSHORT(ptr_add(classRangeRecord, 2))

            if glyph < strawStart then
                r = m - 1
            elseif glyph > strawEnd then
                l = m + 1
            else
                return stbtt_int32(ttUSHORT(ptr_add(classRangeRecord, 4)))
            end
        end
    else
        return -1  -- Unsupported definition type
    end

    -- "All glyphs not assigned to a class fall into class 0". (OpenType spec)
    return 0
end

local function stbtt__GetGlyphGPOSInfoAdvance(info, glyph1, glyph2)
    if info.gpos == 0 then return 0 end

    local data = ptr_add(info.data, info.gpos)

    if ttUSHORT(ptr_add(data, 0)) ~= 1 then return 0 end -- Major version 1
    if ttUSHORT(ptr_add(data, 2)) ~= 0 then return 0 end -- Minor version 0

    local lookupListOffset = ttUSHORT(ptr_add(data, 8))
    local lookupList = ptr_add(data, lookupListOffset)
    local lookupCount = ttUSHORT(lookupList)

    for i = 0, lookupCount - 1 do
        local lookupOffset = ttUSHORT(ptr_add(lookupList, 2 + 2 * i))
        local lookupTable = ptr_add(lookupList, lookupOffset)

        local lookupType = ttUSHORT(lookupTable)
        local subTableCount = ttUSHORT(ptr_add(lookupTable, 4))
        local subTableOffsets = ptr_add(lookupTable, 6)
        if lookupType ~= 2 then -- Pair Adjustment Positioning Subtable
            goto outer_continue
        end

        for sti = 0, subTableCount - 1 do
            local subtableOffset = ttUSHORT(ptr_add(subTableOffsets, 2 * sti))
            local _table = ptr_add(lookupTable, subtableOffset)
            local posFormat = ttUSHORT(_table)
            local coverageOffset = ttUSHORT(ptr_add(_table, 2))
            local coverageIndex = stbtt__GetCoverageIndex(ptr_add(_table, coverageOffset), glyph1)
            if coverageIndex == -1 then
                goto inner_continue
            end

            if posFormat == 1 then
                local valueFormat1 = ttUSHORT(ptr_add(_table, 4))
                local valueFormat2 = ttUSHORT(ptr_add(_table, 6))
                if valueFormat1 == 4 and valueFormat2 == 0 then -- Support more formats?
                    local valueRecordPairSizeInBytes = 2
                    local pairSetCount = ttUSHORT(ptr_add(_table, 8))
                    local pairPosOffset = ttUSHORT(ptr_add(_table, 10 + 2 * coverageIndex))
                    local pairValueTable = ptr_add(_table, pairPosOffset)
                    local pairValueCount = ttUSHORT(pairValueTable)
                    local pairValueArray = ptr_add(pairValueTable, 2)

                    if coverageIndex >= pairSetCount then return 0 end

                    local needle = glyph2
                    local r = pairValueCount - 1
                    local l = 0

                    -- Binary search
                    while l <= r do
                        local m = bit.rshift(l + r, 1)
                        local pairValue = ptr_add(pairValueArray, (2 + valueRecordPairSizeInBytes) * m)
                        local secondGlyph = ttUSHORT(pairValue)
                        local straw = secondGlyph
                        if needle < straw then
                            r = m - 1
                        elseif needle > straw then
                            l = m + 1
                        else
                            local xAdvance = ttSHORT(ptr_add(pairValue, 2))
                            return xAdvance
                        end
                    end
                else
                    return 0
                end

            elseif posFormat == 2 then
                local valueFormat1 = ttUSHORT(ptr_add(_table, 4))
                local valueFormat2 = ttUSHORT(ptr_add(_table, 6))
                if valueFormat1 == 4 and valueFormat2 == 0 then -- Support more formats?
                    local classDef1Offset = ttUSHORT(ptr_add(_table, 8))
                    local classDef2Offset = ttUSHORT(ptr_add(_table, 10))
                    local glyph1class = stbtt__GetGlyphClass(ptr_add(_table, classDef1Offset), glyph1)
                    local glyph2class = stbtt__GetGlyphClass(ptr_add(_table, classDef2Offset), glyph2)

                    local class1Count = ttUSHORT(ptr_add(_table, 12))
                    local class2Count = ttUSHORT(ptr_add(_table, 14))
                    local class1Records = ptr_add(_table, 16)

                    if glyph1class < 0 or glyph1class >= class1Count then return 0 end -- malformed
                    if glyph2class < 0 or glyph2class >= class2Count then return 0 end -- malformed

                    local class2Records = ptr_add(class1Records, 2 * (glyph1class * class2Count))
                    local xAdvance = ttSHORT(ptr_add(class2Records, 2 * glyph2class))
                    return xAdvance
                else
                    return 0
                end
            else
                return 0 -- Unsupported position format
            end
            :: inner_continue ::
        end
        :: outer_continue ::
    end

    return 0
end

local function stbtt_GetGlyphKernAdvance(info, g1, g2)
    local xAdvance = 0

    if info.gpos ~= 0 then
        xAdvance = xAdvance + stbtt__GetGlyphGPOSInfoAdvance(info, g1, g2)
    elseif info.kern ~= 0 then
        xAdvance = xAdvance + stbtt__GetGlyphKernInfoAdvance(info, g1, g2)
    end

    return xAdvance
end

local function stbtt_GetCodepointKernAdvance(info, ch1, ch2)
    if info.kern == 0 and info.gpos == 0 then -- if no kerning table, don't waste time looking up both codepoint->glyphs
        return 0
    end
    return stbtt_GetGlyphKernAdvance(info, stbtt_FindGlyphIndex(info, ch1), stbtt_FindGlyphIndex(info, ch2))
end

local function stbtt_GetCodepointHMetrics(info, codepoint) -- const stbtt_fontinfo *info, int codepoint, int *advanceWidth, int *leftSideBearing
    return stbtt_GetGlyphHMetrics(info, stbtt_FindGlyphIndex(info, codepoint))
end

function stbtt_GetFontVMetrics(info) -- const stbtt_fontinfo *info, int *ascent, int *descent, int *lineGap
    local ascent = ttSHORT(ptr_add(info.data, info.hhea + 4))
    local descent = ttSHORT(ptr_add(info.data, info.hhea + 6))
    local lineGap = ttSHORT(ptr_add(info.data, info.hhea + 8))

    return ascent, descent, lineGap
end

--- Unused in ImGui
--
-- function stbtt_GetFontVMetricsOS2(info)
-- end

local function stbtt_GetFontBoundingBox(info)
    local x0 = ttSHORT(ptr_add(info.data, info.head + 36))
    local y0 = ttSHORT(ptr_add(info.data, info.head + 38))
    local x1 = ttSHORT(ptr_add(info.data, info.head + 40))
    local y1 = ttSHORT(ptr_add(info.data, info.head + 42))

    return x0, y0, x1, y1
end

function stbtt_ScaleForPixelHeight(info, height)
    local fheight = ttSHORT(ptr_add(info.data, info.hhea + 4)) - ttSHORT(ptr_add(info.data, info.hhea + 6))
    return height / fheight
end

local function stbtt_ScaleForMappingEmToPixels(info, pixels)
    local unitsPerEm = ttUSHORT(ptr_add(info.data, info.head + 18))
    return pixels / unitsPerEm
end

local function stbtt_FindSVGDoc(info, gl)
    local data = info.data
    local svg_doc_list = data + stbtt__get_svg(info)

    local numEntries = ttUSHORT(svg_doc_list)
    local svg_docs = svg_doc_list + 2

    for i = 0, numEntries - 1 do
        local svg_doc = svg_docs + (12 * i)
        if gl >= ttUSHORT(svg_doc) and gl <= ttUSHORT(ptr_add(svg_doc, 2)) then
            return svg_doc
        end
    end
    return 0
end

--- Unused in ImGui
--
-- local function stbtt_GetGlyphSVG(info, gl)
-- end

--- Unused in ImGui
--
-- local function stbtt_GetCodepointSVG(info, unicode_codepoint)
-- end

------------------------------------
--- antialiasing software rasterizer
--

function stbtt_GetGlyphBitmapBoxSubpixel(font, glyph, scale_x, scale_y, shift_x, shift_y)
    local n, x0, y0, x1, y1 = stbtt_GetGlyphBox(font, glyph)

    local ix0, iy0, ix1, iy1
    if n == 0 then
        -- e.g. space character
        ix0 = 0
        iy0 = 0
        ix1 = 0
        iy1 = 0
    else
        -- move to integral bboxes (treating pixels as little squares, what pixels get touched)?
        ix0 = STBTT_ifloor( x0 * scale_x + shift_x)
        iy0 = STBTT_ifloor(-y1 * scale_y + shift_y)
        ix1 = STBTT_iceil( x1 * scale_x + shift_x)
        iy1 = STBTT_iceil(-y0 * scale_y + shift_y)
    end

    return ix0, iy0, ix1, iy1
end

function stbtt_GetGlyphBitmapBox(font, glyph, scale_x, scale_y)
    return stbtt_GetGlyphBitmapBoxSubpixel(font, glyph, scale_x, scale_y, 0.0, 0.0)
end

local function stbtt_GetCodepointBitmapBoxSubpixel(font, codepoint, scale_x, scale_y, shift_x, shift_y)
    return stbtt_GetGlyphBitmapBoxSubpixel(font, stbtt_FindGlyphIndex(font, codepoint), scale_x, scale_y, shift_x, shift_y)
end

local function stbtt_GetCodepointBitmapBox(font, codepoint, scale_x, scale_y)
    return stbtt_GetCodepointBitmapBoxSubpixel(font, codepoint, scale_x, scale_y, 0.0, 0.0)
end

--------------
--- Rasterizer
--

local function stbtt__handle_clipped_edge(scanline, x, e, x0, y0, x1, y1)
    if y0 == y1 then return end
    STBTT_assert(y0 < y1)
    STBTT_assert(e.sy <= e.ey)

    if y0 > e.ey then return end
    if y1 < e.sy then return end
    if y0 < e.sy then
        x0 = x0 + (x1 - x0) * (e.sy - y0) / (y1 - y0)
        y0 = e.sy
    end
    if y1 > e.ey then
        x1 = x1 + (x1 - x0) * (e.ey - y1) / (y1 - y0)
        y1 = e.ey
    end

    if x0 == x then
        STBTT_assert(x1 <= x + 1)
    elseif x0 == x + 1 then
        STBTT_assert(x1 >= x)
    elseif x0 <= x then
        STBTT_assert(x1 <= x)
    elseif x0 >= x + 1 then
        STBTT_assert(x1 >= x + 1)
    else
        STBTT_assert(x1 >= x and x1 <= x + 1)
    end

    if x0 <= x and x1 <= x then
        scanline[x] = scanline[x] + e.direction * (y1 - y0)
    elseif x0 >= x + 1 and x1 >= x + 1 then
        -- do nothing
    else
        STBTT_assert(x0 >= x and x0 <= x + 1 and x1 >= x and x1 <= x + 1)
        scanline[x] = scanline[x] + e.direction * (y1 - y0) * (1 - ((x0 - x) + (x1 - x)) / 2)
    end
end

local function stbtt__sized_trapezoid_area(height, top_width, bottom_width)
    STBTT_assert(top_width >= 0)
    STBTT_assert(bottom_width >= 0)
    return (top_width + bottom_width) / 2.0 * height
end

local function stbtt__position_trapezoid_area(height, tx0, tx1, bx0, bx1)
    return stbtt__sized_trapezoid_area(height, tx1 - tx0, bx1 - bx0)
end

local function stbtt__sized_triangle_area(height, width)
    return height * width / 2
end

local function stbtt__fill_active_edges_new(scanline, scanline_fill, len, e, y_top)
    local y_bottom = y_top + 1

    while e do
        -- brute force every pixel
        -- compute intersection points with top & bottom
        STBTT_assert(e.ey >= y_top)

        if e.fdx == 0 then
            local x0 = e.fx
            if x0 < len then
                if x0 >= 0 then
                    stbtt__handle_clipped_edge(scanline, trunc(x0), e, x0, y_top, x0, y_bottom)
                    stbtt__handle_clipped_edge(scanline_fill, trunc(x0) + 1, e, x0, y_top, x0, y_bottom)
                else
                    stbtt__handle_clipped_edge(scanline_fill, 0, e, x0, y_top, x0, y_bottom)
                end
            end
        else
            local x0 = e.fx
            local dx = e.fdx
            local xb = x0 + dx
            local x_top, x_bottom
            local sy0, sy1
            local dy = e.fdy
            STBTT_assert(e.sy <= y_bottom and e.ey >= y_top)

            -- compute endpoints of line segment clipped to this scanline (if the
            -- line segment starts on this scanline. x0 is the intersection of the
            -- line with y_top, but that may be off the line segment.
            if e.sy > y_top then
                x_top = x0 + dx * (e.sy - y_top)
                sy0 = e.sy
            else
                x_top = x0
                sy0 = y_top
            end
            if e.ey < y_bottom then
                x_bottom = x0 + dx * (e.ey - y_top)
                sy1 = e.ey
            else
                x_bottom = xb
                sy1 = y_bottom
            end

            if x_top >= 0 and x_bottom >= 0 and x_top < len and x_bottom < len then
                -- from here on, we don't have to range check x values
                if trunc(x_top) == trunc(x_bottom) then
                    -- simple case, only spans one pixel
                    local height
                    local x = trunc(x_top)
                    height = (sy1 - sy0) * e.direction
                    STBTT_assert(x >= 0 and x < len)
                    scanline[x] = scanline[x] + stbtt__position_trapezoid_area(height, x_top, x + 1.0, x_bottom, x + 1.0)
                    scanline_fill[x + 1] = scanline_fill[x + 1] + height -- everything right of this pixel is filled
                else
                    local x, x1, x2
                    local y_crossing, y_final, step, sign, area
                    -- covers 2+ pixels
                    if x_top > x_bottom then
                        -- flip scanline vertically; signed area is the same
                        local t
                        sy0 = y_bottom - (sy0 - y_top)
                        sy1 = y_bottom - (sy1 - y_top)
                        t = sy0
                        sy0 = sy1
                        sy1 = t
                        t = x_bottom
                        x_bottom = x_top
                        x_top = t
                        dx = -dx
                        dy = -dy
                        t = x0
                        x0 = xb
                        xb = t
                    end
                    STBTT_assert(dy >= 0)
                    STBTT_assert(dx >= 0)

                    x1 = trunc(x_top)
                    x2 = trunc(x_bottom)
                    -- compute intersection with y axis at x1+1
                    y_crossing = y_top + dy * (x1 + 1 - x0)

                    -- compute intersection with y axis at x2
                    y_final = y_top + dy * (x2 - x0)

                    --           x1    x_top                            x2    x_bottom
                    --     y_top  +------|-----+------------+------------+--------|---+------------+
                    --            |            |            |            |            |            |
                    --            |            |            |            |            |            |
                    --       sy0  |      Txxxxx|............|............|............|............|
                    -- y_crossing |            *xxxxx.......|............|............|............|
                    --            |            |     xxxxx..|............|............|............|
                    --            |            |     /-   xx*xxxx........|............|............|
                    --            |            | dy <       |    xxxxxx..|............|............|
                    --   y_final  |            |     \-     |          xx*xxx.........|............|
                    --       sy1  |            |            |            |   xxxxxB...|............|
                    --            |            |            |            |            |            |
                    --            |            |            |            |            |            |
                    --  y_bottom  +------------+------------+------------+------------+------------+
                    --
                    -- goal is to measure the area covered by '.' in each pixel

                    -- if x2 is right at the right edge of x1, y_crossing can blow up, github #1057
                    -- TODO: maybe test against sy1 rather than y_bottom?
                    if y_crossing > y_bottom then
                        y_crossing = y_bottom
                    end

                    sign = e.direction

                    -- area of the rectangle covered from sy0..y_crossing
                    area = sign * (y_crossing - sy0)

                    -- area of the triangle (x_top,sy0), (x1+1,sy0), (x1+1,y_crossing)
                    scanline[x1] = scanline[x1] + stbtt__sized_triangle_area(area, x1 + 1 - x_top)

                    -- check if final y_crossing is blown up; no test case for this
                    if y_final > y_bottom then
                        local denom = (x2 - (x1 + 1))
                        y_final = y_bottom
                        if denom ~= 0 then -- [DEAR IMGUI] Avoid div by zero (https://github.com/nothings/stb/issues/1316)
                            dy = (y_final - y_crossing) / denom -- if denom=0, y_final = y_crossing, so y_final <= y_bottom
                        end
                    end

                    -- in second pixel, area covered by line segment found in first pixel
                    -- is always a rectangle 1 wide * the height of that line segment; this
                    -- is exactly what the variable 'area' stores. it also gets a contribution
                    -- from the line segment within it. the THIRD pixel will get the first
                    -- pixel's rectangle contribution, the second pixel's rectangle contribution,
                    -- and its own contribution. the 'own contribution' is the same in every pixel except
                    -- the leftmost and rightmost, a trapezoid that slides down in each pixel.
                    -- the second pixel's contribution to the third pixel will be the
                    -- rectangle 1 wide times the height change in the second pixel, which is dy.

                    step = sign * dy * 1 -- dy is dy/dx, change in y for every 1 change in x,
                    -- which multiplied by 1-pixel-width is how much pixel area changes for each step in x
                    -- so the area advances by 'step' every time

                    for _x = x1 + 1, x2 - 1 do
                        scanline[_x] = scanline[_x] + area + step / 2 -- area of trapezoid is 1*step/2
                        area = area + step
                    end
                    STBTT_assert(STBTT_fabs(area) <= 1.01) -- accumulated error from area += step unless we round step down
                    STBTT_assert(sy1 > y_final - 0.01)

                    -- area covered in the last pixel is the rectangle from all the pixels to the left,
                    -- plus the trapezoid filled by the line segment in this pixel all the way to the right edge
                    scanline[x2] = scanline[x2] + area + sign * stbtt__position_trapezoid_area(sy1 - y_final, x2, x2 + 1.0, x_bottom, x2 + 1.0)

                    -- the rest of the line is filled based on the total height of the line segment in this pixel
                    scanline_fill[x2 + 1] = scanline_fill[x2 + 1] + sign * (sy1 - sy0)
                end
            else
                -- if edge goes outside of box we're drawing, we require
                -- clipping logic. since this does not match the intended use
                -- of this library, we use a different, very slow brute
                -- force implementation
                -- note though that this does happen some of the time because
                -- x_top and x_bottom can be extrapolated at the top & bottom of
                -- the shape and actually lie outside the bounding box
                for x = 0, len - 1 do
                    -- cases:
                    --
                    -- there can be up to two intersections with the pixel. any intersection
                    -- with left or right edges can be handled by splitting into two (or three)
                    -- regions. intersections with top & bottom do not necessitate case-wise logic.
                    --
                    -- the old way of doing this found the intersections with the left & right edges,
                    -- then used some simple logic to produce up to three segments in sorted order
                    -- from top-to-bottom. however, this had a problem: if an x edge was epsilon
                    -- across the x border, then the corresponding y position might not be distinct
                    -- from the other y segment, and it might ignored as an empty segment. to avoid
                    -- that, we need to explicitly produce segments based on x positions.

                    -- rename variables to clearly-defined pairs
                    local y0 = y_top
                    local x1 = x
                    local x2 = x + 1
                    local x3 = xb
                    local y3 = y_bottom

                    -- x = e->x + e->dx * (y-y_top)
                    -- (y-y_top) = (x - e->x) / e->dx
                    -- y = (x - e->x) / e->dx + y_top
                    local y1 = (x - x0) / dx + y_top
                    local y2 = (x + 1 - x0) / dx + y_top

                    if x0 < x1 and x3 > x2 then -- three segments descending down-right
                        stbtt__handle_clipped_edge(scanline, x, e, x0, y0, x1, y1)
                        stbtt__handle_clipped_edge(scanline, x, e, x1, y1, x2, y2)
                        stbtt__handle_clipped_edge(scanline, x, e, x2, y2, x3, y3)
                    elseif x3 < x1 and x0 > x2 then -- three segments descending down-left
                        stbtt__handle_clipped_edge(scanline, x, e, x0, y0, x2, y2)
                        stbtt__handle_clipped_edge(scanline, x, e, x2, y2, x1, y1)
                        stbtt__handle_clipped_edge(scanline, x, e, x1, y1, x3, y3)
                    elseif x0 < x1 and x3 > x1 then -- two segments across x, down-right
                        stbtt__handle_clipped_edge(scanline, x, e, x0, y0, x1, y1)
                        stbtt__handle_clipped_edge(scanline, x, e, x1, y1, x3, y3)
                    elseif x3 < x1 and x0 > x1 then -- two segments across x, down-left
                        stbtt__handle_clipped_edge(scanline, x, e, x0, y0, x1, y1)
                        stbtt__handle_clipped_edge(scanline, x, e, x1, y1, x3, y3)
                    elseif x0 < x2 and x3 > x2 then -- two segments across x+1, down-right
                        stbtt__handle_clipped_edge(scanline, x, e, x0, y0, x2, y2)
                        stbtt__handle_clipped_edge(scanline, x, e, x2, y2, x3, y3)
                    elseif x3 < x2 and x0 > x2 then -- two segments across x+1, down-left
                        stbtt__handle_clipped_edge(scanline, x, e, x0, y0, x2, y2)
                        stbtt__handle_clipped_edge(scanline, x, e, x2, y2, x3, y3)
                    else -- one segment
                        stbtt__handle_clipped_edge(scanline, x, e, x0, y0, x3, y3)
                    end
                end
            end
        end
        e = e.next
    end
end

local function stbtt__rasterize_sorted_edges(result, e, n, vsubsample, off_x, off_y)
    local active = nil

    local scanline = {} -- size = result.w, 0-based
    local scanline2 = {} -- size = result.w + 1, 0-based

    STBTT__NOTUSED(vsubsample)

    local y = off_y
    e[n + 1].y0 = off_y + result.h + 1

    local j = 0
    local p = 1
    while j < result.h do
        -- find center of pixel for this scanline
        local scan_y_top = y + 0.0
        local scan_y_bottom = y + 1.0

        for i = 0, result.w - 1 do scanline[i] = 0 end
        for i = 0, result.w do scanline2[i] = 0 end

        local prev = nil
        local curr = active
        while curr do
            local next = curr.next
            if curr.ey <= scan_y_top then
                if prev then prev.next = next
                else          active   = next end
                curr.direction = 0
            else
                prev = curr
            end
            curr = next
        end

        local edge = e[p]
        while edge.y0 <= scan_y_bottom do
            if edge.y0 ~= edge.y1 then
                local z = stbtt__new_active(edge, off_x, scan_y_top)
                if j == 0 and off_y ~= 0 and z.ey < scan_y_top then
                    z.ey = scan_y_top
                end
                STBTT_assert(z.ey >= scan_y_top)
                z.next = active
                active = z
            end
            p = p + 1
            edge = e[p]
        end

        if active then
            stbtt__fill_active_edges_new(scanline, scanline2, result.w, active, scan_y_top)
        end

        do
            local sum = 0
            for i = 0, result.w - 1 do
                local k
                local m
                sum = sum + scanline2[i]
                k = scanline[i] + sum
                k = STBTT_fabs(k) * 255 + 0.5
                m = trunc(k)
                if m > 255 then m = 255 end
                ptr_index_set(result.pixels, j * result.stride + i, unsigned_char(m))
            end
        end

        step = active
        while step do
            step.fx = step.fx + step.fdx
            step = step.next
        end

        y = y + 1
        j = j + 1
    end
end

local STBTT__COMPARE = function(a, b)
    if a.y0 == nil then return false end -- sentinels on the back
    if b.y0 == nil then return true  end
    return a.y0 < b.y0
end

local function stbtt__sort_edges(p)
    STBTT_sort(p, STBTT__COMPARE)
end

local function stbtt__rasterize(result, pts, wcount, windings, scale_x, scale_y, shift_x, shift_y, off_x, off_y, invert)
    local y_scale_inv = (invert ~= 0) and -scale_y or scale_y
    local e
    local n, m

    local vsubsample = 1 -- STBTT_RASTERIZER_VERSION == 2

    -- now we have to blow out the windings into explicit edge lists
    n = 0
    for i = 1, windings do
        n = n + wcount[i]
    end

    e = {} for i = 1, n + 1 do e[i] = stbtt__edge() end -- add an extra one as a sentinel
    n = 0

    m = 0
    local j
    for i = 1, windings do
        local p = m
        m = m + wcount[i]
        j = wcount[i]
        for k = 1, wcount[i] do
            local a = k
            local b = j
            -- skip the edge if horizontal
            if pts[p + j].y == pts[p + k].y then
                goto inner_continue
            end
            -- add edge from j to k to the list
            n = n + 1
            e[n].invert = 0
            if invert ~= 0 then
                if pts[p + j].y > pts[p + k].y then
                    e[n].invert = 1
                    a = j
                    b = k
                end
            else
                if pts[p + j].y < pts[p + k].y then
                    e[n].invert = 1
                    a = j
                    b = k
                end
            end
            e[n].x0 = pts[p + a].x * scale_x + shift_x
            e[n].y0 = (pts[p + a].y * y_scale_inv + shift_y) * vsubsample
            e[n].x1 = pts[p + b].x * scale_x + shift_x
            e[n].y1 = (pts[p + b].y * y_scale_inv + shift_y) * vsubsample

            :: inner_continue ::
            j = k
        end
    end

    -- now sort the edges by their highest point (should snap to integer, and then by x)
    stbtt__sort_edges(e)

    -- now, traverse the scanlines and find the intersections on each scanline, use xor winding rule
    stbtt__rasterize_sorted_edges(result, e, n, vsubsample, off_x, off_y)
end

local function stbtt__add_point(points, n, x, y)
    if not points then return end -- during first pass, it's unallocated
    points[n + 1].x = x
    points[n + 1].y = y
end

-- tessellate until threshold p is happy... @TODO warped to compensate for non-linear stretching
--- @return integer
local function stbtt__tesselate_curve(points, num_points, x0, y0, x1, y1, x2, y2, objspace_flatness_squared, n)
    -- midpoint
    local mx = (x0 + 2 * x1 + x2) / 4
    local my = (y0 + 2 * y1 + y2) / 4
    -- versus directly drawn line
    local dx = (x0 + x2) / 2 - mx
    local dy = (y0 + y2) / 2 - my

    if n > 16 then -- 65536 segments on one curve better be enough!
        return num_points
    end

    if dx * dx + dy * dy > objspace_flatness_squared then -- half-pixel error allowed... need to be smaller if AA
        num_points = stbtt__tesselate_curve(points, num_points, x0, y0, (x0 + x1) / 2.0, (y0 + y1) / 2.0, mx, my, objspace_flatness_squared, n + 1)
        num_points = stbtt__tesselate_curve(points, num_points, mx, my, (x1 + x2) / 2.0, (y1 + y2) / 2.0, x2, y2, objspace_flatness_squared, n + 1)
    else
        stbtt__add_point(points, num_points, x2, y2)
        num_points = num_points + 1
    end

    return num_points
end

--- @return integer
local function stbtt__tesselate_cubic(points, num_points, x0, y0, x1, y1, x2, y2, x3, y3, objspace_flatness_squared, n)
    -- @TODO this "flatness" calculation is just made-up nonsense that seems to work well enough
    local dx0 = x1 - x0
    local dy0 = y1 - y0
    local dx1 = x2 - x1
    local dy1 = y2 - y1
    local dx2 = x3 - x2
    local dy2 = y3 - y2
    local dx = x3 - x0
    local dy = y3 - y0
    local longlen = STBTT_sqrt(dx0 * dx0 + dy0 * dy0) + STBTT_sqrt(dx1 * dx1 + dy1 * dy1) + STBTT_sqrt(dx2 * dx2 + dy2 * dy2)
    local shortlen = STBTT_sqrt(dx * dx + dy * dy)
    local flatness_squared = longlen * longlen - shortlen * shortlen

    if n > 16 then -- 65536 segments on one curve better be enough!
        return num_points
    end

    if flatness_squared > objspace_flatness_squared then
        local x01 = (x0 + x1) / 2
        local y01 = (y0 + y1) / 2
        local x12 = (x1 + x2) / 2
        local y12 = (y1 + y2) / 2
        local x23 = (x2 + x3) / 2
        local y23 = (y2 + y3) / 2

        local xa = (x01 + x12) / 2
        local ya = (y01 + y12) / 2
        local xb = (x12 + x23) / 2
        local yb = (y12 + y23) / 2

        local mx = (xa + xb) / 2
        local my = (ya + yb) / 2

        num_points = stbtt__tesselate_cubic(points, num_points, x0, y0, x01, y01, xa, ya, mx, my, objspace_flatness_squared, n + 1)
        num_points = stbtt__tesselate_cubic(points, num_points, mx, my, xb, yb, x23, y23, x3, y3, objspace_flatness_squared, n + 1)
    else
        stbtt__add_point(points, num_points, x3, y3)
        num_points = num_points + 1
    end

    return num_points
end

--- @return stbtt__point[], integer?, integer[]?
local function stbtt_FlattenCurves(vertices, num_verts, objspace_flatness)
    local points = {}
    local num_points = 0

    local objspace_flatness_squared = objspace_flatness * objspace_flatness
    local n = 0
    local start = 0

    -- count how many "moves" there are to get the contour count
    for i = 1, num_verts do
        if vertices[i].type == STBTT_vmove then
            n = n + 1
        end
    end

    local num_contours = n
    if n == 0 then return points end

    local contour_lengths = {} -- size = n

    -- make two passes through the points so we don't need to realloc
    for pass = 0, 1 do
        local x, y = 0, 0
        if pass == 1 then
            for i = 1, num_points do points[i] = stbtt__point() end
        end
        num_points = 0
        n = -1
        for i = 1, num_verts do
            if vertices[i].type == STBTT_vmove then
                -- start the next contour
                if n >= 0 then
                    contour_lengths[n + 1] = num_points - start
                end
                n = n + 1
                start = num_points

                x = vertices[i].x
                y = vertices[i].y
                stbtt__add_point(points, num_points, x, y)
                num_points = num_points + 1
            elseif vertices[i].type == STBTT_vline then
                x = vertices[i].x
                y = vertices[i].y
                stbtt__add_point(points, num_points, x, y)
                num_points = num_points + 1
            elseif vertices[i].type == STBTT_vcurve then
                num_points = stbtt__tesselate_curve(points, num_points, x, y,
                                    vertices[i].cx, vertices[i].cy,
                                    vertices[i].x, vertices[i].y,
                                    objspace_flatness_squared, 0)
                x = vertices[i].x
                y = vertices[i].y
            elseif vertices[i].type == STBTT_vcubic then
                num_points = stbtt__tesselate_cubic(points, num_points, x, y,
                                    vertices[i].cx, vertices[i].cy,
                                    vertices[i].cx1, vertices[i].cy1,
                                    vertices[i].x, vertices[i].y,
                                    objspace_flatness_squared, 0)
                x = vertices[i].x
                y = vertices[i].y
            end
        end
        contour_lengths[n + 1] = num_points - start
    end

    return points, num_contours, contour_lengths
end

local function stbtt_Rasterize(result, flatness_in_pixels, vertices, num_verts, scale_x, scale_y, shift_x, shift_y, x_off, y_off, invert)
    local scale = (scale_x > scale_y) and scale_y or scale_x
    local windings
    local winding_count
    local winding_lengths

    windings, winding_count, winding_lengths = stbtt_FlattenCurves(vertices, num_verts, flatness_in_pixels / scale)

    if windings then
        stbtt__rasterize(result, windings, winding_lengths, winding_count, scale_x, scale_y, shift_x, shift_y, x_off, y_off, invert)
    end
end

--- Unused in ImGui
--
-- local function stbtt_GetGlyphBitmapSubpixel(info, scale_x, scale_y, shift_x, shift_y, glyph)
-- end

-- local function stbtt_GetGlyphBitmap(info, scale_x, scale_y, glyph)
--     return stbtt_GetGlyphBitmapSubpixel(info, scale_x, scale_y, 0.0, 0.0, glyph)
-- end

local function stbtt_MakeGlyphBitmapSubpixel(info, output, out_w, out_h, out_stride, scale_x, scale_y, shift_x, shift_y, glyph)
    local num_verts, vertices = stbtt_GetGlyphShape(info, glyph)
    local gbm = stbtt__bitmap()

    local ix0, iy0 = stbtt_GetGlyphBitmapBoxSubpixel(info, glyph, scale_x, scale_y, shift_x, shift_y)
    gbm.pixels = output
    gbm.w = out_w
    gbm.h = out_h
    gbm.stride = out_stride

    if gbm.w ~= 0 and gbm.h ~= 0 then
        stbtt_Rasterize(gbm, 0.35, vertices, num_verts, scale_x, scale_y, shift_x, shift_y, ix0, iy0, 1)
    end
end

local function stbtt_MakeGlyphBitmap(info, output, out_w, out_h, out_stride, scale_x, scale_y, glyph)
    stbtt_MakeGlyphBitmapSubpixel(info, output, out_w, out_h, out_stride, scale_x, scale_y, 0.0, 0.0, glyph)
end

-- local function stbtt_MakeCodepointBitmapSubpixelPrefilter(info, output, out_w, out_h, out_stride, scale_x, scale_y, shift_x, shift_y, oversample_x, oversample_y, codepoint)
--     return stbtt_MakeGlyphBitmapSubpixelPrefilter(info, output, out_w, out_h, out_stride, scale_x, scale_y, shift_x, shift_y, oversample_x, oversample_y, stbtt_FindGlyphIndex(info, codepoint))
-- end

-- local function stbtt_MakeCodepointBitmap(info, output, out_w, out_h, out_stride, scale_x, scale_y, codepoint)
--     stbtt_MakeCodepointBitmapSubpixel(info, output, out_w, out_h, out_stride, scale_x, scale_y, 0.0, 0.0, codepoint)
-- end

------------------------------------------------------------
--- bitmap baking
--- "This is SUPER-CRAPPY packing to keep source code small"
--

--- Unused in ImGui, and involves pointer arithmetics
--
-- local function stbtt_BakeFontBitmap_internal(data, offset, pixel_height, pixels, pw, ph, first_char, num_chars, chardata)
-- end

-- local function stbtt_BakeFontBitmap(data, offset, pixel_height, pixels, pw, ph, first_char, num_chars, chardata)
-- end

--- Unused in ImGui, and involves pointer arithmetics
--
-- local function stbtt_GetBakedQuad(chardata, pw, ph, char_index, xpos, ypos, q, opengl_fillrule)
-- end

-----------------
--- bitmap baking
--

--- Unused in ImGui
--
-- local function stbtt_PackBegin(spc, pixels, pw, ph, stride_in_bytes, padding, alloc_context)
-- end

--- Unused in ImGui
--
-- local function stbtt_PackSetOversampling(spc, h_oversample, v_oversample)
-- end

--- Unused in ImGui
--
-- local function stbtt_PackSetSkipMissingCodepoints(spc, skip)
-- end

local STBTT__OVER_MASK = STBTT_MAX_OVERSAMPLE - 1

local function stbtt__h_prefilter(pixels, w, h, stride_in_bytes, kernel_width)
    local buffer = {} for i = 0, STBTT_MAX_OVERSAMPLE - 1 do buffer[i] = 0 end
    local safe_w = w - kernel_width

    for j = 0, h - 1 do
        local total = 0
        local row_offset = j * stride_in_bytes

        for i = 0, kernel_width - 1 do buffer[i] = 0 end

        for i = 0, safe_w do
            total = total + pixels[row_offset + i] - buffer[bit.band(i, STBTT__OVER_MASK)]
            buffer[bit.band(i + kernel_width, STBTT__OVER_MASK)] = pixels[row_offset + i]
            pixels[row_offset + i] = unsigned_char(total / kernel_width)
        end

        for i = safe_w + 1, w - 1 do
            STBTT_assert(pixels[row_offset + i] == 0)
            total = total - buffer[bit.band(i, STBTT__OVER_MASK)]
            pixels[row_offset + i] = unsigned_char(total / kernel_width)
        end
    end
end

local function stbtt__v_prefilter(pixels, w, h, stride_in_bytes, kernel_width)
    local buffer = {} for i = 0, STBTT_MAX_OVERSAMPLE - 1 do buffer[i] = 0 end
    local safe_h = h - kernel_width

    for j = 0, w - 1 do
        local total = 0
        local col_offset = j

        for i = 0, kernel_width - 1 do buffer[i] = 0 end

        for i = 0, safe_h do
            total = total + pixels[col_offset + i * stride_in_bytes] - buffer[bit.band(i, STBTT__OVER_MASK)]
            buffer[bit.band(i + kernel_width, STBTT__OVER_MASK)] = pixels[col_offset + i * stride_in_bytes]
            pixels[col_offset + i * stride_in_bytes] = unsigned_char(total / kernel_width)
        end

        for i = safe_h + 1, h - 1 do
            STBTT_assert(pixels[col_offset + i * stride_in_bytes] == 0)
            total = total - buffer[bit.band(i, STBTT__OVER_MASK)]
            pixels[col_offset + i * stride_in_bytes] = unsigned_char(total / kernel_width)
        end
    end
end

local function stbtt__oversample_shift(oversample)
    if oversample == 0 then
        return 0.0
    end
    return -(oversample - 1) / (2.0 * oversample)
end

--- Unused in ImGui, and involves pointer arithmetics
--
-- local function stbtt_PackFontRangesGatherRects(spc, info, ranges, num_ranges, rects)
-- end

function stbtt_MakeGlyphBitmapSubpixelPrefilter(info, output, out_w, out_h, out_stride, scale_x, scale_y, shift_x, shift_y, prefilter_x, prefilter_y, glyph)
    stbtt_MakeGlyphBitmapSubpixel(info, output, out_w - (prefilter_x - 1), out_h - (prefilter_y - 1), out_stride, scale_x, scale_y, shift_x, shift_y, glyph)

    if prefilter_x > 1 then
        stbtt__h_prefilter(output, out_w, out_h, out_stride, prefilter_x)
    end

    if prefilter_y > 1 then
        stbtt__v_prefilter(output, out_w, out_h, out_stride, prefilter_y)
    end

    local sub_x, sub_y
    sub_x = stbtt__oversample_shift(prefilter_x)
    sub_y = stbtt__oversample_shift(prefilter_y)
    return sub_x, sub_y
end

--- Unused in ImGui, and involves pointer arithmetics
--
-- function stbtt_PackFontRangesRenderIntoRects(spc, info, ranges, num_ranges, rects)
-- end

--- Unused in ImGui, and involves pointer arithmetics
--
-- function stbtt_PackFontRangesPackRects(spc, rects, num_rects)
-- end

--- Unused in ImGui
--
-- function stbtt_PackFontRanges(spc, fontdata, font_index, ranges, num_ranges)
-- end

--- Unused in ImGui
--
-- function stbtt_PackFontRange(spc, fontdata, font_index, font_size, first_unicode_codepoint_in_range, num_chars_in_range, chardata_for_range)
-- end

function stbtt_GetScaledFontVMetrics(fontdata, index, size)
    local scale
    local info = stbtt_fontinfo()

    stbtt_InitFont(info, fontdata, stbtt_GetFontOffsetForIndex(fontdata, index))
    scale = (size > 0) and stbtt_ScaleForPixelHeight(info, size) or stbtt_ScaleForMappingEmToPixels(info, -size)
    local i_ascent, i_descent, i_lineGap = stbtt_GetFontVMetrics(info)

    local ascent = i_ascent * scale
    local descent = i_descent * scale
    local lineGap = i_lineGap * scale

    return ascent, descent, lineGap
end

function stbtt_GetPackedQuad(chardata, pw, ph, char_index, xpos, ypos, q, align_to_integer)
    local ipw = 1.0 / pw
    local iph = 1.0 / ph
    local b = chardata + char_index

    if align_to_integer ~= 0 then
        local x = STBTT_ifloor((xpos + b.xoff) + 0.5)
        local y = STBTT_ifloor((ypos + b.yoff) + 0.5)
        q.x0 = x
        q.y0 = y
        q.x1 = x + b.xoff2 - b.xoff
        q.y1 = y + b.yoff2 - b.yoff
    else
        q.x0 = xpos + b.xoff
        q.y0 = ypos + b.yoff
        q.x1 = xpos + b.xoff2
        q.y1 = ypos + b.yoff2
    end

    q.s0 = b.x0 * ipw
    q.t0 = b.y0 * iph
    q.s1 = b.x1 * ipw
    q.t1 = b.y1 * iph

    xpos = xpos + b.xadvance

    return xpos
end


-------------------
--- sdf computation
--

-- local STBTT_min = math.min
-- local STBTT_max = math.max

-- local function stbtt__ray_intersect_bezier(orig, ray, q0, q1, q2, hits)
-- end

-- local function equal(a, b)
--     return a[1] == b[1] and a[2] == b[2]
-- end

-- local function stbtt__compute_crossings_x(x, y, nverts, verts)
-- end

-- local function stbtt__cuberoot(x)
-- end

-- local function stbtt__solve_cubic(a, b, c, r)
-- end

-- local function stbtt_GetGlyphSDF(info, scale, glyph, padding, onedge_value, pixel_dist_scale)
-- end

-- local function stbtt_GetCodepointSDF(info, scale, codepoint, padding, onedge_value, pixel_dist_scale)
--     return stbtt_GetGlyphSDF(info, scale, stbtt_FindGlyphIndex(info, codepoint), padding, onedge_value, pixel_dist_scale)
-- end

-----------------------------------------------------
--- font name matching -- recommended not to use this
--

--- NOT IMPLEMENTED

function stbtt_GetFontOffsetForIndex(data, index)
    return stbtt_GetFontOffsetForIndex_internal(data, index)
end

function stbtt_InitFont(info, data, offset)
    return stbtt_InitFont_internal(info, data, offset)
end

return {
    fontinfo = stbtt_fontinfo,

    InitFont                         = stbtt_InitFont,
    FindGlyphIndex                   = stbtt_FindGlyphIndex,
    MakeGlyphBitmapSubpixelPrefilter = stbtt_MakeGlyphBitmapSubpixelPrefilter,
    GetFontVMetrics                  = stbtt_GetFontVMetrics,
    GetGlyphBitmapBox                = stbtt_GetGlyphBitmapBox,
    GetGlyphBitmapBoxSubpixel        = stbtt_GetGlyphBitmapBoxSubpixel,
    GetGlyphHMetrics                 = stbtt_GetGlyphHMetrics,
    GetFontOffsetForIndex            = stbtt_GetFontOffsetForIndex,
    ScaleForPixelHeight              = stbtt_ScaleForPixelHeight
}