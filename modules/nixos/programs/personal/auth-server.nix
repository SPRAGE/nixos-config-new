{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.services.auth-server;
  authServerPkg = cfg.package or (throw "services.auth-server.package is required");
in {
  options.services.auth-server = {
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
  };

  config = lib.mkIf cfg.enable {
    users.groups.auth = {};
    users.users.auth = {
      isSystemUser = true;
      group = "auth";
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
          ++ lib.optionals (cfg.configFile != null) [ "--config" "${cfg.configFile}" ]
        );

        Restart = "on-failure";
        User = "auth";
        Group = "auth";

        # Runtime dirs
        WorkingDirectory = "/var/lib/auth-server";
        StateDirectory = "auth-server";

        # For OpenSSL dynamic linking
        Environment = "LD_LIBRARY_PATH=${pkgs.openssl.out}/lib";

        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
  };
}
