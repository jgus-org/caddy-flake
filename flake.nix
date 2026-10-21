{
  description = "Caddy with selected plugins (cloudflare DNS, rate-limit, cache-handler).";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-lib = {
      url = "github:jgus-org/flake-lib/v1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-lib,
      treefmt-nix,
    }:
    flake-lib.lib.eachDefaultSystem (
      system:
      let
        # Single source of truth for the plugin list + combined vendor hash. Regenerate via `nix run .#update-version` from this directory.
        pin = import ./pin.nix;
        pkgs = import nixpkgs { inherit system; };
        treefmtEval = treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true;
          programs.shfmt.enable = true;
        };
        caddy = pkgs.caddy.withPlugins {
          inherit (pin) plugins hash;
        };
        update-version = pkgs.writeShellApplication {
          name = "update-version";
          text = ''exec ${./update-version.sh} "$@"'';
        };
        # The vendor-hash-by-build-failure dance is shared via flake-lib; the bespoke
        # plugin resolution stays in update-version.sh (a manifest-style source).
        revalidate-hash = flake-lib.lib.mkRevalidateHash {
          inherit pkgs;
          hashField = "hash";
        };
      in
      {
        packages = {
          inherit caddy update-version revalidate-hash;
          default = caddy;
        };
        formatter = treefmtEval.config.build.wrapper;
        checks.formatting = treefmtEval.config.build.check self;
      }
    );
}
