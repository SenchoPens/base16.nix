{
  description = "Nix utility functions to configure base16 themes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    lib = (import ./.) { lib = nixpkgs.lib; pkgs = nixpkgs; };
  };
}
