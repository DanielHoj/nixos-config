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
  # swayosd ships a udev rule granting the `video` group write access to the
  # backlight brightness node. home-manager's services.swayosd only runs the
  # daemon, it doesn't install this, so brightness keys silently no-op
  # without it (volume works fine since PipeWire needs no special perms).
  services.udev.packages = [ pkgs.swayosd ];
  # Portals: gtk for the file chooser/settings, gnome for screencast (so
  # screen-sharing in Zoom/Meet/browsers works), gnome-keyring for the Secret
  # portal. Routing Screencast to gtk (the old default) silently breaks it.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-gnome ];
    config.common = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.Screencast" = [ "gnome" ];
      "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
    };
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

  # --- Fonts (Nerd Font for waybar/starship glyphs) ---
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    inter                       # crisp UI sans
    noto-fonts
    noto-fonts-color-emoji   # renamed from noto-fonts-emoji in nixpkgs 26.05
    cantarell-fonts
    liberation_ttf              # Arial/Times/Courier-compatible metrics (docs/web)
    dejavu_fonts
  ];

  # X11 app support: niri (25.08+) natively spawns xwayland-satellite and
  # exports $DISPLAY on demand — it just needs the binary on PATH.
  environment.systemPackages = [
    niri-flake.packages.${pkgs.system}.xwayland-satellite-unstable
  ];

  # --- Wayland-friendly env ---
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
