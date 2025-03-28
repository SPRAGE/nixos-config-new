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
      command = "swaymsg seat * hide_cursor 5000";
      always = true;
    }
    {
      command = "swaymsg seat * cursor ${pointer.name} ${toString pointer.size}";
    }
    {
      command = "wl-paste --watch cliphist store";
    }
    {
      command = "${getExe pkgs.wlsunset} -l 32.7 -L -96.9";
    }
  ];
}
