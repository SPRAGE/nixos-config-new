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

  modules.hardware.mounts = {
    enable = true;

    disks = [
      {
        mountPoint = "/mnt/karan";
        uuid = "7D133D5F1C140076"; # Replace with your disk's UUID
        fsType = "ntfs-3g";
        options = [ "rw" "nofail" ];
      }

      {
        mountPoint = "/mnt/shaun";
        uuid = "bdfefd75-37a2-4d2b-b6d5-cb14d5396d2d"; # Replace with your disk's UUID
        fsType = "ext4";
        options = [ "rw" "nofail" ];
      }

      {
        mountPoint = "/mnt/hdd";
        uuid = "C252DCB252DCAC83"; # Replace with your disk's UUID
        fsType = "ntfs-3g";
        options = [ "rw" "nofail" ];
      }
    ];
  };

  networking = {
    hostName = "datasever";
    interfaces.enp2s0.wakeOnLan.enable = true;
  };

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };


  modules = {

    roles = {
      server.enable = true;
    };

    hardware = {
      cpu.type = "intel";
      sound.enable = true;

    };

    # display = {
    #   gpuAcceleration.enable = true;
    #   desktop = {
    #     enable = true;
    #     windowManager = "hyprland";
    #     hyprland.enable = true;
    #   };
    #   monitors = [
    #     {
    #       name = "HDMI-2";
    #       resolution = "1920x1080";
    #       position = "0x0";
    #       refreshRate = 60;
    #       scale = "1";
    #       primary = true;
    #       workspaces = [
    #         1
    #         3
    #         5
    #         7
    #         9
    #       ];
    #     }
    #     {
    #       name = "DP-1";
    #       resolution = "1920x1080";
    #       scale = "1";
    #       refreshRate = 60;
    #       position = "1920x0";
    #       workspaces = [
    #         2
    #         4
    #         6
    #         8
    #         10
    #       ];
    #     }
    #   ];
    # };

    programs = {
      ntfs-3g.enable = true;
    };

    os = {
      mainUser = "pai";
      users = [ "pai" ];
      extraGroups = [ "wheel" "audio" "docker" ]
      ++ lib.optionals config.networking.networkmanager.enable [ "networkmanager" ];
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
