{ config, pkgs, lib, ... }:
# Idiomatic nvim port: the Lua config lives in the cloned ~/dotfiles (live-
# editable via an out-of-store symlink), while all LSP/DAP/formatter binaries
# and the plugin build toolchain come from Nix instead of Mason. A /etc/NIXOS
# guard in the nvim config disables Mason on NixOS (see dotfiles nvim).
{
  # nvim config from the cloned dotfiles repo (edits apply without a rebuild).
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/nvim/.config/nvim";

  home.packages = with pkgs; [
    # --- LSP servers (from init.lua's vim.lsp.enable list) ---
    basedpyright
    ruff
    gopls
    golangci-lint
    golangci-lint-langserver
    lua-language-server
    typescript-language-server
    vue-language-server
    sql-language-server

    # --- Formatters / linters (conform, nvim-lint) ---
    prettier
    uv                 # nvim-lint's uv_mypy runs mypy via uv

    # --- DAP adapters ---
    delve                                        # Go (dlv)
    vscode-js-debug                              # frontend JS/TS
    (python3.withPackages (ps: [ ps.debugpy ]))  # Python fallback adapter

    # --- Plugin build toolchain (lazy.nvim, tree-sitter parsers) ---
    gcc
    gnumake
    tree-sitter
    nodejs_22
    cargo
    rustc
    ripgrep
    fd
    curl
    unzip
  ];
}
