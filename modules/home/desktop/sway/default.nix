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

    wayland.windowManager.sway = {
      enable = true;
      systemd.enable = false;
    };

    services.cliphist.enable = true;

    modules.desktop = {
      swayidle.enable = mkDefault false;
      swaylock.enable = mkDefault true;
    };
  };
}
