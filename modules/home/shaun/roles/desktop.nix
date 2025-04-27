{
  osConfig,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  cfg = osConfig.modules.roles.desktop;
in
{
  config = mkIf cfg.enable {
    modules = {
      theme.stylix.enable = mkDefault true;
      # programs.spicetify.enable = mkDefault true;
      # programs.index-frontend.enable = mkDefault true;
    };
  };
}
