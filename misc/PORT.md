# Porting From C/C++ to (G)Lua 5.1 with JIT

Note that *this may be outdated*

## Notes

- It's very important to pay attention to `=` operators. Sometimes full copy is necessary instead of simply using `=` on tables(structures)

- (LuaJIT) `string.format()` %p get address?

- Use `getfenv` and `setfenv`?

- Avoid `continue` (Lua extension) or `goto label` + `:: label ::` (LuaJIT) for better compat between versions. Try to use branches in a particular style that makes it easier to maintain, and looks decent. **Don't ignore original `break` when trying to convert to `repeat ... until true` + `do break end` hack!**

Search for "LUA:" to see Lua specific changes!

This is overall a painful experience, but I learnt a lot.
