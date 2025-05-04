{ pkgs, config, lib, ... }:
let
  inherit (lib) mkIf mkEnableOption;
in {
  options.modules.programs.corectrl = {
    enable = mkEnableOption "Enable CoreCtrl";
  };

  config = mkIf config.modules.programs.corectrl.enable {
    # Install the CoreCtrl package
    environment.systemPackages = [ pkgs.corectrl ];
  };
}
