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

--- void ImDrawList::_SetDrawListSharedData(ImDrawListSharedData* data)
function _ImDrawList:_SetDrawListSharedData(data)
    if self._Data ~= nil then
        self._Data.DrawLists:find_erase_unsorted(self)
    end
    self._Data = data
    if self._Data ~= nil then
        self._Data.DrawLists:push_back(self)
    end
end

function _ImDrawList:AddDrawCmd(draw_call, ...)
    self.CmdBuffer:push_back({draw_call = draw_call, args = {...}})
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

function _ImDrawList:_CalcCircleAutoSegmentCount(radius)
    local radius_idx = ImFloor(radius + 0.999999)

    if radius_idx >= 0 and radius_idx < 64 then -- IM_ARRAYSIZE(_Data->CircleSegmentCounts))
        return self._Data.CircleSegmentCounts[radius_idx] -- Use cached value 
    else
        return IM_DRAWLIST_CIRCLE_AUTO_SEGMENT_CALC(radius, self._Data.CircleSegmentMaxError)
    end
end

function _ImDrawList:PushClipRect(cr_min, cr_max, intersect_with_current_clip_rect)
    local cr = ImVec4(cr_min.x, cr_min.y, cr_max.x, cr_max.y)

    if intersect_with_current_clip_rect then
        local current = self._CmdHeader.ClipRect

        if cr.x < current.x then cr.x = current.x end
        if cr.y < current.y then cr.y = current.y end
        if cr.z > current.z then cr.z = current.z end
        if cr.w > current.w then cr.w = current.w end
    end

    cr.z = ImMax(cr.x, cr.z)
    cr.w = ImMax(cr.y, cr.w)

    self._ClipRectStack:push_back(cr)
    self._CmdHeader.ClipRect = cr
    -- _OnChangedClipRect()
end

function _ImDrawList:PrimReserve(idx_count, vtx_count)
    -- IM_ASSERT_PARANOID(idx_count >= 0 && vtx_count >= 0)


end

--- void ImDrawList::_PathArcToFastEx
-- currently we use push_back instead of resizing and indexing
function _ImDrawList:_PathArcToFastEx(center, radius, a_min_sample, a_max_sample, a_step)
    if radius < 0.5 then
        self._Path:push_back(center)
        return
    end

    if a_step <= 0 then
        a_step = ImFloor(IM_DRAWLIST_ARCFAST_SAMPLE_MAX / self:_CalcCircleAutoSegmentCount(radius)) -- FIXME: I may forget to add ImFloor if result is int somewhere
    end

    a_step = ImClamp(a_step, 1, ImFloor(IM_DRAWLIST_ARCFAST_TABLE_SIZE / 4))

    local sample_range = ImAbs(a_max_sample - a_min_sample)
    local a_next_step = a_step

    local extra_max_sample = false

    if a_step > 1 then
        local overstep = sample_range % a_step

        if overstep > 0 then
            extra_max_sample = true

            if sample_range > 0 then
                a_step = a_step - ImFloor((a_step - overstep) / 2)
            end
        end
    end

    local sample_index = a_min_sample
    if sample_index < 0 or sample_index >= IM_DRAWLIST_ARCFAST_SAMPLE_MAX then
        sample_index = sample_index % IM_DRAWLIST_ARCFAST_SAMPLE_MAX
        if sample_index < 0 then
            sample_index = sample_index + IM_DRAWLIST_ARCFAST_SAMPLE_MAX
        end
    end

    if a_max_sample >= a_min_sample then
        local a = a_min_sample
        while a <= a_max_sample do
            if sample_index >= IM_DRAWLIST_ARCFAST_SAMPLE_MAX then
                sample_index = sample_index - IM_DRAWLIST_ARCFAST_SAMPLE_MAX
            end

            local s = self._Data.ArcFastVtx[sample_index]
            self._Path:push_back(ImVec2(center.x + s.x * radius, center.y + s.y * radius))

            a = a + a_step
            sample_index = sample_index + a_step
            a_step = a_next_step
        end
    else
        local a = a_min_sample
        while a >= a_max_sample do
            if sample_index < 0 then
                sample_index = sample_index + IM_DRAWLIST_ARCFAST_SAMPLE_MAX
            end

            local s = self._Data.ArcFastVtx[sample_index]
            self._Path:push_back(ImVec2(center.x + s.x * radius, center.y + s.y * radius))

            a = a - a_step
            sample_index = sample_index - a_step
            a_step = a_next_step
        end
    end

    if extra_max_sample then
        local normalized_max_sample = a_max_sample % IM_DRAWLIST_ARCFAST_SAMPLE_MAX
        if normalized_max_sample < 0 then
            normalized_max_sample = normalized_max_sample + IM_DRAWLIST_ARCFAST_SAMPLE_MAX
        end

        local s = self._Data.ArcFastVtx[normalized_max_sample]
        self._Path:push_back(ImVec2(center.x + s.x * radius, center.y + s.y * radius))
    end
end

function _ImDrawList:PathArcToFast(center, radius, a_min_of_12, a_max_of_12)
    if radius < 0.5 then
        self._Path:push_back(center)
        return
    end

    self:_PathArcToFastEx(center, radius, a_min_of_12 * IM_DRAWLIST_ARCFAST_SAMPLE_MAX / 12, a_max_of_12 * IM_DRAWLIST_ARCFAST_SAMPLE_MAX / 12, 0)
end

function _ImDrawList:_PathArcToN(center, radius, a_min, a_max, num_segments)
    if radius < 0.5 then
        self._Path:push_back(center)
        return
    end

    for i = 0, num_segments do
        local a = a_min + (i / num_segments) * (a_max - a_min)
        self._Path:push_back(ImVec2(center.x + ImCos(a) * radius, center.y + ImSin(a) * radius))
    end
end

function _ImDrawList:PathArcTo(center, radius, a_min, a_max, num_segments)
    if radius < 0.5 then
        self._Path:push_back(center)
        return
    end

    if num_segments > 0 then
        self:_PathArcToN(center, radius, a_min, a_max, num_segments)
        return
    end

    if radius <= self._Data.ArcFastRadiusCutoff then
        local a_is_reverse = a_max < a_min

        local a_min_sample_f = IM_DRAWLIST_ARCFAST_SAMPLE_MAX * a_min / (IM_PI * 2.0)
        local a_max_sample_f = IM_DRAWLIST_ARCFAST_SAMPLE_MAX * a_max / (IM_PI * 2.0)

        local a_min_sample = a_is_reverse and ImFloor(a_min_sample_f) or ImCeil(a_min_sample_f)
        local a_max_sample = a_is_reverse and ImCeil(a_max_sample_f) or ImFloor(a_max_sample_f)
        local a_mid_samples = a_is_reverse and ImMax(a_min_sample - a_max_sample, 0) or ImMax(a_max_sample - a_min_sample, 0)

        local a_min_segment_angle = a_min_sample * IM_PI * 2.0 / IM_DRAWLIST_ARCFAST_SAMPLE_MAX
        local a_max_segment_angle = a_max_sample * IM_PI * 2.0 / IM_DRAWLIST_ARCFAST_SAMPLE_MAX
        local a_emit_start = ImAbs(a_min_segment_angle - a_min) >= 1e-5
        local a_emit_end = ImAbs(a_max - a_max_segment_angle) >= 1e-5

        if a_emit_start then
            self._Path:push_back(ImVec2(center.x + ImCos(a_min) * radius, center.y + ImSin(a_min) * radius))
        end

        if a_mid_samples > 0 then
            self:_PathArcToFastEx(center, radius, a_min_sample, a_max_sample, 0)
        end

        if a_emit_end then
            self._Path:push_back(ImVec2(center.x + ImCos(a_max) * radius, center.y + ImSin(a_max) * radius))
        end
    else
        local arc_length = ImAbs(a_max - a_min)
        local circle_segment_count = self:_CalcCircleAutoSegmentCount(radius)
        local arc_segment_count = ImMax(
            ImCeil(circle_segment_count * arc_length / (IM_PI * 2.0)),
            2.0 * IM_PI / arc_length
        )

        self:_PathArcToN(center, radius, a_min, a_max, arc_segment_count)
    end
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