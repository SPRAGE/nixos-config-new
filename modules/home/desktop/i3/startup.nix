{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) getExe;
  pointer = config.home.pointerCursor;
in
{
  xsession.windowManager.i3.config.startup = [
    {
      command = "xsetroot -cursor_name ${pointer.name}";
    }
    {
      command = "cliphist store &";
    }
    {
      command = "${getExe pkgs.wlsunset} -l 32.7 -L -96.9";
    }
    {
      command = "i3-msg workspace 1";
    }
  ];
}
