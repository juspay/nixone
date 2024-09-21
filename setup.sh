#!/bin/sh

# Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install --no-confirm --extra-conf "trusted-users = $(whoami)"

# Source nix configuration
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# Run `om health`
echo "\n# Check nix health"
nix --accept-flake-config run github:juspay/omnix health

# Setup nix-dev-home
echo "\n# Setting up home-manager & direnv"
mkdir -p ~/nixconfig && cd ~/nixconfig
nix --accept-flake-config run github:juspay/omnix -- \
  init github:juspay/nix-dev-home -o . \
  --non-interactive \
  --params '{"username":"'$(whoami)'", "git-name":"'$(id -F)'", "git-email":"'$(whoami)'@juspay.in", "neovim": true, "github-ci": false}'
nix run
# TODO: ^ must move dotfiles out of the way

echo "\n# All done 🥳 Please start a **new terminal window**"
# TODO: Can we automate this? This doesn't work
# env -i HOME="$HOME" "$SHELL" -l
