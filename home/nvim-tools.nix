{ config, pkgs, lib, ... }:
# Idiomatic nvim port: the Lua config lives in the cloned ~/dotfiles (live-
# editable via an out-of-store symlink); the LSP servers, DAP adapters, and
# tree-sitter come from Nix instead of Mason. A /etc/NIXOS guard in the nvim
# config disables Mason on NixOS (see dotfiles nvim). General toolchains and
# the dual-use CLI linters/formatters these servers shell out to (ruff,
# prettier, golangci-lint, delve, gcc, node…) live in ./dev.nix and land on
# the same PATH.
{
  # nvim config from the cloned dotfiles repo (edits apply without a rebuild).
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/nvim/.config/nvim";

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
    # NOTE: sqlls (joe-re sql-language-server) isn't in nixpkgs; guarded off in
    # nvim init.lua on NixOS. Add `sqls` (Go) or package it if SQL LSP is needed.
    # ruff also provides `ruff server` (LSP) — the binary lives in ./dev.nix.

    # --- DAP adapters ---
    vscode-js-debug                              # frontend JS/TS
    (python3.withPackages (ps: [ ps.debugpy ]))  # Python fallback adapter

    # --- tree-sitter CLI (builds nvim-treesitter parsers; needs gcc from ./dev.nix) ---
    tree-sitter
  ];
}
