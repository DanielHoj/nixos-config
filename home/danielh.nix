{ config, pkgs, lib, ... }:
let
  c = config.lib.stylix.colors.withHashtag;
in
{
  imports = [ ./shell.nix ./dev.nix ./nvim-tools.nix ./tmux.nix ./niri.nix ./desktop.nix ./zen.nix ];

  home.username = "danielh";
  home.homeDirectory = "/home/danielh";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # Create ~/Downloads, ~/Documents, ~/Pictures, etc. on a fresh install.
  xdg.userDirs.enable = true;

  # Stylix targets we manage ourselves:
  stylix.targets.neovim.enable = false;  # nvim has its own colorscheme (colorschema.lua)
  stylix.targets.waybar.enable = false;  # custom waybar layout below (colors from Stylix palette)
  stylix.targets.niri.enable = false;    # niri config in ./niri.nix (niri-flake would else generate it)

  # --- Terminal (colors/fonts/opacity from Stylix) ---
  programs.ghostty = {
    enable = true;
    # Always drop into tmux (attach the "main" session, or create it).
    settings.command = "tmux new-session -A -s main";
  };

  # --- Media player (Stylix-themed) ---
  programs.mpv.enable = true;

  # --- PDF viewer (Stylix-themed; replaces KDE okular) ---
  programs.zathura.enable = true;

  # --- Launcher (fuzzel; notifications via swaync in ./desktop.nix) ---
  programs.fuzzel.enable = true;

  programs.waybar = {
    enable = true;
    systemd.enable = true;   # restarts on rebuild → no re-login for waybar/theme changes
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
      modules-right = [ "cpu" "memory" "battery" "network" "pulseaudio" "tray" ];
      clock.format = "{:%a %d %b  %H:%M}";
      clock.tooltip-format = "<tt><small>{calendar}</small></tt>";

      # Focused window (app icon + title) — distinct from the tray.
      "niri/window" = {
        format = "{}";
        icon = true;
        icon-size = 16;
        max-length = 50;
        separate-outputs = true;
      };

      # CPU / memory
      cpu.format = " {usage}%";
      cpu.interval = 5;
      memory.format = " {percentage}%";
      memory.interval = 5;

      # Network: wifi signal icons; click opens the GUI connection editor.
      network.format-wifi = "{icon} {essid}";
      network.format-ethernet = "󰈀 wired";
      network.format-disconnected = "󰤭 off";
      network.format-icons = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
      network.tooltip-format = "{ifname}: {ipaddr}";
      network.tooltip-format-wifi = "{essid}  {signalStrength}%\n{ipaddr}";
      network.on-click = "nm-connection-editor";

      # Sound: scroll to change volume, right-click to mute (via swayosd OSD).
      pulseaudio.format = "{icon} {volume}%";
      pulseaudio.format-bluetooth = "{icon}  {volume}%";
      pulseaudio.format-muted = "󰖁 muted";
      pulseaudio.format-icons = { headphone = " "; headset = " "; default = [ " " " " " " ]; };
      pulseaudio.on-click = "pavucontrol";
      pulseaudio.on-click-right = "swayosd-client --output-volume mute-toggle";
      pulseaudio.on-scroll-up = "swayosd-client --output-volume raise";
      pulseaudio.on-scroll-down = "swayosd-client --output-volume lower";

      # battery: hidden on desktops/VMs with no battery; shows on the ThinkPad.
      battery.format = "{icon} {capacity}%";
      battery.format-charging = "󰂄 {capacity}%";
      battery.format-plugged = "󰚥 {capacity}%";
      battery.format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
      battery.states = { warning = 20; critical = 10; };
      battery.interval = 30;
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
      #battery { color: ${c.base0B}; }
      #battery.warning { color: ${c.base0A}; }
      #battery.critical { color: ${c.base08}; }
      #network { color: ${c.base0D}; }
      #pulseaudio { color: ${c.base0E}; }
      #pulseaudio.muted { color: ${c.base03}; }
    '';
  };

  # niri config is in ./niri.nix (colors follow Stylix).

  # --- Wallpaper (referenced by swaybg in niri config) ---
  # Hokusai's "Great Wave off Kanagawa" (public domain) — the namesake of the
  # kanagawa theme. swaybg reads the bytes, so the .png target name is fine.
  home.file.".local/share/wallpaper.png".source = ./wallpapers/kanagawa-wave.jpg;

  home.packages = with pkgs; [
    btop
    yazi
    wl-clipboard              # niri/wayland clipboard
    brightnessctl
    swaybg                    # wallpaper
    pavucontrol               # audio GUI (waybar click target)
    easyeffects               # PipeWire EQ/effects
    obsidian                  # notes (unfree)
    imv                       # Wayland image viewer (replaces KDE gwenview)
    networkmanagerapplet      # nm-applet + nm-connection-editor (GUI wifi)
    google-chrome             # secondary browser (unfree); Zen is primary (./zen.nix)
    # Zen browser is configured in ./zen.nix (HM module installs the package).
  ];
}
