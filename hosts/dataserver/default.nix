{
  pkgs,
  config,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    inputs.disko.nixosModules.disko
    (import ../disks/lvm-btrfs.nix {
      disks = [ "/dev/nvme0n1" ];
      swapSize = "8G";
    })
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
  };


services.sambaAdvanced = {
  enable = true;

  shares = {
    public = {
      path = "/mnt/shaun";
      forceUser = "shaun";
    };
    private = {
      path = "/mnt/karan";
      forceUser = "karan";
    };
  };
};
  
  # enable = true;
#   securityType = "user";
#   openFirewall = true;
#   settings = {
#     global = {
#       "workgroup" = "WORKGROUP";
#       "server string" = "smbnix";
#       "netbios name" = "smbnix";
#       "security" = "user";
#       #"use sendfile" = "yes";
#       #"max protocol" = "smb2";
#       # note: localhost is the ipv6 localhost ::1
#       "hosts allow" = "192.168.0. 127.0.0.1 localhost";
#       "hosts deny" = "0.0.0.0/0";
#       "guest account" = "nobody";
#       "map to guest" = "bad user";
#     };
#     "public" = {
#       "path" = "/mnt/shaun";
#       "browseable" = "yes";
#       "read only" = "no";
#       "guest ok" = "no";
#       "create mask" = "0644";
#       "directory mask" = "0755";
#       "force user" = "shaun";
#       # "force group" = "groupname";
#     };
#     "private" = {
#       "path" = "/mnt/karan";
#       "browseable" = "yes";
#       "read only" = "no";
#       "guest ok" = "no";
#       "create mask" = "0644";
#       "directory mask" = "0755";
#       "force user" = "karan";
#       # "force group" = "groupname";
#     };
#   };
# };

# services.samba-wsdd = {
#   enable = true;
#   openFirewall = true;
# };

# networking.firewall.enable = true;
# networking.firewall.allowPing = true;

  modules.hardware = {

    cpu.type = "intel";
    sound.enable = true;
    mounts = {
      enable = true;

      disks = [
        {
          mountPoint = "/mnt/karan";
          uuid = "7D133D5F1C140076"; # Replace with your disk's UUID
          fsType = "ntfs-3g";
          options = [
            "rw"
            "nofail"
          ];
        }

        {
          mountPoint = "/mnt/shaun";
          uuid = "bdfefd75-37a2-4d2b-b6d5-cb14d5396d2d"; # Replace with your disk's UUID
          fsType = "ext4";
          options = [
            "rw"
            "nofail"
          ];
        }

        {
          mountPoint = "/mnt/hdd";
          uuid = "C252DCB252DCAC83"; # Replace with your disk's UUID
          fsType = "ntfs-3g";
          options = [
            "rw"
            "nofail"
          ];
        }
      ];
    };
  };

  networking = {
    hostName = "datasever";
    interfaces.enp2s0.wakeOnLan.enable = true;
  };

  virtualisation.docker = {
    enable = true;
  };

  modules = {

    roles = {
      server.enable = true;
    };

    os = {
      mainUser = "pai";
      users = [
        "pai"
      ];
      additionalGroups = [ "docker" ];

      otherUsers = {
        shaun = [ "sambashare" ];
        karan = [ "sambashare" ];

      };
      autoLogin = false;
    };

    networking.optomizeTcp = true;

    boot = {
      enableKernelTweaks = true;
      impermanence.enable = false;
    };
  };

  hardware = {
    # Udev rules for vial
    keyboard.qmk.enable = true;

  };

}
