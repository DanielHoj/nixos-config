{ config, pkgs, lib, zen-browser, ... }:
let
  c = config.lib.stylix.colors.withHashtag;
in
{
  imports = [ ./shell.nix ./nvim-tools.nix ./tmux.nix ./niri.nix ];

  home.username = "danielh";
  home.homeDirectory = "/home/danielh";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # Stylix targets we manage ourselves:
  stylix.targets.neovim.enable = false;  # nvim has its own colorscheme (colorschema.lua)
  stylix.targets.waybar.enable = false;  # custom waybar layout below (colors from Stylix palette)
  stylix.targets.niri.enable = false;    # keep our editable config.kdl (niri-flake would else generate it)

  # --- Terminal (colors/fonts/opacity from Stylix) ---
  programs.ghostty.enable = true;

  # --- Wayland desktop companions (mako/fuzzel themed by Stylix) ---
  programs.fuzzel.enable = true;
  services.mako.enable = true;

  programs.waybar = {
    enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 30;
      spacing = 6;
      margin-top = 6;
      margin-left = 8;
      margin-right = 8;
      modules-left = [ "niri/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "network" "pulseaudio" "tray" ];
      clock.format = "{:%a %d %b  %H:%M}";
      clock.tooltip-format = "<tt><small>{calendar}</small></tt>";
      network.format-wifi = " {essid}";
      network.format-ethernet = " ";
      network.format-disconnected = "󰤭 ";
      network.tooltip-format = "{ifname}: {ipaddr}";
      pulseaudio.format = " {volume}%";
      pulseaudio.format-muted = "󰖁 ";
      pulseaudio.on-click = "pavucontrol";
      tray.spacing = 8;
    };
    style = ''
      * {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 12px;
        min-height: 0;
      }
      window#waybar {
        background: transparent;
        color: ${c.base04};
      }
      .modules-left, .modules-center, .modules-right {
        background: ${c.base00};
        border-radius: 10px;
        padding: 0 6px;
      }
      #workspaces button {
        color: ${c.base03};
        padding: 0 6px;
      }
      #workspaces button.active {
        color: ${c.base0C};
      }
      #workspaces button.urgent {
        color: ${c.base08};
      }
      #window { color: ${c.base0D}; padding: 0 8px; }
      #clock { color: ${c.base06}; font-weight: bold; padding: 0 10px; }
      #cpu, #memory, #network, #pulseaudio, #tray {
        padding: 0 8px;
      }
      #cpu { color: ${c.base0B}; }
      #memory { color: ${c.base0A}; }
      #network { color: ${c.base0D}; }
      #pulseaudio { color: ${c.base0E}; }
      #pulseaudio.muted { color: ${c.base03}; }
    '';
  };

  # niri config is in ./niri.nix (colors follow Stylix).

  # --- Wallpaper (referenced by swaybg in niri config) ---
  home.file.".local/share/wallpaper.png".source = ./wallpapers/nord.png;

  home.packages = with pkgs; [
    btop
    yazi
    wl-clipboard              # niri/wayland clipboard
    brightnessctl
    swaybg                    # wallpaper
    pavucontrol               # audio GUI (waybar click target)
    zen-browser.packages.${pkgs.system}.default
  ];
}
