# NixOS + niri evaluation VM — Design

**Date:** 2026-07-03
**Host:** EndeavourOS (Arch-based), KDE Plasma / Wayland
**Goal:** Build a minimal, real, persistent NixOS + niri VM to evaluate NixOS and niri. Long-term this flake becomes the config for bare-metal on this machine, so it is structured for multi-host from day one.

## Workflow

- **Session 1 (this session):** author the flake repo on the host, install the libvirt stack, create the VM, install NixOS from the minimal ISO using the flake, boot into niri, verify.
- **Session 2+ (inside the VM):** edit the config in the repo, run `sudo nixos-rebuild switch --flake .#nixos-vm`, iterate. Take virt-manager snapshots before risky changes.

Explicitly out of scope for session 1: porting the large neovim config, screenshots/wallpaper/clipboard-manager/idle-lock tooling, and the second (bare-metal) host entry. These come later.

## Decisions (locked)

| Topic | Decision |
|-------|----------|
| Host VM stack | libvirt + virt-manager + QEMU/KVM |
| Config style | Flakes, nixpkgs pinned |
| Home Manager | Yes, as a NixOS module (one `nixos-rebuild` applies system + user) |
| Login | greetd + tuigreet launching niri |
| Terminal | ghostty |
| Launcher | fuzzel |
| Bar | waybar (minimal) |
| Notifications | mako |
| Editor/tools (system) | neovim, git (bootstrap) |
| Shell | zsh + starship + atuin reimplemented **natively in Home Manager** (not porting zinit) |
| Repo location | `~/nixos-config` (separate from Stow `~/dotfiles`) |
| Channel | Hybrid: stable `25.05` base + `nixpkgs-unstable` overlay (`pkgs.unstable.*`); niri on **nightly** via `niri-flake` |
| VM resources | 4 vCPU / 8 GB RAM / 40 GB disk |

## Install approach

Boot the **official NixOS minimal ISO** in the VM → standard UEFI partition (ESP + root) → `nixos-generate-config --root /mnt` to capture the VM's `hardware-configuration.nix` → clone this flake → `nixos-install --flake .#nixos-vm`. This rehearses the real bare-metal install.

Rejected: building the image on the host with `nixos-generators` — the Arch host has no Nix and it wouldn't rehearse the install.

## Host side (EndeavourOS)

- Install from Arch repos: `qemu-full`, `libvirt`, `virt-manager`, `dnsmasq`, `edk2-ovmf`.
- Enable `libvirtd`; add `danielh` to the `libvirt` group.
- VM: UEFI (OVMF), qcow2 disk, virtio disk/net, SPICE display + spice guest agent (clipboard + auto-resize).
- Suggested VM resources: 4 vCPU, 8 GB RAM, 40 GB disk (tunable).

## Channels / inputs

- `nixpkgs` pinned to `nixos-25.05` (stable) — the base for all system + user packages.
- `nixpkgs-unstable` as a second input, surfaced through an overlay as `pkgs.unstable.<name>`. Moving any package to nightly is then a one-word change.
- `niri-flake` (`github:sodiboo/niri-flake`) for **niri nightly** plus its NixOS/HM module. Its `niri-flake.cache` binary cache is enabled so nightly niri is fetched, not built.

## Flake repo structure

```
nixos-config/
  flake.nix                         # inputs: nixpkgs (25.05), nixpkgs-unstable, home-manager, niri-flake
  hosts/nixos-vm/
    configuration.nix               # system config for the VM
    hardware-configuration.nix      # generated inside the VM at install time
  modules/desktop-niri.nix          # niri + greetd/tuigreet + fonts (system bits)
  home/danielh.nix                  # Home Manager user config
  docs/specs/                       # this design doc
```

`hardware-configuration.nix` is host-specific and generated in the VM; it is committed under `hosts/nixos-vm/` so the flake is self-contained. Bare metal later = a new `hosts/<name>/` dir.

## What's in the minimal config

### System (`configuration.nix` + `modules/desktop-niri.nix`)
- Boot: systemd-boot, UEFI.
- `nix.settings.experimental-features = [ "nix-command" "flakes" ]`.
- Networking: hostname `nixos-vm`, NetworkManager or default DHCP.
- User `danielh`, shell zsh, in `wheel` (sudo).
- `programs.niri.enable = true` with `programs.niri.package = niri-flake`'s nightly package.
- greetd with tuigreet as the greeter, launching a niri session.
- PipeWire audio.
- `services.qemuGuest.enable` + `services.spice-vdagentd.enable`.
- Fonts: a Nerd Font (for waybar/starship glyphs).
- System packages: `git`, `neovim` (bootstrap only).

### Home Manager (`home/danielh.nix`)
- **Shell:** `programs.zsh` (with autosuggestions + syntax-highlighting), `programs.starship`, `programs.atuin` — native HM, replacing zinit.
- **Terminal:** ghostty.
- **Launcher:** fuzzel.
- **Bar:** waybar (minimal: workspaces, clock, tray/battery).
- **Notifications:** mako.
- **Tools:** tmux, git.
- **niri:** `config.kdl` with keybinds — `Mod+Return` → ghostty, `Mod+D` → fuzzel, plus basic window/workspace navigation and quit.

## Safety / rollback

- virt-manager snapshots before risky rebuilds.
- NixOS generations give bootloader-level rollback inside the VM.
- Per-host `hardware-configuration.nix` keeps the future bare-metal host cleanly separated.

## Verification (session 1 done-criteria)

Boot into niri via tuigreet; `Mod+Return` opens ghostty; `Mod+D` opens fuzzel; waybar visible; clipboard + window auto-resize work (spice agent); `sudo nixos-rebuild switch --flake .#nixos-vm` succeeds from inside the VM.
