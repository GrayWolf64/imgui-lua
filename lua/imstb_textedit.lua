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

----------------------------------------
----------------------------------------
---
--- Implementation
---
---

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

local function stb_textedit_clear_state(state, is_single_line)

end

return {
    createundo = stb_text_createundo,
    initialize_state = stb_textedit_clear_state
}