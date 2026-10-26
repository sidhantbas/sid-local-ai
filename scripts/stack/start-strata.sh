#!/usr/bin/env bash
# Start Strata (native macOS, Metal engine) on port 8080 with Qwen3.8-Flash-Next Gyro-S
# (125B mixture of experts), serving an OpenAI-compatible API at http://127.0.0.1:8080/v1.
# The main model since 2026-10-24 (Charles: the bigger model is smarter); for the faster
# Qwen3.6-35B-A3B use ./scripts/stack/start-unsloth.sh instead. Only one of the two fits in 48 GB,
# so this stops Unsloth Studio first.
#
#   ./scripts/stack/start-strata.sh
#
# Streaming mode (STRATA_METAL_STREAM=1): the model file is 58.5 GB, so experts that are not
# in the in-memory arena are read from the SSD. Strata sizes the arena from the memory free at
# start, so close Chrome first for faster answers (see benchmarks/README.md).
# Install steps: docs/setup-log.md section 16. Engine log: ~/.local/state/strata/launch/.
# If the Hermes container is running, it is pointed at Strata.
set -euo pipefail
cd "$(dirname "$0")/../.."

PORT="${STRATA_PORT:-8080}"
MODEL=qwen3.8-flash-next-gyro-gyro-s
CONTEXT=65536
FEED=https://github.com/Niko1221/Strata/releases/download/v0.2.2  # pinned release
LOG="${HOME}/.local/state/strata/launch/gyro-s-64k.engine.log"

if curl -fsS "http://127.0.0.1:${PORT}/v1/models" >/dev/null 2>&1; then
  echo "Strata is already running on port ${PORT}."
else
  if curl -fsS "http://127.0.0.1:${UNSLOTH_PORT:-8890}/api/health" >/dev/null 2>&1; then
    echo "Stopping Unsloth Studio to free memory..."
    ./scripts/stack/stop-unsloth.sh
    sleep 10  # let macOS take its memory back; the arena is sized from what is free
  fi
  echo "Loading Gyro-S (takes about a minute)..."
  # The containers reach Strata as host.docker.internal, which its DNS-rebinding check
  # refuses unless the server (not only the engine) is started with this set.
  STRATA_ALLOWED_HOSTS="host.docker.internal,host.docker.internal:${PORT}" \
    "${HOME}/.local/bin/strata" launch --model gyro-s --family gyro --context 64k --vision off \
    --access local --port "${PORT}" --parallel 1 --set STRATA_METAL_STREAM=1 \
    --no-tui --yes --feed "${FEED}" >/dev/null
  echo "Strata is up: http://127.0.0.1:${PORT} (API: /v1)"
  arena=$(grep -o 'expert arena [0-9.]* GB' "${LOG}" | tail -1 | grep -o '[0-9.]*' || echo 0)
  echo "Expert arena: ${arena} GB in memory."
  if [ "${arena%.*}" -lt 15 ]; then
    echo "  Little memory was free; close Chrome and run ./scripts/stack/stop-strata.sh && ./scripts/stack/start-strata.sh for faster answers."
  fi
fi

if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx hermes; then
  docker exec hermes hermes config set model.base_url "http://host.docker.internal:${PORT}/v1" >/dev/null
  docker exec hermes hermes config set model.default "${MODEL}" >/dev/null
  docker exec hermes hermes config set model.context_length "${CONTEXT}" >/dev/null
  # Strata keeps one cached prompt; Hermes's title request would evict its ~13.5K-token
  # system prompt after every question (55 s instead of 6 s for the next one)
  docker exec hermes hermes config set auxiliary.title_generation.model_upgrade_enabled false >/dev/null
  echo "Hermes now uses Strata ${MODEL} with ${CONTEXT} tokens of context."
fi
