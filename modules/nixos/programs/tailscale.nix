{ pkgs, config, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption;
in {
  options.modules.programs.tailscale = {
    enable = mkEnableOption "Enable tailscale";
  };

  config = mkIf config.modules.programs.tailscale.enable {
    # Install the tailscale package
    services.tailscale.enable = true;
  };
}
