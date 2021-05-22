{
  description = "Scaphandre";

  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

  outputs = { self, nixpkgs }:
  let
    systems = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system); 
    # Memoize nixpkgs for different platforms for efficiency.
    nixpkgsFor = forAllSystems (system:
      import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      }
    );
  in {
    overlay = final: prev: {

      scaphandre = with final; ( rustPlatform.buildRustPackage rec {
          pname = "scaphandre";
          version = "0.3.0";
          src = fetchFromGitHub {
            owner = "hubblo-org";
            repo = pname;
            # rev = "v${version}";
            rev = "6fcdf2e877adc2b06a71d708ff326bab2de0a225"; # fix containing the Carglo.lock file 
            sha256 = "sha256-nn/nDegKwuqO+e2ipXAMTwSOhifCwI7WBJ8wY0sSTxo=";
          };

          cargoSha256 = "sha256-OlShMwVesIE5WK3IBQJ38EMXQV6cHfxWGWpwAW6HC08=";

          nativeBuildInputs = [ pkgconfig ];
          buildInputs = [ openssl ];
          # checkType = "debug";
          doCheck = false;

          meta = with pkgs.stdenv.lib; {
            description = "Electrical power consumption metrology agent";
            homepage = "https://github.com/hubblo-org/scaphandre";
            license = licenses.asl20;
            platforms = platforms.unix;
            maintainers = with maintainers; [ mmai ];
          };
        });
      };

    packages = forAllSystems (system: {
      inherit (nixpkgsFor.${system}) scaphandre;
    });

    defaultPackage = forAllSystems (system: self.packages.${system}.scaphandre);

    devShell = forAllSystems (system: (import ./shell.nix { pkgs = nixpkgs.legacyPackages.${system}; }));

    # scaphandre service module
    # nixosModule = (import ./module.nix);

  };
}
