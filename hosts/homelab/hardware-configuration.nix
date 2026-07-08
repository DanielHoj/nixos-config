{ config, lib, pkgs, modulesPath, ... }:
# Placeholder for the ThinkCentre M75q Gen 2 (AMD Ryzen 5 Pro 5650GE, Cezanne).
# Filesystems are NOT declared here — they come from ./disko.nix.
#
# ⚠ REGENERATE at install (the box isn't here yet):
#     nixos-generate-config --no-filesystems --root /mnt --show-hardware-config \
#       > hosts/homelab/hardware-configuration.nix
#   The values below are the standard AMD/NVMe set so the flake evaluates now.
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;
}
