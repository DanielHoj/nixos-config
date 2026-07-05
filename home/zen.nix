{ config, pkgs, lib, zen-browser, ... }:
# Zen browser, configured declaratively via zen-browser-flake's Home Manager
# module (the `beta` variant → the `zen-beta` binary that niri's Mod+B spawns).
# The module wraps HM's Firefox module, so extensions/policies, about:config
# prefs, containers and spaces are all managed here.
let
  amo = slug: "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
  forced = slug: { install_url = amo slug; installation_mode = "force_installed"; };
in
{
  imports = [ zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;

    # Enforced org policies (policies.json) — the user cannot change these.
    policies = {
      DisableTelemetry = true;
      DisablePocket = true;
      DontCheckDefaultBrowser = true;
      ExtensionSettings = {
        "uBlock0@raymondhill.net" = forced "ublock-origin";
        "addon@darkreader.org" = forced "darkreader";
        "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = forced "vimium-ff";
        "78272b6fa58f4a1abaac99321d503a20@proton.me" = forced "proton-pass";
        "vpn@proton.ch" = forced "proton-vpn-firefox-extension";
      };
    };

    profiles.default = {
      # about:config prefs (prefs.js) — defaults, still changeable in-browser.
      settings = {
        "zen.workspaces.continue-where-left-off" = true;
        "zen.welcome-screen.seen" = true;
      };

      # One isolated cookie jar per space (Firefox contextual identities).
      containersForce = true;   # prune containers not declared here
      containers = {
        Personal = { color = "purple"; icon = "fingerprint"; id = 1; };
        Dev      = { color = "blue";   icon = "briefcase";   id = 2; };
      };

      # Declarative workspaces, each bound to its container above.
      # ⚠ Close Zen before `nixos-rebuild switch`: the activation script rewrites
      #   Zen's compressed session file (zen-sessions.jsonlz4) and needs exclusive
      #   access. Changing a space's `id` re-creates it (loses that space's tabs).
      spacesForce = true;       # prune spaces not declared here
      spaces = {
        "Personal" = {
          id = "a1b2c3d4-0001-4e5f-8a9b-0123456789ab";
          position = 1000;
          icon = "🏠";
          container = 1;
        };
        "Dev" = {
          id = "a1b2c3d4-0002-4e5f-8a9b-0123456789ab";
          position = 2000;
          icon = "🧑‍💻";
          container = 2;
        };
      };
    };
  };
}
