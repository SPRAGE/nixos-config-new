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
      50001 # analysis server
      50002 # ingestion server
      9094 # Kafka external
      9092 # Kafka internal
      2181 # Zookeeper
      8085 # Zookeeper AdminServer
      8086 # Kafka UI

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
