{
  description = "Nixos System Configuration";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hyprland.url = "git+https://github.com/hyprwm/Hyprland/?submodules=1/d26439a0fe5594fb26d5a3c01571f9490a9a2d2c";
    hyprpanel = {
      url = "github:Jas-SinghFSU/HyprPanel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # declareable filesystem
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # A tree-wide formatter
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # database for comma
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # get colors from wallpaper
    matugen = {
      url = "github:InioX/matugen";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # plugin to show the starship prompt in yazi
    starship-yazi = {
      url = "github:Rolv-Apneseth/starship.yazi";
      flake = false;
    };
    solaar = {
      url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz"; # For latest stable version
      #url = "https://flakehub.com/f/Svenum/Solaar-Flake/0.1.1.tar.gz"; # uncomment line for solaar version 1.1.13
      #url = "github:Svenum/Solaar-Flake/main"; # Uncomment line for latest unstable version
      inputs.nixpkgs.follows = "nixpkgs";
    };


    # Color theming
    stylix.url = "github:danth/stylix";
    # persist files on boot
    impermanence.url = "github:nix-community/impermanence";
    # create nix project automatically
    dev-assistant.url = "github:spector700/DevAssistant";
    # My app launcher
    lumastart.url = "github:spector700/lumastart";
    # my neovim flake
    nvix.url = "github:SPRAGE/nixvim";
    # # gaming tweaks and addons
    # gaming.url = "github:fufexan/nix-gaming";

    # my sops-nix private repo
    #nix-secrets = {
    #  url = "git+ssh://git@github.com/SPRAGE/nix-secrets.git?ref=main&shallow=1";
    #  flake = false;
    #};
    #Github private repos
    auth-server = {
      url = "git+ssh://git@github.com/SPRAGE/auth-server.git?ref=master";
    };

    analysis-server = {
      url = "git+ssh://git@github.com/SPRAGE/analysis-server.git?ref=main";
    };
    ingestion-server = {
      url = "git+ssh://git@github.com/SPRAGE/ingestion-service.git?ref=main";
    };
    websocket-server = {
      url = "git+ssh://git@github.com/SPRAGE/websocket-client.git?ref=main";
    };
    index-frontend = {
      url = "git+ssh://git@github.com/SPRAGE/index_frontend.git?ref=websocket-source";
    };
    internal-websocket = {
      url = "git+ssh://git@github.com/SPRAGE/internal-websocket.git?ref=main";
    };

  };

  outputs = inputs@{ self, flake-parts, ... }:
    let
      lib' = import ./lib;
      user = "shaun";
      location = "/home/${user}/nixos-config";

      # --- Auto-detect hosts ---
      hostDirs = builtins.filter
        (name:
          let path = ./hosts + "/${name}";
          in builtins.pathExists (path + "/default.nix") && name != "disks"
        )
        (builtins.attrNames (builtins.readDir ./hosts));

      homeManager = [
        inputs.home-manager.nixosModules.home-manager
        ./modules/home
      ];

      specialArgs = {
        inherit inputs self lib' location;
        nix-stable = import inputs.nixpkgs-stable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      };

      mkHost = name: {
        name = name;
        value = inputs.nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            (./hosts + "/${name}")
            ./modules/nixos
          ] ++ homeManager;
        };
      };

      nixosConfigurations = builtins.listToAttrs (map mkHost hostDirs);

    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule
        ./flake
        ./pkgs
      ];

      flake = {
        nixosConfigurations = nixosConfigurations;
      };
    };
}
