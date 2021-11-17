{ pkgs, inputs, ... }:
let
  auto-base16-theme = pkgs.writeShellScriptBin "auto-base16-theme" ''
    ${pkgs.python3Minimal}/bin/python3 ${inputs.auto-base16-theme}/AutoBase16Theme.py "$@"
  '';
in auto-base16-theme
