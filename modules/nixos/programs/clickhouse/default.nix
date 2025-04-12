{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    optionalString
    concatStringsSep
    ;

  cfg = config.modules.programs.clickhouse;

  generatedUsersXml = pkgs.writeText "clickhouse-users.xml" ''
    <clickhouse>
      <profiles>
        <default />
        <readonly>
          <readonly>1</readonly>
        </readonly>
      </profiles>

      <users>
        ${concatStringsSep "\n" (
          [
            # Disable default user
            ''
              <default>
                <password_sha256_hex></password_sha256_hex>
                <networks />
                <profile>readonly</profile>
                <quota>default</quota>
                <access_management>0</access_management>
              </default>
            ''
          ]
          ++ (map (u: ''
            <${u.name}>
              <password_sha256_hex>${u.hash}</password_sha256_hex>
              <networks><ip>::/0</ip></networks>
              <profile>${u.profile}</profile>
              <quota>default</quota>
              <access_management>${if u.profile == "default" then "1" else "0"}</access_management>
            </${u.name}>
          '') cfg.users)
        )}
      </users>

      <quotas>
        <default>
          <interval>
            <duration>3600</duration>
            <queries>0</queries>
            <errors>0</errors>
            <result_rows>0</result_rows>
            <read_rows>0</read_rows>
            <execution_time>0</execution_time>
          </interval>
        </default>
      </quotas>
    </clickhouse>
  '';

  generatedConfigXml = pkgs.writeText "clickhouse-config.xml" ''
    <clickhouse>
      <logger>
        <level>${if cfg.disableLogs then "none" else "information"}</level>
        <console>false</console>
        <log>/dev/null</log>
        <errorlog>/dev/null</errorlog>
      </logger>

      <path>${cfg.dataDir}/</path>
      <tmp_path>${cfg.dataDir}/tmp/</tmp_path>
      <user_files_path>${cfg.dataDir}/user_files/</user_files_path>
      <format_schema_path>${cfg.dataDir}/format_schemas/</format_schema_path>
      <custom_cached_disks_base_directory>${cfg.dataDir}/caches/</custom_cached_disks_base_directory>

      <user_directories>
        <users_xml>
          <path>users.xml</path>
        </users_xml>
        <local_directory>
          <path>${cfg.dataDir}/access/</path>
        </local_directory>
      </user_directories>

      ${optionalString cfg.disableLogs ''
        <query_log remove="1"/>
        <trace_log remove="1"/>
        <query_thread_log remove="1"/>
        <query_views_log remove="1"/>
        <part_log remove="1"/>
        <text_log remove="1"/>
        <metric_log remove="1"/>
        <latency_log remove="1"/>
        <error_log remove="1"/>
        <query_metric_log remove="1"/>
        <asynchronous_metric_log remove="1"/>
        <opentelemetry_span_log remove="1"/>
        <crash_log remove="1"/>
        <processors_profile_log remove="1"/>
        <asynchronous_insert_log remove="1"/>
        <backup_log remove="1"/>
        <s3queue_log remove="1"/>
        <blob_storage_log remove="1"/>
      ''}
    </clickhouse>
  '';
in
{
  options.modules.programs.clickhouse = {
    enable = mkEnableOption "Enable ClickHouse server";

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional path to custom config.xml (overrides auto-generated one).";
    };

    usersFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional path to custom users.xml (overrides auto-generated one).";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/clickhouse";
      description = "Directory where ClickHouse stores data.";
    };

    disableLogs = mkOption {
      type = types.bool;
      default = true;
      description = "Disable all ClickHouse logs.";
    };

    users = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "ClickHouse username.";
          };
          hash = mkOption {
            type = types.str;
            description = "SHA-256 hashed password.";
          };
          profile = mkOption {
            type = types.str;
            default = "readonly";
            description = "Profile for the user ('default' or 'readonly').";
          };
        };
      });
      default = [ ];
      description = "Users to create with password hashes and access profiles.";
    };
  };

  config = mkIf cfg.enable {
    users.groups.clickhouse = {};

    users.users.clickhouse = {
      isSystemUser = true;
      group = "clickhouse";
      home = cfg.dataDir;
      description = "ClickHouse database server user";
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 clickhouse clickhouse - -"
    ];

    environment.etc."clickhouse-server/config.xml".source =
      if cfg.configFile != null then cfg.configFile else generatedConfigXml;

    environment.etc."clickhouse-server/users.xml".source =
      if cfg.usersFile != null then cfg.usersFile else generatedUsersXml;

    systemd.services.clickhouse-server = {
      description = "ClickHouse DBMS";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.clickhouse}/bin/clickhouse-server --config-file=/etc/clickhouse-server/config.xml";
        User = "clickhouse";
        WorkingDirectory = cfg.dataDir;
        Restart = "always";
      };
    };

    environment.systemPackages = [ pkgs.clickhouse ];
  };
}
