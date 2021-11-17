![logo](./logo.png)

# base16.nix

Nix utility functions, a NixOS and home-manager module to help configure applications to use base16 themes.
Intended to be used as a flake.

## Features
- Build a theme for any scheme yaml file and any ejs / mustache template in one function call
- Parse a scheme yaml file to a nix attrset, so one can conveniently theme any application manually
- NixOS module
- home-manager module

## Nonfeatures
This project does not attempt to:
- Provide or even aggregate any schemes / templates (download them yourself!)

## Usage
Disclaimer: This repo is most useful and user-friendly when you use it as a NixOS or homemanager module.
If you want only the functions, they are defined in the [default.nix](default.nix) file

Add this repo to your flake inputs, then, in the outputs section, add it to the modules list
TODO: update the link
(example: [maintainer's flake.nix](https://github.com/SenchoPens/senixos/blob/master/flake.nix#L98))

The repo mainly provides two things: functions to help theme your applications and config options
to ease using these functions throughout your NixOS configuration.
Functions are defined in the [default.nix](default.nix) file and
config options are defined in the [nixos-module.nix](nixos-module.nix) file.

The main function that build themes from templates:
```
buildTemplate = scheme: template: targetTemplate: <string with built template>
```
For example, let's suppose you want to run 


The source files of this repository are quite short, so if you are missing some documentation, you
can try read them :), or even extend the docs, contributions are highly welcome!

## Examples
`config.console.colors = config.base16.schemes.default.listed;`
TODO: more examples

## Exported packages
This flake exports a `pybase16-builder` package, the builder used in this repo for building mustache templates,
[github page of the pybase16-builder](https://github.com/InspectorMustache/base16-builder-python).

## Alternatives
- [atpotts base16-nix](https://github.com/atpotts/base16-nix) and its forks, notably
[lukebfox's base16-nix](https://github.com/lukebfox/base16-nix) and [AlukardBFs base16-nix](https://github.com/AlukardBF/base16-nix),
- [misterio's nix-colors](https://git.sr.ht/~misterio/nix-colors).
- [rycee's theme-base16](https://gitlab.com/rycee/nur-expressions/-/tree/master/hm-modules/theme-base16)

## Acknowledgments
Special thanks to:
- cab404 for theirs [genix7000 - icon generator for nix projects](https://github.com/cab404/genix7000),
- misterio for his [flavours - base16 manager and builder](https://github.com/misterio77/flavours),
