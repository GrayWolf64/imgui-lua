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
            text   = "function ",
        }
    end

    local function escape_lua_string(s)
        return s:gsub('\\', '\\\\'):gsub('"', '\\"')
    end

    for line_start, line in text:gmatch("()([^\r\n]+)") do
        if line:match("^#IMGUI_DEFINE") then
            -- Try pattern with parameters: #IMGUI_DEFINE name(params) body
            local name, params, body = line:match("^#IMGUI_DEFINE%s+([^%s(]+)(%b())%s+(.+)$")

            local replacement
            if name then
                -- Has parameters: IMGUI_DEFINE("name(params)", "body")
                local first_arg = name .. params
                replacement = ('IMGUI_DEFINE("%s", "%s")'):format(
                    escape_lua_string(first_arg),
                    escape_lua_string(body)
                )
            else
                -- Without parameters: #IMGUI_DEFINE name body
                name, body = line:match("^#IMGUI_DEFINE%s+([^%s]+)%s+(.+)$")
                if name then
                    replacement = ('IMGUI_DEFINE("%s", "%s")'):format(
                        escape_lua_string(name),
                        escape_lua_string(body)
                    )
                end
            end

            if replacement then
                diffs[#diffs + 1] = {
                    start = line_start,
                    finish = line_start + #line - 1,
                    text = replacement
                }
            end
        end
    end

    if #diffs == 0 then return nil end
    return diffs
end