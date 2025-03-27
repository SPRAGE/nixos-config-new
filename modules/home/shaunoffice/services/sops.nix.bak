{ inputs, config, ... }:
let
  secretsPath = builtins.toString inputs.nix-secrets;
  secretsFile = "${secretsPath}/secrets.yaml";
  inherit (config.home) homeDirectory;
  # Parameter to easily disable sops temporarily
  disableSops = true; # Set to true to disable sops
in
{
  imports = if !disableSops then [ inputs.sops-nix.homeManagerModules.sops ] else [];

  # Only configure sops if not disabled
  config = if !disableSops then {
    sops = {
      # This is the ta/dev key and needs to have been copied to this location on the host
      age.keyFile = "${homeDirectory}/.config/sops/age/keys.txt";

      defaultSopsFile = "${secretsFile}";
      validateSopsFiles = false;

      secrets = {
        "private_keys/spector" = {
          path = "${homeDirectory}/.ssh/id_spector";
        };
      };
    };
  } else {};
}
