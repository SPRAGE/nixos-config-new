{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) optionalString listToAttrs;

  secretsPath = "${inputs.nix-secrets}/secrets.yaml";
  isPersistence = config.modules.boot.impermanence.enable;

  disableSops = false; # Toggle this to enable/disable SOPS

  # Get all users: main user plus other system-only users
  allUsers =
    [ config.modules.os.mainUser ]
    ++ builtins.attrNames config.modules.os.otherUsers;

  # Generate a secret entry for each user password
  userSecrets = listToAttrs (map (username: {
    name = "users.${username}";
    value = {
      neededForUsers = true;
    };
  }) allUsers);
in
{
  imports = if !disableSops then [ inputs.sops-nix.nixosModules.sops ] else [];

  config = if !disableSops then {
    environment.systemPackages = with pkgs; [
      age
      ssh-to-age
      sops
    ];

    sops = {
      defaultSopsFile = "${secretsPath}/secrets.yaml";
      validateSopsFiles = false;

      age = {
        keyFile = "${optionalString isPersistence "/persist"}/var/lib/sops-nix/key.txt";
        generateKey = false;
        sshKeyPaths = [];
      };

      secrets = userSecrets;
    };
  } else {};
}
