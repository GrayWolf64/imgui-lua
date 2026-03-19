--- ImGui Sincerely
-- This is a Lua port of original `imstb_textedit.h`

-- ALL TABLES IN THIS FILE ARE 1-BASED!
-- Character Indexing:
--     idx=n, the n'th char (1-based)
-- Cursor Indexing:
--     idx=n, the position before the n'th char
--     idx=n+1, the position after the n'th char

-- Symbols that must be defined before using this:
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
local STB_TEXTEDIT_INSERTCHARS   = ImStb.TEXTEDIT_INSERTCHARS

STB_TEXTEDIT_NEWLINE     = 10
STB_TEXTEDIT_K_LEFT      = 0x200000 -- keyboard input to move cursor left
STB_TEXTEDIT_K_RIGHT     = 0x200001 -- keyboard input to move cursor right
STB_TEXTEDIT_K_UP        = 0x200002 -- keyboard input to move cursor up
STB_TEXTEDIT_K_DOWN      = 0x200003 -- keyboard input to move cursor down
STB_TEXTEDIT_K_LINESTART = 0x200004 -- keyboard input to move cursor to start of line
STB_TEXTEDIT_K_LINEEND   = 0x200005 -- keyboard input to move cursor to end of line
STB_TEXTEDIT_K_TEXTSTART = 0x200006 -- keyboard input to move cursor to start of text
STB_TEXTEDIT_K_TEXTEND   = 0x200007 -- keyboard input to move cursor to end of text
STB_TEXTEDIT_K_DELETE    = 0x200008 -- keyboard input to delete selection or character under cursor
STB_TEXTEDIT_K_BACKSPACE = 0x200009 -- keyboard input to delete selection or character left of cursor
STB_TEXTEDIT_K_UNDO      = 0x20000A -- keyboard input to perform undo
STB_TEXTEDIT_K_REDO      = 0x20000B -- keyboard input to perform redo
STB_TEXTEDIT_K_WORDLEFT  = 0x20000C -- keyboard input to move cursor left one word
STB_TEXTEDIT_K_WORDRIGHT = 0x20000D -- keyboard input to move cursor right one word
STB_TEXTEDIT_K_PGUP      = 0x20000E -- keyboard input to move cursor up a page
STB_TEXTEDIT_K_PGDOWN    = 0x20000F -- keyboard input to move cursor down a page
STB_TEXTEDIT_K_SHIFT     = 0x400000

IMSTB_TEXTEDIT_UNDOSTATECOUNT = 99
IMSTB_TEXTEDIT_UNDOCHARCOUNT  = 999
local IMSTB_TEXTEDIT_memmove = ImStb.TEXTEDIT_memmove

local stb_text_undo
local stb_text_redo

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

--- @alias STB_TEXTEDIT_KEYTYPE int

--- @class StbUndoRecord
--- @field where         IMSTB_TEXTEDIT_POSITIONTYPE
--- @field insert_length IMSTB_TEXTEDIT_POSITIONTYPE
--- @field delete_length IMSTB_TEXTEDIT_POSITIONTYPE
--- @field char_storage  int

--- @return StbUndoRecord
--- @nodiscard
local function StbUndoRecord()
    return {
        where         = 1,
        insert_length = 0,
        delete_length = 0,
        char_storage  = 1
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
function STB_TexteditState()
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

local stb_text_makeundo_insert
local stb_text_makeundo_delete
local stb_text_makeundo_replace

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
--- @param single_line bool
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

-- delete the selection
--- @param str   IMSTB_TEXTEDIT_STRING
--- @param state STB_TexteditState
local function stb_textedit_delete_selection(str, state)
    stb_textedit_clamp(str, state)
    if STB_TEXT_HAS_SELECTION(state) then
        if state.select_start < state.select_end then
            stb_textedit_delete(str, state, state.select_start, state.select_end - state.select_start)
            state.cursor = state.select_start
            state.select_end = state.cursor
        else
            stb_textedit_delete(str, state, state.select_end, state.select_start - state.select_end)
            state.cursor = state.select_end
            state.select_start = state.cursor
        end
        state.has_preferred_x = false
    end
end

-- canonicalize the selection so start <= end
--- @param state STB_TexteditState
local function stb_textedit_sortselection(state)
    if state.select_end < state.select_start then
        local temp = state.select_end
        state.select_end = state.select_start
        state.select_start = temp
    end
end

-- move cursor to first character of selection
--- @param state STB_TexteditState
local function stb_textedit_move_to_first(state)
    if STB_TEXT_HAS_SELECTION(state) then
        stb_textedit_sortselection(state)
        state.cursor = state.select_start
        state.select_end = state.select_start
        state.has_preferred_x = false
    end
end

-- move cursor to last character of selection
--- @param str   IMSTB_TEXTEDIT_STRING
--- @param state STB_TexteditState
local function stb_textedit_move_to_last(str, state)
    if STB_TEXT_HAS_SELECTION(state) then
        stb_textedit_sortselection(state)
        stb_textedit_clamp(str, state)
        state.cursor = state.select_end
        state.select_start = state.select_end
        state.has_preferred_x = false
    end
end

-- update selection and cursor to match each other
--- @param state STB_TexteditState
local function stb_textedit_prep_selection_at_cursor(state)
    if not STB_TEXT_HAS_SELECTION(state) then
        state.select_start = state.cursor
        state.select_end = state.cursor
    else
        state.cursor = state.select_end
    end
end

-- API cut: delete selection
--- @param str   IMSTB_TEXTEDIT_STRING
--- @param state STB_TexteditState
--- @return bool
local function stb_textedit_cut(str, state)
    if STB_TEXT_HAS_SELECTION(state) then
        stb_textedit_delete_selection(str, state) -- implicitly clamps
        state.has_preferred_x = false
        return true
    end
    return false
end

-- API paste: replace existing selection with passed-in text
--- @param str   IMSTB_TEXTEDIT_STRING
--- @param state STB_TexteditState
--- @param text  IMSTB_TEXTEDIT_CHARTYPE[]
--- @param len   int
--- @return bool
local function stb_textedit_paste_internal(str, state, text, len)
    -- if there's a selection, the paste should delete it
    stb_textedit_clamp(str, state)
    stb_textedit_delete_selection(str, state)
    -- try to insert the characters
    len = STB_TEXTEDIT_INSERTCHARS(str, state.cursor, text, 1, len)
    if len then
        stb_text_makeundo_insert(state, state.cursor, len)
        state.cursor = state.cursor + len
        state.has_preferred_x = false
        return true
    end
    -- note: paste failure will leave deleted selection, may be restored with an undo (see https://github.com/nothings/stb/issues/734 for details)
    return false
end

-- API key: process text input
-- [IMGUI] Added stb_textedit_text(), extracted out and called by stb_textedit_key() for backward compatibility.
--- @param str       IMSTB_TEXTEDIT_STRING
--- @param state     STB_TexteditState
--- @param text      IMSTB_TEXTEDIT_CHARTYPE[]
--- @param text_len int
local function stb_textedit_text(str, state, text, text_len)
    -- can't add newline in single-line mode
    if text[1] == STB_TEXTEDIT_NEWLINE and state.single_line then
        return
    end

    if state.insert_mode and not STB_TEXT_HAS_SELECTION(state) and state.cursor < STB_TEXTEDIT_STRINGLEN(str) then
        stb_text_makeundo_replace(str, state, state.cursor, 1, 1)
        STB_TEXTEDIT_DELETECHARS(str, state.cursor, 1)
        text_len = STB_TEXTEDIT_INSERTCHARS(str, state.cursor, text, 1, text_len)
        if text_len then
            state.cursor = state.cursor + text_len
            state.has_preferred_x = false
        end
    else
        stb_textedit_delete_selection(str, state) -- implicitly clamps
        text_len = STB_TEXTEDIT_INSERTCHARS(str, state.cursor, text, 1, text_len)
        if text_len then
            stb_text_makeundo_insert(state, state.cursor, text_len)
            state.cursor = state.cursor + text_len
            state.has_preferred_x = false
        end
    end
end

local stb_textedit_key do

local find = StbFindState()
local row = StbTexteditRow()

-- API key: process a keyboard input
--- @param str   IMSTB_TEXTEDIT_STRING
--- @param state STB_TexteditState
--- @param key   STB_TEXTEDIT_KEYTYPE
function stb_textedit_key(str, state, key)
:: retry ::
    if key == STB_TEXTEDIT_K_UNDO then
        stb_text_undo(str, state)
        state.has_preferred_x = false
    elseif key == STB_TEXTEDIT_K_REDO then
        stb_text_redo(str, state)
        state.has_preferred_x = false
    elseif key == STB_TEXTEDIT_K_LEFT then
        -- if currently there's a selection, move cursor to start of selection
        if STB_TEXT_HAS_SELECTION(state) then
            stb_textedit_move_to_first(state)
        else
            if state.cursor > 1 then
                state.cursor = IMSTB_TEXTEDIT_GETPREVCHARINDEX(str, state.cursor)
            end
        end

        state.has_preferred_x = false
    elseif key == STB_TEXTEDIT_K_RIGHT then
        -- if currently there's a selection, move cursor to end of selection
        if STB_TEXT_HAS_SELECTION(state) then
            stb_textedit_move_to_last(str, state)
        else
            state.cursor = IMSTB_TEXTEDIT_GETNEXTCHARINDEX(str, state.cursor)
        end

        stb_textedit_clamp(str, state)
        state.has_preferred_x = false
    elseif key == bit.bor(STB_TEXTEDIT_K_LEFT, STB_TEXTEDIT_K_SHIFT) then
        stb_textedit_clamp(str, state)
        stb_textedit_prep_selection_at_cursor(state)
        -- move selection left
        if state.select_end > 1 then
            state.select_end = IMSTB_TEXTEDIT_GETPREVCHARINDEX(str, state.select_end)
        end
        state.cursor = state.select_end
        state.has_preferred_x = false
    elseif key == STB_TEXTEDIT_K_WORDLEFT then
        -- if currently there's a selection, move cursor to start of selection
        if STB_TEXT_HAS_SELECTION(state) then
            stb_textedit_move_to_first(state)
        else
            state.cursor = STB_TEXTEDIT_MOVEWORDLEFT(str, state.cursor)
            stb_textedit_clamp(str, state)
        end
    elseif key == bit.bor(STB_TEXTEDIT_K_WORDLEFT, STB_TEXTEDIT_K_SHIFT) then
        if not STB_TEXT_HAS_SELECTION(state) then
            stb_textedit_prep_selection_at_cursor(state)
        end

        state.cursor = STB_TEXTEDIT_MOVEWORDLEFT(str, state.cursor)
        state.select_end = state.cursor

        stb_textedit_clamp(str, state)
    elseif key == STB_TEXTEDIT_K_WORDRIGHT then
        -- if currently there's a selection, move cursor to end of selection
        if STB_TEXT_HAS_SELECTION(state) then
            stb_textedit_move_to_last(str, state)
        else
            state.cursor = STB_TEXTEDIT_MOVEWORDRIGHT(str, state.cursor)
            stb_textedit_clamp(str, state)
        end
    elseif key == bit.bor(STB_TEXTEDIT_K_WORDRIGHT, STB_TEXTEDIT_K_SHIFT) then
        if not STB_TEXT_HAS_SELECTION(state) then
            stb_textedit_prep_selection_at_cursor(state)
        end

        state.cursor = STB_TEXTEDIT_MOVEWORDRIGHT(str, state.cursor)
        state.select_end = state.cursor

        stb_textedit_clamp(str, state)
    elseif key == bit.bor(STB_TEXTEDIT_K_RIGHT, STB_TEXTEDIT_K_SHIFT) then
        stb_textedit_prep_selection_at_cursor(state)
        -- move selection right
        state.select_end = IMSTB_TEXTEDIT_GETNEXTCHARINDEX(str, state.select_end)
        stb_textedit_clamp(str, state)
        state.cursor = state.select_end
        state.has_preferred_x = false
    elseif key == STB_TEXTEDIT_K_DOWN
        or key == bit.bor(STB_TEXTEDIT_K_DOWN, STB_TEXTEDIT_K_SHIFT)
        or key == STB_TEXTEDIT_K_PGDOWN
        or key == bit.bor(STB_TEXTEDIT_K_PGDOWN, STB_TEXTEDIT_K_SHIFT) then

        StbFindState_Reset(find)
        StbTexteditRow_Reset(row)
        local sel = (bit.band(key, STB_TEXTEDIT_K_SHIFT) ~= 0)
        local is_page = (bit.band(key, bit.bnot(STB_TEXTEDIT_K_SHIFT)) == STB_TEXTEDIT_K_PGDOWN)
        local row_count = is_page and state.row_count_per_page or 1

        if not is_page and state.single_line then
            -- on windows, up&down in single-line behave like left&right
            key = bit.bor(STB_TEXTEDIT_K_RIGHT, bit.band(key, STB_TEXTEDIT_K_SHIFT))
            goto retry
        end

        if sel then
            stb_textedit_prep_selection_at_cursor(state)
        elseif STB_TEXT_HAS_SELECTION(state) then
            stb_textedit_move_to_last(str, state)
        end

        -- compute current position of cursor point
        stb_textedit_clamp(str, state)
        stb_textedit_find_charpos(find, str, state.cursor, state.single_line)

        for j = 1, row_count do
            local goal_x = state.has_preferred_x and state.preferred_x or find.x
            local x
            local start = find.first_char + find.length

            if find.length == 0 then
                break
            end

            -- [IMGUI]
            -- going down while being on the last line shouldn't bring us to that line end
            --if STB_TEXTEDIT_GETCHAR(str, find.first_char + find.length - 1) ~= STB_TEXTEDIT_NEWLINE then
            --   break
            --end

            -- now find character position down a row
            state.cursor = start
            STB_TEXTEDIT_LAYOUTROW(row, str, state.cursor)
            x = row.x0
            local i = 1
            while i <= row.num_chars do
                local dx = STB_TEXTEDIT_GETWIDTH(str, start, i)
                local next = IMSTB_TEXTEDIT_GETNEXTCHARINDEX(str, state.cursor)
                x = x + dx
                if x > goal_x then
                    break
                end
                i = i + (next - state.cursor)
                state.cursor = next
            end
            stb_textedit_clamp(str, state)

            if state.cursor == find.first_char + find.length then
                str.LastMoveDirectionLR = ImGuiDir.Left
            end
            state.has_preferred_x = true
            state.preferred_x = goal_x

            if sel then
                state.select_end = state.cursor
            end

            -- go to next line
            find.first_char = find.first_char + find.length
            find.length = row.num_chars
        end
    elseif key == STB_TEXTEDIT_K_UP
        or key == bit.bor(STB_TEXTEDIT_K_UP, STB_TEXTEDIT_K_SHIFT)
        or key == STB_TEXTEDIT_K_PGUP
        or key == bit.bor(STB_TEXTEDIT_K_PGUP, STB_TEXTEDIT_K_SHIFT) then

        StbFindState_Reset(find)
        StbTexteditRow_Reset(row)
        local sel = (bit.band(key, STB_TEXTEDIT_K_SHIFT) ~= 0)
        local is_page = (bit.band(key, bit.bnot(STB_TEXTEDIT_K_SHIFT)) == STB_TEXTEDIT_K_PGUP)
        local row_count = is_page and state.row_count_per_page or 1

        if not is_page and state.single_line then
            -- on windows, up&down become left&right
            key = bit.bor(STB_TEXTEDIT_K_LEFT, bit.band(key, STB_TEXTEDIT_K_SHIFT))
            goto retry
        end

        if sel then
            stb_textedit_prep_selection_at_cursor(state)
        elseif STB_TEXT_HAS_SELECTION(state) then
            stb_textedit_move_to_first(state)
        end

        -- compute current position of cursor point
        stb_textedit_clamp(str, state)
        stb_textedit_find_charpos(find, str, state.cursor, state.single_line)

        for j = 1, row_count do
            local goal_x
            if state.has_preferred_x then
                goal_x = state.preferred_x
            else
                goal_x = find.x
            end
            local x

            -- can only go up if there's a previous row
            if find.prev_first == find.first_char then
                break
            end

            -- now find character position up a row
            state.cursor = find.prev_first
            STB_TEXTEDIT_LAYOUTROW(row, str, state.cursor)
            x = row.x0
            local i = 1
            while i <= row.num_chars do
                local dx = STB_TEXTEDIT_GETWIDTH(str, find.prev_first, i)
                local next = IMSTB_TEXTEDIT_GETNEXTCHARINDEX(str, state.cursor)
                x = x + dx
                if x > goal_x then
                    break
                end
                i = i + (next - state.cursor)
                state.cursor = next
            end
            stb_textedit_clamp(str, state)

            if state.cursor == find.first_char then
                str.LastMoveDirectionLR = ImGuiDir.Right
            elseif state.cursor == find.prev_first then
                str.LastMoveDirectionLR = ImGuiDir.Left
            end
            state.has_preferred_x = true
            state.preferred_x = goal_x

            if sel then
                state.select_end = state.cursor
            end

            -- go to previous line
            -- (we need to scan previous line the hard way. maybe we could expose this as a new API function?)
            local prev_scan = find.prev_first > 1 and find.prev_first - 1 or 1
            while prev_scan > 1 do
                local prev = IMSTB_TEXTEDIT_GETPREVCHARINDEX(str, prev_scan)
                if STB_TEXTEDIT_GETCHAR(str, prev) == STB_TEXTEDIT_NEWLINE then
                    break
                end
                prev_scan = prev
            end
            find.first_char = find.prev_first
            find.prev_first = STB_TEXTEDIT_MOVELINESTART(str, state, prev_scan)
        end
    elseif key == STB_TEXTEDIT_K_DELETE
        or key == bit.bor(STB_TEXTEDIT_K_DELETE, STB_TEXTEDIT_K_SHIFT) then

        if STB_TEXT_HAS_SELECTION(state) then
            stb_textedit_delete_selection(str, state)
        else
            local n = STB_TEXTEDIT_STRINGLEN(str)
            if state.cursor <= n then
                stb_textedit_delete(str, state, state.cursor, IMSTB_TEXTEDIT_GETNEXTCHARINDEX(str, state.cursor) - state.cursor)
            end
        end
        state.has_preferred_x = false
    elseif key == STB_TEXTEDIT_K_BACKSPACE
        or key == bit.bor(STB_TEXTEDIT_K_BACKSPACE, STB_TEXTEDIT_K_SHIFT) then

        if STB_TEXT_HAS_SELECTION(state) then
            stb_textedit_delete_selection(str, state)
        else
            stb_textedit_clamp(str, state)
            if state.cursor > 1 then
                local prev = IMSTB_TEXTEDIT_GETPREVCHARINDEX(str, state.cursor)
                stb_textedit_delete(str, state, prev, state.cursor - prev)
                state.cursor = prev
            end
        end
        state.has_preferred_x = false
    elseif key == STB_TEXTEDIT_K_TEXTSTART then
        state.cursor = 1
        state.select_start = 1
        state.select_end = 1
        state.has_preferred_x = false
    elseif key == STB_TEXTEDIT_K_TEXTEND then
        state.cursor = STB_TEXTEDIT_STRINGLEN(str) + 1
        state.select_start = 1
        state.select_end = 1
        state.has_preferred_x = false
    elseif key == bit.bor(STB_TEXTEDIT_K_TEXTSTART, STB_TEXTEDIT_K_SHIFT) then
        stb_textedit_prep_selection_at_cursor(state)
        state.cursor = 1
        state.select_end = 1
        state.has_preferred_x = false
    elseif key == bit.bor(STB_TEXTEDIT_K_TEXTEND, STB_TEXTEDIT_K_SHIFT) then
        stb_textedit_prep_selection_at_cursor(state)
        state.cursor = STB_TEXTEDIT_STRINGLEN(str) + 1
        state.select_end = state.cursor
        state.has_preferred_x = false
    elseif key == STB_TEXTEDIT_K_LINESTART then
        stb_textedit_clamp(str, state)
        stb_textedit_move_to_first(state)
        state.cursor = STB_TEXTEDIT_MOVELINESTART(str, state, state.cursor)
        state.has_preferred_x = false
    elseif key == STB_TEXTEDIT_K_LINEEND then
        stb_textedit_clamp(str, state)
        stb_textedit_move_to_last(str, state)
        state.cursor = STB_TEXTEDIT_MOVELINEEND(str, state, state.cursor)
        state.has_preferred_x = false
    elseif key == bit.bor(STB_TEXTEDIT_K_LINESTART, STB_TEXTEDIT_K_SHIFT) then
        stb_textedit_clamp(str, state)
        stb_textedit_prep_selection_at_cursor(state)
        state.cursor = STB_TEXTEDIT_MOVELINESTART(str, state, state.cursor)
        state.select_end = state.cursor
        state.has_preferred_x = false
    elseif key == bit.bor(STB_TEXTEDIT_K_LINEEND, STB_TEXTEDIT_K_SHIFT) then
        stb_textedit_clamp(str, state)
        stb_textedit_prep_selection_at_cursor(state)
        state.cursor = STB_TEXTEDIT_MOVELINEEND(str, state, state.cursor)
        state.select_end = state.cursor
        state.has_preferred_x = false
    end
end

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

-- discard the oldest entry in the redo list--it's bad if this
-- ever happens, but because undo & redo have to store the actual
-- characters in different cases, the redo character buffer can
-- fill up even though the undo buffer didn't
--- @param state StbUndoState
local function stb_textedit_discard_redo(state)
    local k = IMSTB_TEXTEDIT_UNDOSTATECOUNT

    if state.redo_point <= k then
        -- if the k'th undo state has characters, clean those up
        if state.undo_rec[k].char_storage >= 1 then
            local n = state.undo_rec[k].insert_length
            -- move the remaining redo character data to the end of the buffer
            state.redo_char_point = state.redo_char_point + n
            IMSTB_TEXTEDIT_memmove(state.undo_char, state.redo_char_point, state.undo_char, state.redo_char_point - n, IMSTB_TEXTEDIT_UNDOCHARCOUNT - state.redo_char_point + 1)
            -- adjust the position of all the other records to account for above memmove
            for i = state.redo_point, k - 1 do
                if state.undo_rec[i].char_storage >= 1 then
                    state.undo_rec[i].char_storage = state.undo_rec[i].char_storage + n
                end
            end
        end

        -- now move all the redo records towards the end of the buffer; the first one is at 'redo_point'
        -- [IMGUI]
        local move_size = IMSTB_TEXTEDIT_UNDOSTATECOUNT - state.redo_point - 1
        IMSTB_TEXTEDIT_memmove(state.undo_rec, state.redo_point + 1, state.undo_rec, state.redo_point, move_size)

        -- now move redo_point to point to the new one
        state.redo_point = state.redo_point + 1
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
function stb_text_undo(str, state)
    local s = state.undostate

    if s.undo_point == 1 then
        return
    end

    -- we need to do two things: apply the undo record, and create a redo record
    local u = s.undo_rec[s.undo_point - 1]
    local r = s.undo_rec[s.redo_point - 1]
    r.char_storage = -1

    r.insert_length = u.delete_length
    r.delete_length = u.insert_length
    r.where = u.where

    if u.delete_length > 0 then
        -- if the undo record says to delete characters, then the redo record will
        -- need to re-insert the characters that get deleted, so we need to store
        -- them.

        -- there are three cases:
        --    there's enough room to store the characters
        --    characters stored for *redoing* don't leave room for redo
        --    characters stored for *undoing* don't leave room for redo
        -- if the last is true, we have to bail

        if s.undo_char_point + u.delete_length > IMSTB_TEXTEDIT_UNDOCHARCOUNT then
            -- the undo records take up too much character space; there's no space to store the redo characters
            r.insert_length = 0
        else
            -- there's definitely room to store the characters eventually
            while s.undo_char_point + u.delete_length > s.redo_char_point do
                -- should never happen:
                if s.redo_point == IMSTB_TEXTEDIT_UNDOSTATECOUNT + 1 then
                    return
                end

                -- there's currently not enough room, so discard a redo record
                stb_textedit_discard_redo(s)
            end
            r = s.undo_rec[s.redo_point - 1]

            r.char_storage = s.redo_char_point - u.delete_length
            s.redo_char_point = s.redo_char_point - u.delete_length

            -- now save the characters
            for i = 0, u.delete_length - 1 do
                s.undo_char[r.char_storage + i] = STB_TEXTEDIT_GETCHAR(str, u.where + i)
            end
        end

        -- now we can carry out the deletion
        STB_TEXTEDIT_DELETECHARS(str, u.where, u.delete_length)
    end

    -- check type of recorded action:
    if u.insert_length > 0 then
        -- easy case: was a deletion, so we need to insert n characters
        u.insert_length = STB_TEXTEDIT_INSERTCHARS(str, u.where, s.undo_char, u.char_storage, u.insert_length)
        s.undo_char_point = s.undo_char_point - u.insert_length
    end

    state.cursor = u.where + u.insert_length

    s.undo_point = s.undo_point - 1
    s.redo_point = s.redo_point - 1
end

--- @param str   IMSTB_TEXTEDIT_STRING
--- @param state STB_TexteditState
function stb_text_redo(str, state)
    local s = state.undostate
    if s.undo_point == IMSTB_TEXTEDIT_UNDOSTATECOUNT + 1 then
        return
    end

    -- we need to do two things: apply the redo record, and create an undo record
    local u = s.undo_rec[s.undo_point]
    local r = s.undo_rec[s.redo_point]

    u.delete_length = r.insert_length
    u.insert_length = r.delete_length
    u.where = r.where
    u.char_storage = -1

    if r.delete_length > 0 then
        -- the redo record requires us to delete characters, so the undo record
        -- needs to store the characters
        if s.undo_char_point + u.insert_length > s.redo_char_point then
            u.insert_length = 0
            u.delete_length = 0
        else
            u.char_storage = s.undo_char_point
            s.undo_char_point = s.undo_char_point + u.insert_length

            for i = 0, u.insert_length - 1 do
                s.undo_char[u.char_storage + i] = STB_TEXTEDIT_GETCHAR(str, u.where + i)
            end
        end

        STB_TEXTEDIT_DELETECHARS(str, r.where, r.delete_length)
    end

    if r.insert_length ~= 0 then
        r.insert_length = STB_TEXTEDIT_INSERTCHARS(str, r.where, s.undo_char, r.char_storage, r.insert_length)
        s.redo_char_point = s.redo_char_point + r.insert_length
    end

    state.cursor = r.where + r.insert_length

    s.undo_point = s.undo_point + 1
    s.redo_point = s.redo_point + 1
end

--- @param state  STB_TexteditState
--- @param where  int
--- @param length int
function stb_text_makeundo_insert(state, where, length)
    stb_text_createundo(state.undostate, where, 0, length)
end

--- @param str    IMSTB_TEXTEDIT_STRING
--- @param state  STB_TexteditState
--- @param where  int
--- @param length int
function stb_text_makeundo_delete(str, state, where, length)
    local s = state.undostate
    local p = stb_text_createundo(s, where, length, 0)
    if p then
        for i = 0, length - 1 do
            s.undo_char[p + i] = STB_TEXTEDIT_GETCHAR(str, where + i)
        end
    end
end

--- @param str        IMSTB_TEXTEDIT_STRING
--- @param state      STB_TexteditState
--- @param where      int
--- @param old_length int
--- @param new_length int
function stb_text_makeundo_replace(str, state, where, old_length, new_length)
    local s = state.undostate
    local p = stb_text_createundo(s, where, old_length, new_length)
    if p then
        for i = 0, old_length - 1 do
            s.undo_char[p + i] = STB_TEXTEDIT_GETCHAR(str, where + i)
        end
    end
end

--- @param state          STB_TexteditState
--- @param is_single_line bool
local function stb_textedit_clear_state(state, is_single_line)
    state.undostate.undo_point = 1
    state.undostate.undo_char_point = 1
    state.undostate.redo_point = IMSTB_TEXTEDIT_UNDOSTATECOUNT + 1
    state.undostate.redo_char_point = IMSTB_TEXTEDIT_UNDOCHARCOUNT + 1
    state.select_end = 1
    state.select_start = 1
    state.cursor = 1
    state.has_preferred_x = false
    state.preferred_x = 0
    state.cursor_at_end_of_line = false
    state.initialized = true
    state.single_line = is_single_line
    state.insert_mode = false
    state.row_count_per_page = 0
end

return {
    click = stb_textedit_click,
    drag = stb_textedit_drag,
    createundo = stb_text_createundo,
    initialize_state = stb_textedit_clear_state,

    text = stb_textedit_text,
    key = stb_textedit_key,

    makeundo_replace = stb_text_makeundo_replace,

    clamp = stb_textedit_clamp,
    prep_selection_at_cursor = stb_textedit_prep_selection_at_cursor,
    cut = stb_textedit_cut,
    paste = stb_textedit_paste_internal,

    HAS_SELECTION = STB_TEXT_HAS_SELECTION
}