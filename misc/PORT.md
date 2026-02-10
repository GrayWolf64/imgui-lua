# Porting From C/C++ to (G)Lua 5.1 with JIT

Note that *this is quite old and outdated material*

## Notes

- It's very important to pay attention to `=` operators. Sometimes full copy is necessary in Lua instead of simply using `=` on tables(structures)

Search for "LUA:" to see Lua specific changes!

This is overall a painful experience, but I learnt a lot.
