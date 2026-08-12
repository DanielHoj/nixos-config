return {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  root_markers = {
    "Cargo.toml",
    "Cargo.lock",
    "rust-project.json",
    ".git",
  },
  settings = {
    ["rust-analyzer"] = {
      -- Lint with clippy on save (needs `clippy` on PATH — from nixos-config dev.nix).
      checkOnSave = true,
      check = { command = "clippy" },
      cargo = { allFeatures = true, buildScripts = { enable = true } },
      procMacro = { enable = true },
      inlayHints = {
        bindingModeHints = { enable = false },
        closureReturnTypeHints = { enable = "always" },
        parameterHints = { enable = true },
        typeHints = { enable = true },
      },
    },
  },
}
