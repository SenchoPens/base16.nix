{ pkgs, inputs, ... }:
let
  scheme =
    { schemePath ? null, author ? "", scheme ? "", ... }@schemeArgs: rec {
      # TODO: \/ does not compose good
      inherit schemePath;

      colors = let
        colors' = { base00, base01, base02, base03, base04, base05, base06
          , base07, base08, base09, base0A, base0B, base0C, base0D, base0E
          , base0F, ... }@this:
          let
            base = pkgs.lib.filterAttrs (name: _: hasPrefix "base" key) this;
            mapBase = f:
              colors' (builtins.mapAttrs
                (_: value: f value) base);
          in {
            inherit base00 base01 base02 base03 base04 base05 base06 base07
              base08 base09 base0A base0B base0C base0D base0E base0F;

            # TODO: replace with __functor with a format argument from here:
            # https://github.com/chriskempson/base16/blob/master/builder.md#template-variables
            withHashtag = mapBase (v: "#" + v);
            asDecimal = mapBase colorHex2Dec;
            asList = mapAttrsToList (_: value: value) base;
            mnemonic = getNamed this;
          };
      in colors' schemeArgs;

      # TODO: do we need this?
      builder = rec {
        scheme-name = builtins.baseNameOf schemePath;
        scheme-author = author;
        scheme-slug = pkgs.lib.removeSuffix ".yaml" scheme-name;
      };

      # Builds a theme from a scheme and a template
      __functor = self: args: buildTheme (args // { scheme = self; });
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

  # A scheme attrset from a path to yaml or from a yaml string
  schemeFromYAML = yaml:
    let
      yamlPath = if builtins.isPath yaml then
        yaml
      else
        builtins.toFile "scheme.yaml" yaml;
      yaml2set = yamlPath:
        builtins.fromJSON (builtins.readFile (pkgs.stdenv.mkDerivation {
          name = "fromYAML";
          phases = [ "buildPhase" ];
          buildPhase = "${pkgs.yaml2json}/bin/yaml2json < ${yamlPath} > $out";
        }));
    in scheme ((yaml2set yamlPath) // { schemePath = path-to-yaml; });

  # schemeFromSet = set:

  colorHex2Dec = color:
    let
      hex2int = s:
        with builtins;
        if s == "" then
          0
        else
          let l = stringLength s - 1;
          in (hex2decDigits."${substring l 1 s}" + 16
            * (hex2int (substring 0 l s)));

      hex2decDigits = rec {
        "0" = 0;
        "1" = 1;
        "2" = 2;
        "3" = 3;
        "4" = 4;
        "5" = 5;
        "6" = 6;
        "7" = 7;
        "8" = 8;
        "9" = 9;
        a = 10;
        b = 11;
        c = 12;
        d = 13;
        e = 14;
        f = 15;
        A = a;
        B = b;
        C = c;
        D = d;
        E = e;
        F = f;
      };

      splitHex = hexStr: [
        (builtins.substring 0 2 hexStr)
        (builtins.substring 2 2 hexStr)
        (builtins.substring 4 2 hexStr)
      ];

      doubleDigitHexToDec = hex:
        16 * hex2decDigits."${builtins.substring 0 1 hex}"
        + hex2decDigits."${builtins.substring 1 2 hex}";
    in builtins.concatStringsSep ","
    (map (x: toString (doubleDigitHexToDec x)) (splitHex color));

  # Helper functions for builders:

  # Builders:

  # TODO: add to the buildTemplate function
  # buildTemplate-ejs = schemePath: templatePath: brightness:
  #   pkgs.runCommand "${schemePath}-theme" {} ''
  #     export HOME=$(pwd)/home; mkdir -p $HOME
  #     ${pkgs.base16-builder}/bin/base16-builder \
  #       --scheme ${schemePath} \
  #       --template ${templatePath} \
  #       --brightness ${brightness} \
  #       > $out
  #   '';

  packages = import ./pkgs { inherit pkgs inputs; };

  # TODO: use flavours
  buildTemplate-mustache = schemePath: templateDir: targetTemplate:
    let tCfg = (fromYAMLPath "${templateDir}/config.yaml").${targetTemplate};
    in pkgs.runCommand "${schemePath}-theme" { } ''
        mkdir -p schemes/scheme/
        mkdir -p templates/template/

        cp ${schemePath} schemes/scheme/scheme.yaml
      r} templates/template/templates

        ${packages.base16-builder-python.python}/bin/pybase16 build

        cat output/template/${tCfg.output}/base16-scheme${tCfg.extension} > $out
    '';

  # Builds a theme from a scheme and a template
  buildTheme = {
    # A scheme object (for example, config.base16.cur)
    # or a path to .yaml file.
    scheme,
    # A directory with mustache files (config.yaml, etc.)
    # or a flake input, or a path with templates/ directory with mustache files
    # or (for base16-builder ejs templates) a template name
    # from github:base16-builder/base16-builder/db/templates.
    templateSrc,
    # One of the options in config.yaml file.
    # Most often you want this to be "default".
    # For base16-builder ejs templates this specifies brightness
    # ("dark", "light", "dark-256", etc.)
    targetTemplate }:
    let
      schemePath = scheme.schemePath or scheme;
      # template 
    in { };

  generateSchemeFileFromImage = imagePath: schemeSlug:
    pkgs.runCommand "${schemeSlug}.yaml" { } ''
      ${packages.schemer2}/bin/schemer2 -format img::colors -in ${imagePath} -out colors.txt -maxBright 255 \
        && ${packages.auto-base16-theme}/bin/auto-base16-theme ${
          ./image-theme-template.yaml
        } $out \
        && rm colors.txt
    '';
in { inherit buildTheme scheme schemeFromYAML generateSchemeFileFromImage; }
