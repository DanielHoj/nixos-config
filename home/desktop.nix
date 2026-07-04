{ config, pkgs, lib, ... }:
# niri "daily driver" utilities: lock/idle, notification center, OSD popups,
# clipboard history, screenshots, power menu, night light. Menus use fuzzel.
let
  screenshot-menu = pkgs.writeShellScriptBin "screenshot-menu" ''
    dir="$HOME/Pictures"; mkdir -p "$dir"
    file="$dir/screenshot-$(date +%Y-%m-%d-%H-%M-%S).png"
    choice=$(printf " region → clipboard\n region → file\n screen → file" \
      | ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt "screenshot ")
    case "$choice" in
      *"region → clipboard") ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.wl-clipboard}/bin/wl-copy
        ${pkgs.libnotify}/bin/notify-send "Screenshot" "Region copied to clipboard" ;;
      *"region → file") ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" "$file"
        ${pkgs.libnotify}/bin/notify-send "Screenshot" "Saved $file" ;;
      *"screen → file") ${pkgs.grim}/bin/grim "$file"
        ${pkgs.libnotify}/bin/notify-send "Screenshot" "Saved $file" ;;
    esac
  '';

  clipboard-menu = pkgs.writeShellScriptBin "clipboard-menu" ''
    ${pkgs.cliphist}/bin/cliphist list \
      | ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt "clipboard " \
      | ${pkgs.cliphist}/bin/cliphist decode \
      | ${pkgs.wl-clipboard}/bin/wl-copy
  '';

  power-menu = pkgs.writeShellScriptBin "power-menu" ''
    choice=$(printf " Lock\n Suspend\n Reboot\n Shutdown\n Logout" \
      | ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt "power ")
    case "$choice" in
      *Lock)     ${pkgs.swaylock-effects}/bin/swaylock -f ;;
      *Suspend)  systemctl suspend ;;
      *Reboot)   systemctl reboot ;;
      *Shutdown) systemctl poweroff ;;
      *Logout)   niri msg action quit ;;
    esac
  '';
in
{
  # --- Lock screen (Stylix-themed) ---
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      clock = true;
      indicator = true;
      screenshots = true;
      effect-blur = "7x5";
      indicator-radius = 100;
      show-failed-attempts = true;
    };
  };

  # --- Idle: lock after 15 min, suspend after 30, lock before sleep ---
  services.swayidle = {
    enable = true;
    timeouts = [
      { timeout = 900; command = "${pkgs.swaylock-effects}/bin/swaylock -f"; }
      { timeout = 1800; command = "systemctl suspend"; }
    ];
    events = [
      { event = "before-sleep"; command = "${pkgs.swaylock-effects}/bin/swaylock -f"; }
    ];
  };

  # --- Notification center + DND (Stylix-themed; replaces mako) ---
  services.swaync.enable = true;

  # --- Volume/brightness OSD popups ---
  services.swayosd.enable = true;

  # --- Clipboard history (wl-paste watchers) ---
  services.cliphist.enable = true;

  # --- Night light (Copenhagen) ---
  services.wlsunset = {
    enable = true;
    latitude = "55.7";
    longitude = "12.6";
  };

  home.packages = [
    screenshot-menu
    clipboard-menu
    power-menu
    pkgs.grim
    pkgs.slurp
    pkgs.libnotify
  ];
}
