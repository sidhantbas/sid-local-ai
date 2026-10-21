#!/usr/bin/env bash
# Stop every running Unsloth Studio server (frees the ~20 GB the model uses).
set -euo pipefail

"${HOME}/.local/bin/unsloth" studio stop
