{ lib, pkgs, inputs, ... }:
with lib;
let
  getScheme = { base00, base01, base02, base03, base04, base05, base06, base07
    , base08, base09, base0A, base0B, base0C, base0D, base0E, base0F, ... }@numbered:
  rec {
    numberedList = [ base00 base01 base02 base03 base04 base05 base06 base07 base08 base09 base0A base0B base0C base0D base0E base0F ];

    inherit numbered;
    numberedHashtag = builtins.mapAttrs (_: v: "#" + v) numbered;
    numberedDec = builtins.mapAttrs (name: color: colorHex2Dec color) numbered;

    named = getNamed numbered;
    namedHashtag = getNamed numberedHashtag;
    namedDec = getNamed numberedDec;
  };

  getNamed = { base00, base01, base02, base03, base04, base05, base06, base07
      , base08, base09, base0A, base0B, base0C, base0D, base0E, base0F, ... }: {
    bg = base00;
    dark = base01;

    alt = base02;
    gray = base03;

    dark_fg = base04;
    default_fg = base05;
    light_fg = base06;

    fg = base07;

    red = base08;
    orange = base09;
    yellow = base0A;
    green = base0B;
    cyan = base0C;
    blue = base0D;
    purple = base0E;
    dark_orange = base0F;
  };

  fromYAML = yaml:
    builtins.fromJSON (builtins.readFile (pkgs.stdenv.mkDerivation {
      name = "fromYAML";
      phases = [ "buildPhase" ];
      buildPhase = "echo '${yaml}' | ${pkgs.yaml2json}/bin/yaml2json > $out";
    }));

  fromYAMLPath = path-to-yaml: fromYAML (builtins.readFile path-to-yaml);

  getSchemeFromYAMLPath = path-to-yaml: getScheme (fromYAMLPath path-to-yaml);

  hex2int = s: with builtins; if s == "" then 0 else let l = stringLength s - 1; in 
    (hex2decDigits."${substring l 1 s}" + 16 * (hex2int (substring 0 l s)));

  hex2decDigits = rec {
    "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4; "5" = 5; "6" = 6; "7" = 7; "8" = 8; "9" = 9;
    a = 10; b = 11; c = 12; d = 13; e = 14; f = 15; 
    A = a; B = b; C = c; D = d; E = e; F = f;
  };

  splitHex = hexStr:
    map (x: builtins.elemAt x 0) (builtins.filter (a: a != "" && a != [ ])
      (builtins.split "(.{2})" (builtins.substring 1 6 hexStr)));

  doubleDigitHexToDec = hex:
    16 * hex2decDigits."${builtins.substring 0 1 hex}"
    + hex2decDigits."${builtins.substring 1 2 hex}";

  colorHex2Dec = color:
    builtins.concatStringsSep ","
    (map (x: toString (doubleDigitHexToDec x)) (splitHex color));

  buildTheme = scheme: template: brightness:
    pkgs.runCommand "${scheme}-theme" {} ''
    export HOME=$(pwd)/home; mkdir -p $HOME
    ${pkgs.base16-builder}/bin/base16-builder \
      --scheme ${scheme} \
      --template ${template} \
      --brightness ${brightness} \
      > $out
    '');

in {
  inherit
    buildTheme
    fromYAML
    fromYAMLPath
    getScheme
    getSchemeFromYAMLPath
}
