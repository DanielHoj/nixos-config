{ config, pkgs, lib, zen-browser, ... }:
let
  c = config.lib.stylix.colors.withHashtag;

  amo = slug: "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
  forced = slug: { install_url = amo slug; installation_mode = "force_installed"; };

  # Zen with declaratively force-installed extensions + sensible policy defaults.
  zen = zen-browser.packages.${pkgs.system}.default.override {
    extraPolicies = {
      DisableTelemetry = true;
      DisablePocket = true;
      DontCheckDefaultBrowser = true;
      ExtensionSettings = {
        "uBlock0@raymondhill.net" = forced "ublock-origin";
        "addon@darkreader.org" = forced "darkreader";
        "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = forced "vimium-ff";
        "78272b6fa58f4a1abaac99321d503a20@proton.me" = forced "proton-pass";
      };
    };
  };
in
{
  imports = [ ./shell.nix ./nvim-tools.nix ./tmux.nix ./niri.nix ./desktop.nix ];

  home.username = "danielh";
  home.homeDirectory = "/home/danielh";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

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
    easyeffects               # PipeWire EQ/effects
    obsidian                  # notes (unfree)
    # proton-pass desktop app removed: Electron renderer glitches in the VM.
    # Use the Zen extension + web app (pass.proton.me); revisit on bare metal.
    zen                       # Zen browser (+ extensions, defined above)
  ];
}
