{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    optionalString;

  cfg = config.modules.services.ws-manager;

  waitForKafka = pkgs.writeShellScript "wait-for-kafka" ''
    echo "🕒 Waiting for Kafka to become ready..."

    for i in {1..50}; do
      if ${pkgs.apacheKafka}/bin/kafka-topics.sh \
        --bootstrap-server 192.168.0.7:9092 \
        --list | grep -q "__consumer_offsets"; then
        echo "✅ Kafka is ready."
        exit 0
      fi
      echo "⏳ Kafka not ready yet, retrying in 1s... ($i/20)"
      sleep 1
    done

    echo "❌ Timed out waiting for Kafka readiness."
    exit 1
  '';
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
        After = [ "kafka.service" ];
        Requires = [ "kafka.service" "valkey.service" ];
      };

      Service = {
        ExecStartPre = waitForKafka;

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
