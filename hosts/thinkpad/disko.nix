# Declarative partitioning for the internal NVMe (nix-community/disko).
# Full wipe: GPT with a 1 GiB EFI System Partition + ext4 root (no swap
# partition — zramSwap handles swap, see modules/common.nix).
#
# ⚠ `device` MUST match the install target. On the T14 the internal disk is
#   /dev/nvme0n1; confirm with `lsblk` from the live USB before running disko.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
