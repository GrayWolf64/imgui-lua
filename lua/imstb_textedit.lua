--- ImGui Sincerely
-- This is a Lua port of original `imstb_textedit.h`

-- ALL TABLES IN THIS FILE ARE 1-BASED!
-- Character Indexing:
--     idx=n, the n'th char (1-based)
-- Cursor Indexing:
--     idx=n, the position before the n'th char
--     idx=n+1, the position after the n'th char

-- Symbols that must be defined before using this:
local STB_TEXTEDIT_NEWLINE   = ImStb.TEXTEDIT_NEWLINE
local STB_TEXTEDIT_STRINGLEN = ImStb.TEXTEDIT_STRINGLEN
local STB_TEXTEDIT_GETCHAR   = ImStb.TEXTEDIT_GETCHAR
local STB_TEXTEDIT_GETWIDTH  = ImStb.TEXTEDIT_GETWIDTH
local STB_TEXTEDIT_LAYOUTROW = ImStb.TEXTEDIT_LAYOUTROW
local IMSTB_TEXTEDIT_GETNEXTCHARINDEX = ImStb.TEXTEDIT_GETNEXTCHARINDEX
local IMSTB_TEXTEDIT_GETPREVCHARINDEX = ImStb.TEXTEDIT_GETPREVCHARINDEX
local STB_TEXTEDIT_MOVEWORDLEFT  = ImStb.TEXTEDIT_MOVEWORDLEFT
local STB_TEXTEDIT_MOVEWORDRIGHT = ImStb.TEXTEDIT_MOVEWORDRIGHT
local STB_TEXTEDIT_MOVELINESTART = ImStb.TEXTEDIT_MOVELINESTART
local STB_TEXTEDIT_MOVELINEEND   = ImStb.TEXTEDIT_MOVELINEEND
local STB_TEXTEDIT_DELETECHARS   = ImStb.TEXTEDIT_DELETECHARS

local IMSTB_TEXTEDIT_UNDOSTATECOUNT = ImStb.TEXTEDIT_UNDOSTATECOUNT
local IMSTB_TEXTEDIT_UNDOCHARCOUNT = ImStb.TEXTEDIT_UNDOCHARCOUNT
local IMSTB_TEXTEDIT_memmove = ImStb.TEXTEDIT_memmove

----------------------------------------------------------------
----------------------------------------------------------------
---
--- STB_TexteditState
---
--- Definition of STB_TexteditState which you should store
--- per-textfield; it includes cursor position, selection state,
--- and undo state.
---
--- @alias IMSTB_TEXTEDIT_POSITIONTYPE int
--- @alias IMSTB_TEXTEDIT_CHARTYPE     char

--- @class StbUndoRecord
--- @field where         IMSTB_TEXTEDIT_POSITIONTYPE
--- @field insert_length IMSTB_TEXTEDIT_POSITIONTYPE
--- @field delete_length IMSTB_TEXTEDIT_POSITIONTYPE
--- @field char_storage  int

--- @return StbUndoRecord
--- @nodiscard
local function StbUndoRecord()
    return {
        where         = 0,
        insert_length = 0,
        delete_length = 0,
        char_storage  = 0
    }
end

--- @class StbUndoState
--- @field undo_rec        StbUndoRecord[]           # size = IMSTB_TEXTEDIT_UNDOSTATECOUNT
--- @field undo_char       IMSTB_TEXTEDIT_CHARTYPE[] # size = IMSTB_TEXTEDIT_UNDOCHARCOUNT
--- @field undo_point      short                     # next available slot
--- @field redo_point      short                     # next available slot
--- @field undo_char_point int                       # next available slot
--- @field redo_char_point int                       # next available slot

--- @return StbUndoState
--- @nodiscard
local function StbUndoState()
    local undo_rec = {}
    for i = 1, IMSTB_TEXTEDIT_UNDOSTATECOUNT do
        undo_rec[i] = StbUndoRecord()
    end

    local undo_char = {}
    for i = 1, IMSTB_TEXTEDIT_UNDOCHARCOUNT do
        undo_char[i] = 0
    end

    return {
        undo_rec        = undo_rec,
        undo_char       = undo_char,

        undo_point      = 1,
        redo_point      = 1,
        undo_char_point = 1,
        redo_char_point = 1
    }
end

--- @class STB_TexteditState
--- @field cursor                int           # position of the text cursor within the string
--- @field select_start          int           # selection start point
--- @field select_end            int
--- @field insert_mode           bool
--- @field row_count_per_page    int
--- @field cursor_at_end_of_line bool          # not implemented yet
--- @field initialized           bool
--- @field has_preferred_x       bool
--- @field single_line           bool
--- @field padding1              unsigned_char
--- @field padding2              unsigned_char
--- @field padding3              unsigned_char
--- @field preferred_x           float
--- @field undostate             StbUndoState

--- @return STB_TexteditState
--- @nodiscard
local function STB_TexteditState()
    return {
        cursor = 0,

        select_start = 0,
        select_end   = 0,

        insert_mode = false,

        row_count_per_page = 0,

        cursor_at_end_of_line = false,
        initialized           = false,
        has_preferred_x       = false,
        single_line           = false,
        padding1 = 0,
        padding2 = 0,
        padding3 = 0,

        preferred_x = 0.0,

        undostate = StbUndoState()
    }
end

--- @param s STB_TexteditState
local function STB_TEXT_HAS_SELECTION(s)
    return s.select_start ~= s.select_end
end

--- @class StbTexteditRow
--- @field x0               float # starting x location
--- @field x1               float # end x location
--- @field baseline_y_delta float # position of baseline relative to previous row's baseline
--- @field ymin             float # height of row above baseline
--- @field ymax             float # height of row below baseline
--- @field num_chars        int

--- @return StbTexteditRow
--- @nodiscard
local function StbTexteditRow()
    return {
        x0 = 0.0,
        x1 = 0.0,

        baseline_y_delta = 0.0,

        ymin = 0.0,
        ymax = 0.0,

        num_chars = 0
    }
end

--- @param r StbTexteditRow
local function StbTexteditRow_Reset(r)
    r.x0 = 0.0
    r.x1 = 0.0
    r.baseline_y_delta = 0.0
    r.ymin = 0.0
    r.ymax = 0.0
    r.num_chars = 0
end

----------------------------------------
----------------------------------------
---
--- Implementation
---
---

local stb_text_locate_coord do

-- only create once, reuse later
local r = StbTexteditRow()

--- traverse the layout to locate the nearest character to a display position
--- @param str IMSTB_TEXTEDIT_STRING
--- @param x   float
--- @param y   float
--- @return int  idx
--- @return bool side_on_line
function stb_text_locate_coord(str, x, y)
    local n = STB_TEXTEDIT_STRINGLEN(str)
    local base_y = 0
    local prev_x

    StbTexteditRow_Reset(r)

    local out_side_on_line = false

    -- search rows to find one that straddles 'y'
    local i = 1
    while i <= n do
        STB_TEXTEDIT_LAYOUTROW(r, str, i)
        if r.num_chars <= 0 then
            return n + 1, out_side_on_line
        end

        if i == 1 and y < base_y + r.ymin then
            return 1, out_side_on_line
        end

        if y < base_y + r.ymax then
            break
        end

        i = i + r.num_chars
        base_y = base_y + r.baseline_y_delta
    end

    -- below all text, return 'after' last character
    if i > n then
        out_side_on_line = true
        return n + 1, out_side_on_line
    end

    -- check if it's before the beginning of the line
    if x < r.x0 then
        return i, out_side_on_line
    end

    -- check if it's before the end of the line
    if x < r.x1 then
        -- search characters in row for one that straddles 'x'
        prev_x = r.x0
        local k = 1
        while k <= r.num_chars do
            local w = STB_TEXTEDIT_GETWIDTH(str, i, k)
            if x < prev_x + w then
                out_side_on_line = (k == 1) and false or true
                if x < prev_x + w / 2 then
                    return k + i - 1, out_side_on_line
                else
                    return IMSTB_TEXTEDIT_GETNEXTCHARINDEX(str, i + k - 1), out_side_on_line
                end
            end
            prev_x = prev_x + w
            k = IMSTB_TEXTEDIT_GETNEXTCHARINDEX(str, i + k - 1) - i + 1
        end
        -- shouldn't happen, but if it does, fall through to end-of-line case
    end

    -- if the last character is a newline, return that. otherwise return 'after' the last character
    out_side_on_line = true
    if STB_TEXTEDIT_GETCHAR(str, i + r.num_chars - 1) == STB_TEXTEDIT_NEWLINE then
        return i + r.num_chars - 1, out_side_on_line
    else
        return i + r.num_chars, out_side_on_line
    end
end

end

local stb_textedit_click do

local r = StbTexteditRow()

-- API click: on mouse down, move the cursor to the clicked location, and reset the selection
--- @param str   IMSTB_TEXTEDIT_STRING
--- @param state STB_TexteditState
--- @param x     float
--- @param y     float
function stb_textedit_click(str, state, x, y)
    -- In single-line mode, just always make y = 0. This lets the drag keep working if the mouse
    -- goes off the top or bottom of the text
    local side_on_line
    if state.single_line then
        StbTexteditRow_Reset(r)
        STB_TEXTEDIT_LAYOUTROW(r, str, 1)
        y = r.ymin
    end

    state.cursor, side_on_line = stb_text_locate_coord(str, x, y)
    state.select_start = state.cursor
    state.select_end = state.cursor
    state.has_preferred_x = false
    str.LastMoveDirectionLR = (side_on_line ~= false) and ImGuiDir.Right or ImGuiDir.Left
end

end

local stb_textedit_drag do

local r = StbTexteditRow()

-- API drag: on mouse drag, move the cursor and selection endpoint to the clicked location
--- @param str   IMSTB_TEXTEDIT_STRING
--- @param state STB_TexteditState
--- @param x     float
--- @param y     float
function stb_textedit_drag(str, state, x, y)
    local p = 1
    local side_on_line

    -- In single-line mode, just always make y = 0. This lets the drag keep working if the mouse
    -- goes off the top or bottom of the text
    if state.single_line then
        StbTexteditRow_Reset(r)
        STB_TEXTEDIT_LAYOUTROW(r, str, 1)
        y = r.ymin
    end

    if state.select_start == state.select_end then
        state.select_start = state.cursor
    end

    p, side_on_line = stb_text_locate_coord(str, x, y)
    state.cursor = p
    state.select_end = p
    str.LastMoveDirectionLR = (side_on_line ~= false) and ImGuiDir.Right or ImGuiDir.Left
end

end

---------------------------
---------------------------
---
--- Keyboard input handling
---
---

local stb_text_makeundo_delete

--- @class StbFindState
--- @field x          float # position of n'th character
--- @field y          float
--- @field height     float # height of line
--- @field first_char int   # first char of row, and length
--- @field length     int
--- @field prev_first int   # first char of previous row

--- @return StbFindState
local function StbFindState()
    return {
        x = 0.0, y = 0.0,
        height = 0.0,
        first_char = 0, length = 0,
        prev_first = 0
    }
end

--- @param f StbFindState
local function StbFindState_Reset(f)
    f.x = 0.0
    f.y = 0.0
    f.height = 0.0
    f.first_char = 0
    f.length = 0
    f.prev_first = 0
end

local stb_textedit_find_charpos do

local r = StbTexteditRow()

-- find the x/y location of a character, and remember info about the previous row in
-- case we get a move-up event (for page up, we'll have to rescan)
--- @param find        StbFindState
--- @param str         IMSTB_TEXTEDIT_STRING
--- @param n           int
--- @param single_line int
function stb_textedit_find_charpos(find, str, n, single_line)
    StbTexteditRow_Reset(r)
    local prev_start = 1
    local z = STB_TEXTEDIT_STRINGLEN(str)
    local first

    -- special case if it's at the end (may not be needed?)
    if n == z + 1 and single_line then
        STB_TEXTEDIT_LAYOUTROW(r, str, 1)
        find.y = 0
        find.first_char = 1
        find.length = z
        find.height = r.ymax - r.ymin
        find.x = r.x1

        return
    end

    -- search rows to find the one that straddles character n
    find.y = 0

    local i = 1
    while true do
        STB_TEXTEDIT_LAYOUTROW(r, str, i)
        if n < i + r.num_chars - 1 then
            break
        end
        if str.LastMoveDirectionLR == ImGuiDir.Right and str.Stb.cursor > 1 and str.Stb.cursor == i + r.num_chars and STB_TEXTEDIT_GETCHAR(str, i + r.num_chars - 1) ~= STB_TEXTEDIT_NEWLINE then -- [IMGUI] Wrapping point handling
            break
        end
        if (i - 1) + r.num_chars == z and z > 0 and STB_TEXTEDIT_GETCHAR(str, z) ~= STB_TEXTEDIT_NEWLINE then -- [IMGUI] special handling for last line
            break
        end
        prev_start = i
        i = i + r.num_chars
        find.y = find.y + r.baseline_y_delta
        if i == z + 1 then -- [IMGUI]
            r.num_chars = 0
            break
        end
    end

    find.first_char = i
    first = i
    find.length = r.num_chars
    find.height = r.ymax - r.ymin
    find.prev_first = prev_start

    -- now scan to find xpos
    find.x = r.x0
    i = 1
    while first + i <= n + 1 do
        find.x = find.x + STB_TEXTEDIT_GETWIDTH(str, first, i)
        i = IMSTB_TEXTEDIT_GETNEXTCHARINDEX(str, first + i - 1) - first + 1
    end
end

end

-- make the selection/cursor state valid if client altered the string
--- @param str   IMSTB_TEXTEDIT_STRING
--- @param state STB_TexteditState
local function stb_textedit_clamp(str, state)
    local n = STB_TEXTEDIT_STRINGLEN(str)
    if STB_TEXT_HAS_SELECTION(state) then
        if state.select_start > n + 1 then state.select_start = n + 1 end
        if state.select_end > n + 1 then state.select_end = n + 1 end
        -- if clamping forced them to be equal, move the cursor to match
        if state.select_start == state.select_end then
            state.cursor = state.select_start
        end
    end
    if state.cursor > n + 1 then state.cursor = n + 1 end
end

-- delete characters while updating undo
--- @param str   IMSTB_TEXTEDIT_STRING
--- @param state STB_TexteditState
--- @param where int
--- @param len   int
local function stb_textedit_delete(str, state, where, len)
    stb_text_makeundo_delete(str, state, where, len)
    STB_TEXTEDIT_DELETECHARS(str, where, len)
    state.has_preferred_x = false
end

-----------------------------------------------------
-----------------------------------------------------
---
--- Undo processing
--- OPTIMIZE: the undo/redo buffer should be circular
---

--- @param state StbUndoState
local function stb_textedit_flush_redo(state)
    state.redo_point = IMSTB_TEXTEDIT_UNDOSTATECOUNT + 1
    state.redo_char_point = IMSTB_TEXTEDIT_UNDOCHARCOUNT + 1
end

-- discard the oldest entry in the undo list
--- @param state StbUndoState
local function stb_textedit_discard_undo(state)
    if state.undo_point > 0 then
        -- if the 1th undo state has characters, clean those up
        if state.undo_rec[1].char_storage >= 0 then
            local n = state.undo_rec[1].insert_length
            -- delete n characters from all other records
            state.undo_char_point = state.undo_char_point - n
            IMSTB_TEXTEDIT_memmove(state.undo_char, 1, state.undo_char, n + 1, state.undo_char_point - 1)
            for i = 1, state.undo_point do
                if state.undo_rec[i].char_storage >= 0 then
                    state.undo_rec[i].char_storage = state.undo_rec[i].char_storage - n -- OPTIMIZE: get rid of char_storage and infer it
                end
            end
        end
        state.undo_point = state.undo_point - 1
        IMSTB_TEXTEDIT_memmove(state.undo_rec, 1, state.undo_rec, 2, state.undo_point - 1)
    end
end

--- @param state    StbUndoState
--- @param numchars int
local function stb_text_create_undo_record(state, numchars)
    -- any time we create a new undo record, we discard redo
    stb_textedit_flush_redo(state)

    -- if we have no free records, we have to make room, by sliding the
    -- existing records down
    if state.undo_point == IMSTB_TEXTEDIT_UNDOSTATECOUNT then
        stb_textedit_discard_undo(state)
    end

    -- if the characters to store won't possibly fit in the buffer, we can't undo
    if numchars > IMSTB_TEXTEDIT_UNDOCHARCOUNT then
        state.undo_point = 1
        state.undo_char_point = 1
        return nil
    end

    -- if we don't have enough free characters in the buffer, we have to make room
    while state.undo_char_point + numchars > IMSTB_TEXTEDIT_UNDOCHARCOUNT do
        stb_textedit_discard_undo(state)
    end

    local ret = state.undo_rec[state.undo_point]
    state.undo_point = state.undo_point + 1
    return ret
end

--- @param state      StbUndoState
--- @param pos        int
--- @param insert_len int
--- @param delete_len int
--- @return int? # index into undostate.undo_char[]
local function stb_text_createundo(state, pos, insert_len, delete_len)
    local r = stb_text_create_undo_record(state, insert_len)
    if r == nil then
        return nil
    end

    r.where = pos
    r.insert_length = insert_len
    r.delete_length = delete_len

    if insert_len == 0 then
        r.char_storage = -1
        return nil
    else
        r.char_storage = state.undo_char_point
        state.undo_char_point = state.undo_char_point + insert_len
        return r.char_storage
    end
end

--- @param str   IMSTB_TEXTEDIT_STRING
--- @param state STB_TexteditState
local function stb_text_undo(str, state)

end

local function stb_text_redo()

end

local function stb_text_makeundo_insert()

end

function stb_text_makeundo_delete(str, state, where, length)

end

local function stb_text_makeundo_replace()

end

local function stb_textedit_clear_state(state, is_single_line)

end

return {
    click = stb_textedit_click,
    drag = stb_textedit_drag,
    createundo = stb_text_createundo,
    initialize_state = stb_textedit_clear_state,

    HAS_SELECTION = STB_TEXT_HAS_SELECTION
}