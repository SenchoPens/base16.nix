{ lib, normalize-parsed-scheme, ... }:
let
  /* Converts 2 digit hex to decimal number.

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

  
  /* Ensure Base24 colors are available
     https://github.com/tinted-theming/base24/blob/master/styling.md
  */
  mkBase24 = scheme: scheme // {
    base10 = scheme.base10 or scheme.base00;
    base11 = scheme.base11 or scheme.base00;
    base12 = scheme.base12 or scheme.base08;
    base13 = scheme.base13 or scheme.base0A;
    base14 = scheme.base14 or scheme.base0B;
    base15 = scheme.base15 or scheme.base0C;
    base16 = scheme.base16 or scheme.base0D;
    base17 = scheme.base17 or scheme.base0E;
  };

  /* Returns an attrset with the colors that the builder should provide, listed in
     https://github.com/base16-project/base16/blob/main/builder.md#template-variables.

     For convenience, attributes of the form `baseXX` are provided, which are equal to
     `baseXX-hex`, along with a `toList` attribute, which is equal to `[ base00 ... base0F ]`
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
      # normalize-parsed-scheme will already be checked or is not in danger anyhow
      base = (normalize-parsed-scheme "" scheme).value;
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

in { inherit colors mkBase24; }
