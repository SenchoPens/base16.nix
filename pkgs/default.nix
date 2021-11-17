{ pkgs, inputs, ... }: {
  base16-builder-python =
    (import ./base16-builder-python.nix) { inherit pkgs inputs; };
  auto-base16-theme = (import ./auto-base16-theme.nix) { inherit pkgs inputs; };
  schemer2 = (import ./schemer2.nix) { inherit pkgs inputs; };
}
