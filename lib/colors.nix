{ lib, normalize-colors, ... }:
let
  inherit (builtins) getAttr;
  compose = lib.flip lib.pipe;
  base-digits = lib.stringToCharacters "0123456789abcdefghijklmnopqrstuvwxyz";
  parseIntRadix =
    base:
    assert 2 <= base && base <= 36;
    let
      digits' = compose [
        (lib.take base)
        (lib.imap0 (lib.flip lib.nameValuePair))
        lib.listToAttrs
      ] base-digits;
    in
    compose [
      lib.toLower
      lib.stringToCharacters
      (map (lib.flip getAttr digits'))
      (lib.foldr (cur: acc: acc * base + cur) 0)
    ];
  toIntBase16 = parseIntRadix 16;

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
      inherit (builtins) listToAttrs attrValues;
      uncurry = lib.foldl lib.id;
      mapAttrValues = compose [
        lib.const
        lib.mapAttrs
      ];
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
          rgb = mapAttrValues toIntBase16 (splitRGB self.hex);
          dec = mapAttrValues (x: x / 255.0) self.rgb;
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
        in
        {
          inherit (ansi'.dark)
            red
            green
            cyan
            blue
            magenta
            ;
          orange = ansi'.dark.yellow;
          yellow = palette.base0A;
          brown = palette.base0F;
        }
        // builtins.listToAttrs (
          lib.zipListsWith lib.nameValuePair
            (map (x: "bright-${x}") [
              "red"
              "green"
              "orange"
              "blue"
              "magenta"
              "cyan"
            ])
            (
              lib.pipe ansi'.bright.toList [
                lib.tail
                lib.init
              ]
            )
        );

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
      prepend = compose [
        lib.singleton
        lib.concat
      ];
      # transforms a list of colors to a flat list expected by base16 templates
      based = lib.concatMapAttrs (
        name: value:
        listToAttrs (
          map (
            p:
            lib.pipe
              [
                (compose [
                  (prepend name)
                  (lib.concatStringsSep "-")
                ])
                (lib.flip lib.getAttrFromPath value)
              ]
              [
                (map (lib.flip lib.id p))
                (uncurry lib.nameValuePair)
              ]
          ) paths
        )
      );

      /*
        Maps a value by function `f`, recurring whenever `cond` is `true` 
        and the value under question is either attrs or list.
      */
      mapRecursiveCond =
        cond: f:
        let
          inherit (builtins) isAttrs isList;
        in
        lib.fix (
          self: val:
          (
            if isAttrs val && cond val then
              mapAttrValues self
            else if isList val && cond val then
              map self
            else
              f
          )
            val
        );

      extra =
        palette:
        mnemonic palette
        // {
          ansi = ansi palette;
          toList = attrValues palette;
        };
      total = palette: based palette // extra palette;
      total' =
        palette:
        mapRecursiveCond (x: lib.strings.isConvertibleWithToString x -> builtins.isList x) toString (
          total palette
        )
        // {
          original = palette // extra palette;
        };

      withHashtag = mapAttrValues (lib.flip lib.mergeAttrs { __toString = self: self.hex.withHashtag; });
    in
    total' base-colors // { withHashtag = total' (withHashtag base-colors); };
in
{
  inherit colors mkBase24;
}
