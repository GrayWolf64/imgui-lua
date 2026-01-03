--- This is a temporary load file script for testing ImGui
-- This also should be a preprocessor file that includes code into the imgui.lua file before it's executed
-- because GMod limits a file size compressed to 64kb, and the main file is growing so quickly
--

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

    if #line < 13 then return nil end
    if line:sub(pos, pos + 12) ~= "IMGUI_INCLUDE" then return nil end
    pos = pos + 13

    while pos <= #line and is_whitespace(line:sub(pos, pos)) do pos = pos + 1 end

    if pos > #line or line:sub(pos, pos) ~= "(" then return nil end
    pos = pos + 1

    while pos <= #line and is_whitespace(line:sub(pos, pos)) do pos = pos + 1 end
    if pos > #line or line:sub(pos, pos) ~= "\"" then return nil end
    pos = pos + 1

    local start = pos
    while pos <= #line and line:sub(pos, pos) ~= "\"" do pos = pos + 1 end
    if pos > #line then return nil end
    local path = line:sub(start, pos - 1)
    pos = pos + 1

    while pos <= #line and is_whitespace(line:sub(pos, pos)) do pos = pos + 1 end
    if pos > #line or line:sub(pos, pos) ~= ")" then return nil end

    return path
end

local function parse_define(line)
    local pos = 1

    if #line < 12 then return nil end
    if line:sub(pos, pos + 11) ~= "IMGUI_DEFINE" then return nil end
    pos = pos + 12

    while pos <= #line and is_whitespace(line:sub(pos, pos)) do pos = pos + 1 end
    if pos > #line or line:sub(pos, pos) ~= "(" then return nil end
    pos = pos + 1

    while pos <= #line and is_whitespace(line:sub(pos, pos)) do pos = pos + 1 end

    local name_start = pos
    while pos <= #line and is_alnum_or_underscore(line:sub(pos, pos)) do pos = pos + 1 end
    if pos == name_start then return nil end
    local name = line:sub(name_start, pos - 1)

    while pos <= #line and is_whitespace(line:sub(pos, pos)) do pos = pos + 1 end
    if pos > #line or line:sub(pos, pos) ~= "," then return nil end
    pos = pos + 1

    while pos <= #line and is_whitespace(line:sub(pos, pos)) do pos = pos + 1 end

    local value_start = pos
    local paren_depth = 0

    while pos <= #line do
        local c = line:sub(pos, pos)
        if c == "(" then
            paren_depth = paren_depth + 1
        elseif c == ")" then
            if paren_depth == 0 then break end
            paren_depth = paren_depth - 1
        end
        pos = pos + 1
    end

    if pos > #line then return nil end
    local value = line:sub(value_start, pos - 1)

    return name, value
end

local function expand_line(line, defines, seen)
    seen = seen or {}
    local result = {}
    local i = 1

    while i <= #line do
        local c = line:sub(i, i)

        if is_alpha(c) or c == "_" then
            local word_start = i
            while i <= #line and is_alnum_or_underscore(line:sub(i, i)) do i = i + 1 end
            local word = line:sub(word_start, i - 1)

            local macro = defines[word]
            if macro and not seen[word] then
                seen[word] = true
                local expanded = expand_line(macro, defines, seen)
                table.insert(result, expanded)
                seen[word] = false
            else
                table.insert(result, word)
            end
        else
            table.insert(result, c)
            i = i + 1
        end
    end

    return table.concat(result)
end

local function process_file(filepath, depth, defines, include_stack)
    if depth > 8 then error("Circular IMGUI_INCLUDE in " .. filepath) end

    for i = 1, #include_stack do
        if include_stack[i] == filepath then return "" end
    end

    local lines = read_lines(filepath)
    table.insert(include_stack, filepath)
    local output = {}

    for _, line in ipairs(lines) do
        local include_path = parse_include(line)
        local def_name, def_value = parse_define(line)

        if include_path then
            local included = process_file(include_path, depth + 1, defines, include_stack)
            if included ~= nil then table.insert(output, included) end
        elseif def_name then
            defines[def_name] = def_value
            table.insert(output, string.format("--[[ #define %s %s ]]--", def_name, def_value))
        else
            table.insert(output, expand_line(line, defines))
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