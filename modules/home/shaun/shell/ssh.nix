{ self, ... }:
let
  hostnames = builtins.attrNames self.nixosConfigurations;
in
{
  programs.ssh = {
    enable = true;
    hashKnownHosts = true;
    compression = true;
    matchBlocks = {
      net = {
        host = builtins.concatStringsSep " " hostnames;
        forwardAgent = true;
      };
      # 🐙 GitHub alias using your custom key
      "github-shaun" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/gitkey";
        identitiesOnly = true;
      };
    };
  };
}
