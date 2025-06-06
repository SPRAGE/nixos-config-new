# Git
#
{ config, ... }:
{
  programs = {
    git = {
      enable = true;
      lfs.enable = true;

      extraConfig = {
        init = {
          defaultBranch = "main";
        };
        pull.rebase = true;
        core.askPass = "";

        diff.colorMoved = "default";
        commit.gpgSign = true;
        gpg.format = "ssh";
        user.signingkey = "${config.home.homeDirectory}/.ssh/gitkey";

        push = {
          default = "current";
          followTags = true;
          autoSetupRemote = true;
        };
        signing = {
          signByDefault = true;
          key = "${config.home.homeDirectory}/.ssh/gitkey";
        };
      };
      

      ignores = [
        ".direnv"
        "result"
        "node_modules"
      ];

      userEmail = "shauna.pai@gmail.com";
      userName = "SPRAGE";
    };
  };
}
