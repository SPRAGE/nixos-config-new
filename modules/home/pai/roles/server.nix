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
      auth-server = {
        enable = true;
        package = inputs.auth-server.packages.${pkgs.system}.default;
        configFile = null; # or ./config.toml
      };
      analysis-server = {
        enable = true;
        package = inputs.analysis-server.packages.${pkgs.system}.default;
        configFile = null; # or ./config.toml
      };
      ingestion-server = {
        enable = true;
        package = inputs.ingestion-server.packages.${pkgs.system}.ingestion-server;
        configFile = null; # or ./config.toml
        rustLogLevel = "warn";
      };
      historical-data-updater = {
        enable = true;
        package = inputs.ingestion-server.packages.${pkgs.system}.historical-data-updater;
        configFile = null; # or ./config.toml
        rustLogLevel = "debug";
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
    };
  };
}
