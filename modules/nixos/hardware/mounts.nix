{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    ;
  cfg = config.modules.hardware.mounts;
in
{
  options.modules.hardware.mounts = {
    enable = mkEnableOption "Enable custom disk mounts";

    disks = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            mountPoint = mkOption {
              type = types.str;
              description = "Where to mount the disk";
            };
            uuid = mkOption {
              type = types.str;
              description = "UUID of the disk";
            };
            fsType = mkOption {
              type = types.str;
              description = "Filesystem type (e.g. ext4, ntfs-3g)";
            };
            options = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Mount options (e.g. rw, nofail, etc.)";
            };
          };
        }
      );
      default = [ ];
      description = "List of disks to mount";
    };
  };

  config = mkIf cfg.enable {
    fileSystems = lib.mkMerge (
      map (disk: {
        "${disk.mountPoint}" = {
          device = "/dev/disk/by-uuid/${disk.uuid}";
          inherit (disk) fsType;
          inherit (disk) options;
        };
      }) cfg.disks
    );
  };
}
