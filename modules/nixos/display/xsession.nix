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
  options.modules.display.desktop.xsession = {
    enable = lib.mkEnableOption "Enable X session for legacy applications";
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
      description = "List of video drivers to use with the X session.";
    };
    layout = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "Default keyboard layout for X sessions.";
    };
    xkbOptions = lib.mkOption {
      type = lib.types.str;
      default = "terminate:ctrl_alt_bksp";
      description = "XKB options (e.g., to enable Ctrl+Alt+Backspace to terminate the X server).";
    };
  };

  config = lib.mkIf cfg.xsession.enable {
    # Enable the X server service (this is the built-in module)
    services.xserver = {
      enable = true;
      videoDrivers = cfg.xsession.videoDrivers;
      layout = cfg.xsession.layout;
      xkbOptions = cfg.xsession.xkbOptions;
      # Add additional settings as needed.
    };

    # If i3 is selected, you might want to ensure i3 is in the environment.
    # This example assumes that when using i3, you'll run it directly.
    environment.systemPackages = lib.mkIf (cfg.xsession.windowManager == "i3") [
      pkgs.i3
    ];
  };
}
