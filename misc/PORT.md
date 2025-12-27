# Porting From C/C++ to (G)Lua 5.1 with JIT

```lua
--- This is no longer used
local CValue do
    local _CValue = {}
    _CValue.__index = _CValue

    function _CValue:deref() return self[1] end
    function _CValue:set_deref(val) self[1] = val end

    function CValue(val) return setmetatable({[1] = val}, _CValue) end
end
```
