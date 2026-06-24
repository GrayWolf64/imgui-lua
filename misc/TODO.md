# TODOs

- Should make more tables 1-based unless necessary to be 0-based: MouseXXX `table<ImVec2>`
- All loop var start from 1 unless necessary
- Optimize: Deal with GC?
- Exposed a lot of globals. Quite messy.
- Don't have overloads for functions. So follow a convention like: if there's a function ImMax for numbers, then ImMaxV2 is for ImVec2s. When it takes in many params, better name it like ImLerpV2V2V2. This helps me avoid type checking in these helper functions and also keep the code clear.
- Enclose some flags into tables when they don't rely on each other, e.g. no bit.* ops
- Actually rewrite the stb ports
- GMod Backend: GMod render.MaxTextureWidth/Height()
- Widgets: `DragXXX` & `Slider` -> `ColorEdit` -> `TextInput` -> `CollapsingHeader`
- API: Some render text related functions take in `text_begin`, which is usually 1. Consider removing this param?
- API: Swap the 2 returns of `CheckboxFlags`?
- API: `IsMouseClicked` and `IsMouseClickedEx` combine
