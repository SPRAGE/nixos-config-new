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
      # services.nextcloud-client.enable = mkDefault true;
      theme.stylix.enable = mkDefault true;
      programs.remmina = {
        enable = true;
        overwrite = true;
        # connectionFilesDir = ./remmina-connections;

        showToolbar = false;
        tabMode = 3;
        groupByGroup = false;
        hideToolbar = true;
        darkTheme = true;
        saveViewMode = true;
        confirmClose = true;
      };
      # programs.spicetify.enable = mkDefault true;
      # programs.index-frontend.enable = mkDefault true;
    };
  };
}
