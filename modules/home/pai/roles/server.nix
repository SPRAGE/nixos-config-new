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

      valkey = {
        enable = true;
        port = 6379;
        bind = [ "192.168.0.x" ];
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
    };

  };
}
