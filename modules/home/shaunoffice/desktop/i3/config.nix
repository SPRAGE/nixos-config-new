{
  config,
  lib,
  pkgs,
  ...
}:

{
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      # Minimal configuration; tweak to match Hyprland style
      modifier = "Mod4";
      terminal = "kitty";
      focus.followMouse = true;
      bars = [
        {
          position = "top";
          statusCommand = "i3status";
        }
      ];
    };
  };
}
