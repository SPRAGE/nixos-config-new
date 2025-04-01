{ lib, config, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkDefault
    mkIf
    types
    ;
  id = x: x;

  cfg = config.modules.display.desktop;
in
{
  imports = [
    ./login
    ./graphical.nix
    ./monitors.nix
    ./wayland.nix
    ./xserver.nix # 👈 Add this
  ];

  options.modules.display.desktop = {
    enable = mkEnableOption "Enable graphical desktop environment";

    windowManager = mkOption {
      type = types.enum [
        "hyprland"
        "sway"
        "i3"
      ];
      default = "hyprland";
      description = "Which window manager to use.";
    };

    isWayland = mkOption {
      type = types.bool;
      default = cfg.windowManager != "i3";
      description = "Whether to enable Wayland-specific modules.";
    };

    hyprland.enable = mkEnableOption "Enable Hyprland window manager";
    sway.enable = mkEnableOption "Enable Sway window manager";
    i3.enable = mkEnableOption "Enable i3 window manager";

    command = mkOption {
      type = types.str;
      default =
        if cfg.sway.enable then
          "sway"
        else if cfg.hyprland.enable then
          "uwsm start hyprland-uwsm.desktop"
        else if cfg.i3.enable then
          "i3"
        else
          "sh -c 'echo No WM enabled >&2; sleep 5'";
      description = "Startup command for the selected window manager.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          lib.length (
            lib.filter id [
              cfg.hyprland.enable
              cfg.sway.enable
              cfg.i3.enable
            ]
          ) == 1;

        message = "Exactly one window manager must be enabled (Hyprland, Sway, or i3).";
      }
    ];
  };
}
