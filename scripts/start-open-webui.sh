#!/usr/bin/env bash
# Start Open WebUI (Docker, on Colima) at http://localhost:3000.
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/start-colima.sh
docker compose --env-file .env -f docker/docker-compose.yml up -d open-webui

echo "Waiting for Open WebUI to become healthy..."
for _ in $(seq 1 60); do
  if curl -fsS http://localhost:3000/health >/dev/null 2>&1; then
    echo "Open WebUI is up: http://localhost:3000"
    exit 0
  fi
  sleep 5
done
echo "Open WebUI did not respond within 5 minutes; check: docker logs open-webui" >&2
exit 1
