--- This is a temporary load file script for testing ImGui
-- This also should be a preprocessor file that includes code into the imgui.lua file before it's executed
-- because GMod limits a file size compressed to 64kb, and the main file is growing so quickly
--

local pattern_fileinclude = "IMGUI_INCLUDE%(%\"(.-)%\"%)"

local function func_to_replace_with_file(file_name) return "IMGUI_INCLUDE(\"" .. file_name .. "\")" end

function IMGUI_INCLUDE(_file_name) end

local file_includes = {}

local main_file = file.Read("imgui.lua", "LUA")
for file_name in string.gmatch(main_file, pattern_fileinclude) do
    main_file = string.Replace(main_file, func_to_replace_with_file(file_name), file.Read(file_name, "LUA"))
end

file.Write("preprocessed_main.txt", main_file)

--- GMod doesn't allow saving a lua file to LUA folder
--
CompileString(main_file, "ImGui")()