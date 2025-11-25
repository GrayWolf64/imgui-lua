local remove_at    = table.remove
local setmetatable = setmetatable
local next         = next

--- A compact ImVector clone, maybe
-- ImVector<>
local ImVector = {}
ImVector.__index = ImVector

function ImVector:push_back(value)
    self._top = self._top + 1
    self._items[self._top] = value
end

function ImVector:pop_back()
    if self._top == 0 then return nil end
    local value = self._items[self._top]
    self._items[self._top] = nil
    self._top = self._top - 1
    return value
end

function ImVector:clear()
    for i = 1, self._top do
        self._items[i] = nil
    end
    self._top = 0
end

function ImVector:size() return self._top end
function ImVector:empty() return self._top == 0 end

function ImVector:peek()
    if self._top == 0 then return nil end
    return self._items[self._top]
end

function ImVector:erase(i)
    if i < 1 or i > self._top then return nil end
    local removed = remove_at(self._items, i)
    self._top = self._top - 1
    return removed
end

function ImVector:at(i)
    if i < 1 or i > self._top then return nil end
    return self._items[i]
end

function ImVector:iter()
    local i = 0
    local n = self._top
    return function()
        i = i + 1
        if i <= n then
            return i, self._items[i]
        end
    end
end

function ImVector.new() return setmetatable({_items = {}, _top = 0}, ImVector) end

return ImVector.new