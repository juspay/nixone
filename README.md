# nixone

**Status**: WIP

One-click setup of all things Nix for Juspay'ers

## Getting Started

On a macOS machine that does not already have Nix installed run,

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://juspay.github.io/nixone/setup | sh -s
```

## What it does

- [Install Nix](https://nixos.asia/en/install)
- [Run `om health`](https://omnix.page/om/health.html)
- [Setup home-manager via `nix-dev-home`](https://github.com/juspay/nix-dev-home)
    - Resulting config will be at `$HOME/nixconfig`.
