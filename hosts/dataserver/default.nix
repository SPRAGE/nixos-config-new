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
    firewall.allowedTCPPorts = [
      8443 # auth-server
      6379 # redis
      8123 # ch http
      9000 # Native TCP protocol (clickhouse-client)
      8123 # HTTP API
      9009 # Interserver communication (for clusters)

    ];

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
      autoLogin = true;
    };
    # programs = {
      
    #   clickhouse = {
    #     enable = true;
    #     dataDir = "/mnt/shaun/clickhouse-data";
    #     disableLogs = true;

    #     users = [
    #       {
    #         name = "shaun";
    #         hash = "5060a3874499a874ae0e6d3d8b576121037d322e97de5632c8726e94c480ae86";
    #         profile = "default";
    #       }
    #       {
    #         name = "default";
    #         hash = "62362d60d7efa6e6844e5ad8621bd5fa57b573d0435e339c1f77feb28ae07cfe";
    #         profile = "readonly";
    #       }
    #       {
    #         name = "read";
    #         hash = "62362d60d7efa6e6844e5ad8621bd5fa57b573d0435e339c1f77feb28ae07cfe";
    #         profile = "readonly";
    #       }
    #     ];
    #   };

    # };
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
