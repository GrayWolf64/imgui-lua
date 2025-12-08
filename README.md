# ImGui Sincerely

## Primary Goal

Try to make an *Immediate Mode UI* library for Garry's Mod.

In other words, currently I'm implementing an ImGui clone in **pure Lua**.

Originally I just wanted to make some contributions to [RiceLib](https://github.com/RiceMCUT/Lib-Rice), and it wasn't the first time that I got terrified by the messy and bloat codebase of it. So I set out to remove all the non-UI related features added by *RiceLib* author [RiceMCUT](https://github.com/RiceMCUT) and to make UI creation for GMod in general easier.

Really want to say goodbye to the crazy indents when creating UI in *RiceLib*, and embrace *Immediate Mode UI*!

Don't confuse this with [imgui](https://github.com/wyozi-gmod/imgui), which is limited in terms of functionality. Keep in mind that if you have `imgui.lua` from that project placed in `lua` folder, it will potentially cause conflicts since we also use `imgui.lua` file name in `lua` currently.

Thanks to [Dear ImGui](https://github.com/ocornut/imgui)!
