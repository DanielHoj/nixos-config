vim.g.mapleader = " "
vim.g.localmapleader = " "

require("config.lazy")
require("options")
require("keymaps")

local lsp_servers = {
  "basedpyright",
  "ruff",
  "lua_ls",
  "ts_ls",
  "vue_ls",
  -- eslint disabled: vscode-langservers-extracted@4.10.0 (latest published)
  -- doesn't support ESLint v10's removal of `FlatESLint`. Re-enable once
  -- upstream ships v10 support. Until then, `make lint-frontend` covers it.
  -- "eslint",
  "gopls",
  "golangci_lint_ls",
  "rust_analyzer",
  "nixd",
}

-- sqlls (joe-re sql-language-server) isn't packaged in nixpkgs, so only enable
-- it where Mason provides it (Arch), not on NixOS.
if not require("config.nix").is_nixos then
  table.insert(lsp_servers, "sqlls")
end

vim.lsp.enable(lsp_servers)

-- Go uses tabs per gofmt convention
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "go", "gomod", "gowork", "gotmpl" },
  callback = function()
    vim.bo.expandtab = false
    vim.bo.tabstop = 4
    vim.bo.shiftwidth = 4
    vim.bo.softtabstop = 4
  end,
})

-- Stop LSP clients cleanly on exit so tsserver/vue_ls don't end up
-- as orphaned children eating RAM + holding inotify watches.
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("LspCleanShutdown", { clear = true }),
  callback = function()
    for _, client in ipairs(vim.lsp.get_clients()) do
      pcall(vim.lsp.stop_client, client.id, true)
    end
  end,
})

