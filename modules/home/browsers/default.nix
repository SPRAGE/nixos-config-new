{ config, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.browsers;
in
{
  imports = [ ./firefox ];

  options.modules.browsers = {
    enable = mkEnableOption "Enable browser configuration";

    firefox.enable = mkEnableOption "Enable Firefox browser";
  };

  config = mkIf cfg.enable {
    # Optional: shared config for all browsers
  };
}
