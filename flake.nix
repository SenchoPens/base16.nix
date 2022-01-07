{
  description = "Nix utility functions to configure base16 themes";

  outputs = { self, nixpkgs, ... } @ inputs:
    {
      lib = import ./.;

      nixosModule = import ./module.nix self;

      homeManagerModule = self.nixosModule;
      #
      # devShell = pkgs.mkShell rec {
      #   nativeBuildInputs = with pkgs; [
      #     nixfmt
      #   ];
      # };
    };
}
