{
  description = "Nix utility functions to configure base16 themes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    auto-base16-theme = {
      url = "github:makuto/auto-base16-theme";
      flake = false;
    };
    schemer2 = {
      url = "github:thefryscorer/schemer2";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... } @ inputs:
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        packages = import ./pkgs { inherit pkgs inputs; };
      in {
        lib = import ./. { inherit pkgs inputs; };

        packages = {
          inherit (packages.base16-builder-python) pybase16-builder;
          inherit (packages) auto-base16-theme;
          inherit (packages) schemer2;
        };

        nixosModule = import ./nixos-module.nix { base16-pkgs = pkgs; base16-inputs = inputs; };
        # nixosModule = { ... }: {
        #   imports = [ (import ./nixos-module.nix { base16-pkgs = pkgs; base16-inputs = inputs; }) ];
        # };
        devShell = pkgs.mkShell rec {
          nativeBuildInputs = with pkgs; [
            nixfmt
          ];
        };
      }
    ));
}
