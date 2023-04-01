{
  inputs.odin.url = "github:odin-lang/Odin";
  inputs.odin.flake = false;

  outputs = { self, odin, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in
  {
    packages.${system} = {
      odin = (with pkgs; llvmPackages_11.stdenv.mkDerivation (rec {
        pname = "odin";
        version = "nightly";
        dontConfigure = true;

        buildInputs = [
          llvm
          clang
          git
          which
        ];

        src = odin;

        buildPhase = ''
          bash ./build_odin.sh nightly
        '';

        installPhase = ''
          mkdir -p $out/bin
          cp odin $out/bin/odin
          cp -r core $out/bin/core
          cp -r vendor $out/bin/vendor
        '';
      }));
    };

    devShells.${system} = {
      default = pkgs.mkShell {
        buildInputs = [
          self.packages.${system}.odin
          pkgs.clang
        ];
      };
    };
  };
}
