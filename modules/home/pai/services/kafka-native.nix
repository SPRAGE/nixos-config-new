{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption mkOption mkIf types;
  cfg = config.modules.services.kafkaKRaft;
in {
  options.modules.services.kafkaKRaft = {
    enable = mkEnableOption "Run Kafka 4.x in KRaft mode without Zookeeper";

    dataDir = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/.local/share/kafka-kraft";
    };

    nodeId = mkOption {
      type = types.int;
      default = 1;
    };

    clusterId = mkOption {
      type = types.str;
      default = "kraft-cluster-id";
    };

    hostIp = mkOption {
      type = types.str;
      default = "127.0.0.1";
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
    # Write kraft.properties and init script
    home.activation.kafkaConfigs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "${cfg.dataDir}/logs"

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

      cat > "${cfg.dataDir}/init-kraft.sh" <<EOF
#!${pkgs.bash}/bin/bash
set -eux
export PATH="${lib.makeBinPath [ pkgs.apacheKafka pkgs.coreutils pkgs.gnused pkgs.gnugrep ]}:$PATH"

if [ ! -f "${cfg.dataDir}/logs/meta.properties" ]; then
  kafka-storage.sh format \
    --cluster-id=${cfg.clusterId} \
    --config "${cfg.dataDir}/kraft.properties" \
    --ignore-formatted
fi
EOF

      chmod +x "${cfg.dataDir}/init-kraft.sh"
    '';

    systemd.user.services.kafka = {
      Unit = {
        Description = "Apache Kafka 4.x (KRaft)";
        After = [ "network.target" ];
      };

      Service = {
        ExecStartPre = "${cfg.dataDir}/init-kraft.sh";
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
  };
}
