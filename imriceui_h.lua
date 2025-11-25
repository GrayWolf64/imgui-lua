local bit = bit

--- enum ImGuiWindowFlags_
local ImGuiWindowFlags_ = {
    None                      = 0,
    NoTitleBar                = bit.lshift(1, 0),
    NoResize                  = bit.lshift(1, 1),
    NoMove                    = bit.lshift(1, 2),
    NoScrollbar               = bit.lshift(1, 3),
    NoScrollWithMouse         = bit.lshift(1, 4),
    NoCollapse                = bit.lshift(1, 5),
    AlwaysAutoResize          = bit.lshift(1, 6),
    NoBackground              = bit.lshift(1, 7),
    NoSavedSettings           = bit.lshift(1, 8),
    NoMouseInputs             = bit.lshift(1, 9),
    MenuBar                   = bit.lshift(1, 10),
    HorizontalScrollbar       = bit.lshift(1, 11),
    NoFocusOnAppearing        = bit.lshift(1, 12),
    NoBringToFrontOnFocus     = bit.lshift(1, 13),
    AlwaysVerticalScrollbar   = bit.lshift(1, 14),
    AlwaysHorizontalScrollbar = bit.lshift(1, 15),
    NoNavInputs               = bit.lshift(1, 16),
    NoNavFocus                = bit.lshift(1, 17),
    UnsavedDocument           = bit.lshift(1, 18),

    ChildWindow = bit.lshift(1, 24),
    Tooltip     = bit.lshift(1, 25),
    Popup       = bit.lshift(1, 26),
    Modal       = bit.lshift(1, 27),
    ChildMenu   = bit.lshift(1, 28)
}

ImGuiWindowFlags_.NoNav = bit.bor(
    ImGuiWindowFlags_.NoNavInputs,
    ImGuiWindowFlags_.NoNavFocus
)
ImGuiWindowFlags_.NoDecoration = bit.bor(
    ImGuiWindowFlags_.NoTitleBar,
    ImGuiWindowFlags_.NoResize,
    ImGuiWindowFlags_.NoScrollbar,
    ImGuiWindowFlags_.NoCollapse
)
ImGuiWindowFlags_.NoInputs = bit.bor(
    ImGuiWindowFlags_.NoMouseInputs,
    ImGuiWindowFlags_.NoNavInputs,
    ImGuiWindowFlags_.NoNavFocus
)

--- enum ImGuiItemFlags_
local ImGuiItemFlags_ = {
    None              = 0,
    NoTabStop         = bit.lshift(1, 0),
    NoNav             = bit.lshift(1, 1),
    NoNavDefaultFocus = bit.lshift(1, 2),
    ButtonRepeat      = bit.lshift(1, 3),
    AutoClosePopups   = bit.lshift(1, 4),
    AllowDuplicateID  = bit.lshift(1, 5)
}