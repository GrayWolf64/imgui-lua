# Widget Comparison

| Widget Kinds | GMod Derma (VGUI) | ImGui Sincerely (This Port) | Additional Info |
| - | - | - | - |
| Button | DButton, DImageButton | Button, SmallButton, `ImageButton` | `ImageButton` requires user registered texture/RT |
| Checkbox | DCheckBox, DCheckBoxLabel | Checkbox | - |
| Text Input | `DTextEntry`, `DNumberWang` | InputText, InputFloat/Int | `DNumberWang` has poor support for numeric data types |
| Slider/Drag | DNumSlider | SliderFloat/Int, DragFloat/Int, VSliders | - |
| Label | RichText, `DLabel` | Text, LabelText, TextColored, TextDisabled | `DLabel` has limited APIs for controlling text wrapping |
| Window | `DFrame` | Begin + End, BeginChild + EndChild(child windows) | - |
| Menu | DMenuBar, DMenu, DMenuItem | `BeginMenuBar` + `EndMenuBar`, `BeginMenu` + `EndMenu`, MenuItem | - |
| Tree | `DTree` | `TreeNode` + `TreePop` | `DTree` has limited APIs. And you'll need to touch `DTree`, `DTree_Node`, `DTree_Node_Button` internals if wanting to do something complex. Warning! Derma uses inheritance heavily since it's OO and retained |
| Scroll | `DHorizontalScroller`, `DScrollPanel`(they internally uses `DHScrollBar` or `DVScrollBar`) | Configurable, automatic scroll bars and `ImGuiListClipper` | - |
| Image | `DImage` | `Image` | Requires user registered texture/RT |
| Color | `DColorMixer`, DColorButton | ColorButton, ColorEdit3/4, `ColorPicker4`(selectable color cube / hue wheel + sv triangle) | `DColorMixer` only supports color cube(`DColorCube`), has limited options, and does not have popups |
| Progress | DProgressBar | ProgressBar | - |
| Tooltip | DTooltip | BeginTooltip + EndTooltip | - |
| Tabs | `DPropertySheet` | **NYI** | - |
| Collapsible | DCategoryList, DCollapsibleCategory | CollapsingHeader | - |
| Layout | DForm, DGrid, DIconLayout | SameLine, Spacing, BeginGroup, ... | - |
| Plot | - | `PlotLines`, `PlotHistogram` | - |
| Selectable | `DComboBox` | BeginCombo + EndCombo, Selectable(primitive widget), RadioButton | - |
| Drag & Drop | `dragndrop` lib | **NYI** | - |
| Table | `DListView` | **NYI** | `DListView` APIs are very limited compared to ImGui Tables API |
| Bullet | - | Bullet, BulletText | - |
| 3D Model Display | `DModelPanel` | **NYI** | Possible with `Image()` + user registered texture/RT that renders the scene |
| HTML | `DHTML` | **NYI** | Possible with `Image()` + user registered texture/RT that renders the page |
| File Browser | `DFileBrowser` | **NYI** | Possible with existing APIs + platform specific APIs |

_The table above may provide limited information!_
