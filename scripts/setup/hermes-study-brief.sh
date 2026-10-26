#!/usr/bin/env bash
# Morning study brief on Telegram: on weekdays at 07:30 (Europe/London), Hermes sends today's
# sessions and lecture briefs from ~/brain/study (mounted at /opt/data/study). No model involved:
# the job runs study/tools/today.py and delivers its output; on a day without classes it prints
# nothing, so nothing is sent.
#
#   ./scripts/setup/hermes-study-brief.sh [telegram user id]   # default: Sid's id
set -euo pipefail

USER_ID="${1:-8547315541}"

# wrapper in Hermes's scripts dir (cron --script only runs files from there)
docker exec -i -u hermes hermes sh -c 'mkdir -p /opt/data/scripts && cat > /opt/data/scripts/study-brief.py' <<'EOF'
"""Morning study brief for Telegram: runs ~/brain/study/tools/today.py (mounted at /opt/data/study)."""
import runpy
import sys

sys.argv = ["today.py"]
runpy.run_path("/opt/data/study/tools/today.py", run_name="__main__")
EOF

if docker exec hermes hermes cron list 2>/dev/null | grep -q study-brief; then
  echo "A study-brief job already exists:"
else
  docker exec hermes hermes cron create "30 7 * * 1-5" --name study-brief --no-agent \
    --script study-brief.py --deliver "telegram:${USER_ID}" >/dev/null
  echo "Created the study-brief job:"
fi
docker exec hermes hermes cron list | grep -A3 study-brief
echo "Test it now (sends today's brief to Telegram): docker exec hermes hermes cron run study-brief"
