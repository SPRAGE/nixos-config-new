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

  services = {
    # auth-server = {
    #   enable = true;
    # };

    sambaAdvanced = {
      enable = true;

      shares = {
        shaun = {
          path = "/mnt/shaun";
          forceUser = "shaun";
        };
        karan = {
          path = "/mnt/karan";
          forceUser = "karan";
        };
      };
    };
  };

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
    programs = {
      valkey = {
        enable = true;
        disableDefaultUser = true;
        users = [
          {
            name = "read";
            hash = "8877c58975fc1f061338418bc0424b5b08c95ff412dc08a68cfa879f45dbbf10"; # sha256
            acl = "~readonly:* +get +info";
          }
          {
            name = "shaun";
            hash = "a65aaf4f6cd6b72db0280c4f4f0abdee8d65ec047e4a21b7fadb0a4f89f3fb52"; # sha256
            acl = "allcommands allkeys";
          }
        ];
      };
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
