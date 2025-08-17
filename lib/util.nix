{ lib, pkgs, msg, fromYaml, ... }:
let
  success-monad = 
    let
      res = { success, value, ... }: {
        inherit success value;
        __functor = self: { f, err-msg ? "" }:
          let
            evaled = f value;
            evaled' = if evaled?success then evaled else { success = true; value = evaled; };
            trace-err = if err-msg == "" then (x: x) else builtins.trace err-msg;
            new = if evaled'.success then evaled'
                  else trace-err { success = false; inherit (self) value; };
          in res new;
      };
    in value: res { success = true; inherit value; };

  sm-or = e1': e2': {
    f = value:
      let
        e1 = e1'.f value;
        e2 = e2'.f value;
      in if e1.success then e1 else e2;
  };

  /* Writes a text to file so that the name of the file is short (without hash)
     and with the correct extension.
  */
  writeTextFile' = path: text: ''${pkgs.writeTextDir path text}/${path}'';

  /* Same as writeTextFile', but escaped for use in the builder.
  */
  writeTextFile'' = path: text: ''${pkgs.writeTextDir path text}/${lib.escapeShellArg path}'';

  /* Converts a yaml file to a json file, parseable by builtins.fromJSON.
  */
  yaml2json = yaml: pkgs.stdenv.mkDerivation {
    name = "fromYAML";
    allowSubstitutes = false;
    preferLocalBuild = true;
    nativeBuildInputs = [ pkgs.yaml2json ];
    buildCommand = ''
      yaml2json < ${yaml} > $out
    '';
  };

  /* Simplified tinted-theming 0.11 slugify.
     From Misterio77/nix-colors
  */
  slugify = 
    let
      filterChars = f: str: lib.concatStrings (lib.filter f (lib.stringToCharacters str));
      validChars = lib.stringToCharacters "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890-";
      isValid = x: lib.elem x validChars;
    in str: lib.toLower (filterChars isValid (lib.replaceStrings [" "] ["-"] str)); 

  /* Converts tinted-theming 0.11 format to the old one
  */
  convert-scheme-to-common-format = raw:
    (raw.palette or {})
    // {
      scheme = raw.name or "untitled";
      slug = raw.slug or (slugify (raw.name or "untitled"));
    }
    // (removeAttrs raw [ "palette" ]);

  /* Normalizes a scheme attrset's colors:
     - filters color fields from the scheme,
     - trims the optional prefix hashtag,
     - lowers the values.
  */
  normalize-colors = err-msg: raw:
    let
      baseXXs = lib.filterAttrs (name: _: lib.hasPrefix "base" name && builtins.stringLength name == 6) raw;
      check-color = color: builtins.isString color && builtins.stringLength (lib.removePrefix "#" color) == 6;
    in success-monad baseXXs {
      f = baseXXs:
        let
          are-colors = builtins.attrValues (builtins.mapAttrs (_: check-color) baseXXs);
        in {
          success = builtins.length are-colors >= 1 && builtins.all (x: x) are-colors;
          value = builtins.mapAttrs (_: value: lib.toLower (lib.removePrefix "#" value)) baseXXs;
        };
      inherit err-msg;
    };

  /* Parses a yaml file to an attrset.
  */
  yaml2attrs = {
    # The file to parse.
    yaml,
    # Whether to use [IFD](https://nixos.wiki/wiki/Import_From_Derivation) to parse yaml.
    # One of "always", "auto", "never". The default is "never".
    # "always" and "auto" can cause problems with `nix flake check / show` (see the issue #3).
    use-ifd ? "never",
    # if use-ifd == "auto", the function to decide whether the YAML was parsed correctly without the IFD.
    # The default checks as if we are trying to parse a scheme.
    check ? (raw: normalize-colors msg.scheme-check-failed (convert-scheme-to-common-format raw)),
  }:
    let
      without-ifd = fromYaml (builtins.readFile yaml);
      with-ifd = builtins.fromJSON (builtins.readFile (yaml2json yaml));
    in
      if use-ifd == "always" then with-ifd
      else if use-ifd == "never" then
        if (check without-ifd).success then without-ifd
        else builtins.trace msg.no-ifd-failed without-ifd
      else if (check without-ifd).success then without-ifd
      else builtins.trace msg.no-ifd-failed with-ifd;

  /* Returns a derivation that checks that an attrset was correctly parsed from a yaml file.
  */
  check-parsed-yaml = yaml: parsed: let 
    correctlyParsedYamlAsJson = yaml2json yaml;
    yaml-filename = lib.escapeShellArg "${yaml}";
    parsedYamlAsJson =
      pkgs.writeText "parsed-yaml-as-json" (builtins.toJSON parsed);
  in pkgs.stdenv.mkDerivation {
    name = "base16-nix-parse-check";
    nativeCheckInputs = [ pkgs.diffutils pkgs.jd-diff-patch ];
    allowSubstitutes = false;
    preferLocalBuild = true;
    doCheck = true;
    phases = [ "checkPhase" "installPhase" ];
    checkPhase = ''
      runHook preCheck
      set +e
      DIFF=$(jd ${correctlyParsedYamlAsJson} ${parsedYamlAsJson}) 
      set -e
      if [ "$DIFF" != "" ]
      then
        echo 'Output of "jd ${correctlyParsedYamlAsJson} ${parsedYamlAsJson}":'
        echo "$DIFF"
        echo '${msg.incorrect-parsing-detected yaml-filename}'
        exit 1
      fi
      runHook postCheck
    '';
    installPhase = ''
      mkdir $out
    '';
  };
in { inherit success-monad sm-or writeTextFile' writeTextFile'' yaml2json yaml2attrs check-parsed-yaml convert-scheme-to-common-format normalize-colors; }
