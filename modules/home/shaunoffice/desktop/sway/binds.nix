{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:

{
  wayland.windowManager.sway.config = {
    keybindings = [
      # Workspace switching
      "bindsym $mod+1 workspace number 1"
      "bindsym $mod+2 workspace number 2"
      # Add more as needed...

      # Applications
      "bindsym $mod+Return exec ${pkgs.kitty}/bin/kitty"
      "bindsym $mod+E exec ${pkgs.kitty}/bin/kitty -e yazi"
      "bindsym Ctrl+Shift+Escape exec ${pkgs.kitty}/bin/kitty -e btop"

      # Rofi launcher
      "bindsym $mod+D exec rofi -show drun"
      "bindsym $mod+V exec ${pkgs.cliphist}/bin/cliphist list | rofi -dmenu | ${pkgs.cliphist}/bin/cliphist decode | wl-copy"

      # Power and lock
      "bindsym $mod+L exec swaylock"
      "bindsym XF86PowerOff exec systemctl poweroff"

      # Screenshot
      "bindsym Print exec ${pkgs.grimblast}/bin/grimblast --notify copysave area"

      # Media keys
      "bindsym XF86AudioPlay exec ${pkgs.playerctl}/bin/playerctl play-pause"
      "bindsym XF86AudioNext exec ${pkgs.playerctl}/bin/playerctl next"
      "bindsym XF86AudioPrev exec ${pkgs.playerctl}/bin/playerctl previous"
      "bindsym XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      "bindsym XF86AudioMicMute exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

      # Volume
      "bindsym XF86AudioRaiseVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      "bindsym XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
    ];
  };
}
