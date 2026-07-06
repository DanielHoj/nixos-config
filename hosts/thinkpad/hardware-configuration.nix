{ config, lib, pkgs, modulesPath, ... }:
# Hardware profile for the T14 Gen 2i (Tiger Lake, NVMe). Filesystems are NOT
# declared here — they come from ./disko.nix.
#
# ⚠ REGENERATE at install to capture exact modules for this machine:
#     nixos-generate-config --no-filesystems --root /mnt --show-hardware-config \
#       > hosts/thinkpad/hardware-configuration.nix
#   The values below are the standard Tiger Lake set so the flake evaluates now.
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
