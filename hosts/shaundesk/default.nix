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
      swapSize = "32G";
    })
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    #For openrgb with gigabyte motherboard
    #kernelParams = [ "acpi_enforce_resources=lax" ];
  };

  networking.hostName = "shaundesk";
  networking.interfaces.enp8s0.wakeOnLan.policy = true;

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # home-manager modules
  home-manager.users.${config.modules.os.mainUser}.config.modules = {
    theme.wallpaper = ../../modules/home/shaun/theming/wallpaper;
  };

  modules = {
    roles = {
      desktop.enable = true;
      development.enable = true;
      gaming.enable = true;
    };

    hardware = {
      cpu.type = "amd";
      gpu.type = "amd";
      sound.enable = true;
    };

    display = {
      gpuAcceleration.enable = true;
      desktop.hyprland.enable = true;

      monitors = [
        {
          name = "DP-2";
          scale = "1";
          rotation = "transform,1";
          position = "0x0";
          workspaces = [ 1 ];
        }
        {
          name = "DP-3";
          resolution = "2560x1080";
          position = "1080x680";
          refreshRate = 75;
          scale = "1";
          primary = true;
          workspaces = [ 2 ];
        }
        {
          name = "HDMI-A-1";
          resolution = "1920x1080";
          scale = "1";
          refreshRate = 60;
          position = "3640x280";
          workspaces = [ 3 ];
        }
      ];
    };

    programs = {
      thunar.enable = true;
    };

    os = {
      mainUser = "shaun";
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
