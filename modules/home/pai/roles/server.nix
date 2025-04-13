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
    };

  };
}
