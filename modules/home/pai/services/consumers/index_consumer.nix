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

  cfg = config.modules.services.index-consumer;
in
{
  options.modules.services.index-consumer = {
    enable = mkEnableOption "Enable the index-consumer as a user service";

    package = mkOption {
      type = types.package;
      description = "The package providing the index_consumer binary.";
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional path to the TOML config file used by index_consumer.";
    };

    rustLogLevel = mkOption {
      type = types.str;
      default = "warn";
      description = "The log level for the RUST_LOG environment variable.";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.index-consumer = {
      Unit = {
        Description = "User-space index-consumer service";
        After = [ "kafka.service" ]; # Wait for Kafka
        Requires = [ "kafka.service" "redis.service"  ]; # Fail if Kafka is not available
      };

      Service = {
        ExecStart = lib.concatStringsSep " " (
          [ "${cfg.package}/bin/index_consumer" ]
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
