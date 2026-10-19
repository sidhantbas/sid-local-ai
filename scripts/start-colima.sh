#!/usr/bin/env bash
# Start the Colima Docker runtime (4 CPU, 2 GB RAM, VZ + Rosetta) and use its context.
set -euo pipefail

if colima status >/dev/null 2>&1; then
  echo "Colima is already running."
else
  colima start --cpu 4 --memory 2 --vm-type vz --vz-rosetta
fi

docker context use colima >/dev/null 2>&1
echo "Docker context: $(docker context show)"
