{
  description = "Testcontainers";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { flake-utils, nixpkgs, self }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          config = {};

          overlays = [
            # This is an overlay we apply on top of Nixpkgs with some of our
            # own packages defined.
            (final: prev: {
              # A Haskell package set with our own overrides and packages defined.
              myHaskellPackages = final.haskellPackages.override {
                overrides = hfinal: hprev: {
                  # This is our local Haskell package.
                  testcontainers-flake =
                    hfinal.callCabal2nix "testcontainers" ./. { };
                };
              };

              # This is just a convenient shortcut to our package from the
              # top-level of Nixpkgs.  We're also applying the
              # justStaticExecutables function to our package in order to
              # reduce the size of the output derivation.
              testcontainers-flake =
                final.haskell.lib.compose.justStaticExecutables
                  final.myHaskellPackages.testcontainers-flake;

              # A Haskell development shell for our package that includes
              # things like cabal and HLS.
              myDevShell = final.myHaskellPackages.shellFor {
                packages = p: [ p.testcontainers-flake p.tasty-discover ];
                

                nativeBuildInputs = [
                  final.cabal-install
                  final.haskellPackages.haskell-language-server
                ];
              };
            })
          ];

          # Our full Nixpkgs with the above overlay applied.
          pkgs = import nixpkgs { inherit config overlays system; };
        in
        {
          packages.default = pkgs.testcontainers-flake;

          devShells.default = pkgs.myDevShell;
        }
      );
}