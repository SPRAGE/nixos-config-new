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

      # Add libinput configuration for input devices
      inputClassSections = [
        {
          identifier = "libinput pointer catchall";
          matchIsPointer = true;
          driver = "libinput";
        }
        {
          identifier = "libinput keyboard catchall";
          matchIsKeyboard = true;
          driver = "libinput";
        }
        {
          identifier = "libinput touchpad catchall";
          matchIsTouchpad = true;
          driver = "libinput";
          option.Tapping = "on";
        }
      ];
    };

    environment.systemPackages = with pkgs; [
      i3
      i3status
      dmenu
      feh
      picom
      xclip
      xorg.xinit
      xorg.libinput # Add libinput package
    ];

    environment.sessionVariables = {
      XDG_SESSION_DESKTOP = "i3";
    };
  };
}
