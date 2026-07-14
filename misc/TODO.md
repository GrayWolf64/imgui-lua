# TODOs

- Should make more tables 1-based unless necessary to be 0-based: MouseXXX `table<ImVec2>`
- All loop var start from 1 unless necessary
- Optimize: Deal with GC?
- Exposed a lot of globals. Quite messy.
- Enclose some flags into tables when they don't rely on each other, e.g. no bit.* ops
- GMod Backend: GMod render.MaxTextureWidth/Height()
- Widgets: Consolidate existing ones -> Multi-Select -> Tabs -> Tables
- API: Some render text related functions take in `text_begin`, which is usually 1. Consider removing this param?
- API: Swap the 2 returns of `CheckboxFlags`?
- API: `IsMouseClicked` and `IsMouseClickedEx` combine
