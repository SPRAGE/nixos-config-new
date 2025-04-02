{
  osConfig,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  cfg = osConfig.modules.roles.development;
in
{
  config = mkIf cfg.enable {
    editors.windsurf.enable = true;
    # modules.shell.zellij.enable = mkDefault true;
  };
}
