fromYaml-repo:
{ pkgs, lib, ... }:
let
  msg = import ./msg.nix;
  fromYaml = import "${fromYaml-repo}/fromYaml.nix" { inherit lib; };
  _base-imports = { inherit lib pkgs msg fromYaml; };
  util = import ./util.nix _base-imports;
  colors = import ./colors.nix (_base-imports // util);
  mk-theme = import ./mk-theme.nix (_base-imports // util);
  mk-scheme-attrs = import ./mk-scheme-attrs.nix (_base-imports // util // colors // mk-theme);
in {
  inherit (mk-scheme-attrs) mkSchemeAttrs;
}
