{
  inputs,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
  cfg = osConfig.modules.roles.server;
in
{
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # inputs.nix-citizen.packages.${system}.star-citizen
      # prismlauncher # Minecraft
      # bottles
      # inputs.xivlauncher-rb.packages.${system}.default
    ];

    modules.services = {
      grpcInvoker = {
        enable           = true;
        targetIp         = "127.0.0.1:50002";
        instrumentMethod = "ingestion.IngestionService/IngestInstruments";
        futuresMethod    = "ingestion.IngestionService/IngestFutures";
      };
      auth-server = {
        enable = true;
        package = inputs.trading.packages.${pkgs.system}.auth_server;
        configFile = null; # or ./config.toml
      };
      analysis-server = {
        enable = true;
        package = inputs.analysis-server.packages.${pkgs.system}.default;
        configFile = null; # or ./config.toml
      };
      ingestion-server = {
        enable = true;
        package = inputs.trading.packages.${pkgs.system}.ingestion_server;
        configFile = null; # or ./config.toml
        rustLogLevel = "debug";
      };
      internal-websocket = {
        enable = true;
        package = inputs.internal-websocket.packages.${pkgs.system}.default;
        configFile = null; # or ./config.toml
        rustLogLevel = "error";
      };
      index-consumer = {
        enable = true;
        package = inputs.websocket-server.packages.${pkgs.system}.index_consumer;
        configFile = null; # or ./config.toml
        rustLogLevel = "error";
      };
      futures-consumer = {
        enable = true;
        package = inputs.websocket-server.packages.${pkgs.system}.futures_consumer;
        configFile = null; # or ./config.toml
        rustLogLevel = "error";
      };
      greeks-consumer = {
        enable = true;
        package = inputs.websocket-server.packages.${pkgs.system}.greeks_consumer;
        configFile = null; # or ./config.toml
        rustLogLevel = "error";
      };
      ws-manager = {
        enable = true;
        package = inputs.websocket-server.packages.${pkgs.system}.ws_manager;
        configFile = null; # or ./config.toml
        rustLogLevel = "error";
      };

      historical-data-updater = {
        enable = true;
        package = inputs.ingestion-server.packages.${pkgs.system}.historical-data-updater;
        configFile = null; # or ./config.toml
        rustLogLevel = "error";
      };

      valkey = {
        enable = true;
        port = 6379;
        bind = [ "*" ];
        aclUsers = [
          {
            name = "read";
            hash = "8877c58975fc1f061338418bc0424b5b08c95ff412dc08a68cfa879f45dbbf10"; # sha256
            acl = "~readonly:* +get +info";
          }
          {
            name = "shaun";
            hash = "a65aaf4f6cd6b72db0280c4f4f0abdee8d65ec047e4a21b7fadb0a4f89f3fb52"; # sha256
            acl = "allcommands allkeys";
          }
        ];

        disableDefaultUser = true;
      };

      clickhouse = {
        enable = true;
        listenHost = "0.0.0.0";
        dataDir = "/mnt/shaun/clickhouse";
        users = [
          {
            name = "shaun";
            hash = "5060a3874499a874ae0e6d3d8b576121037d322e97de5632c8726e94c480ae86";
            profile = "default";
          }
          {
            name = "default";
            hash = "62362d60d7efa6e6844e5ad8621bd5fa57b573d0435e339c1f77feb28ae07cfe";
            profile = "readonly";
          }
          {
            name = "read";
            hash = "62362d60d7efa6e6844e5ad8621bd5fa57b573d0435e339c1f77feb28ae07cfe";
            profile = "readonly";
          }
        ];

      };
      kafkaKRaft = {
        enable = true;
        dataDir = "/mnt/shaun/kafka-kraft";
        clusterId = "63c32934-29e7-448b-8de3-da94924282f6"; # Optional: you can use `uuidgen` for randomness
        hostIp = "192.168.0.7";
        topics = [
          {
            name = "tick_data";
            partitions = 1;
            replication = 1;
          }
          {
            name = "text_message";
            partitions = 1;
            replication = 1;
          }
          {
            name = "__consumer_offsets";
            partitions = 1;
            replication = 1;
            config = {
              "cleanup.policy" = "compact";
            };
          }
        ];
      };
      kafkaUi = {
        enable = true;
        kafkaBootstrapServers = "192.168.0.7:9092"; # Or "127.0.0.1:9092"
        port = 8086;
        clusterName = "kraft-shaun";
      };

    };
  };
}
