# TODOs

- `string.format()` %p get address
- Remove the usage of `CArray` and `CValue` entirely. Use Lua native tables instead
- All indices use 1 based!
- All loop var start from 1 unless necessary
- Project file structure. `include` usage. Use `getfenv` and `setfenv`?
- Optimize: Deal with GC?
- Exposed a lot of globals. Quite messy.
- Don't have overloads for functions. So follow a convention like: if there's a function ImMax for numbers, then ImMaxV2 is for ImVec2s. When it takes in many params, better name it like ImLerpV2V2V2. This helps me avoid type checking in these helper functions and also keep the code clear.
- Enclose some flags into tables when they don't rely on each other, e.g. no bit.* ops
- Actually rewrite the stb ports
- I hate cpp mess. Wtf imgui passes ImRect and ImVec4 window.ClipRect so randomly and everything works? I have to use `ImRectFromVec4` which looks ugly and feels bad.
- GMod Backend: GMod render.MaxTextureWidth/Height()
- Widgets: `ComboBox` -> `DragXXX` & `Slider` -> `ColorEdit` -> `TextInput` -> `CollapsingHeader`
