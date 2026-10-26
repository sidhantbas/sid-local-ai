#!/usr/bin/env bash
# Stop Hermes Agent. Its state is kept in the sid-local-ai_hermes-data volume.
set -euo pipefail
cd "$(dirname "$0")/../.."

docker compose --env-file .env -f docker/docker-compose.yml stop hermes
