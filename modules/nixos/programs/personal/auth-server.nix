{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.modules.programs.personal.auth-server;
  authServerPkg = cfg.package or (throw "modules.programs.personal.auth-server.package is required");
in
{
  options.modules.programs.personal.auth-server = {
    enable = lib.mkEnableOption "Enable the Rust-based Auth Server";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The `auth-server` package to run.";
    };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional path to a TOML config file passed via --config.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8443;
      description = "Port to expose for incoming HTTPS requests.";
    };

    runAsUser = lib.mkOption {
      type = lib.types.str;
      default = "auth";
      description = "User under which the auth server should run.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.${cfg.runAsUser} = { };
    users.users.${cfg.runAsUser} = {
      isSystemUser = true;
      group = cfg.runAsUser;
      home = "/var/lib/auth-server";
      createHome = true;
    };

    environment.systemPackages = [ cfg.package ];

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    systemd.services.auth-server = {
      description = "Rust Auth Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = lib.concatStringsSep " " (
          [ "${cfg.package}/bin/auth-server" ]
          ++ lib.optionals (cfg.configFile != null) [
            "--config"
            "${cfg.configFile}"
          ]
        );

        Restart = "on-failure";
        User = cfg.runAsUser;
        Group = cfg.runAsUser;

        WorkingDirectory = "/var/lib/auth-server";
        StateDirectory = "auth-server";

        Environment = "LD_LIBRARY_PATH=${pkgs.openssl.out}/lib";

        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
  };
}
