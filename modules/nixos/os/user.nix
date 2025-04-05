{ pkgs, config, lib, ... }:

let
  inherit (lib) mkOption types optionals mapAttrs;
  user = config.modules.os.mainUser;
in
{
  options.modules.os = {
    users = mkOption {
      type = with types; listOf str;
      default = [ "shaun" ];
      description = "A list of home-manager users on the system.";
    };

    mainUser = mkOption {
      type = types.enum config.modules.os.users;
      default = builtins.elemAt config.modules.os.users 0;
      description = ''
        The username of the main user for your system.

        In case of multiple users, this one will have priority in ordered lists and enabled options.
      '';
    };

    autoLogin = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable passwordless login (e.g. on systems with FDE).
      '';
    };

    additionalGroups = mkOption {
      type = with types; listOf str;
      default = [];
      description = ''
        Extra groups the main user should be a part of.
      '';
    };

    otherUsers = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = {};
      description = ''
        A set of system-only users. Keys are usernames, and values are lists of extra groups.
        These users are created without Home Manager or home directories.
      '';
    };
  };

  config = {
    users.mutableUsers = true;

    users.users.${user} = {
      isNormalUser = true;
      shell = pkgs.zsh;
      initialPassword = "changeme";
      extraGroups = [
        "wheel"
      ] ++ optionals config.networking.networkmanager.enable [ "networkmanager" ]
        ++ config.modules.os.additionalGroups;
    };

    # Create system-only users from `otherUsers` attrset
    users.users = mapAttrs (name: groups: {
      isSystemUser = true;
      createHome = false;
      home = "/var/empty";
      description = "System user created via modules.os.otherUsers";
      extraGroups = groups;
    }) config.modules.os.otherUsers;

    # Warning if no main user is defined
    warnings = optionals (config.modules.os.users == [ ]) [
      ''
        You have not added any users to your system. This may result in an unusable system.

        Consider setting `modules.os.users` and `modules.os.mainUser`.
      ''
    ];
  };
}
