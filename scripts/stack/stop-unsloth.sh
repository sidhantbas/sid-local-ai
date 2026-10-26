#!/usr/bin/env bash
# Stop every running Unsloth Studio server (frees the ~20-30 GB the model uses).
set -euo pipefail

if curl -fsS "http://127.0.0.1:${UNSLOTH_PORT:-8890}/api/health" >/dev/null 2>&1; then
  "${HOME}/.local/bin/unsloth" studio stop
else
  echo "Unsloth Studio is not running."
fi
