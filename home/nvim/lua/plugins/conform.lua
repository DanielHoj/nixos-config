return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      mode = { "n", "v" },
      desc = "Format buffer (conform)",
    },
  },
  opts = {
    -- Filetypes managed here are also skipped by the LSP format-on-save in snacks.lua.
    formatters_by_ft = {
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      vue = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      html = { "prettier" },
      json = { "prettier" },
      jsonc = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
      python = { "ruff_format", "ruff_organize_imports" },
      rust = { "rustfmt" },
      nix = { "nixfmt" },
    },
    format_on_save = function(bufnr)
      -- Disable autoformat for files in a `node_modules` or generated directory.
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      if bufname:match("/node_modules/") or bufname:match("/generated/") then
        return
      end
      return { timeout_ms = 2000, lsp_format = "never" }
    end,
    -- Pick up `prettier` from the project's local node_modules first.
    formatters = {
      prettier = {
        cwd = function(self, ctx)
          return require("conform.util").root_file({
            ".prettierrc",
            ".prettierrc.json",
            ".prettierrc.js",
            ".prettierrc.cjs",
            "prettier.config.js",
            "package.json",
          })(self, ctx)
        end,
      },
    },
  },
}
