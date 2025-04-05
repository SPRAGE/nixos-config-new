{ config, lib, pkgs, ... }:

let
  cfg = config.services.sambaAdvanced;
in {
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
        "server string" = "smbnix";
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
      default = {};
      description = "A set of share definitions (e.g. public/private).";
    };

    enableWSDD = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable WSDD for Windows network discovery.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.samba = {
      enable = true;
      settings = {
        global = cfg.globalConfig;
        shares = lib.mapAttrs (_: lib.mkIniSection) cfg.shares;
      };
      openFirewall = cfg.openFirewall;
    };

    services.samba-wsdd = lib.mkIf cfg.enableWSDD {
      enable = true;
      openFirewall = cfg.openFirewall;
    };

    networking.firewall.enable = true;
    networking.firewall.allowPing = true;
  };
}
