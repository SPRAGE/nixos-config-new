{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types;
  cfg = config.modules.services.solaar;
in
{
  options.modules.services.solaar = {
    enable = mkEnableOption "Enable Logitech Solaar service";

    package = mkOption {
      type = types.package;
      default = pkgs.solaar;
      description = "Solaar package to run (can be overridden).";
    };

    window = mkOption {
      type = types.enum [ "show" "hide" "only" ];
      default = "hide";
      description = "Whether to show the Solaar window at startup.";
    };

    batteryIcons = mkOption {
      type = types.enum [ "regular" "symbolic" "solaar" ];
      default = "regular";
      description = "Which battery icon style to use.";
    };

    extraArgs = mkOption {
      type = types.str;
      default = "";
      description = "Extra arguments to pass to Solaar.";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.solaar = {
      Unit = {
        Description = "Solaar - Logitech device manager";
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = ''
          ${cfg.package}/bin/solaar --window=${cfg.window} --battery-icons=${cfg.batteryIcons} ${cfg.extraArgs}
        '';
        Restart = "on-failure";
        Environment = "DISPLAY=:0";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
