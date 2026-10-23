#!/usr/bin/env bash
# Start Unsloth Studio (native macOS) on port 8890 with a Qwen model loaded,
# serving an OpenAI-compatible API at http://127.0.0.1:8890/v1.
#
#   ./scripts/start-unsloth.sh            # Qwen3.6-35B-A3B (mixture of experts, 3B active; the default)
#   ./scripts/start-unsloth.sh 27b        # Qwen3.8-27B (dense; ~7x slower prompts, 3x slower answers)
#
# The default changed from 27b on 2026-10-23 after benchmarks/README.md. Hermes's
# model.default must name the loaded model (see docs/architecture.md).
#
# To switch models: ./scripts/stop-unsloth.sh, then start with the other one.
# Logs: logs/unsloth.log. The API key (label "open-webui") is reused across
# runs and lives in .env as UNSLOTH_API_KEY.
set -euo pipefail
cd "$(dirname "$0")/.."

PORT="${UNSLOTH_PORT:-8890}"
UNSLOTH="${HOME}/.local/bin/unsloth"

case "${1:-35b-a3b}" in
  27b)     REPO=unsloth/Qwen3.8-27B-GGUF;          NAME=Qwen3.8-27B ;;
  35b-a3b) REPO=unsloth/Qwen3.6-35B-A3B-MTP-GGUF;  NAME=Qwen3.6-35B-A3B ;;
  *) echo "usage: start-unsloth.sh [27b|35b-a3b]" >&2; exit 2 ;;
esac

if curl -fsS "http://127.0.0.1:${PORT}/api/health" >/dev/null 2>&1; then
  echo "Unsloth Studio is already running on port ${PORT}."
  exit 0
fi

mkdir -p logs
nohup "${UNSLOTH}" studio run \
  --model "${REPO}" --gguf-variant UD-Q4_K_XL \
  --max-seq-length 65536 \
  -p "${PORT}" --api-key-name open-webui \
  --temperature 1.0 --top-p 0.95 --top-k 20 --min-p 0.0 \
  >logs/unsloth.log 2>&1 &

echo "Loading ${NAME} (takes about a minute)..."
for _ in $(seq 1 60); do
  if grep -q "Model loaded:" logs/unsloth.log 2>/dev/null; then
    echo "Unsloth Studio is up: http://127.0.0.1:${PORT} (API: /v1)"
    exit 0
  fi
  sleep 5
done
echo "Model did not load within 5 minutes; check logs/unsloth.log" >&2
exit 1
