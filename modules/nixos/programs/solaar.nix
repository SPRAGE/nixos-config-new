{ pkgs, config, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption;
in {
  options.modules.programs.solaar = {
    enable = mkEnableOption "Enable solaar";
  };

  config = mkIf config.modules.programs.csolaar.enable {
    # Install the solaar package
    environment.systemPackages = [ pkgs.solaar ];
  };
}
