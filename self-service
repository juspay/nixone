#!/bin/sh
# MDM self-service script for installing Nix on managed Macs where the user is
# not a sudoer.
#
# This entire script runs as root. It installs Nix silently, then
# opens Terminal in the console user's GUI session to run home-manager setup.
# On install failure, Terminal is opened showing the error logs.
set -eu

NIXONE_BASE_URL="https://juspay.github.io/nixone"
LOG_FILE="/tmp/nixone-install.log"

CONSOLE_USER=$(stat -f%Su /dev/console)

if [ -z "${CONSOLE_USER}" ] || \
   [ "${CONSOLE_USER}" = "loginwindow" ] || \
   [ "${CONSOLE_USER}" = "root" ]; then
  echo "Error: No valid console user (got: '${CONSOLE_USER:-<empty>}')"
  exit 1
fi

CONSOLE_USER_UID=$(id -u "${CONSOLE_USER}")

if ! curl --proto '=https' --tlsv1.2 -sSf -L "${NIXONE_BASE_URL}/install-nix" | \
     sh -s -- --user "${CONSOLE_USER}" > "${LOG_FILE}" 2>&1; then

  chown "${CONSOLE_USER}" "${LOG_FILE}"
  launchctl asuser "${CONSOLE_USER_UID}" \
    osascript -e "tell application \"Terminal\"
      activate
      do script \"echo 'Nix installation failed:'; echo; cat ${LOG_FILE}\"
    end tell"
  exit 1
fi

launchctl asuser "${CONSOLE_USER_UID}" \
  osascript -e "tell application \"Terminal\"
    activate
    do script \"curl --proto '=https' --tlsv1.2 -sSf -L ${NIXONE_BASE_URL}/setup-hm | sh -s\"
  end tell"
