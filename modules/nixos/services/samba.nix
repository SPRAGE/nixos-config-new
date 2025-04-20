{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.sambaAdvanced;
in
{
  options.services.sambaAdvanced = {
    enable = lib.mkEnableOption "Enable Samba file sharing with custom shares";

    shares = lib.mkOption {
      type = with lib.types; attrsOf (submodule {
        options = {
          path = lib.mkOption {
            type = str;
            description = "Path to the directory to share.";
          };
          forceUser = lib.mkOption {
            type = str;
            description = "User to force for access to the share.";
          };
        };
      });
      default = {};
      description = "Custom Samba shares with path and forced user.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.samba = {
      enable = true;
      openFirewall = true;

      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "smbnix";
          "netbios name" = "smbnix";
          "security" = "user";
          "hosts allow" = "192.168.0. 127.0.0.1 localhost";
          "hosts deny" = "0.0.0.0/0";
          "guest account" = "nobody";
          "map to guest" = "bad user";
          "security" = "user";
        };

        # Generate shares from cfg.shares
      } // lib.attrsets.mapAttrs' (name: share:
        lib.nameValuePair name {
          "path" = share.path;
          "browseable" = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
          "force user" = share.forceUser;
        }
      ) cfg.shares;
    };

    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    networking.firewall = {
      enable = true;
      allowPing = true;
    };
  };
}
