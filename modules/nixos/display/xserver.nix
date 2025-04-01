{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.display.desktop;
in
{
  config = lib.mkIf cfg.i3.enable {
    services.xserver = {
      enable = true;
      displayManager.startx.enable = true;
      windowManager.i3.enable = true;

      xkb.layout = "us";
    };

    environment.systemPackages = with pkgs; [
      i3
      i3status
      dmenu
      feh
      picom
      xclip
      xorg.xinit
    ];

    environment.sessionVariables = {
      XDG_SESSION_DESKTOP = "i3";
    };
  };
}
