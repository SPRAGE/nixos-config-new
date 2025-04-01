{
  config,
  lib,
  pkgs,
  ...
}:

{
  xsession.windowManager.i3.config.keybindings = {
    "Mod4+Return" = "exec alacritty";
    "Mod4+d" = "exec rofi -show drun";
    "Mod4+Shift+q" = "kill";
    "Mod4+Shift+r" = "restart";
    "Mod4+f" = "fullscreen toggle";
    # Add more keybindings as desired
  };
}
