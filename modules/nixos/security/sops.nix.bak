{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) optionalString;
  isEd25519 = k: k.type == "ed25519";
  getKeyPath = k: k.path;
  keys = builtins.filter isEd25519 config.services.openssh.hostKeys;

  secretsPath = builtins.toString inputs.nix-secrets;

  isPersistence = config.modules.boot.impermanence.enable;
  
  # Parameter to easily disable sops temporarily
  disableSops = true; # Set to true to disable sops
in
{
  imports = if !disableSops then [ inputs.sops-nix.nixosModules.sops ] else [];

  # Only configure sops if not disabled
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
        # automatically import host SSH keys as age keys
        sshKeyPaths = map getKeyPath keys;
        # key that is expected to already be in the file system
        keyFile = "${optionalString isPersistence "/persist"}/var/lib/sops-nix/key.txt";
        # This will generate a new key if the key specified above does not exist
        generateKey = true;
      };

      secrets."users.shaun.password".neededForUsers = true;
    };
  } else {};
}
