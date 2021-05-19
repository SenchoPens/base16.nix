{ stdenv, pkgs }:
let
  pybase16-builder = pkgs.python3Packages.buildPythonPackage rec {
    pname = "pybase16-builder";
    version = "0.2.7"

    src = pkgs.python3Packages.fetchPypi {
      inherit pname version;
    };

    propagatedBuildInputs = with pkgs.python3Packages; [ pystache pyyaml aiofiles ];

    doCheck = false;
  };

  customPython = pkgs.python3.buildEnv.override {
    extraLibs = [ pybase16-builder ];
  };
in
stdenv.mkDerivation {
  name = "base16-builder-python-${version}";
  version = pybase16-builder.version;

  propagatedBuildInputs = [ customPython ];
}
