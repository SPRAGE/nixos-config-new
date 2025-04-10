{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.my.services.valkey;
in
{
  options.modules.programs.valkey = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable the Valkey key-value store service.";
    };

    port = mkOption {
      type = types.port;
      default = 6379;
      description = "Port on which Valkey should listen.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/valkey";
      description = "Data directory for Valkey.";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra Valkey configuration lines.";
    };
  };

  config = mkIf cfg.enable {
    users.users.valkey = {
      description = "Valkey user";
      isSystemUser = true;
      home = cfg.dataDir;
    };

    systemd.services.valkey = {
      description = "Valkey Server";
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
        Restart = "always";
        User = "valkey";
        WorkingDirectory = cfg.dataDir;
      };
    };

    environment.systemPackages = [ pkgs.valkey ];

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 valkey valkey - -"
    ];
  };
}
