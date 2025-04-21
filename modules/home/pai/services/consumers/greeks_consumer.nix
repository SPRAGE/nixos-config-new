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

  cfg = config.modules.services.greeks-consumer;
in
{
  options.modules.services.greeks-consumer = {
    enable = mkEnableOption "Enable the greeks-consumer as a user service";

    package = mkOption {
      type = types.package;
      description = "The package providing the greeks_consumer binary.";
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional path to the TOML config file used by greeks_consumer.";
    };

    rustLogLevel = mkOption {
      type = types.str;
      default = "warn";
      description = "The log level for the RUST_LOG environment variable.";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.greeks-consumer = {
      Unit = {
        Description = "User-space greeks-consumer service";
        After = [ "kafka.service" ]; # Wait for Kafka
        Requires = [ "kafka.service" "valkey.service" "futures-consumer"  ]; # Fail if Kafka is not available
      };

      Service = {
        ExecStart = lib.concatStringsSep " " (
          [ "${cfg.package}/bin/greeks_consumer" ]
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
