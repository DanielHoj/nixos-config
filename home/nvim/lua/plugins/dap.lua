-- Unified DAP for the me3cs stack:
--   * Python (workers/) via debugpy
--   * Go (backend/) via Delve
--   * TypeScript / Vue (frontend/) via vscode-js-debug
--   * Rust via codelldb
-- Same keymaps and UI for all four. Filetype dispatches to the right
-- configurations table automatically.

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "rcarriga/nvim-dap-ui",
      { "mfussenegger/nvim-dap-python", lazy = true },
      "igorlfs/nvim-dap-view",
      "leoluz/nvim-dap-go",
      {
        "jay-babu/mason-nvim-dap.nvim",
        -- NixOS: js-debug-adapter comes from Nix (vscode-js-debug), so skip
        -- Mason entirely. On Arch this stays enabled as before.
        enabled = not require("config.nix").is_nixos,
        dependencies = { "mason-org/mason.nvim" },
        opts = {
          -- Mason-managed DAP adapters. Delve lives in ~/go/bin already.
          -- debugpy is installed by dap-python through the project venv.
          ensure_installed = { "js-debug-adapter" },
          handlers = {}, -- skip auto-config; we wire each adapter ourselves
        },
      },
    },
    keys = {
      { "<M-d>c", desc = "DAP: [c]ontinue" },
      { "<M-d>o", desc = "DAP: Step [o]ver" },
      { "<M-d>O", desc = "DAP: Step [O]ut" },
      { "<M-d>i", desc = "DAP: Step [i]nto" },
      { "<M-d>b", desc = "DAP: Toggle [b]reakpoint" },
      { "<M-d>B", desc = "DAP: Conditional [B]reakpoint" },
      { "<M-d>r", desc = "DAP: toggle [r]EPL" },
      { "<M-d>u", desc = "DAP: toggle [u]i" },
      { "<M-d>h", desc = "DAP: [h]over" },
      { "<M-d>v", desc = "DAP: variable explorer" },
      { "<M-d>s", desc = "DAP: [s]top" },
      { "<M-d>R", desc = "DAP: [R]estart" },
      { "<M-d>tm", desc = "DAP-Python: Test Method" },
      { "<M-d>tc", desc = "DAP-Python: Test Class" },
      { "<M-d>ts", desc = "DAP-Python: Debug Selection" },
      { "<M-d>gt", desc = "DAP-Go: Debug nearest test" },
      { "<M-d>gT", desc = "DAP-Go: Debug last test" },
      { "<M-CR>", mode = { "n", "x" }, desc = "DAP-Python: send selection/current block" },
    },
    config = function()
      local dap = require('dap')
      local dapui = require('dapui')
      local dap_python = require('dap-python')
      local dap_view = require('dap-view')
      local dap_go = require('dap-go')

      -- ── helpers ────────────────────────────────────────────────────────

      local function find_venv_python()
        local cwd = vim.fn.getcwd()
        local candidates = {
          cwd .. "/.venv/bin/python",
          cwd .. "/venv/bin/python",
          cwd .. "/workers/.venv/bin/python",
        }
        for _, path in ipairs(candidates) do
          if vim.fn.executable(path) == 1 then return path end
        end
        return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
      end

      -- Resolve the per-worktree Vite port from `.env.worktree` (allocated
      -- by `make worktree-setup`). Falls back to 5173 (main worktree).
      local function vite_port()
        local cwd = vim.fn.getcwd()
        local env_file = cwd .. "/.env.worktree"
        if vim.fn.filereadable(env_file) ~= 1 then
          -- Try the frontend subdir's parent
          env_file = cwd .. "/../.env.worktree"
        end
        if vim.fn.filereadable(env_file) == 1 then
          for line in io.lines(env_file) do
            local port = line:match("^VITE_PORT=(%d+)")
            if port then return tonumber(port) end
          end
        end
        return 5173
      end

      -- ── Python (workers/) ──────────────────────────────────────────────

      dap_python.setup(find_venv_python())
      dap_python.test_runner = 'pytest'

      dap.configurations.python = {
        {
          type = 'python',
          request = 'launch',
          name = "Python: launch current file",
          program = "${file}",
          pythonPath = find_venv_python,
          console = "integratedTerminal",
          justMyCode = false,
        },
        {
          type = 'python',
          request = 'launch',
          name = 'Python: launch module',
          module = function() return vim.fn.input('Module: ') end,
          pythonPath = find_venv_python,
          console = "integratedTerminal",
        },
        {
          type = 'python',
          request = 'attach',
          name = 'Python: attach (debugpy.listen)',
          connect = function()
            local host = vim.fn.input('Host [127.0.0.1]: ', '127.0.0.1')
            local port = tonumber(vim.fn.input('Port [5678]: ', '5678')) or 5678
            return { host = host, port = port }
          end,
        },
      }

      -- ── Go (backend/) ──────────────────────────────────────────────────

      dap_go.setup({
        delve = {
          path = vim.fn.exepath("dlv"),
          -- me3cs CLAUDE.md: Go debugging needs `-N -l` to disable
          -- optimizations. dap-go passes -gcflags through automatically.
        },
      })

      -- nvim-dap-go populates dap.configurations.go with the standard
      -- "Debug", "Debug Package", "Debug test", "Debug last test" entries.
      -- Append me3cs-specific scenarios:
      table.insert(dap.configurations.go, {
        type = "go",
        name = "Go: backend (cmd/server)",
        request = "launch",
        mode = "debug",
        program = "${workspaceFolder}/backend/cmd/server",
      })
      table.insert(dap.configurations.go, {
        type = "go",
        name = "Go: attach to delve (127.0.0.1:2345)",
        request = "attach",
        mode = "remote",
        port = 2345,
        host = "127.0.0.1",
      })

      -- ── Rust via codelldb ──────────────────────────────────────────────
      -- codelldb comes from Nix (nixos-config nvim-tools.nix) and is on PATH.

      local codelldb = vim.fn.exepath("codelldb")
      if codelldb ~= "" then
        dap.adapters.codelldb = {
          type = "server",
          port = "${port}",
          executable = {
            command = codelldb,
            args = { "--port", "${port}" },
          },
        }

        dap.configurations.rust = {
          {
            type = "codelldb",
            request = "launch",
            name = "Rust: launch debug binary",
            program = function()
              return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
          },
          {
            type = "codelldb",
            request = "launch",
            name = "Rust: launch test binary",
            program = function()
              return vim.fn.input("Test executable: ", vim.fn.getcwd() .. "/target/debug/deps/", "file")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
          },
        }
      end

      -- ── Frontend (vue / ts / tsx / js) via vscode-js-debug ─────────────

      -- Resolve the vscode-js-debug DAP server. On NixOS it comes from Nix as a
      -- `js-debug` wrapper on PATH (nixos-config nvim-tools.nix); on Arch, Mason
      -- installs it under stdpath('data'). Either way it takes the port as argv.
      local js_debug_exe = vim.fn.exepath("js-debug")
      local mason_js = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter"
      local js_exec
      if js_debug_exe ~= "" then
        js_exec = { command = js_debug_exe, args = { "${port}" } }
      elseif vim.fn.isdirectory(mason_js) == 1 then
        js_exec = { command = "node", args = { mason_js .. "/js-debug/src/dapDebugServer.js", "${port}" } }
      end

      if js_exec then
        for _, adapter in ipairs({ "pwa-chrome", "pwa-node" }) do
          dap.adapters[adapter] = {
            type = "server",
            host = "localhost",
            port = "${port}",
            executable = js_exec,
          }
        end

        local function frontend_root()
          local cwd = vim.fn.getcwd()
          if vim.fn.isdirectory(cwd .. "/frontend") == 1 then
            return cwd .. "/frontend"
          end
          return cwd  -- assume cwd is already inside frontend/
        end

        local frontend_configs = {
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Frontend: launch Chrome on Vite",
            url = function() return "http://localhost:" .. vite_port() end,
            webRoot = frontend_root,
            sourceMaps = true,
            -- Use a separate user-data-dir so the debug Chrome doesn't
            -- collide with your normal Chrome session.
            userDataDir = "${env:HOME}/.cache/me3cs-debug-chrome",
          },
          {
            type = "pwa-chrome",
            request = "attach",
            name = "Frontend: attach to Chrome (port 9222)",
            port = 9222,
            webRoot = frontend_root,
            sourceMaps = true,
            -- Start Chrome with: chromium --remote-debugging-port=9222
          },
          {
            type = "pwa-node",
            request = "launch",
            name = "Frontend: debug Vitest (current file)",
            cwd = frontend_root,
            runtimeExecutable = "npx",
            runtimeArgs = { "vitest", "run", "${file}" },
            console = "integratedTerminal",
            sourceMaps = true,
            skipFiles = { "<node_internals>/**" },
          },
        }

        for _, ft in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact", "vue" }) do
          dap.configurations[ft] = frontend_configs
        end
      end

      -- ── DAP UI ──────────────────────────────────────────────────────────

      dap_view.setup()

      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
        mappings = {
          expand = { "<CR>", "<2-LeftMouse>" },
          open = "o",
          remove = "d",
          edit = "e",
          repl = "r",
          toggle = "t",
        },
        layouts = {
          {
            elements = {
              { id = "scopes", size = 0.25 },
              "breakpoints",
              "stacks",
              "watches",
            },
            size = 40,
            position = "right",
          },
          {
            elements = { "repl", "console" },
            size = 0.25,
            position = "bottom",
          },
        },
        floating = {
          max_height = nil,
          max_width = nil,
          border = "single",
          mappings = { close = { "q", "<Esc>" } },
        },
        windows = { indent = 1 },
        render = {
          max_type_length = nil,
          max_value_lines = 100,
        },
      })

      -- Auto-open / close DAP UI with the debug session
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

      -- ── Keymaps (filetype-agnostic) ────────────────────────────────────

      local keymap = vim.keymap

      keymap.set('n', '<M-d>c', function() dap.continue() end, { desc = "DAP: [c]ontinue" })
      keymap.set('n', '<M-d>o', function() dap.step_over() end, { desc = "DAP: Step [o]ver" })
      keymap.set('n', '<M-d>O', function() dap.step_out() end, { desc = "DAP: Step [O]ut" })
      keymap.set('n', '<M-d>i', function() dap.step_into() end, { desc = "DAP: Step [i]nto" })
      keymap.set('n', '<M-d>b', function() dap.toggle_breakpoint() end, { desc = "DAP: Toggle [b]reakpoint" })
      keymap.set('n', '<M-d>B', function()
        dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
      end, { desc = "DAP: Conditional [B]reakpoint" })
      keymap.set('n', '<M-d>r', function() dap.repl.toggle() end, { desc = "DAP: toggle [r]EPL" })
      keymap.set('n', '<M-d>u', function() dapui.toggle() end, { desc = "DAP: toggle [u]i" })
      keymap.set('n', '<M-d>h', function() dapui.eval(nil, { enter = true }) end, { desc = "DAP: [h]over" })
      keymap.set('n', '<M-d>v', function() dapui.open({ 1, reset = true }) end, { desc = "DAP: variable explorer" })
      keymap.set('n', '<M-d>s', function() dap.terminate() end, { desc = "DAP: [s]top" })
      keymap.set('n', '<M-d>R', function() dap.restart() end, { desc = "DAP: [R]estart" })

      -- Python-specific (test runners via dap-python)
      keymap.set('n', '<M-d>tm', function() dap_python.test_method() end, { desc = "DAP-Python: Test Method" })
      keymap.set('n', '<M-d>tc', function() dap_python.test_class() end, { desc = "DAP-Python: Test Class" })
      keymap.set('n', '<M-d>ts', function() dap_python.debug_selection() end, { desc = "DAP-Python: Debug Selection" })

      -- Go-specific (test helpers via nvim-dap-go)
      keymap.set('n', '<M-d>gt', function() dap_go.debug_test() end, { desc = "DAP-Go: Debug nearest test" })
      keymap.set('n', '<M-d>gT', function() dap_go.debug_last_test() end, { desc = "DAP-Go: Debug last test" })

      -- Send the current Python block/selection to the DAP REPL, launching the
      -- current file first if no session exists.
      keymap.set({ "n", "x" }, "<M-CR>", function()
        local lines = require('keymaps.python-parser').get_text()
        if dap.session() then
          dap.repl.execute(lines)
          dd(lines)
        else
          dap.set_breakpoint()
          dap.run({
            type = 'python',
            request = 'launch',
            name = "Launch file",
            program = "${file}",
            pythonPath = find_venv_python,
            console = "integratedTerminal",
          })
          dap.repl.execute(lines)
          dd(lines)
        end
      end, { desc = "DAP-Python: send selection/current block" })
    end,
  }
}
