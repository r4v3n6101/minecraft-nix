{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    version-manifest = {
      url = "file+https://piston-meta.mojang.com/mc/game/version_manifest.json";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      version-manifest,
    }:
    let
      manifest = builtins.fromJSON (builtins.readFile version-manifest);

      packageName =
        id: "v${nixpkgs.lib.replaceStrings [ "." "-" " " "+" "/" ] [ "_" "_" "_" "_" "_" ] id}";
      sha1FromPistonUrl = url: builtins.elemAt (nixpkgs.lib.splitString "/" url) 5;
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        inherit (pkgs) lib callPackage;
      in
      {
        packages = lib.listToAttrs (
          map (v: {
            name = packageName v.id;
            value = callPackage ./package/game.nix {
              url = v.url;
              sha1 = sha1FromPistonUrl v.url;
            };
          }) manifest.versions
        );
      }
    );
}
