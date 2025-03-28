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

  config = mkIf cfg.i3.enable {
    home.packages = with pkgs; [
      i3
      dmenu
      rofi
      i3status
      i3lock
      picom
      xclip
      xterm
    ];

    xsession.windowManager.i3.enable = true;

    services.cliphist.enable = true;

    modules.desktop = {
      i3lock.enable = mkDefault true;
    };
  };
}
