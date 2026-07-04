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
          # overloadt2: resolves as hold after 180ms OR on an intervening key tap,
          # so a quick tap fires Esc promptly and chords (Caps+D) stay reliable.
          capslock = "overloadt2(meta, esc, 180)";
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
