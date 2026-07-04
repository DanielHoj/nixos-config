{ config, pkgs, lib, ... }:
# System-wide key remapping via keyd (ported from host /etc/keyd/default.conf).
{
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          # Caps Lock: tap = Escape, hold = Super (home-row niri Mod key).
          capslock = "overload(meta, esc)";
        };
        # Emacs-style navigation while Ctrl is held.
        control = {
          n = "down";
          p = "up";
        };
      };
    };
  };
}
