{ base16-pkgs, base16-inputs }:
{ lib, pkgs, config, ... }:

with lib;

let
  colorType = types.str;

  schemeType =
    types.submodule {
      options = rec {
        schemePath = mkOption {
          description =
            "Filepath to the scheme";
          type = types.nullOr types.path;
          default = null;
        };

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

        listed = mkOption {
          description =
            "Same as original, but as a list in order of base00, base01, ..., base0F";
          type = types.listOf colorType;
        };

        listedHashtag = mkOption {
          description =
            "Same as originalHashtag, but as a list in order of base00, base01, ..., base0F";
          type = types.listOf colorType;
        };

        listedDec = mkOption {
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

        builder = mkOption {
          # TODO: implement
          description =
            "NOT IMPLEMENTED Provides variables that are listed in the section "Template Variables" of http://chriskempson.com/projects/base16/";
          type = types.attrsOf colorType;
        };
      };
    };
in {
  options.base16 = {
    schemes = mkOption {
      description = "Attribute set of schemes";
      type = types.attrsOf schemeType;
    };

    cur = mkOption {
      description = "Convenience option for the current scheme of the system";
      type = schemeType;
    };

    lib = mkOption {
      description = "Functions for theming";
      type = types.attrsOf types.anything;
    };
  };

  config.base16.lib = import ./default.nix { pkgs = base16-pkgs; inputs = base16-inputs; };
}
