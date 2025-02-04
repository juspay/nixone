#!/bin/sh
set -eu

# Check if nix is already installed
if ! which nix > /dev/null; then
  # Install Nix
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
    sh -s -- install --no-confirm --extra-conf "trusted-users = $(whoami)"

  # Resolves https://github.com/juspay/nixone/issues/19
  if [ ! -d "/nix/var/nix/profiles/per-user/$(id -un)/" ]; then
    sudo mkdir /nix/var/nix/profiles/per-user/$(id -un)/
    sudo chown $(id -un) /nix/var/nix/profiles/per-user/$(id -un)
  fi

  # Source nix configuration
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Run `om health`
echo "\n# Check nix health"
nix --accept-flake-config run github:juspay/omnix health

health_out=$(nix --accept-flake-config run github:juspay/omnix -- health --json 2>/dev/null)
is_nix_healthy=$?

echo $health_out | nix run nixpkgs#jq -- -e '.info.nix_installer.type == "DetSys"' > /dev/null
is_detsys_used=$?

# Check if any of the required health checks fail and also that https://github.com/DeterminateSystems/nix-installer is used
#
# TODO: evaluate if Uninstalling Nix is too harsh of a suggestion here
if [ $is_nix_healthy -ne 0 ] && [ $is_detsys_used -ne 0 ]; then
  echo "\n# Uninstall Nix: <https://nixos.asia/en/howto/uninstall-nix>. Post uninstall, re-run the script."
  exit 1
fi

echo $health_out | nix run nixpkgs#jq -- -e '.checks.shell.result != "Green"' > /dev/null
is_home_manager_inactive=$?

if [ $is_home_manager_inactive -eq 0 ]; then
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
fi
