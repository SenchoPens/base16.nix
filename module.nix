self:
{ config, pkgs, lib, ... }: {
  config.lib.base16 = self.lib { inherit pkgs lib; };
  options.scheme = with lib.types;
    let
      schemeAttrsType = attrsOf anything;
      optionValueType = oneOf [ schemeAttrsType path str ];
      coerce = value:
        if value ? "scheme-name" then
          value
        else
          config.lib.base16.mkSchemeAttrs value
        ;
    in lib.options.mkOption {
      description = "Current scheme (scheme attrs or a path to a yaml file)";
      type = coercedTo optionValueType coerce schemeAttrsType;
      default = {
        slug = "balsoftheme"; name = "Base16 theme by balsoft"; author = "balsoft";
        base00 = "000000"; base01 = "333333"; base02 = "666666"; base03 = "999999";
        base04 = "cccccc"; base05 = "ffffff"; base06 = "e6e6e6"; base07 = "e6e6e6";
        base08 = "bf4040"; base09 = "bf8040"; base0A = "bfbf40"; base0B = "80bf40";
        base0C = "40bfbf"; base0D = "407fbf"; base0E = "7f40bf"; base0F = "bf40bf";
      };
      example = ''
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
           You can specify a scheme as follows:
        */
        "''${inputs.base16-eva-scheme}/eva-dim.yaml";
        /* Overriding a scheme. Now we need to explicitely use `mkSchemeAttrs` function
           to use `override` field of the resulting scheme attrs:
        */
        (config.lib.base16.mkSchemeAttrs "''${inputs.base16-eva-scheme}/eva-dim.yaml").override {
          scheme = "Now it's my scheme >:]";
          base00 = "000000";  # make background completely black
        };
        /* Specifying a scheme from scratch in Nix, source:
           https://code.balsoft.ru/balsoft/nixos-config/src/branch/master/modules/themes.nix
        */
        {
          slug = "balsoftheme"; name = "Base16 theme by balsoft"; author = "balsoft";
          base00 = "000000"; base01 = "333333"; base02 = "666666"; base03 = "999999";
          base04 = "cccccc"; base05 = "ffffff"; base06 = "e6e6e6"; base07 = "e6e6e6";
          base08 = "bf4040"; base09 = "bf8040"; base0A = "bfbf40"; base0B = "80bf40";
          base0C = "40bfbf"; base0D = "407fbf"; base0E = "7f40bf"; base0F = "bf40bf";
        };
      '';
    };
}
