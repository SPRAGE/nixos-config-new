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
    ./sway.nix
  ];

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      grimblast
      wl-clipboard
      wlsunset
      swaylock
    ];

    services.cliphist.enable = true;

    wayland.windowManager.sway = {
      enable = true;
    };

    programs.swaylock = {
      enable = true;
      settings = {
        show-failed-attempts = true;
        # other settings
      };
    };
  };
}
