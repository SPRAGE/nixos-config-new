{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.sambaAdvanced;
in
{
  options.services.sambaAdvanced = {
    enable = lib.mkEnableOption "Enable advanced Samba configuration";

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open firewall ports for Samba and WSDD";
    };

    globalConfig = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        workgroup = "WORKGROUP";
        "server string" = "Samba Server"; # Updated default server string
        "netbios name" = "smbnix";
        security = "user";
        "hosts allow" = "192.168.0. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };
      description = "Global Samba configuration options.";
    };

    shares = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.str);
      default = { };
      description = "A set of share definitions (e.g. public/private).";
      example = {
        "example-share" = {
          "path" = "/path/to/share";
          "browseable" = "true";
          "read only" = "false";
          "guest ok" = "false";
        };
      };
    };

    enableWSDD = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable WSDD for Windows network discovery.";
    };

    enableFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the system firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.samba = {
      enable = true;
      settings = {
        global = cfg.globalConfig;
        shares = cfg.shares;
      };
      openFirewall = cfg.openFirewall;
    };

    services.samba-wsdd = lib.mkIf cfg.enableWSDD {
      enable = true;
      openFirewall = cfg.openFirewall;
    };

    # Make firewall enabling configurable
    networking.firewall.enable = cfg.enableFirewall;
    networking.firewall.allowPing = cfg.enableFirewall;
  };
}
