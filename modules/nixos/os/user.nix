{ pkgs, config, lib, ... }:

let
  inherit (lib) mkOption types optionals mapAttrs mkMerge;
  user = config.modules.os.mainUser;

  # all user names
  allUsers = [ user ] ++ builtins.attrNames config.modules.os.otherUsers;

  # group for each user
  userGroups = builtins.listToAttrs (map (u: {
    name = u;
    value = {};
  }) allUsers);
in
{
  options.modules.os = {
    users = mkOption {
      type = with types; listOf str;
      default = [ "shaun" ];
      description = "A list of Home Manager users on the system.";
    };

    mainUser = mkOption {
      type = types.enum config.modules.os.users;
      default = builtins.elemAt config.modules.os.users 0;
      description = ''
        The main system user. This user is created with full access (wheel, etc.)
        and usually managed by Home Manager.
      '';
    };

    autoLogin = mkOption {
      type = types.bool;
      default = false;
      description = "Enable automatic login (useful for FDE systems).";
    };

    additionalGroups = mkOption {
      type = with types; listOf str;
      default = [];
      description = "Extra groups for the main user (e.g. docker, video, etc.).";
    };

    otherUsers = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = {};
      description = ''
        A set of additional system-only users (not managed by Home Manager).
        Keys are usernames; values are lists of extra groups.
      '';
    };
  };

  config = {
    users.mutableUsers = true;

    users.users = mkMerge [
      # Main user
      {
        ${user} = {
          isNormalUser = true;
          shell = pkgs.zsh;
          # initialPassword = "changeme"; # Replace with hashedPasswordFile for production
          hashedPasswordFile = config.sops.secrets."users.${user}".path;
          group = user;
          extraGroups = [
            "wheel"
          ] ++ optionals config.networking.networkmanager.enable [ "networkmanager" ]
            ++ config.modules.os.additionalGroups;
        };
      }

      # System-only users
      (mapAttrs (name: groups: {
        isSystemUser = true;
        createHome = false;
        home = "/var/empty";
        group = name;
        description = "System user from modules.os.otherUsers";
        extraGroups = groups;
      }) config.modules.os.otherUsers)
    ];

    # Add a matching group for each user
    users.groups = userGroups;

    warnings = optionals (config.modules.os.users == [ ]) [
      ''
        No users are defined in modules.os.users — your system may be inaccessible!
        Define at least one user using `modules.os.users` and `modules.os.mainUser`.
      ''
    ];
  };
}
