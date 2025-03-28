{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.shaun.graphical.x;
in
{
  options.shaun.graphical.x = {
    enable = lib.mkEnableOption "X11 graphical session with i3 window manager";
  };

  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      windowManager.i3.enable = true;
      displayManager.lightdm.enable = true;
      displayManager.defaultSession = "none+i3";
    };

    environment.systemPackages = with pkgs; [
      i3
      dmenu
      rofi
      i3status
      i3lock
      picom
      xterm
      xclip
      xorg.xrandr
      xorg.xset
      xdotool
    ];

    programs.dconf.enable = true;
  };
}
