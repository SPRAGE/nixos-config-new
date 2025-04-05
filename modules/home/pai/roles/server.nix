{
  inputs,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
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
  };
}
