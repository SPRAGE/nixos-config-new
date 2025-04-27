{ config, lib, pkgs, ... }:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    concatStringsSep;

  cfg = config.modules.services.valkey;

  aclFilePath = "${config.xdg.configHome}/valkey/users.acl";
  confFilePath = "${config.xdg.configHome}/valkey/valkey.conf";

  generatedConf = ''
    bind ${concatStringsSep " " cfg.bind}
    port ${toString cfg.port}
    dir ${cfg.dataDir}
    logfile "${cfg.dataDir}/valkey.log"
    pidfile "${cfg.dataDir}/valkey.pid"
    aclfile ${aclFilePath}

    # Disable persistence
    save ""
    appendonly no

    daemonize no
    databases 16
    always-show-logo no
    lazyfree-lazy-eviction yes
    lazyfree-lazy-expire yes
    lazyfree-lazy-server-del yes
    replica-lazy-flush yes
    lazyfree-lazy-user-del yes
    lazyfree-lazy-user-flush yes
  '';

in
{
  options.modules.services.valkey = {
    enable = mkEnableOption "Enable Valkey (user-level)";

    dataDir = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.local/share/valkey";
      description = "Data directory for Valkey.";
    };

    port = mkOption {
      type = types.port;
      default = 6379;
      description = "Port Valkey should listen on.";
    };

    bind = mkOption {
      type = types.listOf types.str;
      default = [ "127.0.0.1" ];
      description = "IP addresses Valkey should bind to.";
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

    # Generate ACL file
    xdg.configFile."valkey/users.acl".text = mkIf (cfg.aclUsers != [ ] || cfg.disableDefaultUser) (
      let
        userLines = map (u: "user ${u.name} on #${u.hash} ${u.acl}") cfg.aclUsers;
        defaultLine = if cfg.disableDefaultUser then [ "user default off" ] else [ ];
      in
        concatStringsSep "\n" (defaultLine ++ userLines)
    );

    # Generate full valkey.conf dynamically
    xdg.configFile."valkey/valkey.conf".text = generatedConf;

    # User-level Valkey systemd service
    systemd.user.services.valkey = {
      Unit = {
        Description = "Valkey user-level key-value store";
        After = [ "network.target" ];
      };

      Service = {
        ExecStart = "${pkgs.valkey}/bin/valkey-server ${confFilePath}";
        WorkingDirectory = cfg.dataDir;
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "multi-user.target" ];
      };
    };

    # CLI tools
    home.packages = [ pkgs.valkey ];
  };
}