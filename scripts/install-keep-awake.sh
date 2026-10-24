#!/usr/bin/env bash
# Install (or remove) the LaunchAgent that keeps the Mac awake while a model is serving,
# so HumanLoop answers on Telegram until the lid is closed. See scripts/keep-awake.sh.
#
#   ./scripts/install-keep-awake.sh              # install and start (also at every login)
#   ./scripts/install-keep-awake.sh --uninstall  # remove; the Mac sleeps normally again
set -euo pipefail
cd "$(dirname "$0")/.."

LABEL="com.sidlocalai.keepawake"
PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"
LOG="${HOME}/Library/Logs/sid-keepawake.log"

launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
if [ "${1:-}" = "--uninstall" ]; then
  rm -f "${PLIST}"
  echo "Removed the keep-awake agent."
  exit 0
fi

mkdir -p "$(dirname "${PLIST}")"
cat > "${PLIST}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array><string>/bin/bash</string><string>$(pwd)/scripts/keep-awake.sh</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>${LOG}</string>
  <key>StandardErrorPath</key><string>${LOG}</string>
</dict>
</plist>
EOF
plutil -lint "${PLIST}" >/dev/null
launchctl bootstrap "gui/$(id -u)" "${PLIST}"
echo "Keep-awake agent running (log: ${LOG})."
