function OnSetText(uri, text)
    if not uri:match("%.lua$") then
        return nil
    end

    local diffs = {}

    for kwPos, class, colon, meth, sigStart in text:gmatch("()struct_method%s+([%w_]+)(:)([%w_]+)()") do
        local kwEnd = kwPos + #"struct_method" - 1

        diffs[#diffs + 1] = {
            start  = kwPos,
            finish = kwEnd,
            text   = "",
        }

        diffs[#diffs + 1] = {
            start  = kwEnd + 1,
            finish = kwEnd,
            text   = "function GMetaTables.",
        }
    end

    if #diffs == 0 then return nil end
    return diffs
end