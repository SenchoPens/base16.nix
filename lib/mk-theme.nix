{ lib, pkgs, msg, success-monad, yaml2attrs, writeTextFile', writeTextFile'', check-parsed-yaml, sm-or, ... }:
let
  /* Builds a theme file from a scheme and a template and returns its path.
     If you do not supply `templateRepo`, then
     you need to supply both `template` and `extension`.
  */
  mkTheme = {
    # A scheme attrset returned from `mkSchemeAttrs` function
    scheme,
    # A directory with a `templates` subdirectory (containing templates and a `config.yaml` file)
    # (e.g. a flake input of a template repository).
    templateRepo ? null,
    # Name of the template to lookup in templateRepo.
    # Must be one of the top-level targets from `${templateRepo}/templates/config.yaml` and
    # correspond to a template `${templateRepo}/templates/${targetTemplate}.mustache`.
    target ? "default",
    # A string with mustache template.
    # If is `null`, then `${templateRepo}/templates/${target}.mustache` is used.
    template ? null,
    # An extension (e.g. ".config") with which to save the resulting theme file.
    # If is `null` and `templateRepo` is passed, the extension will be grabbed from there,
    # otherwise it's an empty string
    extension ? null,
    # Whether to use [IFD](https://nixos.wiki/wiki/Import_From_Derivation) to parse yaml.
    # One of "always", "auto", "never". The default is "never".
    # "always" and "auto" can cause problems with `nix flake check / show` (see the issue #3).
    use-ifd ? "never",
    # Whether to check if the config.yaml was parsed correctly.
    check-parsed-config-yaml ? true,
  }:
    let
      config-yaml =
        if (extension == null && templateRepo != null) then
          "${templateRepo}/templates/config.yaml"
        else
          null;
      check-parsed-config-yaml' = config-yaml != null && check-parsed-config-yaml && use-ifd != "always";
      get-extension = parsed:
        let
          safe-accessor = name: {
            f = value: { success = value?${name}; value = value.${name}; };
          };
          get-new-format-ext = {
            f = value: {
              success = value ? "filename";
              value = if lib.hasInfix "." value.filename
                then ''.${lib.last (lib.splitString "." value.filename)}''
                else "";
            };
          };
          ext-must-be-string = {
            f = extension: { success = builtins.isString extension; value = extension; };
          };
        in success-monad parsed (safe-accessor target)
          (sm-or
            (safe-accessor "extension")
            get-new-format-ext
          ) ext-must-be-string;
      parsed-config = yaml2attrs { yaml = config-yaml; inherit use-ifd; check = get-extension; };
      ext =
        if extension != null then extension
        else if templateRepo == null then ""
        else let checked-ext = get-extension parsed-config;
          in if checked-ext.success then checked-ext.value
             else builtins.trace msg.config-check-failed "";
      themeFilename = "base16-${scheme.scheme-slug}${ext}";
      templatePath =
        let target' = lib.escapeShellArg "${target}.mustache"; in
        if template == null then
          "${templateRepo}/templates/${target'}"  # escaped
        else if lib.isPath template then
          template  # treated as already escaped
        else if lib.isDerivation template then
          template.outPath  # treated as already escaped
        else
          writeTextFile'' "${target}.mustache" template  # escaped
        ;
      # Taken from https://pablo.tools/blog/computers/nix-mustache-templates/
      themeDerivation = pkgs.stdenv.mkDerivation {
        name = "${builtins.unsafeDiscardStringContext scheme.scheme-slug}";
        allowSubstitutes = false;
        preferLocalBuild = true;
        nativeBuildInputs = [ pkgs.mustache-go ]
          ++ lib.optional check-parsed-config-yaml' (check-parsed-yaml config-yaml parsed-config);
        # Pass JSON as file to avoid escaping
        passAsFile = [ "jsonData" ];
        jsonData = builtins.toJSON (builtins.removeAttrs scheme [ "outPath" "override" "check" "__functor" ]);
        # Disable phases which are not needed. In particular the unpackPhase will
        # fail, if no src attribute is set
        phases = [ "buildPhase" "installPhase" ];
        buildPhase = ''
          mustache "$jsonDataPath" ${templatePath} > theme
        '';
        installPhase = ''
          mkdir $out
          cp theme $out/${lib.escapeShellArg themeFilename}
        '';
      };
    in "${themeDerivation}/${themeFilename}";
in { inherit mkTheme; }
