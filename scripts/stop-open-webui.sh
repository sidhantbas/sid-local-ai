#!/usr/bin/env bash
# Stop Open WebUI. Chats and settings are kept in the "open-webui" Docker volume.
set -euo pipefail
cd "$(dirname "$0")/.."

docker compose --env-file .env -f docker/docker-compose.yml stop open-webui
