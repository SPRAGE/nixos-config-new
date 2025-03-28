{
  pkgs,
  config,
  lib,
  ...
}:

let
  mod = "Mod4"; # SUPER
  inherit (lib) getExe;
in
{
  xsession.windowManager.i3.config.keybindings = {
    "${mod}+Return" = "exec ${getExe pkgs.kitty}";
    "${mod}+d" = "exec rofi -show drun";
    "${mod}+e" = "exec ${getExe pkgs.kitty} -e yazi";
    "Ctrl+Shift+Escape" = "exec ${getExe pkgs.kitty} -e btop";
    "${mod}+Shift+e" = "exec ${getExe pkgs.thunar}";

    "${mod}+h" = "focus left";
    "${mod}+j" = "focus down";
    "${mod}+k" = "focus up";
    "${mod}+l" = "focus right";

    "${mod}+Shift+h" = "move left";
    "${mod}+Shift+j" = "move down";
    "${mod}+Shift+k" = "move up";
    "${mod}+Shift+l" = "move right";

    "${mod}+Shift+q" = "kill";
    "${mod}+f" = "fullscreen toggle";
    "${mod}+space" = "floating toggle";
    "${mod}+l" = "exec i3lock";

    "Print" = "exec ${getExe pkgs.grimblast} --notify copysave area";

    "XF86AudioPlay" = "exec ${getExe pkgs.playerctl} play-pause";
    "XF86AudioNext" = "exec ${getExe pkgs.playerctl} next";
    "XF86AudioPrev" = "exec ${getExe pkgs.playerctl} previous";
    "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
    "XF86AudioMicMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
  };
}
