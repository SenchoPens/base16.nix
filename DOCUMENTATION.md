# Documentation

The documentation fully explains how everything works.

## Module
_defined in [module.nix](module.nix)_

- Adds a `scheme` option to be set to whatever `mkSchemeAttrs` accepts (see below).
  When used as a value, `scheme` will be equal to `mkSchemeAttrs scheme`.
- Sets `config.lib.base16.mkSchemeAttrs`.

As you can see, it's tiny. That's because the business logic is done by the library:

## Library
_defined in [default.nix](default.nix)_

Access it as:
- `config.lib.base16` if using `base16.nix` as a NixOS module,
- `pkgs.callPackage inputs.base16.lib {}` otherwise.

It exports just 1 function:

### `mkSchemeAttrs`

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
  and meta attributes (`scheme`, `slug` and `author`), see [How To](README.md#-how-to) section,
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
