{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    optionalString
    concatStringsSep;

  cfg = config.modules.services.clickhouse;

  dataDir = "${config.home.homeDirectory}/.local/share/clickhouse";
  configDir = "${config.xdg.configHome}/clickhouse";

  generatedUsersXml = pkgs.writeText "clickhouse-users.xml" ''
    <clickhouse>
      <profiles>
        <default />
        <readonly>
          <readonly>1</readonly>
        </readonly>
      </profiles>

      <users>
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
        <log>${dataDir}/ch_logs/clickhouse-server.log</log>
        <errorlog>${dataDir}/ch_logs/clickhouse-server.err.log</errorlog>
        <console>false</console>
      </logger>

      <path>${dataDir}/</path>
      <tmp_path>${dataDir}/tmp/</tmp_path>
      <user_files_path>${dataDir}/user_files/</user_files_path>
      <format_schema_path>${dataDir}/format_schemas/</format_schema_path>
      <custom_cached_disks_base_directory>${dataDir}/caches/</custom_cached_disks_base_directory>

      <user_directories>
        <users_xml>
          <path>${configDir}/users.xml</path>
        </users_xml>
        <local_directory>
          <path>${dataDir}/access/</path>
        </local_directory>
      </user_directories>

      <tcp_port>${toString cfg.tcpPort}</tcp_port>
      <http_port>${toString cfg.httpPort}</http_port>
      <listen_host>${cfg.listenHost}</listen_host>

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
in {
    options.modules.services.clickhouse = {
    enable = mkEnableOption "Enable ClickHouse (user-level)";

    dataDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.local/share/clickhouse";
      description = "Data directory for ClickHouse. Must be writable by the user.";
    };

    tcpPort = mkOption {
      type = types.port;
      default = 9000;
      description = "TCP port for native ClickHouse protocol.";
    };

    httpPort = mkOption {
      type = types.port;
      default = 8123;
      description = "Port for HTTP interface.";
    };

    listenHost = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Which address to bind ClickHouse to.";
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
            description = "Password hash (SHA-256).";
          };

          profile = mkOption {
            type = types.str;
            default = "readonly";
            description = "User profile: 'readonly' or 'default'.";
          };
        };
      });
      default = [];
      description = "List of ClickHouse users.";
    };
  };


  config = mkIf cfg.enable {
    home.packages = [ pkgs.clickhouse ];

    xdg.configFile."clickhouse/config.xml".source = generatedConfigXml;
    xdg.configFile."clickhouse/users.xml".source = generatedUsersXml;

    systemd.user.services.clickhouse-server = {
      Unit = {
        Description = "User ClickHouse Server";
        After = "network.target";
      };

      Service = {
        ExecStart = "${pkgs.clickhouse}/bin/clickhouse-server --config-file=${configDir}/config.xml";
        WorkingDirectory = dataDir;
        Restart = "always";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
