local M = {}

local defaults = {
  file = nil, -- file to open
  cmd = vim.o.shell, -- terminal command to run
  cwd = vim.fn.getcwd, -- cwd of the command
  id = function() return vim.v.count end, -- float identifier
  start_in_insert = true,
  focus = true,
  window = {
    row = nil, -- supports percentages (<=1) and absolute sizes (>1)
    col = nil, -- supports percentages (<=1) and absolute sizes (>1)
    width = 0.8, -- supports percentages (<=1) and absolute sizes (>1)
    height = 0.8, -- supports percentages (<=1) and absolute sizes (>1)
    h_align = "center", -- alignment helper if no col, "left", "center", "right"
    v_align = "center", -- alignment helper if no row, "top", "center", "bottom"
    border = "rounded",
    zindex = 50,
  },
  wo = {
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
  },
}

local function eval_opts(opts)
  if type(opts) == "function" then return opts() end
  if type(opts) == "table" then
    local res = {}
    for k, v in pairs(opts) do 
      res[k] = eval_opts(v)
    end
    return res
  end
  return opts
end

local function valid_buf(buf) return buf and vim.api.nvim_buf_is_valid(buf) end
local function valid_win(win) return win and vim.api.nvim_win_is_valid(win) end

local function get_win_opts(config)
  local opts = eval_opts(config.window)
  local width, height = opts.width, opts.height
  local row, col = opts.row, opts.col

  width = width <= 1 and math.floor(vim.o.columns * width) or width
  height = height <= 1 and math.floor(vim.o.lines * height) or height

  if row then
    row = (row > 0 and row <= 1) and math.floor(vim.o.lines * row) or row
  else
    if opts.v_align == "top" then
      row = 0
    elseif opts.v_align == "bottom" then
      row = vim.o.lines - height
    else -- default to "center"
      row = math.floor((vim.o.lines - height) / 2)
    end
  end

  if col then
    col = (col > 0 and col <= 1) and math.floor(vim.o.columns * col) or col
  else
    if opts.h_align == "left" then
      col = 0
    elseif opts.h_align == "right" then
      col = vim.o.columns - width
    else -- default to "center
      col = math.floor((vim.o.columns - width) / 2)
    end
  end

  opts.relative = "editor"
  opts.width = width
  opts.height = height
  opts.row = row
  opts.col = col

  opts.v_align = nil
  opts.h_align = nil

  return opts
end

local function create_buf(config)
  local buf = nil
  if config.file then
    buf = vim.fn.bufadd(eval_opts(config.file))
    vim.fn.bufload(buf)
  else
    buf = vim.api.nvim_create_buf(false, true)
  end
  return buf
end

local function create_win(config, buf) 
  local opts = get_win_opts(config)
  local win = vim.api.nvim_open_win(buf, true, opts)
  for opt, val in pairs(config.wo) do
    vim.api.nvim_win_set_option(win, opt, val)
  end
  return win
end

local function toggle(config, opts)
  opts = opts or {}
  local id = opts.id or eval_opts(config.id)
  if type(id) ~= "string" and type(id) ~= "number" then return end  
  
  -- 0 is a special id to toggle previous float
  if id == 0 then id = config.prev_id or 1 end
  local term = config.terms[id] or {}

  local buf_ready = valid_buf(term.buf)
  if not buf_ready then
    term.buf = create_buf(config)
  end

  if valid_win(term.win) then
    vim.api.nvim_win_close(term.win, true)
  else
    -- ensure unwanted float window is closed
    if id ~= config.prev_id then
      local prev_term = config.terms[config.prev_id] or {}
      if valid_win(prev_term.win) then
        vim.api.nvim_win_close(prev_term.win, true)
      end
    end
    -- create new window
    local prev_win = vim.api.nvim_get_current_win()
    term.win = create_win(config, term.buf)
    if not config.file then
      -- ensure terminal command is executed before first show
      if not buf_ready then
        vim.fn.termopen(eval_opts(config.cmd) or vim.o.shell, { cwd = eval_opts(config.cwd) })
      end
      if not eval_opts(config.focus) and valid_win(prev_win) then
        vim.api.nvim_set_current_win(prev_win)
      elseif eval_opts(config.start_in_insert) then
        vim.cmd.startinsert()
      end
    end
  end

  config.prev_id = id
  config.terms[id] = term
end

local function setup(config)
  config.toggle = function(opts) toggle(config, opts) end
  config.terms = {}
  config.prev_id = nil

  vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
      if not config.prev_id then return end
      local term = config.terms[config.prev_id]
      if valid_win(term.win) then
        vim.api.nvim_win_set_config(term.win, get_win_opts(config))
      end
    end,
  })

  return config
end

M.setup = function(opts)
  table.unpack = table.unpack or unpack
  config = vim.tbl_deep_extend("force", defaults, opts or {})
  return setup(config)
end

return M
