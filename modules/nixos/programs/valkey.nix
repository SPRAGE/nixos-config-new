{ config, pkgs, lib, ... }:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    concatStringsSep;

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

    users = mkOption {
      type = types.listOf (types.submodule {
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
            description = "ACL string (permissions, key patterns, etc).";
          };
        };
      });
      default = [ ];
      description = "List of Valkey users with hashed passwords and custom ACLs.";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra lines for valkey.conf.";
    };
  };

  config = mkIf cfg.enable {
    users.groups.valkey = { };

    users.users.valkey = {
      isSystemUser = true;
      group = "valkey";
      description = "Valkey server user";
      home = cfg.dataDir;
    };

    # Generate ACL file with per-user custom ACLs
    environment.etc."valkey/users.acl".text = concatStringsSep "\n" (
      map (u: "user ${u.name} on #${u.hash} ${u.acl}") cfg.users
    );

    environment.etc."valkey/valkey.conf".text = ''
      port ${toString cfg.port}
      dir ${cfg.dataDir}
      bind 127.0.0.1
      aclfile /etc/valkey/users.acl
      ${cfg.extraConfig}
    '';

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 valkey valkey - -"
    ];

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

    boot.kernel.sysctl."vm.overcommit_memory" = 1;

    environment.systemPackages = [ pkgs.valkey ];
  };
}
