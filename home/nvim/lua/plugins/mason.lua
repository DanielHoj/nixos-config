return {
  "mason-org/mason.nvim",
  -- On NixOS the LSP/tool binaries come from Nix (already on PATH), so Mason
  -- is disabled there; on Arch it stays enabled as before.
  enabled = not require("config.nix").is_nixos,
  -- Load at startup so Mason's bin dir is on PATH before vim.lsp.enable()
  -- validates configs that use Mason-managed executables.
  lazy = false,
  opts = {
    ui = {
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗",
      },
    },
  },
}
