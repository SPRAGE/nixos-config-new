{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  authServerPkg = inputs.auth-server.packages.${pkgs.system}.default;
in
{
  options.services.auth-server = {
    enable = lib.mkEnableOption "Rust-based Auth Server";

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to optional TOML config file passed via --config.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8443;
      description = "Port to expose for incoming HTTPS requests.";
    };
  };

  config = lib.mkIf config.services.auth-server.enable {
    users.users.auth = {
      isSystemUser = true;
      group = "auth";
      home = "/var/lib/auth-server";
      createHome = true;
    };

    users.groups.auth = { };

    environment.systemPackages = [ authServerPkg ];

    networking.firewall.allowedTCPPorts = [ config.services.auth-server.port ];

    systemd.services.auth-server = {
      description = "Rust Auth Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = lib.concatStringsSep " " (
          [ "${authServerPkg}/bin/auth-server" ]
          ++ lib.optional (
            config.services.auth-server.configFile != null
          ) "--config ${config.services.auth-server.configFile}"
        );

        Restart = "always";
        User = "pai";
        WorkingDirectory = "/var/lib/auth-server";
        StateDirectory = "auth-server";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
  };
}
