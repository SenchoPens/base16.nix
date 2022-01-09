# PR ideas
- Improve README.md
- More precise typing of scheme attrs
- Integrate with home manager & NixOS application options:
  - Add an option with a list of names of applications to theme
  - Make a script that parses existing configuration and generates such list
- Add an option to display current theme with trace

# Contributing
Contributions are highly welcome (but keep in mind I want to keep this flake small)
Also feel free to ask me any questions about developing flakes modules,
I will try to answer them or figure out the answer with you, as I'm a beginner too.

## Testing / debugging
If you are testing this flake as a module, the easiest way I found to test the result
of the theming is the following: set the flake url to an absolute path to where you cloned this repo, like this:
`base16.url = "/home/sencho/code/github.com/SenchoPens/base16.nix";`
And then, in the directory of your NixOS config, run
`nix flake lock --update-input base16 && sudo nixos-rebuild switch --flake .` 
This way you won't need to commit changes to test them.
