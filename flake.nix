{
  description = "Nix utility functions to configure base16 themes";

  inputs = {
    fromYaml = {
      url = "github:SenchoPens/fromYaml";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, fromYaml, ... }:
    let
      forAllSystems = f:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ] (system: f nixpkgs.legacyPackages.${system});
    in
    {
      lib = import ./lib fromYaml;

      nixosModule = import ./module.nix self;

      homeManagerModule = self.nixosModule;

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
