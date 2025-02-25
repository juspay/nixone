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

_om() {
  nix --extra-experimental-features "flakes nix-command" --accept-flake-config run github:juspay/omnix -- "$@"
}

_jq() {
  nix --extra-experimental-features "flakes nix-command" run nixpkgs#jq -- "$@"
}

# Run `om health`
echo "\n# Check nix health"
_om health

health_out=$(_om health --json 2>/dev/null)

# Check if <https://github.com/DeterminateSystems/nix-installer> is used
#
# TODO: evaluate if Uninstalling Nix is too harsh of a suggestion here
if echo "$health_out" | _jq -e '.info.nix_installer.type != "DetSys"'; then
  echo "\n# Uninstall Nix: <https://nixos.asia/en/howto/uninstall-nix>. Post uninstall, re-run the script."
  exit 1
fi

if echo "$health_out" | _jq -e '.checks.shell.result != "Green"'; then
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
