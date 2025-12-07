--- This is a temporary load file script for testing ImRiceUI
-- This also should be a preprocessor file that includes code into the imriceui.lua file before it's executed
-- because GMod limits a file size compressed to 64kb, and the main file is growing so quickly
--

local pattern_funcdef = "IMGUI_FUNC_DEF_START%(%\"(.-)%\"%)(.-)IMGUI_FUNC_DEF_END%(%)"
local pattern_funcinclude = "IMGUI_INCLUDE_FUNC%(%\"(.-)%\", %\"(.-)%\"%)"

local function func_to_replace(func_name, file_name) return "IMGUI_INCLUDE_FUNC(\"" .. func_name .. "\", \"" .. file_name .. "\")" end

--- use `if IMGUI_INCLUDE_START() then return end` to mark the include section has started.
-- The rest of the file will be ignored by GMod `include()`
function IMGUI_INCLUDE_START() return true end

function IMGUI_FUNC_DEF_START(_func_name) end
function IMGUI_FUNC_DEF_END() end

function IMGUI_INCLUDE_FUNC(_func_name, _file_name) end

local func_includes = {}

local include_source = {
    "imriceui_widgets.lua"
}

for _, file_name in ipairs(include_source) do
    local contents = file.Read(file_name, "LUA")

    for func_name, func_body in string.gmatch(contents, pattern_funcdef) do
        func_includes[func_name] = func_body
    end
end

local main_file = file.Read("imriceui.lua", "LUA")
for func_name, file_name in string.gmatch(main_file, pattern_funcinclude) do
    main_file = string.Replace(main_file, func_to_replace(func_name, file_name), func_includes[func_name])
end

for k in pairs(func_includes) do
    func_includes[k] = nil
end

--- GMod doesn't allow saving a lua file to LUA folder
--
CompileString(main_file, "ImRiceUI")()