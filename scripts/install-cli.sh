#!/usr/bin/env bash
# Install the `sid` CLI (editable, so repo changes apply immediately) and the
# clap listener LaunchAgent that starts at login.
#
#   ./scripts/install-cli.sh             # CLI + clap listener
#   ./scripts/install-cli.sh --no-clap   # CLI only
#   ./scripts/install-cli.sh --uninstall # remove both
set -euo pipefail
cd "$(dirname "$0")/.."

LABEL="com.sidlocalai.clapd"
PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"
LOG="${HOME}/Library/Logs/sid-clapd.log"

if [ "${1:-}" = "--uninstall" ]; then
  launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
  rm -f "${PLIST}"
  uv tool uninstall sid-cli || true
  echo "Removed sid CLI and clap listener."
  exit 0
fi

uv tool install --force --editable ./cli
SID="$(uv tool dir --bin)/sid"
echo "Installed: ${SID}"

[ "${1:-}" = "--no-clap" ] && exit 0

mkdir -p "$(dirname "${PLIST}")"
cat > "${PLIST}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array><string>${SID}</string><string>clap</string><string>daemon</string></array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key><string>${HOME}/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
    <key>SID_LOCAL_AI_HOME</key><string>$(pwd)</string>
  </dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><dict><key>SuccessfulExit</key><false/></dict>
  <key>ProcessType</key><string>Interactive</string>
  <key>StandardOutPath</key><string>${LOG}</string>
  <key>StandardErrorPath</key><string>${LOG}</string>
</dict>
</plist>
EOF
plutil -lint "${PLIST}" >/dev/null

launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "${PLIST}"
echo "Clap listener running (log: ${LOG})."
echo "It listens for 60 s after login and after every unlock; double clap to launch."
