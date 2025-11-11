#!/bin/sh
set -eu

# Parse CLI args
RESET_HM=0
for arg in "$@"; do
  case "$arg" in
    --reset-hm)
      RESET_HM=1
      ;;
  esac
done

# Check if nix is already installed
if ! nix --version > /dev/null 2>&1; then
  echo "\n# Installing Nix"

  # macOS: Check for Rosetta
  if [ "$(uname)" = "Darwin" ]; then
    if [ "$(sysctl -n sysctl.proc_translated 2>/dev/null)" = "1" ]; then
      echo "Error: Running on Rosetta. Please run in native ARM64 terminal"
      exit 1
    fi
  fi

  # macOS: Cleanup old backup files
  if [ "$(uname)" = "Darwin" ]; then
    echo "# Cleaning up old backup files"
    sudo rm -f /etc/bashrc.backup-before-nix /etc/zshrc.backup-before-nix /etc/bash.bashrc.backup-before-nix 2>/dev/null || true
  fi

  # Stop Nix daemon if running
  echo "# Stopping any existing Nix daemon"
  if [ "$(uname)" = "Darwin" ]; then
    sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2>/dev/null || true
  else
    sudo systemctl stop nix-daemon.service 2>/dev/null || true
    sudo systemctl stop nix-daemon.socket 2>/dev/null || true
  fi

  # Remove old Nix users/groups
  echo "# Removing old Nix build users and groups"
  if [ "$(uname)" = "Darwin" ]; then
    # macOS: Remove _nixbld users (with underscore prefix)
    for u in $(sudo dscl . -list /Users 2>/dev/null | grep _nixbld); do
      sudo dscl . -delete /Users/$u
    done
    sudo dscl . -delete /Groups/nixbld 2>/dev/null || true
  else
    # Linux: Remove nixbld users (no underscore prefix)
    for i in $(seq 1 32); do
      sudo userdel nixbld$i 2>/dev/null || true
    done
    sudo groupdel nixbld 2>/dev/null || true
  fi

  # Install Nix using official installer
  echo "# Running official Nix installer"
  curl -L https://nixos.org/nix/install | sudo su - -c 'sh -s -- --daemon'

  # Resolves https://github.com/juspay/nixone/issues/19
  if [ ! -d "/nix/var/nix/profiles/per-user/$(id -un)/" ]; then
    sudo mkdir /nix/var/nix/profiles/per-user/$(id -un)/
    sudo chown $(id -un) /nix/var/nix/profiles/per-user/$(id -un)
  fi

  # Configure nix.conf
  echo "# Configuring nix.conf"
  sudo tee -a /etc/nix/nix.conf > /dev/null <<EOF
max-jobs = auto
experimental-features = nix-command flakes
trusted-users = root $(whoami)
EOF

  # Restart nix-daemon
  echo "# Restarting nix-daemon"
  if [ "$(uname)" = "Darwin" ]; then
    # macOS: launchd manages nix-daemon
    sudo pkill -9 nix-daemon 2>/dev/null || true
  else
    # Linux: systemd manages nix-daemon
    sudo systemctl restart nix-daemon
  fi
  # Give daemon time to restart
  sleep 2

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
# Note: Using `|| true` to ignore exit-code of commands that shouldn't crash the script on failure
echo "\n# Check nix health"
{ _om health; health_status=$?; } || true

health_out=$(_om health --json 2>/dev/null) || true

# Check if required health checks are failing
if [ $health_status -ne 0 ]; then
  echo "\n# Health checks failed. Consider reinstalling Nix."
  echo "\n# Uninstall guide: <https://nixos.asia/en/howto/uninstall-nix>"
  exit 1
fi

# Initialize template, activate home-manager, and initialize git
_setup_hm() {
  # Setup nixos-unified-template
  echo "\n# Setting up home-manager & direnv"
  nix --accept-flake-config run github:juspay/omnix -- \
    init github:juspay/nixos-unified-template#home -o ~/.config/home-manager \
    --non-interactive \
    --params '{"username":"'$(id -un)'", "git-name":"'$(id -un)'", "git-email":"'$(id -un)'@juspay.in", "work": true}'

  cd ~/.config/home-manager && nix run

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
    echo "\n# Directory ~/.config/home-manager already exists."
    echo "Run: \`cd ~/.config/home-manager && nix run\`"
    echo "To activate existing home-manager configuration, or remove the directory and re-run the curl to setup afresh."
    exit 1
  fi

  _setup_hm
fi

