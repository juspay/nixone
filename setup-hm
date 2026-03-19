#!/bin/sh
set -eu

RESET_HM=0
for arg in "$@"; do
  case "$arg" in --reset-hm) RESET_HM=1 ;; esac
done

# Source nix if not in PATH (standalone mode after separate install-nix)
if ! which nix > /dev/null 2>&1; then
  if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  else
    echo "Error: Nix is not installed. Install it first:"
    echo "  curl --proto '=https' --tlsv1.2 -sSf -L https://juspay.github.io/nixone/install-nix | sh -s"
    exit 1
  fi
fi

_om() {
  nix --extra-experimental-features "flakes nix-command" --accept-flake-config run github:juspay/omnix -- "$@"
}

_jq() {
  nix --extra-experimental-features "flakes nix-command" run nixpkgs#jq -- "$@"
}

# Run `om health`
# Note: Using `|| true` to ignore exit-code of commands that shouldn't crash the script on failure
echo "\n# Check nix health"
{ _om health; health_status=$?; } || true

health_out=$(_om health --json 2>/dev/null) || true

# Initialize template, activate home-manager, and initialize git
_setup_hm() {
  # Setup nixos-unified-template
  echo "\n# Setting up home-manager & direnv"
  nix --accept-flake-config run github:juspay/omnix -- \
    init github:juspay/nixos-unified-template#home -o ~/.config/home-manager \
    --non-interactive \
    --params '{"username":"'$(id -un)'", "git-name":"'$(id -un)'", "git-email":"'$(id -un)'@juspay.in", "work": true}'

  cd ~/.config/home-manager && USER=$(id -un) nix run

  echo "\n# Initialize a git repo"
  git init && git add . && git commit -m Init

  echo "\n# All done 🥳 Please start a **new terminal window**"
  # TODO: Can we automate this? This doesn't work
  # env -i HOME="$HOME" "$SHELL" -l
}

# If --reset-hm is passed, reset regardless of shell health status being Green
if [ "$RESET_HM" -eq 1 ]; then
  echo "\n# Resetting home-manager"
  if [ -d ~/.config/home-manager ]; then
    if [ -d ~/.config/home-manager-backup ]; then
      # time-stamped backups can have unbounded growth
      # instead, we assume user wants to keep only the latest config
      echo "\n# Removing existing backup"
      rm -rf ~/.config/home-manager-backup
    fi
    mv ~/.config/home-manager ~/.config/home-manager-backup
    echo "\n# Backed up ~/.config/home-manager to ~/.config/home-manager-backup"
  else
    echo "No existing ~/.config/home-manager to backup."
  fi

  _setup_hm
elif echo "$health_out" | _jq -e '.checks.shell.result != "Green"' > /dev/null; then
  if [ -d ~/.config/home-manager ]; then
    echo "\n# Activating existing home-manager configuration"
    cd ~/.config/home-manager && USER=$(id -un) nix run
    exit $?
  fi

  _setup_hm
fi
