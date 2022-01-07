# PR ideas
- Improve README.md
- Integrate with home manager & NixOS application options:
  - Add an option with a list of names of applications to theme
  - Make a script that parses existing configuration and generates such list
- Generate themes "natively" with just a yaml builder
- Add an option to display current theme with trace

# Contributing
Contributions are highly welcome (but keep in mind I want to keep this flake small)
Also feel free to ask me any questions about developing flakes modules,
I will try to answer them or figure out the answer with you, as I'm a beginner too.

Few tips on testing flakes:
If you are testing this flake as a NixOS submodule, the easiest way I found to test the result
of the theming is the following: set the flake url to an absolute path to where you cloned this repo, like this:
`base16.url = "/home/sencho/code/github.com/SenchoPens/base16.nix";`
And, **from the directory of your NixOS flake configuration**, test it like this:
`nix flake lock --update-input base16 && sudo nixos-rebuild switch`
This way you won't need to commit changes, and testing process is very fast.
