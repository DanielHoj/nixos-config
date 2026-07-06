# ThinkPad T14 Gen 2i — bare-metal migration runbook

Migrate this machine from EndeavourOS to NixOS (`#thinkpad`). **Full wipe**, no
dual-boot, no encryption, single ext4 root. Phase 1 (flake) is done; this covers
Phases 2–4. Read the whole thing before starting.

> ⚠ **This wipes the internal NVMe (`/dev/nvme0n1`) completely.** There is no
> EndeavourOS fallback afterwards. Do Phase 2 first and verify the backup.

---

## Phase 2 — Backup (before touching the disk)

Already safe in GitHub (just confirm nothing uncommitted):
- `~/nixos-config` → `git -C ~/nixos-config status` (clean + pushed)
- `~/dotfiles` → `git -C ~/dotfiles status` (clean + pushed)
- Code projects → check each repo for uncommitted/unpushed work

**Copy to an external drive or another machine** (not in git):
- `~/.ssh/` — private keys (**critical**; nothing works without these)
- `~/.gnupg/` — GPG keys (if used)
- Personal files: `~/Documents`, `~/Pictures`, `~/Downloads`, Obsidian vault, etc.
- Any app data/config not covered by dotfiles (`~/.local/share`, `~/.config/*` you care about)
- Browser: bookmarks/passwords are in **Proton Pass (cloud)**; export anything else you want from the current browser

Passwords are in Proton Pass; Zen starts fresh. Verify the backup is readable on
another device **before** wiping.

---

## Phase 3 — Install (from a NixOS live USB)

### 3.1 Make the USB (on another machine, or this one before wiping)
Download the **NixOS 26.05 minimal (or graphical) x86_64 ISO** from nixos.org, then:
```sh
sudo dd if=nixos-*-26.05-x86_64-linux.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

### 3.2 BIOS prep
Reboot → Enter (F1) BIOS → **Config → Power → Sleep State = Linux** (needed for
suspend-to-RAM on this ThinkPad). Boot the USB (F12 boot menu).

### 3.3 Network on the live system
- **Ethernet (simplest):** plug in — it just works.
- **WiFi (graphical ISO):** `nmtui` → connect to your SSID.
- **WiFi (minimal ISO):**
  ```sh
  sudo wpa_passphrase "SSID" "PASSWORD" | sudo tee /etc/wpa_supplicant.conf
  sudo wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant.conf
  ```
  Verify: `ping -c1 nixos.org`.

### 3.4 Clone the config + confirm the target disk
```sh
nix-shell -p git --run 'git clone https://github.com/DanielHoj/nixos-config /tmp/nixos-config'
lsblk    # CONFIRM the internal disk is /dev/nvme0n1 (matches hosts/thinkpad/disko.nix)
```

### 3.5 Partition + format + mount with disko (**destroys nvme0n1**)
```sh
sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- \
  --mode destroy,format,mount --flake /tmp/nixos-config#thinkpad
```
This wipes the disk, creates a 1 GiB ESP + ext4 root, and mounts them at `/mnt`.
Check: `lsblk` shows `/mnt` and `/mnt/boot`.

### 3.6 Generate the REAL hardware config
The committed `hardware-configuration.nix` is a generic Tiger Lake placeholder —
replace it with the machine-accurate one (filesystems come from disko, so
`--no-filesystems`):
```sh
sudo nixos-generate-config --no-filesystems --root /mnt --show-hardware-config \
  > /tmp/nixos-config/hosts/thinkpad/hardware-configuration.nix
git -C /tmp/nixos-config add -A     # so the (dirty) flake picks it up
```

### 3.7 Install
```sh
sudo nixos-install --flake /tmp/nixos-config#thinkpad \
  --option extra-substituters https://niri.cachix.org \
  --option extra-trusted-public-keys niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=
```
Set the **root** password when prompted. Then `sudo reboot` and remove the USB.

---

## Phase 4 — First boot & restore

1. Log in as **danielh** / `changeme` → run `passwd` immediately.
2. Network: `nmtui` (NetworkManager is enabled) — connect WiFi.
3. Restore keys/data from backup:
   ```sh
   # ~/.ssh from backup, then:
   chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_*
   ```
   Restore `~/.gnupg`, personal files.
4. Clone the repos to their expected live-edit locations:
   ```sh
   git clone https://github.com/DanielHoj/dotfiles ~/dotfiles       # nvim out-of-store symlink target
   git clone git@github.com:DanielHoj/nixos-config ~/nixos-config   # for future rebuilds
   ```
5. **Commit the real hardware config** so GitHub rebuilds work:
   ```sh
   cp /tmp/nixos-config/hosts/thinkpad/hardware-configuration.nix ~/nixos-config/hosts/thinkpad/
   cd ~/nixos-config && git add -A && git commit -m "thinkpad: real hardware-configuration.nix" && git push
   ```
   (Or just re-generate on the running system: `sudo nixos-generate-config --no-filesystems --show-hardware-config`.)
6. Future rebuilds: `sudo nixos-rebuild switch --flake ~/nixos-config#thinkpad`.
7. Apps: open Zen (`Mod+B`) once to seed the profile (spaces materialize per the
   zen notes), log into Proton Pass + Proton VPN.

### Post-install validation checklist
- [ ] niri session starts (greetd → tuigreet → niri), waybar visible
- [ ] WiFi (AX201) + Bluetooth work
- [ ] Audio (PipeWire) — `pavucontrol`
- [ ] Brightness keys (`brightnessctl` / swayosd), volume keys
- [ ] Suspend/resume (lid close) — needs the BIOS Sleep State = Linux from 3.2
- [ ] Intel GPU accel — `nix-shell -p libva-utils --run vainfo`
- [ ] Trackpoint/touchpad, keyd remaps (Caps→Esc/Super), compose key (æøå)
- [ ] `nixos-rebuild switch` from `~/nixos-config` succeeds

### If first boot fails
The NixOS boot menu keeps older generations, but this is a fresh install (one
generation). Re-boot the USB, `disko`-mount, `nixos-install` again after fixing.
Keep the EndeavourOS backup until the new system is proven.
