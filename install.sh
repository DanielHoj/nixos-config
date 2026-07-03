#!/usr/bin/env bash
# One-shot NixOS installer for the eval VM.
# DESTRUCTIVE: wipes /dev/vda. Intended to run from the NixOS minimal ISO
# inside the VM only. Usage (as root):  curl -L <raw-url>/install.sh | sudo bash
set -euo pipefail

DISK="${DISK:-/dev/vda}"
REPO="${REPO:-https://github.com/DanielHoj/nixos-config}"
FLAKE_HOST="${FLAKE_HOST:-nixos-vm}"

# Flakes must be enabled for nixos-install to evaluate the flake.
export NIX_CONFIG="experimental-features = nix-command flakes"

echo ">>> Target disk: $DISK"
lsblk "$DISK"
echo ">>> This will ERASE $DISK. Continuing in 5s (Ctrl-C to abort)..."
sleep 5

echo ">>> Cleaning up any previous run (unmount/swapoff if present)"
swapoff -a 2>/dev/null || true
umount -R /mnt 2>/dev/null || true

echo ">>> Partitioning (UEFI GPT: 512MiB ESP + rest root)"
parted --script "$DISK" -- mklabel gpt
parted --script "$DISK" -- mkpart ESP fat32 1MiB 513MiB
parted --script "$DISK" -- set 1 esp on
parted --script "$DISK" -- mkpart primary 513MiB 100%
partprobe "$DISK" || true
udevadm settle

echo ">>> Formatting"
mkfs.fat -F32 -n BOOT "${DISK}1"
mkfs.ext4 -F -L nixos "${DISK}2"
udevadm settle

echo ">>> Mounting"
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/BOOT /mnt/boot

echo ">>> Generating hardware-configuration.nix"
nixos-generate-config --root /mnt

echo ">>> Cloning flake: $REPO"
rm -rf /mnt/etc/nixos-config
nix-shell -p git --run "git clone --depth 1 $REPO /mnt/etc/nixos-config"

echo ">>> Injecting generated hardware config into the flake host"
cp /mnt/etc/nixos/hardware-configuration.nix \
   "/mnt/etc/nixos-config/hosts/${FLAKE_HOST}/hardware-configuration.nix"

# Flakes only see git-tracked files: stage the generated hardware config so
# `nixos-install --flake` can find it (otherwise: "path ... does not exist").
echo ">>> Staging files so the flake sees the new hardware config"
nix-shell -p git --run "git -C /mnt/etc/nixos-config add -A"

echo ">>> Installing NixOS (first build fetches niri nightly + all packages; be patient)"
nixos-install --flake "/mnt/etc/nixos-config#${FLAKE_HOST}" --no-root-passwd

echo
echo ">>> DONE. User 'danielh' initial password is 'nixos' (change it after first login)."
echo ">>> Now run:  reboot"
