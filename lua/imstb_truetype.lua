--------------------------------
--- stb_truetype in GMod Lua5.1!
-- VER 1.26

---------------------------------
--- To mock C arrays and pointers
--
local _Buf = {}
_Buf.__index = _Buf

function _Buf:new(size)
    local t = {data = {}, size = size}
    return setmetatable(t, _Buf)
end

local _View = {}
_View.__index = _View

local function CArray(size)
    local buf = _Buf:new(size)
    return setmetatable({buf = buf, off = 0}, _View)
end

function _View:top() self.off = 0 return self end
function _View:offset() return self.off end
function _View:size() return self.buf.size end

local function check_bounds(v, delta)
    local no = v.off + delta
    if no < 0 or no >= v.buf.size then error("pointer arithmetic out of bounds", 3) end
end

function _View.__add(lhs, rhs)
    local v, d
    if type(lhs) == "number" and getmetatable(rhs) == _View then v, d = rhs, lhs
    elseif getmetatable(lhs) == _View and type(rhs) == "number" then v, d = lhs, rhs
    else error("bad operand to + (need View + number or number + View)") end
    check_bounds(v, d)
    return setmetatable({ buf = v.buf, off = v.off + d }, _View)
end

function _View.__sub(lhs, rhs)
    if getmetatable(lhs) == _View and type(rhs) == "number" then
        check_bounds(lhs, -rhs); return setmetatable({ buf = lhs.buf, off = lhs.off - rhs }, _View)
    end
    if getmetatable(lhs) == _View and getmetatable(rhs) == _View then
        if lhs.buf ~= rhs.buf then error("cannot subtract pointers to different buffers") end
        return lhs.off - rhs.off
    end
    error("bad operand to - (need View - number or View - View)")
end

function _View:inc() check_bounds(self, 1)  self.off = self.off + 1 return self end
function _View:dec() check_bounds(self, -1) self.off = self.off - 1 return self end

function _View.__eq(lhs, rhs)
    return getmetatable(lhs) == _View and getmetatable(rhs) == _View and lhs.buf == rhs.buf and lhs.off == rhs.off
end

local function view_lt(lhs, rhs)
    if getmetatable(lhs) ~= _View or getmetatable(rhs) ~= _View then
        error("bad operand to comparison", 2)
    end
    if lhs.buf ~= rhs.buf then error("cannot compare pointers to different buffers") end
    return lhs.off < rhs.off
end
function _View.__lt(lhs, rhs) return view_lt(lhs, rhs) end
function _View.__le(lhs, rhs)
    return lhs == rhs or view_lt(lhs, rhs)
end

function _View.__gt(lhs, rhs) return view_lt(rhs, lhs) end
function _View.__ge(lhs, rhs)
    return lhs == rhs or view_lt(rhs, lhs)
end

local function abs2lua(o) return o + 1 end

function _View:deref()
    local k = abs2lua(self.off)
    if k < 1 or k > self.buf.size then error("dereference out of bounds", 2) end
    return self.buf.data[k]
end
function _View:set_deref(v)
    local k = abs2lua(self.off)
    if k < 1 or k > self.buf.size then error("dereference out of bounds", 2) end
    self.buf.data[k] = v
end

function _View.__index(self, key)
    if type(key) == "number" then
        if key < 0 then error("negative index forbidden, use (ptr + n):deref()", 2) end
        local abs = self.off + key
        local k = abs2lua(abs)
        if k < 1 or k > self.buf.size then
            error("index " .. key .. " out of bounds", 2)
        end
        return self.buf.data[k]
    else
        error("invalid key type")
    end
    return _View[key]
end

function _View.__newindex(self, key, value)
    if type(key) == "number" then
        if key < 0 then error("negative index forbidden, use (ptr + n):set_deref(value)", 2) end
        local abs = self.off + key
        local k = abs2lua(abs)
        if k < 1 or k > self.buf.size then
            error("index " .. key .. " out of bounds", 2)
        end
        self.buf.data[k] = value
    else
        error("invalid key type")
    end
end

function _View:__tostring()
    return string.format("View(%p, off=%d/%d)", self.buf, self.off, self.buf.size)
end

local function CArrayInit(size, init) -- XXX: size == #init!
    if not size or size <= 0 then error("Bad CArray init size!") end

    local arr = CArray(size)
    if type(init) == "table" then
        for i = 0, size - 1 do (arr + i):set_deref(init[i + 1]) end
    elseif type(init) == "function" then
        for i = 0, size - 1 do (arr + i):set_deref(init()) end
    end
    return arr
end








local STBTT_PLATFORM_ID = {
    UNICODE   = 0,
    MAC       = 1,
    ISO       = 2,
    MICROSOFT = 3,
}

--- encodingID for STBTT_PLATFORM_ID_MICROSOFT
local STBTT_MS_EID = {
    SYMBOL       = 0,
    UNICODE_BMP  = 1,
    SHIFTJIS     = 2,
    UNICODE_FULL = 10
}

local STBTT_vmove = {
    vmove  = 1,
    vline  = 2,
    vcurve = 3,
    vcubic = 4
}

local STBTT_assert = assert
local STBTT_sqrt = math.sqrt
local STBTT_fabs = math.abs
local floor = math.floor
local STBTT_ifloor = floor
local STBTT_iceil = math.ceil

local function STBTT_memcpy(dst, src, size)
    for i = 0, size - 1 do
        dst[i] = src[i]
    end
end

local lshift = bit.lshift
local rshift = bit.rshift
local bor    = bit.bor
local band   = bit.band
local str_byte = string.byte



local function stbtt_int16(value)
    return band(value, 0xFFFF) - (band(value, 0x8000) ~= 0 and 0x10000 or 0)
end


local _stbtt__buf = {}
_stbtt__buf.__index = _stbtt__buf

-- Usage is 0 based, internal is 1 based since Lua arrays start at 1 :(
local function stbtt__buf()
    return setmetatable({
        data = nil, -- byte array
        cursor = nil, -- >= 0
        size = nil
    }, _stbtt__buf)
end








local _stbtt_fontinfo = {}
_stbtt_fontinfo.__index = _stbtt_fontinfo

local function stbtt_fontinfo()
    return setmetatable({
        userdata  = nil,
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
    }, _stbtt_fontinfo)
end




local _stbtt_vertex = {}
_stbtt_vertex.__index = _stbtt_vertex

local function stbtt_vertex()
    return setmetatable({
        x = nil,
        y = nil,
        cx = nil,
        cy = nil,
        cx1 = nil,
        cy1 = nil,
        type = nil,
        padding = nil
    }, _stbtt_vertex)
end

local _stbtt__csctx = {}
_stbtt__csctx.__index = _stbtt__csctx

local function stbtt__csctx()
    return setmetatable({
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
    }, _stbtt__csctx)
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


local _stbtt_kerningentry = {}
_stbtt_kerningentry.__index = _stbtt_kerningentry

local function stbtt_kerningentry()
    return setmetatable({
        glyph1 = nil,
        glyph2 = nil,
        advance = nil
    }, _stbtt_kerningentry)
end




local _stbtt__edge = {}
_stbtt__edge.__index = _stbtt__edge

local function stbtt__edge()
    return setmetatable({
        x0 = nil,
        y0 = nil,
        x1 = nil,
        y1 = nil,
        invert = nil
    }, _stbtt__edge)
end

--- XXX: STBTT_RASTERIZER_VERSION == 2
local _stbtt__active_edge = {}
_stbtt__active_edge.__index = _stbtt__active_edge

local function stbtt__active_edge()
    return setmetatable({
        next = nil,
        fx = nil,
        fdx = nil,
        fdy = nil,
        direction = nil,
        sy = nil,
        ey = nil
    }, _stbtt__active_edge)
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


----------------------------------------------
--- stbtt__buf helpers to parse data from file
--
local function stbtt__buf_get8(b)
    if b.cursor >= b.size then return 0 end
    local result = b.data[b.cursor + 1]
    b.cursor = b.cursor + 1
    return result
end

local function stbtt__buf_peek8(b)
    if b.cursor >= b.size then return 0 end
    return b.data[b.cursor + 1]
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
        v = bor(lshift(v, 8), stbtt__buf_get8(b))
    end
    return v
end

local function stbtt__new_buf(p, size)
    local r = stbtt__buf()
    STBTT_assert(size < 0x40000000)
    r.data = p
    r.size = size
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
    if b0 >= 32 and b0 <= 256 then return b0 - 139
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
            if (band(v, 0xF) == 0xF or rshift(v, 4) == 0xF) then
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
        if op == 12 then op = bor(stbtt__buf_get8(b), 0x100) end
        if op == key then return stbtt__buf_range(b, start, _end - start) end
    end
    return stbtt__buf_range(b, 0, 0)
end

local function stbtt__dict_get_ints(b, key, outcount, out)
    local operands = stbtt__dict_get(b, key)
    for i = 0, outcount - 1 do
        if operands.cursor >= operands.size then break end
        out[i] = stbtt__cff_int(operands)
    end
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
local function ttUSHORT(p) return p[0] * 256 + p[1] end
local function ttSHORT(p) return p[0] * 256 + p[1] end
local function ttULONG(p) return lshift(p[0], 24) + lshift(p[1], 16) + lshift(p[2], 8) + p[3] end
local function ttLONG(p) return lshift(p[0], 24) + lshift(p[1], 16) + lshift(p[2], 8) + p[3] end

local ttFixed = ttLONG
local function ttBYTE(p) return p:deref() end
local function ttCHAR(p) return p:deref() end

local function stbtt_tag4(p, c0, c1, c2, c3) return p[0] == c0 and p[1] == c1 and p[2] == c2 and p[3] == c3 end
local function stbtt_tag(p, str) return stbtt_tag4(p, str_byte(str, 1, 4)) end

local function stbtt__isfont(font)
    if stbtt_tag4(font, str_byte("1"), 0, 0, 0) then return true end
    if stbtt_tag(font, "typ1") then return true end
    if stbtt_tag(font, "OTTO") then return true end
    if stbtt_tag4(font, 0, 1, 0, 0) then return true end
    if stbtt_tag(font, "true") then return true end
    return false
end

local function stbtt__find_table(data, font_start, tag)
    local num_tables = ttUSHORT(data + font_start + 4)
    local tabledir = font_start + 12
    for i = 0, num_tables - 1 do
        local loc = tabledir + i * 16
        if stbtt_tag(data + loc + 0, tag) then
            return ttULONG(data + loc + 8)
        end
    end
    return 0
end

local function stbtt_GetFontOffsetForIndex_internal(font_collection, index)
    if stbtt__isfont(font_collection) then
        if index == 0 then return 0 else return -1 end
    end

    if stbtt_tag(font_collection, "ttcf") then
        if ttULONG(font_collection + 4) == 0x00010000 or ttULONG(font_collection + 4) == 0x00020000 then
            local n = ttULONG(font_collection + 8)
            if index >= n then
                return -1
            end
            return ttULONG(font_collection + 12 + index * 4)
        end
    end

    return -1
end

local function stbtt_GetNumberOfFonts_internal(font_collection)
    if stbtt__isfont(font_collection) then
        return 1
    end

    if stbtt_tag(font_collection, "ttcf") then
        if ttULONG(font_collection + 4) == 0x00010000 or ttULONG(font_collection + 4) == 0x00020000 then
            return ttULONG(font_collection + 8)
        end
    end

    return 0
end

local function stbtt__get_subrs(cff, fontdict) -- stbtt__buf cff, stbtt__buf fontdict
    local subrsoff = CArrayInit(1, {0})
    local private_loc = CArrayInit(2, {0, 0})
    stbtt__dict_get_ints(fontdict, 18, 2, private_loc)
    if (private_loc[1] == 0 or private_loc[0] == 0) then
        return stbtt__new_buf(nil, 0)
    end
    local pdict = stbtt__buf_range(cff, private_loc[1], private_loc[0])
    stbtt__dict_get_ints(pdict, 19, 1, subrsoff) -- get a single int into subrsoff!
    if subrsoff[0] == 0 then
        return stbtt__new_buf(nil, 0)
    end
    stbtt__buf_seek(cff, private_loc[1] + subrsoff[0])
    return stbtt__cff_get_index(cff)
end

local function stbtt__get_svg(info) -- stbtt_fontinfo *info
    local t
    if info.svg < 0 then
        t = stbtt__find_table(info.data, info.fontstart, "SVG ")
        if t ~= 0 then
            local offset = ttULONG(info.data + t + 2)
            info.svg = t + offset
        else
            info.svg = 0
        end
    end
    return info.svg
end

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
        return 0
    end
    if info.glyf ~= 0 then
        if info.loca == 0 then
            return 0
        end
    else
        local cff = stbtt__find_table(data, fontstart, "CFF ")
        if cff == 0 then
            return 0
        end

        info.fontdicts = stbtt__new_buf(nil, 0)
        info.fdselect = stbtt__new_buf(nil, 0)

        info.cff = stbtt__new_buf(data + cff, 2 * 1024 * 1024) -- TODO: i didn't solve the og todo, and further decreased it. 2MB
        local b = info.cff

        -- read the header
        stbtt__buf_skip(b, 2)
        stbtt__buf_seek(b, stbtt__buf_get8(b))

        -- @TODO the name INDEX could list multiple fonts,
        -- but we just use the first one.
        stbtt__cff_get_index(b) -- name INDEX
        local topdictidx = stbtt__cff_get_index(b)
        local topdict = stbtt__cff_index_get(topdictidx, 0)
        stbtt__cff_get_index(b) -- string INDEX
        info.gsubrs = stbtt__cff_get_index(b)

        local charstrings = CArrayInit(1, {0})
        local cstype      = CArrayInit(1, {2})
        local fdarrayoff  = CArrayInit(1, {0})
        local fdselectoff = CArrayInit(1, {0})
        stbtt__dict_get_ints(topdict, 17, 1, charstrings)
        stbtt__dict_get_ints(topdict, bor(0x100, 6), 1, cstype)
        stbtt__dict_get_ints(topdict, bor(0x100, 36), 1, fdarrayoff)
        stbtt__dict_get_ints(topdict, bor(0x100, 37), 1, fdselectoff)
        info.subrs = stbtt__get_subrs(b, topdict)

        if cstype[0] ~= 2 then
            return 0
        end
        if charstrings[0] == 0 then
            return 0
        end

        if fdarrayoff[0] ~= 0 then
            if fdselectoff[0] == 0 then
                return 0
            end

            stbtt__buf_seek(b, fdarrayoff[0])
            info.fontdicts = stbtt__cff_get_index(b)
            info.fdselect = stbtt__buf_range(b, fdselectoff[0], b.size - fdselectoff[0])
        end

        stbtt__buf_seek(b, charstrings[0])
        info.charstrings = stbtt__cff_get_index(b)
    end

    local t = stbtt__find_table(data, fontstart, "maxp")
    if t ~= 0 then
        info.numGlyphs = ttUSHORT(data + t + 4)
    else
        info.numGlyphs = 0xffff
    end

    info.svg = -1

    numTables = ttUSHORT(data + cmap + 2)
    info.index_map = 0
    for i = 0, numTables - 1 do
        local encoding_record = cmap + 4 + 8 * i
        local platform_id = ttUSHORT(data + encoding_record)

        if platform_id == STBTT_PLATFORM_ID.MICROSOFT then
            local ms_eid = ttUSHORT(data + encoding_record + 2)

            if ms_eid == STBTT_MS_EID.UNICODE_BMP or ms_eid == STBTT_MS_EID.UNICODE_FULL then
                info.index_map = cmap + ttULONG(data + encoding_record + 4)
            end
        elseif platform_id == STBTT_PLATFORM_ID.UNICODE then
            info.index_map = cmap + ttULONG(data + encoding_record + 4)
        end
    end
    if info.index_map == 0 then
        return 0
    end

    info.indexToLocFormat = ttSHORT(data + info.head + 50)
    return 1
end

local function stbtt_FindGlyphIndex(info, unicode_codepoint)
    local data = info.data
    local index_map = info.index_map

    local format = ttUSHORT(data + index_map + 0)
    if format == 0 then
        local bytes = ttUSHORT(data + index_map + 2)
        if unicode_codepoint < bytes - 6 then
            return ttBYTE(data + index_map + 6 + unicode_codepoint)
        end
        return 0
    elseif format == 6 then
        local first = ttUSHORT(data + index_map + 6)
        local count = ttUSHORT(data + index_map + 8)
        if unicode_codepoint >= first and unicode_codepoint < first + count then
            return ttUSHORT(data + index_map + 10 + (unicode_codepoint - first) * 2)
        end
        return 0
    elseif format == 2 then
        STBTT_assert(false) -- TODO: high-byte mapping for japanese/chinese/korean
        return 0
    elseif format == 4 then
        local segcount = rshift(ttUSHORT(data + index_map + 6), 1)
        local searchRange = rshift(ttUSHORT(data + index_map + 8), 1)
        local entrySelector = ttUSHORT(data + index_map + 10)
        local rangeShift = rshift(ttUSHORT(data + index_map + 12), 1)

        local endCount = index_map + 14
        local search = endCount

        if unicode_codepoint > 0xffff then
            return 0
        end

        if unicode_codepoint >= ttUSHORT(data + search + searchRange * 2) then
            search = search + searchRange * 2
        end

        search = search - 2
        while entrySelector ~= 0 do
            searchRange = rshift(searchRange, 1)
            local _end = ttUSHORT(data + search + searchRange * 2)
            if unicode_codepoint > _end then
                search = search + searchRange * 2
            end
            entrySelector = entrySelector - 1
        end
        search = search + 2

        do
            local item = rshift(search - endCount, 1)

            local start = ttUSHORT(data + index_map + 14 + segcount * 2 + 2 + 2 * item)
            local last = ttUSHORT(data + endCount + 2 * item)
            if unicode_codepoint < start or unicode_codepoint > last then
                return 0
            end

            local offset = ttUSHORT(data + index_map + 14 + segcount * 6 + 2 + 2 * item)
            if offset == 0 then
                return unicode_codepoint + ttSHORT(data + index_map + 14 + segcount * 4 + 2 + 2 * item)
            end

            return ttUSHORT(data + offset + (unicode_codepoint - start) * 2 + index_map + 14 + segcount * 6 + 2 + 2 * item)
        end
    elseif format == 12 or format == 13 then
        local ngroups = ttULONG(data + index_map + 12)
        local low = 0
        local high = ngroups
        while low < high do
            local mid = low + rshift(high - low, 1)
            local start_char = ttULONG(data + index_map + 16 + mid * 12)
            local end_char = ttULONG(data + index_map + 16 + mid * 12 + 4)
            if unicode_codepoint < start_char then
                high = mid
            elseif unicode_codepoint > end_char then
                low = mid + 1
            else
                local start_glyph = ttULONG(data + index_map + 16 + mid * 12 + 8)
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
    v.x = x
    v.y = y
    v.cx = cx
    v.cy = cy
end

local function stbtt__GetGlyfOffset(info, glyph_index)
    STBTT_assert(info.cff.size ~= 0)

    if glyph_index >= info.numGlyphs then return -1 end
    if info.indexToLocFormat >= 2 then return -1 end

    local g1, g2
    if info.indexToLocFormat == 0 then
        g1 = info.glyph + ttUSHORT(info.data + info.loca + glyph_index * 2) * 2
        g2 = info.glyph + ttUSHORT(info.data + info.loca + glyph_index * 2 + 2) * 2
    else
        g1 = info.glyph + ttULONG(info.data + info.loca + glyph_index * 4)
        g2 = info.glyph + ttULONG(info.data + info.loca + glyph_index * 4 + 4)
    end

    if g1 == g2 then return -1 else return g1 end
end

local stbtt__GetGlyphInfoT2

local function stbtt_GetGlyphBox(info, glyph_index, x0, y0, x1, y1)
    if info.cff.size ~= 0 then
        stbtt__GetGlyphInfoT2(info, glyph_index, x0, y0, x1, y1)
    else
        local g = stbtt__GetGlyfOffset(info, glyph_index)
        if g < 0 then return 0 end

        if x0 then x0:set_deref(ttSHORT(info.data + g + 2)) end
        if y0 then y0:set_deref(ttSHORT(info.data + g + 4)) end
        if x1 then x1:set_deref(ttSHORT(info.data + g + 6)) end
        if y1 then y1:set_deref(ttSHORT(info.data + g + 8)) end
    end
    return 1
end

local function stbtt_GetCodepointBox(info, codepoint, x0, y0, x1, y1)
    return stbtt_GetGlyphBox(info, stbtt_FindGlyphIndex(info, codepoint), x0, y0, x1, y1)
end

local function stbtt_IsGlyphEmpty(info, glyph_index)
    if info.cff.size ~= 0 then
        return stbtt__GetGlyphInfoT2(info, glyph_index, nil, nil, nil, nil) == 0
    end

    local g = stbtt__GetGlyfOffset(info, glyph_index)
    if g < 0 then return 1 end

    local numberOfContours = ttSHORT(info.data + g)
    return numberOfContours == 0
end

local function stbtt__close_shape(vertices, num_vertices, was_off, start_off, sx, sy, scx, scy, cx, cy)
    if start_off ~= 0 then
        if was_off ~= 0 then
            stbtt_setvertex(vertices[num_vertices], STBTT_vmove.vcurve, rshift(cx + scx, 1), rshift(cy + scy, 1), cx, cy)
            num_vertices = num_vertices + 1
        end
        stbtt_setvertex(vertices[num_vertices], STBTT_vmove.vcurve, sx, sy, scx, scy)
        num_vertices = num_vertices + 1
    else
        if was_off ~= 0 then
            stbtt_setvertex(vertices[num_vertices], STBTT_vmove.vcurve, sx, sy, cx, cy)
            num_vertices = num_vertices + 1
        else
            stbtt_setvertex(vertices[num_vertices], STBTT_vmove.vline, sx, sy, 0, 0)
            num_vertices = num_vertices + 1
        end
    end
    return num_vertices
end

local stbtt_GetGlyphShape
local stbtt__GetGlyphShapeT2

local function stbtt__GetGlyphShapeTT(info, glyph_index, pvertices) -- const stbtt_fontinfo *info, int glyph_index, stbtt_vertex **pvertices
    local data = info.data
    local num_vertices

    local vertices = nil

    local g = stbtt__GetGlyfOffset(info, glyph_index)

    pvertices:set_deref(nil)

    local numberOfContours = ttSHORT(data + g)

    if numberOfContours > 0 then
        local endPtsOfContours = data + g + 10
        local ins = ttUSHORT(data + g + 10 + numberOfContours * 2)
        local points = data + g + 10 + numberOfContours * 2 + 2 + ins

        local n = 1 + ttUSHORT(endPtsOfContours + numberOfContours * 2 - 2)
        local m = n + 2 * numberOfContours

        vertices = CArrayInit(m, stbtt_vertex)

        local j = 0
        local was_off = 0
        local start_off = 0
        local next_move = 0
        local flagcount = 0

        local off = m - n

        -- first load flags
        local flags = 0
        for i = 0, n - 1 do
            if flagcount == 0 then
                flags = (points + 0):deref()
                points:inc()

                if band(flags, 8) ~= 0 then
                    flagcount = (points + 0):deref()
                    points:inc()
                end
            else
                flagcount = flagcount - 1
            end

            vertices[off + i].type = flags
        end

        -- now load x coordinates
        local x = 0
        for i = 0, n - 1 do
            flags = vertices[off + i].type
            if band(flags, 2) ~= 0 then
                local dx = (points + 0):deref()
                points:inc()
                if band(flags, 16) ~= 0 then
                    x = x + dx
                else
                    x = x - dx
                end
            else
                if band(flags, 16) == 0 then
                    x = x + points[0] * 256 + points[1]
                    points = points + 2
                end
            end

            vertices[off + i].x = x
        end

        -- now load y coordinates
        local y = 0
        for i = 0, n - 1 do
            flags = vertices[off + i].type
            if band(flags, 4) ~= 0 then
                local dy = (points + 0):deref()
                points:inc()
                if band(flags, 32) ~= 0 then
                    y = y + dy
                else
                    y = y - dy
                end
            else
                if band(flags, 32) == 0 then
                    y = y + points[0] * 256 + points[1]
                    points = points + 2
                end
            end

            vertices[off + i].y = y
        end

        -- now convert them to our format
        num_vertices = 0
        local sx, sy, cx, cy, scx, scy = 0, 0, 0, 0, 0, 0
        for i = 0, n - 1 do
            flags = vertices[off + i].type
            x = vertices[off + i].x
            y = vertices[off + i].y

            if next_move == i then
                if i ~= 0 then
                    num_vertices = stbtt__close_shape(vertices, num_vertices, was_off, start_off, sx, sy, scx, scy, cx, cy)
                end

                -- now start the new one
                start_off = (band(flags, 1) == 0)
                if start_off then
                    scx = x
                    scy = y
                    if band(vertices[off + i + 1].type, 1) == 0 then
                        sx = rshift(x + vertices[off + i + 1].x, 1)
                        sy = rshift(y + vertices[off + i + 1].y, 1)
                    else
                        sx = vertices[off + i + 1].x
                        sy = vertices[off + i + 1].y
                        i = i + 1
                    end
                else
                    sx = x
                    sy = y
                end
                stbtt_setvertex(vertices[num_vertices], STBTT_vmove.vmove, sx, sy, 0, 0)
                num_vertices = num_vertices + 1
                was_off = 0
                next_move = 1 + ttUSHORT(endPtsOfContours + j * 2)
                j = j + 1
            else
                if band(flags, 1) == 0 then
                    if was_off ~= 0 then
                        stbtt_setvertex(vertices[num_vertices], STBTT_vmove.vcurve, rshift(cx + x, 1), rshift(cy + y, 1), cx, cy)
                        num_vertices = num_vertices + 1
                    end

                    cx = x
                    cy = y
                    was_off = 1
                else
                    if was_off ~= 0 then
                        stbtt_setvertex(vertices[num_vertices], STBTT_vmove.vcurve, x, y, cx, cy)
                        num_vertices = num_vertices + 1
                    else
                        stbtt_setvertex(vertices[num_vertices], STBTT_vmove.vline, x, y, 0, 0)
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

            local mtx = {1, 0, 0, 1, 0, 0}
            local m, n

            flags = ttUSHORT(comp) comp = comp + 2
            gidx = ttUSHORT(comp) comp = comp + 2

            if band(flags, 2) ~= 0 then
                if band(flags, 1) ~= 0 then
                    mtx[4] = ttSHORT(comp) comp = comp + 2
                    mtx[5] = ttSHORT(comp) comp = comp + 2
                else
                    mtx[4] = ttCHAR(comp) comp = comp + 1
                    mtx[5] = ttCHAR(comp) comp = comp + 1
                end
            else
                -- TODO: handle matching point
                STBTT_assert(false)
            end

            if band(flags, lshift(1, 3)) ~= 0 then -- WE_HAVE_A_SCALE
                mtx[3] = ttSHORT(comp) / 16384.0
                mtx[0] = mtx[3]
                comp = comp + 2

                mtx[2] = 0
                mtx[1] = mtx[2]
            elseif band(flags, lshift(1, 6)) ~= 0 then -- WE_HAVE_AN_X_AND_YSCALE
                mtx[0] = ttSHORT(comp) / 16384.0
                comp = comp + 2

                mtx[2] = 0
                mtx[1] = mtx[2]

                mtx[3] = ttSHORT(comp) / 16384.0
                comp = comp + 2
            elseif band(flags, lshift(1, 7)) ~= 0 then -- WE_HAVE_A_TWO_BY_TWO
                mtx[0] = ttSHORT(comp) / 16384.0 comp = comp + 2
                mtx[1] = ttSHORT(comp) / 16384.0 comp = comp + 2
                mtx[2] = ttSHORT(comp) / 16384.0 comp = comp + 2
                mtx[3] = ttSHORT(comp) / 16384.0 comp = comp + 2
            end

            m = STBTT_sqrt(mtx[0] * mtx[0] + mtx[1] * mtx[1])
            n = STBTT_sqrt(mtx[2] * mtx[2] + mtx[3] * mtx[3])

            local comp_verts = {}
            comp_num_vertices = stbtt_GetGlyphShape(info, gidx, comp_verts)
            if comp_num_vertices > 0 then
                for i = 0, comp_num_vertices - 1 do
                    local v = comp_verts[i]
                    local x = v.x
                    local y = v.y
                    v.x = m * (mtx[0] * x + mtx[2] * y + mtx[4])
                    v.y = n * (mtx[1] * x + mtx[3] * y + mtx[5])
                    x = v.cx
                    y = v.cy
                    v.cx = m * (mtx[0] * x + mtx[2] * y + mtx[4])
                    v.cy = n * (mtx[1] * x + mtx[3] * y + mtx[5])
                end

                -- append vertices
                local tmp = CArrayInit(num_vertices + comp_num_vertices, stbtt_vertex)
                if num_vertices > 0 and vertices then
                    STBTT_memcpy(tmp, vertices, num_vertices)
                end
                STBTT_memcpy(tmp + num_vertices, comp_verts, comp_num_vertices)
                vertices = tmp

                num_vertices = num_vertices + comp_num_vertices
            end

            more = band(flags, lshift(1, 5))
        end
    end

    pvertices:set_deref(vertices)
    return num_vertices
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
        if _type == STBTT_vmove.vcubic then
            stbtt__track_vertex(c, cx, cy)
            stbtt__track_vertex(c, cx1, cy1)
        end
    else
        stbtt_setvertex(c.pvertices[c.num_vertices], _type, x, y, cx, cy)
        c.pvertices[c.num_vertices].cx1 = stbtt_int16(cx1)
        c.pvertices[c.num_vertices].cy1 = stbtt_int16(cy1)
    end
end

local function stbtt__csctx_close_shape(ctx)
    if ctx.first_x ~= ctx.x or ctx.first_y ~= ctx.y then
        stbtt__csctx_v(ctx, STBTT_vmove.vline, floor(ctx.first_x), floor(ctx.first_y), 0, 0, 0, 0)
    end
end

local function stbtt__csctx_rmove_to(ctx, dx, dy)
    stbtt__csctx_close_shape(ctx)
    ctx.x = ctx.x + dx
    ctx.first_x = ctx.x
    ctx.y = ctx.y + dy
    ctx.first_y = ctx.y
    stbtt__csctx_v(ctx, STBTT_vmove.vmove, floor(ctx.x), floor(ctx.y), 0, 0, 0, 0)
end

local function stbtt__csctx_rline_to(ctx, dx, dy)
    ctx.x = ctx.x + dx
    ctx.y = ctx.y + dy
    stbtt__csctx_v(ctx, STBTT_vmove.vline, floor(ctx.x), floor(ctx.y), 0, 0, 0, 0)
end

local function stbtt__csctx_rccurve_to(ctx, dx1, dy1, dx2, dy2, dx3, dy3)
    local cx1 = ctx.x + dx1
    local cy1 = ctx.y + dy1
    local cx2 = cx1 + dx2
    local cy2 = cy1 + dy2
    ctx.x = cx2 + dx3
    ctx.y = cy2 + dy3
    stbtt__csctx_v(ctx, STBTT_vmove.vcubic, floor(ctx.x), floor(ctx.y), floor(cx1), floor(cy1), floor(cx2), floor(cy2))
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
    local v, i, b0
    local has_subrs = 0
    local clear_stack

    local s = CArrayInit(48)

    local subr_stack = CArrayInit(10, stbtt__buf)

    local subrs = info.subrs
    local b, f

    local function STBTT__CSERR(_s) return 0 end

    -- this currently ignores the initial width value, which isn't needed if we have hmtx
    b = stbtt__cff_index_get(info.charstrings, glyph_index)
    while b.cursor < b.size do
        i = 0
        clear_stack = 1
        b0 = stbtt__buf_get8(b)

        -- TODO: implement hinting
        if b0 == 0x13 or b0 == 0x14 then -- hintmask or cntrmask
            if in_header ~= 0 then
                maskbits = maskbits + floor(sp / 2)  -- implicit "vstem"
            end
            in_header = 0
            stbtt__buf_skip(b, floor((maskbits + 7) / 8))
        elseif b0 == 0x01 or b0 == 0x03 or b0 == 0x12 or b0 == 0x17 then -- hstem, vstem, hstemhm, vstemhm
            maskbits = maskbits + floor(sp / 2)
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
            i = 0
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
                if i >= sp then break end
                stbtt__csctx_rline_to(c, 0, s[i])
                i = i + 1
            end
        elseif b0 == 0x1F then -- hvcurveto
            if sp < 4 then return STBTT__CSERR("hvcurveto stack") end
            while true do
                if i + 3 >= sp then break end
                local extra = (sp - i == 5) and s[i + 4] or 0.0
                stbtt__csctx_rccurve_to(c, 0, s[i], s[i + 1], s[i + 2], s[i + 3], extra)
                i = i + 4
                if i + 3 >= sp then break end
                extra = (sp - i == 5) and s[i + 4] or 0.0
                stbtt__csctx_rccurve_to(c, s[i], 0, s[i + 1], s[i + 2], extra, s[i + 3])
                i = i + 4
            end
        elseif b0 == 0x1E then -- vhcurveto
            if sp < 4 then return STBTT__CSERR("vhcurveto stack") end

            while true do
                if i + 3 >= sp then break end
                local extra = (sp - i == 5) and s[i + 4] or 0.0
                stbtt__csctx_rccurve_to(c, s[i], 0, s[i + 1], s[i + 2], extra, s[i + 3])
                i = i + 4
                if i + 3 >= sp then break end
                extra = (sp - i == 5) and s[i + 4] or 0.0
                stbtt__csctx_rccurve_to(c, 0, s[i], s[i + 1], s[i + 2], s[i + 3], extra)
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

            if band(sp, 1) ~= 0 then
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
            v = floor(s[sp])
            if subr_stack_height >= 10 then return STBTT__CSERR("recursion limit") end
            subr_stack[subr_stack_height] = b
            subr_stack_height = subr_stack_height + 1
            b = stbtt__get_subr((b0 == 0x0A) and subrs or info.gsubrs, v)
            if b.size == 0 then return STBTT__CSERR("subr not found") end
            b.cursor = 0
            clear_stack = 0
        elseif b0 == 0x0B then -- return
            if subr_stack_height <= 0 then return STBTT__CSERR("return outside subr") end
            subr_stack_height = subr_stack_height - 1
            b = subr_stack[subr_stack_height]
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
                f = stbtt__cff_int(b)
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

function stbtt__GetGlyphShapeT2(info, glyph_index, pvertices)
    -- runs the charstring twice, once to count and once to output (to avoid realloc)
    local count_ctx = STBTT__CSCTX_INIT(1)
    local output_ctx = STBTT__CSCTX_INIT(0)
    if stbtt__run_charstring(info, glyph_index, count_ctx) ~= 0 then
        pvertices:set_deref(CArrayInit(count_ctx.num_vertices, stbtt_vertex))
        output_ctx.pvertices = pvertices:deref()
        if stbtt__run_charstring(info, glyph_index, output_ctx) ~= 0 then
            STBTT_assert(output_ctx.num_vertices == count_ctx.num_vertices)
            return output_ctx.num_vertices
        end
    end
    pvertices:set_deref(nil)
    return 0
end

function stbtt__GetGlyphInfoT2(info, glyph_index, x0, y0, x1, y1) -- const stbtt_fontinfo *info, int glyph_index, int *x0, int *y0, int *x1, int *y1
    local c = STBTT__CSCTX_INIT(1)
    local r = stbtt__run_charstring(info, glyph_index, c)
    if x0 then x0:set_deref((r ~= 0) and c.min_x or 0) end
    if y0 then y0:set_deref((r ~= 0) and c.min_y or 0) end
    if x1 then x1:set_deref((r ~= 0) and c.max_x or 0) end
    if y1 then y1:set_deref((r ~= 0) and c.max_y or 0) end
    return ((r ~= 0) and c.num_vertices or 0)
end

function stbtt_GetGlyphShape(info, glyph_index, pvertices)
    if info.cff.size == 0 then
        return stbtt__GetGlyphShapeTT(info, glyph_index, pvertices)
    else
        return stbtt__GetGlyphShapeT2(info, glyph_index, pvertices)
    end
end

local function stbtt_GetGlyphHMetrics(info, glyph_index, advanceWidth, leftSideBearing) -- const stbtt_fontinfo *info, int glyph_index, int *advanceWidth, int *leftSideBearing
    local numOfLongHorMetrics = ttUSHORT(info.data + info.hhea + 34)
    if glyph_index < numOfLongHorMetrics then
        if advanceWidth then advanceWidth:set_deref(ttSHORT(info.data + info.hmtx + 4 * glyph_index)) end
        if leftSideBearing then leftSideBearing:set_deref(ttSHORT(info.data + info.hmtx + 4 * glyph_index + 2)) end
    else
        if advanceWidth then advanceWidth:set_deref(ttSHORT(info.data + info.hmtx + 4 * (numOfLongHorMetrics - 1))) end
        if leftSideBearing then leftSideBearing:set_deref(ttSHORT(info.data + info.hmtx + 4 * numOfLongHorMetrics + 2 * (glyph_index - numOfLongHorMetrics))) end
    end
end

local function stbtt_GetKerningTableLength(info)
    local data = info.data + info.kern

    -- we only look at the first table. it must be 'horizontal' and format 0
    if info.kern == 0 then
        return 0
    end
    if ttUSHORT(data + 2) < 1 then -- number of tables, need at least 1
        return 0
    end
    if ttUSHORT(data + 8) ~= 1 then -- horizontal flag must be set in format
        return 0
    end

    return ttUSHORT(data + 10)
end

local function stbtt_GetKerningTable(info, _table, table_length)
    local data = info.data + info.kern

    -- we only look at the first table. it must be 'horizontal' and format 0
    if info.kern == 0 then
        return 0
    end
    if ttUSHORT(data + 2) < 1 then -- number of tables, need at least 1
        return 0
    end
    if ttUSHORT(data + 8) ~= 1 then -- horizontal flag must be set in format
        return 0
    end

    local length = ttUSHORT(data + 10)
    if table_length < length then
        length = table_length
    end

    for k = 0, length - 1 do
        _table[k].glyph1 = ttUSHORT(data + 18 + (k * 6))
        _table[k].glyph2 = ttUSHORT(data + 20 + (k * 6))
        _table[k].advance = ttSHORT(data + 22 + (k * 6))
    end

    return length
end

local function stbtt__GetGlyphKernInfoAdvance(info, glyph1, glyph2)
    local data = info.data + info.kern

    -- we only look at the first table. it must be 'horizontal' and format 0
    if info.kern == 0 then
        return 0
    end
    if ttUSHORT(data + 2) < 1 then -- number of tables, need at least 1
        return 0
    end
    if ttUSHORT(data + 8) ~= 1 then -- horizontal flag must be set in format
        return 0
    end

    local m
    local l = 0
    local r = ttUSHORT(data + 10) - 1
    local needle = bor(lshift(glyph1, 16), glyph2)
    local straw
    while l <= r do
        m = rshift(l + r, 1)
        straw = ttULONG(data + 18 + (m * 6))
        if needle < straw then
            r = m - 1
        elseif needle > straw then
            l = m + 1
        else
            return ttSHORT(data + 22 + (m * 6))
        end
    end
    return 0
end

local function stbtt__GetCoverageIndex(coverageTable, glyph)
    local coverageFormat = ttUSHORT(coverageTable)

    if coverageFormat == 1 then
        local glyphCount = ttUSHORT(coverageTable + 2)

        -- Binary search
        local l = 0
        local r = glyphCount - 1

        while l <= r do
            local glyphArray = coverageTable + 4
            local m = rshift(l + r, 1)
            local glyphID = ttUSHORT(glyphArray + 2 * m)

            if glyph < glyphID then
                r = m - 1
            elseif glyph > glyphID then
                l = m + 1
            else
                return m
            end
        end
    elseif coverageFormat == 2 then
        local rangeCount = ttUSHORT(coverageTable + 2)
        local rangeArray = coverageTable + 4

        -- Binary search
        local l = 0
        local r = rangeCount - 1

        while l <= r do
            local m = rshift(l + r, 1)
            local rangeRecord = rangeArray + 6 * m
            local strawStart = ttUSHORT(rangeRecord)
            local strawEnd = ttUSHORT(rangeRecord + 2)

            if glyph < strawStart then
                r = m - 1
            elseif glyph > strawEnd then
                l = m + 1
            else
                local startCoverageIndex = ttUSHORT(rangeRecord + 4)
                return startCoverageIndex + glyph - strawStart
            end
        end
    end

    return -1 -- unsupported
end

local function stbtt__GetGlyphClass(classDefTable, glyph)
    local classDefFormat = ttUSHORT(classDefTable)

    if classDefFormat == 1 then
        local startGlyphID = ttUSHORT(classDefTable + 2)
        local glyphCount = ttUSHORT(classDefTable + 4)
        local classDef1ValueArray = classDefTable + 6

        if glyph >= startGlyphID and glyph < startGlyphID + glyphCount then
            return ttUSHORT(classDef1ValueArray + 2 * (glyph - startGlyphID))
        end
    elseif classDefFormat == 2 then
        local classRangeCount = ttUSHORT(classDefTable + 2)
        local classRangeRecords = classDefTable + 4

        -- Binary search
        local l = 0
        local r = classRangeCount - 1
        while l <= r do
            local m = rshift(l + r, 1)
            local classRangeRecord = classRangeRecords + 6 * m
            local strawStart = ttUSHORT(classRangeRecord)
            local strawEnd = ttUSHORT(classRangeRecord + 2)

            if glyph < strawStart then
                r = m - 1
            elseif glyph > strawEnd then
                l = m + 1
            else
                return ttUSHORT(classRangeRecord + 4)
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

    local data = info.data + info.gpos

    if ttUSHORT(data + 0) ~= 1 then return 0 end -- Major version 1
    if ttUSHORT(data + 2) ~= 0 then return 0 end -- Minor version 0

    local lookupListOffset = ttUSHORT(data + 8)
    local lookupList = data + lookupListOffset
    local lookupCount = ttUSHORT(lookupList)

    for i = 0, lookupCount - 1 do
        local lookupOffset = ttUSHORT(lookupList + 2 + 2 * i)
        local lookupTable = lookupList + lookupOffset

        local lookupType = ttUSHORT(lookupTable)
        local subTableCount = ttUSHORT(lookupTable + 4)
        local subTableOffsets = lookupTable + 6
        if lookupType ~= 2 then -- Pair Adjustment Positioning Subtable
            continue
        end

        for sti = 0, subTableCount - 1 do
            local subtableOffset = ttUSHORT(subTableOffsets + 2 * sti)
            local _table = lookupTable + subtableOffset
            local posFormat = ttUSHORT(_table)
            local coverageOffset = ttUSHORT(_table + 2)
            local coverageIndex = stbtt__GetCoverageIndex(_table + coverageOffset, glyph1)
            if coverageIndex == -1 then continue end

            if posFormat == 1 then
                local valueFormat1 = ttUSHORT(_table + 4)
                local valueFormat2 = ttUSHORT(_table + 6)
                if valueFormat1 == 4 and valueFormat2 == 0 then -- Support more formats?
                    local valueRecordPairSizeInBytes = 2
                    local pairSetCount = ttUSHORT(_table + 8)
                    local pairPosOffset = ttUSHORT(_table + 10 + 2 * coverageIndex)
                    local pairValueTable = _table + pairPosOffset
                    local pairValueCount = ttUSHORT(pairValueTable)
                    local pairValueArray = pairValueTable + 2

                    if coverageIndex >= pairSetCount then return 0 end

                    local needle = glyph2
                    local r = pairValueCount - 1
                    local l = 0

                    -- Binary search
                    while l <= r do
                        local m = rshift(l + r, 1)
                        local pairValue = pairValueArray + (2 + valueRecordPairSizeInBytes) * m
                        local secondGlyph = ttUSHORT(pairValue)
                        local straw = secondGlyph
                        if needle < straw then
                            r = m - 1
                        elseif needle > straw then
                            l = m + 1
                        else
                            local xAdvance = ttSHORT(pairValue + 2)
                            return xAdvance
                        end
                    end
                else
                    return 0
                end

            elseif posFormat == 2 then
                local valueFormat1 = ttUSHORT(_table + 4)
                local valueFormat2 = ttUSHORT(_table + 6)
                if valueFormat1 == 4 and valueFormat2 == 0 then -- Support more formats?
                    local classDef1Offset = ttUSHORT(_table + 8)
                    local classDef2Offset = ttUSHORT(_table + 10)
                    local glyph1class = stbtt__GetGlyphClass(_table + classDef1Offset, glyph1)
                    local glyph2class = stbtt__GetGlyphClass(_table + classDef2Offset, glyph2)

                    local class1Count = ttUSHORT(_table + 12)
                    local class2Count = ttUSHORT(_table + 14)
                    local class1Records = _table + 16

                    if glyph1class < 0 or glyph1class >= class1Count then return 0 end -- malformed
                    if glyph2class < 0 or glyph2class >= class2Count then return 0 end -- malformed

                    local class2Records = class1Records + 2 * (glyph1class * class2Count)
                    local xAdvance = ttSHORT(class2Records + 2 * glyph2class)
                    return xAdvance
                else
                    return 0
                end
            else
                return 0 -- Unsupported position format
            end
        end
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

local function stbtt_GetCodepointHMetrics(info, codepoint, advanceWidth, leftSideBearing) -- const stbtt_fontinfo *info, int codepoint, int *advanceWidth, int *leftSideBearing
    stbtt_GetGlyphHMetrics(info, stbtt_FindGlyphIndex(info, codepoint), advanceWidth, leftSideBearing)
end

local function stbtt_GetFontVMetrics(info, ascent, descent, lineGap) -- const stbtt_fontinfo *info, int *ascent, int *descent, int *lineGap
    if ascent then ascent:set_deref(ttSHORT(info.data + info.hhea + 4)) end
    if descent then descent:set_deref(ttSHORT(info.data + info.hhea + 6)) end
    if lineGap then lineGap:set_deref(ttSHORT(info.data + info.hhea + 8)) end
end

function stbtt_GetFontVMetricsOS2(info, typoAscent, typoDescent, typoLineGap)
    local tab = stbtt__find_table(info.data, info.fontstart, "OS/2")
    if tab == 0 then
        return 0
    end
    if typoAscent then typoAscent:set_deref(ttSHORT(info.data + tab + 68)) end
    if typoDescent then typoDescent:set_deref(ttSHORT(info.data + tab + 70)) end
    if typoLineGap then typoLineGap:set_deref(ttSHORT(info.data + tab + 72)) end
    return 1
end

local function stbtt_GetFontBoundingBox(info, x0, y0, x1, y1)
    x0:set_deref(ttSHORT(info.data + info.head + 36))
    y0:set_deref(ttSHORT(info.data + info.head + 38))
    x1:set_deref(ttSHORT(info.data + info.head + 40))
    y1:set_deref(ttSHORT(info.data + info.head + 42))
end

local function stbtt_ScaleForPixelHeight(info, height)
    local fheight = ttSHORT(info.data + info.hhea + 4) - ttSHORT(info.data + info.hhea + 6)
    return height / fheight
end

local function stbtt_ScaleForMappingEmToPixels(info, pixels)
    local unitsPerEm = ttUSHORT(info.data + info.head + 18)
    return pixels / unitsPerEm
end

local function stbtt_FindSVGDoc(info, gl)
    local data = info.data
    local svg_doc_list = data + stbtt__get_svg(info)

    local numEntries = ttUSHORT(svg_doc_list)
    local svg_docs = svg_doc_list + 2

    for i = 0, numEntries - 1 do
        local svg_doc = svg_docs + (12 * i)
        if gl >= ttUSHORT(svg_doc) and gl <= ttUSHORT(svg_doc + 2) then
            return svg_doc
        end
    end
    return 0
end

local function stbtt_GetGlyphSVG(info, gl, svg)
    local data = info.data

    if info.svg == 0 then
        return 0
    end

    local svg_doc = stbtt_FindSVGDoc(info, gl)
    if svg_doc ~= 0 then
        svg:set_deref(data + info.svg + ttULONG(svg_doc + 4))
        return ttULONG(svg_doc + 8)
    else
        return 0
    end
end

local function stbtt_GetCodepointSVG(info, unicode_codepoint, svg)
    return stbtt_GetGlyphSVG(info, stbtt_FindGlyphIndex(info, unicode_codepoint), svg)
end

------------------------------------
--- antialiasing software rasterizer
--

local function stbtt_GetGlyphBitmapBoxSubpixel(font, glyph, scale_x, scale_y, shift_x, shift_y, ix0, iy0, ix1, iy1)
    local x0 = CArrayInit(1, {0})
    local y0 = CArrayInit(1, {0})
    local x1 = CArrayInit(1)
    local y1 = CArrayInit(1)

    if stbtt_GetGlyphBox(font, glyph, x0, y0, x1, y1) == 0 then
        -- e.g. space character
        if ix0 then ix0:set_deref(0) end
        if iy0 then iy0:set_deref(0) end
        if ix1 then ix1:set_deref(0) end
        if iy1 then iy1:set_deref(0) end
    else
        -- move to integral bboxes (treating pixels as little squares, what pixels get touched)?
        if ix0 then ix0:set_deref(STBTT_ifloor( x0:deref() * scale_x + shift_x)) end
        if iy0 then iy0:set_deref(STBTT_ifloor(-y1:deref() * scale_y + shift_y)) end
        if ix1 then ix1:set_deref(STBTT_iceil ( x1:deref() * scale_x + shift_x)) end
        if iy1 then iy1:set_deref(STBTT_iceil (-y0:deref() * scale_y + shift_y)) end
    end
end

local function stbtt_GetGlyphBitmapBox(font, glyph, scale_x, scale_y, ix0, iy0, ix1, iy1)
    stbtt_GetGlyphBitmapBoxSubpixel(font, glyph, scale_x, scale_y, 0.0, 0.0, ix0, iy0, ix1, iy1)
end

local function stbtt_GetCodepointBitmapBoxSubpixel(font, codepoint, scale_x, scale_y, shift_x, shift_y, ix0, iy0, ix1, iy1)
    stbtt_GetGlyphBitmapBoxSubpixel(font, stbtt_FindGlyphIndex(font, codepoint), scale_x, scale_y, shift_x, shift_y, ix0, iy0, ix1, iy1)
end

local function stbtt_GetCodepointBitmapBox(font, codepoint, scale_x, scale_y, ix0, iy0, ix1, iy1)
    stbtt_GetCodepointBitmapBoxSubpixel(font, codepoint, scale_x, scale_y, 0.0, 0.0, ix0, iy0, ix1, iy1)
end


--------------
--- Rasterizer
--

