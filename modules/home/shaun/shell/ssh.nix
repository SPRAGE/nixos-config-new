{ self, ... }:
let
  hostnames = builtins.attrNames self.nixosConfigurations;
in
{
  programs.ssh = {
    enable = true;
    hashKnownHosts = true;
    compression = true;
    addKeysToAgent = "yes";
    matchBlocks = {
      net = {
        host = builtins.concatStringsSep " " hostnames;
        forwardAgent = true;
      };
      # 🐙 GitHub alias using your custom key
      "github-personal" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/gitkey";
        identitiesOnly = true;
      };
      "github-work" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/gitkey-work";
        identitiesOnly = true;
      };
    };
  };
}
