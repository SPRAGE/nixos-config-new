{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    optionalString
    ;

  cfg = config.modules.services.ingestion-server;
in
{
  options.modules.services.ingestion-server = {
    enable = mkEnableOption "Enable the ingestion server as a user service";

    package = mkOption {
      type = types.package;
      description = "The ingestion-server package to run.";
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional path to the TOML config file used by ingestion-server.";
    };

    rustLogLevel = mkOption {
      type = types.str;
      default = "warn";
      description = "The log level for the RUST_LOG environment variable (e.g., debug, info, warn, error).";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.ingestion-server = {
      Unit = {
        Description = "User-space ingestion-server";
        After = [ "network.target" ];
      };

      Service = {
        ExecStart = lib.concatStringsSep " " (
          [ "${cfg.package}/bin/ingestion-server" ]
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

      Install = {
        WantedBy = [ "multi-user.target" ];
      };
    };
  };
}
