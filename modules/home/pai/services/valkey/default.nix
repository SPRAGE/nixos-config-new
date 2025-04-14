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
    concatStringsSep
    optionals
    ;
  cfg = config.modules.services.valkey;
in
{
  options.modules.services.valkey = {
    enable = mkEnableOption "Enable Valkey (user-level)";

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional custom valkey.conf to use. If null, one is generated.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.local/share/valkey";
      description = "Data directory for Valkey.";
    };

    port = mkOption {
      type = types.port;
      default = 6379;
      description = "Port to listen on.";
    };

    bind = mkOption {
      type = types.listOf types.str;
      default = [ "127.0.0.1" ];
      description = "List of IPs to bind to.";
    };

    aclUsers = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Username for Valkey ACL.";
            };
            hash = mkOption {
              type = types.str;
              description = "SHA-256 hashed password.";
            };
            acl = mkOption {
              type = types.str;
              default = "allcommands allkeys";
              description = "ACL string.";
            };
          };
        }
      );
      default = [ ];
      description = "Valkey ACL users.";
    };

    disableDefaultUser = mkOption {
      type = types.bool;
      default = true;
      description = "Disable the default Valkey user.";
    };
  };

  config = mkIf cfg.enable {
    # Ensure data directory exists
    home.activation.ensureValkeyDataDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${cfg.dataDir}
    '';

    # Optionally generate ACL file
    xdg.configFile."valkey/users.acl".text = mkIf (cfg.aclUsers != [ ] || cfg.disableDefaultUser) (
      let
        userLines = map (u: "user ${u.name} on #${u.hash} ${u.acl}") cfg.aclUsers;
        defaultLine = if cfg.disableDefaultUser then [ "user default off" ] else [ ];
      in
      concatStringsSep "\n" (defaultLine ++ userLines)
    );

    # Optionally generate config file
    xdg.configFile."valkey/valkey.conf".text = mkIf (cfg.configFile == null) ''
      bind ${concatStringsSep " " cfg.bind}
      port ${toString cfg.port}
      dir ${cfg.dataDir}
      logfile "${cfg.dataDir}/valkey.log"
      pidfile "${cfg.dataDir}/valkey.pid"
      aclfile ${config.xdg.configHome}/valkey/users.acl
    '';

    # Valkey user service
    systemd.user.services.valkey = {
      Unit = {
        Description = "Valkey user-level key-value store";
        After = [ "network.target" ];
      };

      Service = {
        ExecStart = lib.concatStringsSep " " (
          [ "${pkgs.valkey}/bin/valkey-server" ]
          ++ optionals (cfg.configFile != null) [ "${cfg.configFile}" ]
          ++ optionals (cfg.configFile == null) [ "${config.xdg.configHome}/valkey/valkey.conf" ]
        );
        WorkingDirectory = cfg.dataDir;
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # CLI tools
    home.packages = [ pkgs.valkey ];
  };
}
