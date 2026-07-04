{ config, pkgs, lib, ... }:
# Centralized theming. Change `base16Scheme` to re-theme the whole desktop
# (ghostty, tmux, mako, fuzzel, GTK, waybar, niri) in one place, then rebuild.
# Swap nord.yaml for e.g. catppuccin-mocha.yaml / kanagawa.yaml /
# tokyo-night-dark.yaml — see ${pkgs.base16-schemes}/share/themes/.
{
  stylix = {
    enable = true;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
    image = ../home/wallpapers/nord.png;

    cursor = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 24;
    };

    fonts = {
      monospace = {
        name = "JetBrainsMono Nerd Font";
        package = pkgs.nerd-fonts.jetbrains-mono;
      };
      sansSerif = {
        name = "Cantarell";
        package = pkgs.cantarell-fonts;
      };
      serif = {
        name = "Noto Serif";
        package = pkgs.noto-fonts;
      };
      emoji = {
        name = "Noto Color Emoji";
        package = pkgs.noto-fonts-emoji;
      };
      sizes = {
        terminal = 11;
        applications = 11;
      };
    };

    opacity.terminal = 0.97;
  };
}
