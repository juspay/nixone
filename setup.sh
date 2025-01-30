#!/bin/sh

# Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install --no-confirm --extra-conf "trusted-users = $(whoami)"

# Source nix configuration
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# Run `om health`
echo "\n# Check nix health"
nix --accept-flake-config run github:juspay/omnix health

# Setup nixos-unified-template
echo "\n# Setting up home-manager & direnv"
nix --accept-flake-config run github:juspay/omnix -- \
  init github:juspay/nixos-unified-template#home -o ~/.config/home-manager \
  --non-interactive \
  --params '{"username":"'$(id -un)'", "git-name":"'$(id -un)'", "git-email":"'$(id -un)'@juspay.in"}'

cd ~/.config/home-manager && nix run

echo "\n# Initialize a git repo"
git init && git add . && git commit -m Init

echo "\n# All done 🥳 Please start a **new terminal window**"
# TODO: Can we automate this? This doesn't work
# env -i HOME="$HOME" "$SHELL" -l

