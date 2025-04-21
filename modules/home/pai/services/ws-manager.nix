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

  cfg = config.modules.services.ws-manager;
in
{
  options.modules.services.ws-manager = {
    enable = mkEnableOption "Enable the ws-manager as a user service";

    package = mkOption {
      type = types.package;
      description = "The package providing the ws_manager binary.";
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional path to the TOML config file used by ws_manager.";
    };

    rustLogLevel = mkOption {
      type = types.str;
      default = "warn";
      description = "The log level for the RUST_LOG environment variable.";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.ws-manager = {
      Unit = {
        Description = "User-space ws-manager service";
        After = [ "kafka.service" ]; # Wait for Kafka
        Requires = [ "kafka.service" "valkey.service" "futures-consumer"  ]; # Fail if Kafka is not available
      };

      Service = {
        ExecStart = lib.concatStringsSep " " (
          [ "${cfg.package}/bin/ws_manager" ]
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
        WantedBy = [ "default.target" ];
      };
    };
  };
}
