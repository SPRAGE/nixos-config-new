{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types;
  cfg = config.modules.services.kafkaUi;
in
{
  options.modules.services.kafkaUi = {
    enable = mkEnableOption "Enable Kafka UI via Docker";

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port to expose the Kafka UI.";
    };

    kafkaBootstrapServers = mkOption {
      type = types.str;
      description = "Kafka bootstrap servers (e.g. 127.0.0.1:9092)";
    };

    clusterName = mkOption {
      type = types.str;
      default = "kafka-cluster";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.kafka-ui = {
      Unit = {
        Description = "Kafka UI via Docker";
        After = [ "network.target" ];
      };

      Service = {
        ExecStart = ''
          ${pkgs.docker}/bin/docker run --rm --name kafka-ui \
            -p ${toString cfg.port}:8080 \
            -e KAFKA_CLUSTERS_0_NAME=${cfg.clusterName} \
            -e KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=${cfg.kafkaBootstrapServers} \
            -e KAFKA_CLUSTERS_0_KRAFT=true \
            provectuslabs/kafka-ui:latest
        '';
        Restart = "always";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
