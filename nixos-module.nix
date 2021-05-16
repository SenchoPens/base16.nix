{ self, lib, pkgs, config, ... }:

with lib;

let
  cfg = config.base16;

  colorType = types.str;

  schemeType =
    types.submodule {
      options = rec {
        original = mkOption {
          description =
            "Attribute set with keys and values in format of 'base0X' and 'rrggbb'";
          type = types.listOf colorType;
        };

        originalHashtag = mkOption {
          description =
            "Attribute set with keys and values in format of 'base0X' and '#rrggbb'";
          type = types.listOf colorType;
        };

        originalDec = mkOption {
          description =
            "Attribute set with keys and values in format of 'base0X' and 'r,g,b', where e.g. r is decimal form of '#rr'";
          type = types.listOf colorType;
        };

        numbered = mkOption {
          description =
            "Same as original, but as a list in order of base00, base01, ..., base0F";
          type = types.listOf colorType;
        };

        numberedHashtag = mkOption {
          description =
            "Same as originalHashtag, but as a list in order of base00, base01, ..., base0F";
          type = types.listOf colorType;
        };

        numberedDec = mkOption {
          description =
            "Same as originalDec, but as a list in order of base00, base01, ..., base0F";
          type = types.listOf colorType;
        };

        named = mkOption {
          description =
            "Same as 'original', but keys are renamed to colors they usually are, e.g. 'base0D' -> 'blue'";
          type = types.attrsOf colorType;
        };

        namedHashtag = mkOption {
          description =
            "Same as 'originalHashtag', but keys are renamed to colors they usually are, e.g. 'base0D' -> 'blue'";
          type = types.attrsOf colorType;
        };

        namedDec = mkOption {
          description =
            "Same as 'originalDec', but keys are renamed to colors they usually are, e.g. 'base0D' -> 'blue'";
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
