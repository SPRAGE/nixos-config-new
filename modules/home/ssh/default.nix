{
  config,
  lib,
  self,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    mkIf
    ;
  cfg = config.modules.shell.ssh;

  # NixOS hostnames used for Match blocks
  nixosHosts = builtins.attrNames self.nixosConfigurations;
in
{
  options.modules.shell.ssh = {
    enable = mkEnableOption "Enable SSH configuration";

    enableAgentForwardingForNixHosts = mkOption {
      type = types.bool;
      default = true;
      description = "Enable SSH agent forwarding to all nixosConfigurations hosts.";
    };

    matchBlocks = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            hostname = mkOption {
              type = types.str;
              description = "The hostname for the SSH match block.";
            };

            user = mkOption {
              type = types.str;
              default = "git";
              description = "The SSH user for the host.";
            };

            identityFile = mkOption {
              type = types.str;
              description = "Path to the identity file (e.g., ~/.ssh/id_ed25519).";
            };

            identitiesOnly = mkOption {
              type = types.bool;
              default = true;
              description = "Only use the specified identity file.";
            };
          };
        }
      );
      default = { };
      description = "Custom SSH match blocks (e.g., GitHub aliases).";
    };
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      hashKnownHosts = true;
      compression = true;
      addKeysToAgent = "yes";

      matchBlocks =
        (lib.mkIf cfg.enableAgentForwardingForNixHosts {
          net = {
            host = builtins.concatStringsSep " " nixosHosts;
            forwardAgent = true;
          };
        })
        // cfg.matchBlocks;
    };
  };
}
