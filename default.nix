{ pkgs, lib, ... }:
let
  #------------------#
  # HELPER FUNCTIONS #
  #------------------#

  /* Converts 2 digit hex to decimal number

     Example:
       primaryHex2Dec "1a" = 26
  */
  primaryHex2Dec = hex:
    let
      hex2decDigits =
        rec {
          "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4;
          "5" = 5; "6" = 6; "7" = 7; "8" = 8; "9" = 9;
          a = 10; b = 11; c = 12; d = 13; e = 14; f = 15;
          A = a; B = b; C = c; D = d; E = e; F = f;
        };
    in
      16 * hex2decDigits."${builtins.substring 0 1 hex}"
      + hex2decDigits."${builtins.substring 1 2 hex}";

  /* Returns an attrset with the colors that the builder should provide, listed in
     https://github.com/base16-project/base16/blob/main/builder.md#template-variables

     For convenience, attributes of the form `baseXX` are provided, which are equal to
     `baseXX-hex`, along with a `toList` attribute, which is equial to `[ base00 ... base0F ]`
     (mainly for config.console.colors).  Also, mnemonic color names for base08-base0F are provided:
     ```
      mnemonic = {
        red = base08;
        orange = base09;
        yellow = base0A;
        green = base0B;
        cyan = base0C;
        blue = base0D;
        magenta = base0E;
        brown = base0F;
      };
      ```
  */
  colors = scheme:
    let
      # filter color fields from the scheme,
      # trim the optional prefix hashtag
      # and lower the values
      base = lib.mapAttrs (_: value: lib.toLower (lib.removePrefix "#" value)) (
        lib.filterAttrs (name: _: lib.hasPrefix "base" name && builtins.stringLength name == 6) scheme
      );

      # define local helper functions:
      splitRGB = hex: {
        r = builtins.substring 0 2 hex;
        g = builtins.substring 2 2 hex;
        b = builtins.substring 4 2 hex;
      };
      splitRGB' = f: hex: prefix:
        let rgb = splitRGB hex;
        in {
          "${prefix}-r" = f rgb.r;
          "${prefix}-g" = f rgb.g;
          "${prefix}-b" = f rgb.b;
        };
      addRGB = f: prefix:
        builtins.foldl' (x: y: x // y) { }
        (builtins.map (baseXX: splitRGB' f base.${baseXX} "${baseXX}-${prefix}")
          (builtins.attrNames base));

      # populate the fields:
      base-hex-rgb = addRGB (x: x) "hex";
      base-rgb-rgb = addRGB (x: builtins.toString (primaryHex2Dec x)) "rgb";
      base-dec-rgb = addRGB (x: builtins.toString (primaryHex2Dec x / 256.0)) "dec";

      base-hex = lib.mapAttrs' (k: v: lib.nameValuePair "${k}-hex" v) base;
      base-short = lib.mapAttrs' (k: v: lib.nameValuePair "${k}" v) base;

      mnemonic = with base-short; {
        red = base08;
        orange = base09;
        yellow = base0A;
        green = base0B;
        cyan = base0C;
        blue = base0D;
        magenta = base0E;
        brown = base0F;
      };

      base-hex-bgr = lib.mapAttrs' (k: v:
        let rgb = splitRGB v;
        in lib.nameValuePair "${k}-hex-bgr" "${rgb.b}${rgb.g}${rgb.r}") base;

      based = base-hex // base-hex-rgb // base-rgb-rgb
        // base-dec-rgb // base-hex-bgr // base-short
        // mnemonic;

      toList = lib.attrValues base;

      withHashtag =
        let hashtag = color: "#${color}";
        in (lib.mapAttrs (_: hashtag) based) // { toList = map hashtag toList; };

    in based // { inherit toList withHashtag; };

  writeTextFile = path: text: ''${pkgs.writeTextDir path text}/${path}'';

  yaml2attrs = yaml:
    builtins.fromJSON (builtins.readFile (pkgs.stdenv.mkDerivation {
      name = "fromYAML";
      phases = [ "buildPhase" ];
      buildPhase = "${pkgs.yaml2json}/bin/yaml2json < ${yaml} > $out";
    }));

  /* Builds a theme file from a scheme and a template and returns its path.
     If you do not supply `templateRepo`, then
     you need to supply both `template` and `extension`.
  */
  mkTheme = {
    # A scheme attrset returned from `mkSchemeAttrs` function
    scheme,
    # A directory with a `templates` subdirectory (containing templates and a `config.yaml` file)
    # (e.g. a flake input of a template repository).
    templateRepo ? null,
    # Name of the template to lookup in templateRepo.
    # Must be one of the top-level targets from `${templateRepo}/templates/config.yaml` and
    # correspond to a template `${templateRepo}/templates/${targetTemplate}.mustache`.
    target ? "default",
    # A string with mustache template.
    # If is `null`, then `${templateRepo}/templates/${targetTemplate}.mustache` is used.
    template ? null,
    # An extension (e.g. ".config") with which to save the resulting theme file.
    # If is `null` and `templateRepo` is passed, the extension will be grabbed from there,
    # otherwise it's an empty string
    extension ? null,
  }:
    let
      ext =
        if extension == null then
          if templateRepo == null then
            ""
          else
            (yaml2attrs "${templateRepo}/templates/config.yaml").${target}.extension
        else
          extension
        ;
      themeFilename = "base16-${scheme.scheme-slug}${ext}";
      templatePath =
        if template == null then
          "${templateRepo}/templates/${target}.mustache"
        else
          writeTextFile "${target}.mustache" template
        ;
      # Taken from https://pablo.tools/blog/computers/nix-mustache-templates/
      themeDerivation = pkgs.stdenv.mkDerivation rec {
        name = "${builtins.unsafeDiscardStringContext scheme.scheme-slug}";

        nativeBuildInpts = [ pkgs.mustache-go ];

        # Pass JSON as file to avoid escaping
        passAsFile = [ "jsonData" ];
        jsonData = builtins.toJSON (builtins.removeAttrs scheme [ "outPath" "override" "__functor" ]);

        # Disable phases which are not needed. In particular the unpackPhase will
        # fail, if no src attribute is set
        phases = [ "buildPhase" "installPhase" ];

        buildPhase = ''
          ${pkgs.mustache-go}/bin/mustache $jsonDataPath ${templatePath} > theme
        '';

        installPhase = ''
          mkdir $out
          cp theme $out/${themeFilename}
        '';
      };
    in "${themeDerivation}/${themeFilename}";

  #--------------------#
  # EXPORTED FUNCTIONS #
  #--------------------#

  /* Returns a scheme attrset
  */
  mkSchemeAttrs =
    # A path to a file or an attrset.
    # It MUST contain contain string attributes `baseXX`
    # and MAY contain string attributes `scheme`, `author`, `description`, `slug`
    # (see https://github.com/base16-project/home/blob/main/builder.md#schemes-repository).
    scheme:
    let
      inputAttrs = 
        if builtins.isAttrs scheme then
          scheme
        else
          { slug =
              lib.removeSuffix ".yaml" (
                builtins.baseNameOf (
                  builtins.unsafeDiscardStringContext "${scheme}"
          ));}
          //
          (yaml2attrs scheme)
        ;

      inputMeta = rec {
        scheme = ''${inputAttrs.scheme or "untitled"}'';
        author = ''${inputAttrs.author or "untitled"}'';
        description = ''${inputAttrs.description or scheme}'';
        slug =
          lib.toLower (
            lib.strings.sanitizeDerivationName (
              inputAttrs.slug or scheme
        ));
      };

      builderMeta = {
        scheme-name = inputMeta.scheme;
        scheme-author = inputMeta.author;
        scheme-description = inputMeta.description;
        scheme-slug = inputMeta.slug;
      };

      # Like Python magic methods
      magic = {
        # Lets scheme attrs be automatically coerced to string (`__str__`)
        outPath =
          writeTextFile "${inputMeta.slug}.yaml"
            (builtins.concatStringsSep "\n"
              (lib.mapAttrsToList (name: value: "${name}: ${value}") inputAttrs));
        # Calling a scheme attrset will build a theme (`__call__`)
        __functor = self: args: mkTheme (
          # if args is a flake input, then it must be templateRepo
          (if args ? outPath then { templateRepo = args; } else args) // { scheme = self; }
        );
      };

      populatedColors = colors inputAttrs;

      allOther = inputMeta // builderMeta // magic // {
        override = new: mkSchemeAttrs (inputAttrs // inputMeta // new);
      };

    in populatedColors // allOther // {
      withHashtag = populatedColors.withHashtag // allOther;
    };

in { inherit mkSchemeAttrs; }
