{ lib, pkgs, msg, mkTheme, yaml2attrs, check-parsed-yaml, normalize-colors, writeTextFile', colors, mkBase24, convert-scheme-to-common-format, ... }:
let
  #---------#
  # HELPERS #
  #---------#

  is-yaml2attrs-args = args: args ? "yaml";

  parse-scheme = yaml2attrs-args: {
    slug = lib.removeSuffix ".yaml" (
      builtins.baseNameOf (
        builtins.unsafeDiscardStringContext "${yaml2attrs-args.yaml}"
    )); 
    scheme = yaml2attrs yaml2attrs-args;
  };

  /* Handles sum type input of the mkSchemeAttrs.
     Given an input which is either a file or an attrset,
     returns an attrset and a check derivation.
  */
  yaml-scheme2attrs = scheme:
    let
      is-y2a-args = is-yaml2attrs-args scheme;
      yaml2attrs-args =
        if is-y2a-args
        then scheme
        else { yaml = scheme; };
      is-not-parsed = builtins.isAttrs scheme && !is-y2a-args;
      parsed = parse-scheme yaml2attrs-args;
      parsedInput' =
        let
          raw = if is-not-parsed then scheme else parsed.scheme;
          unchecked = convert-scheme-to-common-format raw;
          checked = normalize-colors msg.scheme-check-failed unchecked;
        in if checked.success then unchecked else throw ''
          ${msg.bad-mkSchemeAttrs-input}
          builtins.toJSON of the parse result:
          ${builtins.toJSON unchecked}
        '';
      check =
        if !is-not-parsed && (is-y2a-args -> ((scheme.use-ifd or "never") != "always"))
        then
          let check-arg = if is-y2a-args then scheme.yaml else scheme;
          in check-parsed-yaml check-arg parsed.scheme
        else pkgs.emptyDirectory;
      parsedInput = if is-not-parsed then parsedInput' else { inherit (parsed) slug; } // parsedInput';
    in { inherit check parsedInput; };

  input-meta = inputAttrs: rec {
    scheme = ''${inputAttrs.scheme or "untitled"}'';
    author = ''${inputAttrs.author or "untitled"}'';
    description = ''${inputAttrs.description or scheme}'';
    variant = ''${inputAttrs.variant or "unspecified"}'';
    system = ''${inputAttrs.system or "base16"}'';
    slug =
      lib.toLower (
        lib.strings.sanitizeDerivationName (
          inputAttrs.slug or scheme
    ));
  };

  builder-meta = inputMeta: {
    scheme-name = inputMeta.scheme;
    scheme-author = inputMeta.author;
    scheme-description = inputMeta.description;
    scheme-slug = inputMeta.slug;
    scheme-slug-underscored = builtins.replaceStrings ["-"] ["_"] inputMeta.slug;
    scheme-system = inputMeta.system;
    scheme-variant = inputMeta.variant;
  };

  coercion-meta = inputAttrs: inputMeta: {
    # Lets scheme attrs be automatically coerced to string (`__str__`)
    outPath =
      writeTextFile' "${inputMeta.slug}.yaml"
        (builtins.concatStringsSep "\n"
          (lib.mapAttrsToList (name: value: "${name}: ${value}") inputAttrs));
    # Calling a scheme attrset will build a theme (`__call__`)
    __functor = self: args: mkTheme (
      # if args is a flake input, then it must be templateRepo
      (if args ? outPath then { templateRepo = args; } else args) // { scheme = self; }
    );
  };

  override-scheme-attrs = { inputAttrs, inputMeta, check }:
    new:
      let
        new-scheme = mkSchemeAttrs (inputAttrs // inputMeta // new);
        new-override = new-scheme.override;
        allOther-patch = {
          inherit check;
          override = new-new: (new-override new-new) // patch;
        };
        patch = {
          withHashtag = new-scheme.withHashtag // allOther-patch;
        } // allOther-patch;
      in new-scheme // patch;

  #-------------------#
  # RETURNED FUNCTION #
  #-------------------#

  /* Returns a scheme attrset.
  */
  mkSchemeAttrs =
    # A path to a file or an attrset.
    # It MUST contain contain string attributes `baseXX`
    # and MAY contain string attributes `scheme`, `author`, `description`, `slug`
    # (see https://github.com/base16-project/home/blob/main/builder.md#schemes-repository).
    scheme:
    let
      inherit (yaml-scheme2attrs scheme) parsedInput check;
      inputAttrs = mkBase24 parsedInput;
      inputMeta = input-meta inputAttrs;
      builderMeta = builder-meta inputMeta;
      coercionMeta = coercion-meta inputAttrs inputMeta;
      checkMeta = { inherit check; };
      overrideMeta = { override = override-scheme-attrs { inherit inputAttrs inputMeta check; }; };
      allMeta = inputMeta // builderMeta // coercionMeta // checkMeta // overrideMeta;
      populatedColors = colors inputAttrs;
    in populatedColors // allMeta // {
      withHashtag = populatedColors.withHashtag // allMeta;
    };

in { inherit mkSchemeAttrs; }
