{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    optionalString
    ;
  cfg = config.modules.services.historical-data-updater;
in
{
  options.modules.services.historical-data-updater = {
    enable = mkEnableOption "Enable the historical-data-updater as a scheduled user service";

    package = mkOption {
      type = types.package;
      description = "The historical-data-updater package to run.";
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional TOML config file for historical-data-updater.";
    };

    rustLogLevel = mkOption {
      type = types.str;
      default = "warn";
      description = "The log level for the RUST_LOG environment variable.";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.historical-data-updater = {
      Unit = {
        Description = "User-space historical data updater";
        After = [ "network.target" ];
      };

      Service = {
        ExecStart = lib.concatStringsSep " " (
          [ "${cfg.package}/bin/historical-data-updater" ]
          ++ lib.optionals (cfg.configFile != null) [
            "--config"
            "${cfg.configFile}"
          ]
        );
        Restart = "on-failure";
        Environment = [
          "LD_LIBRARY_PATH=${pkgs.openssl.out}/lib"
          "RUST_LOG=${cfg.rustLogLevel}"
        ];
      };

      # Install = {
      #   WantedBy = [ "default.target" "multi-user.target" ];
      # };
    };

    systemd.user.timers.historical-data-updater = {
      Unit = {
        Description = "Run historical data updater at 00:00 Tue-Sat";
      };

      Timer = {
        OnCalendar = "Tue..Sat 00:00";
        Persistent = true; # ensures missed runs are triggered on boot
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
