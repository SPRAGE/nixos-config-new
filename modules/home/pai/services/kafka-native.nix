{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption mkOption mkIf types;
  cfg = config.modules.services.kafkaNative;
in
{
  options.modules.services.kafkaNative = {
    enable = mkEnableOption "Run Kafka and Zookeeper using native Nix packages";

    dataDir = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/.local/share/kafka-native";
      description = "Base directory for Kafka and Zookeeper data";
    };

    hostIp = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "IP address to advertise Kafka externally";
    };

    kafkaPortInternal = mkOption {
      type = types.port;
      default = 9092;
    };

    kafkaPortExternal = mkOption {
      type = types.port;
      default = 9094;
    };

    zookeeperPort = mkOption {
      type = types.port;
      default = 2181;
    };
  };

  config = mkIf cfg.enable {
    # Zookeeper native
    systemd.user.services.zookeeper = {
      Unit = {
        Description = "Zookeeper Server";
        After = [ "network.target" ];
      };

      Service = {
        ExecStart = "${pkgs.zookeeper}/bin/zkServer.sh start-foreground ${cfg.dataDir}/zoo.cfg";
        Restart = "always";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # Kafka native
    systemd.user.services.kafka = {
      Unit = {
        Description = "Apache Kafka Broker";
        After = [ "zookeeper.service" ];
        Requires = [ "zookeeper.service" ];
      };

      Service = {
        ExecStart = "${pkgs.apacheKafka}/bin/kafka-server-start.sh ${cfg.dataDir}/kafka.properties";
        Restart = "always";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # Minimal config files (generated during activation)
    home.activation.kafkaConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "${cfg.dataDir}"

      cat > "${cfg.dataDir}/zoo.cfg" <<EOF
tickTime=2000
dataDir=${cfg.dataDir}/zoo-data
clientPort=${toString cfg.zookeeperPort}
EOF

      cat > "${cfg.dataDir}/kafka.properties" <<EOF
broker.id=1
log.dirs=${cfg.dataDir}/kafka-logs
zookeeper.connect=localhost:${toString cfg.zookeeperPort}
listeners=PLAINTEXT://${cfg.hostIp}:${toString cfg.kafkaPortExternal}
num.network.threads=3
num.io.threads=8
log.retention.hours=1
log.retention.check.interval.ms=300000
message.max.bytes=20971520
EOF
    '';
  };
}
