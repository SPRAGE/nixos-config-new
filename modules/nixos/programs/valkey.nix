{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption mkOption types;
in
{
  options.modules.programs.valkey = {
    enable = mkEnableOption "Enable Valkey (Redis-compatible server)";

    port = mkOption {
      type = types.port;
      default = 6379;
      description = "Port on which Valkey should listen.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/valkey";
      description = "Data directory for Valkey persistence.";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration lines for valkey.conf.";
    };
  };

  config = mkIf config.modules.programs.valkey.enable {
    services.valkey = {
      enable = true;
      port = config.modules.programs.valkey.port;
      dataDir = config.modules.programs.valkey.dataDir;
      extraConfig = config.modules.programs.valkey.extraConfig;
    };

    environment.systemPackages = [ pkgs.valkey ];
  };
}
