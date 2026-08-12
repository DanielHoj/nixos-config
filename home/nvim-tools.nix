{ config, pkgs, lib, ... }:
# Idiomatic nvim port: the Lua config lives in this repo (home/nvim/, live-
# editable via an out-of-store symlink); the LSP servers, DAP adapters, and
# tree-sitter come from Nix instead of Mason. A /etc/NIXOS guard in the nvim
# config disables Mason on NixOS (see home/nvim). General toolchains and
# the dual-use CLI linters/formatters these servers shell out to (ruff,
# prettier, golangci-lint, delve, gcc, node…) live in ./dev.nix and land on
# the same PATH.
{
  # nvim Lua config lives in this repo (home/nvim/), symlinked out-of-store so
  # edits apply live without a rebuild and lazy.nvim can write lazy-lock.json /
  # install plugins at runtime. Migrated from the old ~/dotfiles (Stow) clone.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-config/home/nvim";

  # Editor plumbing only — kept on the unstable overlay because LSP servers and
  # DAP adapters move fast and need to match neovim's current APIs.
  home.packages = with pkgs.unstable; [
    # --- LSP servers (from init.lua's vim.lsp.enable list) ---
    basedpyright
    gopls
    golangci-lint-langserver   # wraps golangci-lint (CLI in ./dev.nix)
    lua-language-server
    typescript-language-server
    vue-language-server
    rust-analyzer              # Rust LSP (runs clippy on save; needs cargo/clippy from ./dev.nix)
    nixd                       # Nix LSP (flake/NixOS-options aware)
    # NOTE: sqlls (joe-re sql-language-server) isn't in nixpkgs; guarded off in
    # nvim init.lua on NixOS. Add `sqls` (Go) or package it if SQL LSP is needed.
    # ruff also provides `ruff server` (LSP) — the binary lives in ./dev.nix.

    # --- DAP adapters ---
    vscode-js-debug                              # frontend JS/TS
    (python3.withPackages (ps: [ ps.debugpy ]))  # Python fallback adapter
    # Rust (and C/C++) debugging: put a `codelldb` on PATH so nvim-dap finds it
    # via exepath(), matching how dlv/debugpy are resolved. The upstream package
    # ships the adapter inside the vscode extension tree; wrap it as a bare cmd.
    (writeShellScriptBin "codelldb" ''
      exec ${vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb "$@"
    '')

    # --- tree-sitter CLI (builds nvim-treesitter parsers; needs gcc from ./dev.nix) ---
    tree-sitter
  ];
}
