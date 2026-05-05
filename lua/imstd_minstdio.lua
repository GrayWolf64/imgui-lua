--- ImGui Sincerely
-- This is a minimal Lua impl of C-like sscanf, sprintf sub-set

-- Supports:
-- - %x, %X, %nx, %nX (where n is a number)
-- - %d, %nd (where n is a number)
--
-- Returns items_matched instead of EOF on error

local _byte = string.byte

local CHAR_PERCENT = _byte'%'
local CHAR_PLUS = _byte'+'
local CHAR_MINUS = _byte'-'
local CHAR_0 = _byte'0'
local CHAR_9 = _byte'9'
local CHAR_a = _byte'a'
local CHAR_A = _byte'A'
local CHAR_d = _byte'd'
local CHAR_f = _byte'f'
local CHAR_F = _byte'F'
local CHAR_x = _byte'x'
local CHAR_X = _byte'X'

local function isspace(c) return c == 32 or c == 9 end
local function isdigit(c) return c >= CHAR_0 and c <= CHAR_9 end
local function isxdigit(c) return isdigit(c) or (c >= CHAR_a and c <= CHAR_f) or (c >= CHAR_A and c <= CHAR_F) end

local function isdigit_under_base(c, base)
    if     base == 10 then return isdigit(c)
    elseif base == 16 then return isxdigit(c)
    end
end

local function hex_digit_to_int(c)
    if c >= CHAR_0 and c <= CHAR_9 then return c - CHAR_0 end
    if c >= CHAR_a and c <= CHAR_f then return c - CHAR_a + 10 end
    if c >= CHAR_A and c <= CHAR_F then return c - CHAR_A + 10 end
end

--- @param buffer       char[]
--- @param buffer_begin int
--- @param format       string
--- @param result       table  # table to store parsed values
local function sscanf(buffer, buffer_begin, format, result)
    local p = buffer_begin
    local f = 1 -- format_begin
    local format_len = #format
    local assigned = 0
    local items_matched = 0

    while f <= format_len do
        if isspace(_byte(format, f, f)) then
            while isspace(buffer[p]) do
                p = p + 1
            end
            f = f + 1

            goto outer_continue
        end

        if _byte(format, f, f) ~= CHAR_PERCENT then
            if buffer[p] == _byte(format, f, f) then
                p = p + 1
                f = f + 1
            else
                return items_matched
            end

            goto outer_continue
        end

        -- encountered % in fmt
        f = f + 1

        -- %%
        if _byte(format, f, f) == CHAR_PERCENT then
            if buffer[p] == CHAR_PERCENT then
                p = p + 1
                f = f + 1
            else
                return items_matched
            end
        end

        -- handle optional width
        local width = 0
        while isdigit(_byte(format, f, f)) do
            width = width * 10 + _byte(format, f, f) - CHAR_0
            f = f + 1
        end
        if width == 0 then
            width = math.huge
        end

        local spec = _byte(format, f, f)
        local base
        if     spec == CHAR_x or spec == CHAR_X then
            base = 16
        elseif spec == CHAR_d then
            base = 10
        else
            return items_matched
        end
        f = f + 1

        do
            while isspace(buffer[p]) do
                p = p + 1
            end

            local negative = false
            -- optional sign
            if base == 10 then
                if     buffer[p] == CHAR_PLUS then
                    p = p + 1
                    width = width -1
                elseif buffer[p] == CHAR_MINUS then
                    negative = true
                    p = p + 1
                    width = width - 1
                end
            end

            local p_start = p
            while width > 0 and buffer[p] and isdigit_under_base(buffer[p], base) do
                p = p + 1
                width = width - 1
            end

            if p == p_start then
                -- failed to match
                return items_matched
            end

            local val = 0
            while p_start < p do
                local c = buffer[p_start]
                p_start = p_start + 1
                val = val * base + hex_digit_to_int(c)
            end

            result[assigned + 1] = negative and -val or val
            assigned = assigned + 1
            items_matched = items_matched + 1
        end

        :: outer_continue ::
    end

    return items_matched
end

local function sprintf()

end

return sscanf