#!/bin/sh
set -eu

TARGET_USER="$(id -un)"
while [ $# -gt 0 ]; do
  case "$1" in
    --user) shift; TARGET_USER="$1" ;;
  esac
  shift
done

if [ -d "/nix" ]; then
  echo "Nix is already installed."
  echo "Run `Nix Uninstaller` from self-service and then re-run the current app to re-install"
  exit 0
fi

curl --proto '=https' --tlsv1.2 -sSf -L \
  https://artifacts.nixos.org/nix-installer/tag/2.34.5/nix-installer.sh | \
  sh -s -- install --no-confirm --extra-conf "trusted-users = ${TARGET_USER}"

# Resolves https://github.com/juspay/nixone/issues/19
if [ ! -d "/nix/var/nix/profiles/per-user/${TARGET_USER}/" ]; then
  sudo mkdir "/nix/var/nix/profiles/per-user/${TARGET_USER}/"
  sudo chown "${TARGET_USER}" "/nix/var/nix/profiles/per-user/${TARGET_USER}"
fi

