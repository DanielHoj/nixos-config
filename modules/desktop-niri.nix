{ config, pkgs, lib, niri-flake, ... }:
{
  # --- niri (nightly) ---
  # Use niri-flake's `packages` output (built against niri-flake's own nixpkgs),
  # NOT `pkgs.niri-unstable` from the overlay (built against our nixpkgs). Only
  # the former matches what niri-flake's CI pushes to niri.cachix.org, so this is
  # what makes the binary cache actually hit instead of compiling from source.
  programs.niri.enable = true;
  programs.niri.package = niri-flake.packages.${pkgs.system}.niri-unstable;

  # niri-flake binary cache so nightly niri is fetched, not built.
  niri-flake.cache.enable = true;

  # --- Wayland session prerequisites ---
  security.polkit.enable = true;
  # swaylock needs a PAM service to verify the password (else it hangs on "validating").
  security.pam.services.swaylock = { };
  # Secret Service (keyring) so apps like Proton Pass can store their session key.
  services.gnome.gnome-keyring.enable = true;
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
    nerd-fonts.fira-code
    inter                       # crisp UI sans
    noto-fonts
    noto-fonts-color-emoji   # renamed from noto-fonts-emoji in nixpkgs 26.05
    cantarell-fonts
  ];

  # --- Wayland-friendly env ---
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
