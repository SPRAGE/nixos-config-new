{ osConfig, ... }:

{
  wayland.windowManager.sway.config = {
    modifier = "Mod4";
    floating_modifier = "Mod4";
    focus_follows_mouse = "yes";
    gaps = {
      inner = 5;
      outer = 5;
    };
    input = {
      "type:touchpad" = {
        tap = "enabled";
        natural_scroll = "enabled";
      };
    };

    output = {
      "*" = {
        bg = "${osConfig.wallpaper or "/etc/sway/bg.png"} fill";
      };
    };

    # Sway does not support Hyprland-specific features like layerrule, windowrulev2, animations, etc.
  };
}
