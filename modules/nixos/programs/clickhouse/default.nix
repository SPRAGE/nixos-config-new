{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.modules.programs.clickhouse;
in
{
  options.modules.programs.clickhouse = {
    enable = mkEnableOption "Enable ClickHouse server";

    configFile = mkOption {
      type = types.path;
      default = ./config.xml;
      description = ''
        Path to a custom config.xml for ClickHouse.
        It will be copied to /etc/clickhouse-server/config.xml.
      '';
    };

    usersFile = mkOption {
      type = types.path;
      default = ./users.xml;
      description = ''
        Path to a custom users.xml for ClickHouse user access control.
        It will be copied to /etc/clickhouse-server/users.xml.
        Password hashes should be precomputed and inserted here.
      '';
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/clickhouse";
      description = "Directory where ClickHouse will store its data.";
    };
  };

  config = mkIf cfg.enable {
    # Create group and user
    users.groups.clickhouse = { };

    users.users.clickhouse = {
      isSystemUser = true;
      group = "clickhouse";
      home = cfg.dataDir;
      description = "ClickHouse server user";
    };

    # Ensure data dir exists
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 clickhouse clickhouse - -"
    ];

    # Provide config and users file
    environment.etc."clickhouse-server/config.xml".source = cfg.configFile;
    environment.etc."clickhouse-server/users.xml".source = cfg.usersFile;

    # Systemd service
    systemd.services.clickhouse-server = {
      description = "ClickHouse DBMS server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.clickhouse}/bin/clickhouse-server --config-file=/etc/clickhouse-server/config.xml";
        User = "clickhouse";
        WorkingDirectory = cfg.dataDir;
        Restart = "always";
      };
    };

    # Add clickhouse tools
    environment.systemPackages = [ pkgs.clickhouse ];
  };
}
