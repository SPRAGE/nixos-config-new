{
  config,
  lib,
  pkgs,
  ...
}:

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
        <!-- Disable the default user -->
        <default>
          <password_sha256_hex>cbf06754df2f70dd1f853bdccaec98cc6d8ba861a2a91d357540b9d561b6ceb7</password_sha256_hex>
          <networks />
          <profile>readonly</profile>
          <quota>default</quota>
          <access_management>0</access_management>
        </default>

        ${concatStringsSep "\n" (
          map (u: ''
            <${u.name}>
              <password_sha256_hex>${u.hash}</password_sha256_hex>
              <networks><ip>::/0</ip></networks>
              <profile>${u.profile}</profile>
              <quota>default</quota>
              <access_management>${if u.profile == "default" then "1" else "0"}</access_management>
            </${u.name}>
          '') cfg.users
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
      <log>${cfg.dataDir}/ch_logs/clickhouse-server.log</log>
      <errorlog>${cfg.dataDir}/ch_logs/clickhouse-server.err.log</errorlog>
      <console>false</console>
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
    enable = mkEnableOption "Enable the ClickHouse database server";

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Custom `config.xml` file. If null, a minimal version is generated.";
    };

    usersFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Custom `users.xml` file. If null, one is generated from `users` option.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/clickhouse";
      description = "Data directory for ClickHouse (must be writable by the clickhouse user).";
    };

    disableLogs = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to disable all ClickHouse logging (files + system logs).";
    };

    openPorts = mkOption {
      type = types.bool;
      default = true;
      description = "Open ClickHouse ports in the firewall (9000, 8123, 9009).";
    };

    users = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Username for ClickHouse.";
            };

            hash = mkOption {
              type = types.str;
              description = "SHA-256 hashed password.";
            };

            profile = mkOption {
              type = types.str;
              default = "readonly";
              description = "User profile (`default` or `readonly`).";
            };
          };
        }
      );
      default = [ ];
      description = "List of users with password hashes and optional profiles.";
    };
  };

  config = mkIf cfg.enable {
    # System user and group
    users.groups.clickhouse = { };
    users.users.clickhouse = {
      isSystemUser = true;
      group = "clickhouse";
      description = "ClickHouse DBMS system user";
      home = cfg.dataDir;
    };

    # Ensure data directory exists and is owned properly
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 clickhouse clickhouse - -"
    ];

    # Place config and user definitions in /etc
    environment.etc."clickhouse-server/config.xml".source =
      if cfg.configFile != null then cfg.configFile else generatedConfigXml;

    environment.etc."clickhouse-server/users.xml".source =
      if cfg.usersFile != null then cfg.usersFile else generatedUsersXml;

    networking.firewall.allowedTCPPorts = mkIf cfg.openPorts [
      9000 # Native TCP protocol (clickhouse-client)
      8123 # HTTP API
      9009 # Interserver communication (for clusters)
    ];

    # Systemd service to run as clickhouse
    systemd.services.clickhouse-server = {
      description = "ClickHouse Database Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.clickhouse}/bin/clickhouse-server --config-file=/etc/clickhouse-server/config.xml";
        User = "clickhouse";
        Group = "clickhouse";
        WorkingDirectory = cfg.dataDir;
        Restart = "always";
      };
    };

    # Provide clickhouse-client + utilities system-wide
    environment.systemPackages = [ pkgs.clickhouse ];
  };
}
