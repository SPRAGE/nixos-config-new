{ lib, config, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.modules.display.desktop;
in
{
  imports = [
    ./login
    ./graphical.nix
    ./monitors.nix
    ./wayland.nix
    ./xsession-custom.nix # Import our custom X session module.
  ];

  options.modules.display.desktop = {
    enable = mkEnableOption "Enable graphical desktop environment";

    windowManager = mkOption {
      type = types.enum [
        "hyprland"
        "sway"
      ];
      default = "hyprland";
      description = "Which Wayland window manager to use.";
    };

    isWayland = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable Wayland-specific modules.";
    };

    hyprland.enable = mkEnableOption "Enable Hyprland window manager";
    sway.enable = mkEnableOption "Enable Sway window manager";

    xsessionCustom.enable = mkEnableOption "Enable custom X session for legacy applications";

    command = mkOption {
      type = types.str;
      default =
        if cfg.sway.enable then
          "sway"
        else if cfg.hyprland.enable then
          "uwsm start hyprland-uwsm.desktop"
        else if cfg.xsessionCustom.enable then
          if cfg.xsessionCustom.windowManager == "i3" then "i3" else "startx"
        else
          "sh -c 'echo No WM enabled >&2; sleep 5'";
      description = "Startup command for the selected session: Wayland or X session.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.hyprland.enable && cfg.sway.enable);
        message = "Only one window manager can be enabled at a time: either Hyprland or Sway, not both.";
      }
    ];
  };
}
