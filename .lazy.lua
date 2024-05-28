--[[
Enable project-specific plugin specs.

File .lazy.lua:
  is read when present in the current working directory
  should return a plugin spec
  has to be manually trusted for each instance of the file

This extra should be the last plugin spec added to lazy.nvim

```lua
return {
  -- lazyvim pre-defined extras
  -- { import = "lazyvim.plugins.extras.xxx" },
  -- user extras
  -- { import = "plugins.extras.xxx" },
}
```

See:
  :h 'exrc'
  :h :trust
--]]


return {
  --
  -- enable all extras for testing
  --

  -- fennel
  { import = "plugins.extras.lsp.fennel" },

  -- c/cpp
  { import = "plugins.extras.util.godbolt" }, -- online compiler

  -- python
  { import = "lazyvim.plugins.extras.lang.python" },
  { import = "lazyvim.plugins.extras.lang.python-semshi" },
  { import = "plugins.extras.lsp.python" },


}
