# modules/display/windowManager/sway/binds.nix
{ pkgs, config, lib, ... }:

let
  # generate workspace bindings 1..10
  workspaces = lib.concatLists (
    lib.genList (i:
      let n = toString (i + 1); in
      [ "bindsym \$mod+${n} workspace ${n}"
        "bindsym \$mod+Shift+${n} move container to workspace ${n}"
      ]) 10);

  # some window‐focus / layout / reload keys
  binds = [
    "bindsym \$mod+Shift+r reload"
    "bindsym \$mod+Return exec ${pkgs.kitty}/bin/kitty"
    "bindsym \$mod+d exec rofi -show drun"
    "bindsym \$mod+v exec cliphist li —display-columns 2 | cliphist decode | wl-copy"
    "bindsym \$mod+l exec swaylock"
  ];

  # multimedia / hardware keys
  media = [
    "bindsym XF86AudioRaiseVolume exec pamixer --increase 5; wl-paste"
    "bindsym XF86AudioLowerVolume exec pamixer --decrease 5; wl-paste"
    "bindsym XF86AudioMute       exec pamixer --toggle-mute"
    "bindsym XF86AudioMicMute    exec pamixer --toggle-mic"
    "bindsym XF86AudioNext       exec playerctl next"
    "bindsym XF86AudioPrev       exec playerctl previous"
  ];
in
{
  config = lib.mkIf config.services.wayland.windowManager.sway.enable {
    services.wayland.windowManager.sway.extraConfig = lib.concatStringsSep "\n" [
      lib.concatStringsSep "\n" workspaces
      lib.concatStringsSep "\n" binds
      lib.concatStringsSep "\n" media
    ];
  };
}
