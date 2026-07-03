{ config, pkgs, lib, ... }:
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

  # --- Terminal ---
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      theme = "catppuccin-mocha";
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
      height = 28;
      modules-left = [ "niri/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "cpu" "memory" "tray" ];
      clock.format = "{:%a %d %b  %H:%M}";
      cpu.format = " {usage}%";
      memory.format = " {}%";
      network.format-wifi = " {essid}";
      network.format-ethernet = " {ipaddr}";
      pulseaudio.format = " {volume}%";
    };
  };
  services.mako.enable = true;

  # --- niri config: plain KDL file (hand-editable, no rebuild to tweak) ---
  xdg.configFile."niri/config.kdl".source = ./niri/config.kdl;

  home.packages = with pkgs; [
    btop
    yazi
    wl-clipboard   # niri/wayland clipboard
    brightnessctl
  ];
}
