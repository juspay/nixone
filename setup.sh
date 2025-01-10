#!/bin/sh

# Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install --no-confirm --extra-conf "trusted-users = $(whoami)"

# Source nix configuration
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# Run `om health`
echo "\n# Check nix health"
nix --accept-flake-config --extra-experimental-features "nix-command flakes" run github:juspay/omnix health

# Setup nixos-unified-template
echo "\n# Setting up nix-darwin & direnv"
nix --accept-flake-config --extra-experimental-features "nix-command flakes" run github:juspay/omnix -- \
  init github:juspay/nixos-unified-template#darwin -o ~/nixconfig \
  --non-interactive \
  --params '{"username":"'$(id -un)'", "git-name":"'$(id -F)'", "git-email":"'$(id -un)'@juspay.in", "hostname": "'$(hostname -s)'"}'

# Avoid any pre-defined nix.conf
echo "\n# Removing /etc/nix/nix.conf"
sudo rm /etc/nix/nix.conf

cd ~/nixconfig && nix --extra-experimental-features "nix-command flakes" run

echo "\n# All done 🥳 Please start a **new terminal window**"
# TODO: Can we automate this? This doesn't work
# env -i HOME="$HOME" "$SHELL" -l

