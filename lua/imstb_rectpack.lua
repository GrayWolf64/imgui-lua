--- @module "imstb_rectpack"
local bit = bit

local STBRP__MAXVAL = 0x7fffffff

local stbrp_pack_rects
local stbrp_init_target
local stbrp_setup_allow_out_of_mem
local stbrp_setup_heuristic

--- @enum STBRP_HEURISTIC_Skyline
local STBRP_HEURISTIC_Skyline = {
    default = 0,
    BL_sortHeight = 0,
    BF_sortHeight = 1
}

local STBRP__INIT_skyline = 1

--- @alias stbrp_coord integer

--- @class stbrp_rect
--- @field id         integer
--- @field w          stbrp_coord
--- @field h          stbrp_coord
--- @field x          stbrp_coord
--- @field y          stbrp_coord
--- @field was_packed int

--- @return stbrp_rect
--- @nodiscard
local function stbrp_rect()
    return {
        id         = 0,
        w          = 0,
        h          = 0,
        x          = 0,
        y          = 0,
        was_packed = 0
    }
end

--- @class stbrp_node
--- @field x    stbrp_coord
--- @field y    stbrp_coord
--- @field next stbrp_node

--- @return stbrp_node
--- @nodiscard
local function stbrp_node()
    return {
        x    = 0,
        y    = 0,
        next = nil
    }
end

--- @class stbrp_context
--- @field width       integer
--- @field height      integer
--- @field align       integer
--- @field init_mode   integer
--- @field heuristic   integer
--- @field num_nodes   integer
--- @field active_head stbrp_node
--- @field free_head   stbrp_node
--- @field extra       stbrp_node[]

--- @return stbrp_context
--- @nodiscard
local function stbrp_context()
    return {
        width     = 0,
        height    = 0,
        align     = 0,
        init_mode = 0,
        heuristic = 0,
        num_nodes = 0,

        active_head = nil,
        free_head   = nil,
        extra       = {stbrp_node(), stbrp_node()}
    }
end

-- GLUA: Simulate stbrp_node **prev_link usage
--- @class stbrp__doubleptr
--- @field obj table
--- @field key string

--- @return stbrp__doubleptr
--- @nodiscard
--- @package
local function stbrp__doubleptr(_obj, _key)
    return {
        obj = _obj,
        key = _key,
    }
end

--- @class stbrp__findresult
--- @field x          integer
--- @field y          integer
--- @field prev_link? stbrp__doubleptr

--- @return stbrp__findresult
local function stbrp__findresult()
    return {
        x         = 0,
        y         = 0,
        prev_link = nil
    }
end

local STBRP_SORT = table.sort
local STBRP_ASSERT = assert
local STBRP__NOTUSED = function(_) end

--------------------------
--- IMPLEMENTATION SECTION
--

--- @param context stbrp_context
--- @param heuristic integer
function stbrp_setup_heuristic(context, heuristic)
    if context.init_mode == STBRP__INIT_skyline then
        STBRP_ASSERT(heuristic == STBRP_HEURISTIC_Skyline.BL_sortHeight or heuristic == STBRP_HEURISTIC_Skyline.BF_sortHeight)
        context.heuristic = heuristic
    else
        STBRP_ASSERT(false)
    end
end

--- @param context stbrp_context
--- @param allow_out_of_mem boolean
function stbrp_setup_allow_out_of_mem(context, allow_out_of_mem)
    if allow_out_of_mem then
        context.align = 1
    else
        context.align = (context.width + context.num_nodes - 1) / context.num_nodes
    end
end

--- @param context stbrp_context
--- @param width integer
--- @param height integer
--- @param nodes stbrp_node[]
--- @param num_nodes integer
function stbrp_init_target(context, width, height, nodes, num_nodes)
    nodes[1] = stbrp_node()
    for i = 1, num_nodes - 1 do
        nodes[i + 1] = stbrp_node()
        nodes[i].next = nodes[i + 1]
    end
    nodes[num_nodes].next = nil
    context.init_mode = STBRP__INIT_skyline
    context.heuristic = STBRP_HEURISTIC_Skyline.default
    context.free_head = nodes[1]
    context.active_head = context.extra[1]
    context.width = width
    context.height = height
    context.num_nodes = num_nodes
    stbrp_setup_allow_out_of_mem(context, false)

    context.extra[1].x = 0
    context.extra[1].y = 0
    context.extra[1].next = context.extra[2]
    context.extra[2].x = width
    context.extra[2].y = bit.lshift(1, 30)
    context.extra[2].next = nil
end

--- @param c stbrp_context
--- @param first stbrp_node
--- @param x0 integer
--- @param width integer
--- @return integer, integer
local function stbrp__skyline_find_min_y(c, first, x0, width)
    local node = first
    local x1 = x0 + width

    STBRP__NOTUSED(c)

    STBRP_ASSERT(first.x <= x0)

    STBRP_ASSERT(node.next.x > x0)

    STBRP_ASSERT(node.x <= x0)

    local min_y = 0
    local waste_area = 0
    local visited_width = 0
    while node.x < x1 do
        if node.y > min_y then
            waste_area = waste_area + visited_width * (node.y - min_y)
            min_y = node.y
            if node.x < x0 then
                visited_width = visited_width + node.next.x - x0
            else
                visited_width = visited_width + node.next.x - node.x
            end
        else
            local under_width = node.next.x - node.x
            if under_width + visited_width > width then
                under_width = width - visited_width
            end
            waste_area = waste_area + under_width * (min_y - node.y)
            visited_width = visited_width + under_width
        end
        node = node.next
    end

    return min_y, waste_area
end

--- @param c stbrp_context
--- @param width integer
--- @param height integer
--- @return stbrp__findresult
local function stbrp__skyline_find_best_pos(c, width, height)
    local best_waste = bit.lshift(1, 30)
    local best_x = 0
    local best_y = bit.lshift(1, 30)
    local fr = stbrp__findresult()
    local best_prev_link = nil

    width = width + c.align - 1
    width = width - width % c.align
    STBRP_ASSERT(width % c.align == 0)

    if width > c.width or height > c.height then
        fr.prev_link = nil
        fr.x = 0
        fr.y = 0
        return fr
    end

    local prev_link = stbrp__doubleptr(c, "active_head")
    local node = c.active_head

    while (node.x + width <= c.width) do
        local y, waste = stbrp__skyline_find_min_y(c, node, node.x, width)

        if c.heuristic == STBRP_HEURISTIC_Skyline.BL_sortHeight then
            if y < best_y then
                best_y = y
                best_prev_link = prev_link
                best_x = node.x
            end
        else
            if y + height <= c.height then
                if y < best_y or (y == best_y and waste < best_waste) then
                    best_y = y
                    best_waste = waste
                    best_prev_link = prev_link
                    best_x = node.x
                end
            end
        end

        prev_link = stbrp__doubleptr(node, "next")
        node = node.next
    end

    if c.heuristic == STBRP_HEURISTIC_Skyline.BF_sortHeight then
        local tail = c.active_head
        local node_scan = c.active_head
        local prev_link_scan = stbrp__doubleptr(c, "active_head")

        while tail and tail.x < width do
            tail = tail.next
        end

        while tail do
            local xpos = tail.x - width
            STBRP_ASSERT(xpos >= 0)

            while node_scan.next and node_scan.next.x <= xpos do
                prev_link_scan = stbrp__doubleptr(node_scan, "next")
                node_scan = node_scan.next
            end

            if node_scan then
                STBRP_ASSERT(node_scan.next.x > xpos and node_scan.x <= xpos)

                local y, waste = stbrp__skyline_find_min_y(c, node_scan, xpos, width)

                if y + height <= c.height then
                    if y <= best_y then
                        if y < best_y or waste < best_waste or (waste == best_waste and xpos < best_x) then
                            best_x = xpos
                            best_y = y
                            best_waste = waste
                            best_prev_link = prev_link_scan
                        end
                    end
                end
            end

            tail = tail.next
        end
    end

    fr.prev_link = best_prev_link
    fr.x = best_x
    fr.y = best_y
    return fr
end

--- @param context stbrp_context
--- @param width integer
--- @param height integer
--- @return stbrp__findresult
local function stbrp__skyline_pack_rectangle(context, width, height)
    local res = stbrp__skyline_find_best_pos(context, width, height)

    if res.prev_link == nil or res.y + height > context.height or context.free_head == nil then
        res.prev_link = nil
        return res
    end

    local node = context.free_head
    node.x = res.x
    node.y = res.y + height
    context.free_head = node.next

    local cur = res.prev_link.obj[res.prev_link.key]

    if cur.x < res.x then
        local next = cur.next
        cur.next = node
        cur = next
    else
        res.prev_link.obj[res.prev_link.key] = node
    end

    while cur.next and cur.next.x <= res.x + width do
        local next = cur.next
        cur.next = context.free_head
        context.free_head = cur
        cur = next
    end

    node.next = cur

    if cur.x < res.x + width then
        cur.x = res.x + width
    end

    return res
end

--- @param a stbrp_rect
--- @param b stbrp_rect
--- @return boolean
--- @package
local function rect_height_compare(a, b)
    if a.h > b.h then
        return true
    elseif a.h < b.h then
        return false
    else
        return a.w > b.w
    end
end

--- @param a stbrp_rect
--- @param b stbrp_rect
--- @return boolean
--- @package
local function rect_original_order(a, b)
    return a.was_packed < b.was_packed
end

--- @param context stbrp_context
--- @param rects stbrp_rect[]
--- @param num_rects integer
--- @return int
function stbrp_pack_rects(context, rects, num_rects)
    local all_rects_packed = 1

    for i = 1, num_rects do
        rects[i].was_packed = (i - 1)
    end

    STBRP_SORT(rects, rect_height_compare)

    for i = 1, num_rects do
        if rects[i].w == 0 or rects[i].h == 0 then
            rects[i].x = 0
            rects[i].y = 0
        else
            local fr = stbrp__skyline_pack_rectangle(context, rects[i].w, rects[i].h)
            if fr.prev_link then
                rects[i].x = fr.x
                rects[i].y = fr.y
            else
                rects[i].x = STBRP__MAXVAL
                rects[i].y = STBRP__MAXVAL
            end
        end
    end

    STBRP_SORT(rects, rect_original_order)

    for i = 1, num_rects do
        rects[i].was_packed = (rects[i].x == STBRP__MAXVAL and rects[i].y == STBRP__MAXVAL) and 0 or 1
        if rects[i].was_packed == 0 then
            all_rects_packed = 0
        end
    end

    return all_rects_packed
end

return {
    context = stbrp_context,
    rect    = stbrp_rect,
    node    = stbrp_node,

    pack_rects             = stbrp_pack_rects,
    init_target            = stbrp_init_target,
    setup_allow_out_of_mem = stbrp_setup_allow_out_of_mem,
    setup_heuristic        = stbrp_setup_heuristic
}