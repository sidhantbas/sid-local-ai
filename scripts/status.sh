#!/usr/bin/env bash
# Show the state of each part of the local AI stack.
set -uo pipefail

echo "== Colima =="
colima list

echo
echo "== Docker context: $(docker context show) =="
if colima status >/dev/null 2>&1; then
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
fi
