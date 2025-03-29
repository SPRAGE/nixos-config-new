{
  modules.shell.ssh = {
    enable = true;

    matchBlocks = {
      github-shaun = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/gitkey";
      };

      github-work = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/gitkey-work";
      };
    };
  };
}
