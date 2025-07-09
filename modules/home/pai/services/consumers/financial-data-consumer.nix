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

  cfg = config.modules.services.financial_data_consumer;

  waitForKafka = pkgs.writeShellScript "wait-for-kafka" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.apacheKafka
        pkgs.coreutils
      ]
    }

    BOOTSTRAP_SERVER="${cfg.kafkaBootstrapServer}"
    echo "🕒 Waiting for Kafka at $BOOTSTRAP_SERVER..."
    
    # Extract host and port
    KAFKA_HOST=$(echo "$BOOTSTRAP_SERVER" | cut -d':' -f1)
    KAFKA_PORT=$(echo "$BOOTSTRAP_SERVER" | cut -d':' -f2)
    
    # Wait for port to be available (max 30 seconds)
    for i in {1..10}; do
      if timeout 2 bash -c "</dev/tcp/$KAFKA_HOST/$KAFKA_PORT" 2>/dev/null; then
        echo "✅ Kafka port is accessible"
        break
      fi
      echo "⏳ Waiting for Kafka port... ($i/10)"
      sleep 3
    done

    # Wait for Kafka to respond to API calls (max 30 seconds)
    for i in {1..10}; do
      if timeout 3 kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list &>/dev/null; then
        echo "✅ Kafka is ready"
        exit 0
      fi
      echo "⏳ Waiting for Kafka API... ($i/10)"
      sleep 3
    done

    echo "❌ Kafka not ready within timeout"
    exit 1
  '';
in
{
  options.modules.services.financial_data_consumer = {
    enable = mkEnableOption "Enable the financial_data_consumer as a user service";

    package = mkOption {
      type = types.package;
      description = "The package providing the financial_data_consumer binary.";
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional path to the TOML config file used by financial_data_consumer.";
    };

    rustLogLevel = mkOption {
      type = types.str;
      default = "warn";
      description = "The log level for the RUST_LOG environment variable.";
    };

    kafkaBootstrapServer = mkOption {
      type = types.str;
      default = "127.0.0.1:9092";
      description = "Kafka bootstrap server address for connection checks.";
    };

    waitForKafka = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to wait for Kafka to be ready before starting the service.";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.financial_data_consumer = {
      Unit = {
        Description = "User-space financial_data_consumer service";
        After = [ "kafka.service" "valkey.service" ]; # Wait for Kafka and Valkey
        Requires = [ "kafka.service" "valkey.service" ]; # Fail if Kafka or Valkey are not available
        BindsTo = [ "kafka.service" ]; # Stop if Kafka stops
      };

      Service = {
        # Conditionally wait for Kafka or just add a simple delay
        ExecStartPre = if cfg.waitForKafka then waitForKafka else "${pkgs.coreutils}/bin/sleep 5";
        ExecStart = lib.concatStringsSep " " (
          [ "${cfg.package}/bin/financial-data-consumer" ]
          ++ lib.optionals (cfg.configFile != null) [
            "--config"
            "${cfg.configFile}"
          ]
        );

        # Timeout configuration
        TimeoutStartSec = "60s";  # Shorter timeout
        TimeoutStopSec = "30s";

        Restart = "on-failure";
        RestartSec = "15s";
        StartLimitBurst = 5;
        StartLimitIntervalSec = "300s";
        
        Environment = [
          "LD_LIBRARY_PATH=${pkgs.openssl.out}/lib"
          "RUST_LOG=${cfg.rustLogLevel}"
        ];
      };

      Install = {
        WantedBy = [ "default.target" "multi-user.target" ];
      };
    };
  };
}
