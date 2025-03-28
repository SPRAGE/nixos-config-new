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
  ];

  options.modules.display.desktop = {
    enable = mkEnableOption "Enable graphical desktop environment";

    command = mkOption {
      type = types.str;
      default = mkDefault "uwsm start hyprland-uwsm.desktop";
      description = "Startup command for the selected window manager";
    };

    isWayland = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable Wayland-specific features";
    };

    hyprland.enable = mkEnableOption "Enable Hyprland window manager";
    sway.enable = mkEnableOption "Enable Sway window manager";
  };

  config = mkIf cfg.enable {
    # Automatically set the command based on which WM is enabled
    modules.display.desktop.command = mkDefault (
      if cfg.sway.enable then
        "sway"
      else if cfg.hyprland.enable then
        "uwsm start hyprland-uwsm.desktop"
      else
        "sh -c 'echo No WM enabled >&2; sleep 5'"
    );
  };
}
