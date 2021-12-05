with import <nixpkgs> {};

#  https://input-output-hk.github.io/haskell.nix/tutorials/development/
pkgs.haskellPackages.shellFor {
  packages = ps : [ ps.cut-the-crap ];
  buildInputs = [
    pkgs.ffmpeg
    pkgs.hlint
    pkgs.pocketsphinx
    pkgs.pkg-config
    pkgs.cabal2nix
    pkgs.cabal-install
  ];
  exactDeps = true;
  NIX_PATH="nixpkgs=${pkgs.path}:.";
}
