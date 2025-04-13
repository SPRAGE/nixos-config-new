{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.modules.services.auth-server;
in
{
  options.modules.services.auth-server = {
    enable = mkEnableOption "Enable Rust-based Auth Server as a user service";

    package = mkOption {
      type = types.package;
      description = "The auth-server package to run.";
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Optional TOML config file for auth-server.";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.auth-server = {
      Unit = {
        Description = "User-space Rust Auth Server";
        After = [ "network.target" ];
      };

      Service = {
        ExecStart = lib.concatStringsSep " " (
          [ "${cfg.package}/bin/auth-server" ]
          ++ lib.optionals (cfg.configFile != null) [
            "--config"
            "${cfg.configFile}"
          ]
        );
        Restart = "on-failure";
        Environment = [
          "LD_LIBRARY_PATH=${pkgs.openssl.out}/lib"
          "RUST_LOG=error"

        ];
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
