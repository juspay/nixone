# nixone

**Status**: Beta

One-click setup of all things Nix for Juspay'ers. We provide an one-line CLI that will install Nix, all the way to setting up home-manager (obviating homebrew) on your Juspay provided Macbook, as well as other Linux machines.

## Getting Started

On a macOS machine that does not already have Nix installed run the following after getting "Temp admin access",

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://juspay.github.io/nixone/setup | sh -s
```

>[!NOTE]
> You may still run this command if you installed Nix already using Determinate Systes nix-installer. The script will then setup `nix-dev-home` for you (see below).

## Running health check only

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://juspay.github.io/nixone/health | sh -s
```

## What it does

- [Install Nix](https://nixos.asia/en/install)
- [Run `om health`](https://omnix.page/om/health.html)
- [Setup home-manager via `nix-dev-home`](https://github.com/juspay/nix-dev-home)
    - Resulting config will be accessible at `~/.config/home-manager`. You can modify this later.
