{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    ;
  cfg = config.modules.shell.git;
in
{
  options.modules.shell.git = {
    enable = mkEnableOption "Enable Git configuration";

    userName = mkOption {
      type = types.str;
      default = "Your Name";
      description = "Git username";
    };

    userEmail = mkOption {
      type = types.str;
      default = "you@example.com";
      description = "Git email address";
    };

    signingKeyPath = mkOption {
      type = types.path;
      default = config.home.homeDirectory + "/.ssh/gitkey";
      description = "Path to SSH signing key for Git commits";
    };
  };

  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      lfs.enable = true;

      inherit (cfg) userName;
      inherit (cfg) userEmail;

      extraConfig = {
        init.defaultBranch = "main";
        core.askPass = "";
        diff.colorMoved = "default";

        commit.gpgSign = true;
        gpg.format = "ssh";
        user.signingkey = cfg.signingKeyPath;

        push = {
          default = "current";
          followTags = true;
          autoSetupRemote = true;
        };

        signing = {
          signByDefault = true;
          key = cfg.signingKeyPath;
        };
      };

      ignores = [
        ".direnv"
        "result"
        "node_modules"
      ];
    };
  };
}
