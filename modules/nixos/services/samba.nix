{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.sambaShares;
in
{
  options.services.sambaShares = {
    enable = lib.mkEnableOption "Samba with non-system users per share";

    shares = lib.mkOption {
      description = "List of Samba shares with access usernames.";
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Share name.";
            };

            path = lib.mkOption {
              type = lib.types.path;
              description = "Path to directory to share.";
            };

            allowedUsers = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "List of Samba-only users allowed to access this share.";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    # Create system user and group that owns all shares
    users.users.samba-share = {
      isSystemUser = true;
      home = "/var/empty";
      group = "samba-share";
    };

    users.groups.samba-share = { };

    environment.systemPackages = with pkgs; [ samba ];

    services.samba = {
      enable = true;

      settings = {
        global = {
          "server string" = "NixOS Samba Server";
          security = "user";
          "map to guest" = "never";
          "obey pam restrictions" = false;
        };

        shares = builtins.listToAttrs (
          map (share: {
            name = share.name;
            value = lib.mkIniSection {
              path = share.path;
              writable = true;
              browseable = true;
              "valid users" = share.allowedUsers;
              "force user" = "samba-share";
            };
          }) cfg.shares
        );

      };
    };

    # Ensure shared directories exist with correct permissions
    systemd.tmpfiles.rules = map (share: "d ${share.path} 0755 samba-share samba-share") cfg.shares;

    # Open standard Samba ports
    networking.firewall.allowedTCPPorts = [
      139
      445
    ];
    networking.firewall.allowedUDPPorts = [
      137
      138
    ];

    # Optionally create Samba users during activation (uses placeholder password)
    system.activationScripts.sambaUsers = {
      text = ''
        ${lib.concatStringsSep "\n" (
          lib.unique (
            lib.flatten (
              map (
                share:
                map (
                  user: "echo '${user}:yourpassword' | ${pkgs.samba}/bin/smbpasswd -a -s ${user} || true"
                ) share.allowedUsers
              ) cfg.shares
            )
          )
        )}
      '';
    };
  };
}
