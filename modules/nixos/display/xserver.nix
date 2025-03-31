{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.display.desktop;
in
{
  options.modules.display.desktop.xserver = {
    enable = lib.mkEnableOption "Enable X server for legacy applications";
    windowManager = lib.mkOption {
      type = lib.types.enum [
        "i3"
        "none"
      ];
      default = "i3";
      description = "Which X window manager to use for X sessions. Choose 'i3' for a tiling WM or 'none' for a plain X session.";
    };
    videoDrivers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "modesetting" ];
      description = "List of video drivers to use with the X server.";
    };
    layout = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "Default keyboard layout for X server sessions.";
    };
    xkbOptions = lib.mkOption {
      type = lib.types.str;
      default = "terminate:ctrl_alt_bksp";
      description = "XKB options (e.g., to enable Ctrl+Alt+Backspace to terminate the X server).";
    };
  };

  config = lib.mkIf cfg.xserver.enable {
    services.xserver = {
      enable = true;
      inherit (cfg.xerver) videoDrivers;
      inherit (cfg.xerver) layout;
      inherit (cfg.xerver) xkbOptions;
    };

    # If i3 is selected as the window manager, add it to the startup command.
    environment.variables = lib.mkIf (cfg.xserver.windowManager == "i3") {
      # Ensure the i3 package is available in your environment.
      PATH = lib.mkForce (pkgs.i3.withPackages (ps: with ps; [ ])) + ":" + lib.getEnv "PATH";
    };
  };
}
