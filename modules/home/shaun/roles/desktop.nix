{
  osConfig,
  lib,
  inputs,
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
      programs.index-frontend.enable = mkDefault true;

    services.solaar = {
      enable = true;
      # package = inputs.solaar.packages.${pkgs.system}.default;
      window = "hide";
      batteryIcons = "regular";
      extraArgs = "";
    };
    };
  };
}
