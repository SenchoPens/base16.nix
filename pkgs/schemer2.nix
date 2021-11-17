{ pkgs, inputs, ... }:
let
  schemer2 = pkgs.buildGoPackage rec {
    pname = "schemer2";
    version = "0.1";

    goPackagePath = "github.com/thefryscorer/schemer2";

    src = inputs.schemer2;
  };
in schemer2
