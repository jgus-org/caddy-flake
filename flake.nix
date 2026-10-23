{
  description = "Caddy with selected plugins (cloudflare DNS, rate-limit, cache-handler).";

  inputs = {
    flake-lib.url = "github:jgus-org/flake-lib/v1";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      self,
      flake-lib,
      nixpkgs,
    }:
    flake-lib.lib.eachDefaultSystem (
      system:
      let
        # Single source of truth for the plugin list + combined vendor hash. Regenerate via `nix run .#update-version` from this directory.
        pin = import ./pin.nix;
        pkgs = import nixpkgs { inherit system; };
        orgFormatting = flake-lib.lib.mkFormatting {
          inherit self system;
        };
        caddy = pkgs.caddy.withPlugins {
          inherit (pin) hash plugins;
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
        checks.formatting = orgFormatting.check;
        formatter = orgFormatting.formatter;
        packages = {
          inherit caddy revalidate-hash update-version;
          default = caddy;
        };
      }
    );
}
