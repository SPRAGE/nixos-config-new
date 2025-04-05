{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
in
{
  options.modules.programs.ntfs-3g = {
    enable = mkEnableOption "Enable NTFS-3G for mounting NTFS drives";
  };

  config = mkIf config.modules.programs.ntfs-3g.enable {
    environment.systemPackages = with pkgs; [ ntfs3g ];

    # Optional: Add any additional configuration for NTFS-3G here
    # For example, you could define default mount options or services
  };
}