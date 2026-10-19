#!/usr/bin/env bash
# Stop the Colima Docker runtime (stops all containers running inside it).
set -euo pipefail

if colima status >/dev/null 2>&1; then
  colima stop
else
  echo "Colima is not running."
fi
