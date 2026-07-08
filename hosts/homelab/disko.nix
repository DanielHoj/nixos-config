# Declarative partitioning for the homelab node.
#  - Internal NVMe  → boot: 1 GiB ESP + ext4 root (the NixOS host itself).
#  - Added disk     → whole-disk ZFS pool `tank` for Incus VM storage + snapshots.
#
# ⚠ The box + extra disk aren't here yet — CONFIRM device paths with `lsblk`
#   from the live USB before running disko. The added disk is assumed to be a
#   2.5" SATA SSD (/dev/sda); if you use a second NVMe instead, change `device`.
{
  disko.devices = {
    disk = {
      # OS disk — internal NVMe.
      os = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = { type = "filesystem"; format = "vfat"; mountpoint = "/boot"; mountOptions = [ "umask=0077" ]; };
            };
            root = {
              size = "100%";
              content = { type = "filesystem"; format = "ext4"; mountpoint = "/"; };
            };
          };
        };
      };
      # Data disk — the added SSD, given entirely to the ZFS pool `tank`.
      data = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions.zfs = { size = "100%"; content = { type = "zfs"; pool = "tank"; }; };
        };
      };
    };

    zpool.tank = {
      type = "zpool";
      rootFsOptions = {
        compression = "zstd";
        "com.sun:auto-snapshot" = "false";
        acltype = "posixacl";
        xattr = "sa";
      };
      # Incus points its storage pool at `tank/incus` (see modules/incus.nix).
      datasets.incus = {
        type = "zfs_fs";
        options.mountpoint = "none";
      };
    };
  };
}
