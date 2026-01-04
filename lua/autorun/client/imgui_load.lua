--- This is a temporary load file script for testing ImGui
-- This also should be a preprocessor file that includes code into the imgui.lua file before it's executed
-- because GMod limits a file size compressed to 64kb, and the main file is growing so quickly
-- https://gcc.gnu.org/onlinedocs/cpp.pdf

local function is_whitespace(c)
    local b = string.byte(c)
    return b == 32 or b == 9 or b == 10 or b == 13
end

local function is_alpha(c)
    local b = string.byte(c)
    return (b >= 65 and b <= 90) or (b >= 97 and b <= 122)
end

local function is_digit(c)
    local b = string.byte(c)
    return b >= 48 and b <= 57
end

local function is_alnum_or_underscore(c)
    local b = string.byte(c)
    return (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or
        (b >= 48 and b <= 57) or b == 95
end

local function skip_spaces(str, len, pos)
    while pos <= len and is_whitespace(string.sub(str, pos, pos)) do pos = pos + 1 end
    return pos
end

local function read_lines(filepath)
    local content = file.Read(filepath, "LUA")
    if not content then error("File not found: " .. filepath) end

    local lines = {}
    local start = 1
    local i = 1

    while i <= #content do
        local c = string.sub(content, i, i)

        if c == "\n" or c == "\r" then
            table.insert(lines, string.sub(content, start, i))
            start = i + 1
        end
        i = i + 1
    end

    if start <= #content then
        table.insert(lines, string.sub(content, start))
    end

    return lines
end

local function parse_include(line)
    local pos = 1
    local len = #line

    if len < 13 then return nil end
    if string.sub(line, pos, pos + 12) ~= "IMGUI_INCLUDE" then return nil end
    pos = pos + 13

    pos = skip_spaces(line, len, pos)

    if pos > len or string.sub(line, pos, pos) ~= "(" then return nil end
    pos = pos + 1

    pos = skip_spaces(line, len, pos)
    if pos > len or string.sub(line, pos, pos) ~= "\"" then return nil end
    pos = pos + 1

    local start = pos
    while pos <= len and string.sub(line, pos, pos) ~= "\"" do pos = pos + 1 end
    if pos > len then return nil end
    local path = string.sub(line, start, pos - 1)
    pos = pos + 1

    pos = skip_spaces(line, len, pos)
    if pos > len or string.sub(line, pos, pos) ~= ")" then return nil end

    return path
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
    while pos <= len and is_alnum_or_underscore(line:sub(pos, pos)) do pos = pos + 1 end
    if pos == name_start then return nil end
    local name = line:sub(name_start, pos - 1)

    -- Check for function parameters
    local params, is_func = nil, false
    local j = pos
    while j <= len and is_whitespace(line:sub(j, j)) do j = j + 1 end

    if j <= len and line:sub(j, j) == "(" then
        is_func, pos, params = true, j + 1, {}
        while true do
            pos = skip_spaces(line, len, pos)
            if pos > len then return nil end
            if line:sub(pos, pos) == ")" then pos = pos + 1; break end

            local param_start = pos
            while pos <= len and is_alnum_or_underscore(line:sub(pos, pos)) do pos = pos + 1 end
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
    local value = line:sub(value_start, pos - 1)

    return name, {type = is_func and "func" or "obj", params = params, body = value}
end

local function substitute_params(body, params, args)
    local param_map = {}
    for i, param in ipairs(params) do
        param_map[param] = "(" .. args[i] .. ")"  -- AUTO-PARENTHESIZE to prevent precedence bugs
    end

    local result, i, len = {}, 1, #body
    while i <= len do
        local c = body:sub(i, i)
        if is_alpha(c) or c == "_" then
            local word_start = i
            while i <= len and is_alnum_or_underscore(body:sub(i, i)) do i = i + 1 end
            local word = body:sub(word_start, i - 1)
            table.insert(result, param_map[word] or word)
        else
            table.insert(result, c)
            i = i + 1
        end
    end
    return table.concat(result)
end

local function expand_line(line, defines, seen)
    seen = seen or {}
    local result, i, len = {}, 1, #line
    local expanded_any = false

    while i <= len do
        local c = line:sub(i, i)
        if is_alpha(c) or c == "_" then
            local word_start = i
            while i <= len and is_alnum_or_underscore(line:sub(i, i)) do i = i + 1 end
            local word = line:sub(word_start, i - 1)

            local macro = defines[word]
            if macro and not seen[word] then
                if macro.type == "func" then
                    local j = i
                    while j <= len and is_whitespace(line:sub(j, j)) do j = j + 1 end

                    if j <= len and line:sub(j, j) == "(" then
                        local args, arg_start, paren_depth = {}, j + 1, 1
                        local arg_pos = arg_start

                        while arg_pos <= len and paren_depth > 0 do
                            local ch = line:sub(arg_pos, arg_pos)
                            if ch == "(" then paren_depth = paren_depth + 1
                            elseif ch == ")" then
                                paren_depth = paren_depth - 1
                                if paren_depth == 0 then
                                    if arg_pos > arg_start then args[#args + 1] = line:sub(arg_start, arg_pos - 1) end
                                    break
                                end
                            elseif ch == "," and paren_depth == 1 then
                                args[#args + 1] = line:sub(arg_start, arg_pos - 1)
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
            table.insert(result, c)
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
            table.insert(output, string.format("--[[ #define %s%s %s ]]--",
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
file.Write("preprocessed_main.txt", processed)

CompileString(processed, "ImGui")()