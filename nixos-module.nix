{ self, lib, pkgs, config, ... }:

with lib;

let
  cfg = config.base16;

  colorType = types.str;

  schemeType =
    types.submodule {
      options = rec {
        numbered = mkOption {
          description =
            "List of base16 colors in order 00, 01, ..., 0F in format of 'rrggbb'";
          type = types.listOf colorType;
        };

        numberedHashtag = mkOption {
          description =
            "List of base16 colors in order 00, 01, ..., 0F in format of '#rrggbb'";
          type = types.listOf colorType;
        };

        numberedDec = mkOption {
          description =
            "List of base16 colors in order 00, 01, ..., 0F in format of 'r,g,b', e.g. r is decimal form of '#rr'";
          type = types.listOf colorType;
        };

        named = mkOption {
          description =
            "Same as 'numbered', but as an attrset, where keys are semantic color names, e.g. 'blue' refers to base0D";
          type = types.attrsOf colorType;
        };

        namedHashtag = mkOption {
          description =
            "Same as 'numberedHashtag', but as an attrset";
          type = types.attrsOf colorType;
        };

        namedDec = mkOption {
          description =
            "Same as 'numberedDec', but as an attrset";
          type = types.attrsOf colorType;
        };
      };
    };
in {
  options.base16.schemes = mkOption {
    description = "Attribute set of schemes";
    type = types.attrsOf schemeType;
  };
}
