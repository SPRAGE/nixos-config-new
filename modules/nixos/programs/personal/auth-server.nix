{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.personal.auth-server;
in
{
  options.modules.programs.personal.auth-server = {

    enable = lib.mkEnableOption "Enable the auth-server service";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The auth-server package to run as a system service.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "authserver";
      description = "User under which the auth-server runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = cfg.user;
      description = "Group under which the auth-server runs.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8443;
      description = "TCP port the auth-server listens on.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra command-line arguments passed to the auth-server binary.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to open the specified port in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
    };

    users.groups.${cfg.group} = { };

    systemd.services.auth-server = {
      description = "Auth Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/auth-server --port ${toString cfg.port} ${lib.concatStringsSep " " cfg.extraArgs}";
        Restart = "always";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = "/";
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        Environment = "LD_LIBRARY_PATH=${pkgs.openssl.out}/lib";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
