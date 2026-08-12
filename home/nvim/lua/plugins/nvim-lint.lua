return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufWritePost", "BufNewFile" },
  config = function()
    local lint = require("lint")

    -- Run mypy via the project's uv env so it sees the same deps CI does.
    -- Matches `cd workers && uv run mypy src/` from the me3cs Makefile.
    lint.linters.uv_mypy = {
      cmd = "uv",
      stdin = false,
      append_fname = false,
      args = function()
        local fname = vim.api.nvim_buf_get_name(0)
        return { "run", "--quiet", "mypy", "--show-column-numbers", "--no-pretty", fname }
      end,
      stream = "stdout",
      ignore_exitcode = true,
      parser = require("lint.parser").from_pattern(
        "([^:]+):(%d+):(%d+):%s+(%w+):%s+(.+)",
        { "file", "lnum", "col", "severity", "message" },
        { ["error"] = vim.diagnostic.severity.ERROR, ["note"] = vim.diagnostic.severity.HINT, ["warning"] = vim.diagnostic.severity.WARN },
        { source = "mypy" }
      ),
      cwd = function()
        -- Use the workers/ directory so uv resolves the right venv.
        local root = vim.fs.find({ "pyproject.toml" }, {
          upward = true,
          path = vim.api.nvim_buf_get_name(0),
          stop = vim.loop.os_homedir(),
        })[1]
        return root and vim.fs.dirname(root) or vim.fn.getcwd()
      end,
    }

    lint.linters_by_ft = {
      python = { "uv_mypy" },
    }

    -- Lint on save (and on enter, for cold-loaded files).
    local lint_group = vim.api.nvim_create_augroup("Me3csNvimLint", { clear = true })
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
      group = lint_group,
      callback = function()
        local ft = vim.bo.filetype
        if lint.linters_by_ft[ft] then
          lint.try_lint()
        end
      end,
    })
  end,
}
