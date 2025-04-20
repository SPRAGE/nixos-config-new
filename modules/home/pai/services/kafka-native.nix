{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption mkOption mkIf types;
  cfg = config.modules.services.kafkaKRaft;
in {
  options.modules.services.kafkaKRaft = {
    enable = mkEnableOption "Enable Kafka 4.x in KRaft (no Zookeeper) mode";

    dataDir = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/.local/share/kafka-kraft";
      description = "Kafka data directory";
    };

    nodeId = mkOption {
      type = types.int;
      default = 1;
      description = "Unique node ID for this Kafka broker";
    };

    clusterId = mkOption {
      type = types.str;
      default = "MkCluster-KRaft-Test"; # You can generate with uuidgen if needed
      description = "Kafka KRaft cluster ID";
    };

    hostIp = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Host IP to bind and advertise for external Kafka connections";
    };

    kafkaPort = mkOption {
      type = types.port;
      default = 9092;
    };

    controllerPort = mkOption {
      type = types.port;
      default = 9093;
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.kafka = {
      Unit = {
        Description = "Apache Kafka 4.x (KRaft mode)";
        After = [ "network.target" ];
      };

      Service = {
        ExecStartPre = ''
          mkdir -p ${cfg.dataDir}
          if [ ! -f ${cfg.dataDir}/meta.properties ]; then
            echo "Bootstrapping Kafka KRaft metadata..."
            ${pkgs.apacheKafka}/bin/kafka-storage.sh format \
              --ignore-formatted \
              --cluster-id=${cfg.clusterId} \
              --config ${cfg.dataDir}/kraft.properties
          fi
        '';

        ExecStart = "${pkgs.apacheKafka}/bin/kafka-server-start.sh ${cfg.dataDir}/kraft.properties";

        Restart = "always";

        Environment = [
          "PATH=${lib.makeBinPath [ pkgs.apacheKafka pkgs.coreutils pkgs.gnused pkgs.gnugrep ]}"
        ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    home.activation.kafkaKRaftConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "${cfg.dataDir}"

      cat > "${cfg.dataDir}/kraft.properties" <<EOF
process.roles=broker,controller
node.id=${toString cfg.nodeId}
controller.quorum.voters=${toString cfg.nodeId}@${cfg.hostIp}:${toString cfg.controllerPort}
controller.listener.names=CONTROLLER

listeners=PLAINTEXT://${cfg.hostIp}:${toString cfg.kafkaPort},CONTROLLER://${cfg.hostIp}:${toString cfg.controllerPort}
advertised.listeners=PLAINTEXT://${cfg.hostIp}:${toString cfg.kafkaPort}
listener.security.protocol.map=PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT

log.dirs=${cfg.dataDir}/logs
num.network.threads=3
num.io.threads=8
log.retention.hours=1
log.retention.check.interval.ms=300000
message.max.bytes=20971520
EOF
    '';
  };
}
