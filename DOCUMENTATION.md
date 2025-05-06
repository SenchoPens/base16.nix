# Documentation

## Module ([module.nix](module.nix))

- Adds a `scheme` option to be set to whatever `mkSchemeAttrs` accepts (see below).
  When used as a value, `scheme` will be equal to `mkSchemeAttrs scheme`.
- Sets `config.lib.base16.mkSchemeAttrs`.

Essentially, the module is a NixOS / home-manager interface to the library.

## Library ([lib](lib/default.nix))

Access it as:
- `config.lib.base16` if using `base16.nix` as a NixOS module,
- `pkgs.callPackage inputs.base16.lib {}` otherwise.

It exports 1 function:

### `mkSchemeAttrs`

Given a [scheme](https://github.com/base16-project/home/blob/main/builder.md#schemes-repository),
which is **either**
- a path to a YAML file,
- an attrset containing colors,
- an argument attrset to `yaml2attrs`,
which
- MUST contain string attributes `baseXX`,
- MAY contain string attributes `scheme`, `author`, `description`, `slug`,


returns a _scheme attrset_ with a ton of convenient color attributes:

- every attribute from [the base16 standard](https://github.com/base16-project/base16/blob/main/builder.md#template-variables),
- attributes `baseXX = baseXX-hex`, e.g. `base00 = "000000"`;
- `toList = [ base00 ... base0F ]`, for use in e.g. `config.console.colors`,
- mnemonic color names for `base08` — `base0F` and `base12` — `base17`:
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
    bright-red = base12 or base08;
    bright-yellow = base13 or base0A;
    bright-green = base14 or base0B;
    bright-cyan = base15 or base0C;
    bright-blue = base16 or base0D;
    bright-magenta = base17 or base0E;
  };
  ```

Other cool stuff:
- `withHashtag` — a scheme with `#` prepended to colors;
- meta attributes: `scheme-name` & `scheme`, `scheme-author` & `author`, `scheme-slug` & `slug`, `scheme-description` & `description`;
- `override` — a function to override the colors (via `baseXX`)
  and meta attributes (`scheme`, `slug` and `author`), see the relevant entry in the [How To](README.md#-how-to) section;
- `outPath` — an attribute for coercion to the scheme's path, i.e. `"${config.scheme}"` equals to a path to a yaml file with the scheme;
- `__functor` — an attribute for coercion to a function: if you use _scheme attrs_ as a function, it will call `mkTheme` by passing the scheme as `scheme` and the argument you called _scheme attrs_ with as `templateRepo` (if it's a derivation or a flake input), otherwise it passes `argument // { scheme = `_scheme attrs_` }`.

Note: `∀ x . mkSchemeAttrs (mkSchemeAttrs x) == mkSchemeAttrs x`
</blockquote></details>

---

The function below isn't exported, but it's what powers up the _scheme attrset_'s `__functor` attribute:

#### `mkTheme`

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
```

#### `yaml2attrs`

Given a path to a YAML file, converts its' contents to a Nix attrset in pure Nix.
- On `use-ifd = "never"` (default), may fail on complex YAMLs.
- On `use-ifd = "always"`, converts the file's contents to a Nix attrset using `yaml2json` package. Causes an [IFD](https://nixos.wiki/wiki/Import_From_Derivation). Isn't used by default, but can help if you're experiencing troubles with incorrectly parsed YAML files (see README Troubleshooting section for details).
- On `use-ifd = "auto"`, causes an IFD if recognizes a complex YAML on which nix parser fails.
