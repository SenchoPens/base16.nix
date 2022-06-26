![logo](./logo.svg)

![demo](./demo.gif)

#### What's base16 and base16.nix?

- [base16](https://github.com/base16-project/base16) is a theming standard by
  which hundreds of
  [colorschemes](https://github.com/base16-project/base16-schemes)
  and application configuration
  [templates](https://github.com/base16-project/base16#template-repositories)
  were made over the years.
- `base16.nix` is a **NixOS** / **home-manager** module and a library that
  makes using base16 / base24 schemes and templates as **simple** as
  possible, while leaving the user full **flexibility**.

### Features

With `base16.nix`, you can:
- use existing schemes, override them, write a new one in YAML / nix;
- theme any application with a base16 template in minimal amount of key strokes,
  or write a new template in [mustache](https://mustache.github.io/) / nix.

### Nonfeatures

- `base16.nix` is simply a <sub>ultrasupermega convenient</sub> <sup>battle-tested</sup>
  nix-y base16 standard implementation, **not a** _ricing_ engine — but if you want one,
  please check out every r/unixporn admin's dream — [Stylix](https://github.com/danth/stylix)! built with `base16.nix`!
- `base16.nix` neither aggregates nor vendors schemes / templates to **keep data and logic separated**.
- No support for legacy template formats like
  [Embedded Ruby](https://github.com/ntpeters/base16-template-converter)
  and [EJS](https://github.com/base16-builder/base16-builder/issues/174).

## 👀 Module example (covers majority of use-cases)

In this example, we will use `base16.nix` as a NixOS module to theme
`zathura`, `neovim` and `alacritty` to use the `nord` scheme in two steps — setup and theming.
(home-manager module works the same way).

### 1. Setup

In your configuration's `flake.nix`:

`flake.nix`
```nix
{ inputs = {
  # Add base16.nix, base16 schemes and
  # zathura and vim templates to the flake inputs.
  base16.url = "/home/sencho/code/github.com/SenchoPens/base16.nix";
  base16.inputs.nixpkgs.follows = "nixpkgs";

  base16-schemes = {
    url = github:base16-project/base16-schemes;
    flake = false;
  };

  base16-zathura = {
    url = github:haozeke/base16-zathura;
    flake = false;
  };

  base16-vim = {
    url = github:base16-project/base16-vim;
    flake = false;
  };
  ...
};
outputs = { self, ... }@inputs {
  ...
    nixosSystem {
      modules = [
        # import the base16.nix module
        base16.nixosModule
        # set system's scheme to nord by setting `config.scheme`
        { scheme = "${inputs.base16-schemes}/nord.yaml"; }
        # import `theming.nix`, we will write it in the next, final, step
        theming.nix
        ...
      ];
      # so you can use `inputs` in config files
      specialArgs = {
        inherit inputs;
      };
      ...
    };
  ...
};
... }
```

### 2. Theming

Now that `config.scheme` is set, we can use it like a function to
create themes from templates.

`theming.nix`
```nix
{ config, pkgs, inputs, ... }:
{
  # Theme zathura
  home-manager.users.sencho.programs.zathura.extraConfig =
    builtins.readFile (config.scheme inputs.base16-zathura);

  # Theme `neovim` — more complex, but the principle is the same.
  home-manager.users.sencho.programs.neovim = {
    plugins = [ (pkgs.vimPlugins.base16-vim.overrideAttrs (old:
      let schemeFile = config.scheme inputs.base16-vim;
      in { patchPhase = ''cp ${schemeFile} colors/base16-scheme.vim''; }
    )) ];
    extraConfig = ''
      set termguicolors background=dark
      let base16colorspace=256
      colorscheme base16-scheme
    '';
  };

  # Theme `alacritty`. home-manager doesn't provide an `extraConfig`,
  # but gives us `settings.colors` option of attrs type to set colors. 
  # As alacritty expects colors to begin with `#`, we use an attribute `withHashtag`.
  # Notice that we now use `config.scheme` as an attrset, and that this attrset,
  # besides from having attributes `base00`...`base0F`, has mnemonic attributes (`red`, etc.) -
  # read more on that in the next section.
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

<blockquote>

The attentive reader will notice that after setting `config.scheme` to a <ins>string</ins>,
we use it as a <ins>function</ins> (to theme `zathura` and `neovim`)
and as an <ins>attrset</ins> (to theme `alacritty`) — that's `base16.nix`' magic!
Read the **Documentation** section to see how it works.
</blockquote>

## 🍳 Cookbook

### Setting `config.scheme`

<details><summary>Importing a scheme from a YAML file</summary><blockquote>

```nix
config.scheme = "${inputs.base16-schemes}/nord.yaml";
```
</blockquote></details>

<details><summary>Overriding a scheme</summary><blockquote>

Now we need to explicitly use `mkSchemeAttrs` function
to use the `override` field of the resulting scheme attrs:
```nix
config.scheme = (config.lib.base16.mkSchemeAttrs "${inputs.base16-schemes}/nord.yaml").override {
  scheme = "Now it's my scheme >:]";
  base00 = "000000";  # make background completely black
};
```
</blockquote></details>

<details><summary>Declaring a scheme in Nix</summary><blockquote>

```nix
config.scheme = {
  slug = "balsoftheme"; scheme = "Theme by balsoft"; author = "balsoft";
  base00 = "000000"; base01 = "333333"; base02 = "666666"; base03 = "999999";
  base04 = "cccccc"; base05 = "ffffff"; base06 = "e6e6e6"; base07 = "e6e6e6";
  base08 = "bf4040"; base09 = "bf8040"; base0A = "bfbf40"; base0B = "80bf40";
  base0C = "40bfbf"; base0D = "407fbf"; base0E = "7f40bf"; base0F = "bf40bf";
};
```
[source](https://code.balsoft.ru/balsoft/nixos-config/src/branch/master/modules/themes.nix)
</blockquote></details>

<details><summary>Using the library to theme with multiple schemes simultaneously</summary><blockquote>

You can apply a template to a scheme without going through `config.scheme` option.

Example of theming `zathura` without `config.scheme` — by calling `mkSchemeAttrs`:
```nix
home-manager.users.sencho.programs.zathura.extraConfig =
  builtins.readFile (config.lib.base16.mkSchemeAttrs inputs.base16-schemes inputs.base16-zathura);
```

or like this, without importing `base16.nix` as a module at all:

```nix
home-manager.users.sencho.programs.zathura.extraConfig =
  builtins.readFile ((pkgs.callPackage inputs.base16.lib {}).mkSchemeAttrs inputs.base16-schemes inputs.base16-zathura);
```

</blockquote></details>

<details><summary>Changing a template's variant</summary><blockquote>

Base16 template repositories often provide **multiple** templates.
For example, [zathura](https://github.com/HaoZeke/base16-zathura) template repository
provides `default.mustache` **and** `recolor.mustache` templates
(the latter being used to color pdfs by the colorscheme along with the interface).
By default, `base16.nix` will use the `default.mustache` template,
so if you want to use e.g. the `recolor` one, write this:
```nix
home-manager.users.sencho.programs.zathura.extraConfig =
  builtins.readFile (config.scheme { templateRepo = inputs.base16-zathura; target = "recolor"; });
```
</blockquote></details>

<details><summary>Overriding a template</summary><blockquote>

Suppose you like the `default.mustache`, but want to **change** the background from `base00` to `base01`.
You can use the scheme's `override` method:
```nix
home-manager.users.sencho.programs.zathura.extraConfig =
  builtins.readFile (config.scheme.override {
      base00 = config.scheme.base01;
    } inputs.base16-zathura);
```
But, unfortunately, in this template it will not only change the `default-bg` color, but also `inputbar-bg`,
`notification-bg`, etc. All that's left is to copy-paste the template and change it how we want:
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
</blockquote></details>


## 📚 Documentation

### Module (`module.nix`)

- Adds a `scheme` option to be set to whatever `mkSchemeAttrs` accepts (see below).
  When used as a value, `scheme` will be equal to `mkSchemeAttrs scheme`.
- Sets `config.lib.base16.mkSchemeAttrs`.

As you can see, it's tiny. That's because the business logic is done by the library:

### Library (`default.nix`)

Access it as `config.lib.base16` if using `base16.nix` as a NixOS module, otherwise as `pkgs.callPackage inputs.base16.lib {}`.

It provides just 1 function:

#### `mkSchemeAttrs`
<details>
<summary>🙃</summary><blockquote>

Given a scheme, which is **either**
- a path to a YAML file,
- a string in YAML format,
- an attrset with attributes `baseXX` and optionally `scheme` and `author`,

returns a _scheme attrset_ with a ton of convenient color attributes:

- **Most** importantly, every attribute from [the base16 standard](https://github.com/base16-project/base16/blob/main/builder.md#template-variables),
- Attributes `baseXX = baseXX-hex`, e.g. `base00 = "000000"`;
- `toList = [ base00 ... base0F ]`, e.g. for `config.console.colors`,
- mnemonic color names for `base08` — `base0F`:
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

Other cool stuff:
- `withHashtag` — a scheme with `#` prepended to colors.
- meta attributes: `scheme-name` and `scheme`, `scheme-author` and `author`, `scheme-slug` and `slug` (used for filenames),
- `override` — a function to override the colors (via `baseXX`)
  and meta attributes (`scheme`, `slug` and `author`), see **Cookbook** section,
- `outPath` — so you can write `"${config.scheme}"` to get a yaml file path with the scheme.
- `__functor` — a magic attribute that calls `mkTheme` if you use _scheme attrs_ as a function:
  it passes the scheme as `scheme` and the argument as `templateRepo` (if it's a derivation or a flake input),
  otherwise it passes `argument // { scheme = `_scheme attrs_` }`

Note: `∀ x . mkSchemeAttrs (mkSchemeAttrs x) == mkSchemeAttrs x`
</blockquote></details>

This function isn't exported, but it's what powers up the _scheme attrset_'s `__functor` attribute:

#### `mkTheme`
<details><summary>🙃</summary><blockquote>

Builds a theme file from a scheme and a template and returns its path.
If you don't supply `templateRepo`, then supply both `template` and `extension`.

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
</blockquote></details>

## 🤍 Repositories that use base16.nix

Flake NixOS modules:
- [Stylix](https://github.com/danth/stylix) — System-wide colorscheming and typography for NixOS.
- [tmux-flake](https://github.com/VTimofeenko/tmux-flake) — a flake that configures tmux.

Configs by:
- [pborzenkov](https://github.com/pborzenkov/nix-config)
- [nryz](https://github.com/nryz/config)
- [MoritzBoehme](https://github.com/MoritzBoehme/dotfiles)
- [IllustratedMan-code](https://github.com/IllustratedMan-code/nixconfig)

Please feel free to list your repository above, it will make my day :)

## ⚔️ Alternatives

- [base16-nix](https://github.com/atpotts/base16-nix) by @atpotts and its forks, notably
[base16-nix](https://github.com/AlukardBF/base16-nix) by @AlukardBF and [base16-nix](https://github.com/lukebfox/base16-nix) by @lukebfox.
- [nix-colors](https://git.sr.ht/~misterio/nix-colors) by @misterio,
  <details><summary>differences:</summary><blockquote>
  Roughly nix-colors can be viewed as an alternative
  to `base16.nix` + [Stylix](https://github.com/danth/stylix),
  without the mustache template support:
  
  `base16.nix` supports the existing
  [≥ 80 mustache templates](https://github.com/base16-project/base16/blob/main/README.md#official-templates),
  nix-colors does not — instead there are
  [≥ 4 contributed nix functions](https://github.com/Misterio77/nix-colors/tree/308fe8855ee4c35347baeaf182453396abdbe8df/lib/contrib)
  and planned (at the time of writing) support for translation from mustache templates to nix functions.
  Stylix has [≥ 10 Stylix theming nix functions](https://github.com/danth/stylix/tree/master/modules).

  You can generate base16 scheme from a wallpaper — in nix-colors via
  [flavours](https://github.com/Misterio77/flavours)
  and in Stylix via home-made CIE-LAB colorspace Haskell genetic algorithm.

  Also, if you use nix-colors without it's nix functions, it does not depend on nixpkgs.
  </blockquote></details>
- [theme-base16](https://gitlab.com/rycee/nur-expressions/-/tree/master/hm-modules/theme-base16) by @rycee.

## ☎️ Help

If you need any help, feel free to open an issue or
contact me via email or telegram ([my contacts are here](https://github.com/SenchoPens)).

## 💙 Acknowledgments

Thanks to:
- @balsoft for [nixos-config](https://code.balsoft.ru/balsoft/nixos-config),
  which inspired this library;
- @cab404 for [Genix7000 — icon generator for nix projects](https://github.com/cab404/genix7000);
- @chriskempson for creating base16
  and @belak and base16-project team for maintaining it;
- @mmanchkin for being a great support and **mastermind** behind all of this.

## 👩‍💻 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)
