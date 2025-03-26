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
    #For openrgb with gigabyte motherboard
    #kernelParams = [ "acpi_enforce_resources=lax" ];
  };

  networking = {
    hostName = "dataserver";
    interfaces.enp2s0.wakeOnLan.enable = true;
  };

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
      cpu.type = "intel";
      # gpu.type = "amd";
      sound.enable = true;
    };

    display = {
      gpuAcceleration.enable = false;
      # desktop.hyprland.enable = ;

      # monitors = [
      #   {
      #     name = "DP-3";
      #     resolution = "2560x1080";
      #     position = "0x0";
      #     refreshRate = 75;
      #     scale = "1";
      #     primary = true;
      #     workspaces = [ 2 ];
      #   }
      #   {
      #     name = "DP-2";
      #     resolution = "1920x1080";
      #     scale = "1";
      #     refreshRate = 60;
      #     rotation = "transform,1";
      #     position = "-1080x-600";
      #     workspaces = [ 1 ];
      #   }
      #   {
      #     name = "HDMI-A-1";
      #     resolution = "1920x1080";
      #     scale = "1";
      #     refreshRate = 60;
      #     position = "2560x-100";
      #     workspaces = [ 3 ];
      #   }
      # ];
    };

    # programs = {
    #   thunar.enable = true;
    # };

    os = {
      mainUser = "pai";
      users = [ "pai" ];
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
