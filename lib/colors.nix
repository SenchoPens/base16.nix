{ lib, normalize-colors, ... }:
let
  /*
    Converts 2 digit hex to decimal number.

    Example:
      primaryHex2Dec "1a" = 26
  */
  primaryHex2Dec =
    hex:
    let
      hex2decDigits = {
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
      };
      hex' = lib.toLower hex;
    in
    16 * hex2decDigits."${builtins.substring 0 1 hex'}"
    + hex2decDigits."${builtins.substring 1 2 hex'}";

  compose = lib.flip lib.pipe;

  /*
    Ensure Base24 colors are available
    https://github.com/tinted-theming/base24/blob/master/styling.md
  */
  mkBase24 =
    scheme:
    scheme
    // {
      base10 = scheme.base10 or scheme.base00;
      base11 = scheme.base11 or scheme.base00;
      base12 = scheme.base12 or scheme.base08;
      base13 = scheme.base13 or scheme.base09;
      base14 = scheme.base14 or scheme.base0B;
      base15 = scheme.base15 or scheme.base0C;
      base16 = scheme.base16 or scheme.base0D;
      base17 = scheme.base17 or scheme.base0E;
    };

  /*
    Returns an attrset with the colors that the builder should provide, listed in
    https://github.com/base16-project/base16/blob/main/builder.md#template-variables.

    For convenience, attributes of the form `baseXX` are provided, which are equal to
    `baseXX-hex`, along with a `toList` attribute, which is equal to `[ base00 ... base0F ]`
    (or likewise for base24), as well as an `ansi` attribute with attributes like `ansi.bright.red`
    and its own `toList` in the form expected by `console.colors` and conforming to [base24 guidelines].
    Also, mnemonic color names for base08-base0F and base12-base17 are provided:
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
       bright-red = base12 or base08;
       bright-orange = base13 or base09;
       bright-green = base14 or base0B;
       bright-cyan = base15 or base0C;
       bright-blue = base16 or base0D;
       bright-magenta = base17 or base0E;
     };
     ```

    [base24 guidelines]: https://github.com/tinted-theming/base24/blob/master/styling.md#specific-colours-and-their-usages
  */
  colors =
    scheme:
    let
      # normalize-colors will already be checked or is not in danger anyhow
      base = (normalize-colors "" scheme).value;
      # define local helper functions:
      splitRGB = hex: {
        r = builtins.substring 0 2 hex;
        g = builtins.substring 2 2 hex;
        b = builtins.substring 4 2 hex;
      };
      _color =
        hex:
        lib.fix (self: {
          hex = {
            __toString = self: hex;
            inherit (splitRGB self.hex) r g b;
            bgr = with self.hex; b + g + r;
            withHashtag = "#${self.hex}";
          };
          __toString = self: self.hex;
          rgb = lib.mapAttrs (_: primaryHex2Dec) (splitRGB self.hex);
          dec = lib.mapAttrs (_: x: x / 255.0) self.rgb;
        });

      ansi-list =
        colors: with colors; [
          black
          red
          green
          yellow
          blue
          magenta
          cyan
          white
        ];
      ansi =
        palette:
        with mkBase24 palette;
        lib.fix (self: {
          dark = {
            black = base01;
            red = base08;
            green = base0B;
            yellow = base09;
            blue = base0D;
            magenta = base0E;
            cyan = base0C;
            white = base06;
            # suitable for programs.wezterm.colorSchemes.<name>.ansi and similar
            toList = ansi-list self.dark;
          };
          bright = {
            black = base02;
            red = base12;
            green = base14;
            yellow = base13;
            blue = base16;
            magenta = base17;
            cyan = base15;
            white = base07;
            toList = ansi-list self.bright;
          };
          # suitable for console.colors and similar
          toList = self.dark.toList ++ self.bright.toList;
        });

      mnemonic =
        palette:
        let
          ansi' = ansi palette;
          color-list = [
            "red"
            "green"
            "orange"
            "blue"
            "magenta"
            "cyan"
          ];
          # everything but first (black) and last (white) elements
          ansi-list = compose [
            lib.tail
            lib.init
          ];
        in
        builtins.listToAttrs (
          lib.zipListsWith lib.nameValuePair (color-list ++ map (x: "bright-${x}") color-list) (
            ansi-list ansi'.dark.toList ++ ansi-list ansi'.bright.toList
          )
        )
        // {
          inherit (ansi.dark)
            red
            green
            blue
            magenta
            cyan
            ;
          orange = ansi.dark.yellow;
          bright-red = ansi.bright.red;
          bright-green = ansi.bright.green;
          bright-orange = ansi.bright.yellow;
          bright-blue = ansi.bright.blue;
          bright-magenta = ansi.bright.magenta;
          bright-cyan = ansi.bright.cyan;
          yellow = palette.base0A;
          brown = palette.base0F;
        };

      # paths like `hex`, `rgb.r` etc.
      paths =
        [
          [ ]
          [ "hex" ]
          [
            "hex"
            "bgr"
          ]
        ]
        ++ (lib.mapCartesianProduct
          (
            { fmt, chan }:
            [
              fmt
              chan
            ]
          )
          {
            fmt = [
              "hex"
              "rgb"
              "dec"
            ];
            chan = [
              "r"
              "g"
              "b"
            ];
          }
        );

      base-colors = lib.mapAttrs (lib.const _color) base;
      # transforms a list of colors to a flat list expected by base16 templates
      based = lib.concatMapAttrs (
        name: value:
        builtins.listToAttrs (
          lib.forEach paths (path: {
            name = lib.concatStringsSep "-" ([ name ] ++ path);
            value = lib.getAttrFromPath path value;
          })
        )
      );

      inherit (builtins) isList isAttrs;

      /*
        Maps a value by function `f`, recurring whenever `cond` is `true`
        and the value under question is either attrs or list.
      */
      mapRecursiveCond =
        cond: f:
        lib.fix (
          self: val:
          if isAttrs val && cond val then
            lib.mapAttrs (_: self) val
          else if isList val && cond val then
            map self val
          else
            f val
        );

      extra =
        palette:
        mnemonic palette
        // {
          ansi = ansi palette;
          toList = builtins.attrValues palette;
        };
      total = palette: based palette // extra palette;
      total' =
        palette:
        mapRecursiveCond (x: lib.strings.isConvertibleWithToString x -> isList x) toString (total palette)
        // {
          original = palette // extra palette;
        };

      withHashtag = lib.mapAttrs (_: x: x // { __toString = self: self.hex.withHashtag; });
    in
    total' base-colors // { withHashtag = total' (withHashtag base-colors); };
in
{
  inherit colors mkBase24;
}
