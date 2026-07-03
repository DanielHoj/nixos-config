{ config, pkgs, lib, ... }:
{
  # --- niri (nightly, from niri-flake overlay) ---
  programs.niri.enable = true;
  programs.niri.package = pkgs.niri-unstable;

  # niri-flake binary cache so nightly niri is fetched, not built.
  niri-flake.cache.enable = true;

  # --- Wayland session prerequisites ---
  security.polkit.enable = true;
  services.dbus.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "gtk";
  };

  # --- Login: greetd + tuigreet launching a niri session ---
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
      user = "greeter";
    };
  };

  # --- Audio (PipeWire) ---
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # --- VM guest integration (clipboard + auto-resize) ---
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # --- Fonts (Nerd Font for waybar/starship glyphs) ---
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-emoji
  ];

  # --- Wayland-friendly env ---
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
