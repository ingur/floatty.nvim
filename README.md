<p align="center">
  <img src="https://github.com/user-attachments/assets/b2d46f4a-bd8e-4f11-ae19-a99981f1a816"/>
  <h1 align="center">floatty.nvim</h1>
</p>

<p align="center">
  A tiny plugin for toggling floating terminals and windows, inspired by <a href="https://github.com/akinsho/toggleterm.nvim">toggleterm.nvim</a>.
</p>

## Features
- Easily toggle floating terminals and custom windows using `.toggle(opts)`.
- Customize window size, position, and appearance.
- Support for different terminal commands, working directories, and window options.
- Dynamic alignment helpers (`h_align`, `v_align`).

## Installation

Install with your favorite package manager. For example, in lazy.nvim:
```lua
{ "ingur/floatty.nvim" }
```

## Example config
```lua

-- initialize config
local term = require("floatty").setup({})

-- set toggle keybinds (supports v:count by default!)
vim.keymap.set('n', '<C-t>', function() term.toggle() end)
vim.keymap.set('t', '<C-t>', function() term.toggle() end)
```

## Defaults
```lua
-- NOTE: all options can be functions to be evaluated
local defaults = {
  file = nil,                -- File to open (if any)
  cmd = vim.o.shell,         -- Terminal command to run
  cwd = vim.fn.getcwd,       -- Working directory of the command
  id = function() return vim.v.count end, -- Identifier for the float
  start_in_insert = true,    -- Start in insert mode
  focus = true,              -- Focus the window after opening
  window = {
    h_align = "center",      -- "left", "center", "right"
    v_align = "center",      -- "top", "center", "bottom"
    row = nil,               -- Supports percentages (<=1) and absolute sizes (>1)
    col = nil,               -- Supports percentages (<=1) and absolute sizes (>1)
    width = 0.8,             -- Supports percentages (<=1) and absolute sizes (>1)
    height = 0.8,            -- Supports percentages (<=1) and absolute sizes (>1)
    border = "rounded",      -- Border style
    zindex = 50,             -- Z-index of the float
    title = "",              -- window title
    title_pos = "center",    -- "left", "center", "right"
    -- see :h nvim_open_win() for more config options
  },
  wo = {                     -- Window-local options
    cursorcolumn = false,
    cursorline = false,
    cursorlineopt = "both",
    fillchars = "eob: ,lastline:…",
    list = false,
    listchars = "extends:…,tab:  ",
    number = false,
    relativenumber = false,
    signcolumn = "no",
    spell = false,
    winbar = "",
    statuscolumn = "",
    wrap = false,
    sidescrolloff = 0,
    -- other window options are also supported
  },
}
```

## More config examples

### Bottom-aligned Terminal
```lua
local term = require("floatty").setup({
  window = {
    row = function() return vim.o.lines - 11 end,
    width = 1.0,
    height = 8,
  },
})

vim.keymap.set('n', '<C-t>', function() term.toggle() end)
vim.keymap.set('t', '<C-t>', function() term.toggle() end)
```

### Lazygit float
```lua
local lazygit = require("floatty").setup({
  cmd = "lazygit",
  id = vim.fn.getcwd, -- Use the current working directory as the float's ID
})

vim.keymap.set('n', '<C-g>', function() lazygit.toggle() end)
vim.keymap.set('t', '<C-g>', function() lazygit.toggle() end)
```

### Toggling Between Horizontal and Vertical Layouts
```lua
local term = require("floatty").setup()
local layout = "horizontal"

term.toggle_layout = function()
  layout = layout == "horizontal" and "vertical" or "horizontal"
  if layout == "horizontal" then
    term.window = {
      row = function() return vim.o.lines - 11 end,
      width = 1.0,
      height = 8,
      h_align = "center",
    }
  else
    term.window = {
      row = nil,
      height = function() return vim.o.lines - 3 end,
      width = 0.25,
      h_align = "right",
      v_align = "top",
    }
  end
end

vim.keymap.set('n', '<leader>tt', term.toggle_layout)
```
