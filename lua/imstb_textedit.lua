--- ImGui Sincerely
-- This is a Lua port of original `imstb_textedit.h`

-- ALL TABLES IN THIS FILE ARE 1-BASED!

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

IMSTB_TEXTEDIT_UNDOSTATECOUNT = 99
IMSTB_TEXTEDIT_UNDOCHARCOUNT  = 999

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
--- @field undo_point      short
--- @field redo_point      short
--- @field undo_char_point int
--- @field redo_char_point int

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

        undo_point      = 0,
        redo_point      = 0,
        undo_char_point = 0,
        redo_char_point = 0
    }
end

--- @class STB_TexteditState
--- @field cursor                int           # position of the text cursor within the string
--- @field select_start          int           # selection start point
--- @field select_end            int
--- @field insert_mode           unsigned_char
--- @field row_count_per_page    int
--- @field cursor_at_end_of_line unsigned_char
--- @field initialized           unsigned_char
--- @field has_preferred_x       unsigned_char
--- @field single_line           unsigned_char
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

        insert_mode = 0,

        row_count_per_page = 0,

        cursor_at_end_of_line = 0,
        initialized           = 0,
        has_preferred_x       = 0,
        single_line           = 0,
        padding1              = 0,
        padding2              = 0,
        padding3              = 0,

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
--- TODO: Implementation
---
---
