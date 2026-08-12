{ config, pkgs, lib, ... }:
# Base home profile: the portable dev environment shared by EVERY host, desktop
# or headless. Shell, dev toolchains, editor, and multiplexer — no GUI, no
# Stylix dependency. SSH into any box and you get the same setup.
{
  imports = [
    ../shell.nix
    ../dev.nix
    ../nvim-tools.nix
    ../tmux.nix
  ];

  home.username = "danielh";
  home.homeDirectory = "/home/danielh";
  # 26.05: the whole setup targets 26.05 defaults (all hosts installed within
  # days of each other against this flake, none predate the 26.05 channel).
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  # CLI tools wanted on every host, including headless (yazi backs shell.nix's `y`).
  home.packages = with pkgs; [
    btop
    yazi
  ];
}
