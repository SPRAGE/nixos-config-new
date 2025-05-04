# modules/display/windowManager/sway/startup.nix
{ config, pkgs, lib, ... }:

let
  # reuse your home‐pointerCursor setting
  pointer = config.home.pointerCursor;
  getExe = lib.getExe;
in
{
  config = lib.mkIf config.services.wayland.windowManager.sway.enable {
    services.wayland.windowManager.sway.extraConfig = lib.concatStringsSep "\n" [
      # set cursor theme/size
      "seat * xcursor ${pointer.name} ${toString pointer.size}"
      # cliphist watcher
      "exec --no-startup-id wl-paste --watch cliphist store"
      # redshift/sunset
      "exec --no-startup-id ${getExe pkgs.wlsunset} -l 32.7 -L -96.9"
      # jump to WS 1 on startup
      "exec --no-startup-id swaymsg workspace 1"
    ];
  };
}
