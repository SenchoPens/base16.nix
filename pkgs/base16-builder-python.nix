{ pkgs, ... }:
let
  pybase16-builder = pkgs.python3Packages.buildPythonPackage rec {
    pname = "pybase16-builder";
    version = "0.2.7";

    src = pkgs.python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "lC3KkIxHrTS4IO7tMGo8wGqoOeZrvm1Zu/dYygBVbTs=";
    };

    propagatedBuildInputs = with pkgs.python3Packages; [
      pystache
      pyyaml
      aiofiles
    ];

    doCheck = false;
  };

  python = pkgs.python3.buildEnv.override { extraLibs = [ pybase16-builder ]; };
in { inherit pybase16-builder python; }
