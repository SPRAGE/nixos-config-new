{ lib, config, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkDefault
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
    ./xserver.nix
  ];

  options.modules.display.desktop = {
    enable = mkEnableOption "Enable graphical desktop environment";

    sway.enable     = mkEnableOption "Enable the Sway window manager";
    hyprland.enable = mkEnableOption "Enable the Hyprland window manager";
    i3.enable       = mkEnableOption "Enable the i3 window manager";

    defaultWindowManager = mkOption {
      type = types.enum [ "sway" "hyprland" "i3" ];
      default = "hyprland";
      description = "Which window manager to use as the default when starting a session.";
    };

    defaultWindowManagerCommand = mkOption {
      type = types.str;
      default =
        if cfg.defaultWindowManager == "sway" then
          "sway"
        else if cfg.defaultWindowManager == "hyprland" then
          "uwsm start hyprland-uwsm.desktop"
        else if cfg.defaultWindowManager == "i3" then
          "i3"
        else
          "sh -c 'echo No WM defined >&2; sleep 5'";
      description = "Startup command for the selected default window manager.";
    };

    isWayland = mkOption {
      type = types.bool;
      default = cfg.defaultWindowManager != "i3";
      description = "Whether to enable Wayland-specific configuration.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          cfg.sway.enable || cfg.hyprland.enable || cfg.i3.enable;
        message = "At least one window manager (sway, hyprland, i3) must be enabled.";
      }

      {
        assertion = (
          (cfg.defaultWindowManager == "sway"     -> cfg.sway.enable)
          && (cfg.defaultWindowManager == "hyprland" -> cfg.hyprland.enable)
          && (cfg.defaultWindowManager == "i3"     -> cfg.i3.enable)
        );
        message = "The selected defaultWindowManager must be enabled.";
      }
    ];
  };
}
