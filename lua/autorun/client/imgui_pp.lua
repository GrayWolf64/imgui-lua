--- This is a temporary load file script for testing ImGui
-- This also should be a preprocessor file that includes code into the imgui.lua file before it's executed
-- because GMod limits a file size compressed to 64kb, and the main file is growing so quickly
-- https://gcc.gnu.org/onlinedocs/cpp.pdf

local output_dir = "imgui_pp/"
file.CreateDir(output_dir)

local PATTERN_OP = "[%+%-*/%^%%#<>]"

--- @type integer
local NEW_LINE = string.byte("\n")
--- @type integer
local PAREN_LEFT = string.byte("(")
--- @type integer
local PAREN_RIGHT = string.byte(")")
--- @type integer
local COMMA = string.byte(",")
--- @type integer
local BACKSLASH = string.byte("\\")

--- @class pp_macro
--- @field name string
--- @field type string
--- @field param_names string[]
--- @field replacement string
--- @field no_expand boolean

--- @return pp_macro
local function pp_macro()
    return {
        name        = nil,
        type        = nil,
        param_names = nil,
        replacement = nil,
        no_expand   = nil
    }
end

--- Normally these are for internal use, and will be replaced
-- immediately after getting parsed
function IMGUI_DEFINE(_identifier, _substitution) error("Unexpected #define!", 2) end

function IMGUI_INCLUDE(_filename)
    local code = file.Read(output_dir .. string.StripExtension(_filename) .. ".txt", "DATA")
    if not code then error("IMGUI_INCLUDE couldn't find the file!", 2) end
    return CompileString(code, "IMGUI_INCLUDE")()
end

function IMGUI_PRAGMA_ONCE() error("Unexpected #pragma once!", 2) end

--- @param c integer
local function is_whitespace(c)
    return c == 32 or c == 9 or c == 10 or c == 13
end

--- @param c integer
local function is_alpha(c)
    return (c >= 65 and c <= 90) or (c >= 97 and c <= 122)
end

--- @param c integer
local function is_identifier_start(c)
    return (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95
end

--- @param c integer
local function is_valid_identifier_char(c)
    return (c >= 48 and c <= 57) or is_identifier_start(c)
end

--- Returns the position where the first non-whitespace character is seen after the `pos`
--- @param str string
--- @param len integer
--- @param pos integer
--- @return integer
local function skip_spaces(str, len, pos)
    while pos <= len and is_whitespace(string.byte(str, pos)) do pos = pos + 1 end
    return pos
end

--- @param str string
--- @param len integer
--- @param pos integer
--- @return integer
local function skip_identifier(str, len, pos)
    while pos <= len and is_valid_identifier_char(string.byte(str, pos)) do pos = pos + 1 end
    return pos
end

--- @param str string
--- @return string
local function trim_whitespace(str)
    return string.match(str, "^%s*(.-)%s*$")
end

--- @param filepath string
--- @return string[]?
local function read_lines(filepath)
    local f = file.Open(filepath, "r", "LUA")
    if not f then error("File not found: " .. filepath) end

    local lines = {}
    while not f:EndOfFile() do
        lines[#lines + 1] = f:ReadLine()
    end
    f:Close()

    return lines
end

local DIRECTIVE_INCLUDE = "#IMGUI_INCLUDE"
local DIRECTIVE_DEFINE  = "#IMGUI_DEFINE"

--- #IMGUI_INCLUDE "filename.lua"
--- @param line string
--- @return string
local function parse_include(line)
    return string.match(line, "^" .. DIRECTIVE_INCLUDE .. "%s*\"([^\"]*)\"%s*\n?$")
end

--- @param line string
--- @return pp_macro?
local function parse_define(line)
    local pos, len = 1, #line

    if len < #DIRECTIVE_DEFINE then return nil end

    if string.sub(line, pos, pos + #DIRECTIVE_DEFINE - 1) ~= DIRECTIVE_DEFINE then return nil end
    pos = pos + #DIRECTIVE_DEFINE

    pos = skip_spaces(line, len, pos)
    -- if pos > len then return nil end

    -- Gets the object name and potentially function name
    local name_start = pos
    pos = skip_identifier(line, len, pos)
    if pos == name_start then return nil end
    local name = line:sub(name_start, pos - 1)

    local params, is_func = {}, false
    local j = pos

    if j > len then return nil end

    -- function-like macro must have left paren close to identifier end
    -- e.g. #define macro_name(p1, p2) p1 + p2
    if string.byte(line, j) == PAREN_LEFT then
        is_func, pos, params = true, j + 1, {}

        while true do
            pos = skip_spaces(line, len, pos)
            if pos > len then return nil end
            if string.byte(line, pos) == PAREN_RIGHT then
                pos = pos + 1

                break
            end

            local param_start = pos
            pos = skip_identifier(line, len, pos)
            if pos == param_start then return nil end
            table.insert(params, line:sub(param_start, pos - 1))

            pos = skip_spaces(line, len, pos)

            --- @type integer
            local next_char = string.byte(line, pos)

            if next_char == COMMA then -- still have param remaining
                pos = pos + 1
            elseif next_char == PAREN_RIGHT then -- param list ends
                pos = pos + 1

                break
            else -- invalid
                return nil
            end
        end
    end

    -- the separator between _identifier and _substitution must be one or more whitespace(s)
    if not is_whitespace(string.byte(line, pos)) then return nil end
    pos = skip_spaces(line, len, pos)

    local startpos = pos
    local endpos = len
    while pos <= len do
        --- @type integer
        local c = string.byte(line, pos)

        if c == NEW_LINE then
            if string.byte(line, pos - 1) == BACKSLASH then -- directive continues to the next line
                -- TODO:
            else -- directive ends
                endpos = pos - 1
                break
            end
        end

        pos = pos + 1
    end

    local macro = pp_macro()

    macro.name        = name
    macro.type        = is_func and "func" or "obj"
    macro.param_names = params
    macro.no_expand   = false
    macro.replacement = line:sub(startpos, endpos)

    return macro
end

--- @param line string
--- @param start_pos integer
--- @return table, integer
local function invocation_parse_args(line, start_pos)
    local args, arg_start, depth = {}, start_pos + 1, 1
    local i = arg_start
    local len = #line

    while i <= len and depth > 0 do
        local b = string.byte(line, i)
        if b == PAREN_LEFT then
            depth = depth + 1
        elseif b == PAREN_RIGHT then
            depth = depth - 1
            if depth == 0 then
                if i > arg_start then
                    table.insert(args, line:sub(arg_start, i - 1))
                end

                return args, i - start_pos + 1
            end
        elseif b == COMMA and depth == 1 then
            table.insert(args, line:sub(arg_start, i - 1))
            arg_start = i + 1
        end

        i = i + 1
    end

    return args, i - start_pos
end

--- Recursively expands macros in a string
--- @param str string
--- @param expanding table<string,boolean> Macros being expanded in current call chain
--- @return string, boolean
local function expand_recursive(str, defines, expanding)
    local result = {}
    local i = 1
    local len = #str
    local did_expand = false

    while i <= len do
        local c = string.byte(str, i)

        -- Preserve whitespace
        if is_whitespace(c) then
            local start = i
            i = skip_spaces(str, len, i)
            table.insert(result, str:sub(start, i - 1))
        -- Check for potential macro name
        elseif is_identifier_start(c) then
            local name_start = i
            i = skip_identifier(str, len, i)
            local name = str:sub(name_start, i - 1)

            local macro = defines[name]
            if macro and not expanding[name] then
                if macro.type == "obj" then
                    -- Object-like macro: replace with definition
                    expanding[name] = true
                    local expanded, _ = expand_recursive(macro.replacement, defines, expanding)
                    expanding[name] = nil
                    table.insert(result, expanded)
                    did_expand = true
                elseif macro.type == "func" then
                    -- Function-like macro: check for parentheses
                    local next_pos = skip_spaces(str, len, i)
                    if next_pos <= len and string.byte(str, next_pos) == PAREN_LEFT then
                        local args, consumed = invocation_parse_args(str, next_pos)

                        -- Only expand if argument count matches
                        if #args == #macro.param_names then
                            -- Expand arguments recursively
                            for j = 1, #args do
                                args[j] = trim_whitespace(args[j])
                                args[j], _ = expand_recursive(args[j], defines, expanding)
                            end

                            -- Map parameters to arguments
                            local param_map = {}
                            for j = 1, #macro.param_names do
                                param_map[macro.param_names[j]] = args[j]
                            end

                            -- Substitute parameters in replacement
                            local repl = macro.replacement
                            local repl_result = {}
                            local repl_i = 1
                            local repl_len = #repl

                            while repl_i <= repl_len do
                                local rc = string.byte(repl, repl_i)

                                if is_whitespace(rc) then
                                    local sp_start = repl_i
                                    repl_i = skip_spaces(repl, repl_len, repl_i)
                                    table.insert(repl_result, repl:sub(sp_start, repl_i - 1))
                                elseif is_identifier_start(rc) then
                                    local id_start = repl_i
                                    repl_i = skip_identifier(repl, repl_len, repl_i)
                                    local id_name = repl:sub(id_start, repl_i - 1)

                                    if param_map[id_name] then
                                        table.insert(repl_result, param_map[id_name])
                                    else
                                        table.insert(repl_result, repl:sub(id_start, repl_i - 1))
                                    end
                                else
                                    table.insert(repl_result, string.char(rc))
                                    repl_i = repl_i + 1
                                end
                            end

                            -- Recursively expand the substituted replacement
                            expanding[name] = true
                            local final_expanded, _ = expand_recursive(table.concat(repl_result), defines, expanding)
                            expanding[name] = nil

                            table.insert(result, final_expanded)
                            did_expand = true
                            i = next_pos + consumed
                        else
                            -- Wrong number of arguments, don't expand
                            table.insert(result, str:sub(name_start, i - 1))
                        end
                    else
                        -- No parentheses, don't expand
                        table.insert(result, str:sub(name_start, i - 1))
                    end
                end
            else
                -- Not a macro or currently expanding
                table.insert(result, str:sub(name_start, i - 1))
            end
        else
            -- Regular character
            table.insert(result, string.char(c))
            i = i + 1
        end
    end

    return table.concat(result), did_expand
end

--- Expands macros in a line of code
--- @param line string
--- @param defines pp_macro[]
--- @return string expanded_line, boolean did_expand
local function expand_line(line, defines)
    -- Track macros currently being expanded to prevent infinite recursion
    local expanding = {}

    return expand_recursive(line, defines, expanding)
end

local function process_file(filepath, depth, defines, include_stack, do_save)
    if depth > 8 then error("Circular IMGUI_INCLUDE in " .. filepath) end

    for i = 1, #include_stack do
        if include_stack[i] == filepath then return "" end
    end

    local lines = read_lines(filepath)
    if not lines then return end

    table.insert(include_stack, filepath)
    local output = {}

    for line_num, line in ipairs(lines) do
        local include_path = parse_include(line)
        local macro = parse_define(line)

        if include_path then
            local included = process_file(include_path, depth + 1, defines, include_stack)
            if included then table.insert(output, included) end
        elseif macro then
            defines[macro.name] = macro
            table.insert(output, string.format("--[[ #define %s%s %s ]]--\n",
                macro.name,
                macro.type == "func" and ("(" .. table.concat(macro.param_names, ", ") .. ")") or "",
                macro.replacement))
        else
            local expanded_line, did_expand = expand_line(line, defines)

            table.insert(output, expanded_line)
        end
    end

    table.remove(include_stack)

    local processed = table.concat(output)
    if do_save then
        file.Write(output_dir .. string.StripExtension(string.GetFileFromFilename(filepath)) .. ".txt", processed)
    end

    return processed
end

local defines = {}
local include_stack = {}

local processed = process_file("imgui.lua", 0, defines, include_stack, true)

--- Temporary
if processed then
    CompileString(processed, "ImGui")()
end

defines = {}
include_stack = {}
processed = process_file("imgui_impl_gmod.lua", 0, defines, include_stack, true)