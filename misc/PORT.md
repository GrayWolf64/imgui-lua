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

--- imstb_truetype compliant table example
local function CArray(size, init)
    assert(type(size) == "number" and size > 0 and size % 1 == 0, "array size must be a positive integer!")

    local arr = {data = {}, offset = 0, size = size}

    if type(init) == "table" then
        assert(#init == size, "init size ~= buffer size!")
        local data = arr.data
        for i = 1, size do data[i] = init[i] end
    elseif type(init) == "function" then
        local data = arr.data
        for i = 1, size do data[i] = init() end
    end

    return arr
end
```
