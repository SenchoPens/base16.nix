# Documentation

## Module ([module.nix](module.nix))

- Adds a `scheme` option to be set to whatever `mkSchemeAttrs` accepts (see below).
  When used as a value, `scheme` will be equal to `mkSchemeAttrs scheme`.
- Sets `config.lib.base16.mkSchemeAttrs`.

As you can see, it's tiny. That's because the business logic is done by the library:

## Library ([default.nix](default.nix))

Access it as:
- `config.lib.base16` if using `base16.nix` as a NixOS module,
- `pkgs.callPackage inputs.base16.lib {}` otherwise.

It exports 3 functions:

### `mkSchemeAttrs`

Given a [scheme](https://github.com/base16-project/home/blob/main/builder.md#schemes-repository),
which is **either**
- a path to a YAML file,
- an attrset,
which
- MUST contain string attributes `baseXX`,
- MAY contain string attributes `scheme`, `author`, `description`, `slug`,


returns a _scheme attrset_ with a ton of convenient color attributes:

- every attribute from [the base16 standard](https://github.com/base16-project/base16/blob/main/builder.md#template-variables),
- attributes `baseXX = baseXX-hex`, e.g. `base00 = "000000"`;
- `toList = [ base00 ... base0F ]`, for use in e.g. `config.console.colors`,
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
- `withHashtag` — a scheme with `#` prepended to colors,
- meta attributes: `scheme-name` & `scheme`, `scheme-author` & `author`, `scheme-slug` & `slug`, `scheme-description` & `descriptio`,
- `override` — a function to override the colors (via `baseXX`)
  and meta attributes (`scheme`, `slug` and `author`), see [How To](README.md#-how-to) section,
- `outPath` — a magic attribute that guarantees that`"${config.scheme}"` equals to a path to a yaml file with the scheme,
- `__functor` — a magic attribute that calls `mkTheme` if you use _scheme attrs_ as a function:
  it passes the scheme as `scheme` and the argument as `templateRepo` (if it's a derivation or a flake input),
  otherwise it passes `argument // { scheme = `_scheme attrs_` }`

Note: `∀ x . mkSchemeAttrs (mkSchemeAttrs x) == mkSchemeAttrs x`
</blockquote></details>

### `yaml2attrs`
Given a path to a YAML file, converts its' contents to a Nix attrset in pure Nix. May fail on complex YAMLs.

### `yaml2attrs-ifd`
Given a path to a YAML file, converts its' contents to a Nix attrset using `yaml2json` package. Causes an [IFD](https://nixos.wiki/wiki/Import_From_Derivation). Isn't used by default, but can help if you're experiencing troubles with incorrectly parsed YAML files (see README Troubleshooting section for details).

---

The function below isn't exported, but it's what powers up the _scheme attrset_'s `__functor` attribute:

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
  # Whether to use [IFD](https://nixos.wiki/wiki/Import_From_Derivation) to parse yaml.
  # Can cause problems with `nix flake check / show` (see the issue #3).
  use-ifd ? false,
  # Whether to check if the config.yaml was parsed correctly.
  check-parsed-config-yaml ? true,
}:
