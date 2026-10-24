#!/usr/bin/env bash
# Stop the Strata server (frees the ~25-33 GB the model uses).
set -euo pipefail

if curl -fsS "http://127.0.0.1:${STRATA_PORT:-8080}/v1/models" >/dev/null 2>&1; then
  "${HOME}/.local/bin/strata" launch --stop --preset "Gyro-S 64K"
else
  echo "Strata is not running."
fi
