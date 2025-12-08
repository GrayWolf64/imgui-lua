--- If lower, the window title cross or arrow will look awful
-- TODO: let client decide?
RunConsoleCommand("mat_antialias", "8")

local function ParseImGuiCol(str)
    local r, g, b, a = str:match("ImVec4%(([%d%.]+)f?, ([%d%.]+)f?, ([%d%.]+)f?, ([%d%.]+)f?%)")
    return {r = tonumber(r) * 255, g = tonumber(g) * 255, b = tonumber(b) * 255, a = tonumber(a) * 255}
end

--- ImGui::StyleColorsDark
local StyleColorsDark = {
    Text              = ParseImGuiCol("ImVec4(1.00f, 1.00f, 1.00f, 1.00f)"),
    WindowBg          = ParseImGuiCol("ImVec4(0.06f, 0.06f, 0.06f, 0.94f)"),
    Border            = ParseImGuiCol("ImVec4(0.43f, 0.43f, 0.50f, 0.50f)"),
    BorderShadow      = ParseImGuiCol("ImVec4(0.00f, 0.00f, 0.00f, 0.00f)"),
    TitleBg           = ParseImGuiCol("ImVec4(0.04f, 0.04f, 0.04f, 1.00f)"),
    TitleBgActive     = ParseImGuiCol("ImVec4(0.16f, 0.29f, 0.48f, 1.00f)"),
    TitleBgCollapsed  = ParseImGuiCol("ImVec4(0.00f, 0.00f, 0.00f, 0.51f)"),
    MenuBarBg         = ParseImGuiCol("ImVec4(0.14f, 0.14f, 0.14f, 1.00f)"),
    Button            = ParseImGuiCol("ImVec4(0.26f, 0.59f, 0.98f, 0.40f)"),
    ButtonHovered     = ParseImGuiCol("ImVec4(0.26f, 0.59f, 0.98f, 1.00f)"),
    ButtonActive      = ParseImGuiCol("ImVec4(0.06f, 0.53f, 0.98f, 1.00f)"),
    ResizeGrip        = ParseImGuiCol("ImVec4(0.26f, 0.59f, 0.98f, 0.20f)"),
    ResizeGripHovered = ParseImGuiCol("ImVec4(0.26f, 0.59f, 0.98f, 0.67f)"),
    ResizeGripActive  = ParseImGuiCol("ImVec4(0.26f, 0.59f, 0.98f, 0.95f)")
}

local ImNoColor = {r = 0, g = 0, b = 0, a = 0}

local IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MIN = 4
local IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_MAX = 512

function _ImDrawListSharedData:ImDrawListSharedData()
    for i = 0, IM_DRAWLIST_ARCFAST_TABLE_SIZE - 1 do
        local a = (i * 2 * IM_PI) / IM_DRAWLIST_ARCFAST_TABLE_SIZE
        self.ArcFastVtx[i] = ImVec2(ImCos(a), ImSin(a))
    end

    self.ArcFastRadiusCutoff = IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_R(IM_DRAWLIST_ARCFAST_SAMPLE_MAX, self.CircleSegmentMaxError)
end

function _ImDrawListSharedData:SetCircleTessellationMaxError(max_error)
    if self.CircleSegmentMaxError == max_error then return end
    -- IM_ASSERT(max_error > 0)

    self.CircleSegmentMaxError = max_error
    for i = 0, 64 - 1 do
        local radius = i
        self.CircleSegmentCounts[i] = i > 0 and IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC(radius, self.CircleSegmentMaxError) or IM_DRAWLIST_ARCFAST_SAMPLE_MAX
    end

    self.ArcFastRadiusCutoff = IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC_R(IM_DRAWLIST_ARCFAST_SAMPLE_MAX, self.CircleSegmentMaxError)
end

function _ImDrawList:AddDrawCmd(draw_call, ...)
    self.CmdBuffer[#self.CmdBuffer + 1] = {draw_call = draw_call, args = {...}}
end

function _ImDrawList:AddRectFilled(color, p_min, p_max)
    self:AddDrawCmd(surface.SetDrawColor, color)
    self:AddDrawCmd(surface.DrawRect, p_min.x, p_min.y, p_max.x - p_min.x, p_max.y - p_min.y)
end

function _ImDrawList:AddRectOutline(color, p_min, p_max, thickness)
    self:AddDrawCmd(surface.SetDrawColor, color)
    self:AddDrawCmd(surface.DrawOutlinedRect, p_min.x, p_min.y, p_max.x - p_min.x, p_max.y - p_min.y, thickness)
end

function _ImDrawList:AddText(text, font, pos, color)
    self:AddDrawCmd(surface.SetTextPos, pos.x, pos.y)
    self:AddDrawCmd(surface.SetFont, font)
    self:AddDrawCmd(surface.SetTextColor, color)
    self:AddDrawCmd(surface.DrawText, text)
end

function _ImDrawList:AddLine(p1, p2, color)
    self:AddDrawCmd(surface.SetDrawColor, color)
    self:AddDrawCmd(surface.DrawLine, p1.x, p1.y, p2.x, p2.y)
end

--- Points must be in clockwise order
function _ImDrawList:AddTriangleFilled(indices, color)
    self:AddDrawCmd(surface.SetDrawColor, color)
    self:AddDrawCmd(draw.NoTexture)
    self:AddDrawCmd(surface.DrawPoly, indices)
end

function _ImDrawList:RenderTextClipped(text, font, pos, color, w, h)
    surface.SetFont(font)
    local text_width, text_height = surface.GetTextSize(text)
    local need_clipping = text_width > w or text_height > h

    if need_clipping then
        self:AddDrawCmd(render.SetScissorRect, pos.x, pos.y, pos.x + w, pos.y + h, true)
    end

    self:AddText(text, font, pos, color)

    if need_clipping then
        self:AddDrawCmd(render.SetScissorRect, 0, 0, 0, 0, false)
    end
end

local function PushClipRect(draw_list, cr_min, cr_max, intersect_with_current_clip_rect)
    local cr = ImVec4(cr_min.x, cr_min.y, cr_max.x, cr_max.y)

    if intersect_with_current_clip_rect then
        local current = draw_list._CmdHeader.ClipRect

        if cr.x < current.x then cr.x = current.x end
        if cr.y < current.y then cr.y = current.y end
        if cr.z > current.z then cr.z = current.z end
        if cr.w > current.w then cr.w = current.w end
    end

    cr.z = math.max(cr.x, cr.z) -- TODO: ImMax
    cr.w = math.max(cr.y, cr.w)

    insert_at(draw_list._ClipRectStack, cr)
    draw_list._CmdHeader.ClipRect = cr
    -- _OnChangedClipRect()
end

--- ImGui::RenderArrow
local function RenderArrow(draw_list, pos, color, dir, scale)
    local h = GImGui.FontSize -- TODO: draw_list->_Data->FontSize * 1.00f?
    local r = h * 0.40 * scale

    center = pos + ImVec2(h * 0.50, h * 0.50 * scale)

    local a, b, c

    if dir == ImDir_Up or dir == ImDir_Down then
        if dir == ImDir_Up then r = -r end
        a = ImVec2( 0.000,  0.750) * r
        b = ImVec2(-0.866, -0.750) * r
        c = ImVec2( 0.866, -0.750) * r
    elseif dir == ImDir_Left or dir == ImDir_Right then
        if dir == ImDir_Left then r = -r end
        a = ImVec2( 0.750,  0.000) * r
        b = ImVec2(-0.750,  0.866) * r
        c = ImVec2(-0.750, -0.866) * r
    end

    draw_list:AddTriangleFilled({center + a, center + b, center + c}, color)
end