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
    ./binds.nix
    ./config.nix
    ./startup.nix
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

    # no sway-specific modules needed here
  };
}
