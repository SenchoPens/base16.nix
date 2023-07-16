let
  ending = "Please consult https://github.com/SenchoPens/base16.nix/tree/main#%EF%B8%8F-troubleshooting";
in builtins.mapAttrs (_: msg: "${msg}${ending}") {
  scheme-check-failed = ''
    Error (base16.nix): A scheme does not follow base16 format or was incorrectly parsed.
  '';
  config-check-failed = ''
    Warning (base16.nix): A config.yaml does not follow base16 conventions or was incorrectly parsed.
    Defaulting to an empty extension.
  '';
  bad-mkSchemeAttrs-input = ''
    Error (base16.nix): Processing the input argument of the `mkSchemeAttrs` failed.
  '';
} // {
  incorrect-parsing-detected = yaml-filename: ''
    Error (base16.nix): ${yaml-filename} was parsed incorrectly during nix evaluation.
    ${ending}'';
  no-ifd-failed = "Warning (base16.nix): failed to parse YAML file without an IFD.";
}
