#!/usr/bin/env bash
# Keep the Mac from idle-sleeping while a model server (Strata or Unsloth's llama-server) is
# running, so Hermes and the Telegram bot keep answering. The display still sleeps, and
# closing the lid still sleeps the Mac. Run by the LaunchAgent from install-keep-awake.sh.
set -uo pipefail

while true; do
  pid="$(pgrep -f '/strata/components/engine/' | head -1)"
  [ -n "${pid}" ] || pid="$(pgrep -x llama-server | head -1)"
  if [ -n "${pid}" ]; then
    echo "$(date '+%F %T') model server ${pid} running: staying awake"
    caffeinate -i -w "${pid}"  # returns when that process exits
    echo "$(date '+%F %T') model server ${pid} stopped: normal sleep"
  else
    sleep 30
  fi
done
