{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    mkForce
    types
    ;
  cfg = config.modules.shell.gpg;

  pinentryMap = {
    gnome3 = pkgs.pinentry-gnome3;
    qt = pkgs.pinentry-qt;
    tty = pkgs.pinentry;
  };

  pinentryPkg = pinentryMap.${cfg.pinentry or "gnome3"};
in
{
  options.modules.shell.gpg = {
    enable = mkEnableOption "Enable GPG and gpg-agent setup";

    enableSshSupport = mkOption {
      type = types.bool;
      default = true;
      description = "Enable SSH agent support in gpg-agent.";
    };

    pinentry = mkOption {
      type = types.enum [
        "gnome3"
        "qt"
        "tty"
      ];
      default = "gnome3";
      description = "Which pinentry program to use.";
    };
  };

  config = mkIf cfg.enable {
    services.gpg-agent = mkIf pkgs.stdenv.hostPlatform.isLinux {
      enable = true;
      enableBashIntegration = config.programs.bash.enable;
      enableFishIntegration = config.programs.fish.enable;
      enableZshIntegration = config.programs.zsh.enable;
      enableNushellIntegration = config.programs.nushell.enable;
      pinentryPackage = pinentryPkg;
      enableScDaemon = true;
      inherit (cfg) enableSshSupport;

      defaultCacheTtl = 1209600;
      defaultCacheTtlSsh = 1209600;
      maxCacheTtl = 1209600;
      maxCacheTtlSsh = 1209600;

      extraConfig = "allow-preset-passphrase";
    };

    systemd.user.services.gpg-agent.Unit.RefuseManualStart = mkForce false;

    programs.gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
      settings = {
        keyserver = "keys.openpgp.org";
        personal-cipher-preferences = "AES256 AES192 AES";
        personal-digest-preferences = "SHA512 SHA384 SHA256";
        personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
        default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
        cert-digest-algo = "SHA512";
        s2k-digest-algo = "SHA512";
        s2k-cipher-algo = "AES256";
        charset = "utf-8";
        fixed-list-mode = "";
        no-comments = "";
        no-emit-version = "";
        no-greeting = "";
        keyid-format = "0xlong";
        list-options = "show-uid-validity";
        verify-options = "show-uid-validity";
        with-fingerprint = "";
        require-cross-certification = "";
        no-symkey-cache = "";
        use-agent = "";
        armor = "";
        throw-keyids = "";
      };
    };
  };
}
