{
  config,
  lib,
  pkgs,
  ...
}:

{
  xsession.windowManager.i3.config.startup = [
    {
      command = "nm-applet";
      always = true;
      notification = false;
    }
    {
      command = "picom";
      always = true;
      notification = false;
    }
    {
      command = "feh --bg-scale ~/.config/wallpaper";
      always = true;
      notification = false;
    }
    # Match similar apps you start in Hyprland
  ];
}
