--- A crappy Bad Apple player using windows
-- https://github.com/mon/bad_apple_virus

local raw_frames, size = ImFileLoadToMemory("data/boxes_badapple.dat", "rb") --- @cast raw_frames ImSlice

local curr_frame = 0

local frames = {}
local current = {}

-- This is probably unnecessary, can just read on the fly
while raw_frames.offset < size do
    local x = IM_SLICE_GET(raw_frames, 0)
    local y = IM_SLICE_GET(raw_frames, 1)
    local w = IM_SLICE_GET(raw_frames, 2)
    local h = IM_SLICE_GET(raw_frames, 3)
    IM_SLICE_INC(raw_frames, 4)

    if w == 0 then
        table.insert(frames, current)
        current = {}
    else
        table.insert(current, {x = x, y = y, w = w, h = h})
    end
end

print(string.format("Loaded %d frames", #frames))

-- CreateContext
-- Init
-- YOUR RENDER LOOP START
-- NewFrame

local ratio_x = w / 64
local ratio_y = h / 48

if curr_frame > 0 and curr_frame <= #frames then
    local boxes = frames[curr_frame]

    for idx, box in ipairs(boxes) do
        local px = box.x * ratio_x
        local py = box.y * ratio_y
        local pw = box.w * ratio_x + 15
        local ph = box.h * ratio_y + 8

        ImGui.SetNextWindowPos(ImVec2(px, py), ImGuiCond_Always)
        ImGui.SetNextWindowSize(ImVec2(pw, ph), ImGuiCond_Always)

        ImGui.Begin("BA@" .. idx, nil)
        ImGui.End()
    end

    frame_accum = frame_accum + g.IO.DeltaTime
    if frame_accum >= 1 / 30 then
        curr_frame = curr_frame + 1
        frame_accum = 0
        if curr_frame > #frames then curr_frame = 0 end
    end
else
    ImGui.SetNextWindowPos(ImVec2(w / 2 - 100, h / 2 - 50), ImGuiCond_Always)
    ImGui.SetNextWindowSize(ImVec2(100, 100), ImGuiCond_Always)
    if ImGui.Begin("Controls") then
        ImGui.Text("Frames: %d", #frames)
        if ImGui.Button("Play!") then
            curr_frame = 1
            frame_accum = 0
        end
    end
    ImGui.End()
    if curr_frame == 1 then
        -- Start playing the background music here
    end
end

-- EndFrame
-- Renders
-- YOUR RENDER LOOP END