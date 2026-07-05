{ config, pkgs, lib, ... }:
# General development toolchains + CLIs — everything you'd want at a shell
# regardless of editor. Editor-only plumbing (LSP servers, DAP adapters,
# tree-sitter) lives in ./nvim-tools.nix. These sit on plain stable `pkgs`
# (26.05): unlike fast-moving LSP servers, toolchains have no reason to track
# nightly, so they stay on the leaner, more stable channel.
{
  home.packages = with pkgs; [
    # --- Language toolchains ---
    cargo
    rustc
    uv                 # Python env/package manager
    gcc                # C compiler (also builds nvim's tree-sitter parsers / native plugins)
    gnumake
    nodejs_22          # moved here from shell.nix (was the Arch nvm replacement)
    bun                # moved here from shell.nix (was ~/.bun)

    # --- Dual-use linters / formatters / debuggers ---
    # Real CLIs you can invoke directly; nvim (conform/nvim-lint/nvim-dap) also
    # calls them from PATH. Their LSP wrappers live in ./nvim-tools.nix.
    ruff               # Python linter/formatter
    prettier           # JS/TS/web formatter
    golangci-lint      # Go meta-linter (golangci-lint-langserver wraps this)
    delve              # Go debugger (dlv)

    # --- General CLI utilities ---
    ripgrep
    fd
    curl
    unzip
  ];
}
