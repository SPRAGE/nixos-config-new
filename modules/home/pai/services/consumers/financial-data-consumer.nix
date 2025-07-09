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
        pkgs.coreutils      # for sleep
        pkgs.gnugrep        # for grep
        pkgs.nettools       # for netstat
        pkgs.inetutils      # for telnet
      ]
    }

    BOOTSTRAP_SERVER="${cfg.kafkaBootstrapServer}"
    echo "🕒 Waiting for Kafka to become ready..."
    echo "🔗 Connecting to: $BOOTSTRAP_SERVER"
    
    # Extract host and port for connectivity test
    KAFKA_HOST=$(echo "$BOOTSTRAP_SERVER" | cut -d':' -f1)
    KAFKA_PORT=$(echo "$BOOTSTRAP_SERVER" | cut -d':' -f2)
    
    echo "🔍 Testing network connectivity to $KAFKA_HOST:$KAFKA_PORT..."
    
    # First check if the port is open
    for i in {1..10}; do
      if timeout 3 bash -c "</dev/tcp/$KAFKA_HOST/$KAFKA_PORT" 2>/dev/null; then
        echo "✅ Port $KAFKA_PORT is open on $KAFKA_HOST"
        break
      fi
      echo "⏳ Port not yet open, retrying in 2s... ($i/10)"
      sleep 2
    done

    # Now test Kafka readiness with topics
    for i in {1..30}; do
      echo "🔍 Attempt $i/30: Testing Kafka topic listing..."
      if kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list 2>/dev/null | grep -q "__consumer_offsets"; then
        echo "✅ Kafka is ready - found __consumer_offsets topic."
        exit 0
      elif kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list 2>/dev/null; then
        echo "⚠️  Kafka is responding but __consumer_offsets topic not found yet..."
        echo "📋 Available topics:"
        kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list 2>/dev/null || echo "  (none)"
      else
        echo "⏳ Kafka not ready yet, retrying in 3s... ($i/30)"
      fi
      sleep 3
    done

    echo "❌ Timed out waiting for Kafka readiness."
    echo "🔍 Final debug information:"
    echo "  Bootstrap server: $BOOTSTRAP_SERVER"
    echo "  Network test to $KAFKA_HOST:$KAFKA_PORT:"
    timeout 3 bash -c "</dev/tcp/$KAFKA_HOST/$KAFKA_PORT" 2>/dev/null && echo "    ✅ Port is reachable" || echo "    ❌ Port is not reachable"
    echo "  Kafka topics list attempt:"
    kafka-topics.sh --bootstrap-server "$BOOTSTRAP_SERVER" --list 2>&1 || echo "    Failed to connect"
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
        ExecStartPre = [
          "${pkgs.coreutils}/bin/sleep 10"  # Give Kafka more time to start
          waitForKafka
        ];
        ExecStart = lib.concatStringsSep " " (
          [ "${cfg.package}/bin/financial-data-consumer" ]
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
        WantedBy = [ "default.target" "multi-user.target" ];
      };
    };
  };
}
