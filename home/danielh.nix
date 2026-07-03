{ config, pkgs, lib, zen-browser, ... }:
{
  home.username = "danielh";
  home.homeDirectory = "/home/danielh";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # --- Shell: native HM (replaces zinit) ---
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    history.size = 50000;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
  };

  # --- Terminal (Nord colors) ---
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 11;
      background = "#2e3440";
      foreground = "#d8dee9";
      cursor-color = "#88c0d0";
      selection-background = "#434c5e";
      background-opacity = 0.97;
      palette = [
        "0=#3b4252" "1=#bf616a" "2=#a3be8c" "3=#ebcb8b"
        "4=#81a1c1" "5=#b48ead" "6=#88c0d0" "7=#e5e9f0"
        "8=#4c566a" "9=#bf616a" "10=#a3be8c" "11=#ebcb8b"
        "12=#81a1c1" "13=#b48ead" "14=#8fbcbb" "15=#eceff4"
      ];
    };
  };

  # --- Multiplexer / VCS ---
  programs.tmux.enable = true;
  programs.git = {
    enable = true;
    userName = "danielh";
    userEmail = "danielhoj@pm.me";
  };
  programs.lazygit.enable = true;

  # --- Wayland desktop companions ---
  programs.fuzzel.enable = true;
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
      modules-left = [ "niri/workspaces" "niri/window" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "cpu" "memory" "tray" ];
      "niri/window".max-length = 60;
      clock.format = "{:%a %d %b  %H:%M}";
      clock.tooltip-format = "<tt><small>{calendar}</small></tt>";
      cpu.format = " {usage}%";
      memory.format = " {}%";
      network.format-wifi = " {essid}";
      network.format-ethernet = " {ipaddr}";
      network.format-disconnected = "󰤭 ";
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
        color: #d8dee9;
      }
      .modules-left, .modules-center, .modules-right {
        background: #2e3440;
        border-radius: 10px;
        padding: 0 6px;
      }
      #workspaces button {
        color: #4c566a;
        padding: 0 6px;
      }
      #workspaces button.active {
        color: #88c0d0;
      }
      #workspaces button.urgent {
        color: #bf616a;
      }
      #window { color: #81a1c1; padding: 0 8px; }
      #clock { color: #eceff4; font-weight: bold; padding: 0 10px; }
      #cpu, #memory, #network, #pulseaudio, #tray {
        padding: 0 8px;
      }
      #cpu { color: #a3be8c; }
      #memory { color: #ebcb8b; }
      #network { color: #81a1c1; }
      #pulseaudio { color: #b48ead; }
      #pulseaudio.muted { color: #4c566a; }
    '';
  };

  services.mako = {
    enable = true;
    settings = {
      background-color = "#2e3440";
      text-color = "#d8dee9";
      border-color = "#88c0d0";
      border-size = 2;
      border-radius = 10;
      padding = "10";
      margin = "10";
      default-timeout = 5000;
      font = "JetBrainsMono Nerd Font 10";
    };
  };

  # --- niri config: plain KDL file (hand-editable, no rebuild to tweak) ---
  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;

  # --- Wallpaper (referenced by swaybg in niri config) ---
  home.file.".local/share/wallpaper.png".source = ./wallpapers/nord.png;

  # --- GTK / cursor / UI font theming ---
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    font = {
      name = "Cantarell";
      size = 11;
      package = pkgs.cantarell-fonts;
    };
  };

  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
  };

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
