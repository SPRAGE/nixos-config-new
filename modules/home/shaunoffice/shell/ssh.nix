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
      # Individual host configurations with specific users
      "dataserver" = {
        hostname = "dataserver";
        user = "pai";
        forwardAgent = true;
      };
      "shaundesk" = {
        hostname = "shaundesk";
        user = "shaun";
        forwardAgent = true;
      };
      "shaunoffice" = {
        hostname = "shaunoffice";
        user = "shaunoffice";
        forwardAgent = true;
      };
      # 🐙 GitHub alias using your custom key
      "github-shaun" = {
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
