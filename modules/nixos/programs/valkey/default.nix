{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    concatStringsSep
    ;

  cfg = config.modules.programs.valkey;
in
{
  options.modules.programs.valkey = {
    enable = mkEnableOption "Enable Valkey (Redis-compatible server)";

    configFile = mkOption {
      type = types.path;
      default = ./valkey.conf;
      description = ''
        Path to a custom valkey.conf file.
        It will be copied to /etc/valkey/valkey.conf.
        You are responsible for setting all configuration,
        including aclfile, port, bind address, etc.
      '';
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/valkey";
      description = "Data directory for Valkey persistence.";
    };

    users = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Username for Valkey ACL.";
            };
            hash = mkOption {
              type = types.str;
              description = "SHA-256 hashed password for the user.";
            };
            acl = mkOption {
              type = types.str;
              default = "allcommands allkeys";
              description = "ACL string (permissions, key patterns, etc).";
            };
          };
        }
      );
      default = [ ];
      description = "Optional list of Valkey users with hashed passwords and custom ACLs.";
    };

    disableDefaultUser = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to disable the default Valkey user.";
    };
  };

  config = mkIf cfg.enable {
    # System group and user
    users.groups.valkey = { };

    users.users.valkey = {
      isSystemUser = true;
      group = "valkey";
      description = "Valkey server user";
      home = cfg.dataDir;
    };

    # Copy custom valkey.conf to /etc/valkey
    environment.etc."valkey/valkey.conf".source = cfg.configFile;

    # Conditionally create users.acl if users or disableDefaultUser is set
    environment.etc."valkey/users.acl".text = mkIf (cfg.users != [ ] || cfg.disableDefaultUser) (
      let
        userLines = map (u: "user ${u.name} on #${u.hash} ${u.acl}") cfg.users;
        defaultLine = if cfg.disableDefaultUser then [ "user default off" ] else [ ];
      in
      concatStringsSep "\n" (defaultLine ++ userLines)
    );

    # Ensure data directory exists
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 valkey valkey - -"
    ];

    # systemd service
    systemd.services.valkey = {
      description = "Valkey (Redis-compatible key-value store)";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.valkey}/bin/valkey-server /etc/valkey/valkey.conf";
        User = "valkey";
        WorkingDirectory = cfg.dataDir;
        Restart = "always";
      };
    };

    # Kernel tuning: avoid memory overcommit warning
    boot.kernel.sysctl."vm.overcommit_memory" = 1;

    # Provide valkey CLI tools
    environment.systemPackages = [ pkgs.valkey ];
  };
}
