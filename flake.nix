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
    # hyprpanel = {
    #   url = "github:Jas-SinghFSU/HyprPanel";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
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
      inputs.nixpkgs.follows = "nixpkgs";
    };


    # Color theming
    stylix.url = "github:danth/stylix";
    # persist files on boot
    impermanence.url = "github:nix-community/impermanence";
    # # create nix project automatically
    # dev-assistant.url = "github:spector700/DevAssistant";
    # # My app launcher
    # lumastart.url = "github:spector700/lumastart";
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
    trading = {
      url = "git+ssh://git@github.com/SPRAGE/trading.git?ref=main";
    };


    # auth-server = {
    #   url = "git+ssh://git@github.com/SPRAGE/auth-server.git?ref=master";
    # };

    # analysis-server = {
    #   url = "git+ssh://git@github.com/SPRAGE/analysis-server.git?ref=main";
    # };
    # ingestion-server = {
    #   url = "git+ssh://git@github.com/SPRAGE/ingestion-service.git?ref=main";
    # };
    # websocket-server = {
    #   url = "git+ssh://git@github.com/SPRAGE/websocket-client.git?ref=main";
    # };
    # index-frontend = {
    #   url = "git+ssh://git@github.com/SPRAGE/index-frontend.git?ref=main";
    # };
    internal-websocket = {
      url = "git+ssh://git@github.com/SPRAGE/internal-websocket.git?ref=main";
    };
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    let
      # custom lib functions
      lib' = import ./lib;
      # main user for location
      user = "shaun";
      # Location of the nixos config
      location = "/home/${user}/nixos-config";
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      # systems for which the `perSystem` attributes will be built
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        inputs.treefmt-nix.flakeModule

        # the flake utilities
        ./flake
        ./pkgs
      ];
      # perSystem =
      #   { pkgs, system, ... }:
      #   {
      #   };

      flake = {
        # entry-point for nixosConfigurations
        nixosConfigurations = import ./hosts/profiles.nix {
          inherit
            inputs
            self
            lib'
            location
            ;
        };
      };
    };
}
