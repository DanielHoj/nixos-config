return {
  cmd = { "nixd" },
  filetypes = { "nix" },
  root_markers = {
    "flake.nix",
    ".git",
  },
  settings = {
    nixd = {
      -- Formatting is handled by conform (`nix = nixfmt`); point nixd at the same
      -- tool for its own format requests. nixpkgs/options completion is left
      -- unconfigured on purpose: those exprs are machine-specific and this config
      -- is shared with the Arch host.
      formatting = { command = { "nixfmt" } },
    },
  },
}
