{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.modules.programs.valkey;
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

  config = mkIf cfg.enable {
    users.users.valkey = {
      isSystemUser = true;
      description = "Valkey server user";
      home = cfg.dataDir;
    };

    systemd.services.valkey = {
      description = "Valkey (Redis-compatible key-value store)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = ''
          ${pkgs.valkey}/bin/valkey-server \
            --port ${toString cfg.port} \
            --dir ${cfg.dataDir} \
            --bind 127.0.0.1 \
            ${pkgs.writeText "valkey-extra.conf" cfg.extraConfig}
        '';
        User = "valkey";
        WorkingDirectory = cfg.dataDir;
        Restart = "always";
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 valkey valkey - -"
    ];

    environment.systemPackages = [ pkgs.valkey ];
  };
}
