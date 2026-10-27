# caddy-flake

A Nix flake that provides [Caddy](https://github.com/caddyserver/caddy) built with three extra modules compiled in: [cloudflare DNS](https://github.com/caddy-dns/cloudflare), [rate-limit](https://github.com/mholt/caddy-ratelimit), and [cache-handler](https://github.com/caddyserver/cache-handler). The plugin revisions are pinned by this flake and only move when its updater runs; the Caddy release itself tracks this flake's nixpkgs input, so it is whatever nixpkgs-unstable currently ships.

## Outputs

- `packages.<system>.caddy` — the Caddy binary with those modules compiled in. `packages.<system>.default` is the same derivation.
- `packages.<system>.revalidate-hash` — maintenance output, not needed to consume the flake.
- `packages.<system>.update-version` — maintenance output, not needed to consume the flake.

`<system>` covers `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin`. There are no overlays, devShells, or apps.

## Consuming it

```nix
inputs.caddy = {
  url = "github:jgus-org/caddy-flake";
  inputs.flake-lib.follows = "flake-lib";
};
```

then take `inputs.caddy.packages.${system}.caddy`, which is what a service or image installs.

**Do not `follows` nixpkgs into this flake.** The vendor hash in `pin.nix` is resolved against this flake's own pinned nixpkgs — xcaddy resolves the plugin module graph fresh on every build, and the pinned Go toolchain and xcaddy from nixpkgs are part of what that resolution lands on. Overriding nixpkgs with a consumer's copy changes those inputs, and the build fails on a vendor hash mismatch rather than resolving. `flake-lib` is safe to follow.

The module set is fixed. If you need a different set of plugins, `pkgs.caddy.withPlugins` against your own nixpkgs is the direct route; this flake only publishes the one combination it pins.

See [LICENSE.md](LICENSE.md) for licensing and copyright, and [NOTICE.md](NOTICE.md) for the terms of upstream and distributed artifacts.
