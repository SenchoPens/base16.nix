self:
{ config, pkgs, lib, ... }: {
  config.lib.base16 = self.lib { inherit pkgs lib; };

  options.scheme = with lib.types;
    let
      optionValueType = oneOf [ schemeAttrsType path str ];
      coerce = value:
        if value ? "scheme-name" then
          value
        else
          config.lib.base16.mkSchemeAttrs value
        ;
      schemeAttrsType = attrsOf anything;
    in lib.options.mkOption {
      description = "Current scheme (scheme attrs or a path to a yaml file)";
      type = coercedTo optionValueType coerce schemeAttrsType;
    };
}
