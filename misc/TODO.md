# TODOs

1. `string.format()` %p get address
2. Remove the usage of `CArray` and `CValue` entirely. Use Lua native tables instead
3. All indices use 1 based!
4. All loop var start from 1 unless necessary
5. Project file structure. `include` & preprocessor usage.
    Use `getfenv` and `setfenv`?
6. *imgui_pp* pragma once, process_file with file.Write
7. Deal with GC? Optimize?
8. Exposed a lot of globals. Quite messy.
9. Don't have overloads for functions. So follow a convention like: if there's a function ImMax for numbers, then ImMaxV2 is for ImVec2s. When it takes in many params, better name it like ImLerpV2V2V2. This helps me avoid type checking in these helper functions and also keep the code clear.
