local opt = vim.opt

-- Search
opt.hlsearch = true
opt.ignorecase = true
opt.smartcase = true

-- Clipboard
opt.clipboard = "unnamedplus"

-- Swap / Undo
opt.swapfile = false
opt.undofile = true

-- Line Numbers
opt.number = true
opt.relativenumber = true

-- Scrolling
opt.scrolloff = 999

-- Tabs & Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.autoindent = true
opt.breakindent = true

-- Line Wrapping
opt.wrap = true
opt.linebreak = true

-- Cursor
opt.cursorline = true

-- Appearance
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
vim.diagnostic.config {
  float = { border = "rounded" },
}

-- Completion
opt.completeopt = "menuone,noselect"

-- Backspace
opt.backspace = "indent,eol,start"

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Diff
opt.diffopt = {
  "internal",
  "filler",
  "closeoff",
  "algorithm:histogram",
  "indent-heuristic",
  "inline:char",
  "linematch:60",
}

-- Consider - as part of keyword
opt.iskeyword:append("-")

-- Disable mouse
opt.mouse = ""

-- Session Management
opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- Update time
opt.updatetime = 250

-- Commands
vim.api.nvim_create_user_command('CdHere', function()
  vim.cmd('cd %:p:h')
  print('Changed directory to: ' .. vim.fn.getcwd())
end, {})

-- Set VIRTUAL_ENV + prepend its bin/ to PATH for nvim's env. This propagates
-- to `:terminal`, DAP launches, and any subprocess spawned by a plugin.
-- The previous version called `!source` in a transient subshell that exited
-- immediately, so it had no effect.
vim.api.nvim_create_user_command('ActivateEnv', function()
  local cwd = vim.fn.getcwd()
  local venv_dirs = { ".venv", "venv", "env" }
  local found_venv = nil

  for _, dir in ipairs(venv_dirs) do
    local venv_path = cwd .. "/" .. dir
    if vim.fn.isdirectory(venv_path) == 1 then
      found_venv = venv_path
      break
    end
  end

  if not found_venv then
    vim.notify("No virtual environment found in " .. cwd, vim.log.levels.WARN)
    return
  end

  vim.env.VIRTUAL_ENV = found_venv
  vim.env.PATH = found_venv .. "/bin:" .. vim.env.PATH
  vim.notify("Activated venv: " .. found_venv, vim.log.levels.INFO)
end, {})
