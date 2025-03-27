{
  pkgs,
  lib,
  osConfig,
  ...
}:

let
  inherit (lib) mkIf mkDefault;
  cfg = osConfig.modules.display.desktop;
in
{
  imports = [
    ./config.nix
  ];

  config = mkIf cfg.sway.enable {
    home.packages = with pkgs; [
      grimblast
      wl-clipboard
      wlsunset
    ];

    services.cliphist.enable = true;

    wayland.windowManager.sway = {
      enable = true;
    };

    # Optional module settings
    modules = {
      desktop = {
        swaylock.enable = mkDefault true;
      };
    };
  };
}
