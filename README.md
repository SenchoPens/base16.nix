![logo](./logo.png)

# base16.nix

_1 configuration option, 16 colors_

![demo](./demo.gif)

#### What's base16?

base16 is a standard for specifying colorschemes and application
configuration templates, that produced a lot of templates and schemes
over the years. `base16.nix` makes using them in NixOS as easy as
possible, while retaining much flexibility.

### Features

With `base16.nix`, you can:
- theme any application that has a base16 template in minimal amount of key strokes;
- use existing schemes, override them or create your own from scratch;

This flake provides:
- a function to create a scheme attrset from a scheme,
  that can further be used to create base16 (base24 is also supported)
  themes from templates.
- a NixOS module,
- a home-manager module.

### Nonfeatures

This project does not attempt to:
- aggregate schemes or templates, as you can discover most of them through
  [base16 repository](https://github.com/chriskempson/base16)
- support EJS templates, which are part of the
  [base16-builder/base16-builder](https://github.com/base16-builder/base16-builder)
  repository, as it has been long time abandoned and almost all of the EJS templates
  have mustache alternatives.

## Module example (covers majority of use-cases)

In this example, we will use base16.nix as a NixOS module to theme
`zathura`, `neovim` and `alacritty` to use colors of
[eva scheme](https://github.com/kjakapat/eva-theme)
(home-manager module works the same way).

### Setup

- Open your NixOS configuration's `flake.nix` file.
- Optionally, open [base16 repository](https://github.com/chriskempson/base16#template-repositories)
  to pick a scheme and templates you want to use, in this tutorial we already chose them.
- Add `base16.nix`, `eva` scheme and
  [zathura](https://github.com/HaoZeke/base16-zathura) and
  [vim](https://github.com/chriskempson/base16-vim) templates to the flake inputs.
- Import `base16.nix` module.
- Add `eva` scheme to config under `config.scheme` path.
- Import `theming.nix`, a file we will write in the next (and final) step.

`flake.nix`
```nix
inputs = {
  base16.url = "/home/sencho/code/github.com/SenchoPens/base16.nix";
  base16.inputs.nixpkgs.follows = "nixpkgs";

  base16-eva-scheme = {
    url = github:kjakapat/base16-eva-scheme;
    flake = false;
  };

  base16-fzf = {
    url = github:fnune/base16-fzf;
    flake = false;
  };

  base16-zathura = {
    url = github:haozeke/base16-zathura;
    flake = false;
  };
  ...
};
outputs = { self, ... }@inputs {
  ...
    nixosSystem {
      modules = [
        base16.nixosModule
        { scheme = "${inputs.base16-eva-scheme}/eva.yaml"; }
        theming.nix
        ...
      ];
      specialArgs = {
        inherit inputs;
      };
      ...
    };
  ...
};
...
```

### Theming

- Theme `zathura`.
  Now that `config.scheme` is set, we can use it like a function to
  create a theme from a template.
- Theme `neovim` - more complex, but the principle is the same.
- Theme `alacritty`. home-manager doesn't provide an `extraConfig`,
  but gives us `settings.colors` option of attrs type to set colors. 
  As alacritty expects colors to begin with '#', we use an attribute `withHashtag`.
  Notice that we now use `config.scheme` as an attrset, and that this attrset,
  besides from having attributes `base00`...`base0F`, has mnemonic attributes (`red`, etc.) -
  read more on that in the next section.

`theming.nix`
```nix
{ config, pkgs, inputs, ... }:
{
  home-manager.users.sencho.programs.zathura.extraConfig =
    builtins.readFile (config.scheme inputs.base16-zathura);

  home-manager.users.sencho.programs.neovim = {
    plugins = [ (pkgs.vimPlugins.base16-vim.overrideAttrs (old:
      let schemeFile = config.scheme inputs.base16-vim;
      in { patchPhase = ''cp ${schemeFile} colors/base16-scheme.vim''; }
    )) ];
    extraConfig = ''
      set termguicolors
      colorscheme base16-scheme
      set background=dark
      let base16colorspace=256
    '';
  };

  home-manager.users.sencho.programs.alacritty.settings.colors =
    with config.scheme.withHashtag; let default = {
        black = base00; white = base07;
        inherit red green yellow blue cyan magenta;
      };
    in {
      primary = { background = base00; foreground = base07; };
      cursor = { text = base02; cursor = base07; };
      normal = default; bright = default; dim = default;
    };
}
```

That's all, we themed 3 applications!

## Advanced examples and usage as a library

_Assuming you read the previous section._

### All the ways to set `config.scheme`:

- Specifying a scheme by a yaml file:
```nix
config.scheme = "${inputs.base16-eva-scheme}/eva-dim.yaml";
```
- Overriding a scheme. Now we need to explicitely use `mkSchemeAttrs` function
  to use `override` field of the resulting scheme attrs:
```nix
config.scheme = (config.lib.base16.mkSchemeAttrs "${inputs.base16-eva-scheme}/eva-dim.yaml").override {
  scheme = "Now it's my scheme >:]";
  base00 = "000000";  # make background completely black
};
```
- Specifying a scheme from scratch in Nix,
  [source](https://code.balsoft.ru/balsoft/nixos-config/src/branch/master/modules/themes.nix)
```nix
{
  slug = "balsoftheme"; scheme = "Theme by balsoft"; author = "balsoft";
  base00 = "000000"; base01 = "333333"; base02 = "666666"; base03 = "999999";
  base04 = "cccccc"; base05 = "ffffff"; base06 = "e6e6e6"; base07 = "e6e6e6";
  base08 = "bf4040"; base09 = "bf8040"; base0A = "bfbf40"; base0B = "80bf40";
  base0C = "40bfbf"; base0D = "407fbf"; base0E = "7f40bf"; base0F = "bf40bf";
};
```

### Multiple schemes and usage as a library, without importing to NixOS

You can apply a template to a scheme without going through `config.scheme` option.

Example of theming `zathura` without `config.scheme` - by calling `mkSchemeAttrs`:
```nix
home-manager.users.sencho.programs.zathura.extraConfig =
  builtins.readFile (config.lib.base16.mkSchemeAttrs inputs.base16-eva-scheme inputs.base16-zathura);
```

or like this, without importing `base16.nix` as a module at all:

```nix
home-manager.users.sencho.programs.zathura.extraConfig =
  builtins.readFile (inputs.base16.lib.mkSchemeAttrs inputs.base16-eva-scheme inputs.base16-zathura);
```

### More on mustache templates

Base16 template repositories often provide more than one template.
For example, [zathura](https://github.com/HaoZeke/base16-zathura) template repository
provides `default.mustache` and `recolor.mustache` templates (the latter will override the colors of the pdf itself).
By default, `base16.nix` will always use the `default.mustache` template,
so, if you want to use the `recolor` one, write this:
```nix
home-manager.users.sencho.programs.zathura.extraConfig =
  builtins.readFile (config.scheme { templateRepo = inputs.base16-zathura; target = "recolor"; });
```
or this:
```nix
home-manager.users.sencho.programs.zathura.extraConfig =
  builtins.readFile (inputs.base16.lib.mkSchemeAttrs inputs.base16-eva-scheme
    { templateRepo = inputs.base16-zathura; target = "recolor"; });
```

Now, suppose you like the `default.mustache`, but want to change the background from `base00` to `base01`.
You can use `override`:
```nix
home-manager.users.sencho.programs.zathura.extraConfig =
  builtins.readFile (config.scheme.override {
      base00 = config.scheme.base01;
    } inputs.base16-zathura);
```
But, unfortunately, in this template it will not only change the `default-bg` color, but also `inputbar-bg`,
`notification-bg`, etc. Then we can copy-paste the template entirely and change what we want:
```nix
home-manager.users.sencho.programs.zathura.extraConfig =
  builtins.readFile (config.scheme { template = ''
    ... 
    set default-bg   "#{{base01-hex}}"  # <-- we changed this
    set default-fg   "#{{base01-hex}}"

    set statusbar-fg "#{{base04-hex}}"
    set statusbar-bg "#{{base02-hex}}"
    ...
   '');
```

## Full documentation (explanation of previous sections)

How did that happen, that after we set `config.scheme` to a string,
we then use it as a function (to theme `zathura` and `neovim`) and as an attrset (to theme `alacritty`)?
Because `base16.nix` applies `config.lib.base16.mkSchemeAttrs` function to 
the value the `config.scheme` was set to.

### `mkSchemeAttrs`

Given a scheme (either a path to a `.yaml` file or an attrset), `mkSchemeAttrs` returns a scheme attrset.
If an attrset is passed, it must contain attributes you would
expect a scheme `.yaml` file to have (see the last example in the previous section).
Also, the following holds: `forall x . mkSchemeAttrs (mkSchemeAttrs x) == mkSchemeAttrs x`.

You can access it as either `config.lib.base16.mkSchemeAttrs` or `inputs.base16.lib.mkSchemeAttrs`.

Returns an attrset (so-called scheme attrset), that has:
- the colors that the builder should provide, listed in
  [base16 documentation](https://github.com/chriskempson/base16/blob/master/builder.md#template-variables)

  For convenience, attributes in the form `baseXX` are provided, equal to
  `baseXX-hex`, along with a `toList` attribute, which is equial to `[ base00 ... base0F ]`
  (mainly for `config.console.colors`).  Also, mnemonic color names for `base08` - `base0F` are provided:
```nix
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
- meta attributes: `scheme-name` and `scheme`, `scheme-author` and `author`, `scheme-slug` and `slug` (used for filenames),
- `override` - a function with which you can override the colors (attributes `baseXX`),
  and meta attributes (`scheme`, `slug` and `author`).
- `withHashtag` - a scheme with '#' prepended to colors.
- `__functor` - a magic attribute that calls `mkTheme` on call to scheme attrs,
  and passes it the current scheme as `scheme` argument, and,
  if an argument is a derivation or a flake input, it is passed to `mkTheme` as `templateRepo` argument.
- `outPath` - with it you can write `"${config.scheme}"` and get a path to a yaml file containing the current scheme.

### `mkTheme`

This function isn't exported, but it powers up the `__functor` attribute.
It builds a theme file from a scheme and a template and returns its path.
If you do not supply `templateRepo`, then you need to supply both `template` and `extension`.
It is declared as follows:

```nix
mkTheme = {
  # A scheme attrset returned from `mkSchemeAttrs` function.
  scheme,
  # A directory with a `templates` subdirectory (containing templates and a `config.yaml` file)
  # (e.g. a flake input of a template repository).
  templateRepo ? null,
  # Name of the template to lookup in templateRepo.
  # Must be one of the top-level targets from `${templateRepo}/templates/config.yaml` and
  # correspond to a template `${templateRepo}/templates/${targetTemplate}.mustache`.
  target ? "default",
  # A string with mustache template.
  # If is `null`, then `${templateRepo}/templates/${targetTemplate}.mustache` is used.
  template ? null,
  # An extension (e.g. ".config") with which to save the resulting theme file.
  # If is `null` and `templateRepo` is passed, the extension will be grabbed from there,
  # otherwise it's an empty string
  extension ? null,
}:
```

## Repositories that use base16.nix
Flake NixOS modules:
- [Stylix](https://github.com/danth/stylix) — System-wide colorscheming and typography for NixOS.
- [tmux-flake](https://github.com/VTimofeenko/tmux-flake) — a flake that configures tmux.

Configs by:
- [pborzenkov](https://github.com/pborzenkov/nix-config)
- [nryz](https://github.com/nryz/config)
- [MoritzBoehme](https://github.com/MoritzBoehme/dotfiles)
- [IllustratedMan-code](https://github.com/IllustratedMan-code/nixconfig)

Please feel free to list your repository above, it will make my day :)

## Alternatives

- [base16-nix](https://github.com/atpotts/base16-nix) by @atpotts and its forks, notably
[base16-nix](https://github.com/AlukardBF/base16-nix) by @AlukardBF and [base16-nix](https://github.com/lukebfox/base16-nix) by @lukebfox.
- [nix-colors](https://git.sr.ht/~misterio/nix-colors) by @misterio, differences:
  
  `base16.nix` tries to have a rather minimalistic interface, exporting 1
  configuration option and 1 function, but provide a plenty of ergonomic
  logic within, to give user a way to configure maximum amount of
  applications with minimum effort, because I think that's the point
  of base16 - you pick an ideal for you scheme, almost without making
  compromises, and you want 99-100% of your applications to use this
  scheme.

  So, the goal I was up to is not to provide a quick way to theme some popular
  applications with some popular schemes, `nix-colors` with its libraries might do
  that better, but to provide a general way to theme any application with any
  scheme and to easily override it to your liking. With `base16.nix`, maybe you will
  spend some more time on, say, generating a GTK theme, but you won't spend an
  hour trying to figure out how to theme that one small not-so-popular app or how
  to adjust a template a bit, or how to use a beautiful scheme you just found on
  the internet, but with another orange color.

- [theme-base16](https://gitlab.com/rycee/nur-expressions/-/tree/master/hm-modules/theme-base16) by @rycee.

## Help

If you need any help on how to use this module, feel free to open an issue or
contact me via email or telegram ([my contacts are here](https://github.com/SenchoPens)).

## Acknowledgments

Thanks to:
- @balsoft for [nixos-config](https://code.balsoft.ru/balsoft/nixos-config),
  which inspired this library;
- @cab404 for [Genix7000 - icon generator for nix projects](https://github.com/cab404/genix7000);
- @chriskempson for creating [base16](https://github.com/chriskempson/base16)
  and @belak for maintaining it;
- @mmanchkin for guiding me in Nix, NixOS and life.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)
