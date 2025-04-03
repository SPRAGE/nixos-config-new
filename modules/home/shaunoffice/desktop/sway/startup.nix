{
  config,
  pkgs,
  lib,
  ...
}:

let
  pointer = config.home.pointerCursor;
  inherit (lib) getExe;
in
{
  wayland.windowManager.sway.config.startup = [
    {
      command = "swaymsg seat * cursor set ${pointer.name} ${toString pointer.size}";
      always = true;
    }
    {
      command = "wl-paste --watch cliphist store";
      always = true;
    }
    {
      command = "${getExe pkgs.wlsunset} -l 32.7 -L -96.9";
      always = true;
    }
    {
      command = "swaymsg workspace 1";
      always = true;
    }
  ];
}
