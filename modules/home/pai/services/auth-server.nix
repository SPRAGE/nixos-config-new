{ config, lib, pkgs, auth-server, ... }:

let
  cfg = config.services.auth-server;
in
{
  options.services.auth-server = {
    enable = lib.mkEnableOption "Enable the Rust Auth Server";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      auth-server.packages.${pkgs.system}.default
    ];

    systemd.user.services.auth-server = {
      Unit = {
        Description = "Rust Auth Server";
        After = [ "network.target" ];
      };
      Service = {
        ExecStart = "${auth-server.packages.${pkgs.system}.default}/bin/auth-server";
        Restart = "on-failure";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
