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
              description = "Path to directory.";
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
    users.users.samba-share = {
      isSystemUser = true;
      home = "/var/empty";
    };

    services.samba = {
      enable = true;
      securityType = "user";
      extraConfig = ''
        map to guest = never
        obey pam restrictions = no
        guest ok = no
      '';

      shares = lib.listToAttrs (
        map (share: {
          name = share.name;
          value = {
            path = share.path;
            writable = true;
            browseable = true;
            validUsers = share.allowedUsers;
            "force user" = "samba-share";
          };
        }) cfg.shares
      );
    };

    systemd.tmpfiles.rules = map (share: "d ${share.path} 0755 samba-share samba-share") cfg.shares;

    networking.firewall.allowedTCPPorts = [
      139
      445
    ];
    networking.firewall.allowedUDPPorts = [
      137
      138
    ];

    environment.systemPackages = with pkgs; [ samba ];

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
