--- This is a temporary load file script for testing ImGui
-- This also should be a preprocessor file that includes code into the imgui.lua file before it's executed
-- because GMod limits a file size compressed to 64kb, and the main file is growing so quickly
-- https://gcc.gnu.org/onlinedocs/cpp.pdf

local output_dir = "imgui_pp/"
file.CreateDir(output_dir)

local PATTERN_OP = "[%+%-*/%^%%#]"

--- Normally these are for internal use, and will be replaced
-- immediately after getting parsed
function IMGUI_DEFINE(_identifier, _token_string) error("Unexpected #define!", 2) end

function IMGUI_INCLUDE(_filename)
    local code = file.Read(output_dir .. string.StripExtension(_filename) .. ".txt", "DATA")
    if not code then error("IMGUI_INCLUDE couldn't find the file!", 2) end
    return CompileString(code, "IMGUI_INCLUDE")()
end

function IMGUI_PRAGMA_ONCE() error("Unexpected #pragma once!", 2) end

local function is_whitespace(c)
    return c == 32 or c == 9 or c == 10 or c == 13
end

local function is_alpha(c)
    return (c >= 65 and c <= 90) or (c >= 97 and c <= 122)
end

local function is_valid_identifier_char(c)
    return (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or
        (c >= 48 and c <= 57) or c == 95
end

local function skip_spaces(str, len, pos)
    while pos <= len and is_whitespace(string.byte(str, pos)) do pos = pos + 1 end
    return pos
end

local function skip_identifier(str, len, pos)
    while pos <= len and is_valid_identifier_char(string.byte(str, pos)) do pos = pos + 1 end
    return pos
end

local function trim_whitespace(s)
    return string.match(s, "^%s*(.-)%s*$")
end

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

local function parse_include(line)
    return string.match(line, "^IMGUI_INCLUDE%s*%(%s*\"([^\"]*)\"%s*%)\n?$")
end

local function parse_define(line)
    local pos, len = 1, #line
    if len < 12 then return nil end
    if line:sub(pos, pos + 11) ~= "IMGUI_DEFINE" then return nil end
    pos = pos + 12

    pos = skip_spaces(line, len, pos)
    if pos > len or line:sub(pos, pos) ~= "(" then return nil end
    pos = pos + 1

    pos = skip_spaces(line, len, pos)

    local name_start = pos
    pos = skip_identifier(line, len, pos)
    if pos == name_start then return nil end
    local name = line:sub(name_start, pos - 1)

    -- Check for function parameters
    local params, is_func = nil, false
    local j = pos
    j = skip_spaces(line, len, j)

    if j <= len and line:sub(j, j) == "(" then
        is_func, pos, params = true, j + 1, {}
        while true do
            pos = skip_spaces(line, len, pos)
            if pos > len then return nil end
            if line:sub(pos, pos) == ")" then pos = pos + 1; break end

            local param_start = pos
            pos = skip_identifier(line, len, pos)
            if pos == param_start then return nil end
            table.insert(params, line:sub(param_start, pos - 1))

            pos = skip_spaces(line, len, pos)
            local next_char = line:sub(pos, pos)
            if next_char == "," then pos = pos + 1
            elseif next_char == ")" then pos = pos + 1; break
            else return nil end
        end
    end

    pos = skip_spaces(line, len, pos)
    if pos > len or line:sub(pos, pos) ~= "," then return nil end
    pos = pos + 1

    pos = skip_spaces(line, len, pos)

    local value_start = pos
    local paren_depth = 0
    while pos <= len do
        local c = line:sub(pos, pos)
        if c == "(" then paren_depth = paren_depth + 1
        elseif c == ")" then
            if paren_depth == 0 then break end
            paren_depth = paren_depth - 1
        end
        pos = pos + 1
    end

    if pos > len then return nil end

    local raw = line:sub(value_start, pos - 1)
    -- if the whole body is one quoted string, unwrap it
    local str_open, str_close = raw:match('^%s*(["\'])(.*)%1%s*$')
    if str_close then
        -- honour Lua escapes so \" inside the string is kept correctly
        local body = str_close:gsub('\\(.)', '%1')   -- naive, good enough here
        return name, {type = is_func and "func" or "obj", params = params, body = body}
    else
        return name, {type = is_func and "func" or "obj", params = params, body = raw}
    end
end

local function substitute_params(body, params, args)
    local param_map = {}
    for i, param in ipairs(params) do
        if string.find(args[i], PATTERN_OP) then
            param_map[param] = "(" .. args[i] .. ")"
        else
            param_map[param] = args[i]
        end
    end

    return string.gsub(body, "[%a_][%w_]*", function(word)
        return param_map[word] or word
    end)
end

local function expand_line(line, defines, seen)
    seen = seen or {}
    local result, i, len = {}, 1, #line
    local expanded_any = false

    while i <= len do
        local c = string.byte(line, i)
        if is_alpha(c) or c == 95 then
            local word_start = i
            i = skip_identifier(line, len, i)
            local word = line:sub(word_start, i - 1)

            local macro = defines[word]
            if macro and not seen[word] then
                if macro.type == "func" then
                    local j = i
                    j = skip_spaces(line, len, j)

                    if j <= len and line:sub(j, j) == "(" then
                        local args, arg_start, paren_depth = {}, j + 1, 1
                        local arg_pos = arg_start

                        while arg_pos <= len and paren_depth > 0 do
                            local ch = line:sub(arg_pos, arg_pos)
                            if ch == "(" then paren_depth = paren_depth + 1
                            elseif ch == ")" then
                                paren_depth = paren_depth - 1
                                if paren_depth == 0 then
                                    if arg_pos > arg_start then args[#args + 1] = trim_whitespace(line:sub(arg_start, arg_pos - 1)) end
                                    break
                                end
                            elseif ch == "," and paren_depth == 1 then
                                args[#args + 1] = trim_whitespace(line:sub(arg_start, arg_pos - 1))
                                arg_start = arg_pos + 1
                            end
                            arg_pos = arg_pos + 1
                        end

                        if paren_depth == 0 and #args == #macro.params then
                            seen[word] = true
                            expanded_any = true

                            local expanded_args = {}
                            for k, arg in ipairs(args) do
                                local exp_arg, child_expanded = expand_line(arg, defines, seen)
                                expanded_args[k] = exp_arg
                                expanded_any = expanded_any or child_expanded
                            end

                            local body_with_args = substitute_params(macro.body, macro.params, expanded_args)
                            local expanded_body, body_expanded = expand_line(body_with_args, defines, seen)
                            expanded_any = expanded_any or body_expanded
                            table.insert(result, expanded_body)

                            i = arg_pos + 1
                            seen[word] = nil
                        else
                            table.insert(result, word)
                        end
                    else
                        table.insert(result, word)
                    end
                else
                    seen[word] = true
                    expanded_any = true
                    local expanded, child_expanded = expand_line(macro.body, defines, seen)
                    expanded_any = expanded_any or child_expanded
                    table.insert(result, expanded)
                    seen[word] = nil
                end
            else
                table.insert(result, word)
            end
        else
            table.insert(result, string.char(c))
            i = i + 1
        end
    end

    return table.concat(result), expanded_any
end

local function process_file(filepath, depth, defines, include_stack)
    if depth > 8 then error("Circular IMGUI_INCLUDE in " .. filepath) end

    for i = 1, #include_stack do
        if include_stack[i] == filepath then return "" end
    end

    local lines = read_lines(filepath)
    table.insert(include_stack, filepath)
    local output = {}

    for line_num, line in ipairs(lines) do
        local include_path = parse_include(line)
        local def_name, macro = parse_define(line)

        if include_path then
            local included = process_file(include_path, depth + 1, defines, include_stack)
            if included then table.insert(output, included) end
        elseif def_name then
            defines[def_name] = macro
            table.insert(output, string.format("--[[ #define %s%s %s ]]--\n",
                def_name,
                macro.type == "func" and ("(" .. table.concat(macro.params, ", ") .. ")") or "",
                macro.body))
        else
            local expanded_line, did_expand = expand_line(line, defines)

            table.insert(output, expanded_line)
        end
    end

    table.remove(include_stack)
    return table.concat(output)
end

local defines = {}
local include_stack = {}

local processed = process_file("imgui.lua", 0, defines, include_stack)
file.Write(output_dir .. "imgui.txt", processed)

--- Temporary
CompileString(processed, "ImGui")()

defines = {}
include_stack = {}
processed = process_file("imgui_impl_gmod.lua", 0, defines, include_stack)
file.Write(output_dir .. "imgui_impl_gmod.txt", processed)