self:
{ config, pkgs, lib, ... }: {
  config.lib.base16 = self.lib { inherit pkgs lib; };
  options.base16 = with lib.types;
    let
      schemeAttrsType = attrsOf anything;
      optionValueType = oneOf [ schemeAttrsType path str ];
    in lib.options.mkOption {
      description = "Attrset of scheme attrsets";
      # type = attrsOf optionValueType;
      # apply = config.lib.base16.mkSchemeAttrs;
      type = attrsOf (coercedTo optionValueType config.lib.base16.mkSchemeAttrs schemeAttrsType);
      default = { };
      example = {
        /* Specifying a scheme from a yaml file.

           Given
           ```
           inputs = {
             ...
             base16-eva-scheme = {
               url = github:kjakapat/base16-eva-scheme;
               flake = false;
             };
           }
           ```
           Then you can specify a scheme as follows:
        */
        eva = "${inputs.base16-eva-scheme}/eva-dim.yaml";
        /* Overriding a scheme. Now we need to explicitely use `mkSchemeAttrs` function
           to use `override` field of the resulting scheme attrs:
        */
        evaOverriden = (config.lib.base16.mkSchemeAttrs "${inputs.base16-eva-scheme}/eva-dim.yaml").override {
          name = "Now it's my scheme >:]";
          base00 = "000000";  # make background completely black
        };
        /* Specifying a scheme from scratch in Nix, source:
           https://code.balsoft.ru/balsoft/nixos-config/src/branch/master/modules/themes.nix
        */
        balsoftheme = {
          slug = "balsoftheme"; name = "Base16 theme by balsoft"; author = "balsoft";
          base00 = "000000"; base01 = "333333"; base02 = "666666"; base03 = "999999";
          base04 = "cccccc"; base05 = "ffffff"; base06 = "e6e6e6"; base07 = "e6e6e6";
          base08 = "bf4040"; base09 = "bf8040"; base0A = "bfbf40"; base0B = "80bf40";
          base0C = "40bfbf"; base0D = "407fbf"; base0E = "7f40bf"; base0F = "bf40bf";
        };
        /* Specifying the same scheme as a yaml string:
        */
        balsofthemeYAML = ''
          slug: "balsoftheme"
          name: "Base16 theme by balsoft"
          author: "balsoft"
          base00: "000000"
          base01: "333333"
          base02: "666666"
          base03: "999999"
          base04: "cccccc"
          base05: "ffffff"
          base06: "e6e6e6"
          base07: "e6e6e6"
          base08: "bf4040"
          base09: "bf8040"
          base0A: "bfbf40"
          base0B: "80bf40"
          base0C: "40bfbf"
          base0D: "407fbf"
          base0E: "7f40bf"
          base0F: "bf40bf"
        '';
      };
    };
}
