{
  osConfig,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  cfg = osConfig.modules.roles.server;
in
{
  config = mkIf cfg.enable {
    modules = {
    };
  };
}
