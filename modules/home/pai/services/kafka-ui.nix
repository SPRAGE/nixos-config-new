{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types;
  cfg = config.modules.services.kafkaUiDocker;
in
{
  options.modules.services.kafkaUiDocker = {
    enable = mkEnableOption "Enable Kafka UI via Docker";

    kafkaUiDockerImage = mkOption {
      type = types.str;
      default = "provectuslabs/kafka-ui:latest";
      description = "Kafka UI Docker image to run";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port to expose Kafka UI on";
    };

    clusterName = mkOption {
      type = types.str;
      default = "kafka-cluster";
      description = "Name of the Kafka cluster to show in the UI";
    };

    bootstrapServers = mkOption {
      type = types.str;
      default = "localhost:9092";
      description = "Kafka bootstrap servers";
    };

    zookeeperConnect = mkOption {
      type = types.str;
      default = "localhost:2181";
      description = "Zookeeper connection string";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.kafka-ui = {
      Unit = {
        Description = "Kafka UI (Docker)";
        After = [ "network.target" ];
      };

      Service = {
        ExecStart = ''
          ${pkgs.docker}/bin/docker run --rm --name kafka-ui \
            -p ${toString cfg.port}:8080 \
            -e KAFKA_CLUSTERS_0_NAME=${cfg.clusterName} \
            -e KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=${cfg.bootstrapServers} \
            -e KAFKA_CLUSTERS_0_ZOOKEEPER=${cfg.zookeeperConnect} \
            ${cfg.kafkaUiDockerImage}
        '';
        ExecStop = "${pkgs.docker}/bin/docker stop kafka-ui";
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
