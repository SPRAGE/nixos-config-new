{
  inputs,
  self,
  location,
  lib',
  ...
}:
let
  inherit (inputs.nixpkgs.lib) concatLists nixosSystem;

  # combine hm flake input and the home module to be imported together
  homeManager = [
    inputs.home-manager.nixosModules.home-manager
    ../modules/home # home-manager configurations for hosts that need home-manager
    { nixpkgs.overlays = [ inputs.hyprpanel.overlay ]; }
  ];

  specialArgs = {
    inherit
      inputs
      self
      lib'
      location
      ;
      nix-stable = import inputs.nixpkgs-stable {
      system = "x86_64-linux"; # or detect dynamically
      config.allowUnfree = true;
    };
  };
in
{
  # Desktop
  shaundesk = nixosSystem {
    inherit specialArgs;
    # Modules that are used
    modules = [
      ./shaundesk
      ../modules/nixos
    ] ++ concatLists [ homeManager ];
  };

  # shaunoffice
  shaunoffice = nixosSystem {
    inherit specialArgs;
    # Modules that are used
    modules = [
      ./shaunoffice
      ../modules/nixos
    ] ++ concatLists [ homeManager ];
  };

  # dataserver
  dataserver = nixosSystem {
    inherit specialArgs;
    # Modules that are used
    modules = [
      ./dataserver
      ../modules/nixos
    ] ++ concatLists [ homeManager ];
  };
}
