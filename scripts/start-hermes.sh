#!/usr/bin/env bash
# Start Hermes Agent (Docker, on Colima) with its dashboard at http://localhost:9119.
# Uses the local model via Strata (start-strata.sh) or Unsloth Studio (start-unsloth.sh);
# whichever start script ran last points Hermes at its server.
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/start-colima.sh
docker volume create sid-local-ai_hermes-data >/dev/null
docker compose --env-file .env -f docker/docker-compose.yml up -d hermes

if ! curl -fsS "http://127.0.0.1:${STRATA_PORT:-8080}/v1/models" >/dev/null 2>&1 &&
   ! curl -fsS "http://127.0.0.1:${UNSLOTH_PORT:-8890}/api/health" >/dev/null 2>&1; then
  echo "Note: no model server is running; Hermes needs one (./scripts/start-strata.sh)." >&2
fi

echo "Waiting for the Hermes dashboard..."
for _ in $(seq 1 36); do
  code=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:9119/ || true)
  # 302 = redirect to the dashboard's /login page, i.e. it is up
  if [ "${code}" = "200" ] || [ "${code}" = "302" ]; then
    echo "Hermes is up: http://localhost:9119 (login: see HERMES_DASHBOARD_* in .env)"
    exit 0
  fi
  sleep 5
done
echo "Hermes dashboard did not respond within 3 minutes; check: docker logs hermes" >&2
exit 1
