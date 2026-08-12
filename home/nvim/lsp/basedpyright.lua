---@brief
---
--- https://detachhead.github.io/basedpyright
---
--- `basedpyright`, a static type checker and language server for python

-- Function to set Python path for basedpyright
local function set_python_path(path)
  local clients = vim.lsp.get_clients {
    bufnr = vim.api.nvim_get_current_buf(),
    name = 'basedpyright',
  }
  for _, client in ipairs(clients) do
    if client.settings then
      client.settings.python = vim.tbl_deep_extend('force', client.settings.python or {}, { pythonPath = path })
    else
      client.config.settings = vim.tbl_deep_extend('force', client.config.settings, { python = { pythonPath = path } })
    end
    client.notify('workspace/didChangeConfiguration', { settings = nil })
  end
end

-- Function to find Python path in virtual environment
local function find_venv_python()
  -- Get current directory
  local cwd = vim.fn.getcwd()
  
  -- Common virtual environment directories to check
  local venv_paths = {
    cwd .. "/.venv/bin/python",
    cwd .. "/venv/bin/python",
    cwd .. "/.env/bin/python",
    cwd .. "/env/bin/python",
    -- Add more patterns if needed
  }
  
  -- Check if any of the paths exist
  for _, path in ipairs(venv_paths) do
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end
  
  -- Fall back to system Python
  return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
end

return {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python", "ipynb" },
  root_markers = {
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    "pyrightconfig.json",
    ".git",
  },
  settings = {
    basedpyright = {
      -- Type checking is delegated to mypy via nvim-lint (matches me3cs CI).
      -- basedpyright is kept for navigation, hover, and completion only.
      disableOrganizeImports = false,
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        typeCheckingMode = "off",
        diagnosticMode = "openFilesOnly",
      },
    },
    -- This will be overwritten by the venv detection
    python = {
      -- Empty by default, will be set by on_attach
    },
  },
  on_attach = function(client, bufnr)
    -- Try to find and set venv Python path
    local python_path = find_venv_python()
    if python_path then
      set_python_path(python_path)
    end
    
    -- Add organize imports command
    vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightOrganizeImports', function()
      client:exec_cmd({
        command = 'basedpyright.organizeimports',
        arguments = { vim.uri_from_bufnr(bufnr) },
      })
    end, {
      desc = 'Organize Imports',
    })

    -- Add command to manually set Python path
    vim.api.nvim_buf_create_user_command(0, 'LspPyrightSetPythonPath', function(opts)
      set_python_path(opts.args)
      print("Python path set to: " .. opts.args)
    end, {
      desc = 'Reconfigure basedpyright with the provided python path',
      nargs = 1,
      complete = 'file',
    })
    
    -- Add command to show current Python path being used
    vim.api.nvim_buf_create_user_command(0, 'LspPyrightInfo', function()
      if client.settings and client.settings.python and client.settings.python.pythonPath then
        print("Python path: " .. client.settings.python.pythonPath)
      else
        print("Python path not explicitly set. Using default.")
      end
    end, {
      desc = 'Show current Python path for basedpyright',
    })
  end,
}
