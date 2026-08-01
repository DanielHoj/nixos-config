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
- `~/.config/sops/age/keys.txt` — **the sops admin age key (critical)**. This is
  the master key for editing every secret in the repo. If it's lost you can't
  edit secrets anymore. Also store a copy in Proton Pass. (It lives on THIS
  machine right now and gets wiped otherwise.)
- `~/.gnupg/` — GPG keys (if used)
- **Local dev state not in git** — check for anything you care about:
  - Postgres: `pg_dumpall > ~/pgdump.sql` if any local DB has data worth keeping.
  - Docker: `docker volume ls` — back up any volume with real data (images/
    containers themselves are disposable; volumes aren't).
- Personal files: `~/Documents`, `~/Pictures`, `~/Downloads`, Obsidian vault, etc.
- Shell history (optional): `~/.local/share/atuin/` if you want it carried over.
- Any other app data/config not covered by dotfiles (`~/.local/share`, `~/.config/*`).
- Browser: bookmarks/passwords are in **Proton Pass (cloud)**; export anything
  else you want (Zen bookmarks/open tabs) — Zen starts fresh otherwise.

⚠ If a cleartext secrets file is still lying around (e.g. an old
`~/passwords.csv` Firefox export), **`shred -u` it** — don't copy it into the
backup. Passwords live in Proton Pass.

Verify the backup is readable on another device **before** wiping.

---

## Phase 3 — Install (from a NixOS live USB)

### 3.1 Make the USB (on another machine, or this one before wiping)
Download the **NixOS 26.05 minimal (or graphical) x86_64 ISO** from nixos.org.

**Verify it** against the checksum on the download page — a corrupt ISO means a
failed install on a machine that no longer has a fallback OS:
```sh
sha256sum nixos-*-26.05-x86_64-linux.iso   # must match the SHA256 shown on nixos.org
```

**Identify the USB stick — NOT the internal NVMe.** Writing to the wrong device
is unrecoverable, so confirm before you `dd`:
```sh
lsblk -o NAME,SIZE,TYPE,TRAN,MODEL,MOUNTPOINTS   # USB = TRAN:usb + matches the stick's size
```
Then write it, replacing `sdX` with the **confirmed** USB device (e.g. `sdb`) —
never `nvme0n1`:
```sh
sudo dd if=nixos-*-26.05-x86_64-linux.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

### 3.2 BIOS prep
Reboot → Enter (F1) BIOS →
- **Config → Power → Sleep State = Linux** (suspend-to-RAM on this ThinkPad).
- **Security → Secure Boot = Disabled.** systemd-boot without lanzaboote won't
  boot with Secure Boot on — the install would succeed but the machine wouldn't
  boot. (EndeavourOS likely already had it off, but confirm.)

Boot the USB (F12 boot menu).

### 3.3 Network on the live system
- **Ethernet (simplest):** plug in — it just works.
- **WiFi (graphical ISO):** `nmtui` → connect to your SSID.
- **WiFi (minimal ISO):** find the wireless interface first — with predictable
  naming it's likely `wlp0s20f3`, not `wlan0`:
  ```sh
  iw dev || ip -br link          # note the wireless iface name
  IFACE=wlp0s20f3                # ← set to what the command above showed
  sudo wpa_passphrase "SSID" "PASSWORD" | sudo tee /etc/wpa_supplicant.conf
  sudo wpa_supplicant -B -i "$IFACE" -c /etc/wpa_supplicant.conf
  ```
  Verify: `ping -c1 nixos.org`.

### 3.4 Clone the config + confirm the target disk
```sh
nix-shell -p git --run 'git clone https://github.com/DanielHoj/nixos-config /tmp/nixos-config'
lsblk    # CONFIRM the internal disk is /dev/nvme0n1 (matches hosts/thinkpad/disko.nix)
```

### 3.5 Partition + format + mount with disko (**destroys nvme0n1**)
Run the **disko revision pinned in the repo's `flake.lock`**, not `/latest` —
`latest` can drift from the version you tested on the VM between now and install:
```sh
DISKO_REV=$(nix-shell -p jq --run "jq -r '.nodes.disko.locked.rev' /tmp/nixos-config/flake.lock")
sudo nix --experimental-features "nix-command flakes" run "github:nix-community/disko/$DISKO_REV" -- \
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
git -C /tmp/nixos-config add hosts/thinkpad/hardware-configuration.nix  # so the (dirty) flake picks it up
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
2. Network: `nmtui` (NetworkManager is enabled) → **Activate a connection** →
   select **`Zyxel_9D81`** → enter the Wi-Fi password (WPA3; it's in Proton Pass
   / on the router). You only do this once — NetworkManager saves it and
   auto-reconnects on every boot thereafter. (Or use Ethernet, which just works.)
3. Restore keys/data from backup:
   ```sh
   # ~/.ssh from backup, then:
   chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_*
   # sops admin age key (so you can edit secrets from this machine):
   mkdir -p ~/.config/sops/age && cp <backup>/keys.txt ~/.config/sops/age/keys.txt
   chmod 600 ~/.config/sops/age/keys.txt
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
8. **Tailscale** — enrol this laptop on the tailnet (interactive host, no auth
   key): `sudo tailscale up --ssh`. (It won't auto-enrol; that's homelab-only.)
9. **Fingerprint** (optional): `fprintd-enroll`, then `sudo -k; sudo true` should
   prompt for a finger (password still works as fallback). No manual PAM editing
   needed — on NixOS `services.fprintd.enable` auto-wires fingerprint into the
   sudo + login PAM stacks (`security.pam.services.*.fprintAuth`). **Caveat:**
   libfprint doesn't support every ThinkPad reader; if `fprintd-enroll` can't
   find the device, this unit's reader just isn't supported — skip it, nothing
   depends on it.
10. **pi ecosystem plugins** (npm-global, not in Nix — re-install imperatively):
    ```sh
    npm i -g pi-vim pi-subagents pi-memory pi-mcp-adapter pi-observational-memory
    ```
11. Restore local dev state if you backed it up: `psql -d danielh < ~/pgdump.sql`,
    Docker volumes, etc.

> **sops on the T14:** by design this host decrypts *nothing* at activation (it
> declares no secrets — that's why the install doesn't need the T14 to be a
> `.sops.yaml` recipient). If you later want it to hold a secret, derive its key
> (`ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`), add it under `keys:` in
> `.sops.yaml`, `sops updatekeys secrets/secrets.yaml`, then declare the secret.

### Post-install validation checklist
- [ ] niri session starts (greetd → tuigreet → niri), waybar visible
- [ ] WiFi (AX201) + Bluetooth work
- [ ] Audio (PipeWire) — `pavucontrol`
- [ ] Brightness keys (`brightnessctl` / swayosd), volume keys
- [ ] Suspend/resume (lid close) — needs the BIOS Sleep State = Linux from 3.2
- [ ] Intel GPU accel — `nix-shell -p libva-utils --run vainfo`
- [ ] Trackpoint/touchpad, keyd remaps (Caps→Esc/Super), compose key (æøå)
- [ ] `nixos-rebuild switch` from `~/nixos-config` succeeds
- [ ] Git over SSH works (key restored) — `git -C ~/nixos-config pull`
- [ ] Tailscale enrolled — `tailscale status` lists the tailnet

### If first boot fails
The NixOS boot menu keeps older generations, but this is a fresh install (one
generation). Re-boot the USB, `disko`-mount, `nixos-install` again after fixing.
Keep the EndeavourOS backup until the new system is proven.
