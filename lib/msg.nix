let
  ending = "Please consult https://github.com/SenchoPens/base16.nix/tree/main#%EF%B8%8F-troubleshooting";
in {
  incorrect-parsing-detected = yaml-filename: ''
    Error (base16.nix): ${yaml-filename} was parsed incorrectly during nix evaluation.
    ${ending}'';
  config-check-failed = target: ''
    Warning (base16.nix): A config.yaml does not contain the target "${target}", does not follow base16 conventions or was incorrectly parsed.
    Defaulting to an empty extension.
    ${ending}'';
  scheme-check-failed = ''
    Error (base16.nix): A scheme does not follow base16 format or was incorrectly parsed.
    ${ending}'';
  bad-mkSchemeAttrs-input = ''
    Error (base16.nix): Processing the input argument of the `mkSchemeAttrs` failed.
    ${ending}'';
  no-ifd-failed = ''
    Warning (base16.nix): failed to parse YAML file without an IFD.
    ${ending}'';
}
