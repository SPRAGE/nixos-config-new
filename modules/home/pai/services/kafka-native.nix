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

    zookeeperAdminServer = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Zookeeper AdminServer (Jetty-based web UI)";
      };

      port = mkOption {
        type = types.port;
        default = 8085;
        description = "Port for Zookeeper AdminServer (if enabled)";
      };
    };
  };

  config = mkIf cfg.enable {
    # Zookeeper
    systemd.user.services.zookeeper = {
      Unit = {
        Description = "Zookeeper Server";
        After = [ "network.target" ];
      };

      Service = {
        ExecStartPre = ''${pkgs.coreutils}/bin/test -f ${cfg.dataDir}/zoo.cfg'';
        ExecStart = "${pkgs.zookeeper}/bin/zkServer.sh start-foreground ${cfg.dataDir}/zoo.cfg";
        Restart = "always";
        Environment = [
          "PATH=${lib.makeBinPath [ pkgs.zookeeper pkgs.coreutils pkgs.gnused pkgs.gnugrep ]}"
        ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # Kafka
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

    # Generate config files
    home.activation.kafkaConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "${cfg.dataDir}"

      echo "tickTime=2000" > "${cfg.dataDir}/zoo.cfg"
      echo "dataDir=${cfg.dataDir}/zoo-data" >> "${cfg.dataDir}/zoo.cfg"
      echo "clientPort=${toString cfg.zookeeperPort}" >> "${cfg.dataDir}/zoo.cfg"
      ${if cfg.zookeeperAdminServer.enable then ''
        echo "admin.enableServer=true" >> "${cfg.dataDir}/zoo.cfg"
        echo "admin.serverPort=${toString cfg.zookeeperAdminServer.port}" >> "${cfg.dataDir}/zoo.cfg"
      '' else ''
        echo "admin.enableServer=false" >> "${cfg.dataDir}/zoo.cfg"
      ''}

      cat > "${cfg.dataDir}/kafka.properties" <<EOF
process.roles=broker
node.id=1

controller.quorum.voters=0@dummy:9093
controller.listener.names=CONTROLLER

log.dirs=${cfg.dataDir}/kafka-logs
zookeeper.connect=localhost:${toString cfg.zookeeperPort}

listeners=PLAINTEXT://${cfg.hostIp}:${toString cfg.kafkaPortExternal},CONTROLLER://dummy:9093
advertised.listeners=PLAINTEXT://${cfg.hostIp}:${toString cfg.kafkaPortExternal}

num.network.threads=3
num.io.threads=8
log.retention.hours=1
log.retention.check.interval.ms=300000
message.max.bytes=20971520
EOF
    '';
  };
}
